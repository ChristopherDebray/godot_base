extends ProjectileAbility

func _ready():
	setup_on_ready()
	animated_sprite_2d.play('repeat')

func on_hit():
	queue_free()
