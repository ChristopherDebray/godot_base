class_name WeatherBiomeRule
extends WeightRule

const B := EnvironmentManager.BIOME
const W := EnvironmentManager.WEATHER_TYPE

# Map of biome -> per-weather factor (multiplicative is clearer for "gates")
@export var biome_factors := {
	B.PLAINS: { W.RAIN: 1.0, W.WIND: 1.2, W.FOG: 0.8, W.CLEAR: 1.0 },
	B.DESERT: { W.RAIN: 0.0, W.DUST: 1.5, W.WIND: 1.3, W.CLEAR: 1.2 },
	B.FOREST: { W.RAIN: 1.3, W.FOG: 1.4, W.CLEAR: 0.8 }
}

func factor_for(item: WeatherEntry, context: Dictionary) -> float:
	if not context.has("biome"):
		return 0.0
	if not item.compatible_biomes.has(context["biome"] as EnvironmentManager.BIOME):
		return 0.0
	var biome: EnvironmentManager.BIOME = context["biome"]
	if not biome_factors.has(biome):
		return 0.0
	var per_weather: Dictionary = biome_factors[biome]
	if per_weather.has(item.id):
		return float(per_weather[item.id])
	return 1.0
