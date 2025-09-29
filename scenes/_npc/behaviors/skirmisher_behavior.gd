class_name SkirmisherBehavior
extends NpcBehavior

var _jitter_timer_seconds: float = 0.0
var _strafe_sign: float = 1.0

# Target = anchor point on a ring around the target (middle of the band)
func compute_target(npc: BaseNpc) -> Vector2:
	var target_node := npc._ability_target
	if target_node == null or not is_instance_valid(target_node):
		return npc.global_position

	var vector_target_to_npc := npc.global_position - target_node.global_position
	if vector_target_to_npc.length() <= 0.001:
		vector_target_to_npc = Vector2.RIGHT

	var ring_radius := (stop_range + preferred_range) * 0.5
	var direction_from_target := vector_target_to_npc.normalized()
	return target_node.global_position + direction_from_target * ring_radius

func steering(npc: BaseNpc, delta: float, path_velocity: Vector2) -> Vector2:
	var target_node := npc._ability_target
	if target_node == null or not is_instance_valid(target_node):
		return Vector2.ZERO

	var to_target := target_node.global_position - npc.global_position
	var distance_to_target := to_target.length()
	if distance_to_target <= 0.001:
		return Vector2.ZERO

	var direction_to_target := to_target / distance_to_target

	# Randomly flip strafe side at jitter interval
	_jitter_timer_seconds -= delta
	if _jitter_timer_seconds <= 0.0:
		_jitter_timer_seconds = max(0.08, jitter)
		if randf() < 0.5:
			_strafe_sign = -_strafe_sign
		else:
			_strafe_sign = _strafe_sign

	var steering := Vector2.ZERO

	# Radial kiting
	if distance_to_target < stop_range:
		steering -= direction_to_target       # back off
	elif distance_to_target > preferred_range:
		steering += direction_to_target       # move in a bit

	# Perpendicular strafe
	var perpendicular := Vector2(-direction_to_target.y, direction_to_target.x) * _strafe_sign * strafe_bias
	steering += perpendicular

	# Scale to speed; final clamp happens in locomotion
	if steering.length() > 0.001:
		return steering.normalized() * npc.speed
	return Vector2.ZERO
