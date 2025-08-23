extends Area2D

@onready var timer: Timer = $Timer
var damage_interval = 0.5
var damage = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.wait_time = damage_interval
	timer.start() # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	pass


func _on_timer_timeout():
	var bodis_in_area = get_overlapping_bodies()
	for body in bodis_in_area:
		if body.has_method("on_hit"):
			body.on_hit(damage)
	
