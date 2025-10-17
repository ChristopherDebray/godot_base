extends Control

const RELIC_SELECTION = preload("res://scenes/ui/relics/components/relic_selection.tscn")

var _relics: Array[BaseRelic]
@onready var relics_holder: HBoxContainer = $MarginContainer/RelicsHolder

func roll_relics():
	var relics = RelicManager.pick_relic_amount(3)
	set_relics(relics)

func set_relics(relics: Array[BaseRelic]):
	_relics = relics
	for relic in _relics:
		var instance = RELIC_SELECTION.instantiate()
		instance.setup(relic)
		relics_holder.add_child(instance)
