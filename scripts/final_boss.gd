extends Entity

@onready var boss_saber: Node2D = $boss_weapon/BossSaber
@onready var player = Globals.player
@onready var ranged_timer: Timer = $Ranged_Timer
const RANGE_ATTACK = preload("res://scenes/range_attack.tscn")

@onready var final_level = get_parent()

var final_walls
var room_width
var room_height

var speed = 100

var boss_max_health = 100
var stage_two_health = 40

var current_stage = 1

var moving_dist = 0.0
var is_attacking = false
var saber_dist = 20

var attack_this_round = []
var attack_stage_one
var attack_stage_two

var ranged_cooldown = 5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	room_width = final_level.x_dim * 16
	room_height = final_level.y_dim * 16
	
	
	#attack_this_round = [["attack_saber","attack_dash"].pick_random(), "attack_range"]
	attack_stage_one = ["attack_saber","attack_dash"].pick_random()
	if attack_stage_one	== "attack_saber":
		moving_dist = 20
	else:
		moving_dist = 80
		
	attack_stage_two = [attack_stage_one,"attack_range"].pick_random()
	ranged_timer.wait_time = ranged_cooldown
	ranged_timer.start()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func perform_attack():
	if current_stage == 1:
		pass

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
		
	
func get_random_pos(points_array: Array):
	var pos = Vector2.ZERO
	for i in range(5):
		pos.x = randf_range(32, room_width - 32)
		pos.y = randf_range(32, room_height - 32)
		points_array.append(pos)


func _on_ranged_timer_timeout() -> void:
	ranged_attack()
