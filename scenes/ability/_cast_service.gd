class_name CastService

static func safe_dir(dir: Vector2, fallback_vec: Vector2) -> Vector2:
	return dir if dir != Vector2.ZERO else fallback_vec.normalized()

static func clamp_to_range(sender_pos: Vector2, desired_pos: Vector2, range: float) -> Dictionary:
	var v := desired_pos - sender_pos
	var dist := v.length()
	if dist == 0.0:
		return {"dir": Vector2.ZERO, "dist": 0.0, "point": sender_pos}
	var dir := v / dist
	var clamped = sender_pos + dir * min(dist, range)
	return {"dir": dir, "dist": min(dist, range), "point": clamped}

static func resolve_aim_target(sender_pos: Vector2, ctx: AimContext, range: float) -> Dictionary:
	if ctx.has_point:
		return clamp_to_range(sender_pos, ctx.desired_point, range)
	elif ctx.has_dir and ctx.desired_dir != Vector2.ZERO:
		var dir := ctx.desired_dir.normalized()
		return {"dir": dir, "dist": range, "point": sender_pos + dir * range}
	else:
		return {"dir": Vector2.ZERO, "dist": 0.0, "point": sender_pos}

static func resolve_aoe_los(
	space: PhysicsDirectSpaceState2D,
	sender_pos: Vector2,
	clamped: Vector2,
	dir: Vector2,
	aoe_radius: float,
	walls_mask: int,
) -> Vector2:
	var q := PhysicsRayQueryParameters2D.create(sender_pos, clamped)
	q.collision_mask = walls_mask
	var hit := space.intersect_ray(q)

	if !hit:
		return clamped

	var final_dir := safe_dir(dir, clamped - sender_pos)
	return hit.position - final_dir * max(aoe_radius, 2.0)

func _compute_aoe_spawn_with_los(
	sender: Damageable,
	clamped_point: Vector2,
	dir: Vector2,
	aoe_radius_tiles: float,
) -> Vector2:
	var sp := sender.global_position
	sender.raycast_ability_to(clamped_point)
	var ray := sender.ray_cast_ability

	if not ray.is_colliding():
		return clamped_point
		
	var hit_point := ray.get_collision_point()
	var aoe_radius_px := aoe_radius_tiles * UnitUtils.TILE_SIZE
	if aoe_radius_px < 2.0:
		aoe_radius_px = 2.0
	
	return hit_point - dir * aoe_radius_px
