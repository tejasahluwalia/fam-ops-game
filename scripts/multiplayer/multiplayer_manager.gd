extends Node

const SERVER_HOST = "127.0.0.1"
const SERVER_PORT = 6060

signal player_instantiated(id: PlayerEntity)

var player_scene = preload("res://characters/player/player_entity.tscn")
var _player_spawn_node


func start_server(player_spawn_node: Node3D):
	_player_spawn_node = player_spawn_node

	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)

	multiplayer.multiplayer_peer = server_peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)


func join_game():
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_HOST, SERVER_PORT)

	multiplayer.multiplayer_peer = client_peer


func _add_player(id: int = 1):
	print("Player %s joined the game." % id)
	var player = player_scene.instantiate()
	player.player_id = id
	player.name = str(id)
	player_instantiated.emit(player)
	_player_spawn_node.call_deferred("add_child", player)


func _remove_player(id: int):
	print("Player disconnected")
	if not _player_spawn_node.has_node(str(id)):
		return
	_player_spawn_node.get_node(str(id)).queue_free()
