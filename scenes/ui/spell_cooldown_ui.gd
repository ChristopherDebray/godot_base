extends Control

const SpellEnums = preload("res://data/spells/spells.gd")

@onready var indicator_container = $VBoxContainer
@onready var spell_book = get_node("/root/World/Player/SpellBook")

func _process(delta):
	for child in indicator_container.get_children():
		if child is SpellCooldownIndicator:
			var key = SpellEnums.get_key_from_spell_name(child.spell_name)
			var remain = spell_book.get_remaining_cooldown(key)
			var total = spell_book.get_spell_from_elements(key).cooldown
			child.update_cooldown(remain, total)
