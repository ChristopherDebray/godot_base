extends Resource
class_name SpellData

const SpellEnums = preload("res://data/spells/enums.gd")

@export var name: String
@export var damage: float
@export var cooldown: float
@export var effect: SpellEnums.EFFECTS
@export var magnitude: float
@export var range: float
@export var scene: PackedScene
