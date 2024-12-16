extends SwitchComponent


func on_interaction(_requested):
	if get_parent().one_shot and is_activated:
		return
		
	# if requested == false or Dialogic.current_timeline != null: 
	# 	return
	is_activated = true
