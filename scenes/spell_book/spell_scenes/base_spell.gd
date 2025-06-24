extends Node2D

class_name BaseSpell

const Enums = preload("res://data/spells/enums.gd")

@export var damage: float
@export var effect: Enums.EFFECTS
@export var effect_duration: float = 2.0
@export var duration: float = 2.0
@export var aoe_enabled: bool = true

var sender: Node
var _has_hit: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var hitbox: Area2D = $Hitbox
@onready var area_of_effect: Area2D = $AreaOfEffect

func _ready():
	lifetime_timer.start(duration)

func _on_hitbox_body_entered(body):
	if body != sender:
		on_spell_hit(body)

func on_spell_hit(body):
	# @todo fix to allow spell to be aoe only or have both
	if aoe_enabled:
		for receiver in area_of_effect.get_overlapping_bodies():
			apply_damage_and_effect(receiver)
	else:
		for receiver in area_of_effect.get_overlapping_bodies():
			apply_damage_and_effect(receiver)

	_has_hit = true
	on_hit()

func _on_area_of_effect_body_entered(body: Node2D) -> void:
	on_aoe_hit()

func on_aoe_hit():
	for receiver in area_of_effect.get_overlapping_bodies():
		apply_damage_and_effect(receiver)

func activate_aoe():
	area_of_effect.monitoring = true

func apply_damage_and_effect(target):
	var hurtable = target.get_node_or_null("Hurtable")
	if hurtable:
		hurtable.apply_damage(damage)
		hurtable.apply_effect(effect)

# Call the supercharged in the children
func on_hit():
	pass

func _on_lifetime_timer_timeout():
	# Call the supercharged in the children
	on_spell_timeout()

# "Abstract" method, by default just delete the element but could be used for effect on duration over
func on_spell_timeout():
	queue_free()
