# AimingController with RStick Auto: Aiming State
extends PlayerState

var arrow_prefab = preload("res://assets/objects/weapons/toy_gun/Arrow.tscn")
var _aiming_direction := Vector3.ZERO
var _aim_input := Vector2.ZERO
@onready var _timer : Timer = $Timer


func process(delta) -> void:
	if multiplayer.is_server():
		_update_player_input()
		
		#TODO: Move this to a _on_weapon_updated() function
		var weapon = player.inventory.weapons.get(player.current_weapon)
		if weapon:
			_timer.wait_time = (1.0 / weapon["fire_rate"])
		
		if _aiming_direction.length() <= 0.2:
			_state_machine.transition_to("Rest")
		if _timer.time_left <= 0:
			_timer.start()
			call_deferred("_shoot_arrow")

		player.model.orient_model_to_direction(_aiming_direction, delta)


func enter(msg: = {}) -> void:
	super(msg) # parent send a signal and we dont want to override it!
	player.model.play_aiming.rpc(true)
	_timer.start()
	# NOTE: we delay the start of the shooting, kind of sucks for reactivity but
	# the character skin needs to finish its aiming animation


func _shoot_arrow(initial_velocity: int = 50, damage: int = 1) -> void:
	var arrow = arrow_prefab.instantiate()
	arrow.global_transform = player.shoot_anchor.global_transform
	arrow.set_shooter(player)
	arrow.damage = damage
	arrow.initial_velocity = initial_velocity
	get_tree().current_scene.projectile_spawn_node.add_child(arrow, true)
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
