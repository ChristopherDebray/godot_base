extends Resource
class_name Damager

@export var damage: float = 0.0
@export var aoe_damage: float = 0.0
@export var main_element: SpellsManager.ELEMENTS
@export var magnitude: float = 1.0
@export var effect: EffectData
@export var faction: AbilityData.ABILITY_FACTION = AbilityData.ABILITY_FACTION.PLAYER
