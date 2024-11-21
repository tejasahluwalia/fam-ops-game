extends Node3D

var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene
@export var buttons: Array[Button]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass


func _on_host_button_pressed() -> void:
    peer.create_server(6060)
    multiplayer.multiplayer_peer = peer
    multiplayer.peer_connected.connect(_add_player)
    _add_player()
    remove_buttons()
    pass # Replace with function body.


func _add_player(id = 1):
    var player = player_scene.instantiate()
    player.name = str(id)
    call_deferred("add_child", player)
    pass


func _on_join_button_pressed() -> void:
    peer.create_client("192.168.1.15", 6060)
    multiplayer.multiplayer_peer = peer
    remove_buttons()
    pass # Replace with function body.


func remove_buttons() -> void:
    for button in buttons:
        button.queue_free()
    pass
