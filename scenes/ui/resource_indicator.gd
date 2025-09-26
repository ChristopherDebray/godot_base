extends Control

@onready var color_rect: ColorRect = $ColorRect

@export var resource_type: GameManager.RESOURCE_TYPE = GameManager.RESOURCE_TYPE.LIFE

const COLOR_HEALTH = 'bf2626'
const MANA_HEALTH = '2d81ce'

var width_tween: Tween
var full_width: float = 0.0

func _ready() -> void:
	SignalManager.resource_value_change.connect(_on_resource_value_changed)
	full_width = size.y
	if full_width <= 0.0:
		full_width = 100.0 # fallback

func fill_indicator_color():
	var fill_color
	match resource_type:
		GameManager.RESOURCE_TYPE.LIFE:
			fill_color = Color(COLOR_HEALTH)
	
	color_rect.color = fill_color

func _on_resource_value_changed(amount: float, resource_type: GameManager.RESOURCE_TYPE):
	match resource_type:
		GameManager.RESOURCE_TYPE.LIFE:
			_on_health_changed(GameManager.current_health, GameManager.max_health, float(GameManager.current_health) / float(GameManager.max_health))

func _on_health_changed(current: int, maxv: int, ratio: float) -> void:
	_update_bar_immediate(ratio)
	
	#percent_label.text = "%d%%" % percent

func _update_bar_immediate(ratio: float) -> void:
	if ratio <= 0:
		color_rect.scale.y = 0
		return
	
	color_rect.scale.y = ratio
