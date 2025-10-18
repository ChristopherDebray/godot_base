extends BaseAbility
class_name AoeInstantAbility

## The size of the aoe in tiles, used to avoid collision with a wall
@export var aoe_radius_tiles: float = 1.0
var telegraph

func _ready():
	super._ready()
	begin_cast_flow()
	if ability_resource.faction != AbilityData.ABILITY_FACTION.PLAYER:
		return
	
	if final_cast_time > 0:
		set_telegraph()

func set_telegraph() -> void:
	telegraph = TelegraphPolygon.generate_telegraph(area_of_effect_collision_shape, self.target_type)
	self.add_child(telegraph)

func delay_ability() -> void:
	if must_delay_ability:
		delay_timer.start()

func init(ability_data: AbilityData, ctx: AimContext) -> void:
	start_from(ctx.los_clamped_point, range)

func _get_aoe_radius() -> float:
	return UnitUtils.tiles_to_px(aoe_radius_tiles)
