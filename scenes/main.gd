extends Node3D

var peer = ENetMultiplayerPeer.new()

@onready var game_over: Control = $GameOver
@onready var game_win: Control = $GameWin

@export var hud: HUD
@export var player_spawn_node: Node3D
@export var projectile_spawn_node: Node3D
@export var enemies_node: Enemies

var alive_player_list = []

var home_menu_scene = preload("res://scenes/home_menu/home_menu.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		MultiplayerManager.start_server(player_spawn_node)
	else:
		var home_menu = home_menu_scene.instantiate()
		get_node("MainMenu/MarginContainer").add_child(home_menu)

	WaveManager.enemies_node = enemies_node
	AudioManager.main_menu_track.play()
	WaveManager.all_waves_survived.connect(_game_won.rpc)


@rpc("authority", "call_remote", "reliable", 0)
func _game_won():
	hud.visible = false
	game_win.visible = true


@rpc("authority", "call_remote", "reliable", 0)
func _game_lost():
	hud.visible = false
	game_over.visible = true


func _on_player_entered_tree(node: Node) -> void:
	node.ready.connect(_on_player_ready.bind(node))


func _on_player_ready(node: Node) -> void:
	if node is PlayerEntity:
		alive_player_list.append(node.player_id)
		node.is_dead.connect(_on_player_death)
		print(alive_player_list)


func _on_player_death(player_id: int) -> void:
	if multiplayer.is_server():
		alive_player_list.remove_at(alive_player_list.find(player_id))
		print(alive_player_list)
		if len(alive_player_list) == 0:
			_game_lost.rpc()
