extends ActionLeaf


func tick(actor, _blackboard):
	actor.move_to_idling.rpc()
	actor.current_state = actor.BehaviorState.Attacking
	actor.play_on_attacking.rpc(true)
	return SUCCESS
