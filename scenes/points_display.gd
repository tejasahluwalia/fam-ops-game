extends Label

var player: PlayerEntity = null

func set_player(p: PlayerEntity) -> void:
	player = p

func _process(delta: float) -> void:
	if player:
		text = "Points: %d" % player.points
