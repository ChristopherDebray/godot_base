class_name RelicPool
extends Node

@export var relics_common: Array[BaseRelic]
@export var relics_rare: Array[BaseRelic]
@export var relics_epic: Array[BaseRelic]

const RELIC_RATE = {
	'common': 0.70,
	'rare': 0.45,
	'epic': 0.15,
	'legendary': 0.05,
}

func pick_relic_amount(amount: int, wave_index: int) -> Array[BaseRelic]:
	var p_common := RELIC_RATE.common
	var p_rare := RELIC_RATE.rare
	var p_epic := RELIC_RATE.epic
	# Slight pity over time
	var bonus = clamp(float(wave_index) * 0.01, 0.0, 0.10)
	p_rare += bonus
	p_epic += bonus * 0.5
	p_common = 1.0 - p_rare - p_epic

	var out: Array[BaseRelic] = []
	for i in amount:
		var roll := randf()
		var pool := relics_common
		if roll < p_epic and relics_epic.size() > 0:
			pool = relics_epic
		elif roll < p_epic + p_rare and relics_rare.size() > 0:
			pool = relics_rare
		out.append(pool[randi() % pool.size()])
	return out
