extends ConditionLeaf


func tick(actor, _blackboard):
	if actor.current_state == actor.BehaviorState.Idling:
		return SUCCESS
	else:
		return FAILURE
