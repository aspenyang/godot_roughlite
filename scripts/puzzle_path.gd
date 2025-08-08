extends Node2D

# Tile data
const WALL_SOURCE_ID = 0
const WALL_ATLAS_COORDS = Vector2i(6, 1)

const FLOOR_SOURCE_ID = 3
const FLOOR_ATLAS_COORDS = Vector2i(7, 1)

# Room size (including walls)
const ROOM_WIDTH = 35
const ROOM_HEIGHT = 17

# Main layer index
const MAIN_LAYER = 0

# Node references
@onready var tilemap: TileMap = $TileMap
@onready var door = $Door
@onready var exit_door = $Exit
@onready var spawn_point = $SpawnPoint

func _ready():
	draw_room()
	place_entry_exit_spawn()
	
func draw_room():
	tilemap.clear()
	for x in range(ROOM_WIDTH):
		for y in range(ROOM_HEIGHT):
			var pos = Vector2i(x, y)
			if x == 0 or x == ROOM_WIDTH - 1 or y == 0 or y == ROOM_HEIGHT - 1:
				tilemap.set_cell(MAIN_LAYER, pos, WALL_SOURCE_ID, WALL_ATLAS_COORDS)
			else:
				tilemap.set_cell(MAIN_LAYER, pos, FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS)

func place_entry_exit_spawn():
	# Tile positions
	var entry_tile = Vector2i(0, ROOM_HEIGHT / 2)
	var exit_tile = Vector2i(ROOM_WIDTH - 2, ROOM_HEIGHT / 2) # Right next to wall
	var spawn_tile = Vector2i(1, ROOM_HEIGHT / 2)

	# Convert to world positions
	var entry_pos = tilemap.map_to_local(entry_tile)
	var exit_pos = tilemap.map_to_local(exit_tile)
	var spawn_pos = tilemap.map_to_local(spawn_tile)

	# Assign positions
	door.position = entry_pos
	exit_door.position = exit_pos
	spawn_point.position = spawn_pos
