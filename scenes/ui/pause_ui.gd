extends Control

@onready var ability_list: VBoxContainer = $MarginContainer/TextureRect/MarginContainer/TabContainer/Spells/MarginContainer/HBoxContainer/VScrollBar/AbilityList
@onready var elements_container: HBoxContainer = $MarginContainer/TextureRect/MarginContainer/TabContainer/Spells/MarginContainer/HBoxContainer/Panel/MarginContainer/VBoxContainer/ElementsContainer

@export var sheet: Texture2D
@export var cell_size: Vector2i = Vector2i(32, 32)

const KEY_INDICATOR = preload("res://scenes/ui/components/key_indicator.tscn")

var _cache: Dictionary = {}

const ABILITY_INFO = preload("res://scenes/ui/components/ability_info.tscn")

func _ready() -> void:
	var ability_datas = SpellsManager.SPELLS.values()
	for ability_data in ability_datas:
		var ability_detail_ui = ABILITY_INFO.instantiate()
		ability_detail_ui.ability_data = ability_data
		ability_list.add_child(ability_detail_ui)
	_update_elements_display()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		var is_paused = get_tree().paused
		get_tree().paused = !is_paused
		if is_paused:
			hide()
		else:
			show()

func _update_elements_display() -> void:
	var element_indicator = VBoxContainer.new()
	elements_container.add_child(element_indicator)
	
	var key_indicator = KEY_INDICATOR.instantiate()
	key_indicator.action_name = 'x_1_action'
	element_indicator.add_child(key_indicator)
	
	var bg := TextureRect.new()
	bg.texture = preload("res://assets/ui/losange.png")
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	element_indicator.add_child(bg)

	var icon := TextureRect.new()
	icon.texture = AbilityManager.get_icon(SpellsManager.ELEMENTS.FIRE)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(icon)
