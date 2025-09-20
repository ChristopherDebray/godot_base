extends Resource
class_name AbilityData

enum ABILITY_KIND { PROJECTILE, AOE, MELEE, HEAL, BUFF, DEBUFF, SELF }
enum ABILITY_FACTION { PLAYER, ENEMY, ALL }
enum ABILITY_TAG { AOE, PROJECTILE, BUFF, DEBUFF, INSTANT, FINISHER }

@export var name: String
@export var cooldown: float = 0.5
## Maginitude of the effect
@export var magnitude: float = 1.0
@export var range: float = 160.0
@export var faction: ABILITY_FACTION = ABILITY_FACTION.PLAYER
@export var kind: ABILITY_KIND = ABILITY_KIND.PROJECTILE
@export var scene: PackedScene

@export var damage: float = 0.0
@export var aoe_damage: float = 0.0
@export var main_element: SpellsManager.ELEMENTS
## Optional, dot, slow, etc
@export var effect: EffectData
@export var description: String
@export var tags: Array[ABILITY_TAG] = []

# Canalisation (optionnal)
@export var is_channeled: bool = false
@export var channel_tick_rate: float = 0.5 # tick effect during channel
@export var max_channel_duration: float = 3.0
