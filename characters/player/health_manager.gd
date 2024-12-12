extends Node

signal health_changed(old_value, new_value)
signal damage
signal health_depleted
signal health_replenished

@export var max_health: int = 100
@export var start_health: int = 100
@export var damage_bar_cooldown: float = 0.5
@export var damage_bar_speed: float = 100

# Health regeneration parameters
@export var health_regen_cooldown: float = 5.0
@export var base_regen_rate: float = 10.0  # Health points per second
@export var low_health_threshold: float = 0.3
@export var low_health_regen_multiplier: float = 2.0

var health_points: int = 0: set = set_health
var damage_bar_value: float
var damage_bar_timer: float
var is_damage_bar_active: bool = false
var accumulated_health: float = 0.0  # Add this as a class variable


# Regeneration variables
var regen_timer: float = 0.0
var can_regenerate: bool = true

@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_bar: ProgressBar = $DamageBar


func _ready():
	health_points = start_health
	damage_bar_value = start_health
	update_health_bar()
	update_damage_bar()


func _process(delta):
	handle_damage_bar(delta)
	
	# Only server handles regeneration logic
	if multiplayer.is_server():
		handle_health_regeneration(delta)


func handle_damage_bar(delta):
	if is_damage_bar_active:
		damage_bar_timer -= delta
		if damage_bar_timer <= 0:
			var new_value = move_toward(damage_bar_value, health_points, damage_bar_speed * delta)
			if new_value != damage_bar_value:
				damage_bar_value = new_value
				update_damage_bar()
			
			if damage_bar_value == health_points:
				is_damage_bar_active = false


func handle_health_regeneration(delta):
	if health_points >= max_health:
		return
		
	if regen_timer > 0:
		regen_timer -= delta
		return
	
	# Calculate regeneration rate based on current health percentage
	var health_percentage = float(health_points) / max_health
	var regen_multiplier = 1.0
	
	# Apply increased regeneration rate for low health
	if health_percentage <= low_health_threshold:
		regen_multiplier = low_health_regen_multiplier
	
	# Calculate health to regenerate this frame
	accumulated_health += base_regen_rate * regen_multiplier * delta

	# Ensure we regenerate at least 1 health point if there's any regeneration
	if accumulated_health >= 1.0:
		var heal_amount = int(accumulated_health)
		accumulated_health -= heal_amount
		set_health(health_points + heal_amount)
		is_damage_bar_active = true


@rpc("any_peer", "call_remote", "reliable")
func set_health(value: int):
	var old_value = health_points
	health_points = clamp(value, 0, max_health)
	health_changed.emit(old_value, health_points)
	update_health_bar()
	
	if old_value > health_points: # Took damage
		start_damage_bar_effect()
		reset_regen_timer()
	
	if health_points <= 0:
		health_depleted.emit()
	elif health_points == max_health:
		health_replenished.emit()


func reset_regen_timer():
	regen_timer = health_regen_cooldown


@rpc("any_peer", "call_remote", "reliable")
func start_damage_bar_effect():
	damage_bar_timer = damage_bar_cooldown
	is_damage_bar_active = true


func update_health_bar():
	health_bar.value = health_points


func update_damage_bar():
	damage_bar.value = damage_bar_value


func get_damage(amount: int):
	if multiplayer.is_server():
		set_health.rpc(health_points - amount)
	else:
		set_health.rpc_id(1, health_points - amount)
	damage.emit()


func get_health(amount: int):
	if multiplayer.is_server():
		set_health.rpc(health_points + amount)
	else:
		set_health.rpc_id(1, health_points + amount)


func get_full_health():
	if multiplayer.is_server():
		set_health.rpc(max_health)
		damage_bar_value = max_health
		update_damage_bar()
	else:
		set_health.rpc_id(1, max_health)


func instant_death():
	if multiplayer.is_server():
		set_health.rpc(0)
	else:
		set_health.rpc_id(1, 0)
