extends Node2D

class_name Damageable

const SpellEnums = preload("res://data/spells/enums.gd")

@export var health: float = 10.0
@export var resist_effects: Array[SpellEnums.EFFECTS] = []
@export var resist_elements: Array[SpellEnums.ELEMENTS] = []

func apply_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		on_death()

func apply_effect(effect: int) -> void:
	if effect in resist_effects:
		print("Immune to effect", effect)
		return

	print("Affected by effect:", effect)

# Can be supercharged
func on_death():
	queue_free()

## Realy used ? Since spell will apply the damage. Let's keep it like that for now
func _on_hurtbox_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	pass # Replace with function body.
