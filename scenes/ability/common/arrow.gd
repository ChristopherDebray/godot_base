extends ProjectileAbility

const ARROW_SWISH = preload("res://assets/sounds/effects/arrow-swish.ogg")

func _ready():
	setup_on_ready()
	SoundManager.play_tag_at("arrow", ARROW_SWISH, global_position, -4.0)
	animated_sprite_2d.play('repeat')

func on_hit():
	queue_free()
