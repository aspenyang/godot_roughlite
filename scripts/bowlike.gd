extends Area2D

const arrowlike = preload("res://scenes/Arrowlike.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func fire_arrow():
	var arrowlike_instance = arrowlike.instantiate()
	get_parent().add_child(arrowlike_instance) #add it to the miniboss to prevent rotation issue
	arrowlike_instance.global_position = global_position
	arrowlike_instance.rotation = rotation
