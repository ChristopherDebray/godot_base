extends Damager
class_name AbilityData

enum ABILITY_KIND { PROJECTILE, AOE, MELEE, HEAL, BUFF, DEBUFF, SELF, MOVEMENT }
enum ABILITY_FACTION { PLAYER, ENEMY, ALL }
enum ABILITY_TAG {
	AOE,
	PROJECTILE,
	BUFF,
	DEBUFF,
	INSTANT,
	FINISHER,
	PIERCE,
	BASE_ABILITY,
	CONTROL
}
const ABILITY_TAG_LABELS: Dictionary = {
	ABILITY_TAG.AOE: "AOE",
	ABILITY_TAG.PROJECTILE: "Projectile",
	ABILITY_TAG.BUFF: "Buff",
	ABILITY_TAG.DEBUFF: "Debuff",
	ABILITY_TAG.INSTANT: "Instant",
	ABILITY_TAG.FINISHER: "Finisher",
	ABILITY_TAG.PIERCE: "Pierce",
	ABILITY_TAG.BASE_ABILITY: "Base",
	ABILITY_TAG.CONTROL: "Control",
}

@export var name: String
@export var cooldown: float = 0.5
## Maginitude of the effect
@export var range: float = 160.0
@export var kind: ABILITY_KIND = ABILITY_KIND.PROJECTILE
@export var scene: PackedScene

## Optional, dot, slow, etc
@export var self_effect: EffectData
@export var description: String
@export var tags: Array[ABILITY_TAG] = []
@export var icon: Texture2D

# Canalisation (optionnal)
@export var is_channeled: bool = false
@export var channel_tick_rate: float = 0.5 # tick effect during channel
@export var max_channel_duration: float = 3.0

@export var base_size: float = 1.0
@export var base_projectile_count: int = 1
@export var base_piercing: int = 0
@export var base_chain_count: int = 0
@export var base_damage: float = 10.0
@export var base_speed: float = 400.0

var cast_time: float= 0

func is_base_ability() -> bool:
	return tags.has(ABILITY_TAG.BASE_ABILITY)
