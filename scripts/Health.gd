extends Node
class_name Health

@export var max_health : int
var current_health: int

signal health_changed(new_health: int)
signal died

func _ready():
	if current_health <= 0:
		current_health = max_health
		
func set_max_health(value: int, reset: bool = true):
	max_health = value
	if reset:
		current_health = max_health
		emit_signal("health_changed", current_health)
		
func take_damage(damage: int):
	if damage <= 0:
		return
	current_health = max(0, current_health - damage)
	emit_signal("health_changed", current_health)
	if current_health <= 0:
		emit_signal("died")
		
func heal(amount: int):
	if amount <= 0:
		return
	current_health = min(max_health, current_health + amount)
	emit_signal("health_changed", current_health)
