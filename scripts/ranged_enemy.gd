#extends CharacterBody2D
extends Entity

@export var attack_cooldown: float = 3.0
@export var attack_range: float = 200.0
@export var detection_range: float = 300.0
@export var move_speed: float = 50.0
@export var bomb_scene: PackedScene

var can_attack = true
var wander_target: Vector2
var navigation_setup_complete = false
var player: Node2D = null

@onready var attack_timer = $AttackTimer
@onready var agent = $NavigationAgent2D

@onready var sprite_2d: Sprite2D = $Sprite2D
var hit_flash_time := 0.2

var ranged_max_health = 30

func _ready():
	# Get player reference
	player = Globals.player
	if player:
		#print("Ranged enemy found player: ", player.name)
		pass
	else:
		print("Warning: Ranged enemy could not find player!")
	
	# Configure timer
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	# Configure navigation agent
	agent.avoidance_enabled = true
	agent.radius = 8.0
	agent.max_speed = move_speed
	
	# Wait for navigation to be ready
	call_deferred("setup_navigation")
	max_health = ranged_max_health
	super._ready()

func setup_navigation():
	# Wait one frame for navigation to be ready
	await get_tree().process_frame
	
	# Find navigation region - try multiple paths
	var nav_region = find_navigation_region()
	
	if nav_region and nav_region.navigation_polygon:
		navigation_setup_complete = true
		set_new_wander_target()
	else:
		print("Warning: No NavigationRegion2D found for ranged enemy!")

func find_navigation_region() -> NavigationRegion2D:
	# Try to find nav region in parent first
	var parent = get_parent()
	while parent:
		var nav_region = parent.get_node_or_null("NavigationRegion2D")
		if nav_region:
			return nav_region
		parent = parent.get_parent()
	
	# Fallback: search in current scene
	return get_tree().current_scene.find_child("NavigationRegion2D", true, false)

func _physics_process(delta):
	if not player or not is_instance_valid(player):
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	# Attack if player is in range
	if can_attack and dist <= attack_range and dist > 32.0:  # avoid self-damage
		throw_bomb(player.global_position)
	
	# Handle wandering movement
	handle_movement()

func handle_movement():
	if not navigation_setup_complete:
		return
	
	if not agent.is_navigation_finished():
		var next_point = agent.get_next_path_position()
		var direction = (next_point - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
	else:
		# Reached target, pick new wander point
		set_new_wander_target()

func set_new_wander_target():
	var nav_region = find_navigation_region()
	if nav_region and nav_region.navigation_polygon:
		wander_target = get_random_point_inside_polygon(nav_region.navigation_polygon)
		agent.target_position = wander_target

func throw_bomb(target_pos: Vector2):
	if not bomb_scene:
		print("Warning: No bomb scene assigned to ranged enemy!")
		return
	
	can_attack = false
	var bomb = bomb_scene.instantiate()
	
	# Set bomb properties
	bomb.global_position = global_position
	if bomb.has_method("set_target"):
		bomb.set_target(target_pos)
	elif "target_pos" in bomb:
		bomb.target_pos = target_pos
	
	get_tree().current_scene.add_child(bomb)
	attack_timer.start()

func _on_attack_timer_timeout():
	can_attack = true

# Helper function for random point generation
func get_random_point_inside_polygon(nav_poly: NavigationPolygon) -> Vector2:
	var points = nav_poly.get_vertices()
	if points.size() == 0:
		return global_position
	
	# Get bounding box
	var min_pos = points[0]
	var max_pos = points[0]
	
	for point in points:
		min_pos.x = min(min_pos.x, point.x)
		min_pos.y = min(min_pos.y, point.y)
		max_pos.x = max(max_pos.x, point.x)
		max_pos.y = max(max_pos.y, point.y)
	
	# Try to find valid point (max 50 attempts)
	for i in range(50):
		var random_point = Vector2(
			randf_range(min_pos.x, max_pos.x),
			randf_range(min_pos.y, max_pos.y)
		)
		
		if is_point_in_polygon(random_point, points):
			return random_point
	
	# Fallback to current position
	return global_position

func is_point_in_polygon(point: Vector2, polygon: Array) -> bool:
	var inside = false
	var j = polygon.size() - 1
	
	for i in range(polygon.size()):
		var pi = polygon[i]
		var pj = polygon[j]
		
		if ((pi.y > point.y) != (pj.y > point.y)) and \
		   (point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y) + pi.x):
			inside = not inside
		j = i
	
	return inside

func flash_hit():
	# Tint red when hit
	sprite_2d.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(hit_flash_time).timeout
	sprite_2d.modulate = Color(1, 1, 1) # Reset to normal

func on_hit(damage):
	health.take_damage(damage)
	flash_hit()
