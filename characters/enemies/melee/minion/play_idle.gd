extends ActionLeaf


func tick(actor, _blackboard):
	actor.update_target()
	actor.move_to_idling.rpc()
	actor.current_state = actor.BehaviorState.Idling
	return SUCCESS
