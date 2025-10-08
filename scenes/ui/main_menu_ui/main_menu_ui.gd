extends Control

@onready var start: TextureButton = $ColorRect/MarginContainer/VBoxContainer/Start
@onready var options: TextureButton = $ColorRect/MarginContainer/VBoxContainer/Options
@onready var quit: TextureButton = $ColorRect/MarginContainer/VBoxContainer/Quit
@onready var pause_ui: Control = $ColorRect/PauseUi

func _on_start_pressed() -> void:
	GameManager.load_level("level_farm_one")

func _on_quit_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func _on_options_pressed() -> void:
	pause_ui.show()
