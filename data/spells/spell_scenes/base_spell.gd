extends Node2D

const Enums = preload("res://data/spells/enums.gd")

@export var damage: float
@export var effect: Enums.EFFECTS
@export var effect_duration: float = 2.0
@export var duration: float = 2.0
@export var aoe_enabled: bool = true

var sender: Node

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var hitbox: Area2D = $Hitbox
@onready var area_of_effect: Area2D = $AreaOfEffect

func _ready():
	lifetime_timer.start(duration)
	hitbox.connect("body_entered", Callable(self, "_on_hitbox_body_entered"))

func _on_hitbox_body_entered(body):
	if body != sender:
		on_spell_hit(body)

func on_spell_hit(body):
	if aoe_enabled:
		area_of_effect.visible = true
		for receiver in area_of_effect.get_overlapping_bodies():
			apply_damage_and_effect(receiver)
	else:
		apply_damage_and_effect(body)

	# Calls an effect or override
	on_hit()

func apply_damage_and_effect(target):
	if target.has_method("apply_damage"):
		target.apply_damage(damage)
	if target.has_method("apply_effect"):
		target.apply_effect(effect)

# Call the supercharged in the children
func on_hit():
	pass

func _on_lifetime_timer_timeout():
	# Call the supercharged in the children
	on_spell_timeout()

# "Abstract" method, by default just delete the element but could be used for effect on duration over
func on_spell_timeout():
	queue_free()
