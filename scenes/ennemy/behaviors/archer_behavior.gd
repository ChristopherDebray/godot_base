class_name ArcherBehavior
extends EnemyBehavior

var _jitter_timer := 0.0
var _strafe_dir := 1.0

func compute_desired_velocity(enemy: BaseEnemy, delta: float) -> Vector2:
	var player := enemy._player_ref
	if player == null:
		return Vector2.ZERO

	var to_player := player.global_position - enemy.global_position
	var dist := to_player.length()
	var dir := to_player.normalized()

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
