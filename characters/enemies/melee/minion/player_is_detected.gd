class_name PlayerIsDetected extends ConditionLeaf


func tick(actor, _blackboard):
	if actor.is_target_detected:
		return SUCCESS
	else:
		return FAILURE
