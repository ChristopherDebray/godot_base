class_name SpellBook
extends Node2D

var spells: Dictionary = {}
var _cooldowns := {}

func _ready() -> void:
	register_spells()

func _physics_process(_delta: float) -> void:
	pass

func get_spell_from_elements(elements: Array[SpellsManager.ELEMENTS]) -> AbilityData:
	if elements.is_empty():
		return null

	var combo_key = _combo_key(elements)
	var spell_name = SpellsManager.SPELLS_ELEMENTS.get(combo_key)

	if not spell_name:
		return null

	var spell = SpellsManager.SPELLS.get(spell_name)
	return spell as AbilityData

func register_spell(elements: Array[int], data: Dictionary):
	var key = elements.duplicate()
	key.sort()
	spells[key] = data

func use_spell(active_elements: Array[SpellsManager.ELEMENTS], aim_direction: Vector2):
	active_elements.sort()
	var spell = get_spell_from_elements(active_elements)
	
	if (!spell):
		return

	if not SpellCooldownManager.can_cast(active_elements):
		return
	var nodes := get_tree().get_nodes_in_group("player")
	var player = nodes[0] as Player

	if spell.kind == AbilityData.ABILITY_KIND.AOE:
		SignalManager.use_ability.emit(spell, get_global_mouse_position(), global_position, AbilityManager.TARGET_TYPE.PLAYER, player)
	elif spell.kind == AbilityData.ABILITY_KIND.PROJECTILE:
		SignalManager.use_ability.emit(spell, aim_direction, global_position, AbilityManager.TARGET_TYPE.PLAYER, player)
	_register_cooldown(spell.name, spell.cooldown)

func _can_cast(elementCombo: Array[SpellsManager.ELEMENTS], cooldown: float) -> bool:
	var key = _combo_key(elementCombo)
	if not _cooldowns.has(key):
		return true
	var remaining = _cooldowns[key] - Time.get_ticks_msec() / 1000.0
	return remaining <= 0

func _register_cooldown(abilityName: String, cooldown: float) -> void:
	SpellCooldownManager.set_cooldown(abilityName, Time.get_ticks_msec() / 1000.0 + cooldown)

func get_remaining_cooldown(combo: Array[SpellsManager.ELEMENTS]) -> float:
	var key = _combo_key(combo)
	var spellKey = SpellsManager.SPELLS_ELEMENTS[key]
	
	if not _cooldowns.has(spellKey):
		return 0.0
	return max(0.0, _cooldowns[spellKey] - Time.get_ticks_msec() / 1000.0)

func _combo_key(arr: Array[SpellsManager.ELEMENTS]) -> String:
	var sorted = arr.duplicate()
	sorted.sort()
	return ",".join(PackedStringArray(sorted.map(func(x): return str(x))))

func register_spells():
	for key in SpellsManager.SPELLS.keys():
		spells[key] = SpellsManager.SPELLS[key]
		var data = SpellsManager.SPELLS[key]
