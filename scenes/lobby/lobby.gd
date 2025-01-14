extends Control

@onready var start_button = %StartButton
@onready var player_list = %PlayerList
@onready var session_name: Label = %SessionName
@onready var timer: Timer = $Timer

var home_menu_scene = load("res://scenes/home_menu/home_menu.tscn")


func _ready():
	SessionManager.session_started.connect(_on_session_started)
	SessionManager.session_joined.connect(_on_player_joined)
	SessionManager.session_error.connect(_on_session_error)
	refresh_player_list()
	start_button.visible = SessionManager.is_host
	session_name.text = SessionManager.lobby_name
	timer.timeout.connect(get_session_details)


func get_session_details() -> void:
	SessionManager.get_session()
	refresh_player_list()


func refresh_player_list():
	# Clear existing items
	for child in player_list.get_children():
		child.queue_free()
	
	# Add new player items
	for player_id in SessionManager.player_list:
		var label = Label.new()
		label.text = player_id
		if player_id == SessionManager.host_id:
			label.text += " (Host)"
		player_list.add_child(label)


func _on_start_button_pressed():
	SessionManager.start_session()


func _on_leave_button_pressed():
	SessionManager.leave_session()
	var home_menu = home_menu_scene.instantiate()
	self.get_parent().add_child(home_menu)
	queue_free()


func _on_session_started(host: String, port: int):
	timer.stop()
	MultiplayerManager.connect_to_server(host, port)
	get_tree().current_scene.get_node("MainMenu").queue_free()


func _on_player_joined(_session_id: String):
	refresh_player_list()


func _on_session_error(message: String):
	print("Session error: " + message)
