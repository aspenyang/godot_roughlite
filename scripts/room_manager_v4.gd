extends Node2D
# This script follows the v3 version, for change the whole randomized system.
@onready var player = get_parent().get_node("Player")

var current_room: Node = null
var rooms_completed: int = 0
const TOTAL_ROOMS: int = 7

var maze_used := false
var reward_used := false

var miniboss_count := 0
const MAX_MINIBOSS := 1

# path for puzzle level
var puzzle_path = "res://scenes/rooms/puzzle_path.tscn"

var miniboss_rooms := [
	"res://scenes/rooms/combat_miniboss_01.tscn",
	#"res://scenes/rooms/combat_miniboss_02.tscn"
]

# Room weights (out of 100)
var room_weights := {
	"combat": 100,
	"maze": 0, #should be 20
	"reward": 100 #should be 20
}

func _ready():
	load_next_room()

func _on_room_completed():
	print("Room completed! Loading next room...")
	load_next_room()

func load_next_room():
	if current_room:
		current_room.queue_free()
	
	var room_scene: PackedScene

	# Final boss room
	if rooms_completed == TOTAL_ROOMS - 1:
		room_scene = load("res://scenes/rooms/final_boss.tscn")
		spawn_room(room_scene)
		rooms_completed += 1
		return

	var room_type = choose_next_room_type()
	var scene_path = ""

	match room_type:
		"combat":
			#scene_path = choose_combat_layout() #fiexed rooms picking
			# Use procedural room layout
			var layout_choice = choose_combat_layout()
			if layout_choice == "PROCEDURAL":
				var generated_level = generate_combat()
				spawn_generated_room(generated_level)
				rooms_completed += 1
				return
			else:
				scene_path = layout_choice
		"maze":
			scene_path = "res://scenes/rooms/maze.tscn"
			maze_used = true
		"reward":
			scene_path = "res://scenes/rooms/reward.tscn"
			reward_used = true

	room_scene = load(scene_path)
	spawn_room(room_scene)
	print(player.current_room_scene_path)
	rooms_completed += 1

func spawn_room(room_scene: PackedScene):
	var room_instance = room_scene.instantiate()
	add_child(room_instance)
	current_room = room_instance

	# Move player to SpawnPoint
	if room_instance.has_node("SpawnPoint"):
		var spawn_point = room_instance.get_node("SpawnPoint")
		player.global_position = spawn_point.global_position
	else:
		print("Warning: No SpawnPoint in this room!")
	
	player.set_current_scene(room_instance)
		
	# Inform player of current room
	if Globals.player and Globals.player.has_method("set_current_room_scene"):
		Globals.player.set_current_room_scene(room_scene.resource_path)

	# Connect signal
	var exit_door = room_instance.get_node("Exit")
	exit_door.connect("exit_triggered", Callable(self, "_on_room_completed"))


# For procedural combat room
func spawn_generated_room(level_container: Node2D):
	add_child(level_container)
	current_room = level_container
	
	# Move player to base room's spawn point or door
	var base_room = level_container.get_node("level_room0")  # Assuming base is first
	if base_room.has_node("SpawnPoint"):
		player.global_position = base_room.get_node("SpawnPoint").global_position
	else:
		print("Warning: No SpawnPoint in this room!")
		
	# Connect exit signal from the room with visible exit
	for child in level_container.get_children():
		var exit_door = child.get_node("Exit")
		print(exit_door.visible)
		if exit_door.visible:
			exit_door.connect("exit_triggered", Callable(self, "_on_room_completed"))
			print("connected")
			break


func choose_next_room_type() -> String:
	var choices = []

	if not maze_used and room_weights["maze"] > 0:
		for i in range(room_weights["maze"]):
			choices.append("maze")

	if not reward_used and room_weights["reward"] > 0:
		for i in range(room_weights["reward"]):
			choices.append("reward")

	if room_weights["combat"] > 0:
		for i in range(room_weights["combat"]):
			choices.append("combat")

	if choices.size() == 0:
		return "combat"  # fallback
		
	return choices[randi() % choices.size()]

# 🔥 Combat layout selection with miniboss rules
func choose_combat_layout() -> String:
	var level = rooms_completed + 1
	var pool: Array[String] = []

	var miniboss_allowed = level >= 3 and level <= TOTAL_ROOMS - 2 and miniboss_count < MAX_MINIBOSS

	if miniboss_allowed:
		
		# procedural combat room
		for i in range(2): #should be 24
			pool.append("PROCEDURAL")
		# Add combat_mob_03 only (12% chance)
		for i in range(0): # should be 12
			pool.append(puzzle_path)  # combat_mob_03.tscn
		# Add miniboss rooms (12% each)
		for room_path in miniboss_rooms:
			for i in range(12): 
				pool.append(room_path)
		
	else:
		# 20% per mob layout
		#for room_path in mob_rooms:
			#for i in range(20):
				#pool.append(room_path)
		# procedural combat room
		for i in range(24): #should be 24
			pool.append("PROCEDURAL")
		# Add combat_mob_03 only (12% chance)
		for i in range(1): #should be 20
			pool.append(puzzle_path)  # combat_mob_03.tscn

	var chosen = pool[randi() % pool.size()]

	# Track miniboss usage
	if miniboss_rooms.has(chosen):
		miniboss_count += 1

	return chosen
	
# Helper method
func add_to_set(set_array: Array, pos: Vector2):
	if not pos in set_array:
		set_array.append(pos)

# Generate combat level map
func generate_combat():
	var room_layout = []
	
	# Create parent container
	var level_container = Node2D.new()
	level_container.name = "GeneratedLevel"
	
	var room_count = randi() % 2 + 5 #there will be 5 or 6 rooms including the base
	
	# Place base
	var base = load("res://scenes/rooms/level_map.tscn").instantiate()
	base.name = "level_room0"
	room_layout.append(Vector2(0, 0))
	base.close_all_paths()
	base.get_node("Door").visible = true
	base.get_node("Exit").visible = false

	#Open path(s)
	var first_rooms = randi() % 3
	match first_rooms:
		0:
			room_layout.append(Vector2(0, -1))
			base.north_pass()
		1:
			room_layout.append(Vector2(1, 0))
			base.east_pass()
		2:
			room_layout.append(Vector2(0, -1))
			base.north_pass()
			room_layout.append(Vector2(1, 0))
			base.east_pass()
	
	level_container.add_child(base)
	
	while room_layout.size() < room_count:
		for i in range(1, room_layout.size()):
			# South
			if randf() < 0.25 and room_layout.size() < room_count:
				add_to_set(room_layout, Vector2(room_layout[i].x, room_layout[i].y + 1))
			# West
			if randf() < 0.25 and room_layout.size() < room_count:
				add_to_set(room_layout, Vector2(room_layout[i].x - 1, room_layout[i].y))
			# North
			if randf() < 0.25 and room_layout.size() < room_count:
				add_to_set(room_layout, Vector2(room_layout[i].x, room_layout[i].y - 1))
			# East
			if randf() < 0.25 and room_layout.size() < room_count:
				add_to_set(room_layout, Vector2(room_layout[i].x + 1, room_layout[i].y))
	
	print(room_layout.size()," ", room_count)
	
	# Make sure if the north and east room of the base exit, the path(s) will be open
	if Vector2(0, -1) in room_layout:
		base.north_pass()
	if Vector2(1, 0) in room_layout:
		base.east_pass()
	
	var if_exit = false # for activate exit
	
	var melee = preload("res://scenes/melee.tscn")
	var ranged_enemy = preload("res://scenes/RangedEnemy.tscn")
	#var enemy_pool = [melee,ranged_enemy]
	var enemy_pool = [melee if randf() < 0.5 else ranged_enemy, melee if randf() < 0.5 else ranged_enemy,]
	
	for i in range(room_layout.size()-1, 0, -1):
		var pos = room_layout[i]
		var unit = load("res://scenes/rooms/level_map.tscn").instantiate()
		var exit_door = unit.get_node("Exit")
		exit_door.visible = false
		var entry = unit.get_node("Door")
		entry.visible = false
		unit.name = "level_room%d"%i
		unit.close_all_paths()
		# South
		if Vector2(pos.x, pos.y + 1 ) in room_layout:
			unit.south_pass()
		# West
		if Vector2(pos.x - 1, pos.y) in room_layout:
			unit.west_pass()
		# North (If the north room is the base, not connect)
		if Vector2(pos.x, pos.y - 1) in room_layout and Vector2(pos.x, pos.y - 1) != Vector2(0, 0):
			unit.north_pass()
		# East (If the east room is the base, not connect)
		if Vector2(pos.x + 1, pos.y) in room_layout and Vector2(pos.x + 1, pos.y) != Vector2(0, 0):
			unit.east_pass()
			
		# Spawn enemies (skip base room, which is at index 0 in the loop range)
		spawn_enemies_in_room(unit, enemy_pool)
		# Place the room
		unit.position = pos * 320
		
		# Place exit door
		if not if_exit and unit.get_node("NorthWall").visible:
			exit_door.visible = true
			if_exit = true
		
		level_container.add_child(unit)
	
	# Inform player of current room
	if Globals.player and Globals.player.has_method("set_current_room_scene"):
		Globals.player.set_current_room_scene("res://scenes/rooms/level_map.tscn")
	return level_container

func spawn_enemies_in_room(room: Node2D, enemy_pool: Array):
	var room_width = 256
	var room_height = 256
	var margin = 64
	var min_distance = 32
	
	var enemy_count = 1 # should be randi_range(2, 3)
	
	var spawn_positions = []
	
	for i in range(enemy_count):
		var enemy = enemy_pool[randi() % enemy_pool.size()].instantiate()
		var valid_position = false
		var attempts = 0
		var random_pos = Vector2.ZERO
		
		# Try to find a valid position
		while not valid_position and attempts < 15:
			random_pos.x = randf_range(0 + margin, room_width - margin)
			random_pos.y = randf_range(0 + margin, room_height - margin)
		
		# Check distance from other enemies
			valid_position = true
			for pos in spawn_positions:
				if random_pos.distance_to(pos) < min_distance:
					valid_position = false
					break
			
			attempts += 1
		
		enemy.position = random_pos
		spawn_positions.append(random_pos)
		room.add_child(enemy)
	
