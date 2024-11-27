extends Node

signal health_changed(old_value, new_value)
signal damage
signal health_depleted
signal health_replenished

@export var max_health: int = 100 # Max health is now a single value (e.g., 100)
@export var start_health: int = 100 # Starting health

var health_points: int = 0: set = set_health
@onready var health_bar: ProgressBar = $HealthBar # Reference to the health bar node


func _ready():
	health_points = start_health
	update_health_bar()


@rpc("any_peer", "call_remote", "reliable", 0)
func set_health(value: int):
	var old_value = health_points
	health_points = clamp(value, 0, max_health) # Clamp the health value between 0 and max_health
	health_changed.emit(old_value, health_points)
	update_health_bar()
	if health_points <= 0:
		health_depleted.emit()
	elif health_points == max_health:
		health_replenished.emit()


func update_health_bar():
	# Set the health bar's value to the current health
	health_bar.value = health_points


func get_damage(amount: int):
	set_health.rpc_id(1, health_points - amount)
	damage.emit()


func get_health(amount: int):
	set_health(health_points + amount)


func get_full_health():
	set_health(max_health)

func instant_death():
	set_health(0)
