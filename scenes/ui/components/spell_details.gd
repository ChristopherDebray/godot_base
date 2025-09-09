extends Control
class_name SpellDetails

@onready var elements_container: HBoxContainer = $VBoxContainer/HBoxContainer/ElementsContainer
@onready var name_label: Label = $VBoxContainer/HBoxContainer/NameLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel

var spell_data: SpellData

func setup(spell: SpellData):
	spell_data = spell
	name_label.text = spell.name
	
	# Add element icons
	for elem in spell.elements:
		var icon = UiManager.get_element_icon_texture_rect(elem)
		elements_container.add_child(icon)
	
	# Set stats text
	var effect = spell.effect.name if spell.effect else "None"

	stats_label.text = "- Damage: %s\n- AoE dammage: %s\n- Effect: %s\n- Main element: %s" % [
		spell.damage,
		spell.aoe_damage,
		effect,
		SpellsManager.ELEMENTS_STRING[spell.main_element]
	]

func _make_custom_tooltip(for_text):
	var tooltip = preload("res://scenes/ui/components/tooltip.tscn").instantiate()
	tooltip.setup('Hello')
	return tooltip
