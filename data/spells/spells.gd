extends Node

const Enums = preload("res://data/spells/enums.gd")
const SpellData = preload("res://data/spells/spell_data.gd")

const SPELLS: Dictionary = {
	[Enums.ELEMENTS.FIRE, Enums.ELEMENTS.FIRE]: preload("res://data/spells/fireball.tres"),
}

const SPELLS_d: Dictionary = {
	[Enums.ELEMENTS.FIRE, Enums.ELEMENTS.FIRE]: {
		name = "Fireball",
		damage = 10.5,
		effect = Enums.EFFECTS.FIRE,
		magnitude = 1.0,
		range = 30.5,
		cooldown = 2.5
	},
	[Enums.ELEMENTS.WATER, Enums.ELEMENTS.WATER]: {
		name = "Ice Lance",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[Enums.ELEMENTS.EARTH, Enums.ELEMENTS.EARTH]: {
		name = "Stone Shield",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[Enums.ELEMENTS.WIND, Enums.ELEMENTS.WIND]: {
		name = "Gust",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[Enums.ELEMENTS.FIRE, Enums.ELEMENTS.WATER]: {
		name = "Steam Burst",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[Enums.ELEMENTS.FIRE, Enums.ELEMENTS.EARTH]: {
		name = "Magma Wave",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[Enums.ELEMENTS.WATER, Enums.ELEMENTS.WIND]: {
		name = "Blizzard",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[Enums.ELEMENTS.EARTH, Enums.ELEMENTS.WIND]: {
		name = "Sandstorm",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[Enums.ELEMENTS.FIRE, Enums.ELEMENTS.WIND]: {
		name = "Flame Tornado",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	},
	[Enums.ELEMENTS.WATER, Enums.ELEMENTS.EARTH]: {
		name = "Mud Trap",
		damage = 10.5,
		effect = null,
		magnitude = 0,
		range = 30.5,
		cooldown = 2.5
	}
}
