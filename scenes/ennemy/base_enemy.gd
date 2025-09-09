## Base class for all enemies in the game.
##
## Handles shared logic such as detection, navigation,
## attack cooldowns and basic state machine.
## Extend this class to create specific enemy types (Archer, Melee, Mage...).
class_name BaseEnemy
extends Damageable

@onready var sprite_container: Node2D = $SpriteContainer
@onready var animated_sprite_2d: AnimatedSprite2D = $SpriteContainer/AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavAgent
@onready var ray_cast_2d: RayCast2D = $Detection/RayCast2D
@onready var field_view: Area2D = $SpriteContainer/FieldView
@onready var attack_timer: Timer = $AttackTimer
@onready var muzzle: Marker2D = $Muzzle

## FOV rotation speed (deg/sec)
@export var turn_speed_deg: float = 3000.0

@export var attack_cooldown: float = 2.0
@export var patrol_points: NodePath
@export var initial_state: STATE = STATE.IDLE
@export var behavior: EnemyBehavior
@export var roam_radius: float = 200.0
## A non zone locked enemy will not go back to its initial location after searching
@export var is_zone_locked: bool = true
@export var walk_anim_name := "default"
@export var idle_frame_index := 0

# ---------- Targeting tuning ----------
@export var fov_poll_interval: float = 0.18         # FOV scan frequency (s)
@export var min_lock_time: float = 5.0              # Minimum time to keep current target (s)
@export var retarget_cooldown: float = 0.8          # Minimum delay between retargets (s)
@export var los_grace_time: float = 0.9             # LOS loss grace time before dropping target (s)
@export var switch_score_gain: float = 1.25         # New target must be >= 1.25x better (lower cost)
@export var max_candidates_considered: int = 8       # Max candidates per poll
@export var max_los_checks_per_poll: int = 3         # Max raycasts per poll

# --- Auto-aggro on spawn ---
@export var auto_aggro_on_spawn: bool = true
@export var initial_aggro_group: String = "player"  # group name for initial target pick

# Scoring weights (lower score == better)
@export var w_distance: float = 1.0
@export var w_angle: float = 0.5
@export var w_same_as_current_bonus: float = -0.4   # Fidelity bonus
@export var w_recent_attacker_bonus: float = -0.6   # Aggro bonus

var _candidates: Array[Damageable] = []
var _attack_target: Damageable = null
var _last_attacker: Damageable = null

var _poll_accum: float = randf_range(0.0, 0.2)  # phase offset to spread load
var _lock_timer: float = 0.0
var _retarget_timer: float = 0.0
var _los_lost_timer: float = 0.0
# ---------- End targeting ----------

enum STATE {
	IDLE,
	RETURNING,
	ROAMING,
	PATROLLING,
	ATTACKING,
	SEARCHING,
	FLEEING,
	DEAD
}

var next_attack_timer: float
var state: STATE

var _waypoints: Array = []
var _current_wp: int = 0

var _initial_facing_direction: Vector2
var _initial_position: Vector2

var _last_seen_pos: Vector2 = Vector2.ZERO

var roaming_target_position: Vector2
var roam_delay: float = 2.0
var _roam_timer: float = 0.0

var can_move: bool = true

func _ready() -> void:
	setup()
	call_deferred("late_setup")

func setup():
	set_physics_process(false)
	state = initial_state

	_initial_facing_direction = animated_sprite_2d.global_transform.x.normalized()
	_initial_position = global_position
	_create_wp()

	# Default: enemies hunt opponents
	set_initial_attack_target_type(AbilityManager.TARGET_TYPE.ENEMY)
	set_current_attack_target_type(AbilityManager.TARGET_TYPE.ENEMY)

	# If we want initial aggro on "enemy" group (same-faction),
	# we MUST flip the filter to 'PLAYER' (== allies in your enum).
	if initial_aggro_group == "enemy":
		set_current_attack_target_type(AbilityManager.TARGET_TYPE.PLAYER)

	TargetManager.set_detection_mask_for(faction, current_attack_target_type, field_view)

	# Optional: keep track of recent attackers for aggro bonus if you emit this signal
	if SignalManager.has_signal("damaged"):
		SignalManager.damaged.connect(func(victim: Damageable, attacker: Damageable):
			if victim == self and attacker and attacker != self:
				_last_attacker = attacker
		)

	# Cleanup when a candidate dies
	if SignalManager.has_signal("died"):
		SignalManager.died.connect(func(victim: Damageable):
			if victim == null: return
			_candidates.erase(victim)
			if victim == _attack_target:
				_attack_target = null
				state = STATE.SEARCHING
		)
	
	if auto_aggro_on_spawn:
		_try_auto_target_on_spawn()

## Deferred setup for nodes that need a ready world (navigation, etc.)
func late_setup():
	await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout
	call_deferred("set_physics_process", true)

func _physics_process(delta: float) -> void:
	_handle_targeting_poll(delta)
	_handle_detection_and_state(delta)
	_update_action_by_state(delta)
	_update_navigation()
	_update_facing(delta)
	_update_sprite_facing()
	_update_sprite_anim()

func set_current_attack_target_type(target_type: AbilityManager.TARGET_TYPE):
	current_attack_target_type = target_type
	TargetManager.set_detection_mask_for(faction, current_attack_target_type, field_view)

# ---------- Targeting core ----------

func _try_auto_target_on_spawn() -> void:
	# Pick first valid node in the configured group (e.g., "player")
	var nodes := get_tree().get_nodes_in_group(initial_aggro_group)
	if nodes.is_empty():
		return

	# We expect the player to be Damageable (so we can filter/fight)
	var cand := nodes[0] as Damageable
	if cand == null: 
		return
	if not is_instance_valid(cand) or not cand.is_alive:
		return
	if not _matches_target_filter(cand):
		return

	# Optional: add to candidates so future polls see it immediately
	_candidates.append(cand)

	# If LOS is clear, hard-set target; otherwise start searching toward last known pos
	if _has_line_of_sight(cand):
		_set_target(cand)
	else:
		_last_seen_pos = cand.global_position
		state = STATE.SEARCHING

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

	if _attack_target == null:
		_set_target(best)
		return

	if _attack_target == best:
		return

	if _lock_timer > 0.0 or _retarget_timer > 0.0:
		return

	var current_score := _score_candidate(_attack_target)
	if best_score <= current_score / switch_score_gain:
		_set_target(best)

func _matches_target_filter(dmg: Damageable) -> bool:
	if not is_instance_valid(dmg): return false
	if not dmg.is_alive: return false
	if dmg == self: return false

	match current_attack_target_type:
		AbilityManager.TARGET_TYPE.ENEMY:
			return dmg.faction != self.faction
		AbilityManager.TARGET_TYPE.PLAYER: # “PLAYER” means same-faction (ally) in your enum
			return dmg.faction == self.faction
		AbilityManager.TARGET_TYPE.ALL:
			return true
		_:
			return false

func _score_candidate(c: Damageable) -> float:
	var d2 := global_position.distance_squared_to(c.global_position)
	var dir := (c.global_position - global_position).normalized()
	var forward := field_view.global_transform.x.normalized()
	var ang_cost = 1.0 - clamp(forward.dot(dir), -1.0, 1.0) # 0=in front, ~2=behind

	var score = w_distance * d2 + w_angle * ang_cost
	if c == _attack_target:
		score += w_same_as_current_bonus
	if c == _last_attacker:
		score += w_recent_attacker_bonus
	return score

func _has_line_of_sight(to: Node2D) -> bool:
	if to == null: return false
	ray_cast_2d.target_position = ray_cast_2d.to_local(to.global_position)
	ray_cast_2d.force_raycast_update()
	if not ray_cast_2d.is_colliding():
		return false
	var collider := ray_cast_2d.get_collider()
	return collider != null and collider == to

func _set_target(t: Damageable) -> void:
	_attack_target = t
	_lock_timer = min_lock_time
	_retarget_timer = retarget_cooldown
	_los_lost_timer = 0.0
	_last_seen_pos = t.global_position
	state = STATE.ATTACKING

func _handle_detection_and_state(delta: float) -> void:
	if _attack_target and is_instance_valid(_attack_target) and _attack_target.is_alive:
		_last_seen_pos = _attack_target.global_position
		if _has_line_of_sight(_attack_target):
			_los_lost_timer = 0.0
		else:
			_los_lost_timer += delta
			if _los_lost_timer >= los_grace_time:
				_attack_target = null
				state = STATE.SEARCHING
	else:
		if state == STATE.ATTACKING:
			state = STATE.SEARCHING

func _on_field_view_body_entered(body: Node) -> void:
	if body != self and body is Damageable and _matches_target_filter(body):
		_candidates.append(body)

func _on_field_view_body_exited(body: Node) -> void:
	if body is Damageable:
		_candidates.erase(body)
# ---------- End targeting core ----------

func _update_action_by_state(delta: float) -> void:
	match state:
		STATE.IDLE:
			process_idle()
		STATE.RETURNING:
			process_returning()
		STATE.ROAMING:
			process_roaming(delta)
		STATE.PATROLLING:
			process_patrolling()
		STATE.SEARCHING:
			process_searching(delta)
		STATE.ATTACKING:
			process_attacking(delta)
			if behavior == null or behavior.try_attack(self, delta):
				perform_attack(delta)
		STATE.FLEEING:
			process_fleeing(delta)
		STATE.DEAD:
			process_dead()

# ----- Hooks to be overridden by child classes -----

func process_idle() -> void:
	pass

func process_attacking(delta: float) -> void:
	if _attack_target and is_instance_valid(_attack_target):
		set_nav_to_position(_attack_target.global_position)

func process_searching(delta: float) -> void:
	if not nav_agent.is_navigation_finished():
		return
	if initial_state == STATE.IDLE or initial_state == STATE.ROAMING:
		if not is_zone_locked:
			state = initial_state
			_initial_position = global_position
			return
		state = STATE.RETURNING
		return
	state = STATE.PATROLLING

func perform_attack(delta: float) -> void:
	if not _can_attack():
		return
	var did_attack := _do_attack(delta)
	if did_attack:
		_apply_attack_cooldown()

func _can_attack() -> bool:
	return attack_timer.is_stopped()

func _apply_attack_cooldown() -> void:
	set_next_attack_timer()
	attack_timer.start(next_attack_timer)

func _do_attack(delta: float) -> bool:
	return false

func set_next_attack_timer():
	next_attack_timer = attack_cooldown + randf_range(-0.3, 0.3)

func process_fleeing(delta: float) -> void:
	var pivot
	if (_attack_target and is_instance_valid(_attack_target)):
		pivot = _attack_target.global_position
	else:
		pivot = _initial_position

	var away = (global_position - pivot).normalized()
	var random_offset = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)).normalized()
	var flee_direction = (away + random_offset).normalized()
	nav_agent.target_position = global_position + flee_direction * 200

func process_roaming(delta: float) -> void:
	if not nav_agent.is_navigation_finished():
		return
	_roam_timer -= delta
	if _roam_timer > 0.0:
		return
	var random_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(50.0, roam_radius)
	roaming_target_position = _initial_position + random_offset
	set_nav_to_position(roaming_target_position)
	_roam_timer = roam_delay + randf_range(0.5, 1.5)

func process_patrolling() -> void:
	if nav_agent.is_navigation_finished():
		_navigate_wp()

func process_returning() -> void:
	nav_agent.target_position = _initial_position
	if nav_agent.is_navigation_finished():
		state = initial_state

func process_dead() -> void:
	pass

# ----- Navigation / visuals -----

func _update_navigation() -> void:
	if not can_move:
		velocity = Vector2.ZERO
		nav_agent.set_velocity(Vector2.ZERO)
		return

	var next_vel := Vector2.ZERO
	if behavior and state == STATE.ATTACKING:
		next_vel = behavior.compute_desired_velocity(self, get_physics_process_delta_time())
	else:
		var next_path_position: Vector2 = nav_agent.get_next_path_position()
		if next_path_position == Vector2.ZERO:
			return
		next_vel = global_position.direction_to(next_path_position) * speed

	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(next_vel)
	else:
		velocity = next_vel
		move_and_slide()

func set_nav_to_position(nav_position: Vector2) -> void:
	nav_agent.target_position = nav_position

func _create_wp() -> void:
	if state != STATE.PATROLLING:
		return
	for wp in get_node(patrol_points).get_children():
		_waypoints.append(wp.global_position)

func _navigate_wp() -> void:
	if _current_wp >= _waypoints.size():
		_current_wp = 0
	nav_agent.target_position = _waypoints[_current_wp]
	_current_wp += 1

func _rotate_node_towards(node: Node2D, target: Vector2, delta: float) -> void:
	if node == null:
		return
	var desired := (target - node.global_position).angle()
	var current := node.global_rotation
	var turn := turn_speed_deg * delta / 180.0
	turn = clamp(turn, 0.0, 1.0)
	node.global_rotation = lerp_angle(current, desired, turn)

func _update_facing(delta: float) -> void:
	# 1) Combat: face current target
	if state == STATE.ATTACKING and _attack_target and is_instance_valid(_attack_target):
		_rotate_node_towards(field_view, _attack_target.global_position, delta)
		return
	# 2) Searching: face last seen position
	if state == STATE.SEARCHING:
		_rotate_node_towards(field_view, _last_seen_pos, delta)
		return
	# 3) Returning: face home
	if state == STATE.RETURNING:
		_rotate_node_towards(field_view, _initial_position, delta)
		return
	# 4) Patrolling: face waypoint
	if state == STATE.PATROLLING and _waypoints.size() > 0:
		var target = _waypoints[max(0, _current_wp - 1)]
		_rotate_node_towards(field_view, target, delta)
		return
	# 5) Roaming: face roaming target
	if state == STATE.ROAMING:
		_rotate_node_towards(field_view, roaming_target_position, delta)
		return
	# 6) Idle: keep initial rotation
	if state == STATE.IDLE:
		_rotate_node_towards(field_view, global_position + _initial_facing_direction, delta)

func _update_sprite_facing() -> void:
	if velocity.x < -0.05:
		animated_sprite_2d.flip_h = true
	elif velocity.x > 0.05:
		animated_sprite_2d.flip_h = false

func _update_sprite_anim() -> void:
	var moving := velocity.length_squared() > 1.0
	if moving:
		if animated_sprite_2d.animation != walk_anim_name or not animated_sprite_2d.is_playing():
			animated_sprite_2d.play(walk_anim_name)
	else:
		if animated_sprite_2d.is_playing():
			animated_sprite_2d.stop()
		animated_sprite_2d.frame = idle_frame_index

func on_alert_from(source: Node) -> void:
	# Accept both Node2D and plain Node; prefer Damageable when available.
	if source is Damageable and is_instance_valid(source):
		var dmg := source as Damageable
		_last_seen_pos = dmg.global_position
		# If no current target and filter matches, try to lock immediately
		if _attack_target == null and _matches_target_filter(dmg):
			# Respect lock/cooldown heuristics implicitly through _set_target
			if _has_line_of_sight(dmg):
				_set_target(dmg)
			else:
				state = STATE.SEARCHING
	else:
		# Fallback: if we only have a position in mind, still go SEARCHING
		if source is Node2D and is_instance_valid(source):
			_last_seen_pos = (source as Node2D).global_position
			if state != STATE.ATTACKING:
				state = STATE.SEARCHING

func _pulse_red(duration: float = 2.0) -> void:
	var tw = create_tween()
	tw.set_loops(ceil(duration / 0.5))
	tw.tween_property(animated_sprite_2d, "modulate", Color(1,0.3,0.3), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(animated_sprite_2d, "modulate", Color(1,1,1), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func charm(state: bool = true) -> void:
	# Switch targeting filter depending on initial aggro side
	_charm = state

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

func _force_retarget(immediate: bool = true) -> void:
	# Clear current target and timers so we are allowed to switch now
	_attack_target = null
	_los_lost_timer = 0.0
	if immediate:
		_lock_timer = 0.0        # break the 5s lock
		_retarget_timer = 0.0    # break hysteresis cooldown

	# Run one poll now to pick a new target with the new filter
	_targeting_poll()

	# If nothing picked (e.g., no LOS yet), go searching toward nearest valid candidate
	if _attack_target == null and _candidates.size() > 0:
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
			_last_seen_pos = best.global_position
			state = STATE.SEARCHING
