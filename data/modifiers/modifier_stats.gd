class_name ModifierStats

var _flat_bonuses := {}      # {ModifierType: float}
var _mult_bonuses := {}      # {ModifierType: float}

func clear() -> void:
	_flat_bonuses.clear()
	_mult_bonuses.clear()

func add_modifier(mod: BaseModifier, stacks: int, rarity_mult: float) -> void:
	var final_value = mod.get_final_value(rarity_mult) * stacks
	
	if mod.is_multiplicative:
		var current = _mult_bonuses.get(mod.type, 1.0)
		_mult_bonuses[mod.type] = current + (final_value - 1.0)
	else:
		var current = _flat_bonuses.get(mod.type, 0.0)
		_flat_bonuses[mod.type] = current + final_value

func get_flat(type: BaseModifier.ModifierType) -> float:
	return _flat_bonuses.get(type, 0.0)

func get_multiplier(type: BaseModifier.ModifierType) -> float:
	return _mult_bonuses.get(type, 1.0)

func apply_to_damage(base_damage: float) -> float:
	var dmg = base_damage + get_flat(BaseModifier.ModifierType.DAMAGE_FLAT)
	dmg *= get_multiplier(BaseModifier.ModifierType.DAMAGE_MULTIPLIER)
	return dmg

func apply_to_size(base_size: float) -> float:
	return base_size * get_multiplier(BaseModifier.ModifierType.SIZE_MULTIPLIER)

func get_bonus_projectiles() -> int:
	return int(get_flat(BaseModifier.ModifierType.PROJECTILE_COUNT))

func get_bonus_piercing() -> int:
	return int(get_flat(BaseModifier.ModifierType.PIERCING))

func get_bonus_chains() -> int:
	return int(get_flat(BaseModifier.ModifierType.CHAIN_COUNT))
