extends Node2D

@export var interaction_key: String = "ui_accept"

@onready var potion: Area2D = $Potion
@onready var prompt_label: Label = $Potion/Label
var player: Node2D = null
var healAmount: int = 0
@export var min_heal: int = 15
@export var max_heal: int = 50
var player_in_range: bool = false
var consumed: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = Globals.player
	healAmount = randi_range(min_heal, max_heal)
	if prompt_label:
		prompt_label.text = "Press [E] to take heal potion"
		prompt_label.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if potion and player_in_range and Input.is_action_just_pressed(interaction_key):
		take_potion(healAmount)

func take_potion(amount: int):
	player.get_node("Health").heal(amount)
	potion.queue_free()

func _on_potion_body_entered(body: Node2D) -> void:
	if body == player:
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true


func _on_potion_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false
