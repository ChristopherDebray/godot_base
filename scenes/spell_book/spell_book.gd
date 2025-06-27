extends Node2D

const SpellEnums = preload("res://data/spells/enums.gd")
const Spells = preload("res://data/spells/spells.gd")

var spells: Dictionary = {}
var _cooldowns := {}

func _ready() -> void:
	register_spells()

func _physics_process(_delta: float) -> void:
	pass

func get_spell_from_elements(elements: Array[SpellEnums.ELEMENTS]) -> SpellData:
	if elements.is_empty():
		return null

	var combo_key = _combo_key(elements)
	var spell_name = Spells.SPELLS_ELEMENTS.get(combo_key)

	if not spell_name:
		return null

	var spell = Spells.SPELLS.get(spell_name)
	return spell as SpellData

func register_spell(elements: Array[int], data: Dictionary):
	var key = elements.duplicate()
	key.sort()
	spells[key] = data

func use_spell(active_elements: Array[SpellEnums.ELEMENTS], aim_direction: Vector2):
	active_elements.sort()
	var spell = get_spell_from_elements(active_elements)
	
	if (!spell):
		return

	if not SpellCooldownManager.can_cast(active_elements):
		print('on cooldown')
		return

	var spellInstance = spell.scene.instantiate()
	handle_spell_init(spellInstance, aim_direction)
	get_tree().root.add_child(spellInstance)
	_register_cooldown(active_elements, spell.cooldown)

func handle_spell_init(spellInstance: BaseSpell, aim_direction: Vector2):
	if is_instance_of(spellInstance, ProjectileSpell):
		spellInstance.init(aim_direction, global_position)
	elif is_instance_of(spellInstance, AoeInstantSpell):
		spellInstance.init(get_global_mouse_position())

func _can_cast(elementCombo: Array[SpellEnums.ELEMENTS], cooldown: float) -> bool:
	var key = _combo_key(elementCombo)
	if not _cooldowns.has(key):
		return true
	var remaining = _cooldowns[key] - Time.get_ticks_msec() / 1000.0
	return remaining <= 0

func _register_cooldown(elementCombo: Array[SpellEnums.ELEMENTS], cooldown: float) -> void:
	SpellCooldownManager.set_cooldown(elementCombo, Time.get_ticks_msec() / 1000.0 + cooldown)

func get_remaining_cooldown(combo: Array[SpellEnums.ELEMENTS]) -> float:
	var key = _combo_key(combo)
	var spellKey = Spells.SPELLS_ELEMENTS[key]
	
	if not _cooldowns.has(spellKey):
		return 0.0
	return max(0.0, _cooldowns[spellKey] - Time.get_ticks_msec() / 1000.0)

func _combo_key(arr: Array[SpellEnums.ELEMENTS]) -> String:
	var sorted = arr.duplicate()
	sorted.sort()
	return ",".join(PackedStringArray(sorted.map(func(x): return str(x))))

func register_spells():
	for key in Spells.SPELLS.keys():
		spells[key] = Spells.SPELLS[key]
		var data = Spells.SPELLS[key]
