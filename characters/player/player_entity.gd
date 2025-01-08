class_name PlayerEntity
extends CharacterBody3D

@onready var camera: Camera3D = $CameraPivot/ThirdPersonCamera
@onready var camera_pivot: Node3D = $CameraPivot
@onready var model := $IcySkin
@onready var health_manager := $HealthManager
@onready var anim_tree := $IcySkin/AnimationTree
@onready var shoot_anchor := $IcySkin/%ShootAnchor
@onready var current_controller := $TwoStickControllerAuto
@onready var interaction_area := $IcySkin/PlayerHand
@onready var position_resetter := $PositionResetter
@onready var start_position := global_transform.origin

var points: int = 0

@export var use_saved_controller: bool = true
@export var controller_schemes: Array[PackedScene]
@export var game_data: GameDataStore

@export var player_id := 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)

@export var inventory:Dictionary = {
		"weapons": {
				"toygun": {
					"fire_rate": 2,
					"damage": 1,
					"initial_velocity": 50
				}
			}
	}

var current_weapon = "toygun"

signal is_dead
signal points_changed_server(new_points: int)
signal points_changed_client(new_points: int)


func _ready():
	if not multiplayer.is_server():
		if multiplayer.get_unique_id() == player_id:
			camera.make_current()
		#game_data.controller_scheme_changed.connect(_on_controller_scheme_changed)
		#if use_saved_controller:
			#_on_controller_scheme_changed(game_data.controller_scheme)


func _input(event: InputEvent) -> void:
	if Focus.focused && not multiplayer.is_server() && multiplayer.get_unique_id() == player_id:
		if event.is_action_pressed("p1_interact"):
			_interact.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable", 0)
func _interact() -> void:
	if player_id == multiplayer.get_remote_sender_id():
		var interactibles = interaction_area.get_overlapping_areas()
		for area: Area3D in interactibles:
			if area is InteractableArea3D or area is PointDepositArea:
				area.interact(self)


func on_hit():
	model.play_on_hit(true)


func on_death():
	is_dead.emit()
	model.move_to_dead()
	self.set_collision_layer_value(1, false)
	#current_controller.process_mode = Node.PROCESS_MODE_DISABLED
	current_controller.on_death()


func on_respawn():
	model.move_to_running.rpc()
	current_controller.on_respawn()
	health_manager.get_full_health()


func _on_dialog_started():
	current_controller.process_mode = Node.PROCESS_MODE_DISABLED


func _on_dialog_ended():
	current_controller.process_mode = Node.PROCESS_MODE_INHERIT


#func _on_controller_scheme_changed(value):
	#if current_controller:
		#current_controller.queue_free()
	#var new_controller = controller_schemes[value].instantiate()
	#add_child(new_controller)
	#new_controller.owner = self
	#current_controller = new_controller


func add_points(amount: int) -> void:
	points += amount
	points_changed_server.emit(points)
	_on_points_changed.rpc(points)


func remove_points(amount: int) -> void:
	points -= amount
	points_changed_server.emit(points)
	_on_points_changed.rpc(points)

func upgrade_particle() -> void:
	$UpgradeParticles.emitting =true
	await get_tree().create_timer(3.0).timeout
	$UpgradeParticles.emitting =false
	
	

@rpc("call_remote", "authority", "reliable", 0)
func _on_points_changed(new_points_value: int) -> void:
	points_changed_client.emit(new_points_value)
