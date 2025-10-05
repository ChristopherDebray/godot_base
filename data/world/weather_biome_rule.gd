class_name WeatherBiomeRule
extends WeightRule

# Map of biome -> per-weather factor (multiplicative is clearer for "gates")
@export var biome_factors: Dictionary = {
	"plains": {"rain": 1.0, "wind": 1.2, "fog": 0.8, "clear": 1.0},
	"desert": {"rain": 0.0, "dust": 1.5, "wind": 1.3, "clear": 1.2},
	"forest": {"rain": 1.3, "fog": 1.4, "clear": 0.8}
}

# Convention: we return an **additive** bonus. To apply multiplicative
# factors, convert factor -> additive bonus with a simple mapping,
# or let the picker do multiplicative. Here, we return "no opinion"
# and let the picker multiply (cleaner).
func weight_for(item: Variant, context: Dictionary) -> float:
	return -1.0  # no additive here; we’ll use multiplicative in the picker

func factor_for(item: WeatherEntry, context: Dictionary) -> float:
	if not context.has("biome"):
		return 0.0
	if not item.compatible_biomes.has(context["biome"] as EnvironmentManager.BIOME):
		return 0.0
	var biome: String = context["biome"]
	if not biome_factors.has(biome):
		return 0.0
	var per_weather: Dictionary = biome_factors[biome]
	if per_weather.has(item.id):
		return float(per_weather[item.id])
	return 1.0
