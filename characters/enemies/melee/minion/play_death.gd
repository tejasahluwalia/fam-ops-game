extends ActionLeaf


func tick(actor, blackboard):
	actor.move_to_dying.rpc()
	actor.current_state = actor.BehaviorState.Dead
	if multiplayer.is_server():
		actor.queue_free()
	return SUCCESS
	
