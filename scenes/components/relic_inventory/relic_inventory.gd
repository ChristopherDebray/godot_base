class_name RelicInventory
extends Node

signal relic_added(relic: BaseRelic, stacks: int)

var stacks_by_id: Dictionary = {}  # {StringName: int}
var relics_by_id: Dictionary = {}   # {StringName: m}
var _owner: Damageable

func setup(owner: Damageable):
	_owner = owner

func add_relic(relic: BaseRelic, stacks: int = 1) -> void:
	var current = stacks_by_id.get(relic.relic_id, 0)
	var new_stacks = min(relic.max_stacks, current + stacks)
	var added_stacks = new_stacks - current
	
	if added_stacks > 0:
		stacks_by_id[relic.relic_id] = new_stacks
		relics_by_id[relic.relic_id] = relic
		relic.apply(_owner, added_stacks)
		relic_added.emit(relic, new_stacks)

func remove_relic(relic_id: StringName, stacks: int = 1) -> void:
	if not relics_by_id.has(relic_id):
		return
	
	var current = stacks_by_id[relic_id]
	var new_stacks = max(0, current - stacks)
	
	if new_stacks == 0:
		relics_by_id[relic_id].remove(get_parent(), current)
		relics_by_id.erase(relic_id)
		stacks_by_id.erase(relic_id)
	else:
		relics_by_id[relic_id].remove(get_parent(), stacks)
		stacks_by_id[relic_id] = new_stacks

func get_modifiers_for_ability(ability: AbilityData) -> ModifierStats:
	var stats = ModifierStats.new()
	
	for relic_id in relics_by_id:
		var relic: BaseRelic = relics_by_id[relic_id]
		var stacks = stacks_by_id[relic_id]
		var rarity_mult = relic.get_rarity_multiplier()
		
		# Récupérer les modifiers applicables
		var applicable_mods = relic.get_modifiers_for_ability(ability)
		for mod in applicable_mods:
			stats.add_modifier(mod, stacks, rarity_mult)
	
	return stats

func get_all_relics() -> Array[BaseRelic]:
	var result: Array[BaseRelic] = []
	for relic in relics_by_id.values():
		result.append(relic)
	return result

func get_relic_stacks(relic_id: StringName) -> int:
	return stacks_by_id.get(relic_id, 0)
