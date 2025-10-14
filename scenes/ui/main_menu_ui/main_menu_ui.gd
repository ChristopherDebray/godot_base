extends Control

@onready var start: TextureButton = $ColorRect/MarginContainer/VBoxContainer/Start
@onready var options: TextureButton = $ColorRect/MarginContainer/VBoxContainer/Options
@onready var quit: TextureButton = $ColorRect/MarginContainer/VBoxContainer/Quit
@onready var pause_ui: Control = $ColorRect/OptionsUi/PauseUi
@onready var menu_boostrap: Control = $MenuBoostrap
@onready var cross: TextureButton = $ColorRect/OptionsUi/Cross
@onready var options_ui: Control = $ColorRect/OptionsUi
@onready var margin_container: MarginContainer = $ColorRect/MarginContainer

func _ready() -> void:
	menu_boostrap._on_open_menu()
	pause_ui.on_menu_toggle.connect(_on_open_menu)
	pause_ui.set_physics_process(false)
	MenuManager.push(margin_container)

func _on_open_menu(state: bool):
	if state:
		return
	
	menu_boostrap._on_open_menu()

func _on_start_pressed() -> void:
	GameManager.load_level("level_farm_one")
	MenuManager.pop()

func _on_quit_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func _on_options_pressed() -> void:
	MenuManager.push(options_ui)

func _on_cross_pressed() -> void:
	MenuManager.pop()
