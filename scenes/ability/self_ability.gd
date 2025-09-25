extends BaseAbility
class_name SelfAbility

@export var SPEED: float = 400.0
var _dir_of_travel: Vector2 = Vector2.ZERO

func init(ability_data: AbilityData, ctx: AimContext) -> void:
	_dir_of_travel = ctx.desired_dir
	start_from(Vector2(0, 0), range)

func setup_on_ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	if _has_hit:
		return
	#global_position += SPEED * delta * _dir_of_travel
	sender.global_position += SPEED * delta * _dir_of_travel
	if has_exceeded_range(global_position):
		on_ability_timeout()
