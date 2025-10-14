extends Node

enum SCHEME { KEYBOARD, XBOX, PLAYSTATION }
const INPUT_ACTIONS = [
	"element_1",
	"element_2",
	"element_3",
]
signal scheme_changed(scheme: SCHEME)

var current_scheme: SCHEME = SCHEME.KEYBOARD

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_set_scheme(_detect_gamepad_scheme())
	elif event is InputEventKey or event is InputEventMouse:
		_set_scheme(SCHEME.KEYBOARD)

func _on_joy_connection_changed(_device_id: int, connected: bool) -> void:
	if connected:
		_set_scheme(_detect_gamepad_scheme())
	elif Input.get_connected_joypads().is_empty():
		_set_scheme(SCHEME.KEYBOARD)

func _detect_gamepad_scheme() -> int:
	var ids := Input.get_connected_joypads()
	if ids.is_empty():
		return SCHEME.KEYBOARD
	var name := Input.get_joy_name(ids[0]).to_lower()
	if "xbox" in name or "xinput" in name: return SCHEME.XBOX
	if "sony" in name or "dual" in name or "playstation" in name: return SCHEME.PLAYSTATION
	return SCHEME.KEYBOARD

func _set_scheme(scheme: SCHEME) -> void:
	if scheme == current_scheme:
		return
	current_scheme = scheme
	emit_signal("scheme_changed", current_scheme)
