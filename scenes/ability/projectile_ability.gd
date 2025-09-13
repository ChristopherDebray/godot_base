extends BaseAbility
class_name ProjectileAbility

@export var SPEED: float = 400.0
var _dir_of_travel: Vector2 = Vector2.ZERO

func init(ability_data: AbilityData, aim: AimContext, start_pos: Vector2) -> void:
	global_position = start_pos

	# Prend la direction depuis l’aim résolu (si souris: vers la souris; sinon: dir fournie)
	var res := CastService.resolve_aim_target(start_pos, aim, range)
	_dir_of_travel = res.dir
	if _dir_of_travel == Vector2.ZERO:
		# fallback si aucun input: droite
		_dir_of_travel = Vector2.RIGHT

	# Range unifié : on coupe quand on dépasse la distance depuis l’origine
	start_from(start_pos, range)

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
