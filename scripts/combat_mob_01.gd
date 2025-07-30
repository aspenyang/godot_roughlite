extends Node2D

@export var enemy_scene: PackedScene
@export var enemy_count: int = 3

func _ready():
	spawn_enemies()

func spawn_enemies():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in enemy_count:
		var enemy = enemy_scene.instantiate()
		enemy.position = Vector2(rng.randi_range(64, 256), rng.randi_range(64, 256))
		add_child(enemy)
