extends Node2D

@onready var area_2d: Area2D = $Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var data: TrapData

func apply_damage_and_effect(target: Damageable):
	target.apply_elemental_damage(data, data.damage)
	if data.effect:
		target.apply_effect(data.effect)

## When player walks on trap or a trigger (pressure plate, etc)
func on_trigger():
	activate_trap()

func activate_trap():
	for body in area_2d.get_overlapping_bodies():
		apply_damage_and_effect(body)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "default":
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	animated_sprite_2d.play('default')
	activate_trap()
