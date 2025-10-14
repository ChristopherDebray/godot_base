class_name RelicInventory
extends Node

signal relic_added(relic: BaseRelic, stacks: int)

var stacks_by_id: Dictionary = {}  # {StringName: int}
var relics_by_id: Dictionary = {}   # {StringName: BaseRelic}

func add_relic(relic: BaseRelic, stacks: int = 1) -> void:
	var current = stacks_by_id.get(relic.relic_id, 0)
	var new_stacks = min(relic.max_stacks, current + stacks)
	var added_stacks = new_stacks - current
	
	if added_stacks > 0:
		stacks_by_id[relic.relic_id] = new_stacks
		relics_by_id[relic.relic_id] = relic
		relic.apply(_get_owner_player(), added_stacks)
		relic_added.emit(relic, new_stacks)

func get_modifiers_for_ability(ability_tags: Array[String], weather: String = "") -> ModifierStats:
	"""Calcule tous les modifiers qui s'appliquent à une ability"""
	var stats = ModifierStats.new()
	
	for relic_id in relics_by_id:
		var relic: BaseRelic = relics_by_id[relic_id]
		var stacks = stacks_by_id[relic_id]
		var rarity_mult = relic.get_rarity_multiplier()
		
		# Récupérer les modifiers applicables
		var applicable_mods = relic.get_modifiers_for_ability(ability_tags, weather)
		for mod in applicable_mods:
			stats.add_modifier(mod, stacks, rarity_mult)
	
	return stats

func _get_owner_player() -> Node:
	return GameManager.player
