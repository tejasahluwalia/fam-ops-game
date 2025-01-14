extends Node

signal wave_started(wave_number: int)

var enemies_node: Enemies
var spawn_points: Array[Marker3D] = []
var is_wave_active: bool = false

var TIME_BETWEEN_WAVES: float = 4.0

var _current_wave: Dictionary = {
	"wave_number": 0,
	"spawns_remaining": {}
}

# flow_rate is seconds per spawn
var _wave_tiers: Dictionary = {
	1: {
		"range": [1, 1],
		"base_spawn": {
			"minion": {
				"tier": 1,
				"quantity": 4,
				"flow_rate": 1,
				"spawn_points": ["SW", "SE"]
			}
		}
	},
	2: {
		"range": [2, 4],
		"base_spawn": {
			"minion": {
				"tier": 1,
				"quantity": 12,
				"flow_rate": 0.75,
				"spawn_points": ["SW", "SE"]
			},
			"chaser": {
				"tier": 1,
				"quantity": 6,
				"flow_rate": 4,
				"spawn_points": ["NW", "NE"]
			}
		}
	},
	3: {
		"range": [5, 8],
		"base_spawn": {
			"minion": {
				"tier": 1,
				"quantity": 25,
				"flow_rate": 0.5,
				"spawn_points": ["SW", "SE"]
			},
			"chaser": {
				"tier": 1,
				"quantity": 12,
				"flow_rate": 4,
				"spawn_points": ["NW", "NE"]
			}
		}
	},
	4: {
		"range": [9, 14],
		"base_spawn": {
			"minion": {
				"tier": 1,
				"quantity": 35,
				"flow_rate": 0.5,
				"spawn_points": ["SW", "SE"]
			},
			"chaser": {
				"tier": 1,
				"quantity": 18,
				"flow_rate": 2,
				"spawn_points": ["NW", "NE"]
			}
		}
	},
	5: {
		"range": [15, 20],
		"base_spawn": {
			"minion": {
				"tier": 1,
				"quantity": 50,
				"flow_rate": 0.5,
				"spawn_points": ["SW", "SE"]
			},
			"chaser": {
				"tier": 1,
				"quantity": 20,
				"flow_rate": 2,
				"spawn_points": ["NW", "NE"]
			}
		}
	}
}


func _process(_delta: float) -> void:
	if multiplayer and multiplayer.is_server():
		var _spawns_remaining: int = 0
		if _current_wave.wave_number > 0:
			for _n in _current_wave.spawns_remaining.values():
				_spawns_remaining += _n
			if _spawns_remaining <= 0 and _enemies_remaining() <= 0 and is_wave_active:
				_end_wave()
	pass


@rpc("any_peer", "reliable", "call_remote", 0)
func start() -> void:
	if _current_wave.wave_number == 0:
		start_next_wave()


func start_next_wave() -> void:
	_current_wave.wave_number += 1
	wave_started.emit(_current_wave.wave_number)
	
	var _attrs = _get_wave_attributes()

	if _attrs.has("error"):
		print(_attrs["error"])
		return

	print("Starting wave: ", _current_wave.wave_number)
	for _enemy_name in _attrs.base_spawn.keys():
		var _enemy = _attrs.base_spawn[_enemy_name]
		_current_wave.spawns_remaining[_enemy_name] = _enemy.quantity
		var _timer = Timer.new()
		_timer.wait_time = _enemy.flow_rate
		_timer.timeout.connect(
			_on_enemy_spawn_timeout.bind(_enemy_name, _enemy.spawn_points, _timer, _enemy.quantity)
		)
		get_tree().current_scene.call_deferred("add_child", _timer)
		_timer.autostart = true

	is_wave_active = true


func _on_enemy_spawn_timeout(
	_enemy_name: StringName, _markers, _timer: Timer, _max_spawns: int
) -> void:
	if _current_wave.spawns_remaining[_enemy_name] > 0:
		_current_wave.spawns_remaining[_enemy_name] -= 1
		var _marker_name = _markers[
			(_max_spawns - _current_wave.spawns_remaining[_enemy_name]) % len(_markers)
		]
		var _marker = spawn_points.filter(func(m): return m.name == _marker_name)[0]
		enemies_node.spawn_enemy(_enemy_name, _marker)
		print("Spawning Enemy")
	else:
		_timer.stop()
		print("Stopped spawning")


func _end_wave() -> void:
	print("Ending wave: ", _current_wave.wave_number)
	is_wave_active = false
	await get_tree().create_timer(TIME_BETWEEN_WAVES).timeout
	start_next_wave()


func _enemies_remaining() -> int:
	return enemies_node.get_child_count() - 1


func _get_wave_attributes() -> Dictionary:
	for wave_tier in _wave_tiers.values():
		var wave_tier_range = wave_tier.range
		if (
			wave_tier_range[0] <= _current_wave.wave_number
			and _current_wave.wave_number <= wave_tier_range[1]
		):
			return wave_tier
	return {"error": "Could not find wave attributes."}
