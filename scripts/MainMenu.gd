extends Control  # Or whatever your root node is

@onready var new_game: Button = $CenterContainer/VBoxContainer/NewGame
@onready var load_game: Button = $CenterContainer/VBoxContainer/LoadGame
@onready var exit_game: Button = $CenterContainer/VBoxContainer/ExitGame
@onready var slot1: Button = $CenterContainer/VBoxContainer/Slots/Slot1
@onready var slot2: Button = $CenterContainer/VBoxContainer/Slots/Slot2
@onready var slot3: Button = $CenterContainer/VBoxContainer/Slots/Slot3

var _selected_slot: int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	new_game.pressed.connect(_on_start_pressed)
	load_game.pressed.connect(_on_load_pressed)
	exit_game.pressed.connect(_on_exit_pressed)
	# Require slot selection before enabling New Game
	new_game.disabled = true

	# Make slot buttons togglable for visual feedback
	slot1.toggle_mode = true
	slot2.toggle_mode = true
	slot3.toggle_mode = true

	slot1.pressed.connect(func(): _on_slot_pressed(1))
	slot2.pressed.connect(func(): _on_slot_pressed(2))
	slot3.pressed.connect(func(): _on_slot_pressed(3))

func _on_slot_pressed(slot: int) -> void:
	_selected_slot = slot
	Globals.slot = slot
	new_game.disabled = false
	_update_slot_visuals()

func _update_slot_visuals() -> void:
	slot1.button_pressed = (_selected_slot == 1)
	slot2.button_pressed = (_selected_slot == 2)
	slot3.button_pressed = (_selected_slot == 3)

# Start a new game
func _on_start_pressed():
	# Replace "res://scenes/main.tscn" with your main game scene path
	Globals.new_game = true
	# Print selected slot for testing
	print("Starting New Game on slot ", Globals.slot)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

# Load game (placeholder for now)
func _on_load_pressed():
	# Show a message or implement load logic later
	Globals.new_game = false
	#print(Globals.new_game)
	#print("Load Game pressed (feature coming soon)")
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	

# Exit the game
func _on_exit_pressed():
	get_tree().quit()
