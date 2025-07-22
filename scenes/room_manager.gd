extends Node2D

@onready var player = get_parent().get_node("Player")
var current_room: Node = null

func _ready():
	generate_first_room()

func generate_first_room():
	var room_scene = preload("res://scenes/rooms/baseroom.tscn")
	var room_instance = room_scene.instantiate()
	add_child(room_instance)
	current_room = room_instance

	# Move player to SpawnPoint
	var spawn_point = room_instance.get_node("SpawnPoint")
	player.global_position = spawn_point.global_position

	# Connect room's signal to load next room
	room_instance.connect("room_completed", Callable(self, "_on_room_completed"))

func _on_room_completed():
	print("Room completed! Ready to load next room.")
	# Later: queue_free current_room and load next
