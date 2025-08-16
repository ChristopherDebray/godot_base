extends AoeInstantSpell

var _dir_of_travel: Vector2 = Vector2.ZERO
const SPEED: float = 400.0

func _ready():
	animated_sprite_2d.play('repeat')

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "repeat":
		queue_free()

func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite_2d.frame >= 5 && !is_aoe_activated():
		activate_aoe()
