extends Node2D

@onready var label: Label = $Background/Label
@onready var background: Panel = $Background
@onready var hide_timer: Timer = $HideTimer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func show_text(text: String, duration: float = 1.0, font_size: int = 8, text_color: Color = Color(1,1,1)):
	# Set text and font size
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", text_color)

	# Update size of background
	label.custom_minimum_size = Vector2.ZERO  # reset min_size
	label.scale = Vector2.ONE                 # reset scale

	# Wait for next frame to ensure font size change is applied
	await get_tree().process_frame
	
	# Get the actual size needed for the text with the new font size
	var font = label.get_theme_font("font")
	label.position = Vector2(8,6)
	label.size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	background.size = label.size + Vector2(16, 12)  # add padding
	
	visible = true
	hide_timer.wait_time = duration
	hide_timer.start()


func _on_hide_timer_timeout() -> void:
	visible = false
