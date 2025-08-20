extends CharacterBody2D
# This version is to handle tile by tile movement


var speed = 300  # Movement speed in pixels/second (for free movement)
var sprint_speed = 600
var movement = Vector2.ZERO

var tile_size: int = 16  # Default fallback
var moving = false
var target_position = Vector2.ZERO

var current_room_scene_path = ""

var current_scene = null

func _ready() -> void:
	Globals.player = $"."  # keep your original assignment if needed

	# Try to get tile_size from the current room's TileMap
	#var current_room = get_parent()
	#if current_room and current_room.has_node("TileMap"):
		#var tilemap = current_room.get_node("TileMap") as TileMap
		#tile_size = tilemap.cell_size.x  # assuming square tiles

	target_position = global_position

func set_current_room_scene(path: String) -> void:
	current_room_scene_path = path

func set_current_scene(room_scene: Node):
	current_scene = room_scene
	print(current_scene)

func _physics_process(_delta):
	var is_puzzle_scene = current_room_scene_path.ends_with("puzzle_path.tscn")

	if is_puzzle_scene:
		handle_tile_movement(_delta)
	else:
		handle_free_movement(_delta)

func handle_free_movement(_delta):
	movement = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		movement.x += 1
	if Input.is_action_pressed("ui_left"):
		movement.x -= 1
	if Input.is_action_pressed("ui_up"):
		movement.y -= 1
	if Input.is_action_pressed("ui_down"):
		movement.y += 1

	var current_speed = speed
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed

	movement = movement.normalized() * current_speed
	velocity = movement
	move_and_slide()

func handle_tile_movement(_delta):
	if moving:
		var direction = (target_position - global_position).normalized()
		var distance = (target_position - global_position).length()
		var step = speed * _delta
		if step >= distance:
			global_position = target_position
			moving = false
			
			# --- New code here: notify room that player stepped on a tile ---
			#var current_room = get_parent()
			print(current_scene)
			var tilemap = current_scene.get_node("TileMap") as TileMap
			var tile_pos = tilemap.local_to_map(global_position)
			if current_scene.has_method("player_stepped"):
				current_scene.player_stepped(tile_pos)
			# -------------------------------------------------------------
			
		else:
			global_position += direction * step
	else:
		var input_dir = Vector2.ZERO
		if Input.is_action_just_pressed("ui_right"):
			input_dir.x = 1
		elif Input.is_action_just_pressed("ui_left"):
			input_dir.x = -1
		elif Input.is_action_just_pressed("ui_up"):
			input_dir.y = -1
		elif Input.is_action_just_pressed("ui_down"):
			input_dir.y = 1
		
		if input_dir != Vector2.ZERO:
			target_position = global_position + input_dir * tile_size
			moving = true
	
func flash_hit():
	if $Sprite2D:
		$Sprite2D.modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		$Sprite2D.modulate = Color.WHITE
