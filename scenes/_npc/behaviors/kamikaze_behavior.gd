class_name KamikazeBehavior
extends NpcBehavior

func compute_desired_velocity(enemy: BaseNpc, delta: float) -> Vector2:
	var target = enemy._ability_target
	if target == null:
		return Vector2.ZERO

	var to_target = target.global_position - enemy.global_position
	var dist = to_target.length()
	var dir = to_target.normalized()

	# kiting
	var move := Vector2.ZERO
	if dist > preferred_range:
		move += dir # approaches
	else:
		return Vector2(0, 0)

	# strafe side
	var perp := Vector2(-dir.y, dir.x)
	move += perp

	return move.normalized() * enemy.speed
