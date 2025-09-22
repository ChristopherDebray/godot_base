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
	"1,3": 'thunderstrike',
	"0,3": 'ice spike',
}

const SPELLS: Dictionary = {
	'firebolt': preload("res://data/spells/spell_ressources/firebolt.tres"),
	'thunderstrike': preload("res://data/spells/spell_ressources/thunderstrike.tres"),
	'ice spike': preload("res://data/spells/spell_ressources/ice_spike.tres"),
}

static func get_key_from_spell_name(name: String):
	for key in SPELLS.keys():
		var spell_data := SPELLS[key] as AbilityData
		if spell_data and spell_data.name == name:
			return key
	
	return []
