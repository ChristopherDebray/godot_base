extends Resource
class_name AbilityData

enum ABILITY_KIND { PROJECTILE, AOE, MELEE, HEAL, BUFF, DEBUFF }

@export var name: String
@export var cooldown: float = 0.5
## Maginitude of the effect
@export var magnitude: float = 1.0
@export var range: float = 160.0
@export var faction: String = "player"
@export var kind: ABILITY_KIND = ABILITY_KIND.PROJECTILE
@export var scene: PackedScene

@export var damage: float = 0.0
@export var aoe_damage: float = 0.0
@export var main_element: SpellsManager.ELEMENTS
## Optional, dot, slow, etc
@export var effect: EffectData
