extends BaseSpell
class_name AoeInstantSpell

func init(spell_data: SpellData, target_pos: Vector2) -> void:
	initSpellResource(spell_data)
	global_position = target_pos
