extends CharacterBody2D

@export var speed: float = 80
@export var attack_range: float = 16
@export var attack_cooldown: float = 1.0  # seconds between attacks

var player: Node2D = null
var can_attack = true

func _ready():
	# Find the player node in the scene tree (adjust the path to your player node)
	player = Globals.player
	if player:
		print("Enemy found the Player node:", player.name)
	else:
		print("Enemy could NOT find the Player node!")

func _physics_process(delta):
	if not player:
		return

	var distance = global_position.distance_to(player.global_position)

	if distance > attack_range:
		# Chase player
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	else:
		#In attack range, stop moving and attack
		velocity = Vector2.ZERO
		if can_attack:
			attack_player()
			
func attack_player():
	#print("Enemy attacks player!")
	can_attack = false
	# Play attack animation
	if $Sprite2D/AnimationPlayer:
		$Sprite2D/AnimationPlayer.play("attack")
		
	# If player is close enough, trigger hit animation
	if player and global_position.distance_to(player.global_position) <= attack_range:
		if player.has_method("flash_hit"):
			player.flash_hit()
		
	# Start cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
