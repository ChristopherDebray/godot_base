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

const SPELLS_d: Dictionary = {
	[ELEMENTS.FIRE, ELEMENTS.FIRE]: {
		name = "firebolt",
		damage = 10.5,
		effect = EffectsManager.EFFECTS.BURN,
		magnitude = 1.0,
		range = 30.5,
		cooldown = 2.5
	},
	[ELEMENTS.WATER, ELEMENTS.WATER]: {
		name = "Ice Lance",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[ELEMENTS.EARTH, ELEMENTS.EARTH]: {
		name = "Stone Shield",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[ELEMENTS.WIND, ELEMENTS.WIND]: {
		name = "Gust",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[ELEMENTS.FIRE, ELEMENTS.WATER]: {
		name = "Steam Burst",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[ELEMENTS.FIRE, ELEMENTS.EARTH]: {
		name = "Magma Wave",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[ELEMENTS.WATER, ELEMENTS.WIND]: {
		name = "Blizzard",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[ELEMENTS.EARTH, ELEMENTS.WIND]: {
		name = "Sandstorm",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[ELEMENTS.FIRE, ELEMENTS.WIND]: {
		name = "Flame Tornado",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[ELEMENTS.WATER, ELEMENTS.EARTH]: {
		name = "Mud Trap",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	}
}
