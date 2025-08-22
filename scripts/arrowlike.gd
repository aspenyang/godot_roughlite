extends CharacterBody2D

@onready var player = Globals.player
const SPEED = 200
var direction = Vector2.ZERO
var wall_node

var nocking_time = 0.5
var can_move = false
@onready var nocking_timer: Timer = $Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	direction = (player.global_position - global_position).normalized()
	wall_node = get_parent().get_parent().get_node("Miniboss_walls")
	
	nocking_timer.wait_time = 0.2  # delay in seconds
	nocking_timer.start()
	nocking_timer.connect("timeout", Callable(self, "_on_timer_timeout"))

func _on_timer_timeout():
	can_move = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not can_move:
		return

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
	
