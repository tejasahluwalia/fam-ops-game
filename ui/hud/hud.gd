extends Control
class_name HUD

@onready var points_display: Label = $PointsDisplay
@onready var health_display: Control = $HealthDisplay


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
