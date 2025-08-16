extends BaseAbility
class_name AoeInstantAbility

func init(ability_data: AbilityData, target_pos: Vector2) -> void:
	initAbilityResource(ability_data)
	global_position = target_pos
