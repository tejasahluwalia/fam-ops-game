extends Node3D
class_name Enemies

var _minion_scene = preload("res://characters/enemies/melee/minion/EnemyMinion.tscn")
var _chaser_scene = preload("res://characters/enemies/melee/minion/ChaserMinion.tscn")

var _enemy_scene_map = {
	"minion" = _minion_scene,
	"chaser" = _chaser_scene
}

func spawn_enemy(enemy_name: StringName, marker: Marker3D) -> void:
	var _enemy_scene = _enemy_scene_map[enemy_name]
	
	if not _chaser_scene:
		print("Error getting enemy scene.")
		return
	
	var enemy = _enemy_scene.instantiate()
	enemy.global_transform = marker.global_transform
	call_deferred("add_child", enemy, true)
