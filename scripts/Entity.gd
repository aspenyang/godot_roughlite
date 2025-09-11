extends CharacterBody2D
class_name Entity

@onready var health: Health = $Health
@onready var health_bar: ProgressBar = $HealthBar
@export var max_health: int


func _ready():
	health.set_max_health(max_health)
	health.connect("died", Callable(self, "_on_die"))
	health.connect("health_changed", Callable(self, "_on_health_changed"))
	if health_bar:
		setup_health_bar()

func _on_die():
	die()

func die():
	print("%s died" % self.name)
	queue_free()
	
func _on_health_changed(new_health: int):
	print("%s health changed to %d" % [name, new_health])
	
	# Update health bar
	if health_bar:
		health_bar.value = new_health
	
func setup_health_bar():
	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = max_health
	
	# Position health bar above entity (adjust offset as needed)
	health_bar.position = Vector2(-20, -30)  # Centered above entity
	health_bar.size = Vector2(40, 6)  # Small health bar size
	
	# Style the health bar
	health_bar.show_percentage = false
