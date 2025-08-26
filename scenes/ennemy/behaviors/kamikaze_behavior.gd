class_name KamikazeBehavior
extends EnemyBehavior

func compute_desired_velocity(enemy: BaseEnemy, delta: float) -> Vector2:
	var player := enemy._player_ref
	if player == null:
		return Vector2.ZERO

	var to_player := player.global_position - enemy.global_position
	var dist := to_player.length()
	var dir := to_player.normalized()

	# kiting
	var move := Vector2.ZERO
	if dist < stop_range:
		move -= dir # backs down
	elif dist > preferred_range:
		move += dir # approaches

	# strafe side
	var perp := Vector2(-dir.y, dir.x)
	move += perp

	return move.normalized() * enemy.speed
