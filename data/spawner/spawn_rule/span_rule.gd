class_name SpawnRule
extends WeightRule

# Multiplicative factor: return 0..∞ (1.0 = neutral).
func factor_for(entry: SpawnEntryData, context: Dictionary) -> float:
	return 1.0
