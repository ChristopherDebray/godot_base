extends Node2D
class_name LocomotionComponent

@export var patrol_points: NodePath

var npc: BaseNpc
var _waypoints: Array = []
var _current_wp: int = 0
var _wp_dir: int = 1 # 1 = forward, -1 = backward

var roaming_target_position: Vector2
var roam_delay: float = 2.0
var roam_timer: float = 0.0

var can_move: bool = true
var npc_nav_agent: NavigationAgent2D

var initial_position: Vector2

var _forced_active := false
var _forced_dir := Vector2.ZERO
var _forced_remaining := 0.0
var _forced_speed := 0.0
var _forced_stop_on_collision := true
var _forced_body: CharacterBody2D = null

func setup(owner: BaseNpc, nav_agent: NavigationAgent2D) -> void:
	npc = owner
	npc_nav_agent = nav_agent
	initial_position = global_position
	npc_nav_agent.velocity_computed.connect(_on_npc_nav_agent_velocity_computed)

func set_can_move(state: bool):
	if (false == state):
		npc.velocity = Vector2.ZERO
		npc_nav_agent.set_velocity(Vector2.ZERO)
	can_move = state
	
func _update_navigation() -> void:
	# Forced motion (dash, knockback, etc.)
	if _forced_active:
		_tick_forced_move(npc.get_physics_process_delta_time())
		return

	# Movement lock
	if not can_move:
		return

	var next_velocity := Vector2.ZERO
	var delta_time := npc.get_physics_process_delta_time()

	if npc.behavior and npc.state == npc.STATE.ATTACKING:
		# 1) Ask behavior for a navigation goal.
		#    For Skirmisher: this returns an anchor on the ring (not the raw target).
		var navigation_goal := npc.behavior.compute_target(npc)
		npc_nav_agent.target_position = navigation_goal

		# 2) Compute path velocity, but disable it if we are already inside the ring band.
		var path_velocity := Vector2.ZERO
		var distance_to_target := INF
		var has_valid_target := false

		if npc._ability_target and is_instance_valid(npc._ability_target):
			distance_to_target = npc.global_position.distance_to(npc._ability_target.global_position)
			has_valid_target = true

		var is_in_band := false
		if has_valid_target:
			is_in_band = (distance_to_target >= npc.behavior.stop_range) and (distance_to_target <= npc.behavior.preferred_range)

		if npc_nav_agent.is_navigation_finished() or is_in_band:
			# near goal OR already within desired band → no path driving
			path_velocity = Vector2.ZERO
		else:
			var next_path_position := npc_nav_agent.get_next_path_position()
			var direction_to_next := npc.global_position.direction_to(next_path_position)
			path_velocity = direction_to_next * npc.speed

		# 3) Local steering from behavior (strafe, back-off)
		var steering_velocity := npc.behavior.steering(npc, delta_time, path_velocity)

		# 4) Compose and clamp once
		next_velocity = (path_velocity + steering_velocity).limit_length(npc.speed)

	else:
		# Not in combat: pure path to current nav target
		if npc_nav_agent.is_navigation_finished():
			return

		var next_path_position_non_combat := npc_nav_agent.get_next_path_position()
		var direction_to_next_non_combat := npc.global_position.direction_to(next_path_position_non_combat)
		next_velocity = (direction_to_next_non_combat * npc.speed)

	# Apply velocity via NavigationAgent2D when avoidddddddddddddddddddance is on, otherwise directly
	if npc_nav_agent.avoidance_enabled:
		npc_nav_agent.set_velocity(next_velocity)
	else:
		npc.velocity = next_velocity
		npc.move_and_slide()

func set_nav_to_position(nav_position: Vector2) -> void:
	npc_nav_agent.target_position = nav_position

func _create_wp() -> void:
	_waypoints.clear()

	if patrol_points.is_empty():
		return

	var points_parent := get_node_or_null(patrol_points)
	if points_parent == null:
		push_error("LocomotionComponent: 'patrol_points' does not resolve to a valid node.")
		return

	for child in points_parent.get_children():
		if child is Node2D:
			_waypoints.append(child.global_position)

	_current_wp = 0
	_wp_dir = 1

func _navigate_wp() -> void:
	if _waypoints.is_empty():
		return

	npc_nav_agent.target_position = _waypoints[_current_wp]

	if _waypoints.size() == 1:
		return

	_current_wp += _wp_dir

	if _current_wp >= _waypoints.size():
		_wp_dir = -1
		_current_wp = _waypoints.size() - 2
	elif _current_wp < 0:
		_wp_dir = 1
		_current_wp = 1

func begin_forced_move(body: CharacterBody2D, dir: Vector2, speed: float, distance: float, stop_on_collision: bool = true) -> void:
	_forced_active = true
	_forced_body = body
	_forced_dir = dir.normalized()
	_forced_speed = max(0.0, speed)
	_forced_remaining = max(0.0, distance)
	_forced_stop_on_collision = stop_on_collision

	set_can_move(false)
	if npc:
		npc.velocity = Vector2.ZERO
	if _forced_body:
		_forced_body.velocity = Vector2.ZERO

func interrupt_forced_move() -> void:
	if not _forced_active:
		return
	_forced_active = false
	_forced_body = null
	set_can_move(true)
	SignalManager.forced_motion_finished.emit(true)

func _tick_forced_move(delta: float) -> void:
	if not _forced_active:
		return
	if _forced_remaining <= 0.0:
		_forced_active = false
		_forced_body = null
		set_can_move(true)
		SignalManager.forced_motion_finished.emit(true)
		return

	var step = min(_forced_remaining, _forced_speed * delta)
	var motion = _forced_dir * step
	var collided := false

	if _forced_body and is_instance_valid(_forced_body):
		var col := _forced_body.move_and_collide(motion)
		if col:
			collided = true
	else:
		npc.global_position += motion

	_forced_remaining -= step
	if collided and _forced_stop_on_collision:
		_forced_active = false
		_forced_body = null
		set_can_move(true)
		SignalManager.forced_motion_finished.emit(true)

func _on_npc_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	npc.velocity = safe_velocity
	npc.move_and_slide()
