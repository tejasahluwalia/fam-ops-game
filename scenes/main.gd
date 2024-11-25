extends Node3D

var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene
@export var buttons: Array[Button]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("dedicated_server"):
		MultiplayerManager.start_server()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_join_button_pressed() -> void:
	MultiplayerManager.join_game()
	remove_buttons()


func remove_buttons() -> void:
	for button in buttons:
		button.queue_free()
