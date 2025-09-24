extends Node2D
# version 5, working on highlighting function

# Tile data
var tile_size = 16

const WALL_SOURCE_ID = 0
const WALL_ATLAS_COORDS = Vector2i(6, 1)

const FLOOR_SOURCE_ID = 3
const FLOOR_ATLAS_COORDS = Vector2i(7, 1)

# Room size (including walls)
const ROOM_WIDTH = 13 #23
const ROOM_HEIGHT = 9 #9

# Main layer index
const MAIN_LAYER = 0

# Node references
@onready var tilemap: TileMap = $TileMap
@onready var door = $Door
@onready var exit_door = $Exit
@onready var spawn_point = $SpawnPoint

@onready var reveal_timer: Timer = $RevealTimer
#@onready var puzzle_timer: Timer = $PuzzleTimer
@onready var health_drain_timer: Timer = $HealthDrainTimer

@export var drain_interval: float = 10.0
@export var drain_amount: int = 5

var player: Node2D = null

var path: Array = []
var path_index: int = 0

const TILE_HIGHLIGHT_TIME = 1
const TILE_HIGHLIGHT_DELAY = 0.3

var start = Vector2i(1, ROOM_HEIGHT / 2)
var goal = Vector2i(ROOM_WIDTH - 2, ROOM_HEIGHT / 2)

var reveal_time = 0

func _ready():
	draw_room()
	place_entry_exit_spawn()
	generate_path_and_start()
	reveal_timer.wait_time = 15.0
	#puzzle_timer.wait_time = 15.0
	reveal_timer.connect("timeout", Callable(self, "_on_RevealTimer_timeout"))
	#puzzle_timer.connect("timeout", Callable(self, "_on_PuzzleTimer_timeout"))
	
	player = Globals.player
	# Lock exit at start; player must complete path
	if exit_door and exit_door.has_method("set_exit_enabled"):
		exit_door.set_exit_enabled(false)
	
	health_drain_timer.wait_time = drain_interval
	health_drain_timer.start()

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
	var entry_tile = Vector2i(0, ROOM_HEIGHT / 2)
	var exit_tile = Vector2i(ROOM_WIDTH - 2, ROOM_HEIGHT / 2)  # Just left of right wall
	var spawn_tile = Vector2i(1, ROOM_HEIGHT / 2)

	door.position = tilemap.map_to_local(entry_tile)
	exit_door.position = tilemap.map_to_local(exit_tile)
	spawn_point.position = tilemap.map_to_local(spawn_tile)

func generate_path_and_start():
	path.clear()
	while path.is_empty():
		path = generate_direct_path(start, goal)
	path_index = 0
	reveal_timer.start()
	#puzzle_timer.start()
	#reveal_path_tiles()

func generate_direct_path(start: Vector2i, goal: Vector2i) -> Array:
	path = [start]
	var current = start
	var attempts = 0

	while current != goal and attempts < 1000:
		attempts += 1
		var neighbors = {
			"right": current + Vector2i(1, 0),
			"up": current + Vector2i(0, -1),
			"down": current + Vector2i(0, 1),
			"left": current + Vector2i(-1, 0)
		}

		# Base probabilities
		var probs = {
			"right": 0.55,
			"up": 0.20,
			"down": 0.20,
			"left": 0.05
		}

		# Remove invalid directions and redistribute probabilities
		var valid_dirs = []
		var total_prob = 0.0
		for dir in probs.keys():
			if is_walkable(neighbors[dir]):
				valid_dirs.append(dir)
				total_prob += probs[dir]

		if valid_dirs.is_empty():
			# Backtrack 2 tiles if possible, else break
			if path.size() > 2:
				path.pop_back()
				path.pop_back()
				current = path.back()
				continue
			else:
				print("No path found, stuck at start")
				break

		# Redistribute probabilities proportionally to valid dirs
		for dir in valid_dirs:
			probs[dir] = probs[dir] / total_prob

		# Weighted random pick
		var rand = randf()
		var cumulative = 0.0
		var chosen_dir = valid_dirs[0]
		for dir in valid_dirs:
			cumulative += probs[dir]
			if rand <= cumulative:
				chosen_dir = dir
				break

		var next_tile = neighbors[chosen_dir]

		# Avoid going back to previous tile unless no other option
		var prev_tile = path[path.size() - 2] if path.size() > 1 else Vector2i(-1, -1)
		if next_tile == prev_tile and valid_dirs.size() > 1:
			# Pick another random valid dir excluding previous
			var alt_dirs = valid_dirs.filter(func(d): return neighbors[d] != prev_tile)
			if not alt_dirs.is_empty():
				chosen_dir = alt_dirs[randi() % alt_dirs.size()]
				next_tile = neighbors[chosen_dir]

		path.append(next_tile)
		current = next_tile

		if path.size() > 1000:
			print("Too long path!")
			break
	print(path)
	return path if path[-1] == goal else []

func get_neighbors(pos: Vector2i) -> Array:
	return [
		pos + Vector2i(1, 0),
		pos + Vector2i(-1, 0),
		pos + Vector2i(0, 1),
		pos + Vector2i(0, -1)
	]

func is_walkable(pos: Vector2i) -> bool:
	if pos.x <= 0 or pos.x >= ROOM_WIDTH - 1:
		return false
	if pos.y <= 0 or pos.y >= ROOM_HEIGHT - 1:
		return false
	if pos in path:
		return false
	return true

# Every path will be revealed for 3 times, if time out after the third reveal, generate a new path
func _on_RevealTimer_timeout():
	reveal_time += 1
	if reveal_time < 4: 
		reveal_path_tiles()
	else:
		print("Time's up! Resetting path and player position.")
		reset_player_position()
		generate_path_and_start()
		reveal_path_tiles()
		reveal_time = 0

func reveal_path_tiles() -> void:
	await _highlight_sequence()

func _highlight_sequence() -> void:
	var stagger_delay := 0.3  # how much later each next tile starts
	for i in range(path.size()):
		var tile_pos = path[i]

		# Turn on immediately at this step
		highlight_tile(tile_pos, true)

		# Schedule turning off after TILE_HIGHLIGHT_TIME
		call_deferred("_schedule_unhighlight", tile_pos, TILE_HIGHLIGHT_TIME)

		# Wait only stagger_delay before starting next highlight
		await get_tree().create_timer(stagger_delay).timeout


func _schedule_unhighlight(tile_pos: Vector2i, delay: float) -> void:
	# This helper waits 'delay' seconds and then unhighlights
	await get_tree().create_timer(delay).timeout
	highlight_tile(tile_pos, false)

func highlight_tile(tile_pos: Vector2i, highlight: bool) -> void:
	var highlight_name = "highlight_%s_%s" % [tile_pos.x, tile_pos.y]
	var existing = get_node_or_null(highlight_name)
	var cell_world_pos = tile_pos * tile_size  # simple calculation for exact alignment
	if highlight:
		if existing == null:
			var rect = ColorRect.new()
			rect.name = highlight_name
			rect.color = Color(1, 1, 0.3, 0.5)  # yellow transparent
			rect.size = Vector2(tile_size, tile_size)
			rect.position = cell_world_pos
			add_child(rect)
	else:
		if existing:
			existing.queue_free()

#func _on_PuzzleTimer_timeout():
	#print("Time's up! Resetting path and player position.")
	#reset_player_position()
	#generate_path_and_start()

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
			if exit_door and exit_door.has_method("set_exit_enabled"):
				exit_door.set_exit_enabled(true)
	else:
		print("Wrong tile! Resetting player.")
		reset_player_position()


func _on_health_drain_timer_timeout() -> void:
	if player and player.health: # player inherits from Entity so has health node
		player.health.take_damage(drain_amount)
