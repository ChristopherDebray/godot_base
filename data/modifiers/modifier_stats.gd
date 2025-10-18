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
		return
	
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

func apply_to_speed(base_speed: float) -> float:
	return base_speed * get_multiplier(BaseModifier.ModifierType.SPEED_MULTIPLIER)

func get_bonus_projectiles() -> int:
	return int(get_flat(BaseModifier.ModifierType.PROJECTILE_COUNT))

func get_bonus_piercing() -> int:
	return int(get_flat(BaseModifier.ModifierType.PIERCING))

func get_bonus_chains() -> int:
	return int(get_flat(BaseModifier.ModifierType.CHAIN_COUNT))

func apply_to_cooldown(base_cooldown: float) -> float:
	return base_cooldown * get_multiplier(BaseModifier.ModifierType.COOLDOWN_MULTIPLIER)

# Passive stats (pour Damageable)
func apply_to_max_health(base_health: float) -> float:
	var hp = base_health + get_flat(BaseModifier.ModifierType.MAX_HEALTH_FLAT)
	hp *= get_multiplier(BaseModifier.ModifierType.MAX_HEALTH_MULTIPLIER)
	return hp

func apply_to_movement_speed(base_speed: float) -> float:
	return base_speed * get_multiplier(BaseModifier.ModifierType.MOVEMENT_SPEED_MULTIPLIER)

func get_health_regen() -> float:
	return get_flat(BaseModifier.ModifierType.HEALTH_REGEN_FLAT)

func get_damage_reduction() -> float:
	return get_flat(BaseModifier.ModifierType.DAMAGE_REDUCTION_FLAT) + \
		   get_multiplier(BaseModifier.ModifierType.DAMAGE_REDUCTION_PERCENT)

func get_thorns_damage() -> float:
	return get_flat(BaseModifier.ModifierType.THORNS_DAMAGE_FLAT)
