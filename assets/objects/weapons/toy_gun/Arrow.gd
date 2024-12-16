extends RigidBody3D
class_name Arrow

# signal exploded

var shooter: PlayerEntity = null
var damage: int = 1

@export var initial_velocity = 50
@onready var impact_mesh = $ImpactMesh

var velocity = Vector3.ZERO


func _physics_process(_delta):
	if multiplayer.is_server():
		if velocity.length_squared() > 0.01:
			look_at(transform.origin + velocity.normalized(), Vector3.UP)
	

func _ready():
	impact_mesh.visible = false
	impact_mesh.scale = Vector3(1,1,1)
	if multiplayer.is_server():
		await get_tree().create_timer(10.0).timeout # waits for 1 second
		queue_free()


func _on_body_entered(body):
	if impact_mesh:
		impact_mesh.visible = true
		#TODO: attach to wall and align with collision normal
		#impact_mesh.reparent(get_tree().get_root())
		var tween = self.create_tween()

		(tween.tween_property(impact_mesh, "scale", Vector3(), 0.1)
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_IN))
		tween.parallel().tween_callback(func(): impact_mesh.visible = false).set_delay(0.06)
	
	if body is GridMap: # hit a wall
		self.remove_from_group("bullet")
		call_deferred("set_contact_monitor", false)
		self.max_contacts_reported = 0
		
	await get_tree().create_timer(0.15).timeout
	queue_free()


func set_shooter(player: PlayerEntity) -> void:
	shooter = player
