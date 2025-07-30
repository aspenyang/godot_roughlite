extends CharacterBody2D

@export var speed: float = 80
var player: Node2D = null

func _ready():
	# Find the player node in the scene tree (adjust the path to your player node)
	player = Globals.player
	if player:
		print("Enemy found the Player node:", player.name)
	else:
		print("Enemy could NOT find the Player node!")

func _physics_process(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
