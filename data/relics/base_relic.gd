extends Resource
class_name BaseRelic

enum RARITY {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

const RARITY_MULTIPLIERS = {
	RARITY.COMMON: 1.0,
	RARITY.RARE: 1.25,
	RARITY.EPIC: 1.5,
	RARITY.LEGENDARY: 2.0,
}

@export var relic_id: StringName
@export var display_name: String
@export var description: String
@export var rarity := RARITY.COMMON
@export var max_stacks := 5
@export var modifiers: Array[BaseModifier] = []  # Les effets de la relique

func apply(owner: Node, stacks: int) -> void:
	# Appelé quand on gagne des stacks
	if owner.has_method("add_relic_modifiers"):
		owner.add_relic_modifiers(self, stacks)

func remove(owner: Node, stacks: int) -> void:
	if owner.has_method("remove_relic_modifiers"):
		owner.remove_relic_modifiers(self, stacks)

func get_modifiers_for_ability(ability_tags: Array[String], weather: String = "") -> Array[BaseModifier]:
	"""Retourne les modifiers qui s'appliquent à une ability donnée"""
	var result: Array[BaseModifier] = []
	for mod in modifiers:
		if mod.applies_to(ability_tags, weather):
			result.append(mod)
	return result

func get_rarity_multiplier() -> float:
	return RARITY_MULTIPLIERS.get(rarity, 1.0)
