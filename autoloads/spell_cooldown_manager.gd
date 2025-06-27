extends Node

var _cooldowns := {}

func _combo_key(arr: Array[SpellsManager.ELEMENTS]) -> String:
	var sorted = arr.duplicate()
	sorted.sort()
	return ",".join(PackedStringArray(sorted.map(func(x): return str(x))))

func can_cast(key: Array) -> bool:
	var combo_key = _combo_key(key)
	var spellKey = SpellsManager.SPELLS_ELEMENTS.get(combo_key)
	if not spellKey:
		return false
	
	if not _cooldowns.has(spellKey):
		return true

	var remaining = _cooldowns[spellKey] - Time.get_ticks_msec() / 1000.0
	return remaining <= 0

func set_cooldown(spellName: String, duration: float):
	_cooldowns[spellName] = duration

func get_remaining(key: String) -> float:
	if not _cooldowns.has(key):
		return 0.0
	return max(0.0, _cooldowns[key] - Time.get_ticks_msec() / 1000.0)
