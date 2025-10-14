extends HBoxContainer
class_name RebindRow

@export var action_name: StringName

@onready var label_action: Label = $ActionLabel
@onready var label_binding: Label = $BindingLabel
@onready var btn_rebind: Button = $RebindButton
@onready var btn_clear: Button = $ClearButton

func _ready() -> void:
	label_action.text = String(action_name)
	_refresh_label()  # Pas besoin d'attendre, c'est un autoload
	
	btn_rebind.pressed.connect(_on_rebind_button_pressed)
	btn_clear.pressed.connect(_on_clear_button_pressed)

func _on_rebind_button_pressed() -> void:
	btn_rebind.disabled = true
	btn_rebind.text = "Press any key/button..."
	RebindManager.start_capture(action_name, func(a: StringName, ev: InputEvent):
		btn_rebind.disabled = false
		btn_rebind.text = "Rebind"
		_refresh_label()
	)

func _on_clear_button_pressed() -> void:
	var events := InputMap.action_get_events(action_name)
	for e in events:
		InputMap.action_erase_event(action_name, e)
	RebindManager.save_bindings()
	_refresh_label()

func _refresh_label() -> void:
	var names: Array[String] = []
	for e in InputMap.action_get_events(action_name):
		names.append(e.as_text())
	if names.is_empty():
		label_binding.text = "(unbound)"
	else:
		label_binding.text = ", ".join(names)
