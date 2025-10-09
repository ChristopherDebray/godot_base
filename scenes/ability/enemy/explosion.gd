extends AoeInstantAbility

const EXPLOSION = preload("res://assets/sounds/effects/explosion.ogg")

func _ready():
	super._ready()
	animated_sprite_2d.play('default')
	SoundManager.play_tag_at("spell_cast", EXPLOSION, global_position, -4.0)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "default":
		queue_free()

func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite_2d.frame >= 3 && !is_aoe_activated():
		if sender:
			sender.queue_free()
		impact_particles.emitting = true
		GameManager.shake_camera(5)
		activate_aoe()
