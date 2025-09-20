#extends CharacterBody2D
extends Entity
# inherit variable "health" and "max_health"

@export var speed: float = 80
@export var attack_range: float = 20
@export var attack_cooldown: float = 1.0  # seconds between attacks
@export var damage: int = 10

@export var separation_distance: float = 24   # desired spacing between enemies
@export var separation_strength: float = 0.5  # how strong they push apart

@onready var sprite_2d: Sprite2D = $Sprite2D
var hit_flash_time := 0.2

var melee_max_health = 20

var player: Node2D = null
var can_attack = true

func _ready():
	player = Globals.player
	if player:
		#print("Enemy found the Player node:", player.name)
		pass
	else:
		print("Enemy could NOT find the Player node!")
	max_health = melee_max_health
	#print(max_health)
	super._ready()


func _physics_process(_delta):
	if not player:
		return

	var distance = global_position.distance_to(player.global_position)
	var direction = Vector2.ZERO

	if distance > attack_range:
		# Chase player
		direction = (player.global_position - global_position).normalized()
	else:
		# In attack range, stop moving and attack
		velocity = Vector2.ZERO
		if can_attack:
			attack_player()

	# Apply separation force every frame
	direction += get_separation_vector()

	# Move enemy if direction exists
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
		move_and_slide()

func attack_player():
	can_attack = false

	# Play attack animation
	if $Sprite2D/AnimationPlayer:
		$Sprite2D/AnimationPlayer.play("attack")

	# If player is close enough, trigger hit animation
	if player and global_position.distance_to(player.global_position) <= attack_range:
		if player.has_method("on_hit"):
			player.on_hit(damage)

	# Start cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func get_separation_vector() -> Vector2:
	var push = Vector2.ZERO
	var parent = get_parent()
	if not parent:
		return push

	for child in parent.get_children():
		if child == self:
			continue
		if child is CharacterBody2D:  # assuming all enemies are CharacterBody2D
			var dist = global_position.distance_to(child.global_position)
			if dist < separation_distance and dist > 0:
				var away = (global_position - child.global_position).normalized()
				var strength = (separation_distance - dist) / separation_distance
				push += away * strength * separation_strength

	return push

func flash_hit():
	# Tint red when hit
	sprite_2d.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(hit_flash_time).timeout
	sprite_2d.modulate = Color(1, 1, 1) # Reset to normal

func on_hit(damage):
	health.take_damage(damage)
	flash_hit()
	
#func _on_health_changed(new_health: int):
	#print("%s health: %d" % [name, new_health])
	

	
