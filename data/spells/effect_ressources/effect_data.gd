extends Resource
class_name EffectData

@export var name: String
@export var name_enum: EffectsManager.EFFECTS
@export var value: float
@export var value_type: EffectsManager.EFFECT_VALUE_TYPE
@export var type: EffectsManager.EFFECT_TYPE
@export var characteristic: String
@export var duration: float
@export var tick_rate: float
@export var fx_sprite_frames: SpriteFrames

func apply_tick(target: Damageable) -> Dictionary:
	var result := {
		"type": type,
		"applied": {}  # ex: {"speed": +2.0}
	}
	
	match type:
		EffectsManager.EFFECT_TYPE.DAMAGE:
			if characteristic == "health":
				target.apply_damage(value)
		EffectsManager.EFFECT_TYPE.CONTROL:
			if name == "freeze":
				target.freeze()
				result.applied["freeze"] = 1
			if name == "charm":
				target.targeting.charm()
				result.applied["charm"] = 1
			if name == "root":
				target.root()
				result.applied["root"] = 1
		EffectsManager.EFFECT_TYPE.BUFF, EffectsManager.EFFECT_TYPE.DEBUFF:
			var applied := handle_characteristic_modification(
				target,
				type,
				value,
				value_type,
				characteristic
			)
			# applied est 0.0 si la caractéristique n'est pas reconnue
			if abs(applied) > 0.0:
				result.applied[characteristic] = applied
		_:
			print("Effect type not handled:", type)
	
	return result

func handle_characteristic_modification(
	target: Damageable,
	effectType: EffectsManager.EFFECT_TYPE,
	value: float,
	value_type: EffectsManager.EFFECT_VALUE_TYPE,
	characteristic: String
) -> float:
	var final_value = value

	# Apply percentage logic
	if value_type == EffectsManager.EFFECT_VALUE_TYPE.PERCENTAGE:
		match characteristic:
			"speed":
				final_value = target.speed * (value / 100.0)
			"defense":
				final_value = target.defense * (value / 100.0)

	# Apply sign based on effectType
	if effectType == EffectsManager.EFFECT_TYPE.DEBUFF:
		final_value = -abs(final_value)
	else:
		final_value = abs(final_value)

	match characteristic:
		"speed":
			target.modify_speed(final_value)
		"defense":
			target.modify_defense(final_value)
	
	return final_value
