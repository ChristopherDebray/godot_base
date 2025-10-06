extends Node
class_name WeatherPicker

@export var rebuild_interval_sec: float = 2.0

var table: WeightedTable
var rng: RandomNumberGenerator

var loadout: WeatherLoadout
var rules: Array[WeightRule] = []  # [WeatherBiomeRule, WeatherTimeOfDayRule, WeatherPersistenceRule...]

# State/context
var biome: EnvironmentManager.BIOME = EnvironmentManager.BIOME.PLAINS
var hour: int = 12
var current_weather_id: EnvironmentManager.WEATHER_TYPE = EnvironmentManager.WEATHER_TYPE.CLEAR
var time_in_state: float = 0.0

var _last_rebuild_time: float = -1.0
var _dirty: bool = true

func setup(loadout_in: WeatherLoadout, rules_in: Array) -> void:
	loadout = loadout_in
	rules = rules_in.duplicate()
	table = WeightedTable.new()
	rng = RandomNumberGenerator.new()
	rng.randomize()
	_dirty = true

func set_context(new_biome: EnvironmentManager.BIOME, new_hour: int, current_id: EnvironmentManager.WEATHER_TYPE, seconds_in_state: float) -> void:
	biome = new_biome
	hour = new_hour
	current_weather_id = current_id
	time_in_state = seconds_in_state
	_dirty = true

func _process(delta: float) -> void:
	# If you want the picker to manage its own throttling:
	rebuild_if_needed()

func rebuild_if_needed() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if not _dirty and _last_rebuild_time >= 0.0 and now - _last_rebuild_time < rebuild_interval_sec:
		return
	_rebuild_table()
	_last_rebuild_time = now
	_dirty = false

func pick() -> WeatherEntry:
	rebuild_if_needed()
	return table.pick(rng) as WeatherEntry

func _rebuild_table() -> void:
	table.clear()
	if loadout == null or loadout.entries.is_empty():
		return

	var ctx := {
		"biome": biome,
		"hour": hour,
		"current_weather_id": current_weather_id,
		"time_in_state": time_in_state
	}

	table.set_from(
		loadout.entries,
		func(entry: WeatherEntry) -> float:
			# Start with base weight
			var weight = max(0.0, entry.base_weight)

			# Additive rules (small nudges)
			#if entry.weight_rule != null:
				#var rule_weight = entry.weight_rule.weight_for(entry, ctx)
				#if rule_weight > 0.0:
					#weight += rule_weight
			
			# Multiplicative rules (gates / persistence / biome factors)
			var mult := 1.0
			for rule in rules:
				var add = rule.weight_for(entry, ctx)
				if add > 0.0:
					weight += add
				if "factor_for" in rule:
					mult *= rule.factor_for(entry, ctx)

			# Clamp and return
			weight *= mult
			if weight < 0.0:
				weight = 0.0
			return weight
	)
	table.rebuild()
