extends Resource
## This loadout correspond to the spawnable enemies by a spawner
class_name SpawnLoadoutData

## The enemies / entries to spawn
@export var entries: Array[SpawnEntryData] = []
