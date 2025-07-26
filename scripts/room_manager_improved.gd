extends Node2D

@onready var player = get_parent().get_node("Player")

var current_room: Node = null
var rooms_completed: int = 0
const TOTAL_ROOMS: int = 8

var maze_used := false
var reward_used := false

var miniboss_count := 0
const MAX_MINIBOSS := 2

# Paths for layouts
var mob_rooms := [
	"res://scenes/rooms/combat_mob_01.tscn",
	"res://scenes/rooms/combat_mob_02.tscn",
	"res://scenes/rooms/combat_mob_03.tscn"
]

var miniboss_rooms := [
	"res://scenes/rooms/combat_miniboss_01.tscn",
	"res://scenes/rooms/combat_miniboss_02.tscn"
]

# Room weights (out of 100)
var room_weights := {
	"combat": 60,
	"maze": 20,
	"reward": 20
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
			scene_path = choose_combat_layout()
		"maze":
			scene_path = "res://scenes/rooms/maze.tscn"
			maze_used = true
		"reward":
			scene_path = "res://scenes/rooms/reward.tscn"
			reward_used = true

	room_scene = load(scene_path)
	spawn_room(room_scene)
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

	# Connect signal
	var exit_door = room_instance.get_node("Exit")
	exit_door.connect("exit_triggered", Callable(self, "_on_room_completed"))

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
		# 12% per layout (3 mobs + 2 miniboss)
		for room_path in mob_rooms:
			for i in range(12):
				pool.append(room_path)
		for room_path in miniboss_rooms:
			for i in range(12):
				pool.append(room_path)
	else:
		# 20% per mob layout
		for room_path in mob_rooms:
			for i in range(20):
				pool.append(room_path)

	var chosen = pool[randi() % pool.size()]

	# Track miniboss usage
	if miniboss_rooms.has(chosen):
		miniboss_count += 1

	return chosen
