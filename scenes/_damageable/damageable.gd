extends Node2D

class_name Damageable

const SpellEnums = preload("res://data/spells/enums.gd")

@export var health: float = 10.0
@export var defense: float = 10.0
@export var immunity_effects: Array[SpellEnums.EFFECTS] = []
@export var immunity_elements: Array[SpellEnums.ELEMENTS] = []
@export var resistence_elements: Array[SpellEnums.ELEMENTS] = []

func apply_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		on_death()

func apply_effect(effect: int) -> void:
	if effect in immunity_effects:
		print("Immune to effect", effect)
		return

	print("Affected by effect:", effect)

# Can be supercharged
func on_death():
	queue_free()
