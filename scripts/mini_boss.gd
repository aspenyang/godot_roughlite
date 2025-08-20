extends CharacterBody2D

@onready var bowlike: Area2D = $Bowlike
@onready var player = Globals.player

@export var attack_range: float = 200
@export var attack_cooldown: float = 2.0  # seconds between attacks

var can_attack = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player:
		var direction = (player.global_position - bowlike.global_position).normalized()
		bowlike.rotation = direction.angle()
		#bowlike.look_at(player.global_position) #weapon points to the player
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
			
func attack_player():
	can_attack = false
	
	bowlike.fire_arrow()
	
	# Start cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
