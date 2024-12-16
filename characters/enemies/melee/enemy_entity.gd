extends CharacterBody3D
class_name EnemyEntity

enum BehaviorState {Idling, Reaching, Attacking, Dead}

@onready var navigation_agent:NavigationAgent3D=$NavigationAgent3D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var detection_shape: CollisionShape3D = $DetectionRange/CollisionShape3D
@onready var detection_area: Area3D = $DetectionRange
@onready var weapon_anchor: Node3D = $WeaponAnchor
@onready var beehave_tree: BeehaveTree = $BeehaveTree
@onready var attack_range: Area3D = $AttackRange

@export var movement_speed: float = 8.0
@export var rotation_speed := 12.0
@export var points_dropped: int = 5

var target_object:Node3D = null
var transition:AnimationNodeTransition = null
var _last_strong_direction := Vector3.FORWARD
var gravity = -30.0
var anim_state = null
var current_state = null
var health_points = 3
var is_target_detected = true
var is_target_in_reach = false
var is_target_aligned = false
var detection_range = null
var velocity_for_animations = Vector3.ZERO

signal target_reached


func _ready() -> void:
	if multiplayer.is_server():
		self.navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
		DebugStats.add_property(self, "velocity", "")
		detection_range = detection_shape.shape.radius
		velocity_for_animations = self.velocity
	else:
		beehave_tree.queue_free()
	anim_tree.active = true
	anim_tree.set_multiplayer_authority(multiplayer.get_unique_id())
	transition = anim_tree.tree_root.get("nodes/state/node")
	self.move_to_idling()


@rpc("authority", "call_remote", "reliable", 0)
func update_animation_skin(delta):
	anim_state = self.anim_tree["parameters/state/current_state"]
	if anim_state == "Idling":
		if target_object: # align with target if any
			self.look_at(target_object.global_position)
		if self.velocity_for_animations.length_squared() > 0.01:
			self.move_to_running()
	if anim_state == "Running":
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


func update_navigation_agent(delta, target_object):
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


func _on_attack_range_body_entered(body):
	if multiplayer.is_server():
		if body is PlayerEntity:
			is_target_in_reach = true


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


func _on_attack_range_body_exited(body):
	if multiplayer.is_server():
		if body is PlayerEntity:
			if len(attack_range.get_overlapping_bodies()) == 0:
				is_target_in_reach = false


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
