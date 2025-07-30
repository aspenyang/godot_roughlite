extends Node2D

@onready var tilemap = $maze_paint
@onready var spawn_node = $SpawnPoint
@onready var entry_door = $Door
@onready var exit_door = $Exit

var starting_pos = Vector2i()
const main_layer = 0
const normal_wall_atlas_coords = Vector2i(0, 4)
const walkable_atlas_coords = Vector2i(5, 4)
const doors_coords = Vector2i(5,2)
const SOURCE_ID = 0

var walls_original: Array = []
var walkable_original: Array = []
var entry_original: Array = []
var exit_original: Array = []
var walls_expand: Array = []
var walkable_expand: Array = []
var entry_expand: Array = []
var exit_expand: Array = []

@export var y_dim = 15
@export var x_dim = 31
@export var starting_coords = Vector2i(0, 0)

@export var step_delay: float = 0.0
@export var allow_loops: bool = false

var adj4 = [
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

var start_pos: Vector2i
var end_pos: Vector2i
var start_border: Vector2i
var end_border: Vector2i

func _ready() -> void:
	#place_border()
	#the original code
	#dfs(starting_coords)
	#set_entry_and_exit()
	#change the code to start from the randomly picked start point
	#set_entry_and_exit()
	#dfs(starting_pos)
	#draw_tiles(walls_original, entry_original, exit_original)
	
	while true:
		walls_original.clear()
		walkable_original.clear()
		place_border()
		set_entry_and_exit()
		dfs(start_pos)
		if check_connected(start_pos, end_pos):
			break
	
	expand_maze()
	draw_tiles(walls_expand, entry_expand, exit_expand)
	clear_path()
	var player_pos = Vector2i(start_pos.x*2, start_pos.y*2+1)
	spawn_node.position = tilemap.map_to_local(player_pos)
	var entry_pos = Vector2i(start_border.x*2, start_border.y*2+1)
	var exit_pos = Vector2i(end_border.x*2, end_border.y*2+1)
	entry_door.position = tilemap.map_to_local(entry_pos)
	exit_door.position = tilemap.map_to_local(exit_pos)
	

func _input(event: InputEvent) -> void:
	pass
#	if Input.is_action_just_pressed("reset"):
#		get_tree().reload_current_scene()

func place_border():
	for y in range(-1, y_dim):
		place_wall(Vector2i(-1, y))
	for x in range(-1, x_dim):
		place_wall(Vector2i(x, -1))
	for y in range(-1, y_dim + 1):
		place_wall(Vector2i(x_dim, y))
	for x in range(-1, x_dim + 1):
		place_wall(Vector2i(x, y_dim))

func delete_cell_at(pos: Vector2i):
	tilemap.set_cell(main_layer, pos)

func place_wall(pos: Vector2i):
	#tilemap.set_cell(main_layer, pos, SOURCE_ID, normal_wall_atlas_coords)
	walls_original.append(pos)
	

func will_be_converted_to_wall(spot: Vector2i) -> bool:
	return (spot.x % 2 == 1 and spot.y % 2 == 1)

func is_wall(pos: Vector2i) -> bool:
	#return tilemap.get_cell_atlas_coords(main_layer, pos) == normal_wall_atlas_coords
	return pos in walls_original

func can_move_to(current: Vector2i) -> bool:
	return (
		current.x >= 0 and current.y >= 0 and
		current.x < x_dim and current.y < y_dim and
		!is_wall(current)
	)

func dfs(start: Vector2i) -> void:
	var fringe: Array[Vector2i] = [start]
	var seen = {}

	while fringe.size() > 0:
		var current: Vector2i = fringe.pop_back()
		
		if current in seen or not can_move_to(current):
			if step_delay > 0:
				await get_tree().create_timer(step_delay).timeout
			continue

		seen[current] = true

		if current.x % 2 == 1 and current.y % 2 == 1:
			place_wall(current)
			continue

		#tilemap.set_cell(main_layer, current, SOURCE_ID, walkable_atlas_coords)
		walkable_original.append(current)
		if step_delay > 0:
			await get_tree().create_timer(step_delay).timeout

		var found_new_path = false
		adj4.shuffle()

		for pos in adj4:
			var new_pos = current + pos
			if new_pos not in seen and can_move_to(new_pos):
				var chance_of_no_loop = randi_range(1, 1)
				if allow_loops:
					chance_of_no_loop = randi_range(1, 5)

				if will_be_converted_to_wall(new_pos) and chance_of_no_loop == 1:
					place_wall(new_pos)
				else:
					found_new_path = true
					fringe.append(new_pos)

		if not found_new_path:
			place_wall(current)

func set_entry_and_exit() -> void:
	# Choose start edge randomly: 0=top,1=right,2=bottom,3=left
	var edge = randi() % 4
	match edge:
		0: # top edge
			print("top")
			start_pos = Vector2i(random_even(0, x_dim - 1), 0)
			#end_pos = Vector2i(random_even(0, x_dim - 1), y_dim - 1)
			end_pos = Vector2i(x_dim - start_pos.x, y_dim - 1)
			start_border = Vector2i(start_pos.x,start_pos.y-1)
			end_border = Vector2i(end_pos.x,end_pos.y+1)
		1: # right edge
			print("right")
			start_pos = Vector2i(x_dim - 1, random_even(0, y_dim - 1))
			#end_pos = Vector2i(0, random_even(0, y_dim - 1))
			end_pos = Vector2i(0, y_dim - start_pos.y)
			start_border = Vector2i(start_pos.x+1, start_pos.y)
			end_border = Vector2i(end_pos.x-1, end_pos.y)
		2: # bottom edge
			print("bottom")
			start_pos = Vector2i(random_even(0, x_dim - 1), y_dim - 1)
			#end_pos = Vector2i(random_even(0, x_dim - 1), 0)
			end_pos = Vector2i(x_dim - start_pos.x, 0)
			start_border = Vector2i(start_pos.x, start_pos.y+1)
			end_border = Vector2i(end_pos.x, end_pos.y-1)
		3: # left edge
			print("left")
			start_pos = Vector2i(0, random_even(0, y_dim - 1))
			#end_pos = Vector2i(x_dim - 1, random_even(0, y_dim - 1))
			end_pos = Vector2i(x_dim - 1, y_dim - start_pos.y)
			start_border = Vector2i(start_pos.x-1, start_pos.y)
			end_border = Vector2i(end_pos.x+1, end_pos.y)

	# Carve entrance and exit (make sure these positions are walkable)
	#tilemap.set_cell(main_layer, start_pos, SOURCE_ID, doors_coords)
	#tilemap.set_cell(main_layer, end_pos, SOURCE_ID, doors_coords)
	#tilemap.set_cell(main_layer, start_border, SOURCE_ID, doors_coords)
	#tilemap.set_cell(main_layer, end_border, SOURCE_ID, doors_coords)
	entry_original.append(start_border)
	entry_original.append(start_pos)
	exit_original.append(end_border)
	exit_original.append(end_pos)

	print("Start position: ", start_pos)
	print("End position: ", end_pos)

# Helper: pick a random even number between min and max (inclusive)
func random_even(min_val: int, max_val: int) -> int:
	var n = randi_range(min_val, max_val)
	# Adjust to nearest even number within bounds
	if n % 2 == 1:
		if n == max_val:
			n -= 1
		else:
			n += 1
	return clamp(n, min_val, max_val)

func draw_tiles(walls: Array, entry: Array, exit: Array):
	for pos in walls:
		tilemap.set_cell(main_layer, pos, SOURCE_ID, normal_wall_atlas_coords)
	#for pos in entry:
		#tilemap.set_cell(main_layer, pos, SOURCE_ID, doors_coords)
	#for pos in exit:
		#tilemap.set_cell(main_layer, pos, SOURCE_ID, doors_coords)

func add_to_set(set_array: Array, pos: Vector2i):
	if not pos in set_array:
		set_array.append(pos)

func expand_array(array: Array, set_array: Array):
	for pos in array:
		var pos_expand = Vector2i(pos.x * 2, pos.y * 2)
		add_to_set(set_array, pos_expand)
		add_to_set(set_array, Vector2i(pos_expand.x+1,pos_expand.y))
		add_to_set(set_array, Vector2i(pos_expand.x,pos_expand.y+1))
		add_to_set(set_array, Vector2i(pos_expand.x+1, pos_expand.y+1))

func expand_maze():
	expand_array(walls_original, walls_expand)
	expand_array(entry_original, entry_expand)
	expand_array(exit_original, exit_expand)
	expand_array(walkable_original, walkable_expand)
	
func clear_path():
	#for pos in walkable_expand:
		#delete_cell_at(pos)
	for pos in entry_expand:
		delete_cell_at(pos)
	for pos in exit_expand:
		delete_cell_at(pos)

func check_connected(start: Vector2i, goal: Vector2i) -> bool:
	var open = [start]
	var visited = {}
	while open.size() > 0:
		var current = open.pop_back()
		if current == goal:
			return true
		visited[current] = true
		for dir in adj4:
			var next = current + dir
			if next in walkable_original and not visited.has(next):
				open.append(next)
	return false
