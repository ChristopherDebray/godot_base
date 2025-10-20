class_name ZoneInteractive
extends BaseInteractive

func _on_area_2d_body_entered(body: Node2D) -> void:
	call_deferred("interact")
