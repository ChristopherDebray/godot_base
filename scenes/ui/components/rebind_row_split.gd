# RebindRowSplit.gd - Une row avec 2 colonnes
extends HBoxContainer

@export var action_name: StringName

@onready var label_action: Label = $ActionLabel
@onready var keyboard_container: HBoxContainer = $KeyboardContainer
@onready var gamepad_container: HBoxContainer = $GamepadContainer

func _ready() -> void:
	label_action.text = _prettify_action_name(action_name)
	_refresh_bindings()

func _refresh_bindings() -> void:
	# Colonne Keyboard
	var keyboard_bindings := _get_bindings_for_device(false)
	$KeyboardContainer/Label.text = _format_bindings(keyboard_bindings)
	
	# Colonne Gamepad
	var gamepad_bindings := _get_bindings_for_device(true)
	$GamepadContainer/Label.text = _format_bindings(gamepad_bindings)

func _get_bindings_for_device(is_gamepad: bool) -> Array[InputEvent]:
	var result: Array[InputEvent] = []
	for e in InputMap.action_get_events(action_name):
		var event_is_gamepad := e is InputEventJoypadButton or e is InputEventJoypadMotion
		if event_is_gamepad == is_gamepad:
			result.append(e)
	return result

func _format_bindings(bindings: Array[InputEvent]) -> String:
	if bindings.is_empty():
		return "(unbound)"
	var names: Array[String] = []
	for e in bindings:
		names.append(e.as_text())
	return ", ".join(names)

func _prettify_action_name(action: StringName) -> String:
	return String(action).capitalize().replace("_", " ")
