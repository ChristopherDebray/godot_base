extends ProjectileAbility

func _ready():
	setup_on_ready()
	animated_sprite_2d.play('repeat')
	loop_particles.emitting = true

func on_hit():
	animated_sprite_2d.play('hit')
	AnimationManager.vanish_particules(loop_particles)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "hit":
		queue_free()
