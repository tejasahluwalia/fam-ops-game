extends Node3D

var spawn_markers: Array[Marker3D] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var children = get_children()
	for child in children:
		if child is Marker3D:
			spawn_markers.append(child)
	WaveManager.spawn_points = spawn_markers
