extends AoeInstantAbility

func _ready():
	animated_sprite_2d.play('default')

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "default":
		queue_free()

func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite_2d.frame >= 3 && !is_aoe_activated():
		activate_aoe()
