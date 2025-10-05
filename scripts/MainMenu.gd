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
	# Require slot selection + existing save before enabling Load Game
	load_game.disabled = true

	# Make slot buttons togglable for visual feedback
	slot1.toggle_mode = true
	slot2.toggle_mode = true
	slot3.toggle_mode = true

	slot1.pressed.connect(func(): _on_slot_pressed(1))
	slot2.pressed.connect(func(): _on_slot_pressed(2))
	slot3.pressed.connect(func(): _on_slot_pressed(3))

	# Populate initial slot labels from existing save files
	_refresh_slot_labels()

func _on_slot_pressed(slot: int) -> void:
	_selected_slot = slot
	Globals.slot = slot
	new_game.disabled = false
	_update_load_enabled()
	_update_slot_visuals()

func _update_slot_visuals() -> void:
	slot1.button_pressed = (_selected_slot == 1)
	slot2.button_pressed = (_selected_slot == 2)
	slot3.button_pressed = (_selected_slot == 3)

func _update_load_enabled() -> void:
	if _selected_slot <= 0:
		load_game.disabled = true
		return
	var path := SaveManagerV2._get_save_path(_selected_slot)
	load_game.disabled = not FileAccess.file_exists(path)

func _refresh_slot_labels() -> void:
	slot1.text = _build_slot_label(1)
	slot2.text = _build_slot_label(2)
	slot3.text = _build_slot_label(3)

func _build_slot_label(slot: int) -> String:
	var base := "Save %d" % slot
	var path := SaveManagerV2._get_save_path(slot)
	if not FileAccess.file_exists(path):
		return base + ": empty"

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return base + ": (unreadable)"
	var txt := f.get_as_text()
	f.close()
	var d = JSON.parse_string(txt)
	if typeof(d) != TYPE_DICTIONARY:
		return base + ": (invalid)"

	var runs_completed := int(d.get("completed_runs", 0))
	var in_progress := false
	if d.has("in_progress"):
		in_progress = bool(d["in_progress"])
	if in_progress:
		var levels_completed := int(d.get("levels_completed", 0))
		var levels_total := int(d.get("levels_total", 0))
		return "%s: in progress %d/%d, run: %d" % [base, levels_completed, levels_total, runs_completed + 1]
	else:
		return "%s: run: %d" % [base, runs_completed + 1]

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
