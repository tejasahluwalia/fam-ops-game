extends MeshInstance3D


func interact(player: PlayerEntity) -> void:
	if player.points >= 5:
		player.remove_points(5)
		#player.current_controller.get_node("MovementController/Move").acceleration += 1.0
		player.current_controller.get_node("MovementController/Move").max_speed += 1.0
	else:
		print("Can't afford upgrade")
