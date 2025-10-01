extends Node

func vanish_particules(particules: CPUParticles2D):
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Stop spawning new particles, then fade out what's on screen
	tween.tween_callback(func (): particules.emitting = false)
	# Fade the whole node so existing particles also fade
	tween.tween_property(particules, "modulate:a", 0.0, 0.3)
