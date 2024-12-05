extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func interact(player: PlayerEntity) -> void:
	if player.points >= 5:
		player.remove_points(5)
		player.inventory.weapons.toygun["fire_rate"] += 2	
	else:
		print("Can't afford upgrade")
