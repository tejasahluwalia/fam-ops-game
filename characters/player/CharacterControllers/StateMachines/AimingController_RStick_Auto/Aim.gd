# AimingController with RStick Auto: Aiming State
extends PlayerState

var arrow_prefab = preload("res://assets/objects/weapons/toy_gun/Arrow.tscn")
var _aiming_direction := Vector3.ZERO
var _aim_input := Vector2.ZERO
@onready var _timer : Timer = $Timer


func process(delta) -> void:
	if multiplayer.is_server():
		_update_player_input()
		if _aiming_direction.length() <= 0.2:
			_state_machine.transition_to("Rest")
		if _timer.time_left <= 0:
			# NOTE: we tried with event handling, but weirdly the deadzone was noisy,
			# 1) it would trigger many bullets when near the deadzone
			# 2) it would trigger a second bullet on release
			_timer.start()
			call_deferred("_shoot_arrow")

		player.model.orient_model_to_direction(_aiming_direction, delta)


func enter(msg: = {}) -> void:
	super(msg) # parent send a signal and we dont want to override it!
	player.model.play_aiming.rpc(true)
	_timer.start()
	# NOTE: we delay the start of the shooting, kind of sucks for reactivity but
	# the character skin needs to finish its aiming animation


func _shoot_arrow() -> void:
	var arrow = arrow_prefab.instantiate()
	get_tree().current_scene.get_node("ProjectileSpawnNode").add_child(arrow, true)
	arrow.global_transform = player.shoot_anchor.global_transform
	arrow.apply_central_impulse(arrow.transform.basis.z * arrow.initial_velocity)
	player.model.play_shooting.rpc(true)


func _update_player_input():
	# get input for aiming
	_aim_input = input_synchronizer.input_aim
	# align input with the camera
	_aiming_direction.x = _aim_input.x
	_aiming_direction.z = _aim_input.y
	_aiming_direction.y = 0
	_aiming_direction = player.camera.global_transform.basis * (_aiming_direction)
