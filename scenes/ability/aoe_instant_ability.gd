extends BaseAbility
class_name AoeInstantAbility

@export var WALLS_MASK_BIT: int = 1
## The size of the aoe in tiles, used to avoid collision with a wall
@export var aoe_radius_tiles: float = 1.0

func init(ability_data: AbilityData, ctx: AimContext) -> void:
	# -- Récupère proprement la position du sender
	var sp: Vector2 = ctx.sender_pos
	
	# 1) Clamp dans le disque via l’aim context
	var aim_res := CastService.resolve_aim_target(sp, ctx, range)
	var clamped_point: Vector2 = aim_res.point
	var dir: Vector2 = aim_res.dir

	# 2) LOS unique (on passe le space explicitement)
	var radius := _get_aoe_radius()
	var walls_mask := 1 << WALLS_MASK_BIT
	#var space := get_world_2d().direct_space_state

	#var final_pos := CastService.resolve_aoe_los(
		#space, sp, clamped_point, dir, radius, walls_mask
	#)
	var final_pos = clamped_point

	global_position = final_pos
	start_from(sp, range)


func _get_aoe_radius() -> float:
	return UnitUtils.tiles_to_px(aoe_radius_tiles)
