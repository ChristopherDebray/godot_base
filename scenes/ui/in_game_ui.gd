extends Control

@onready var base_ability_indicator: HBoxContainer = $MarginContainer/MarginContainer/HBoxContainer
@onready var cooldown_indicators: HBoxContainer = $MarginContainer/MarginContainer/CooldownIndicators

const ABILITY_COOLDOWN_INDICATOR = preload("res://scenes/ui/ability_cooldown_indicator.tscn")

func _ready() -> void:
	for ability_name in SpellsManager.SPELLS.keys():
		var ability_data = SpellsManager.SPELLS[ability_name] as AbilityData
		var cooldown_indicator = ABILITY_COOLDOWN_INDICATOR.instantiate()
		cooldown_indicator.spell_name = ability_name
		cooldown_indicator.icon = ability_data.icon
		if ability_data.is_base_ability():
			cooldown_indicator.rotation = 45
			base_ability_indicator.add_child(cooldown_indicator)
		else:
			cooldown_indicators.add_child(cooldown_indicator)

func arg():
	for ability_name in SpellsManager.SPELLS.keys():
		var ability_data = SpellsManager.SPELLS[ability_name] as AbilityData
		var cooldown_indicator = ABILITY_COOLDOWN_INDICATOR.instantiate()
		cooldown_indicator.spell_name = ability_name
		cooldown_indicator.icon = ability_data.icon
		if ability_data.is_base_ability():
			base_ability_indicator.add_child(cooldown_indicator)
		else:
			cooldown_indicators.add_child(cooldown_indicator)
