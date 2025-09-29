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
	if _forced_active:
		_tick_forced_move(npc.get_physics_process_delta_time())
		return
	if not can_move:
		return

	var next_vel := Vector2.ZERO
	var delta_time := npc.get_physics_process_delta_time()

	if npc.behavior and npc.state == npc.STATE.ATTACKING:
		# 1) goal with behavior
		var goal := npc.behavior.compute_target(npc)
		npc_nav_agent.target_position = goal

		# 2) pathfinding
		if npc_nav_agent.is_navigation_finished():
			# near goal = no path_vel or low
			var path_vel := Vector2.ZERO
			var steer := npc.behavior.steering(npc, delta_time, path_vel)
			next_vel = (path_vel + steer).limit_length(npc.speed)
		else:
			var next_path_position := npc_nav_agent.get_next_path_position()
			var path_vel := npc.global_position.direction_to(next_path_position) * npc.speed
			var steer := npc.behavior.steering(npc, delta_time, path_vel)
			next_vel = (path_vel + steer).limit_length(npc.speed)
	else:
		# Not in fight = nav agent only
		if npc_nav_agent.is_navigation_finished():
			return
		var next_path_position: Vector2 = npc_nav_agent.get_next_path_position()
		next_vel = npc.global_position.direction_to(next_path_position) * npc.speed

	if npc_nav_agent.avoidance_enabled:
		npc_nav_agent.set_velocity(next_vel)
	else:
		npc.velocity = next_vel
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
