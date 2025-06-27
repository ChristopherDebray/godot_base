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

func apply_tick(target: Damageable) -> void:
	match type:
		EffectsManager.EFFECT_TYPE.DAMAGE:
			if characteristic == "health":
				target.apply_damage(value)
		EffectsManager.EFFECT_TYPE.CONTROL:
			if name == "freeze":
				target.freeze(duration)
		EffectsManager.EFFECT_TYPE.BUFF:
			handle_characteristic_modification(
				target,
				EffectsManager.EFFECT_TYPE.BUFF,
				value,
				value_type,
				characteristic
			)
		EffectsManager.EFFECT_TYPE.DEBUFF:
			handle_characteristic_modification(
				target,
				EffectsManager.EFFECT_TYPE.DEBUFF,
				value,
				value_type,
				characteristic
			)
		EffectsManager.EFFECT_TYPE.BUFF:
			target.add_buff(characteristic, value)
		_:
			print("Effect type not handled:", type)

func handle_characteristic_modification(
	target: Damageable,
	effectType: EffectsManager.EFFECT_TYPE,
	value: float,
	value_type: EffectsManager.EFFECT_VALUE_TYPE,
	characteristic: String
):
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
