extends Node2D

signal room_completed

func _on_Door_body_entered(body):
	if body.name == "Player":
		emit_signal("room_completed")
