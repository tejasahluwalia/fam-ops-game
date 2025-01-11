extends CharacterBody3D
class_name ChaserEntity

enum BehaviorState {Idling, Reaching, Attacking, Dead}

@onready var navigation_agent:NavigationAgent3D=$NavigationAgent3D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var detection_shape: CollisionShape3D = $DetectionRange/CollisionShape3D
@onready var weapon_anchor: Node3D = $WeaponAnchor
@onready var detection_area: Area3D = $DetectionRange
@onready var beehave_tree: BeehaveTree = $BeehaveTree

@export var movement_speed: float = 8.0
@export var rotation_speed := 12.0
@export var points_dropped: int = 10

var target_object:Node3D = null
var transition:AnimationNodeTransition=null
var _last_strong_direction := Vector3.FORWARD
var gravity = -30.0
var anim_state = null
var current_state = null
var health_points = 3
var is_target_detected = false
var is_target_in_reach = false
var is_target_aligned = false
var detection_range = null
var original_speed: float
var velocity_for_animations = Vector3.ZERO


# Add only these new properties
@export var explosion_delay: float = 2.0
@export var explosion_damage: float = 20.0
@export var explosion_radius: float = 5.0
@export var blink_speed: float = 8.0
@export var explosion_movement_speed: float = 0.3  # Controls how fast the blinking happens

# Add minimal state tracking
var is_exploding: bool = false
var explosion_timer: float = 0.0

#@onready var mesh_instance: MeshInstance3D = $Body_001  # Reference to your model
@onready var radius_mesh: MeshInstance3D = $RadiusMesh   # Add this in editor


signal target_reached

func _ready() -> void:
	setup_radius_visualization()
	if multiplayer.is_server():
		self.navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
		DebugStats.add_property(self, "velocity", "")
		detection_range = detection_shape.shape.radius
		velocity_for_animations = self.velocity
	else:
		beehave_tree.queue_free()
	anim_tree.set_multiplayer_authority(multiplayer.get_unique_id())
	anim_tree.active = true
	transition = anim_tree.tree_root.get("nodes/state/node")
	original_speed = movement_speed


func setup_radius_visualization() -> void:
	if radius_mesh:
		var radius_material = StandardMaterial3D.new()
		radius_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		radius_material.albedo_color = Color(1, 0, 0, 0.2)  # Red with transparency
		radius_material.emission_enabled = true
		radius_material.emission = Color(1, 0, 0, 1)
		radius_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		
		var sphere = SphereMesh.new()
		sphere.radius = explosion_radius  # Just radius for sphere
		sphere.height = explosion_radius * 2  # Height should be double the radius
		radius_mesh.mesh = sphere
		radius_mesh.material_override = radius_material
		radius_mesh.visible = false  # Hide initially


@rpc("authority", "call_remote", "reliable", 0)
func update_animation_skin(delta):
	anim_state = self.anim_tree["parameters/state/current_state"]
	if  anim_state == "Idling":
		#if target_object: # align with target if any
			#self.look_at(target_object.global_position)
		if self.velocity_for_animations.length_squared() > 0.01:
			self.move_to_running()
	if anim_state == "Running":
		# var speed_scale = movement_speed / original_speed  # Normalize to original speed
		#anim_tree["parameters/run/TimeScale"] = speed_scale
		self.orient_model_to_direction.rpc_id(1, Vector3(self.velocity_for_animations.x,0, self.velocity_for_animations.z), delta)
		if self.velocity_for_animations.length_squared() <= 0.01:
			self.move_to_idling()


func update_target() -> void:
	var nearest_player = _get_nearest_player()
	if nearest_player:
		is_target_detected = true
		target_object = nearest_player
	else:
		is_target_detected = false


func _get_nearest_player() -> PlayerEntity:
	var target_body: PlayerEntity = null
	var target_distance: float = INF
	
	for body in detection_area.get_overlapping_bodies():
		if body is PlayerEntity:
			var distance = global_position.distance_squared_to(body.global_position)
			if distance < target_distance:
				target_body = body
				target_distance = distance
	
	return target_body


func update_navigation_agent(delta, _target_object):
	if multiplayer.is_server():
		if self.navigation_agent.is_navigation_finished():
			self.velocity = Vector3(0,0,0)
			target_reached.emit()
			return

	var next_path_position: Vector3 = self.navigation_agent.get_next_path_position()
	var new_velocity: Vector3 = self.global_position.direction_to(next_path_position) * movement_speed
	new_velocity.y = self.velocity.y + gravity*delta
	if self.navigation_agent.avoidance_enabled:
		self.navigation_agent.set_velocity(new_velocity)
	else:# we call it manually because only called by set_velocity when avoidance is true
		_on_velocity_computed(new_velocity)


func set_movement_target(movement_target: Vector3): 
	self.navigation_agent.set_target_position(movement_target)
	

func _on_velocity_computed(safe_velocity: Vector3):
	self.velocity = safe_velocity
	self.move_and_slide()
	velocity_for_animations = safe_velocity



@rpc("authority", "call_remote", "reliable", 0)
func move_to_running() -> void:
	transition.xfade_time = 0.1
	anim_tree["parameters/state/transition_request"] = "Running"


@rpc("authority", "call_remote", "reliable", 0)
func move_to_idling() -> void:
	transition.xfade_time = 0.1
	anim_tree["parameters/state/transition_request"] = "Idling"


@rpc("authority", "call_remote", "reliable", 0)
func move_to_dying() -> void:
	transition.xfade_time = 0
	anim_tree["parameters/state/transition_request"] = "Dying"
	self.process_mode = Node.PROCESS_MODE_DISABLED
	# Note: we set the MeleeSkin so that it does not inherit the parent's state
	# This way it can continue to play the animation and then we use a tween to
	# disable it with a 2 sec delay.
	(get_tree().create_tween()
	.tween_callback(func(): 
		$MeleeSkin.process_mode = Node.PROCESS_MODE_DISABLED
		anim_tree.process_mode = Node.PROCESS_MODE_DISABLED
		)
	.set_delay(2))
	if radius_mesh:
		disable_radius_mesh.rpc_id(1)


@rpc("authority", "call_remote", "reliable", 0)
func play_on_attacking(is_requested: bool) -> void:
	if is_requested:
		anim_tree["parameters/on_attacking/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	else:
		anim_tree["parameters/on_attacking/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT


@rpc("authority", "call_remote", "reliable", 0)
func play_on_hit(is_requested:bool):
	if is_requested:
		anim_tree["parameters/on_hit/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	else:
		anim_tree["parameters/on_hit/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT
	

func deal_damage():
	## To be called by AnimationPlayer on the Skin in Attack animations
	var weapon:Weapon = weapon_anchor.get_child(0)
	if weapon != null and weapon is Weapon:
		weapon.deal_damage()


@rpc("any_peer", "call_remote", "reliable", 0)
func orient_model_to_direction(direction: Vector3, delta: float) -> void:
	
	#if direction.length() > 0.05:
	_last_strong_direction = direction
	if target_object: # prioritize aligning with target if any
		_last_strong_direction = global_position.direction_to(target_object.global_position)
	
	# Remember that Y is the Up Axis
	# LERP is used cumulatively here
	rotation.y = lerp_angle(
		rotation.y, 
		Vector2(_last_strong_direction.z, _last_strong_direction.x).angle(), 
		delta*rotation_speed
	)


func _on_detection_range_body_entered(body):
	if multiplayer.is_server():
		if body is PlayerEntity:
			is_target_detected = true
			target_object = body
			detection_shape.shape.radius = detection_range*1.5


func _on_attack_range_body_entered(body):
	if multiplayer.is_server():
		if body is PlayerEntity and not is_exploding:
			is_target_in_reach = true
			start_explosion_sequence()


func _on_detection_range_body_exited(body):
	if multiplayer.is_server():
		if body is PlayerEntity:
			is_target_detected = false
			target_object = null
			detection_shape.shape.radius = detection_range


func _on_attack_range_body_exited(body):
	if multiplayer.is_server():
		if body is PlayerEntity:
			is_target_in_reach = false


# Add these new functions
func start_explosion_sequence() -> void:
	is_exploding = true
	explosion_timer = 0.0
	movement_speed = movement_speed * explosion_movement_speed  # Slow down while exploding
	if radius_mesh:
		radius_mesh.visible = true  # Show radius indicator


@rpc("any_peer")
func disable_radius_mesh() -> void:
	radius_mesh.visible = false


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		if is_exploding:
			explosion_timer += delta
			#update_blinking(delta)
			if explosion_timer >= explosion_delay:
				trigger_explosion()


func trigger_explosion() -> void:
	# Hide the radius visualization immediately
	if radius_mesh:
		disable_radius_mesh.rpc_id(1)
	
	deal_explosion_damage.rpc_id(1)
	AudioManager.explosion_sfx.play()
	move_to_dying()


@rpc("any_peer", "call_remote", "reliable", 0)
func deal_explosion_damage() -> void:
	print("deal_explosion_damage()")
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = explosion_radius
	query.shape = shape
	query.transform = global_transform
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.collider
		if collider is PlayerEntity:
			print ("damage dealt")
			var distance = global_position.distance_squared_to(collider.global_position)
			print(distance)
			if distance < explosion_radius:
				var damage = explosion_damage
				collider.health_manager.get_damage(damage)
	
	get_tree().create_timer(1.0).timeout.connect(queue_free)


#func update_blinking(delta: float) -> void:
	#if mesh_instance and mesh_instance.get_surface_override_material(0):
		#var blink_value = abs(sin(explosion_timer * blink_speed))
		#var material = mesh_instance.get_surface_override_material(0)
		#material.albedo_color = Color(1, blink_value, blink_value, 1)  # Blink between red and white
		#material.emission_enabled = true
		#material.emission = Color(1, 0, 0, blink_value)  # Red emission
#
		#if radius_mesh and radius_mesh.material_override:
			#radius_mesh.material_override.albedo_color.a = 0.2 * blink_value


func _on_hit_area_body_entered(colliding_body):
	if multiplayer.is_server():
		# Check health at start to avoid race conditions.
		if health_points <= 0:
			return
			
		if colliding_body.is_in_group("bullet"):
			health_points -= colliding_body.damage
			
			if health_points <= 0:
				if colliding_body.shooter != null:
					colliding_body.shooter.add_points(points_dropped)
				get_tree().create_timer(1.0).timeout.connect(queue_free)
			
			else:
				play_on_hit.rpc(true)
			
			colliding_body.remove_from_group("bullet")
