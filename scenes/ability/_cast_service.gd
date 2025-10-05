class_name CastService

static func clamp_to_range(sender_pos: Vector2, desired_pos: Vector2, range: float) -> Vector2:
	var to_target := desired_pos - sender_pos
	var dist := to_target.length()
	if dist == 0.0:
		return sender_pos
	var dir := sender_pos.direction_to(desired_pos)
	var clamped = sender_pos + dir * min(dist, range)
	
	return clamped

static func _compute_aoe_spawn_with_los(
	sender: Damageable,
	ctx: AimContext,
	aoe_radius_px: float,
) -> Vector2:
	if not sender:
		return ctx.desired_point
	sender.raycast_ability_to(ctx.clamp_point)
	var ray := sender.ray_cast_ability

	if not ray.is_colliding():
		return ctx.clamp_point
	var hit_point := ray.get_collision_point()
	
	return hit_point - ctx.desired_dir * aoe_radius_px

static func _coerce_target_world(sender: Node2D, raw_target: Vector2, range_px: float) -> Vector2:
	if sender == null:
		return raw_target
	# If raw_target looks like a Direction, convert to a "world" point
	if raw_target.length() <= 1.5:
		var dir := raw_target
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		else:
			dir = dir.normalized()
		return sender.global_position + dir * range_px
	# Sinon on suppose déjà un point monde
	return raw_target
