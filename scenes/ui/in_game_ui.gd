extends Control

@onready var base_ability_indicator: HBoxContainer = $MarginContainer/MarginContainer/HBoxContainer
@onready var cooldown_indicators: HBoxContainer = $MarginContainer/MarginContainer/CooldownIndicators

const ABILITY_COOLDOWN_INDICATOR = preload("res://scenes/ui/ability_cooldown_indicator.tscn")
@onready var gold_count: Label = $MarginContainer/MarginContainer/MoneyIndicators/HBoxContainer2/GoldCount
@onready var blood_count: Label = $MarginContainer/MarginContainer/MoneyIndicators/HBoxContainer3/BloodCount

func _ready() -> void:
	SignalManager.update_blood_amount.connect(update_blood_label)
	SignalManager.update_gold_amount.connect(update_gold_label)
	for ability_name in SpellsManager.current_profession_loadout.spells.keys():
		var ability_data = SpellsManager.current_profession_loadout.spells[ability_name] as AbilityData
		var cooldown_indicator = ABILITY_COOLDOWN_INDICATOR.instantiate()
		cooldown_indicator.spell_name = ability_name
		cooldown_indicator.icon = ability_data.icon
		if ability_data.is_base_ability():
			cooldown_indicator.rotation = 45
			base_ability_indicator.add_child(cooldown_indicator)
		else:
			cooldown_indicators.add_child(cooldown_indicator)

func arg():
	for ability_name in SpellsManager.current_profession_loadout.spells.keys():
		var ability_data = SpellsManager.current_profession_loadout.spells[ability_name] as AbilityData
		var cooldown_indicator = ABILITY_COOLDOWN_INDICATOR.instantiate()
		cooldown_indicator.spell_name = ability_name
		cooldown_indicator.icon = ability_data.icon
		if ability_data.is_base_ability():
			base_ability_indicator.add_child(cooldown_indicator)
		else:
			cooldown_indicators.add_child(cooldown_indicator)

func update_gold_label(gold: int):
	gold_count.text = str(gold)

func update_blood_label(blood: int):
	blood_count.text = str(blood)
