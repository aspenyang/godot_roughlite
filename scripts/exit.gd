extends Area2D

signal exit_triggered

@export var interaction_key := "ui_accept"  # default is Enter/Z; you can rebind to "E"
@onready var prompt_label = $Label  # optional label like "Press [E] to exit"

var player_in_range = false
var exit_enabled = true  # set false later when room must be cleared first

func _ready():
	if prompt_label:
		prompt_label.visible = false

func _process(delta):
	if exit_enabled and player_in_range and Input.is_action_just_pressed(interaction_key):
		emit_signal("exit_triggered")

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func set_exit_enabled(enabled: bool):
	exit_enabled = enabled
	if prompt_label:
		prompt_label.visible = player_in_range and enabled
