extends Control

@onready var my_health: MarginContainer = $MyHealth
@onready var my_damage_bar: ProgressBar = $MyHealth/DamageBar
@onready var my_health_bar: ProgressBar = $MyHealth/HealthBar

@onready var team_health: MarginContainer = $TeamHealth
@onready var team_health_bars: VBoxContainer = $TeamHealth/TeamHealthBars


func set_player(player: PlayerEntity) -> void:
	visible = true
	_set_teammate_health_mcontainer_size()
	player.health_manager.health_changed.connect(_on_my_health_changed)


func _on_my_health_changed(_old_value: float, new_value: float) -> void:
	my_health_bar.value = new_value


func set_teammate(player: PlayerEntity) -> void:
	_set_teammate_health_mcontainer_size()
	var teammate_health_bar: ProgressBar = my_health_bar.duplicate() as ProgressBar
	teammate_health_bar.size_flags_vertical = teammate_health_bar.SizeFlags.SIZE_EXPAND_FILL
	team_health_bars.call_deferred("add_child", teammate_health_bar)
	player.health_manager.health_changed.connect(_on_teammate_health_changed.bind(teammate_health_bar))


func _on_teammate_health_changed(_old_value: float, new_value: float, teammate_health_bar: ProgressBar) -> void:
	teammate_health_bar.value = new_value


@rpc("call_local", "any_peer", "reliable", 0)
func _set_teammate_health_mcontainer_size() -> void:
	var number_of_teammates: int = len(multiplayer.get_peers()) - 1 # -1 for the server
	team_health_bars.custom_minimum_size = Vector2(320, (40 + (number_of_teammates - 1) * 60))
