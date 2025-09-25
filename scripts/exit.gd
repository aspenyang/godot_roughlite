extends Area2D

signal exit_triggered

@export var interaction_key := "ui_accept"  # default is Enter/Z; you can rebind to "E"
@onready var prompt_label = $Label  # optional label like "Press [E] to exit"

var player_in_range = false
var exit_enabled = true  # set false later when room must be cleared first
var locked_color := Color(1,1,1,0.35)
var unlocked_color := Color(1,1,1,1)
@onready var sprite_2d: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready():
	if prompt_label:
		prompt_label.visible = false
	_update_visuals()

func _process(_delta):
	if exit_enabled and player_in_range and Input.is_action_just_pressed(interaction_key):
		emit_signal("exit_triggered")

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		if prompt_label:
			prompt_label.visible = exit_enabled  # only if interactive

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func set_exit_enabled(enabled: bool):
	exit_enabled = enabled
	_update_visuals()

func _update_visuals():
	# Label logic
	if prompt_label:
		if exit_enabled:
			prompt_label.text = "Press [E] to exit"
			prompt_label.visible = player_in_range
		else:
			prompt_label.visible = false
	# Tint sprite if exists
	if sprite_2d:
		sprite_2d.modulate = unlocked_color if exit_enabled else locked_color
