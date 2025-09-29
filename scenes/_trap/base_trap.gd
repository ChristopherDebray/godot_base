extends Node2D

@onready var area_2d: Area2D = $Area2D

@export var trigger: Area2D
@export var ability: BaseAbility

func apply_damage_and_effect(target: Damageable, damageValue):
	target.apply_elemental_damage(ability_resource, damageValue)
	if !effect:
		return
	target.apply_effect(effect)

## When player walks on trap or a trigger (pressure plate, etc)
func on_trigger():
	activate_trap()

func activate_trap():
	pass
