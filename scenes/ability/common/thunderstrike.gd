extends AoeInstantAbility

var _dir_of_travel: Vector2 = Vector2.ZERO

const SPEED: float = 400.0
const LIGHTNING_STRIKE = preload("res://assets/sounds/effects/lightning_strike.ogg")

func _ready() -> void:
	super._ready()

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "repeat":
		queue_free()

func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite_2d.frame >= 3 && !is_aoe_activated():
		impact_particles.emitting = true
		AnimationManager.vanish_particules(impact_particles)
		activate_aoe()
		GameManager.shake_camera(10)

func _start_impact_phase():
	SoundManager.play_tag_at("spell_cast", LIGHTNING_STRIKE, global_position, -4.0)
	super._start_impact_phase()
	animated_sprite_2d.frame = 0
	animated_sprite_2d.play('repeat')

func on_impact_start() -> void:
	if telegraph:
		telegraph.queue_free()
		telegraph = null
	
