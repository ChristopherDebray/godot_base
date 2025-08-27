extends BaseEnemy

const ARROW_DATA: AbilityData = preload("res://data/abilities/common/arrow.tres")

func _do_attack(delta: float) -> bool:
	#instance, target, origin
	var target = _player_ref.global_position
	var origin = muzzle.global_position
	var direction = origin.direction_to(target)
	SignalManager.use_ability.emit(ARROW_DATA, direction, origin, AbilityManager.TARGET_TYPE.ENEMY)
	return true
