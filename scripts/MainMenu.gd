extends Control  # Or whatever your root node is

@onready var new_game: Button = $CenterContainer/VBoxContainer/NewGame
@onready var load_game: Button = $CenterContainer/VBoxContainer/LoadGame
@onready var exit_game: Button = $CenterContainer/VBoxContainer/ExitGame


# Called when the node enters the scene tree for the first time.
func _ready():
	new_game.pressed.connect(_on_start_pressed)
	load_game.pressed.connect(_on_load_pressed)
	exit_game.pressed.connect(_on_exit_pressed)

# Start a new game
func _on_start_pressed():
	# Replace "res://scenes/main.tscn" with your main game scene path
	get_tree().change_scene_to_file("res://scenes/main.tscn")

# Load game (placeholder for now)
func _on_load_pressed():
	# Show a message or implement load logic later
	print("Load Game pressed (feature coming soon)")

# Exit the game
func _on_exit_pressed():
	get_tree().quit()
