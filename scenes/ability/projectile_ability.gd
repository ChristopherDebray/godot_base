extends BaseAbility
class_name ProjectileAbility

@export var SPEED: float = 400.0
var _dir_of_travel: Vector2 = Vector2.ZERO

func init(ability_data: AbilityData, ctx: AimContext) -> void:
	_dir_of_travel = ctx.desired_dir
	start_from(ctx.sender_pos, range)

func setup_on_ready() -> void:
	super._ready()
	rotation = _dir_of_travel.angle()

func _physics_process(delta: float) -> void:
	if _has_hit:
		return
	global_position += SPEED * delta * _dir_of_travel
	if has_exceeded_range(global_position):
		on_ability_timeout()

## If homing or curved projectile
#var _traveled := 0.0
#func _physics_process(delta: float) -> void:
	#if _has_hit: return
	#var vel := compute_velocity(delta)  # ta logique
	#var step := vel * delta
	#_traveled += step.length()
	#global_position += step
	#if _traveled >= range:
		#on_ability_timeout()
