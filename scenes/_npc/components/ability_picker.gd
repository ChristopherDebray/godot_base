extends Node
## Decides which ability to use:
## - Maintains a WeightedTable of candidate entries
## - Rebuilds the table only when the context changes (dirty flags)
## - Supports optional WeightRules per entry (composition-friendly)
class_name AbilityPicker

## throttle rebuilds to avoid per-frame work
@export var rebuild_interval_sec: float = 0.15
## hysteresis bucket to avoid micro rebuilds
@export var distance_band_size: float = 64.0

var owner_npc: BaseNpc
var targeting: TargetingComponent
var cooldowns: CooldownBank
## Optional: you can leave empty and rely on entry.weight_rule or just static weight
var rules: Array[WeightRule] = []

var table: WeightedTable
var rng: RandomNumberGenerator

## Cached context (for dirty detection)
var _last_target: Damageable = null
var _last_has_los: bool = false
var _last_distance_band: int = -999999
var _last_rebuild_time: float = -1.0

var _is_dirty: bool = true

func setup(npc: BaseNpc, targeting_component: TargetingComponent, cooldown_bank: CooldownBank, rng_in: RandomNumberGenerator = null) -> void:
	owner_npc = npc
	targeting = targeting_component
	cooldowns = cooldown_bank

	table = WeightedTable.new()

	if rng_in != null:
		rng = rng_in
	else:
		rng = RandomNumberGenerator.new()
		rng.seed = int(owner_npc.get_instance_id()) % 2147483647

	# Optional: subscribe to cooldown updates if your CooldownBank emits something like "cooldown_changed"
	if cooldowns != null and cooldowns.has_signal("cooldown_changed"):
		cooldowns.cooldown_changed.connect(_on_cooldown_changed)

	_mark_dirty()

func set_rules(weight_rules: Array) -> void:
	rules = weight_rules.duplicate()
	_mark_dirty()

func _process(delta: float) -> void:
	# If you add this node as a child component and enable processing,
	# it can auto-rebuild on schedule. Otherwise call rebuild_if_needed() from NPC.
	rebuild_if_needed()

func rebuild_if_needed() -> void:
	if not _should_rebuild():
		return
	_rebuild_table()
	_last_rebuild_time = Time.get_ticks_msec() / 1000.0
	_is_dirty = false

func pick_entry() -> AbilityEntry:
	# Ensure table is up-to-date before picking
	rebuild_if_needed()
	return table.pick(rng) as AbilityEntry

# ---------------------- Internal: dirty detection & rebuild ----------------------

func _mark_dirty() -> void:
	_is_dirty = true

func _on_cooldown_changed(_ability: AbilityData) -> void:
	_mark_dirty()

func _should_rebuild() -> bool:
	# 1) throttling
	var now: float = Time.get_ticks_msec() / 1000.0
	if _last_rebuild_time >= 0.0 and now - _last_rebuild_time < rebuild_interval_sec and not _is_dirty:
		return false

	# 2) context changes
	var target := owner_npc._ability_target
	var has_los := false
	if target != null and is_instance_valid(target):
		has_los = owner_npc.targeting._has_line_of_sight(target)

	var dist_band := _compute_distance_band(target)

	var changed := false
	if target != _last_target:
		changed = true
	if has_los != _last_has_los:
		changed = true
	if dist_band != _last_distance_band:
		changed = true
	if _is_dirty:
		changed = true

	_last_target = target
	_last_has_los = has_los
	_last_distance_band = dist_band

	return changed

func _compute_distance_band(target: Damageable) -> int:
	if target == null or not is_instance_valid(target):
		return -1
	var distance := owner_npc.global_position.distance_to(target.global_position)
	if distance_band_size <= 1.0:
		return int(distance)
	return int(floor(distance / distance_band_size))

func _rebuild_table() -> void:
	table.clear()

	# 1) Gather candidates
	var target := owner_npc._ability_target
	if target == null or not is_instance_valid(target):
		return

	var dist := owner_npc.global_position.distance_to(target.global_position)

	var candidates: Array[AbilityEntry] = []
	for entry in owner_npc.ability_loadout.entries:
		if entry.ability == null:
			continue
		if not cooldowns.can_use(entry.ability):
			continue
		if dist < entry.min_range or dist > entry.max_range:
			continue
		if entry.requires_los and not owner_npc.targeting._has_line_of_sight(target):
			continue
		candidates.append(entry)

	if candidates.is_empty():
		return

	# 2) Build context used by rules
	var ctx := {
		"npc": owner_npc,
		"target": target,
		"distance": dist,
		"cooldowns": cooldowns,
		"has_los": _last_has_los
	}

	# 3) Fill table with weights (static + optional rules)
	table.set_from(
		candidates,
		func(entry: AbilityEntry) -> float:
			var weight: float = max(0.0, entry.weight)

			# Entry-level rule (if you added weight_rule on AbilityEntry)
			if "weight_rule" in entry and entry.weight_rule != null:
				var rule_weight = entry.weight_rule.weight_for(entry, ctx)
				if rule_weight >= 0.0:
					weight += rule_weight  # additive by default

			# Global picker rules array (optional composition)
			for rule in rules:
				var rule_weight = rule.weight_for(entry, ctx)
				if rule_weight >= 0.0:
					weight += rule_weight

			# Minimal mid-range nudge if you want a baseline behavior without rules:
			var span = max(1.0, entry.max_range - entry.min_range)
			var mid := (entry.min_range + entry.max_range) * 0.5
			var range_fit = 1.0 - min(1.0, abs(dist - mid) / span)
			weight += range_fit * 0.5

			return max(0.0, weight)
	)
	table.rebuild()
