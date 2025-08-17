extends Node2D

class_name BaseAbility

@export var abilityName: String
@export var aoe_enabled: bool = true
var damage: float
var aoe_damage: float
var effect: EffectData
var duration: float = 2.0
var range: float = 30.0

var sender: Node
var _has_hit: bool = false
var ability_resource: AbilityData
var _pending_masks: Array

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var hitbox: Area2D = $Hitbox
@onready var area_of_effect: Area2D = $AreaOfEffect


func configure_masks(masks: Array) -> void:
	print(masks)
	_pending_masks = masks

func _ready():
	lifetime_timer.start(duration)
	if _pending_masks:
		set_hitboxes_targets(_pending_masks)

func initAbilityResource(ability_data: AbilityData) -> void:
	ability_resource = ability_data
	damage = ability_data.damage
	aoe_damage = ability_data.aoe_damage
	effect = ability_data.effect
	range = ability_data.range

func _on_hitbox_body_entered(body):
	if body != sender:
		on_ability_hit(body)

func on_ability_hit(body):
	if body is Damageable:
		apply_damage_and_effect(body, damage)
		if is_instance_of(body, BaseEnemy):
			body.search_player()

	_has_hit = true
	on_hit()

func _on_area_of_effect_body_entered(body: Node2D) -> void:
	on_aoe_hit()

func on_aoe_hit():
	print(area_of_effect.get_overlapping_bodies())
	for receiver in area_of_effect.get_overlapping_bodies():
		if receiver is Damageable:
			apply_damage_and_effect(receiver, aoe_damage)

func activate_aoe():
	area_of_effect.monitoring = true

func is_aoe_activated() -> bool:
	return area_of_effect.monitoring

func apply_damage_and_effect(target: Damageable, damageValue):
	target.apply_elemental_damage(ability_resource, damageValue)
	if !effect:
		return
	target.apply_effect(effect)

func set_hitboxes_targets(collision_masks: Array):
	reset_collision_masks(hitbox)
	reset_collision_masks(area_of_effect)
	
	for n in collision_masks:
		hitbox.set_collision_mask_value(n, true)
		area_of_effect.set_collision_mask_value(n, true)

func reset_collision_masks(area2d: Area2D):
	for n in range(1, 32):
		area2d.set_collision_mask_value(n, false)

## @abstract
func on_hit():
	pass

func _on_lifetime_timer_timeout():
	# Call the supercharged in the children
	on_ability_timeout()

## @abstract: by default just delete the element but could be used for effect on duration over
func on_ability_timeout():
	queue_free()
