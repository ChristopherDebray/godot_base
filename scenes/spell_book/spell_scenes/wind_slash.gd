extends ProjectileSpell

func _ready():
	setup_on_ready()
	animated_sprite_2d.play('repeat')

func on_hit():
	animated_sprite_2d.play('hit')
