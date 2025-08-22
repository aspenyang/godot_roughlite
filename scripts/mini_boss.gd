#extends CharacterBody2D
extends Entity

@onready var bowlike: Area2D = $Bowlike
@onready var player = Globals.player
@onready var room_scene = get_parent()

@onready var summon_timer = $Summon_Timer

@export var attack_range: float = 180
@export var fire_cooldown: float = 3.0  # seconds between attacks
@export var summon_cooldown: float = 5.0 

@onready var sprite_2d: Sprite2D = $Sprite2D
var sprite_size
var hit_flash_time := 0.2

var miniboss_max_health = 50

const SPEED = 50
const MARGIN = 32
var room_width
var room_height

const melee = preload("res://scenes/melee.tscn")
const TextBubbleScene = preload("res://scenes/TextBubble.tscn")
var summon_bubble: Node2D

var can_attack = true
var can_summon = true
var summon_text_duration = 0.5
var summon_text_fontsize = 16


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	room_height = room_scene.y_dim * 16
	room_width = room_scene.x_dim * 16
	summon_bubble = TextBubbleScene.instantiate()
	add_child(summon_bubble)
	summon_bubble.visible = false
	summon_timer.wait_time = summon_cooldown
	summon_timer.start()
	
	max_health = miniboss_max_health
	super._ready()
	
	sprite_size = sprite_2d.texture.get_size() * sprite_2d.scale



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
	summon_bubble.position = Vector2(-sprite_size.x / 2 + summon_bubble.label.size.x / 2, -sprite_size.y / 2)
	summon_bubble.show_text("Summon mobs", summon_text_duration, summon_text_fontsize,Color(0,0,0))

func _on_summon_timer_timeout() -> void:
	summon_mob()
	
func flash_hit():
	# Tint red when hit
	sprite_2d.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(hit_flash_time).timeout
	sprite_2d.modulate = Color(1, 1, 1) # Reset to normal

func on_hit(damage):
	health.take_damage(damage)
	flash_hit()
