extends ProjectileAbility

func _ready():
	setup_on_ready()
	set_physics_process(false)
	animated_sprite_2d.play('start')
	loop_particles.emitting = true

func on_hit():
	animated_sprite_2d.play('hit')

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "start":
		AnimationManager.vanish_particules(loop_particles)
		animated_sprite_2d.play('repeat')
		set_physics_process(true)
	if animated_sprite_2d.animation == "hit":
		queue_free()
