extends Node2D

const SpellEnums = preload("res://data/spells/enums.gd")
const SpellData = preload("res://data/spells/spells.gd")

var spells: Dictionary = {}

func _ready() -> void:
	register_spells()
	#spell_book.add_child()

func _physics_process(_delta: float) -> void:
	pass

func get_spell_from_elements(elements: Array[int]) -> SpellData:
	if elements.is_empty():
		return null

	var combo = elements.duplicate()
	combo.sort() # ignore l’ordre d’activation

	if spells.has(combo):
		return spells[combo]
	
	if combo.size() == 1 and spells.has([combo[0]]):
		return spells[[combo[0]]]

	return null

func register_spell(elements: Array[int], data: Dictionary):
	var key = elements.duplicate()
	key.sort()
	spells[key] = data

func use_spell(active_elements: Array[int], aim_direction: Vector2):
	var spell = get_spell_from_elements(active_elements)
	if (!spell):
		return

	var spellInstance = spell.scene.instantiate()
	spellInstance.init(aim_direction, global_position)
	get_tree().root.add_child(spellInstance)

func register_spells():
	for key in SpellData.SPELLS.keys():
		var combo = key.duplicate()
		combo.sort()
		spells[combo] = SpellData.SPELLS[key]
