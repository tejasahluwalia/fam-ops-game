extends Node

const SERVER_HOST = "localhost"
const SERVER_PORT = 6060

signal player_instantiated(id: PlayerEntity)

var player_scene = preload("res://characters/player/player_entity.tscn")
var _player_spawn_node
var _http_request: HTTPRequest

# AWS GameServer variables
var _update_timer: Timer
var _player_count = 0


func _ready():
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	
	if ServerConfig.is_aws_mode():
		_setup_aws_server()


func _setup_aws_server():
	# Create update timer for health checks
	_update_timer = Timer.new()
	_update_timer.wait_time = 60.0  # 60 seconds
	_update_timer.connect("timeout", _send_server_update)
	add_child(_update_timer)
	
	# Register server
	var register_data = {
		"instance_id": ServerConfig.instance_id,
		"server_id": ServerConfig.server_id,
		"port": SERVER_PORT,
		"public_hostname": ServerConfig.public_hostname
	}
	
	_http_request.connect("request_completed", _on_register_completed)
	var error = _http_request.request(
		ServerConfig.API_ENDPOINT + "/register-game-server",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(register_data)
	)
	if error != OK:
		printerr("Failed to register server")


func start_server(player_spawn_node: Node3D):
	_player_spawn_node = player_spawn_node

	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)

	multiplayer.multiplayer_peer = server_peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)


func connect_to_server(host: String, port: int):
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(host, port)
	multiplayer.multiplayer_peer = client_peer


func _add_player(id: int = 1):
	print("Player %s joined the game." % id)
	_player_count += 1
	
	var player = player_scene.instantiate()
	player.player_id = id
	player.name = str(id)
	player_instantiated.emit(player)
	_player_spawn_node.call_deferred("add_child", player)
	
	WaveManager.start()
	
	if ServerConfig.is_aws_mode():
		_send_server_update()


func _remove_player(id: int):
	print("Player disconnected")
	_player_count -= 1
	
	if _player_spawn_node.has_node(str(id)):
		_player_spawn_node.get_node(str(id)).queue_free()
	
	if ServerConfig.is_aws_mode():		
		# Deregister server if no players left
		if _player_count <= 0:
			var deregister_data = {
				"server_id": ServerConfig.server_id,
				"session_id": SessionManager.current_session_id
			}
			
			# Stop the update timer
			_update_timer.stop()

			# Deregister from GameLift
			_http_request.request(
				ServerConfig.API_ENDPOINT + "/deregister-game-server",
				["Content-Type: application/json"],
				HTTPClient.METHOD_POST,
				JSON.stringify(deregister_data)
			)

			if _http_request.is_connected("request_completed", _on_register_completed):
				_http_request.disconnect("request_completed", _on_register_completed)
			_http_request.connect("request_completed", _on_degregister_completed)
		else:
			_send_server_update()



func _send_server_update():
	if not ServerConfig.is_aws_mode():
		return
		
	var update_data = {
		"server_id": ServerConfig.server_id,
		"session_id": SessionManager.current_session_id,
		"player_count": _player_count,
		"health_status": "HEALTHY",
		#"players": multiplayer.get_peers()
	}
	
	_http_request.request(
		ServerConfig.API_ENDPOINT + "/update-game-server",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(update_data)
	)


func _on_register_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		print("Server registered successfully")
		_update_timer.start()  # Start health checks
		_http_request.disconnect("request_completed", _on_register_completed)
	else:
		printerr("Failed to register server: ", body.get_string_from_utf8())


func _on_degregister_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		print("Server deregistered successfully")
	else:
		printerr("Failed to deregister server: ", body.get_string_from_utf8())
	get_tree().quit()


func _notification(what: int):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if ServerConfig.is_aws_mode():
			var deregister_data = {
				"server_id": ServerConfig.server_id
			}
			
			# Synchronous request for cleanup
			var http = HTTPClient.new()
			var url = ServerConfig.API_ENDPOINT.split("://")[1]
			var host = url.split("/")[0]
			var path = "/" + url.split("/", true, 1)[1] + "/deregister-game-server"
			
			var tls_options = TLSOptions.client()
			http.connect_to_host(host, 443, tls_options)
			
			var data = JSON.stringify(deregister_data)
			var headers = ["Content-Type: application/json"]
			http.request(HTTPClient.METHOD_POST, path, headers, data)
		
		get_tree().quit()
