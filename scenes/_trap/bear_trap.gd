extends BaseSelfActivatingTrap

const BEAR_TRAP = preload("res://assets/sounds/effects/bear_trap.mp3")

func _on_area_2d_body_entered(body: Node2D) -> void:
	super._on_area_2d_body_entered(body)
	SoundManager.play_tag_at("spell_cast", BEAR_TRAP, global_position, -4.0)
