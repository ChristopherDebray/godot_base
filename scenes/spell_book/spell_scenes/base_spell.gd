extends Node2D

class_name BaseSpell

const Enums = preload("res://data/spells/enums.gd")

@export var spellName: String
var damage: float
var aoe_damage: float
var effect: Enums.EFFECTS
var effect_duration: float = 2.0
var duration: float = 2.0
var range: float = 30.0
@export var aoe_enabled: bool = true

var sender: Node
var _has_hit: bool = false
var spellResource: SpellData

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var hitbox: Area2D = $Hitbox
@onready var area_of_effect: Area2D = $AreaOfEffect

func _ready():
	lifetime_timer.start(duration)

func initSpellResource(spell_data: SpellData) -> void:
	spellResource = spell_data
	damage = spell_data.damage
	aoe_damage = spell_data.aoe_damage
	effect = spell_data.effect
	effect_duration = spell_data.effect_duration
	range = spell_data.range

func _on_hitbox_body_entered(body):
	if body != sender:
		on_spell_hit(body)

func on_spell_hit(body):
	# @todo fix to allow spell to be aoe only or have both
	for receiver in hitbox.get_overlapping_bodies():
		apply_damage_and_effect(receiver, damage)

	_has_hit = true
	on_hit()

func _on_area_of_effect_body_entered(body: Node2D) -> void:
	on_aoe_hit()

func on_aoe_hit():
	print('je tfdssf')
	for receiver in area_of_effect.get_overlapping_bodies():
		print('je ')
		print(receiver)
		apply_damage_and_effect(receiver, aoe_damage)

func activate_aoe():
	area_of_effect.monitoring = true

func is_aoe_activated() -> bool:
	return area_of_effect.monitoring

func apply_damage_and_effect(target, damageValue):
	var damageable = target
	if damageable:
		damageable.apply_damage(damageValue)
		damageable.apply_effect(effect)

# Call the supercharged in the children
func on_hit():
	pass

func _on_lifetime_timer_timeout():
	# Call the supercharged in the children
	on_spell_timeout()

# "Abstract" method, by default just delete the element but could be used for effect on duration over
func on_spell_timeout():
	queue_free()
