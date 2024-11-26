extends ActionLeaf


func tick(actor, blackboard):
	actor.move_to_dying.rpc()
	actor.current_state = actor.BehaviorState.Dead
	actor.queue_free()
	return SUCCESS
	
