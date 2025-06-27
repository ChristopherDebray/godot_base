extends Resource
class_name SpellData

@export var name: String
@export var damage: float
@export var aoe_damage: float
@export var cooldown: float
@export var effect: EffectData
@export var magnitude: float = 1
@export var range: float
@export var main_element: SpellsManager.ELEMENTS
@export var scene: PackedScene
