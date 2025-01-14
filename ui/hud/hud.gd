extends Control
class_name HUD

@onready var points_display: Label = $PointsDisplay
@onready var health_display: Control = $HealthDisplay
@onready var wave_status: Label = $WaveStatus


func _ready() -> void:
	WaveManager.wave_started.connect(_on_wave_started)


func _on_wave_started(wave_number: int) -> void:
	_update_wave_counter.rpc("Wave " + str(wave_number))


@rpc("call_remote", "authority", "reliable", 0)
func _update_wave_counter(text: String) -> void:
	wave_status.text = text


func _on_player_entered_tree(node: Node) -> void:
	node.ready.connect(_on_player_ready.bind(node))


func _on_player_ready(node: Node) -> void:
	if multiplayer and not multiplayer.is_server():
		if node is PlayerEntity:
			if node.player_id == multiplayer.get_unique_id():
				points_display.set_player(node)
				health_display.set_player(node)
			else:
				health_display.set_teammate(node)
