extends Node

signal on_add_relic(relic: BaseRelic)

const RELIC_RATE = {
	'common': 0.70,
	'rare': 0.45,
	'epic': 0.15,
	'legendary': 0.05,
}

const RARITY_KEYS := ["legendary", "epic", "rare", "common"]

# Relics are autoloaded from the data folders
var relics_common: Array[BaseRelic] = []
var relics_rare: Array[BaseRelic] = []
var relics_epic: Array[BaseRelic] = []
var relics_legendary: Array[BaseRelic] = []

# Cache de toutes les reliques par ID
var _relics_by_id: Dictionary = {}  # {StringName: BaseRelic}
var relics: Array[BaseRelic] = []

func _ready() -> void:
	_load_all_relics()
	print("RelicPool loaded: %d common, %d rare, %d epic, %d legendary" % [
		relics_common.size(),
		relics_rare.size(),
		relics_epic.size(),
		relics_legendary.size()
	])

func _load_all_relics() -> void:
	"""Charge automatiquement toutes les reliques depuis les dossiers"""
	relics_common = _load_relics_from_folder("res://data/relics/common/")
	relics_rare = _load_relics_from_folder("res://data/relics/rare/")
	relics_epic = _load_relics_from_folder("res://data/relics/epic/")
	relics_legendary = _load_relics_from_folder("res://data/relics/legendary/")
	
	# Remplir le cache par ID
	for relic in relics_common + relics_rare + relics_epic + relics_legendary:
		_relics_by_id[relic.relic_id] = relic

func _load_relics_from_folder(folder_path: String) -> Array[BaseRelic]:
	"""Charge toutes les reliques .tres d'un dossier"""
	var relics: Array[BaseRelic] = []
	var dir = DirAccess.open(folder_path)
	
	if dir == null:
		push_warning("RelicPool: Folder not found: %s" % folder_path)
		return relics
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path = folder_path + file_name
			var relic = load(full_path) as BaseRelic
			if relic:
				relics.append(relic)
			else:
				push_warning("RelicPool: Failed to load relic: %s" % full_path)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return relics

func pick_relic_amount(amount: int, wave_index: int = 0) -> Array[BaseRelic]:
	# Backward compatibility (no external excludes here)
	return pick_relics_filtered(amount, wave_index, [])

#func pick_relic_amount(amount: int, wave_index: int = 0) -> Array[BaseRelic]:
	#"""Pick un certain nombre de reliques selon la progression"""
	#var p_common := RELIC_RATE.common
	#var p_rare := RELIC_RATE.rare
	#var p_epic := RELIC_RATE.epic
	#
	## Pity system : augmente les chances de rares/epics avec la progression
	#var bonus = clamp(float(wave_index) * 0.01, 0.0, 0.10)
	#p_rare += bonus
	#p_epic += bonus * 0.5
	#p_common = 1.0 - p_rare - p_epic
	#
	#var result: Array[BaseRelic] = []
	#for i in amount:
		#var relic = _pick_one_relic(p_common, p_rare, p_epic)
		#if relic:
			#result.append(relic)
	#
	#return result

func _pick_one_relic(p_common: float, p_rare: float, p_epic: float) -> BaseRelic:
	var roll := randf()
	var pool: Array[BaseRelic]
	
	# Déterminer la rareté
	if roll < p_epic and relics_epic.size() > 0:
		pool = relics_epic
	elif roll < p_epic + p_rare and relics_rare.size() > 0:
		pool = relics_rare
	elif relics_common.size() > 0:
		pool = relics_common
	else:
		# Fallback si un pool est vide
		pool = relics_rare if relics_rare.size() > 0 else relics_epic
	
	if pool.is_empty():
		push_warning("RelicPool: No relics available!")
		return null
	
	return pool.pick_random()

func get_relic_by_id(relic_id: StringName) -> BaseRelic:
	return _relics_by_id.get(relic_id, null)

func get_all_relics() -> Array[BaseRelic]:
	var all: Array[BaseRelic] = []
	all.append_array(relics_common)
	all.append_array(relics_rare)
	all.append_array(relics_epic)
	all.append_array(relics_legendary)
	return all

func get_relics_by_rarity(rarity: BaseRelic.RARITY) -> Array[BaseRelic]:
	match rarity:
		BaseRelic.RARITY.COMMON:
			return relics_common
		BaseRelic.RARITY.RARE:
			return relics_rare
		BaseRelic.RARITY.EPIC:
			return relics_epic
		BaseRelic.RARITY.LEGENDARY:
			return relics_legendary
		_:
			return []

func pick_relics_filtered(amount: int, wave_index: int, exclude_ids: Array[StringName] = []) -> Array[BaseRelic]:
	"""Pick 'amount' unique relics (no duplicates in the single roll),
	respecting exclude_ids and applying pity on rarity probabilities."""
	var probabilities := _compute_probabilities(wave_index)
	var pools := _build_filtered_pools(exclude_ids)

	# Compute how many are actually available
	var total_available = pools["common"].size() + pools["rare"].size() + pools["epic"].size() + pools["legendary"].size()
	var target = min(amount, total_available)

	var result: Array[BaseRelic] = []
	for i in range(target):
		var rarity := _roll_rarity(probabilities)
		var relic := _pick_from_pool_without_replacement(pools, rarity)
		if relic != null:
			result.append(relic)
		else:
			# All pools empty — break early
			break

	return result

#func pick_relics_filtered(amount: int, wave_index: int, exclude_ids: Array[StringName] = []) -> Array[BaseRelic]:
	#"""Pick des reliques en excluant certaines (ex: déjà possédées au max stacks)"""
	## Créer des pools temporaires sans les exclus
	#var filtered_common = relics_common.filter(func(r): return r.relic_id not in exclude_ids)
	#var filtered_rare = relics_rare.filter(func(r): return r.relic_id not in exclude_ids)
	#var filtered_epic = relics_epic.filter(func(r): return r.relic_id not in exclude_ids)
	#
	## Swap temporaire
	#var original_common = relics_common
	#var original_rare = relics_rare
	#var original_epic = relics_epic
	#
	#relics_common = filtered_common
	#relics_rare = filtered_rare
	#relics_epic = filtered_epic
	#
	#var result = pick_relic_amount(amount, wave_index)
	#
	## Restore
	#relics_common = original_common
	#relics_rare = original_rare
	#relics_epic = original_epic
	#
	#return result

func restore_player_relics(player: Player):
	for relic in relics:
		player.relic_inventory.add_relic(relic)

func _compute_probabilities(wave_index: int) -> Dictionary:
	# Base probabilities (copy so we can mutate)
	var p := {
		"common": RELIC_RATE.common,
		"rare": RELIC_RATE.rare,
		"epic": RELIC_RATE.epic,
		"legendary": RELIC_RATE.legendary,
	}

	# Pity system — tune the weights as you like
	# Idea: mostly buff rare/epic, un peu legendary
	var bonus = clamp(float(wave_index) * 0.01, 0.0, 0.10)
	p["rare"] += bonus
	p["epic"] += bonus * 0.5
	p["legendary"] += bonus * 0.2

	# Renormalize to 1.0 (avoid negative common if buffs overflow)
	var sum_other = p["rare"] + p["epic"] + p["legendary"]
	p["common"] = max(0.0, 1.0 - sum_other)

	# If total != 1.0 due to clamp, renormalize all to sum==1.0
	var total = p["common"] + p["rare"] + p["epic"] + p["legendary"]
	if total <= 0.0:
		# Safety: fallback to pure common if everything is zero
		return {"common": 1.0, "rare": 0.0, "epic": 0.0, "legendary": 0.0}

	for k in p.keys():
		p[k] = p[k] / total
	return p


func _roll_rarity(prob: Dictionary) -> String:
	# Returns "common" | "rare" | "epic" | "legendary"
	var r := randf()
	var acc := 0.0
	for k in ["epic", "rare", "legendary", "common"]:
		# Order does not matter as long as it matches the accumulated sum.
		# Here we just iterate and accumulate.
		acc += prob[k]
		if r < acc:
			return k
	# Fallback
	return "common"


func _build_filtered_pools(exclude_ids: Array[StringName]) -> Dictionary:
	# Build working pools (copies) filtered by exclude_ids (no side effects)
	return {
		"common": relics_common.filter(func(r): return r.relic_id not in exclude_ids),
		"rare": relics_rare.filter(func(r): return r.relic_id not in exclude_ids),
		"epic": relics_epic.filter(func(r): return r.relic_id not in exclude_ids),
		"legendary": relics_legendary.filter(func(r): return r.relic_id not in exclude_ids),
	}


func _pick_from_pool_without_replacement(pools: Dictionary, rarity: String) -> BaseRelic:
	# Try target rarity first, then fallback to nearest non-empty pool
	# Fallback order: same rarity -> higher -> lower -> any available
	if pools[rarity].size() > 0:
		var idx := randi_range(0, pools[rarity].size() - 1)
		var relic: BaseRelic = pools[rarity][idx]
		pools[rarity].remove_at(idx) # no replacement
		return relic

	# Fallback strategy: look for the next non-empty pool by descending value
	for alt in RARITY_KEYS:
		if pools[alt].size() > 0:
			var idx2 := randi_range(0, pools[alt].size() - 1)
			var relic2: BaseRelic = pools[alt][idx2]
			pools[alt].remove_at(idx2)
			return relic2

	# Nothing available
	return null
