extends BaseAbility
class_name ProjectileAbility

@export var SPEED: int = 400

var _dir_of_travel: Vector2 = Vector2.ZERO

func init(ability_data: AbilityData, aim_direction: Vector2, start_pos: Vector2) -> void:
	initAbilityResource(ability_data)
	_dir_of_travel = aim_direction
	global_position = start_pos

# Act as the parent on ready
func setup_on_ready():
	super._ready()
	rotation = _dir_of_travel.angle()

func _physics_process(delta: float) -> void:
	if (_has_hit):
		return
	position += SPEED * delta * _dir_of_travel
