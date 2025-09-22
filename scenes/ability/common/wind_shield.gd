extends AoeInstantAbility

func _ready() -> void:
	animated_sprite_2d.play('default')

func init(ability_data: AbilityData, ctx: AimContext) -> void:
	start_from(ctx.sender_pos, range)
