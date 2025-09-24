extends Resource
class_name SpawnEntryData

@export var scene: PackedScene
## Cost used by the spawner for budget calculation
@export var cost: int = 1
## Weight of draw for this entry (to define rarity of spawn)
@export var weight: float = 1.0


func _validate_property(property: Dictionary) -> void:
	if property.name == "cost" and cost < 1:
		cost = 1
	if property.name == "weight" and weight < 0.0:
		weight = 0.0
