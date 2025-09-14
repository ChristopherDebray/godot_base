extends Node2D
class_name TargetingComponent

# --- Auto-aggro on spawn ---
@export var auto_aggro_on_spawn: bool = true
@export var initial_aggro_group: String = "player"  # group name for initial target pick

# ---------- Targeting tuning ----------
@export var fov_poll_interval: float = 0.18         # FOV scan frequency (s)
@export var min_lock_time: float = 5.0              # Minimum time to keep current target (s)
@export var retarget_cooldown: float = 0.8          # Minimum delay between retargets (s)
@export var los_grace_time: float = 0.9             # LOS loss grace time before dropping target (s)
@export var switch_score_gain: float = 1.25         # New target must be >= 1.25x better (lower cost)
@export var max_candidates_considered: int = 8      # Max candidates per poll
@export var max_los_checks_per_poll: int = 3        # Max raycasts per poll

# Scoring weights (lower score == better)
@export var w_distance: float = 1.0
@export var w_angle: float = 0.5
@export var w_same_as_current_bonus: float = -0.4   # Fidelity bonus
@export var w_recent_attacker_bonus: float = -0.6   # Aggro bonus

var npc: BaseNpc
var npc_field_view: Area2D
var npc_ray_cast_2d: RayCast2D

var _candidates: Array[Damageable] = []
var _last_attacker: Damageable = null
var initial_attack_target_type: AbilityManager.TARGET_TYPE

var current_attack_target_type: AbilityManager.TARGET_TYPE
var current_detection_type: TargetManager.TARGET_TYPE

var _poll_accum: float = randf_range(0.0, 0.2)  # phase offset to spread load
var _lock_timer: float = 0.0
var _retarget_timer: float = 0.0
var _los_lost_timer: float = 0.0

func setup(owner: BaseNpc, field_view: Area2D, ray_cast_2d: RayCast2D) -> void:
	npc = owner
	npc_field_view = field_view
	npc_ray_cast_2d = ray_cast_2d
	
	set_initial_attack_target_type(AbilityManager.TARGET_TYPE.ENEMY)
	set_current_attack_target_type(AbilityManager.TARGET_TYPE.ENEMY)
	npc_field_view.body_entered.connect(_on_field_view_body_entered)
	npc_field_view.body_exited.connect(_on_field_view_body_exited)

	# If we want initial aggro on "enemy" group (same-faction),
	# we MUST flip the filter to 'PLAYER' (== allies in your enum).
	if initial_aggro_group == "enemy":
		set_current_attack_target_type(AbilityManager.TARGET_TYPE.PLAYER)
	elif initial_aggro_group == "player":
		set_current_attack_target_type(AbilityManager.TARGET_TYPE.ENEMY)

	TargetManager.set_detection_mask_for(npc.faction, current_attack_target_type, npc_field_view)
	# Optional: keep track of recent attackers for aggro bonus if you emit this signal
	if SignalManager.has_signal("damaged"):
		SignalManager.damaged.connect(func(victim: Damageable, attacker: Damageable):
			if victim == npc and attacker and attacker != npc:
				_last_attacker = attacker
		)

	# Cleanup when a candidate dies
	if SignalManager.has_signal("died"):
		SignalManager.died.connect(func(victim: Damageable):
			if victim == null: return
			_candidates.erase(victim)
			if victim == npc._attack_target:
				npc._attack_target = null
				npc.state = npc.STATE.SEARCHING
		)
	
	if auto_aggro_on_spawn:
		_try_auto_target_on_spawn()

func _physics_process(delta: float) -> void:
	_handle_targeting_poll(delta)
	_handle_detection_and_state(delta)

func _try_auto_target_on_spawn() -> void:
	# Pick first valid node in the configured group (e.g., "player")
	var candidate := get_tree().get_first_node_in_group(initial_aggro_group)
	if not candidate:
		return

	# We expect the player to be Damageable (so we can filter/fight)
	if candidate == null: 
		return
	if not is_instance_valid(candidate) or not candidate.is_alive:
		return
	if not _matches_target_filter(candidate):
		return

	# Optional: add to candidates so future polls see it immediately
	_candidates.append(candidate)

	# If LOS is clear, hard-set target; otherwise start searching toward last known pos
	if _has_line_of_sight(candidate):
		_set_target(candidate)
	else:
		npc._last_seen_pos = candidate.global_position
		npc.state = npc.STATE.SEARCHING

func _matches_target_filter(damageable: Damageable) -> bool:
	if not is_instance_valid(damageable): return false
	if not damageable.is_alive: return false
	if damageable == npc: return false

	match current_attack_target_type:
		AbilityManager.TARGET_TYPE.ENEMY:
			return damageable.faction != npc.faction
		AbilityManager.TARGET_TYPE.PLAYER: # “PLAYER” means same-faction (ally) in your enum
			return damageable.faction == npc.faction
		AbilityManager.TARGET_TYPE.ALL:
			return true
		_:
			return false

func _handle_targeting_poll(delta: float) -> void:
	_poll_accum += delta
	_lock_timer = max(0.0, _lock_timer - delta)
	_retarget_timer = max(0.0, _retarget_timer - delta)

	if _poll_accum >= fov_poll_interval:
		_poll_accum = 0.0
		_targeting_poll()

func _targeting_poll() -> void:
	# Purge invalid candidates
	_candidates = _candidates.filter(func(c):
		return is_instance_valid(c) and c.is_alive and _matches_target_filter(c)
	)
	if _candidates.is_empty():
		return

	# 1) Sort by distance and clamp count
	var sorted := _candidates.duplicate()
	sorted.sort_custom(func(a, b):
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	if sorted.size() > max_candidates_considered:
		sorted = sorted.slice(0, max_candidates_considered)

	# 2) Compute bounded score with limited LOS checks
	var best: Damageable = null
	var best_score := 1e9
	var los_checks := 0

	for c in sorted:
		var score := _score_candidate(c)
		if los_checks < max_los_checks_per_poll:
			if not _has_line_of_sight(c):
				score *= 2.5  # heavy penalty without LOS
			los_checks += 1
		if score < best_score:
			best_score = score
			best = c

	# Decide switch with lock, cooldown and hysteresis
	if best == null:
		return

	if npc._attack_target == null:
		_set_target(best)
		return

	if npc._attack_target == best:
		return

	if _lock_timer > 0.0 or _retarget_timer > 0.0:
		return

	var current_score := _score_candidate(npc._attack_target)
	if best_score <= current_score / switch_score_gain:
		_set_target(best)

func _score_candidate(candidate: Damageable) -> float:
	var d2 := global_position.distance_squared_to(candidate.global_position)
	var dir := (candidate.global_position - global_position).normalized()
	var forward := npc_field_view.global_transform.x.normalized()
	var ang_cost = 1.0 - clamp(forward.dot(dir), -1.0, 1.0) # 0=in front, ~2=behind

	var score = w_distance * d2 + w_angle * ang_cost
	if candidate == npc._attack_target:
		score += w_same_as_current_bonus
	if candidate == _last_attacker:
		score += w_recent_attacker_bonus
	return score

func _has_line_of_sight(to: Node2D) -> bool:
	if to == null: return false
	npc_ray_cast_2d.target_position = npc_ray_cast_2d.to_local(to.global_position)
	npc_ray_cast_2d.force_raycast_update()
	if not npc_ray_cast_2d.is_colliding():
		return false
	var collider := npc_ray_cast_2d.get_collider()
	return collider != null and collider == to

func set_current_attack_target_type(target_type: AbilityManager.TARGET_TYPE):
	current_attack_target_type = target_type
	TargetManager.set_detection_mask_for(npc.faction, current_attack_target_type, npc_field_view)

func set_initial_attack_target_type(target_type: AbilityManager.TARGET_TYPE):
	initial_attack_target_type = target_type

func set_current_detection_type(target_type: TargetManager.TARGET_TYPE, detection_field: Area2D):
	current_detection_type = target_type
	TargetManager.set_detection_mask_for(npc.faction, current_attack_target_type, detection_field)

func _set_target(target: Damageable) -> void:
	npc._attack_target = target
	_lock_timer = min_lock_time
	_retarget_timer = retarget_cooldown
	_los_lost_timer = 0.0
	npc._last_seen_pos = target.global_position
	npc.state = npc.STATE.ATTACKING

func _handle_detection_and_state(delta: float) -> void:
	if npc._attack_target and is_instance_valid(npc._attack_target) and npc._attack_target.is_alive:
		npc._last_seen_pos = npc._attack_target.global_position
		if _has_line_of_sight(npc._attack_target):
			_los_lost_timer = 0.0
		else:
			_los_lost_timer += delta
			if _los_lost_timer >= los_grace_time:
				npc._attack_target = null
				npc.state = npc.STATE.SEARCHING
	else:
		if npc.state == npc.STATE.ATTACKING:
			npc.state = npc.STATE.SEARCHING

func on_alert_from(source: Node) -> void:
	# Accept both Node2D and plain Node; prefer Damageable when available.
	if source is Damageable and is_instance_valid(source):
		var dmg := source as Damageable
		npc._last_seen_pos = dmg.global_position
		# If no current target and filter matches, try to lock immediately
		if npc._attack_target == null and _matches_target_filter(dmg):
			# Respect lock/cooldown heuristics implicitly through _set_target
			if _has_line_of_sight(dmg):
				_set_target(dmg)
			else:
				npc.state = npc.STATE.SEARCHING
	else:
		# Fallback: if we only have a position in mind, still go SEARCHING
		if source is Node2D and is_instance_valid(source):
			npc._last_seen_pos = (source as Node2D).global_position
			if npc.state != npc.STATE.ATTACKING:
				npc.state = npc.STATE.SEARCHING

func _force_retarget(immediate: bool = true) -> void:
	# Clear current target and timers so we are allowed to switch now
	npc._attack_target = null
	_los_lost_timer = 0.0
	if immediate:
		_lock_timer = 0.0        # break the 5s lock
		_retarget_timer = 0.0    # break hysteresis cooldown

	# Run one poll now to pick a new target with the new filter
	_targeting_poll()

	# If nothing picked (e.g., no LOS yet), go searching toward nearest valid candidate
	if npc._attack_target == null and _candidates.size() > 0:
		var best: Damageable = null
		var best_d2 := 1e12
		for c in _candidates:
			if not is_instance_valid(c) or not c.is_alive: 
				continue
			if not _matches_target_filter(c):
				continue
			var d2 := global_position.distance_squared_to(c.global_position)
			if d2 < best_d2:
				best_d2 = d2
				best = c
		if best != null:
			npc._last_seen_pos = best.global_position
			npc.state = npc.STATE.SEARCHING

func _on_field_view_body_entered(body: Node) -> void:
	if body != npc and body is Damageable and _matches_target_filter(body):
		_candidates.append(body)

func _on_field_view_body_exited(body: Node) -> void:
	if body is Damageable:
		_candidates.erase(body)

func charm(state: bool = true) -> void:
	# Switch targeting filter depending on initial aggro side
	npc._charm = state

	if state:
		# While charmed, invert who we consider as "valid targets"
		if initial_aggro_group == "player":
			set_current_attack_target_type(AbilityManager.TARGET_TYPE.PLAYER) # attack allies instead of player
		else:
			set_current_attack_target_type(AbilityManager.TARGET_TYPE.ENEMY)  # attack opponents instead of enemies

		# Break current lock and pick a new target now
		_force_retarget(true)
	else:
		# Restore the original intent when charm ends
		set_current_attack_target_type(initial_attack_target_type)
		_force_retarget(true)
