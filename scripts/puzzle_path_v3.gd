extends Node2D

var tile_size = 16

const WALL_SOURCE_ID = 0
const WALL_ATLAS_COORDS = Vector2i(6, 1)

const FLOOR_SOURCE_ID = 3
const FLOOR_ATLAS_COORDS = Vector2i(7, 1)

const ROOM_WIDTH = 33
const ROOM_HEIGHT = 9
const MAIN_LAYER = 0

@onready var tilemap: TileMap = $TileMap
@onready var door = $Door
@onready var exit_door = $Exit
@onready var spawn_point = $SpawnPoint

@onready var reveal_timer: Timer = $RevealTimer
@onready var puzzle_timer: Timer = $PuzzleTimer

var path: Array = []
var path_index: int = 0

const TILE_HIGHLIGHT_TIME = 0.5
const TILE_HIGHLIGHT_DELAY = 0.3

func _ready():
	draw_room()
	place_entry_exit_spawn()
	generate_path_and_start()

func draw_room():
	tilemap.clear()
	for x in range(ROOM_WIDTH):
		for y in range(ROOM_HEIGHT):
			var pos = Vector2i(x, y)
			if x == 0 or x == ROOM_WIDTH - 1 or y == 0 or y == ROOM_HEIGHT - 1:
				tilemap.set_cell(MAIN_LAYER, pos, WALL_SOURCE_ID, WALL_ATLAS_COORDS)
			else:
				tilemap.set_cell(MAIN_LAYER, pos, FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS)

func place_entry_exit_spawn():
	# Fixed entry and exit tiles
	var entry_tile = Vector2i(0, ROOM_HEIGHT / 2)
	var exit_tile = Vector2i(ROOM_WIDTH - 2, ROOM_HEIGHT / 2)  # Left tile of the exit wall
	var spawn_tile = Vector2i(1, ROOM_HEIGHT / 2)

	door.position = tilemap.map_to_local(entry_tile)
	exit_door.position = tilemap.map_to_local(exit_tile)
	spawn_point.position = tilemap.map_to_local(spawn_tile)

func generate_path_and_start():
	var start = Vector2i(1, ROOM_HEIGHT / 2)
	var goal = Vector2i(ROOM_WIDTH - 2, ROOM_HEIGHT / 2)
	path = generate_maze_path(start, goal)
	path_index = 0
	reveal_timer.start()
	puzzle_timer.start()
	reveal_path_tiles()

func generate_maze_path(start: Vector2i, goal: Vector2i) -> Array:
	var path = []
	var visited = {}

	if _dfs(start, goal, path, visited):
		print(path)
		return path
	return []

func _dfs(current: Vector2i, goal: Vector2i, path: Array, visited: Dictionary) -> bool:
	path.append(current)
	visited[current] = true

	if current == goal:
		return true

	var neighbors = get_neighbors(current)
	neighbors.shuffle()

	for neighbor in neighbors:
		if not visited.has(neighbor) and is_walkable(neighbor):
			if _dfs(neighbor, goal, path, visited):
				return true

	path.pop_back()
	return false

func get_neighbors(pos: Vector2i) -> Array:
	return [
		pos + Vector2i(1, 0),
		pos + Vector2i(-1, 0),
		pos + Vector2i(0, 1),
		pos + Vector2i(0, -1),
	]

func is_walkable(pos: Vector2i) -> bool:
	if pos.x <= 0 or pos.x >= ROOM_WIDTH - 1:
		return false
	if pos.y <= 0 or pos.y >= ROOM_HEIGHT - 1:
		return false
	if pos in path:
		return false
	# Only border walls, rest is walkable floor
	return true

func _on_RevealTimer_timeout():
	reveal_path_tiles()

func reveal_path_tiles() -> void:
	await _highlight_sequence()

func _highlight_sequence() -> void:
	for tile_pos in path:
		highlight_tile(tile_pos, true)
		await get_tree().create_timer(TILE_HIGHLIGHT_TIME).timeout
		highlight_tile(tile_pos, false)
		await get_tree().create_timer(TILE_HIGHLIGHT_DELAY).timeout

func highlight_tile(tile_pos: Vector2i, highlight: bool) -> void:
	var highlight_name = "highlight_%s_%s" % [tile_pos.x, tile_pos.y]
	var existing = get_node_or_null(highlight_name)
	var cell_world_pos = tile_pos * tile_size
	if highlight:
		if existing == null:
			var rect = ColorRect.new()
			rect.name = highlight_name
			rect.color = Color(1, 1, 0.3, 0.5) # yellow transparent
			rect.size = Vector2(tile_size, tile_size)
			rect.position = cell_world_pos
			add_child(rect)
	else:
		if existing:
			existing.queue_free()

func _on_PuzzleTimer_timeout():
	print("Time's up! Resetting path and player position.")
	reset_player_position()
	generate_path_and_start()

func reset_player_position():
	var player = Globals.player
	if player:
		player.global_position = spawn_point.global_position
		path_index = 0

func player_stepped(tile_pos: Vector2i):
	print(path[path_index], " ", tile_pos)
	if path_index + 1 < path.size() and tile_pos == path[path_index + 1]:
		path_index += 1
		print("Correct step:", tile_pos, "Progress:", path_index, "/", path.size())
		if path_index == path.size() - 1:
			print("Player completed the path!")
			# Trigger completion event here
	else:
		print("Wrong tile! Resetting player.")
		reset_player_position()
