extends Node2D

# Tile data
const WALL_SOURCE_ID = 0
const WALL_ATLAS_COORDS = Vector2i(6, 1)

const FLOOR_SOURCE_ID = 3
const FLOOR_ATLAS_COORDS = Vector2i(7, 1)

# Room size (including walls)
const ROOM_WIDTH = 35
const ROOM_HEIGHT = 17

# Main layer index
const MAIN_LAYER = 0

# Node references
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

var map_layout := []
var is_revealing_path = false

func _ready():
	# Connect timer signals
	reveal_timer.timeout.connect(_on_reveal_timer_timeout)
	puzzle_timer.timeout.connect(_on_puzzle_timer_timeout)
	
	draw_room()
	place_entry_exit_spawn()
	generate_path_and_start()

func draw_room():
	tilemap.clear()
	for x in range(ROOM_WIDTH):
		var row = []
		for y in range(ROOM_HEIGHT):
			var pos = Vector2i(x, y)
			if x == 0 or x == ROOM_WIDTH - 1 or y == 0 or y == ROOM_HEIGHT - 1:
				tilemap.set_cell(MAIN_LAYER, pos, WALL_SOURCE_ID, WALL_ATLAS_COORDS)
				row.append("wall")
			else:
				tilemap.set_cell(MAIN_LAYER, pos, FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS)
				row.append("floor")
		map_layout.append(row)

func place_entry_exit_spawn():
	# Tile positions
	var entry_tile = Vector2i(0, ROOM_HEIGHT / 2)
	var exit_tile = Vector2i(ROOM_WIDTH - 2, ROOM_HEIGHT / 2) # Right next to wall
	var spawn_tile = Vector2i(1, ROOM_HEIGHT / 2)

	# Assign positions
	door.position = tilemap.map_to_local(entry_tile)
	exit_door.position = tilemap.map_to_local(exit_tile)
	spawn_point.position = tilemap.map_to_local(spawn_tile)

func generate_path_and_start():
	path = generate_maze_path()
	if path.is_empty():
		print("Error: Could not generate a valid path!")
		return
		
	path_index = 0
	puzzle_timer.start()
	# Start path revelation
	if not is_revealing_path:
		reveal_path_tiles()
	
func generate_maze_path() -> Array:
	var start = Vector2i(1, ROOM_HEIGHT / 2)
	var goal = Vector2i(ROOM_WIDTH - 2, ROOM_HEIGHT / 2)
	
	# Try multiple times with different strategies
	for attempt in range(5):
		var generated_path = attempt_path_generation(start, goal, attempt)
		if not generated_path.is_empty():
			return generated_path
	
	# Fallback: simple straight path if maze generation fails
	print("Warning: Using fallback straight path")
	return generate_straight_path(start, goal)

func attempt_path_generation(start: Vector2i, goal: Vector2i, strategy: int) -> Array:
	var path_attempt = [start]
	var current = start
	var max_attempts = 500 + (strategy * 100)  # Increase attempts each try
	var attempts = 0
	
	while current != goal and attempts < max_attempts:
		attempts += 1
		var neighbors = get_valid_neighbors_for_maze(current, path_attempt)
		
		if neighbors.is_empty():
			# Backtrack strategy
			if path_attempt.size() > 1:
				path_attempt.pop_back()
				if not path_attempt.is_empty():
					current = path_attempt.back()
				else:
					break
			else:
				break
			continue
		
		# Different strategies for different attempts
		var next_tile: Vector2i
		match strategy:
			0: # Greedy approach
				neighbors.sort_custom(func(a, b):
					return (a - goal).length_squared() < (b - goal).length_squared()
				)
				next_tile = neighbors[0]
			1: # Semi-random with bias toward goal
				neighbors.sort_custom(func(a, b):
					return (a - goal).length_squared() < (b - goal).length_squared()
				)
				var max_choice = min(3, neighbors.size())
				next_tile = neighbors[randi() % max_choice]
			_: # More random
				next_tile = neighbors[randi() % neighbors.size()]
		
		path_attempt.append(next_tile)
		current = next_tile
	
	# Return path only if it reaches the goal
	if current == goal:
		return path_attempt
	else:
		return []

func generate_straight_path(start: Vector2i, goal: Vector2i) -> Array:
	var simple_path = [start]
	var current = start
	
	# Move right until we reach the goal's x position
	while current.x < goal.x:
		current.x += 1
		simple_path.append(Vector2i(current.x, current.y))
	
	# Move up/down to reach goal's y position
	while current.y != goal.y:
		if current.y < goal.y:
			current.y += 1
		else:
			current.y -= 1
		simple_path.append(Vector2i(current.x, current.y))
	
	return simple_path

func get_valid_neighbors_for_maze(pos: Vector2i, path: Array) -> Array:
	var candidates = []
	var directions = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	
	for dir in directions:
		var next_pos = pos + dir
		if is_walkable(next_pos) and next_pos not in path:
			candidates.append(next_pos)
	
	return candidates
	
func is_walkable(pos: Vector2i) -> bool:
	if pos.x < 1 or pos.x >= ROOM_WIDTH - 1:
		return false
	if pos.y < 1 or pos.y >= ROOM_HEIGHT - 1:
		return false
	return true
	
func _on_reveal_timer_timeout():
	if not is_revealing_path:
		reveal_path_tiles()

func reveal_path_tiles() -> void:
	if is_revealing_path:
		return
		
	is_revealing_path = true
	await _highlight_sequence()
	is_revealing_path = false

func _highlight_sequence() -> void:
	# Clear any existing highlights first
	clear_all_highlights()
	
	# Highlight each tile in sequence
	for i in range(path.size()):
		var tile_pos = path[i]
		highlight_tile(tile_pos, true)
		await get_tree().create_timer(TILE_HIGHLIGHT_TIME).timeout
		highlight_tile(tile_pos, false)
		
		# Don't wait after the last tile
		if i < path.size() - 1:
			await get_tree().create_timer(TILE_HIGHLIGHT_DELAY).timeout

func clear_all_highlights():
	# Remove all existing highlight nodes
	for child in get_children():
		if child.name.begins_with("highlight_"):
			child.queue_free()

func highlight_tile(tile_pos: Vector2i, highlight: bool) -> void:
	var highlight_name = "highlight_%s_%s" % [tile_pos.x, tile_pos.y]
	var existing = get_node_or_null(highlight_name)
	
	if highlight:
		if existing == null:
			var rect = ColorRect.new()
			rect.name = highlight_name
			rect.color = Color(1, 1, 0.3, 0.5) # yellow transparent
			
			# Use Godot 4 properties
			rect.size = tilemap.tile_set.tile_size if tilemap.tile_set else Vector2(32, 32)
			print("rect.size")
			rect.position = tilemap.map_to_local(tile_pos) - rect.size / 2
			
			add_child(rect)
	else:
		if existing:
			existing.queue_free()

func _on_puzzle_timer_timeout():
	print("Time's up! Resetting path and player position.")
	clear_all_highlights()
	reset_player_position()
	generate_path_and_start()

func reset_player_position():
	# Make sure Globals.player exists before accessing it
	if Globals and Globals.has_method("get") and Globals.player:
		Globals.player.global_position = spawn_point.global_position
	path_index = 0

func player_stepped(tile_pos: Vector2i):
	if path_index < path.size() and tile_pos == path[path_index]:
		# Correct next tile in order
		path_index += 1
		print("Correct step:", tile_pos, "Progress:", path_index, "/", path.size())
		
		if path_index == path.size():
			print("Player completed the path!")
			clear_all_highlights()
			puzzle_timer.stop()
			# You can emit a signal or call a function here to trigger room completion
	else:
		print("Wrong tile! Resetting player.")
		reset_player_position()
