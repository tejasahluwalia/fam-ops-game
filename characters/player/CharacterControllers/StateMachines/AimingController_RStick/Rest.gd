# AimingController with RStick and RStick Auto: Resting State
extends PlayerState

var _player_input := Vector2.ZERO


func unhandled_input(_event: InputEvent) -> void:
	if multiplayer.is_server():
		_update_player_input()
		if _player_input.length()>0.01 and player.inventory.has("toygun"):
			_state_machine.transition_to("Aim")


func enter(msg: = {}) -> void:
	super(msg)
	player.model.play_aiming.rpc(false)


func _update_player_input():
	_player_input = input_synchronizer.input_aim
	
