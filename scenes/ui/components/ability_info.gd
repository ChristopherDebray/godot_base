extends Control

@onready var ability_name: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer2/AbilityName
@onready var description: RichTextLabel = $Panel/MarginContainer/HBoxContainer/VBoxContainer2/Description
#@onready var main_element: TextureRect = $VBoxContainer/MarginContainer/HBoxContainer2/MainElement
@onready var icon: TextureRect = $Panel/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Panel/Icon

@onready var elements: HBoxContainer = $Panel/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Elements

@export var ability_data: SpellRessource

var _cache: Dictionary = {}

func _ready() -> void:
	icon.texture = ability_data.icon
	for key in ability_data.elements:
		var icon_indicator = AbilityManager._get_element_icon_indicator(key)
		elements.add_child(icon_indicator)
	
	ability_name.text = ability_data.name
	description.text = ability_data.description
