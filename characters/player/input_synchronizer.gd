extends MultiplayerSynchronizer
class_name InputSynchronizer

var input_movement_direction
var input_camera
var input_aim
var input_jump


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
	
	input_movement_direction = Focus.input_get_vector("p1_move_left", "p1_move_right", "p1_move_up", "p1_move_down")
	input_camera = Focus.input_get_action_raw_strength("p1_camera_RR") - Focus.input_get_action_raw_strength("p1_camera_RL")
	input_aim = Focus.input_get_vector("p1_aim_left", "p1_aim_right", "p1_aim_up", "p1_aim_down")
	input_jump = false


func _physics_process(delta: float) -> void:
	input_movement_direction = Focus.input_get_vector("p1_move_left", "p1_move_right", "p1_move_up", "p1_move_down")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	input_camera = Focus.input_get_action_raw_strength("p1_camera_RR") - Focus.input_get_action_raw_strength("p1_camera_RL")
	input_aim = Focus.input_get_vector("p1_aim_left", "p1_aim_right", "p1_aim_up", "p1_aim_down")
	input_jump = Focus.input_is_action_just_pressed("p1_jump")
