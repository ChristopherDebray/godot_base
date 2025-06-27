extends Node

func _ready():
	var fireball = preload("res://data/spells/spell_ressources/fireball.tres")
	var s = fireball.get_script()

	print("Script path:", s.resource_path)
	print("Type name:", s.get_instance_base_type())
	print("Custom class:", s.get_class())

	print("is SpellData:", fireball is SpellData)
	print("casted:", fireball as SpellData)
