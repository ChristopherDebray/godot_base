extends Control

@onready var ability_name: Label = $Panel/VBoxContainer2/AbilityName
@onready var description: RichTextLabel = $Panel/VBoxContainer2/Description
#@onready var main_element: TextureRect = $VBoxContainer/MarginContainer/HBoxContainer2/MainElement
@onready var icon: TextureRect = $Panel/VBoxContainer/HBoxContainer/Panel/Icon
@onready var tags: Label = $Panel/VBoxContainer/Tags

@onready var elements: HBoxContainer = $Panel/VBoxContainer/HBoxContainer/Elements

@export var ability_data: SpellRessource

var _cache: Dictionary = {}

func _ready() -> void:
	icon.texture = ability_data.icon
	for key in ability_data.elements:
		var icon_indicator = AbilityManager._get_element_icon_indicator(key)
		elements.add_child(icon_indicator)
	
	ability_name.text = ability_data.name
	description.text = ability_data.description
	tags.text = TextUtils.enum_values_to_joined(ability_data.tags, AbilityData.ABILITY_TAG_LABELS)
