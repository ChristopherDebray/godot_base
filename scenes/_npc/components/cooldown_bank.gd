extends Node
class_name CooldownBank

var _cooldowns: Dictionary = {} # key: String (ability.name), value: float (epoch seconds)

func can_use(ability: AbilityData) -> bool:
	var key := ability.name
	if not _cooldowns.has(key):
		return true
	var remaining = _cooldowns[key] - Time.get_ticks_msec() / 1000.0
	return remaining <= 0.0

func start(ability: AbilityData, duration: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_cooldowns[ability.name] = now + max(0.0, duration)

func remaining(ability: AbilityData) -> float:
	var key := ability.name
	if not _cooldowns.has(key):
		return 0.0
	return max(0.0, _cooldowns[key] - Time.get_ticks_msec() / 1000.0)
