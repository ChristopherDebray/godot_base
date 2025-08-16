extends ProjectileAbility

func _ready():
	setup_on_ready()
	animated_sprite_2d.play('repeat')

func on_hit():
	animated_sprite_2d.play('hit')

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "hit":
		print('test')
		queue_free()
