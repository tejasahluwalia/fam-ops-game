extends State
class_name PlayerState

var player: PlayerEntity
var character_controller: CharacterController
var input_synchronizer: InputSynchronizer


func _ready() -> void:
	await super._ready()
	character_controller = owner
	player = character_controller.get_parent()
	input_synchronizer = character_controller.input_synchronizer
