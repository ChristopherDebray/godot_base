extends ProjectileAbility

const FIREBALL_WHOOSH = preload("res://assets/sounds/effects/fireball_whoosh.ogg")

func _ready():
	setup_on_ready()
	animated_sprite_2d.play('repeat')
	loop_particles.emitting = true
	SoundManager.play_tag_at("arrow", FIREBALL_WHOOSH, global_position, -4.0)

func on_hit():
	AnimationManager.vanish_particules(loop_particles)
	animated_sprite_2d.play('hit')

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "hit":
		queue_free()
