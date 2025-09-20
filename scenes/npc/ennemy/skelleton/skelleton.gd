extends BaseNpc

const ARROW_DATA: AbilityData = preload("res://data/abilities/common/arrow.tres")

func _do_ability(delta: float) -> bool:
	var target = _ability_target.global_position
	var origin = muzzle.global_position
	var direction = origin.direction_to(target)
	SignalManager.use_ability.emit(ARROW_DATA, direction, origin, targeting.current_ability_target_type, self)
	return true
