extends CharacterBody3D
class_name ChaserEntity

enum BehaviorState {Idling, Reaching, Attacking, Dead}

@onready var navigation_agent:NavigationAgent3D=$NavigationAgent3D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var detection_shape: CollisionShape3D = $DetectionRange/CollisionShape3D
@onready var weapon_anchor: Node3D = $WeaponAnchor

@export var movement_speed: float = 8.0
@export var rotation_speed := 12.0

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

# Add only these new properties
@export var explosion_delay: float = 2.0
@export var explosion_damage: float = 2.0
@export var explosion_radius: float = 5.0
@export var blink_speed: float = 8.0
@export var explosion_movement_speed: float = 0.3  # Controls how fast the blinking happens

# Add minimal state tracking
var is_exploding: bool = false
var explosion_timer: float = 0.0

@onready var mesh_instance: MeshInstance3D = $Body_001  # Reference to your model
@onready var radius_mesh: MeshInstance3D = $RadiusMesh   # Add this in editor

signal target_reached

func _ready() -> void:
	setup_radius_visualization()
	self.navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	DebugStats.add_property(self, "velocity", "")
	anim_tree.active = true
	transition = anim_tree.tree_root.get("nodes/state/node")
	detection_range = detection_shape.shape.radius
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





func update_animation_skin(delta):
	anim_state = self.anim_tree["parameters/state/current_state"]
	if  anim_state == "Idling":
		#if target_object: # align with target if any
			#self.look_at(target_object.global_position)
		if self.velocity.length_squared() > 0.01:
			self.move_to_running()
	if anim_state == "Running":
		var speed_scale = movement_speed / original_speed  # Normalize to original speed
		#anim_tree["parameters/run/TimeScale"] = speed_scale
		self.orient_model_to_direction(Vector3(self.velocity.x,0, self.velocity.z), delta)
		if self.velocity.length_squared() <= 0.01:
			self.move_to_idling()
	

func update_navigation_agent(delta, target_object):
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


func move_to_running() -> void:
	transition.xfade_time = 0.1
	anim_tree["parameters/state/transition_request"] = "Running"


func move_to_idling() -> void:
	transition.xfade_time = 0.1
	anim_tree["parameters/state/transition_request"] = "Idling"


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


func play_on_attacking(is_requested: bool) -> void:
	if is_requested:
		anim_tree["parameters/on_attacking/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	else:
		anim_tree["parameters/on_attacking/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT


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
	if body is PlayerEntity:
		is_target_detected = true
		target_object = body
		detection_shape.shape.radius = detection_range*1.5


func _on_attack_range_body_entered(body):
	if body is PlayerEntity and not is_exploding:
		is_target_in_reach = true
		start_explosion_sequence()


func _on_detection_range_body_exited(body):
	if body is PlayerEntity:
		is_target_detected = false
		target_object = null
		detection_shape.shape.radius = detection_range


func _on_attack_range_body_exited(body):
	if body is PlayerEntity:
		is_target_in_reach = false

# Add these new functions
func start_explosion_sequence() -> void:
	is_exploding = true
	explosion_timer = 0.0
	movement_speed = movement_speed * explosion_movement_speed  # Slow down while exploding
	if radius_mesh:
		radius_mesh.visible = true  # Show radius indicator

func _physics_process(delta: float) -> void:
	if is_exploding:
		explosion_timer += delta
		update_blinking(delta)
		if explosion_timer >= explosion_delay:
			trigger_explosion()

func trigger_explosion() -> void:
	# Hide the radius visualization immediately
		if radius_mesh:
			radius_mesh.visible = false

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
				var distance = global_position.distance_to(collider.global_position)
				var damage = explosion_damage * (1.0 - (distance / explosion_radius))
				collider.health_manager.get_damage(damage)
	
		move_to_dying()



func update_blinking(delta: float) -> void:
	if mesh_instance and mesh_instance.get_surface_override_material(0):
		var blink_value = abs(sin(explosion_timer * blink_speed))
		var material = mesh_instance.get_surface_override_material(0)
		material.albedo_color = Color(1, blink_value, blink_value, 1)  # Blink between red and white
		material.emission_enabled = true
		material.emission = Color(1, 0, 0, blink_value)  # Red emission

		if radius_mesh and radius_mesh.material_override:
			radius_mesh.material_override.albedo_color.a = 0.2 * blink_value


func _on_hit_area_body_entered(colliding_body):
	if colliding_body.is_in_group("bullet"):
		print("hit by", colliding_body.name, "!")
		health_points -= 1
		colliding_body.remove_from_group("bullet")
		play_on_hit(true)
