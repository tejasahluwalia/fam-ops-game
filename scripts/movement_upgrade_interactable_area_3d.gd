extends Area3D

@export var cost: int = 100
@export var upgrade_increment: int = 2


func interact(player: PlayerEntity) -> void:
	if player.points >= cost:
		player.remove_points(cost)
		player.current_controller.get_node("MovementController/Move").acceleration += 2
		player.current_controller.get_node("MovementController/Move").max_speed += 5
		player.model.play_upgrading.rpc()
	else:
		print("Can't afford upgrade. Points required: %d" % cost)