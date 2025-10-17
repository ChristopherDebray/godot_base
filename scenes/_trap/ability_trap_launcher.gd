extends BaseActionned


@onready var muzzle: Node2D = $Muzzle

@export var ability: AbilityData

var ability_target: Vector2
var ability_origin: Vector2
var ability_target_type := AbilityManager.TARGET_TYPE.ENEMY

func _ready():
	## TODO move based of mouse_position ?
	# Carreful with the gamepad !
	ability_target = muzzle.global_position + global_position.direction_to(muzzle.global_position)
	ability_origin = muzzle.global_position

func toggle_activation():
	SignalManager.use_ability.emit(ability, ability_target, ability_origin, ability_target_type)
