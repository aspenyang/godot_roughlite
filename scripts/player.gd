extends CharacterBody2D

var speed = 300  # Movement speed in pixels/second
var sprint_speed = 600 
var movement = Vector2.ZERO

func _physics_process(delta):
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
