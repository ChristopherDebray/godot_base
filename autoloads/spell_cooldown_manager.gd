extends Node

const SpellEnums = preload("res://data/spells/enums.gd")

var _cooldowns := {}

func _combo_key(arr: Array[SpellEnums.ELEMENTS]) -> String:
	var sorted = arr.duplicate()
	sorted.sort()
	return ",".join(PackedStringArray(sorted.map(func(x): return str(x))))

func can_cast(key: Array) -> bool:
	var combo_key = _combo_key(key)
	if not _cooldowns.has(combo_key):
		return true

	var remaining = _cooldowns[combo_key] - Time.get_ticks_msec() / 1000.0
	return remaining <= 0

func set_cooldown(key: Array, duration: float):
	key.sort()
	var combo_key = _combo_key(key)
	_cooldowns[combo_key] = Time.get_ticks_msec() / 1000.0 + duration

func get_remaining(key: Array) -> float:
	var combo_key = _combo_key(key)
	if not _cooldowns.has(combo_key):
		return 0.0
	return max(0.0, _cooldowns[combo_key] - Time.get_ticks_msec() / 1000.0)
