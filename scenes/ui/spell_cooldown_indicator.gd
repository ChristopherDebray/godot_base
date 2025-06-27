extends Control
class_name SpellCooldownIndicator

@export var spell_name: String
@export var icon: Texture

const SpellEnums = preload("res://data/spells/spells.gd")
const Enums = preload("res://data/spells/enums.gd")

var remaining_time: float = 0.0
var max_cooldown: float = 1.0

@onready var overlay: ColorRect = $MarginContainer/CooldownOverlay
@onready var icon_node: TextureRect = $MarginContainer/Icon

func _ready():
	icon_node.texture = icon
	update_ui(0)

func _process(_delta):
	var spell = SpellEnums.SPELLS.get(spell_name)
	if spell == null:
		return

	var remain = SpellCooldownManager.get_remaining(spell_name)
	var total = spell.cooldown
	update_cooldown(remain, total)

func update_cooldown(remain: float, total: float):
	remaining_time = remain
	max_cooldown = total
	update_ui(remain)

func update_ui(time_left: float):
	var ratio = clampf(time_left / max_cooldown, 0.0, 1.0)

	if time_left <= 0.0:
		overlay.visible = false
		return

	overlay.visible = true
	var full_height = icon_node.size.y
	overlay.size.y = full_height * ratio

	overlay.color = Color(0, 0, 0, 0.6)
