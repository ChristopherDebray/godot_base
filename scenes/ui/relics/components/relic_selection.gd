extends TextureButton

@onready var title: Label = $MarginContainer/VBoxContainer/Title
@onready var description: RichTextLabel = $MarginContainer/VBoxContainer/Description
@onready var rarity: Label = $MarginContainer/MarginContainer/VBoxContainer/Rarity
@onready var max_stack_obtained: Label = $MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/Control/MaxStackObtained
@onready var max_stack_limit: Label = $MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/Control/MaxStackLimit
@onready var modifiers_container: VBoxContainer = $MarginContainer/VBoxContainer/ModifiersContainer

const POCO_ORANGE_14 = preload("res://themes/font_styles/poco_orange_14.tres")

var _relic: BaseRelic

func setup(relic: BaseRelic):
	_relic = relic

func _ready() -> void:
	title.text = _relic.display_name
	description.text = _relic.description
	rarity.add_theme_color_override("font_color", BaseRelic.RARITY_COLORS[_relic.rarity])
	rarity.text = BaseRelic.RARITY_TEXT[_relic.rarity]
	for modifier in _relic.modifiers:
		var label = Label.new()
		label.label_settings = POCO_ORANGE_14
		label.text = modifier.get_description()
		modifiers_container.add_child(label)

func _on_pressed() -> void:
	GameManager.player.add_relic(_relic)
	RelicManager.on_add_relic.emit(_relic)
