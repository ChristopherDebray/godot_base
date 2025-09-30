extends Control

@onready var ability_list: VBoxContainer = $MarginContainer/TextureRect/MarginContainer/TabContainer/Spells/MarginContainer/VScrollBar/AbilityList

@export var sheet: Texture2D
@export var cell_size: Vector2i = Vector2i(32, 32)

var _cache: Dictionary = {}

const ABILITY_INFO = preload("res://scenes/ui/components/ability_info.tscn")

func _ready() -> void:
	var ability_datas = SpellsManager.SPELLS.values()
	for ability_data in ability_datas:
		var ability_detail_ui = ABILITY_INFO.instantiate()
		ability_detail_ui.ability_data = ability_data
		ability_list.add_child(ability_detail_ui)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		var is_paused = get_tree().paused
		get_tree().paused = !is_paused
		if is_paused:
			hide()
		else:
			show()
