extends Entity

@onready var boss_saber: Node2D = $boss_weapon/BossSaber
@onready var player = Globals.player
@onready var ranged_timer: Timer = $Ranged_Timer
@onready var boss_animation: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var boss_weapon: Node2D = $boss_weapon

const RANGE_ATTACK = preload("res://scenes/range_attack.tscn")
const FIRE = preload("res://scenes/fire.tscn")

@onready var final_level = get_parent()


var final_walls
var room_width
var room_height

var speed = 200
var hit_flash_time := 0.2
var boss_max_health = 100
var stage_two_health = 40

var current_stage = 1

var moving_dist = 0.0
var is_attacking = false
var can_attack = true
var saber_dist = 20

var attack_this_round = []
var attack_stage_one
var attack_stage_two
var current_attack
var cool_down

var ranged_cooldown = 5

const SPRINT_SPEED = 800
const SPRINT_DISTANCE = 100


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	room_width = final_level.x_dim * 16
	room_height = final_level.y_dim * 16
	
	max_health = boss_max_health
	super._ready()
	
	boss_saber.visible = false
	#attack_this_round = [["attack_saber","attack_fire"].pick_random(), "attack_range"]
	attack_stage_one = ["attack_saber","attack_fire"].pick_random()
	#attack_stage_one = "attack_saber"
	current_attack = attack_stage_one
	
	if attack_stage_one	== "attack_saber":
		moving_dist = 40
		cool_down = 5.0
	else:
		moving_dist = 80
		cool_down = 4.0
		
	attack_stage_two = [attack_stage_one,"attack_range"].pick_random()
	ranged_timer.wait_time = ranged_cooldown
	ranged_timer.start()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var distance = global_position.distance_to(player.global_position)
	var direction = Vector2.ZERO
	if can_attack and distance <= moving_dist:
		perform_attack()
	if not is_attacking:
		if distance >= moving_dist:
			direction = (player.global_position - global_position).normalized()
			
		else:
			direction = Vector2.ZERO
		velocity = direction.normalized() * speed
		move_and_slide()


func perform_attack():
	print("perform attack")
	#is_attacking = true
	can_attack = false
	
	if current_attack == "attack_saber":
		print("attack saber")
		is_attacking = true
		boss_weapon.look_at(player.global_position)
		boss_weapon.rotation += deg_to_rad(90)
		boss_saber.visible = true
		await get_tree().create_timer(0.5).timeout
		boss_animation.play("attack_saber")
	elif current_attack == "attack_fire":
		fire_attack()
		print("attakc fire")
	else:
		return
	await get_tree().create_timer(cool_down).timeout
	can_attack = true


func ranged_attack():
	var ranged_points = [player.global_position]
	print(ranged_points[0])
	var ranged_instances = []
	get_random_pos(ranged_points)
	for pos in ranged_points:
		var ranged_instance = RANGE_ATTACK.instantiate()
		ranged_instance.position = pos
		final_level.add_child(ranged_instance)
		ranged_instances.append(ranged_instance)
	
	await get_tree().create_timer(1.5).timeout
	for instance in ranged_instances:
		instance.queue_free()
	ranged_points.clear()
		

func fire_attack():
	var fire_ball = FIRE.instantiate()
	add_child(fire_ball)

func get_random_pos(points_array: Array):
	var pos = Vector2.ZERO
	for i in range(5):
		pos.x = randf_range(32, room_width - 32)
		pos.y = randf_range(32, room_height - 32)
		points_array.append(pos)


func _on_ranged_timer_timeout() -> void:
	ranged_attack()
	await get_tree().create_timer(1).timeout
	ranged_attack()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack_saber":
		is_attacking = false
		boss_saber.visible = false

func flash_hit():
	# Tint red when hit
	sprite_2d.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(hit_flash_time).timeout
	sprite_2d.modulate = Color(1, 1, 1) # Reset to normal

func on_hit(damage):
	health.take_damage(damage)
	flash_hit()
