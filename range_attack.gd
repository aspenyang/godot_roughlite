extends Area2D

@onready var player = Globals.player

@onready var timer: Timer = $Timer
var damage_interval = 1
var damage = 5
var player_in_area = false # keep track of the player

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.wait_time = damage_interval
	#timer.start()
	timer.stop()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	pass


func _on_timer_timeout():
	if player_in_area and player.has_method("on_hit"):
		player.on_hit(damage)
	

func _on_body_entered(body) -> void:
	if body == player:
		player_in_area = true
		timer.start()


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_area = false
		timer.stop()
