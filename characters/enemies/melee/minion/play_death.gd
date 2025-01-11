extends ActionLeaf


func tick(actor, _blackboard):
	actor.move_to_dying.rpc()
	actor.current_state = actor.BehaviorState.Dead
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	# Note: we set the MeleeSkin so that it does not inherit the parent's state
	# This way it can continue to play the animation and then we use a tween to
	# disable it with a 2 sec delay.
	#(get_tree().create_tween()
	#.tween_callback(func():
		#actor.melee_skin.process_mode = Node.PROCESS_MODE_DISABLED
		#actor.anim_tree.process_mode = Node.PROCESS_MODE_DISABLED
		#)
	#.set_delay(2))
	return SUCCESS
