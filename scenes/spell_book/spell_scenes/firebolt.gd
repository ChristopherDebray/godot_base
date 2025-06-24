extends "res://scenes/spell_book/spell_scenes/base_spell.gd"

var _dir_of_travel: Vector2 = Vector2.ZERO
const SPEED: float = 400.0

func init(aim_direction: Vector2, start_pos: Vector2) -> void:
	_dir_of_travel = aim_direction
	global_position = start_pos
	print(aim_direction)

func _ready():
	animated_sprite_2d.play('repeat')
	rotation = _dir_of_travel.angle()

func _physics_process(delta: float) -> void:
	position += SPEED * delta * _dir_of_travel

func on_hit():
	animated_sprite_2d.play('hit')
