extends NinePatchRect

@onready var label: Label = $Label

@export var label_text := '1'


enum KEY_STATE {
	UP,
	DOWN
}

const XBD = preload("res://assets/ui/XBD.png")
const KBD = preload("res://assets/ui/KBD.png")

const FRAME_SIZE := 64
const ANIMATION := {
	KEY_STATE.UP: {
		'label_position': -5,
		'rect_frame': Rect2(0, 0, FRAME_SIZE, FRAME_SIZE),
	},
	KEY_STATE.DOWN: {
		'label_position': 0,
		'rect_frame': Rect2(FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE),
	},
}

var _current_key_state = KEY_STATE.UP

func _ready() -> void:
	if GameManager.CONTROLS_TYPE.XBOX == GameManager.used_controls:
		self.texture = XBD
	label.text = label_text

func _on_timer_timeout() -> void:
	if KEY_STATE.UP == _current_key_state:
		_current_key_state = KEY_STATE.DOWN
	else:
		_current_key_state = KEY_STATE.UP
	
	var current_anmiation = ANIMATION[_current_key_state]
	self.region_rect = current_anmiation.rect_frame
	label.position.y = current_anmiation.label_position
