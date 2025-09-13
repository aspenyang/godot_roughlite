extends Node

var overlay: CanvasLayer = null
var color_rect: ColorRect = null
var death_label: Label = null

func show_death_transition():
	# Create overlay CanvasLayer
	overlay = CanvasLayer.new()
	get_tree().current_scene.add_child(overlay)

	# Create ColorRect (black, 0 alpha)
	color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 1)
	color_rect.modulate.a = 0
	color_rect.anchor_left = 0
	color_rect.anchor_top = 0
	color_rect.anchor_right = 1
	color_rect.anchor_bottom = 1
	color_rect.offset_left = 0
	color_rect.offset_top = 0
	color_rect.offset_right = 0
	color_rect.offset_bottom = 0
	overlay.add_child(color_rect)

	# Create Label ("You die")
	death_label = Label.new()
	death_label.text = "You die"
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	death_label.anchor_left = 0
	death_label.anchor_top = 0
	death_label.anchor_right = 1
	death_label.anchor_bottom = 1
	death_label.offset_left = 0
	death_label.offset_top = 0
	death_label.offset_right = 0
	death_label.offset_bottom = 0
	death_label.visible = false
	overlay.add_child(death_label)

	# Fade in ColorRect
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.7, 1.5)
	tween.tween_callback(Callable(self, "_on_death_fade_in"))
	tween.play()

func _on_death_fade_in():
	if is_instance_valid(death_label):
		death_label.visible = true
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
