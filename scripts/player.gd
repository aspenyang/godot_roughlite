extends CharacterBody2D

var speed = 300  # Movement speed in pixels/second
var sprint_speed = 600 
var movement = Vector2.ZERO

func _ready() -> void:
	Globals.player = $"."

func _physics_process(_delta):
	# Get input direction
	movement = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		movement.x += 1
	if Input.is_action_pressed("ui_left"):
		movement.x -= 1
	if Input.is_action_pressed("ui_up"):
		movement.y -= 1
	if Input.is_action_pressed("ui_down"):
		movement.y += 1

	# Sprint if spacebar is pressed
	var current_speed = speed
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed

	# Normalize to prevent faster diagonal movement
	movement = movement.normalized() * current_speed

	# Apply movement
	velocity = movement
	move_and_slide()
	
func flash_hit():
	if $Sprite2D:
		$Sprite2D.modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		$Sprite2D.modulate = Color.WHITE
