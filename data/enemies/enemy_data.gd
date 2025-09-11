class_name EnemyData
extends Resource

@export var name: String
@export var health: float = 10
@export var defense: float = 0
@export var base_speed: float = 90
@export var immunities_effects: Array[EffectsManager.EFFECTS] = []
@export var immunities_elements: Array[SpellsManager.ELEMENTS] = []
@export var resistances: Array[SpellsManager.ELEMENTS] = []
@export var attack_cooldown: float = 1.8
@export var behavior: NpcBehavior
