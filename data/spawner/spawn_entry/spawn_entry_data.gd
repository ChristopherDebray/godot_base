extends Resource
class_name SpawnEntryData

@export var scene: PackedScene
## Cost used by the spawner for budget calculation
@export var cost: int = 1
## Weight of draw for this entry (to define rarity of spawn)
@export var weight: float = 1.0
@export var base_weight: float = 5.0

# Optional metadata for filtering/rules
@export var tags: Array[String] = []                 # e.g. ["humanoid","ranged"]
@export var compatible_biomes: Array[EnvironmentManager.BIOME] = []       # indices of your BIOME enum
@export var min_wave: int = 1
@export var max_wave: int = 9999

# Optional per-entry rule (composition-friendly)
@export var weight_rule: SpawnRule = null  # SpawnRule
