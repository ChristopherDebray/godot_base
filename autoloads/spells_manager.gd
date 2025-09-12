extends Node

enum ELEMENTS {
	WATER,
	FIRE,
	EARTH,
	WIND,
	PHYSICAL,
}

const SPELLS_ELEMENTS = {
	"1": 'firebolt',
	"1,3": 'lightning',
}

const SPELLS: Dictionary = {
	'firebolt': preload("res://data/spells/spell_ressources/firebolt.tres"),
	'lightning': preload("res://data/spells/spell_ressources/lightning.tres"),
}

static func get_key_from_spell_name(name: String):
	for key in SPELLS.keys():
		var spell_data := SPELLS[key] as AbilityData
		if spell_data and spell_data.name == name:
			return key
	
	return []
