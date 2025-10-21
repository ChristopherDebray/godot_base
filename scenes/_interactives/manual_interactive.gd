class_name ManualInteractive
extends BaseInteractive

func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_instance_of(body, Player):
		SignalManager.player_interact.connect(interact)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if is_instance_of(body, Player):
		SignalManager.player_interact.disconnect(interact)
