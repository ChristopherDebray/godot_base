class_name AimContext
extends Node2D
var sender_pos: Vector2
var muzzle_pos: Vector2
var desired_point: Vector2 = Vector2.ZERO
var desired_dir: Vector2 = Vector2.ZERO
var clamp_point: Vector2 = Vector2.ZERO
var los_clamped_point: Vector2

static func from_mouse(player: Player, instance: BaseAbility) -> AimContext:
	var ctx := AimContext.new()
	if player != null:
		ctx.sender_pos = player.global_position
		ctx.muzzle_pos = player.muzzle.global_position
		ctx.desired_point = player.get_global_mouse_position() # monde
		ctx.clamp_point = CastService.clamp_to_range(
			ctx.sender_pos,
			ctx.desired_point,
			instance.range
		)
		ctx.desired_dir = ctx.sender_pos.direction_to(ctx.clamp_point)
	else:
		ctx.sender_pos = Vector2.ZERO
		ctx.desired_point = Vector2.ZERO
	return ctx

static func from_npc(node: BaseNpc, instance: BaseAbility, target: Vector2) -> AimContext:
	var ctx := AimContext.new()
	if node != null:
		ctx.sender_pos = node.global_position
		ctx.muzzle_pos = node.muzzle.global_position
		ctx.desired_point = target
		ctx.clamp_point = CastService.clamp_to_range(
			ctx.sender_pos,
			ctx.desired_point,
			instance.range
		)
		ctx.desired_dir = ctx.sender_pos.direction_to(ctx.clamp_point)
	
	return ctx

static func from_context(instance: BaseAbility, ctx_target: Vector2, ctx_origin: Vector2) -> AimContext:
	var ctx := AimContext.new()
	ctx.sender_pos = ctx_origin
	ctx.muzzle_pos = ctx_origin
	ctx.desired_point = ctx_target
	ctx.clamp_point = CastService.clamp_to_range(
		ctx.sender_pos,
		ctx.desired_point,
		instance.range
	)
	ctx.desired_dir = ctx.sender_pos.direction_to(ctx.clamp_point)
	
	return ctx
