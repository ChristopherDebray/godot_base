extends Control

signal on_menu_toggle(state: bool)

@onready var ability_list: VBoxContainer = $MarginContainer/TextureRect/MarginContainer/TabContainer/Spells/MarginContainer/HBoxContainer/VScrollBar/AbilityList
@onready var elements_container: HBoxContainer = $MarginContainer/TextureRect/MarginContainer/TabContainer/Spells/MarginContainer/HBoxContainer/Panel/MarginContainer/VBoxContainer/ElementsContainer
@onready var menu_boostrap: Control = $MenuBoostrap

@export var sheet: Texture2D
@export var cell_size: Vector2i = Vector2i(32, 32)

const KEY_INDICATOR = preload("res://scenes/ui/components/key_indicator.tscn")
const ABILITY_INFO = preload("res://scenes/ui/components/ability_info.tscn")

var _cache: Dictionary = {}

func _ready() -> void:
	var ability_datas = SpellsManager.current_profession_loadout.spells.values()
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
			on_menu_toggle.emit(false)
			MenuManager.pop()
		else:
			show()
			menu_boostrap._on_open_menu()
			on_menu_toggle.emit(true)
			MenuManager.push(self)

func _update_elements_display() -> void:
	var element_indicator = VBoxContainer.new()
	elements_container.add_child(element_indicator)
	element_indicator.alignment = element_indicator.ALIGNMENT_CENTER
	
	var key_indicator = KEY_INDICATOR.instantiate()
	key_indicator.action_name = 'element_1'
	element_indicator.add_child(key_indicator)
	element_indicator.add_child(AbilityManager._get_element_icon_indicator(SpellsManager.ELEMENTS.FIRE))
