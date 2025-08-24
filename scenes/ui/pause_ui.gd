extends Control

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		var is_paused = get_tree().paused
		get_tree().paused = !is_paused
		if is_paused:
			hide()
		else:
			show()
