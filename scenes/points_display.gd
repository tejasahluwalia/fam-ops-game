extends Label

var player: PlayerEntity = null

func set_player(p: PlayerEntity) -> void:
	player = p
	player.points_changed_client.connect(Callable(self._on_points_changed))
	_set_text(player.points)


func _on_points_changed(points: int) -> void:
	_set_text(points)


func _set_text(points: int) -> void:
	text = "Points: %d" % points
