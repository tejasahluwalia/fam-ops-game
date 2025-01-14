extends Node

signal session_created(session_id: String)
signal session_joined(session_id: String)
signal session_list_updated(sessions: Array)
signal session_started(host: String, port: int)
signal session_error(message: String)

const API_ENDPOINT = ServerConfig.API_ENDPOINT
var _http_request: HTTPRequest

var current_session_id: String = ""
var is_host: bool = false
var session_state: String = ""
var host_id: String = ""
var player_list: Array = []
var max_players: int = 4
var lobby_name: String = ""
var connection_info: String = ""
var my_player_name: String = ""


func _ready():
	_http_request = HTTPRequest.new()
	add_child(_http_request)


func create_session(server_name: StringName, host_name: StringName):
	if _http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_request.cancel_request()
		
	is_host = true
	var data = {
		"host_id": host_name,
		"max_players": 4,  # TODO: Make configurable
		"player_count": 1,
		"connected_players": [host_name],
		"session_state": "WAITING",
		"server_name": server_name
	}
	
	_http_request.request(
		API_ENDPOINT + "/create-game",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(data)
	)
	if _http_request.is_connected("request_completed", _on_request_completed):
		_http_request.disconnect("request_completed", _on_request_completed)
	_http_request.connect("request_completed", _on_request_completed.bind("/create-game"))
	
	host_id = host_name
	player_list = [host_name]
	lobby_name = server_name
	my_player_name = host_name


func list_sessions():
	if _http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
    	# Request is already in progress
		return
	
	_http_request.request(
		API_ENDPOINT + "/list-available-sessions",
		["Content-Type: application/json"],
		HTTPClient.METHOD_GET
	)
	if _http_request.is_connected("request_completed", _on_request_completed):
		_http_request.disconnect("request_completed", _on_request_completed)
	_http_request.connect("request_completed", _on_request_completed.bind("/list-available-sessions"))


func join_session(session_id: StringName, player_name: StringName):
	if _http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_request.cancel_request()
	
	current_session_id = session_id
	is_host = false
	my_player_name = player_name
	
	var data = {
		"session_id": session_id,
		"player_id": player_name
	}
	
	_http_request.request(
		API_ENDPOINT + "/join-waiting-room",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(data)
	)
	if _http_request.is_connected("request_completed", _on_request_completed):
		_http_request.disconnect("request_completed", _on_request_completed)
	_http_request.connect("request_completed", _on_request_completed.bind("/join-waiting-room"))


func get_session():
	if _http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
    	# Request is already in progress
		return
	
	var data = {
		"session_id": current_session_id
	}

	_http_request.request(
		API_ENDPOINT + "/get-session",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(data)
	)
	if _http_request.is_connected("request_completed", _on_request_completed):
		_http_request.disconnect("request_completed", _on_request_completed)
	_http_request.connect("request_completed", _on_request_completed.bind("/get-session"))
	

func start_session():
	if _http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_request.cancel_request()

	if not is_host:
		session_error.emit("Only the host can start the session")
		return
		
	var data = {
		"session_id": current_session_id,
		"host_id": host_id
	}
	
	_http_request.request(
		API_ENDPOINT + "/start-game",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(data)
	)
	if _http_request.is_connected("request_completed", _on_request_completed):
		_http_request.disconnect("request_completed", _on_request_completed)
	_http_request.connect("request_completed", _on_request_completed.bind("/start-game"))


func leave_session():
	if _http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_request.cancel_request()

	if not current_session_id:
		return
		
	var data = {
		"session_id": current_session_id,
		"player_id": my_player_name
	}
	
	_http_request.request(
		API_ENDPOINT + "/leave-waiting-room",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(data)
	)
	if _http_request.is_connected("request_completed", _on_request_completed):
		_http_request.disconnect("request_completed", _on_request_completed)
	_http_request.connect("request_completed", _on_request_completed.bind("/leave-waiting-room"))
	
	current_session_id = ""
	is_host = false


func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, path: StringName):
	if response_code != 200:
		session_error.emit("Request failed with code " + str(response_code))
		return
		
	var response = JSON.parse_string(body.get_string_from_utf8())
	print_debug(response)
	
	match path:
		"/create-game":
			current_session_id = response.session_id
			session_created.emit(current_session_id)
		"/list-available-sessions":
			session_list_updated.emit(response.games)
		"/join-waiting-room":
			host_id = response.host_id
			player_list = response.players
			lobby_name = response.server_name
			session_joined.emit(current_session_id)
		"/start-game":
			session_started.emit(
				response.server_details.connection_info.split(":")[0],
				int(response.server_details.connection_info.split(":")[1])
			)
		"/leave-waiting-room":
			if current_session_id == response.session_id:
				current_session_id = ""
				is_host = false
				host_id = ""
				player_list.clear()
		"/get-session":
			host_id = response.host_id
			player_list = response.players
			lobby_name = response.server_name
			session_state = response.status
			if session_state == "ACTIVE":
				session_started.emit(
					response.server_details.connection_info.split(":")[0],
					int(response.server_details.connection_info.split(":")[1])
				)
