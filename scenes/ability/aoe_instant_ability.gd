extends BaseAbility
class_name AoeInstantAbility

## The size of the aoe in tiles, used to avoid collision with a wall
@export var aoe_radius_tiles: float = 1.0

func init(ability_data: AbilityData, ctx: AimContext) -> void:
	start_from(ctx.los_clamped_point, range)

func _get_aoe_radius() -> float:
	return UnitUtils.tiles_to_px(aoe_radius_tiles)
