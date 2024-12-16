extends ActionLeaf


func tick(actor, _blackboard):
	actor.move_to_dying.rpc()
	actor.current_state = actor.BehaviorState.Dead
	return SUCCESS
	
