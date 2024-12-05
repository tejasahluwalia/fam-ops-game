class_name PointDepositArea
extends Area3D

signal points_deposited(points: int)

@export var cost = 5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func interact(player: PlayerEntity) -> void:
	print("Interacting with exit point deposit area.")
	if player.points >= cost:
		player.remove_points(cost)
		points_deposited.emit(cost)
	else:
		print("Can't afford to deposit points.")
