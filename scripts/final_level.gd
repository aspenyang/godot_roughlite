extends Node2D

@onready var final_walls: TileMap = $final_walls
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var final_boss: CharacterBody2D = $FinalBoss
@onready var exit: Area2D = $Exit
@onready var door: Area2D = $Door

# Overlay UI for ending transition
@onready var overlay: CanvasLayer = $Overlay
@onready var color_rect: ColorRect = $Overlay/ColorRect
@onready var ending_text: Label = $Overlay/EndingText

const main_layer = 0
const SOURCE_ID = 0
const wall_atlas_coords = Vector2i(6, 2)

@export var y_dim = 43
@export var x_dim = 43


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	draw_walls()
	spawn_point.position = final_walls.map_to_local(Vector2i(x_dim/2, y_dim - 1))
	door.position = final_walls.map_to_local(Vector2i(x_dim/2, y_dim))
	exit.position = final_walls.map_to_local(Vector2i(x_dim/2, 0))
	exit.visible = false
	final_boss.position = final_walls.map_to_local(Vector2i(x_dim/2, y_dim/2))
	
	color_rect.visible = false



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Shows the ending transition: fade in, show text, then go to main menu
func show_ending():
	# Only handles boss victory transition in final level
	color_rect.color = Color(0.2, 0.8, 0.4, 1)  # Joyful color, alpha 0
	color_rect.modulate.a = 0  # Start fully transparent
	ending_text.text = "Congratulations!"
	ending_text.visible = false
	color_rect.visible = true
	# Fade in the color_rect
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.5, 1.5)
	tween.tween_callback(Callable(self, "_on_veil_faded_in"))
	tween.play()

# Called after the veil has faded in
func _on_veil_faded_in():
	ending_text.visible = true
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	
func draw_walls():
	final_walls.clear()
	#tilemap.set_cell(main_layer, pos, SOURCE_ID, normal_wall_atlas_coords)
	for y in range(0, y_dim + 1): # x = 0
		final_walls.set_cell(main_layer, Vector2i(0, y), SOURCE_ID, wall_atlas_coords)
	for y in range(0, y_dim + 1): # x = x_dim
		final_walls.set_cell(main_layer, Vector2i(x_dim, y), SOURCE_ID, wall_atlas_coords)
	for x in range(0, x_dim + 1):
		final_walls.set_cell(main_layer, Vector2i(x, 0), SOURCE_ID, wall_atlas_coords)
	for x in range(0, x_dim +1 ):
		final_walls.set_cell(main_layer, Vector2i(x, y_dim), SOURCE_ID, wall_atlas_coords)
