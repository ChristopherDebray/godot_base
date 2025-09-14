extends Node2D
class_name LocomotionComponent

@export var patrol_points: NodePath

var npc: BaseNpc
var _waypoints: Array = []
var _current_wp: int = 0

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
	if npc.state != npc.STATE.PATROLLING:
		return
	for wp in npc.get_node(patrol_points).get_children():
		_waypoints.append(wp.global_position)

func _navigate_wp() -> void:
	if _current_wp >= _waypoints.size():
		_current_wp = 0
	npc_nav_agent.target_position = _waypoints[_current_wp]
	_current_wp += 1

func _on_npc_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	npc.velocity = safe_velocity
	npc.move_and_slide()
