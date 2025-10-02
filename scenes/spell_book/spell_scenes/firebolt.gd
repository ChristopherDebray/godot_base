extends ProjectileAbility

const FIREBALL_WHOOSH = preload("res://assets/sounds/effects/fireball_whoosh.mp3")

func _ready():
	setup_on_ready()
	animated_sprite_2d.play('repeat')
	loop_particles.emitting = true
	SoundManager.play_tag_at("arrow", FIREBALL_WHOOSH, global_position, -4.0)

func on_hit():
	animated_sprite_2d.play('hit')
	AnimationManager.vanish_particules(loop_particles)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "hit":
		queue_free()
