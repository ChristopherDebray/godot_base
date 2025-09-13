class_name CastService

static func safe_dir(dir: Vector2, fallback_vec: Vector2) -> Vector2:
	return dir if dir != Vector2.ZERO else fallback_vec.normalized()

static func clamp_to_range(sender_pos: Vector2, desired_pos: Vector2, range: float) -> Vector2:
	var v := desired_pos - sender_pos
	var dist := v.length()
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
	print('HELLO')
	sender.raycast_ability_to(ctx.clamp_point)

	var ray := sender.ray_cast_ability

	if not ray.is_colliding():
		print(ctx.clamp_point)
		return ctx.clamp_point
		
	var hit_point := ray.get_collision_point()
	print('HIT_POINT')
	print(hit_point)
	print(hit_point - ctx.desired_dir)
	print('aoe_radius_px')
	print(aoe_radius_px)
	print(hit_point - ctx.desired_dir * aoe_radius_px)
	
	ctx.sender_pos + hit_point
	
	return hit_point - ctx.desired_dir * aoe_radius_px
