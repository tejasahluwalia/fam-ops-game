extends Area3D

@export var cost: int = 150
@export var upgrade_increment: float = 0.75


func interact(player: PlayerEntity) -> void:
	if player.points >= cost:
		player.remove_points(cost)
		player.inventory.weapons.toygun["fire_rate"] += upgrade_increment
		player.model.play_upgrading.rpc()
	else:
		print("Can't afford upgrade. Points required: %d" % cost)
