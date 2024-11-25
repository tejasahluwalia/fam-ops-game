extends Node
class_name FocusInput

var focused := true

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			focused = false
		NOTIFICATION_APPLICATION_FOCUS_IN:
			focused = true


func input_is_action_pressed(action: StringName) -> bool:
	if focused:
		return Input.is_action_pressed(action)

	return false


func event_is_action_pressed(event: InputEvent, action: StringName) -> bool:
	if focused:
		return event.is_action_pressed(action)

	return false


func input_get_action_raw_strength(action: StringName) -> float:
	if focused:
		return Input.get_action_raw_strength(action)
	
	return false


func input_get_vector(negative_x: StringName, positive_x: StringName, negative_y: StringName, positive_y: StringName, deadzone: float = -1.0) -> Vector2:
	if focused:
		return Input.get_vector(negative_x, positive_x, negative_y, positive_y, deadzone)
	
	return Vector2(0.0, 0.0)


func input_is_action_just_pressed(action: StringName) -> bool:
	if focused:
		return Input.is_action_just_pressed(action)
		
	return false
