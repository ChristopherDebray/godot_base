extends ProjectileSpell

func _ready():
	setup_on_ready()
	animated_sprite_2d.play('start')

func on_hit():
	animated_sprite_2d.play('hit')

# @todo Add reset of stat on effect end
# Add magnitude calculation
