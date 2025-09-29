class_name SkirmisherBehavior
extends NpcBehavior

var _jitter_timer := 0.0
var _strafe_dir := 1.0

func steering(npc: BaseNpc, delta: float, path_velocity: Vector2) -> Vector2:
	var target := npc._ability_target
	if target == null or not is_instance_valid(target):
		return Vector2.ZERO

	var to_target := target.global_position - npc.global_position
	var dist := to_target.length()
	var dir := Vector2.ZERO
	if (dist > 0.0):
		dir = to_target / dist

	# Jitter to change straf size
	_jitter_timer -= delta
	if _jitter_timer <= 0.0:
		_jitter_timer = jitter
		_strafe_dir = 1.0
		if (randf() < 0.5):
			_strafe_dir = -1.0

	var steer := Vector2.ZERO

	# Kiting
	if dist < stop_range:
		steer -= dir
	elif dist > preferred_range:
		steer += dir

	# Strafe
	var perp := Vector2(-dir.y, dir.x) * _strafe_dir * strafe_bias
	steer += perp

	# Mixed with path
	return steer.limit_length(npc.speed * 0.6)
