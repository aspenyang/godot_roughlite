extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#connect("body_entered", Callable(self, "_on_body_entered"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body) -> void:
	print(body)
	if body.is_in_group("enemies"):
		body.on_hit()
		print("hit")
