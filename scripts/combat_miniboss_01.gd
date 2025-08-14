extends Node2D

@onready var miniboss_walls: TileMap = $Miniboss_walls
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var mini_boss: CharacterBody2D = $MiniBoss
@onready var exit: Area2D = $Exit
@onready var door: Area2D = $Door

const main_layer = 0
const SOURCE_ID = 0
const wall_atlas_coords = Vector2i(6, 1)

@export var y_dim = 31
@export var x_dim = 31


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	draw_walls()
	spawn_point.position = miniboss_walls.map_to_local(Vector2i(1, y_dim/2))
	mini_boss.position = miniboss_walls.map_to_local(Vector2i(x_dim/2, y_dim/2))
	door.position = miniboss_walls.map_to_local(Vector2i(0, y_dim/2))
	exit.position = miniboss_walls.map_to_local(Vector2i(x_dim, y_dim/2))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func draw_walls():
	#tilemap.set_cell(main_layer, pos, SOURCE_ID, normal_wall_atlas_coords)
	for y in range(0, y_dim + 1): # x = 0
		miniboss_walls.set_cell(main_layer, Vector2i(0, y), SOURCE_ID, wall_atlas_coords)
	for y in range(0, y_dim + 1): # x = x_dim
		miniboss_walls.set_cell(main_layer, Vector2i(x_dim, y), SOURCE_ID, wall_atlas_coords)
	for x in range(0, x_dim + 1):
		miniboss_walls.set_cell(main_layer, Vector2i(x, 0), SOURCE_ID, wall_atlas_coords)
	for x in range(0, x_dim +1 ):
		miniboss_walls.set_cell(main_layer, Vector2i(x, y_dim), SOURCE_ID, wall_atlas_coords)
