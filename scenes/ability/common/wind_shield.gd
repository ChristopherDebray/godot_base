extends AoeInstantAbility

const WIND_GUST = preload("res://assets/sounds/effects/wind_gust.ogg")

func _ready() -> void:
	animated_sprite_2d.play('default')
	SoundManager.play_tag_at("spell_cast", WIND_GUST, global_position, 20.0)
	loop_particles.emitting = true
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 1) Grow the particles emitter (sequential)
	tween.tween_property(loop_particles, "scale_amount_min", 1, .12)
	tween.tween_property(loop_particles, "scale_amount_max", 1.2, .12)

	# 2) Stop spawning new particles, then fade out what's on screen
	tween.tween_callback(func (): loop_particles.emitting = false)

	# Fade the whole node so existing particles also fade
	tween.tween_property(loop_particles, "modulate:a", 0.0, 0.12)

func init(ability_data: AbilityData, ctx: AimContext) -> void:
	start_from(ctx.sender_pos, range)
