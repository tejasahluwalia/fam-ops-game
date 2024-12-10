extends Node3D
class_name EnemySpawner

var _enemy_scene = preload("res://characters/enemies/melee/minion/EnemyMinion.tscn")
@export var enemy_spawn_marker: Marker3D
@export var enemy_spawn_node: Node3D
@onready var enemy_spawner: MultiplayerSpawner = $EnemySpawner


func _ready() -> void:
	if enemy_spawn_node:
		enemy_spawner.spawn_path = enemy_spawn_node.get_path()
	else:
		print("No enemy spawn node set.")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func spawn_enemies() -> void:
	var minion: EnemyEntity = _enemy_scene.instantiate()
	minion.global_transform = enemy_spawn_marker.global_transform
	enemy_spawn_node.call_deferred("add_child", minion, true)
