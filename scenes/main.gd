extends Node3D

var peer = ENetMultiplayerPeer.new()

@export var hud: HUD
@export var player_spawn_node: Node3D
@export var projectile_spawn_node: Node3D
@export var enemies_node: Enemies

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
