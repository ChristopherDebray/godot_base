class_name SpawnBiomeRule
extends SpawnRule

# biome_index -> id -> factor
@export var biome_factors: Dictionary = {
	EnvironmentManager.BIOME.PLAINS: {"skeleton": 1.0, "warrior": 0.0, "kamikaze": 0.75, "farmer": 1},
	EnvironmentManager.BIOME.DESERT: {"skeleton": 0.5, "warrior": 1.5, "kamikaze": 0.75, "farmer": 0}
}

func factor_for(entry: SpawnEntryData, context: Dictionary) -> float:
	if not context.has("biome"):
		return 1.0
	var biome := String(str(int(context["biome"])))
	if not biome_factors.has(biome):
		return 1.0
	var per = biome_factors[biome]
	var key := String(entry.id)
	if per.has(key):
		return float(per[key])
	return 1.0
