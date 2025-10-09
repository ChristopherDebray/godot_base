extends ProjectileAbility

const ICE_FORMATION = preload("res://assets/sounds/effects/ice_formation.ogg")

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	setup_on_ready()
	set_physics_process(false)
	animated_sprite_2d.play('start')
	SoundManager.play_tag_at("arrow", ICE_FORMATION, global_position, -4.0)

func on_hit():
	animated_sprite_2d.play('hit')

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "start":
		animated_sprite_2d.play('repeat')
		animation_player.play("hit")
		set_physics_process(true)
	if animated_sprite_2d.animation == "hit":
		queue_free()
