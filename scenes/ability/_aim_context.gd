class_name AimContext
extends Node2D
var sender_pos: Vector2
var has_point: bool = false
var desired_point: Vector2 = Vector2.ZERO
var has_dir: bool = false
var desired_dir: Vector2 = Vector2.ZERO

static func from_mouse(player: Node2D) -> AimContext:
	var ctx := AimContext.new()
	if player != null:
		ctx.sender_pos = player.global_position
		ctx.has_point = true
		ctx.desired_point = player.get_global_mouse_position() # monde
	else:
		ctx.sender_pos = Vector2.ZERO
		ctx.has_point = false
		ctx.desired_point = Vector2.ZERO
	return ctx

static func from_dir(sender_pos: Vector2, dir: Vector2) -> AimContext:
	var ctx := AimContext.new()
	ctx.sender_pos = sender_pos
	ctx.has_dir = true
	ctx.desired_dir = dir

	return ctx

static func from_point(sender_pos: Vector2, world_point: Vector2) -> AimContext:
	var ctx := AimContext.new()
	ctx.sender_pos = sender_pos
	ctx.has_point = true
	ctx.desired_point = world_point
	return ctx
