extends Node

signal use_ability(data: AbilityData, target: Vector2, origin: Vector2)

signal wave_started(total: int)
signal wave_cleared()

signal died(target: Damageable)
