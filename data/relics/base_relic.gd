extends Resource
class_name BaseRelic

enum RARITY {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

const RARITY_TEXT = {
	RARITY.COMMON: 'Common',
	RARITY.RARE: 'Rare',
	RARITY.EPIC: 'Epic',
	RARITY.LEGENDARY: 'Legendary',
}

const RARITY_MULTIPLIERS = {
	RARITY.COMMON: 1.0,
	RARITY.RARE: 1.25,
	RARITY.EPIC: 1.5,
	RARITY.LEGENDARY: 2.0,
}

const RARITY_COLORS = {
	RARITY.COMMON: Color.WHITE,
	RARITY.RARE: Color(0.4, 0.7, 1.0),
	RARITY.EPIC: Color(0.7, 0.3, 1.0),
	RARITY.LEGENDARY: Color(1.0, 0.6, 0.0),
}

@export var relic_id: StringName
@export var display_name: String
@export_multiline var description: String
@export var rarity := RARITY.COMMON
@export var max_stacks := 5
@export var modifiers: Array[BaseModifier] = []
@export var flavor_text: String = ""        # Texte d'ambiance (optionnel)

func apply(owner: Node, stacks: int) -> void:
	# Appelé quand on gagne des stacks
	if owner.has_method("add_relic_modifiers"):
		owner.add_relic_modifiers(self, stacks)

func remove(owner: Node, stacks: int) -> void:
	if owner.has_method("remove_relic_modifiers"):
		owner.remove_relic_modifiers(self, stacks)

func get_modifiers_for_ability(ability: AbilityData) -> Array[BaseModifier]:
	var result: Array[BaseModifier] = []
	for mod in modifiers:
		if mod.applies_to(ability.tags):
			result.append(mod)
	return result

func get_rarity_color() -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

func get_auto_description() -> String:
	if modifiers.is_empty():
		return "No effects"
	
	var lines: Array[String] = []
	for mod in modifiers:
		lines.append(mod.get_description())
	
	return "\n".join(lines)

func get_full_description(stacks: int = 1) -> String:
	"""Description complète avec les stacks"""
	var text = description if description != "" else get_auto_description()
	
	if stacks > 1:
		text += "\n\n[Stack %d/%d]" % [stacks, max_stacks]
	
	if flavor_text != "":
		text += "\n\n[i]%s[/i]" % flavor_text
	
	return text

func get_rarity_multiplier() -> float:
	return RARITY_MULTIPLIERS.get(rarity, 1.0)
