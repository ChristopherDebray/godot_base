extends ProjectileAbility

func _ready() -> void:
	setup_on_ready()

func on_hit() -> void:
	animated_sprite_2d.play('hit')

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "hit":
		queue_free()
