extends Node

const SERVER_HOST = "192.168.1.16"
const SERVER_PORT = 6060

var player_scene = preload("res://characters/player/PlayerEntity.tscn")
var _player_spawn_path


func start_server():
	_player_spawn_path = get_tree().get_current_scene().get_node("PlayerSpawnPath")
	
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	
	multiplayer.multiplayer_peer = server_peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)


func join_game():
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_HOST, SERVER_PORT)
	
	multiplayer.multiplayer_peer = client_peer


func _add_player(id: int):
	print("Player %s joined the game."%id)
	var player = player_scene.instantiate()
	player.player_id = id
	player.name = str(id)
	_player_spawn_path.call_deferred("add_child", player)


func _remove_player(id: int):
	print("Player disconnected")
	if not _player_spawn_path.has_node(str(id)):
		return
	_player_spawn_path.get_node(str(id)).queue_free()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
