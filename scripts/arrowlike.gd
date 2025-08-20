extends CharacterBody2D

@onready var player = Globals.player
const SPEED = 200
var direction = Vector2.ZERO
var wall_node



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	direction = (player.global_position - global_position).normalized()
	wall_node = get_parent().get_parent().get_node("Miniboss_walls")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#var movement = Vector2.ZERO
	
	#movement.x += direction.x
	#movement.y += direction.y
	
	#velocity = movement * SPEED * delta
	velocity = direction * SPEED * delta
	#var collision = move_and_slide()
	var collision = move_and_collide(velocity)
	var collider
	if collision:
		collider = collision.get_collider()

		if collider == player:
			player.flash_hit()
			queue_free()
		elif collider == wall_node:
			queue_free()
	
