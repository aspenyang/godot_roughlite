extends CharacterBody2D

const SPEED = 150
const TRAVEL_DISTANCE = 300
const DAMAGE = 5

@onready var timer: Timer = $Timer
@onready var fire_player: AnimationPlayer = $AnimationPlayer

var player = Globals.player
var is_targeted = true
var target_time = 0.5
var direction = Vector2.ZERO
var last_dir = Vector2.ZERO
var distance_traveled = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fire_player.play("flame")
	timer.wait_time = target_time
	timer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_targeted:
		direction = (player.global_position - global_position).normalized()
		last_dir = direction
		
	var movement = direction * SPEED * delta
	var collision = move_and_collide(movement)
	
	distance_traveled += movement.length()
	
	if collision:
		var collider = collision.get_collider()
		if collider == player:
			player.on_hit(DAMAGE)
		queue_free()
	elif distance_traveled > TRAVEL_DISTANCE:
		queue_free()
		

func _on_timer_timeout() -> void:
	is_targeted = false
	direction = last_dir
