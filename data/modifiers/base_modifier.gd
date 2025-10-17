extends Resource
class_name BaseModifier

enum ModifierType {
	# Ability modifiers
	DAMAGE_MULTIPLIER,
	DAMAGE_FLAT,
	SIZE_MULTIPLIER,
	PROJECTILE_COUNT,
	PIERCING,
	CHAIN_COUNT,
	COOLDOWN_MULTIPLIER,
	SPEED_MULTIPLIER,
	DURATION_MULTIPLIER,
	CAST_TIME_MULTIPLIER,
	
	# Passive modifiers (s'appliquent au Damageable)
	MAX_HEALTH_FLAT,
	MAX_HEALTH_MULTIPLIER,
	MOVEMENT_SPEED_MULTIPLIER,
	ATTACK_SPEED_MULTIPLIER,
	HEALTH_REGEN_FLAT,
	DAMAGE_REDUCTION_FLAT,
	DAMAGE_REDUCTION_PERCENT,
	THORNS_DAMAGE_FLAT,
	
	# Active abilities (déclenchées par le relic)
	ACTIVATE_ABILITY,  # Déclenche une ability (ex: cercle de dégâts)
}

@export var type: ModifierType
@export var value: float = 1.0
@export var tags_required: Array[AbilityData.ABILITY_TAG] = []
@export var weather_condition: EnvironmentManager.WEATHER_TYPE
@export var is_multiplicative: bool = true     # true = * value, false = + value
 
# Pour ACTIVATE_ABILITY
@export var ability_to_spawn: PackedScene = null
@export var trigger_interval: float = 5.0

func applies_to(ability_tags: Array[AbilityData.ABILITY_TAG]) -> bool:
	if tags_required.size() > 0:
		for tag in tags_required:
			if tag not in ability_tags:
				return false
	
	if not weather_condition:
		return true
	
	if weather_condition != GameManager.current_weather_type:
		return false
	
	return true

func get_final_value(rarity_multiplier: float = 1.0) -> float:
	return value * rarity_multiplier

func is_passive_stat() -> bool:
	return type >= ModifierType.MAX_HEALTH_FLAT and type < ModifierType.ACTIVATE_ABILITY

func is_active_ability() -> bool:
	return type == ModifierType.ACTIVATE_ABILITY

func get_description() -> String:
	var desc := ""
	var percent = (value - 1.0) * 100 if is_multiplicative else value
	
	match type:
		ModifierType.DAMAGE_MULTIPLIER:
			desc = "+%.0f%% damage" % percent
		ModifierType.DAMAGE_FLAT:
			desc = "+%.0f damage" % value
		ModifierType.SIZE_MULTIPLIER:
			desc = "+%.0f%% size" % percent
		ModifierType.PROJECTILE_COUNT:
			desc = "+%.0f projectiles" % value
		ModifierType.PIERCING:
			desc = "+%.0f piercing" % value
		ModifierType.CHAIN_COUNT:
			desc = "+%.0f chains" % value
		ModifierType.MAX_HEALTH_FLAT:
			desc = "+%.0f max HP" % value
		ModifierType.MAX_HEALTH_MULTIPLIER:
			desc = "+%.0f%% max HP" % percent
		ModifierType.MOVEMENT_SPEED_MULTIPLIER:
			desc = "+%.0f%% movement speed" % percent
		ModifierType.HEALTH_REGEN_FLAT:
			desc = "+%.0f HP/s" % value
		ModifierType.DAMAGE_REDUCTION_PERCENT:
			desc = "+%.0f%% damage reduction" % percent
		ModifierType.THORNS_DAMAGE_FLAT:
			desc = "+%.0f thorns damage" % value
		ModifierType.ACTIVATE_ABILITY:
			desc = "Triggers ability every %.1fs" % trigger_interval
		_:
			desc = "Unknown effect"
	
	if tags_required.size() > 0:
		desc += " (%s)" % " + ".join(tags_required)
	if weather_condition:
		desc += " [%s]" % weather_condition
	
	return desc
