extends PanelContainer

var session_id: String
var player: String

@onready var label = %Label


func setup(_session_id: String, server_name: String, player_name: String):
	session_id = _session_id
	label.text = server_name
	player = player_name


func _on_join_button_pressed() -> void:
	SessionManager.join_session(session_id, player)
