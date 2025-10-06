class_name WeatherEntry
extends Resource

@export var id: EnvironmentManager.WEATHER_TYPE
@export var scene: PackedScene
@export var compatible_biomes: Array[EnvironmentManager.BIOME] = [EnvironmentManager.BIOME.PLAINS, EnvironmentManager.BIOME.FOREST]
@export var compatible_env: Array[EnvironmentManager.ENVIRONMENT_TAG] = [EnvironmentManager.ENVIRONMENT_TAG.OVERWORLD, EnvironmentManager.ENVIRONMENT_TAG.OUTDOOR]
@export var base_weight: float = 5.0
