extends "res://data/spells/spell_scenes/base_spell.gd"

func _ready():
	animated_sprite_2d.play('repeat')

func on_hit():
	animated_sprite_2d.play('hit')
