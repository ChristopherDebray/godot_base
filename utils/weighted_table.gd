## Reusable weighted-selection table (roulette-wheel / cumulative method).
class_name WeightedTable
extends Node
# Build once (or whenever weights change), then pick quickly.

## - items: Array of arbitrary objects (AbilityEntry, loot, etc.)
var items: Array = []
## - weights: PackedFloat32Array of non-negative weights
var weights: PackedFloat32Array = PackedFloat32Array()
## - cumulative_weights: cumulative sums used to sample
var cumulative_weights: PackedFloat32Array = PackedFloat32Array()
## - total_weight: sum of all weights (<= 0 => no valid pick)
var total_weight: float = 0.0
var is_dirty: bool = true

func clear() -> void:
	# Reset the table to an empty state.
	items.clear()
	weights = PackedFloat32Array()
	cumulative_weights = PackedFloat32Array()
	total_weight = 0.0
	is_dirty = true

func add(item: Variant, weight: float) -> void:
	# Append a single (item, weight) entry.
	# Call rebuild() before calling any pick method.
	var clamped_weight: float = max(0.0, float(weight))
	items.append(item)

	var new_weights := PackedFloat32Array()
	new_weights.resize(weights.size() + 1)
	for i in weights.size():
		new_weights[i] = weights[i]
	new_weights[new_weights.size() - 1] = clamped_weight

	weights = new_weights
	is_dirty = true

func set_from(source_items: Array, weight_fn: Callable) -> void:
	# Bulk fill from an item array + a weight function.
	# Call rebuild() before calling any pick method.
	items = source_items.duplicate()
	weights = PackedFloat32Array()
	weights.resize(items.size())

	for i in items.size():
		var w: float = float(weight_fn.call(items[i]))
		if w < 0.0:
			w = 0.0
		weights[i] = w

	is_dirty = true

func rebuild() -> void:
	# Recompute cumulative sums and total weight.
	cumulative_weights = PackedFloat32Array()
	cumulative_weights.resize(weights.size())

	total_weight = 0.0
	for i in weights.size():
		total_weight += weights[i]
		cumulative_weights[i] = total_weight

	is_dirty = false

func update_weight(index: int, weight: float) -> void:
	# Update a single weight; marks the table as dirty (needs rebuild).
	if index < 0 or index >= weights.size():
		return
	weights[index] = max(0.0, float(weight))
	is_dirty = true

func ensure_ready() -> void:
	# Build if needed prior to sampling.
	if is_dirty:
		rebuild()

func is_empty() -> bool:
	# Returns true if there are no items.
	return items.is_empty()

func pick_index(rng: RandomNumberGenerator = null) -> int:
	# Return an index in [0..n-1] or -1 if picking is not possible.
	ensure_ready()
	if cumulative_weights.is_empty():
		return -1
	if total_weight <= 0.0:
		return -1

	var r: float = _randf(rng) * total_weight
	return _lower_bound(cumulative_weights, r)

func pick(rng: RandomNumberGenerator = null) -> Variant:
	# Return the picked item or null if picking is not possible.
	var idx: int = pick_index(rng)
	if idx < 0:
		return null
	return items[idx]

func pick_k_unique(k: int, rng: RandomNumberGenerator = null) -> Array:
	# Draw k unique items without replacement.
	# Rebuilds a local cumulative at each removal (simple & robust).
	var clamped_k: int = clamp(k, 0, items.size())
	var result: Array = []
	if clamped_k == 0:
		return result

	# Local copies of items and weights to remove from.
	var local_items: Array = items.duplicate()
	var local_weights: PackedFloat32Array = _copy_packed_f32(weights)

	for _round in clamped_k:
		# Build local cumulative
		var local_cumulative := PackedFloat32Array()
		local_cumulative.resize(local_weights.size())
		var local_total: float = 0.0

		for j in local_weights.size():
			var w: float = max(0.0, local_weights[j])
			local_total += w
			local_cumulative[j] = local_total

		if local_total <= 0.0:
			break

		var r: float = _randf(rng) * local_total
		var pick_j: int = _lower_bound(local_cumulative, r)

		result.append(local_items[pick_j])
		local_items.remove_at(pick_j)
		local_weights.remove_at(pick_j)

	return result

static func _randf(rng: RandomNumberGenerator) -> float:
	# RNG indirection so you can pass a per-NPC RNG for determinism.
	if rng != null:
		return rng.randf()
	return randf()

static func _lower_bound(cumulative: PackedFloat32Array, x: float) -> int:
	# First index i such that cumulative[i] >= x (binary search).
	var lo := 0
	var hi := cumulative.size() - 1
	while lo < hi:
		var mid := (lo + hi) >> 1
		if cumulative[mid] >= x:
			hi = mid
		else:
			lo = mid + 1
	return lo

static func _copy_packed_f32(src: PackedFloat32Array) -> PackedFloat32Array:
	# Utility: ensure we have an explicit copy of a PackedFloat32Array.
	var out := PackedFloat32Array()
	out.resize(src.size())
	for i in src.size():
		out[i] = src[i]
	return out
