class_name InteractableArea3D
extends Area3D

@export var cost: int = 100
@export var upgrade_increment: int = 2


func interact(player: PlayerEntity) -> void:
	if player.points >= cost:
		player.remove_points(cost)
		player.inventory.weapons.toygun["fire_rate"] += upgrade_increment
		player.upgrade_particle()
		AudioManager.upgrade_sfx.play()
		
	else:
		print("Can't afford upgrade. Points required: %d" % cost)
