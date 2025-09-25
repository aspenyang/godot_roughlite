extends Node2D
# This script follows the v4 version, for save and load system.
@onready var player = get_parent().get_node("Player")

var current_room: Node = null
var rooms_completed: int = 0
const TOTAL_ROOMS: int = 5 # set to 5 for testing. Originally set to 7 or 8


var maze_used := false
var reward_used := false

var miniboss_count := 0
const MAX_MINIBOSS := 1

# save data 
var dynamic_data : Dictionary = {}

# path for puzzle level
var puzzle_path = "res://scenes/rooms/puzzle_path.tscn"

var miniboss_rooms := [
	"res://scenes/rooms/combat_miniboss_01.tscn",
	#"res://scenes/rooms/combat_miniboss_02.tscn"
]

# Room weights (out of 100)
var room_weights := {
	"combat": 20, #should be 60
	"maze": 10, #should be 20
	"reward": 10 #should be 20
}

# --- New vars for exit gating ---
var remaining_enemies := 0
var current_exit_node: Node = null
var exit_locked_for_combat := false

func _ready():
	load_next_room()

func fresh_data():
	rooms_completed = 0
	maze_used = false
	reward_used = false
	miniboss_count = 0
	dynamic_data = {
		"slot": Globals.slot,
		"levels_total": TOTAL_ROOMS,
		"last_result": "",
		"in_progress": true,
		"levels_completed": 0,
		"maze_used": maze_used,
		"reward_used": reward_used,
		"miniboss_count": miniboss_count,
		"current_level": "",
		"player_state":  {
			"current_health": player.max_health,
			"max_health": player.max_health
		}
	}

func _on_room_completed():
	print("Room completed! Loading next room...")
	load_next_room()

func load_next_room():
	SaveManagerV2.print_info()
	if current_room:
		current_room.queue_free()
	remaining_enemies = 0
	current_exit_node = null
	exit_locked_for_combat = false
	
	var room_scene: PackedScene

	# Final boss room
	if rooms_completed == TOTAL_ROOMS - 1:
		room_scene = load("res://scenes/rooms/final_level.tscn")
		spawn_room(room_scene)
		rooms_completed += 1
		return

	var room_type = choose_next_room_type()
	var scene_path = ""

	match room_type:
		"combat":
			# Use procedural or fixed
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

	# Connect exit signal
	var exit_door = room_instance.get_node("Exit")
	exit_door.connect("exit_triggered", Callable(self, "_on_room_completed"))
	
	# Decide if this room needs enemy clear gating
	var path = room_scene.resource_path
	var needs_clear = not (path.ends_with("reward.tscn") or path.ends_with("maze.tscn") or path.contains("final_level") or path.contains("puzzle_path"))
	if needs_clear:
		_setup_exit_lock_for_combat(room_instance, exit_door)

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
		
	# Find the visible exit and connect
	for child in level_container.get_children():
		if child.has_node("Exit"):
			var exit_door = child.get_node("Exit")
			if exit_door.visible:
				exit_door.connect("exit_triggered", Callable(self, "_on_room_completed"))
				_setup_exit_lock_for_combat(level_container, exit_door)
				break
	
	# Inform player of current room
	if Globals.player and Globals.player.has_method("set_current_room_scene"):
		Globals.player.set_current_room_scene("res://scenes/rooms/level_map.tscn")

# --- Enemy tracking & exit locking helpers ---
func _setup_exit_lock_for_combat(room_root: Node, exit_node: Node):
	current_exit_node = exit_node
	remaining_enemies = 0
	exit_locked_for_combat = true
	# Collect existing enemies
	var enemies: Array = []
	_collect_enemies(room_root, enemies)
	for e in enemies:
		_register_enemy(e)
	# Lock exit if any enemies
	if remaining_enemies > 0 and exit_node.has_method("set_exit_enabled"):
		exit_node.set_exit_enabled(false)
	else:
		exit_locked_for_combat = false  # No enemies, keep it open

func _collect_enemies(node: Node, out_list: Array):
	for c in node.get_children():
		if c is Entity and c.name != "Player":
			out_list.append(c)
		_collect_enemies(c, out_list)

func _register_enemy(enemy: Node):
	if not enemy or not is_instance_valid(enemy):
		return
	if not enemy.has_node("Health"):
		return
	var health = enemy.get_node("Health")
	if not health.is_connected("died", Callable(self, "_on_enemy_died")):
		health.connect("died", Callable(self, "_on_enemy_died"))
	remaining_enemies += 1

func _on_enemy_died():
	remaining_enemies -= 1
	if remaining_enemies <= 0 and exit_locked_for_combat and current_exit_node and current_exit_node.has_method("set_exit_enabled"):
		current_exit_node.set_exit_enabled(true)
		exit_locked_for_combat = false

# (If later you want summoned enemies counted, call _register_enemy(new_enemy) after spawning.)

# --- Existing functions below (unchanged) ---

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
		return "combat"
	return choices[randi() % choices.size()]

func choose_combat_layout() -> String:
	var level = rooms_completed + 1
	var pool: Array[String] = []
	var miniboss_allowed = level >= 3 and level <= TOTAL_ROOMS - 2 and miniboss_count < MAX_MINIBOSS
	if miniboss_allowed:
		for i in range(2):
			pool.append("PROCEDURAL")
		for i in range(12):
			pool.append(puzzle_path)
		for room_path in miniboss_rooms:
			for i in range(12):
				pool.append(room_path)
	else:
		for i in range(24):
			pool.append("PROCEDURAL")
		for i in range(20):
			pool.append(puzzle_path)
	var chosen = pool[randi() % pool.size()]
	if miniboss_rooms.has(chosen):
		miniboss_count += 1
	return chosen

func add_to_set(set_array: Array, pos: Vector2):
	if not pos in set_array:
		set_array.append(pos)

func generate_combat():
	var room_layout = []
	var level_container = Node2D.new()
	level_container.name = "GeneratedLevel"
	var room_count = randi() % 2 + 5
	var base = load("res://scenes/rooms/level_map.tscn").instantiate()
	base.name = "level_room0"
	room_layout.append(Vector2(0, 0))
	base.close_all_paths()
	base.get_node("Door").visible = true
	base.get_node("Exit").visible = false
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
			if randf() < 0.25 and room_layout.size() < room_count:
				add_to_set(room_layout, Vector2(room_layout[i].x, room_layout[i].y + 1))
			if randf() < 0.25 and room_layout.size() < room_count:
				add_to_set(room_layout, Vector2(room_layout[i].x - 1, room_layout[i].y))
			if randf() < 0.25 and room_layout.size() < room_count:
				add_to_set(room_layout, Vector2(room_layout[i].x, room_layout[i].y - 1))
			if randf() < 0.25 and room_layout.size() < room_count:
				add_to_set(room_layout, Vector2(room_layout[i].x + 1, room_layout[i].y))
	print(room_layout.size()," ", room_count)
	if Vector2(0, -1) in room_layout:
		base.north_pass()
	if Vector2(1, 0) in room_layout:
		base.east_pass()
	var if_exit = false
	var melee = preload("res://scenes/melee.tscn")
	var ranged_enemy = preload("res://scenes/RangedEnemy.tscn")
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
		if Vector2(pos.x, pos.y + 1 ) in room_layout:
			unit.south_pass()
		if Vector2(pos.x - 1, pos.y) in room_layout:
			unit.west_pass()
		if Vector2(pos.x, pos.y - 1) in room_layout and Vector2(pos.x, pos.y - 1) != Vector2(0, 0):
			unit.north_pass()
		if Vector2(pos.x + 1, pos.y) in room_layout and Vector2(pos.x + 1, pos.y) != Vector2(0, 0):
			unit.east_pass()
		spawn_enemies_in_room(unit, enemy_pool)
		unit.position = pos * 320
		if not if_exit and unit.get_node("NorthWall").visible:
			exit_door.visible = true
			if_exit = true
		level_container.add_child(unit)
	if Globals.player and Globals.player.has_method("set_current_room_scene"):
		Globals.player.set_current_room_scene("res://scenes/rooms/level_map.tscn")
	return level_container

func spawn_enemies_in_room(room: Node2D, enemy_pool: Array):
	var room_width = 256
	var room_height = 256
	var margin = 64
	var min_distance = 32
	var enemy_count = 1
	var spawn_positions = []
	for i in range(enemy_count):
		var enemy = enemy_pool[randi() % enemy_pool.size()].instantiate()
		var valid_position = false
		var attempts = 0
		var random_pos = Vector2.ZERO
		while not valid_position and attempts < 15:
			random_pos.x = randf_range(0 + margin, room_width - margin)
			random_pos.y = randf_range(0 + margin, room_height - margin)
			valid_position = true
			for pos in spawn_positions:
				if random_pos.distance_to(pos) < min_distance:
					valid_position = false
					break
			attempts += 1
		enemy.position = random_pos
		spawn_positions.append(random_pos)
		room.add_child(enemy)

func set_completed_room(completed: int):
	rooms_completed = completed
