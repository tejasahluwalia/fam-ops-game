extends MultiplayerSynchronizer

var input_movement_direction
var input_camera


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
	
	input_movement_direction = Input.get_vector("p1_move_left", "p1_move_right", "p1_move_up", "p1_move_down")
	input_camera = Input.get_action_raw_strength("p1_camera_RR") - Input.get_action_raw_strength("p1_camera_RL")


func _physics_process(delta: float) -> void:
	input_movement_direction = Input.get_vector("p1_move_left", "p1_move_right", "p1_move_up", "p1_move_down")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	input_camera = Input.get_action_raw_strength("p1_camera_RR") - Input.get_action_raw_strength("p1_camera_RL")
