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
	"3,3": 'wind shield',
	"0,0": 'ice cone',
}

enum PROFESSION {
	MAGE,
	RANGER,
	PALADIN
}

const SPELLS: Dictionary = {
	'firebolt': preload("res://data/spells/spell_ressources/firebolt.tres"),
	'thunderstrike': preload("res://data/spells/spell_ressources/thunderstrike.tres"),
	'ice spike': preload("res://data/spells/spell_ressources/ice_spike.tres"),
	'wind shield': preload("res://data/spells/spell_ressources/wind_shield.tres"),
	'ice cone': preload("res://data/spells/spell_ressources/ice_cone.tres"),
}

const PROFESSION_LOADOUTS = {
	PROFESSION.MAGE: {
		'spells': {
			'firebolt': preload("res://data/spells/spell_ressources/firebolt.tres"),
			'thunderstrike': preload("res://data/spells/spell_ressources/thunderstrike.tres"),
			'ice spike': preload("res://data/spells/spell_ressources/ice_spike.tres"),
			'wind shield': preload("res://data/spells/spell_ressources/wind_shield.tres"),
			'ice cone': preload("res://data/spells/spell_ressources/ice_cone.tres"),
		},
		'elements': {
			"1": 'firebolt',
			"1,3": 'thunderstrike',
			"0,3": 'ice spike',
			"3,3": 'wind shield',
			"0,0": 'ice cone',
		}
	}
}

var current_profession: SpellsManager.PROFESSION = SpellsManager.PROFESSION.MAGE
var current_profession_loadout = SpellsManager.PROFESSION_LOADOUTS[current_profession]

#static func get_key_from_spell_name(name: String):
	#for key in SPELLS.keys():
		#var spell_data := SPELLS[key] as AbilityData
		#if spell_data and spell_data.name == name:
			#return key
	#
	#return []
#
#static func get_key_by_name_in_loadout(name: String, profession: PROFESSION):
	#var profession_loadout = PROFESSION_LOADOUTS[profession]
	#
	#for key in profession_loadout.spells.keys():
		#var spell_data := profession_loadout[key] as AbilityData
		#if spell_data and spell_data.name == name:
			#return key
	#
	#return []
