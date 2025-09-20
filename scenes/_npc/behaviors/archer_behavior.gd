class_name ArcherBehavior
extends NpcBehavior

var _jitter_timer := 0.0
var _strafe_dir := 1.0

func compute_desired_velocity(enemy: BaseNpc, delta: float) -> Vector2:
	var target = enemy._ability_target
	if target == null:
		return Vector2.ZERO

	var to_target = target.global_position - enemy.global_position
	var dist = to_target.length()
	var dir = to_target.normalized()

	_jitter_timer -= delta
	if _jitter_timer <= 0.0:
		_jitter_timer = jitter
		_strafe_dir = sign(randf() - 0.5) # -1 or 1

	# kiting
	var move := Vector2.ZERO
	if dist < stop_range:
		move -= dir # backs down
	elif dist > preferred_range:
		move += dir # approaches

	# strafe side
	var perp := Vector2(-dir.y, dir.x)
	move += perp * _strafe_dir * strafe_bias

	return move.normalized() * enemy.speed
