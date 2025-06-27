extends Control
class_name SpellCooldownIndicator

@export var spell_name: String
@export var icon: Texture

const SpellEnums = preload("res://data/spells/spells.gd")

var remaining_time: float = 0.0
var max_cooldown: float = 1.0

@onready var icon_node: TextureRect = $Icon
@onready var overlay: ColorRect = $CooldownOverlay
@onready var label: Label = $CooldownLabel

func _ready():
	icon_node.texture = icon
	update_ui(0)

func _process(_delta):
	var key = SpellEnums.get_key_from_spell_name(spell_name)
	if key.is_empty():
		return

	var remain = SpellCooldownManager.get_remaining(key)
	var spell = SpellEnums.SPELLS.get(key)
	if spell == null:
		return

	var total = spell.cooldown
	update_cooldown(remain, total)

func update_cooldown(remain: float, total: float):
	remaining_time = remain
	max_cooldown = total
	update_ui(remain)

func update_ui(time_left: float):
	var ratio = clampf(time_left / max_cooldown, 0.0, 1.0)
	overlay.visible = time_left > 0.0
	overlay.modulate.a = 0.6 # semi-transparent
	overlay.size.y = size.y * ratio
	label.text = str(round(time_left * 10.0) / 10.0) if time_left > 0.0 else ""
