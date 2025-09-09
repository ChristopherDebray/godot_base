extends BaseEnemy

const EXPLOSION = preload("res://data/abilities/enemy/explosion.tres")

func _do_attack(delta: float) -> bool:
	can_move = false
	_pulse_red(attack_timer.wait_time)
	attack_timer.start()

	return true

func _launch_explosion():
	var origin = global_position
	SignalManager.use_ability.emit(EXPLOSION, origin, origin, AbilityManager.TARGET_TYPE.ALL, self)

func _on_attack_timer_timeout() -> void:
	_launch_explosion()
	_modulate_red(false)
