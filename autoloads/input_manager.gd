extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	pass
	#if event.is_action_pressed("pause"):
		#UiManager.toggle_pause()
