extends Area3D
class_name InteractableArea3D


func interact(player: PlayerEntity) -> void:
	player.inventory.weapons.toygun["fire_rate"] += 2	
