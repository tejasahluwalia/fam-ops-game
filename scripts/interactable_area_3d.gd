class_name InteractableArea3D
extends Area3D

@export var cost: int = 100
@export var upgrade_increment: int = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func interact(player: PlayerEntity) -> void:
	if player.points >= cost:
		player.remove_points(cost)
		player.inventory.weapons.toygun["fire_rate"] += upgrade_increment
	else:
		print("Can't afford upgrade. Points required: %d" % cost)
