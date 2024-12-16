extends ConditionLeaf


func tick(actor, _blackboard):
	if actor.health_points <= 0:
		return SUCCESS
	else:
		return FAILURE
