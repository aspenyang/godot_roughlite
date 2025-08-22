extends Node2D

@export var explosion_radius: float = 32.0
@export var fuse_time: float = 2.0
@export var damage: int = 20
@export var hint_circle_color: Color = Color.RED
@export var hint_circle_alpha: float = 0.3

var target_pos: Vector2
var is_exploded: bool = false

@onready var hint_circle = $HintCircle
@onready var fuse_timer = $Timer
@onready var explosion_area = $ExplosionArea
@onready var collision_shape = $ExplosionArea/CollisionShape2D

func _ready():
	# Set up fuse timer
	fuse_timer.wait_time = fuse_time
	fuse_timer.timeout.connect(_on_fuse_timer_timeout)
	
	# Set up explosion area
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = explosion_radius
	collision_shape.shape = circle_shape
	explosion_area.body_entered.connect(_on_body_entered_explosion_area)
	
	# Move to target position
	if target_pos != Vector2.ZERO:
		global_position = target_pos
	
	# Set up hint circle
	setup_hint_circle()
	
	# Start the fuse
	fuse_timer.start()
	print("Bomb armed at: ", global_position, " - exploding in ", fuse_time, " seconds")

func set_target(pos: Vector2):
	target_pos = pos

func setup_hint_circle():
	if not hint_circle:
		return
	
	# Make the hint circle show the explosion radius
	hint_circle.modulate = Color(hint_circle_color.r, hint_circle_color.g, hint_circle_color.b, hint_circle_alpha)
	
	# Scale the circle sprite to match explosion radius
	# Assuming your hint circle sprite is designed for a specific size, adjust accordingly
	var sprite_radius = 32.0  # Adjust this to match your sprite's natural radius
	var scale_factor = explosion_radius / sprite_radius
	hint_circle.scale = Vector2(scale_factor, scale_factor)

func _on_fuse_timer_timeout():
	explode()

func explode():
	if is_exploded:
		return
	
	is_exploded = true
	print("BOOM! Explosion at: ", global_position)
	
	# Hide hint circle
	if hint_circle:
		hint_circle.visible = false
	
	# Get all bodies in explosion area
	var bodies_in_area = explosion_area.get_overlapping_bodies()
	
	for body in bodies_in_area:
		damage_entity(body)
	
	# Visual explosion effect (you can replace this with an animation)
	create_explosion_effect()
	
	# Clean up bomb after short delay
	await get_tree().create_timer(0.5).timeout
	queue_free()

func damage_entity(body: Node):
	
	#print("Explosion hit: ", body.name)
	
	# Damage entities
	if body.has_method("on_hit") and body.name != "RangedEnemy":
		body.on_hit(damage)

		print(body.name + " hit by explosion!")
	

func create_explosion_effect():
	# Simple explosion visual - you can replace with AnimationPlayer later
	if hint_circle:
		hint_circle.visible = true
		hint_circle.modulate = Color.ORANGE
		hint_circle.scale *= 1.2
		
		# Quick flash effect
		var tween = create_tween()
		tween.tween_property(hint_circle, "modulate:a", 0.0, 0.3)

func _on_body_entered_explosion_area(body):
	# This gets called when bodies enter the area during the fuse time
	# You could add additional logic here if needed
	pass
