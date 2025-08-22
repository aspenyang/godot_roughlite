extends CharacterBody2D
class_name Entity

@onready var health: Health = $Health
@export var max_health: int


func _ready():
	health.set_max_health(max_health)
	health.connect("died", Callable(self, "_on_die"))
	health.connect("health_changed", Callable(self, "_on_health_changed"))

func _on_die():
	die()

func die():
	print("%s died" % self.name)
	queue_free()
	
func _on_health_changed(new_health: int):
	print("%s health changed to %d" % [name, new_health])
