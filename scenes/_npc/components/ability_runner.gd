extends Node
class_name AbilityRunner

signal ability_started(ability: AbilityData)
signal ability_launched(ability: AbilityData)
signal ability_interrupted(ability: AbilityData)
signal ability_finished(ability: AbilityData)

enum ABILITY_RUNNER_STATE {
	IDLE,
	CASTING,
	CHANNELING,
	RECOVERY
}

var owner_npc: BaseNpc
var state: ABILITY_RUNNER_STATE = ABILITY_RUNNER_STATE.IDLE
var current_entry: AbilityEntry = null
var current_ability: AbilityData = null

var _cast_timer: Timer
var _channel_timer: Timer
var _recovery_timer: Timer
var _channel_tick_accum: float = 0.0

var _saved_origin: Vector2        # snapshot at begin of cast
var _saved_target_pos: Vector2    # usefull for telegraphed AOE
var _saved_dir: Vector2
var _telegraph_node: Node2D = null

func setup(npc: BaseNpc) -> void:
	owner_npc = npc
	_cast_timer = Timer.new()
	_channel_timer = Timer.new()
	_recovery_timer = Timer.new()
	_cast_timer.one_shot = true
	_channel_timer.one_shot = false
	_recovery_timer.one_shot = true
	add_child(_cast_timer)
	add_child(_channel_timer)
	add_child(_recovery_timer)
	_cast_timer.timeout.connect(_on_cast_timeout)
	_channel_timer.timeout.connect(_on_channel_tick)
	_recovery_timer.timeout.connect(_on_recovery_timeout)

func is_busy() -> bool:
	return state != ABILITY_RUNNER_STATE.IDLE

func start(entry: AbilityEntry, target_pos: Vector2, origin: Vector2, dir: Vector2) -> bool:
	if is_busy():
		return false
	if entry == null or entry.ability == null:
		return false

	current_entry = entry
	current_ability = entry.ability
	_saved_origin = origin
	_saved_target_pos = target_pos
	_saved_dir = dir
	_channel_tick_accum = 0.0
	current_ability.base_cast_time = current_entry.cast_time

	if entry.lock_movement_during_cast:
		owner_npc.locomotion.set_can_move(false)

	# optionnal animation
	if current_entry.animation_name != "":
		owner_npc.animated_sprite_2d.play(entry.animation_name)

	# Telegraph optional (ex: circle on ground)
	_create_telegraph_if_needed()

	emit_signal("ability_started", current_ability)

	# Start ICD au début si demandé
	if current_entry != null and owner_npc.cooldowns != null:
		if entry.start_icd_on == AbilityEntry.ICD_ON.START:
			owner_npc.cooldowns.start(current_ability, _cooldown_for(current_entry))

	# Cast time or direct
	if entry.cast_time > 0.0:
		state = ABILITY_RUNNER_STATE.CASTING
		owner_npc._pulse_red(entry.cast_time)
		_cast_timer.start(entry.cast_time)
	else:
		_launch_now_or_channel()
	return true

func interrupt() -> void:
	if not current_ability:
		return
	if not current_entry.interruptible:
		return
	_cleanup_and_finish(true)

# --- Internal helpers ---

func _cooldown_for(entry: AbilityEntry) -> float:
	if entry.cooldown_override > 0.0:
		return entry.cooldown_override
	return entry.ability.cooldown

func _create_telegraph_if_needed() -> void:
	if current_entry.telegraph_fx == null:
		return
	var node := current_entry.telegraph_fx.instantiate() as Node2D
	if node:
		owner_npc.add_child(node)
		_telegraph_node = node
		_telegraph_node.global_position = _saved_target_pos

func _clear_telegraph() -> void:
	if _telegraph_node and is_instance_valid(_telegraph_node):
		_telegraph_node.queue_free()
	_telegraph_node = null

func _on_cast_timeout() -> void:
	_launch_now_or_channel()

func _launch_now_or_channel() -> void:
	# Launch of principal effect
	_do_launch_effect()
	emit_signal("ability_launched", current_ability)

	# Start ICD at end if asked (most cases)
	if current_entry != null and owner_npc.cooldowns != null:
		if current_entry.start_icd_on == AbilityEntry.ICD_ON.END:
			owner_npc.cooldowns.start(current_ability, _cooldown_for(current_entry))

	# Channeling or recovery
	if current_ability.is_channeled:
		state = ABILITY_RUNNER_STATE.CHANNELING
		_channel_timer.start(current_ability.channel_tick_rate)
	else:
		_begin_recovery_or_finish()

func _on_channel_tick() -> void:
	if state != ABILITY_RUNNER_STATE.CHANNELING:
		return
	_channel_tick_accum += current_ability.channel_tick_rate
	# Apply effect tick (ex: dps, slow, etc.)
	SignalManager.use_ability.emit(current_ability, _saved_target_pos, _saved_origin, owner_npc.targeting.current_ability_target_type, owner_npc)

	if _channel_tick_accum + 0.001 >= current_ability.max_channel_duration:
		_channel_timer.stop()
		_begin_recovery_or_finish()

func _begin_recovery_or_finish() -> void:
	if current_entry.recovery_time > 0.0:
		state = ABILITY_RUNNER_STATE.RECOVERY
		_recovery_timer.start(current_entry.recovery_time)
	else:
		_cleanup_and_finish(false)

func _on_recovery_timeout() -> void:
	_cleanup_and_finish(false)

func _cleanup_and_finish(interrupted: bool) -> void:
	# Restaure mouvement si locké
	if current_ability and current_entry.lock_movement_during_cast:
		owner_npc.locomotion.set_can_move(true)

	_clear_telegraph()
	_cast_timer.stop()
	_channel_timer.stop()
	_recovery_timer.stop()

	var finished_ability := current_ability
	current_entry = null
	current_ability = null
	state = ABILITY_RUNNER_STATE.IDLE

	if interrupted:
		emit_signal("ability_interrupted", finished_ability)
	else:
		emit_signal("ability_finished", finished_ability)

func _do_launch_effect() -> void:
	_clear_telegraph()

	match current_ability.kind:
		AbilityData.ABILITY_KIND.PROJECTILE, AbilityData.ABILITY_KIND.SELF, AbilityData.ABILITY_KIND.MOVEMENT:
			SignalManager.use_ability.emit(current_ability, _saved_dir, _saved_origin, owner_npc.targeting.current_ability_target_type, owner_npc)
		AbilityData.ABILITY_KIND.AOE:
			SignalManager.use_ability.emit(current_ability, _saved_target_pos, _saved_origin, owner_npc.targeting.current_ability_target_type, owner_npc)
		_:
			pass
