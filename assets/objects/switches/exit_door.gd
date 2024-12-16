extends Node3D

@export var total_cost: int = 500
@export var point_deposit_area: PointDepositArea
@export var points_remaining_label: Label3D

var _current_value: int = 0
var _is_accepting_deposits = true
var _switch_component: SwitchComponent = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_switch_component = get_node("SwitchComponent")
	
	if not _switch_component:
		print("SwitchComponent for door not found.")
		return
		
	if not point_deposit_area:
		print("Point deposit area for door not set.")
		return
	
	point_deposit_area.points_deposited.connect(_on_points_deposited)
	_update_text.rpc(total_cost - _current_value)


func _on_points_deposited(points: int):
	if _is_accepting_deposits:
		_current_value += points
		_update_text.rpc(total_cost - _current_value)
	
	if _current_value >= total_cost:
		_switch_component.on_interaction(true)
		_is_accepting_deposits = false


@rpc("authority", "call_remote", "reliable", 0)
func _update_text(points_needed: int):
	points_remaining_label.text = "Points needed: %d" % points_needed
