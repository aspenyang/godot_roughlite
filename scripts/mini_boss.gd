extends CharacterBody2D

@onready var bowlike: Area2D = $Bowlike
@onready var player = Globals.player
@onready var room_scene = get_parent()

@onready var summon_timer = $Summon_Timer

@export var attack_range: float = 180
@export var fire_cooldown: float = 3.0  # seconds between attacks
@export var summon_cooldown: float = 5.0 

const SPEED = 50
const MARGIN = 32
var room_width
var room_height

const melee = preload("res://scenes/melee.tscn")

var can_attack = true
var can_summon = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	room_height = room_scene.y_dim * 16
	room_width = room_scene.x_dim * 16
	summon_timer.wait_time = summon_cooldown
	summon_timer.start()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player:
		#var direction = (player.global_position - bowlike.global_position).normalized()
		#bowlike.rotation = direction.angle()
		bowlike.look_at(player.global_position) #weapon points to the player
		#bowlike.look_at(get_global_mouse_position()) #if wanting the weapon points to the cursor
		
	var distance = global_position.distance_to(player.global_position)
	var direction = Vector2.ZERO
	if distance > attack_range:
		# Chase player
		direction = (player.global_position - global_position).normalized()
	else:
		# In attack range, stop moving and attack
		direction = Vector2.ZERO
		if can_attack:
			attack_player()
			
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * SPEED
		move_and_slide()
			
func attack_player():
	can_attack = false
	
	bowlike.fire_arrow()
	
	# Start cooldown
	await get_tree().create_timer(fire_cooldown).timeout
	can_attack = true

func summon_mob():
	var enemy = melee.instantiate()
	var random_pos = Vector2.ZERO
	var valid_position = false
	var attempts = 0
	
	while not valid_position and attempts < 20:
		random_pos.x = randf_range(0 + MARGIN, room_width - MARGIN)
		random_pos.y = randf_range(0 + MARGIN, room_height - MARGIN)
		
		# Check distance from other enemies
		valid_position = true
		if random_pos.distance_to(player.global_position) < 16 or random_pos.distance_to(global_position) < 16:
			valid_position = false
			break
		attempts += 1
		
	enemy.position = random_pos
	room_scene.add_child(enemy)
	

func _on_summon_timer_timeout() -> void:
	summon_mob()
