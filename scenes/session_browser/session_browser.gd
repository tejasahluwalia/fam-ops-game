extends Control

var session_item_scene = load("res://scenes/session_browser/session_item.tscn")
var lobby_scene = load("res://scenes/lobby/lobby.tscn")
var home_menu_scene = load("res://scenes/home_menu/home_menu.tscn")

var player_name: StringName = ""

@onready var session_list = %SessionList


func _ready():
	SessionManager.session_list_updated.connect(_on_session_list_updated)
	SessionManager.session_joined.connect(_on_session_joined)
	SessionManager.session_error.connect(_on_session_error)
	refresh_sessions()


func refresh_sessions():
	# Clear existing items
	for child in session_list.get_children():
		child.queue_free()
	
	SessionManager.list_sessions()


func _on_session_list_updated(sessions: Array):
	for session in sessions:
		var item = session_item_scene.instantiate()
		session_list.add_child(item)
		item.setup(
			session.session_id,
			session.server_name,
			player_name
		)


func _on_session_joined(_session_id: String):
	var lobby = lobby_scene.instantiate()
	get_parent().add_child(lobby)
	queue_free()


func _on_session_error(message: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()


func _on_refresh_button_pressed() -> void:
	refresh_sessions()


func _on_back_button_pressed() -> void:
	var home_menu = home_menu_scene.instantiate()
	self.get_parent().add_child(home_menu)
	queue_free()
