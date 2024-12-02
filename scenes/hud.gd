extends Control
class_name HUD

@export var points_display: Label


func _on_player_spawn_node_child_entered_tree(node: Node) -> void:
	if !multiplayer.is_server():
		if node is PlayerEntity:
			if node.name == str(multiplayer.get_unique_id()):
				points_display.set_player(node)
