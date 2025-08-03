extends Node2D 

@export var enemy_count: int = 3
@onready var nav_region = $NavigationRegion2D

func _ready():
	# Wait a frame for navigation to be properly set up
	call_deferred("spawn_enemies")

func spawn_enemies():
	if not nav_region:
		print("Error: NavigationRegion2D not found!")
		return
		
	var nav_poly = nav_region.navigation_polygon
	if not nav_poly:
		print("Error: NavigationPolygon not assigned to NavigationRegion2D!")
		return
	
	print("Spawning ", enemy_count, " ranged enemies...")
	
	for i in range(enemy_count):
		spawn_ranged_enemy(nav_poly)

func spawn_ranged_enemy(nav_poly: NavigationPolygon):
	var enemy_scene = preload("res://scenes/RangedEnemy.tscn")
	var bomb_scene = preload("res://scenes/bomb.tscn")
	
	if not enemy_scene:
		print("Error: Could not load RangedEnemy.tscn")
		return
	if not bomb_scene:
		print("Error: Could not load bomb.tscn")
		return
	
	var enemy = enemy_scene.instantiate()
	var spawn_pos = get_random_point_inside_polygon(nav_poly)
	
	# Ensure spawn position is valid
	if spawn_pos == Vector2.ZERO:
		print("Warning: Could not find valid spawn position, using fallback")
		spawn_pos = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	
	enemy.global_position = spawn_pos
	enemy.bomb_scene = bomb_scene
	
	add_child(enemy)
	print("Spawned ranged enemy at: ", spawn_pos)

func get_random_point_inside_polygon(nav_poly: NavigationPolygon) -> Vector2:
	var points = nav_poly.get_vertices()
	if points.is_empty():
		print("Warning: NavigationPolygon has no vertices!")
		return Vector2.ZERO
	
	var rect = get_navigation_polygon_bounds(nav_poly)
	if rect.size.x <= 0 or rect.size.y <= 0:
		print("Warning: Invalid navigation polygon bounds!")
		return Vector2.ZERO
	
	# Try to find a valid point (increased attempts)
	for i in range(100):
		var point = Vector2(
			randf_range(rect.position.x, rect.position.x + rect.size.x),
			randf_range(rect.position.y, rect.position.y + rect.size.y)
		)
		if is_point_in_polygon(point, points):
			return point
	
	print("Warning: Could not find valid spawn point after 100 attempts")
	return rect.get_center()  # Return center as fallback

func get_navigation_polygon_bounds(nav_poly: NavigationPolygon) -> Rect2:
	var points = nav_poly.get_vertices()
	if points.is_empty():
		return Rect2()
	
	var min_pos = points[0]
	var max_pos = points[0]
	
	for point in points:
		min_pos.x = min(min_pos.x, point.x)
		min_pos.y = min(min_pos.y, point.y)
		max_pos.x = max(max_pos.x, point.x)
		max_pos.y = max(max_pos.y, point.y)
	
	return Rect2(min_pos, max_pos - min_pos)

func is_point_in_polygon(point: Vector2, polygon: Array) -> bool:
	var inside = false
	var j = polygon.size() - 1
	
	for i in range(polygon.size()):
		var pi = polygon[i]
		var pj = polygon[j]
		
		if ((pi.y > point.y) != (pj.y > point.y)) and \
		   (point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y) + pi.x):
			inside = not inside
		j = i
	
	return inside
