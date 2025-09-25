extends Node

signal use_ability(data: AbilityData, target: Vector2, origin: Vector2)

signal wave_started(total: int)
signal wave_cleared()

signal resource_value_change(amount: float, resource_type: GameManager.RESOURCE_TYPE)
signal died(target: Damageable)

signal ability_started(ability: AbilityData)
signal ability_launched(ability: AbilityData)
signal ability_interrupted(ability: AbilityData)
signal ability_finished(ability: AbilityData)
