extends Node
class_name CharacterController

var _parent:PlayerEntity
var _player_input
@export var input_synchronizer: InputSynchronizer

@export var _camera_rotation_speed = 0.05
@export var cursor_arrow:Texture2D = null
@export var cursor_hand:Texture2D = null

# Called when the node enters the scene tree for the first time.
func _enter_tree():
	_parent = get_parent()
	var hotspot:Vector2 = Vector2(16,16) if cursor_arrow else Vector2.ZERO
	Input.set_custom_mouse_cursor(cursor_arrow, Input.CURSOR_ARROW, hotspot)
	Input.set_custom_mouse_cursor(cursor_hand, Input.CURSOR_POINTING_HAND, hotspot)


func _ready():
	pass


func _process(delta) -> void:
	if multiplayer.is_server():
		_update_player_input()


func _update_player_input():
	_player_input = input_synchronizer.input_camera
	_parent.camera_pivot.rotate_y(_player_input * _camera_rotation_speed)


func on_start():
	$MovementController.transition_to("Move/Idle")
	$AimingController.transition_to("Rest")


func on_death():
	$MovementController.transition_to("Dead")
	$AimingController.transition_to("Dead")


func on_respawn():
	$MovementController.transition_to("Move/Run")
	$AimingController.transition_to("Rest")
