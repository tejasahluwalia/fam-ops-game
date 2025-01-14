extends Control


var lobby_scene = load("res://scenes/lobby/lobby.tscn")
var session_browser_scene = load("res://scenes/session_browser/session_browser.tscn")

@onready var server_name: LineEdit = $HostLobbyInputPanel/MarginContainer/VBoxContainer/ServerName
@onready var host_name: LineEdit = $HostLobbyInputPanel/MarginContainer/VBoxContainer/PlayerName
@onready var host_lobby_input_panel: PanelContainer = $HostLobbyInputPanel
@onready var join_lobby_input_panel: PanelContainer = $JoinLobbyInputPanel
@onready var player_name: LineEdit = $JoinLobbyInputPanel/MarginContainer/VBoxContainer/PlayerName


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SessionManager.session_created.connect(_on_session_created)


func _on_join_button_pressed() -> void:
	join_lobby_input_panel.visible = true


func _on_join_submit_button_pressed() -> void:
	var session_browser = session_browser_scene.instantiate()
	session_browser.player_name = player_name.text
	self.get_parent().add_child(session_browser)
	queue_free()


func _on_host_button_pressed() -> void:
	host_lobby_input_panel.visible = true


func _on_session_created(_session_id: String) -> void:
	var lobby = lobby_scene.instantiate()
	self.get_parent().add_child(lobby)
	queue_free()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_host_submit_button_pressed() -> void:
	if server_name.text != "" and host_name.text != "":
		SessionManager.create_session(server_name.text, host_name.text)
