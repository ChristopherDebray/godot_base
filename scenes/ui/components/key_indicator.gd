extends NinePatchRect

@onready var label: Label = $Label
@onready var timer: Timer = $Timer

@export var action_name: String = "x_1_action"
@export var is_auto_animated: bool = true

enum KEY_STATE {
	UP,
	DOWN
}

const XBD = preload("res://assets/ui/XBD.png")
const KBD = preload("res://assets/ui/KBD.png")

const XBOX_COLORS := {
	JOY_BUTTON_A: Color8(40, 200, 40),
	JOY_BUTTON_B: Color8(220, 60, 60),
	JOY_BUTTON_X: Color8(60, 120, 255),
	JOY_BUTTON_Y: Color8(245, 210, 40)
}

const LABEL_OFFSET_Y := {
	KEY_STATE.UP: -5.0,
	KEY_STATE.DOWN: 0.0
}

const FRAME_SIZE := 64

# Cache des AtlasTexture par scheme/state
var _frames: Dictionary = {}
var _state = KEY_STATE.UP

func _ready() -> void:
	_build_frames_cache()
	InputSchemeManager.scheme_changed.connect(_on_scheme_changed)
	_refresh_visual()
	if is_auto_animated:
		timer.start()
	else:
		set_process_unhandled_input(true)

func _build_frames_cache() -> void:
	# Build once; réutilisé par toutes les instances de ce Node
	_frames.clear()
	_frames[InputSchemeManager.SCHEME.KEYBOARD] = {
		KEY_STATE.UP: _atlas(KBD, 0),
		KEY_STATE.DOWN: _atlas(KBD, 1)
	}
	_frames[InputSchemeManager.SCHEME.XBOX] = {
		KEY_STATE.UP: _atlas(XBD, 0),
		KEY_STATE.DOWN: _atlas(XBD, 1)
	}
	# Optionnel: PLAYSTATION, SWITCH si tu as des sheets

func _atlas(sheet: Texture2D, frame_index: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(frame_index * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
	return at

func _on_scheme_changed(_s: int) -> void:
	_refresh_visual()

func _refresh_visual() -> void:
	var scheme := InputSchemeManager.current_scheme

	# 1) Texture de fond selon scheme + état
	if _frames.has(scheme):
		texture = _frames[scheme][_state]
	else:
		texture = _frames[InputSchemeManager.SCHEME.KEYBOARD][_state]

	# 2) Contenu du label et couleur
	if action_name == "":
		label.text = ""
		return

	if scheme == InputSchemeManager.SCHEME.KEYBOARD:
		label.text = _keyboard_label_for_action()
		self.self_modulate = Color.WHITE
	else:
		var btn := _gamepad_button_for_action()
		label.text = _gamepad_label_for_button(btn)
		self.self_modulate = _color_for_gamepad_button(btn)

	# 3) Offset visuel
	label.position.y = LABEL_OFFSET_Y[_state]

func _keyboard_label_for_action() -> String:
	var events := InputMap.action_get_events(action_name)
	for e in events:
		if e is InputEventKey and e.physical_keycode != 0:
			return OS.get_keycode_string(e.physical_keycode)
	return "?"

func _gamepad_button_for_action() -> int:
	var events := InputMap.action_get_events(action_name)
	for e in events:
		if e is InputEventJoypadButton:
			return e.button_index
	return -1

func _gamepad_label_for_button(b: int) -> String:
	if b == JOY_BUTTON_A: return "A"
	if b == JOY_BUTTON_B: return "B"
	if b == JOY_BUTTON_X: return "X"
	if b == JOY_BUTTON_Y: return "Y"
	return "?"

func _color_for_gamepad_button(b: int) -> Color:
	if XBOX_COLORS.has(b):
		return XBOX_COLORS[b]
	return Color.WHITE

# Anime l’état sur vraie pression / relâchement de l’action
func _unhandled_input(event: InputEvent) -> void:
	if action_name == "" or is_auto_animated:
		return
	if event.is_action_pressed(action_name):
		_set_state(KEY_STATE.DOWN)
	elif event.is_action_released(action_name):
		_set_state(KEY_STATE.UP)

func _on_timer_timeout():
	if(KEY_STATE.DOWN == _state):
		_set_state(KEY_STATE.UP)
		return
	
	_set_state(KEY_STATE.DOWN)

func _set_state(new_state: int) -> void:
	if _state == new_state:
		return
	_state = new_state
	_refresh_visual()
