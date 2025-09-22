extends AoeInstantAbility

var _dir_of_travel: Vector2 = Vector2.ZERO

const SPEED: float = 400.0

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "repeat":
		queue_free()

func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite_2d.frame >= 3 && !is_aoe_activated():
		activate_aoe()

func on_impact_start() -> void:
	if telegraph:
		telegraph.queue_free()
		telegraph = null
	animated_sprite_2d.play('repeat')
