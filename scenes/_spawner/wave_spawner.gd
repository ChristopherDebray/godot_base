extends Node2D
class_name WaveSpawner

@onready var timer: Timer = $Timer

@export var spawn_loadout: SpawnLoadoutData
@export var spawn_points: Array[NodePath] = []     # set in editor
@export var player: Player
@export var min_distance_from_player: float = 64.0 # avoid popping on the player
@export var max_spawns_per_wave: int = 50
@export var rng_seed: int = 12345   
@export var spawn_interval: float = 1.2               # set from a run-state if you want reproducibility

@export var rules: Array[SpawnRule] = []
@export var telegraph_scene: PackedScene
@export var pre_spawn_delay: float = 0.6

# Context (set from your WaveManager/Level)
var biome: EnvironmentManager.BIOME = EnvironmentManager.BIOME.PLAINS
var current_wave: int = 1
var current_weather_id: StringName = &""

# Cached, sorted-by-cost data (built once or when table changes)
var _points: Array[Node2D] = []
var _costs: PackedInt32Array
var _weights: PackedFloat32Array
var _cum_weights: PackedFloat32Array
var _scenes: Array[PackedScene]
var _ids: PackedStringArray

var _rng := RandomNumberGenerator.new()
var _last_spawn_id: StringName = &""
var _spawning: bool = false

var budget: int
var spawns := 0
var safety := 1000

func _ready() -> void:
	_rng.seed = rng_seed
	_resolve_points()
	_build_sorted_cache()
	timer.wait_time = spawn_interval
	budget = max(0, WaveManager.budget_base)

func set_spawn_loadout(table: SpawnLoadoutData) -> void:
	# Call this if you swap themes at runtime.
	spawn_loadout = table
	_build_sorted_cache()

func set_rng_seed(seed_value: int) -> void:
	rng_seed = seed_value
	_rng.seed = rng_seed

## Optional helper to inject points from code.
func set_spawn_points(points: Array[Node2D]) -> void:
	_points = points.duplicate()

func set_context(biome_index: int, wave_index: int, weather_id: StringName) -> void:
	biome = biome_index
	current_wave = wave_index
	current_weather_id = weather_id
	_build_sorted_cache_from_context()

func _spawn_with_telegraph(index: int, pt: Node2D) -> void:
	if telegraph_scene == null:
		# Direct spawn if no telegraph provided
		_do_spawn(index, pt)
		return

	var tele := telegraph_scene.instantiate()
	if tele and tele is Node2D:
		add_child(tele)
		tele.global_position = pt.global_position

	# Delay, then spawn (defensive: check still active)
	await get_tree().create_timer(max(0.0, pre_spawn_delay)).timeout
	if not _spawning:
		if tele and is_instance_valid(tele):
			tele.queue_free()
		return

	_do_spawn(index, pt)

	if tele and is_instance_valid(tele):
		tele.queue_free()

func _do_spawn(index: int, pt: Node2D) -> void:
	var enemy := _scenes[index].instantiate() as BaseNpc
	enemy.initial_state = BaseNpc.STATE.ATTACKING
	enemy.global_position = pt.global_position
	get_tree().current_scene.add_child(enemy)

	_last_spawn_id = StringName(_ids[index])
	budget -= _costs[index]
	spawns += 1

# ---------- build cache (weights from context) ----------

func _build_sorted_cache_from_context() -> void:
	_costs = PackedInt32Array()
	_weights = PackedFloat32Array()
	_cum_weights = PackedFloat32Array()
	_scenes = []
	_ids = PackedStringArray()

	if spawn_loadout == null or spawn_loadout.entries.is_empty():
		return

	# Gather and context-filter first (biomes / waves)
	var candidates: Array[SpawnEntryData] = []
	for e in spawn_loadout.entries:
		if e.scene == null:
			continue
		if e.max_wave > 0 and (current_wave < e.min_wave or current_wave > e.max_wave):
			continue
		if not e.compatible_biomes.is_empty() and not e.compatible_biomes.has(biome):
			continue
		candidates.append(e)

	if candidates.is_empty():
		return

	# Compute final weight per candidate
	var ctx := {
		"biome": biome,
		"wave": current_wave,
		"weather_id": current_weather_id
	}

	## each item: { "idx": int, "cost": int, "weight": float, "scene": PackedScene, "id": String }
	var weighted: Array = []

	for i in candidates.size():
		var e: SpawnEntryData = candidates[i]
		var w = max(0.0, e.base_weight)

		# Per-entry rule (additive + multiplicative)
		if e.weight_rule != null:
			if "weight_for" in e.weight_rule:
				var add = e.weight_rule.weight_for(e, ctx)
				if add >= 0.0:
					w += add
			if "factor_for" in e.weight_rule:
				w *= e.weight_rule.factor_for(e, ctx)

		# Global rules
		for r in rules:
			if "weight_for" in r:
				var a := r.weight_for(e, ctx)
				if a >= 0.0:
					w += a
			if "factor_for" in r:
				w *= r.factor_for(e, ctx)

		weighted.append({
			"idx": i,
			"cost": max(1, e.cost),
			"weight": max(0.0, w),
			"scene": e.scene,
			"id": String(e.id)
		})

	# Sort by cost asc (stable)
	weighted.sort_custom(func(a, b):
		if a["cost"] == b["cost"]:
			return a["id"] < b["id"]
		return a["cost"] < b["cost"]
	)

	# Fill cached arrays
	var running := 0.0
	for item in weighted:
		_costs.push_back(int(item["cost"]))
		var w := float(item["weight"])
		_weights.push_back(w)
		running += w
		_cum_weights.push_back(running)
		_scenes.append(item["scene"])
		_ids.push_back(item["id"])

func spawn_wave() -> void:
	_spawning = true
	timer.start()

func spawn():
	# Spend the provided budget by spawning enemies until exhausted or capped.
	if budget < 0 or spawns > max_spawns_per_wave or safety < 0:
		timer.stop()
		_spawning = false
		return

	safety -= 1
	var k := _upper_bound_cost(budget) # number of affordable entries
	if k <= 0:
		return

	var total_w := _cum_weights[k - 1]
	if total_w <= 0.0:
		return

	var i := _pick_affordable_index(k)

	# Soft anti-repeat: if same id and there is an alternative, repick once
	if _ids[i] == _last_spawn_id and k > 1:
		var j := _pick_affordable_index(k)
		if _ids[j] != _last_spawn_id:
			i = j

	var pt := _pick_spawn_point(player)
	if pt == null:
		# No valid point found at safe distance; you can relax constraints or stop
		return

	_spawn_with_telegraph(i, pt)

# ---------- internals ----------

func _resolve_points() -> void:
	_points.clear()
	for p in spawn_points:
		var n := get_node_or_null(p)
		if n and n is Node2D:
			_points.append(n)

func _build_sorted_cache() -> void:
	_costs = PackedInt32Array()
	_weights = PackedFloat32Array()
	_cum_weights = PackedFloat32Array()
	_scenes = []
	_ids = PackedStringArray()

	if spawn_loadout == null or spawn_loadout.entries.is_empty():
		return

	# build index list then sort by cost asc (stable by original index)
	var idxs: Array[int] = []
	idxs.resize(spawn_loadout.entries.size())
	for i in idxs.size():
		idxs[i] = i
	idxs.sort_custom(_by_cost)

	var running: float = 0.0
	for j in idxs:
		var e: SpawnEntryData = spawn_loadout.entries[j]
		var c = max(1, e.cost)
		var w = max(0.0, e.weight)
		var id = StringName(e.scene.resource_path.get_file())

		_costs.push_back(c)
		_weights.push_back(w)
		running += w
		_cum_weights.push_back(running)
		_scenes.append(e.scene)
		_ids.push_back(String(id))

func _by_cost(a: int, b: int) -> bool:
	var ea: SpawnEntryData = spawn_loadout.entries[a]
	var eb: SpawnEntryData = spawn_loadout.entries[b]
	if ea.cost == eb.cost:
		return a < b
	return ea.cost < eb.cost

func _upper_bound_cost(budget: int) -> int:
	# returns count of entries with cost <= budget (first index > budget)
	var lo := 0
	var hi := _costs.size()
	while lo < hi:
		var mid := (lo + hi) >> 1
		if _costs[mid] <= budget:
			lo = mid + 1
		else:
			hi = mid
	return lo

func _pick_affordable_index(k: int) -> int:
	# pick in [0, k) using _cum_weights
	var r := _rng.randf() * _cum_weights[k - 1]
	return _lower_bound_cum(r, k)

func _lower_bound_cum(value: float, k: int) -> int:
	# first index in [0, k) whose cum >= value
	var lo := 0
	var hi := k
	while lo < hi:
		var mid := (lo + hi) >> 1
		if _cum_weights[mid] < value:
			lo = mid + 1
		else:
			hi = mid
	if lo < 0:
		return 0
	if lo >= k:
		return k - 1
	return lo

## Picks a random spawn point outside of min distance with the player if possible
func _pick_spawn_point(player: Node2D) -> Node2D:
	if _points.is_empty():
		return null
	
	# Try several times to respect min distance
	for _i in range(3):
		var idx := _rng.randi_range(0, _points.size() - 1)
		var pt := _points[idx]
		if player == null:
			return pt
		var d := pt.global_position.distance_to(player.global_position)
		if d >= min_distance_from_player:
			return pt
	# As a fallback return any point
	return _points[_rng.randi_range(0, _points.size() - 1)]

func _on_timer_timeout() -> void:
	spawn()
