extends Node3D

var peer = ENetMultiplayerPeer.new()

@export var main_menu: Control
@export var hud: HUD
@export var player_spawn_node: Node3D
@export var projectile_spawn_node: Node3D
@export var enemies_node: Enemies
@onready var controls = $Controls


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		MultiplayerManager.start_server(player_spawn_node)

	WaveManager.enemies_node = enemies_node
	AudioManager.main_menu_track.play()


func _on_join_button_pressed() -> void:
	MultiplayerManager.join_game()
	_remove_buttons()



	await get_tree().create_timer(3).timeout
	WaveManager.start.rpc_id(1)


func _remove_buttons() -> void:
	main_menu.queue_free()



func _on_quit_button_pressed():
	get_tree().quit()


func _on_controls_button_pressed():
	controls.visible = true


func _on_back_button_pressed():
	controls.visible = false
