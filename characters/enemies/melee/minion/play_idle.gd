extends ActionLeaf


func tick(actor, blackboard):
	actor.move_to_idling.rpc()
	actor.current_state = actor.BehaviorState.Idling
	return SUCCESS
