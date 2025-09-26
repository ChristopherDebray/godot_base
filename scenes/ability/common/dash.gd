extends SelfAbility

func _ready() -> void:
	return
	var typed_sender
	if (is_instance_of(Player, sender)):
		typed_sender = sender as Player
	else:
		typed_sender = sender as BaseNpc
		typed_sender.global_position + Vector2(200, 200)
		typed_sender.locomotion_freeze(true)
