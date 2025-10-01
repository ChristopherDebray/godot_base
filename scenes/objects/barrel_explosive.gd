extends Damageable

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

enum BARREL_TYPE {
	EXPLOSION,
	POISON,
	OIL,
}

const BARREL_TYPE_CONTENT = {
	0: {
		'frame': 0,
		'ability': preload("res://data/abilities/enemy/explosion.tres")
	},
	1: {
		'frame': 1,
		'ability': preload("res://data/abilities/enemy/explosion.tres")
	},
	2: {
		'frame': 2,
		'ability': preload("res://data/abilities/enemy/explosion.tres")
	}
}

@export var barrel_type: BARREL_TYPE = BARREL_TYPE.EXPLOSION

var current_barrel_content

func _ready() -> void:
	current_barrel_content = BARREL_TYPE_CONTENT[barrel_type]
	animated_sprite_2d.frame = current_barrel_content.frame

func on_death():
	SignalManager.use_ability.emit(current_barrel_content.ability, global_position, global_position, AbilityManager.TARGET_TYPE.ENEMY, self)
	super.on_death()
