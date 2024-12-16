extends MeshInstance3D


func interact(player: PlayerEntity) -> void:
	if player.points >= 5:
		player.remove_points(5)
		player.inventory.weapons.toygun["fire_rate"] += 2
	else:
		print("Can't afford upgrade")
