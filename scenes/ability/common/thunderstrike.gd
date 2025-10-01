extends AoeInstantAbility

var _dir_of_travel: Vector2 = Vector2.ZERO

const SPEED: float = 400.0

func _ready() -> void:
	super._ready()

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "repeat":
		queue_free()

func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite_2d.frame >= 3 && !is_aoe_activated():
		impact_particles.emitting = true
		var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# 2) Stop spawning new particles, then fade out what's on screen
		tween.tween_callback(func (): impact_particles.emitting = false)
		# Fade the whole node so existing particles also fade
		tween.tween_property(impact_particles, "modulate:a", 0.0, 0.3)
		activate_aoe()
		GameManager.shake_camera(10)

func _start_impact_phase():
	super._start_impact_phase()
	animated_sprite_2d.frame = 0
	animated_sprite_2d.play('repeat')

func on_impact_start() -> void:
	if telegraph:
		telegraph.queue_free()
		telegraph = null
	
