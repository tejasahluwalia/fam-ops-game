extends PlayerState


func physics_process(delta: float) -> void:
	if multiplayer.is_server():
		_parent.physics_process(delta)
		if player.is_on_floor():  # and _parent._snap == Vector3.ZERO:
			state_machine.transition_to("Move/Idle")


func enter(msg := {}) -> void:
	player.model.move_to_falling.rpc()
	_parent.enter(msg)


func exit() -> void:
	_parent.exit()
