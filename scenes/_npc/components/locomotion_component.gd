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

func setup(owner: BaseNpc, nav_agent: NavigationAgent2D) -> void:
	npc = owner
	npc_nav_agent = nav_agent
	initial_position = global_position
	npc_nav_agent.velocity_computed.connect(_on_npc_nav_agent_velocity_computed)

func _update_navigation() -> void:
	if not can_move:
		npc.velocity = Vector2.ZERO
		npc_nav_agent.set_velocity(Vector2.ZERO)
		return

	var next_vel := Vector2.ZERO
	if npc.behavior and npc.state == npc.STATE.ATTACKING:
		next_vel = npc.behavior.compute_desired_velocity(npc, npc.get_physics_process_delta_time())
	else:
		var next_path_position: Vector2 = npc_nav_agent.get_next_path_position()
		if next_path_position == Vector2.ZERO:
			return
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

	# Set current target
	npc_nav_agent.target_position = _waypoints[_current_wp]

	# Prepare next index (called only when nav is finished)
	if _waypoints.size() == 1:
		return

	_current_wp += _wp_dir

	# Bounce on edges
	if _current_wp >= _waypoints.size():
		_wp_dir = -1
		_current_wp = _waypoints.size() - 2
	elif _current_wp < 0:
		_wp_dir = 1
		_current_wp = 1


func _on_npc_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	npc.velocity = safe_velocity
	npc.move_and_slide()
