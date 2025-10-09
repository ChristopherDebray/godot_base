extends ProjectileAbility

const SLASH = preload("res://assets/sounds/effects/slash.ogg")

func _ready():
	setup_on_ready()
	animated_sprite_2d.play('default')
	SoundManager.play_tag_at("spell_cast", SLASH, global_position, 0)

func on_hit():
	queue_free()
