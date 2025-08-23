extends Node2D

@onready var final_walls: TileMap = $final_walls
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var final_boss: CharacterBody2D = $FinalBoss
@onready var exit: Area2D = $Exit
@onready var door: Area2D = $Door

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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
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
