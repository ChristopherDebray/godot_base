extends PanelContainer

@onready var ability_name: Label = $VBoxContainer/MarginContainer/HBoxContainer2/AbilityName
@onready var main_element: TextureRect = $VBoxContainer/MarginContainer/HBoxContainer2/MainElement

@onready var description: Label = $VBoxContainer/MarginContainer2/Description

@onready var damage_label: Label = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer/HBoxContainer/DamageLabel
@onready var range_label: Label = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer/HBoxContainer2/RangeLabel
@onready var aoe_damage: Label = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer/HBoxContainer3/AoeDamage

@onready var effect_detail: Label = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer2/EffectDetail
@onready var elements_box: HBoxContainer = $VBoxContainer/MarginContainer/HBoxContainer2/MarginContainer/Elements

@export var ability_data: SpellRessource
@export var sheet: Texture2D
@export var cell_size: Vector2i = Vector2i(13, 12)
@export var mapping := [
	0,
	1,
	2,
	3
]

var _cache: Dictionary = {}

func _ready() -> void:
	ability_name.text = ability_data.name.to_upper()
	var icon_tex: Texture2D = get_icon(ability_data.main_element)
	main_element.texture = icon_tex
	description.text = ability_data.description
	damage_label.text = str(ability_data.damage)
	aoe_damage.text = str(ability_data.aoe_damage)
	range_label.text = str(ability_data.range)
	
	for e in ability_data.elements:
		_add_icon(e)

func _add_icon(element_id: int) -> void:
	var tr := TextureRect.new()
	tr.expand = true
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(14, 12)
	tr.texture = get_icon(element_id)
	tr.scale = Vector2(6, 6)
	elements_box.add_child(tr)

func get_icon(key: int) -> Texture2D:
	if sheet == null:
		return null
	if _cache.has(key):
		return _cache[key]
	var col = mapping[key]
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(Vector2(col * cell_size.x, 0), cell_size)
	_cache[key] = at
	return at
