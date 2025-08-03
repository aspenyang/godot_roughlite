extends Node2D

@export var radius: float = 64.0
@export var color: Color = Color(1, 0, 0, 0.3) # red, 30% opacity

func _draw():
	draw_circle(Vector2.ZERO, radius, color)

func set_radius(r):
	radius = r
	queue_redraw()
