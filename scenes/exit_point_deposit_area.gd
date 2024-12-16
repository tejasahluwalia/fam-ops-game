class_name PointDepositArea
extends Area3D

signal points_deposited(points: int)

@export var cost = 5


func interact(player: PlayerEntity) -> void:
	if player.points >= cost:
		player.remove_points(cost)
		points_deposited.emit(cost)
	else:
		print("Can't afford to deposit points.")
