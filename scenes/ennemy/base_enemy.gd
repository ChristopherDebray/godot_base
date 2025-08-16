## Base class for all enemies in the game.
##
## Handles shared logic such as detection, navigation,
## attack cooldowns and basic state machine.
## Extend this class to create specific enemy types (Archer, Melee, Mage...).
class_name BaseEnemy extends Damageable

@onready var sprite_container: Node2D = $SpriteContainer
@onready var animated_sprite_2d: AnimatedSprite2D = $SpriteContainer/AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavAgent
@onready var ray_cast_2d: RayCast2D = $Detection/RayCast2D
@onready var field_view: Area2D = $SpriteContainer/FieldView
@onready var attack_timer: Timer = $AttackTimer

@export var turn_speed_deg: float = 660.0 # FOV rotation speed (deg/sec)

@export var attack_cooldown: float = 2.0
@export var patrol_points: NodePath
@export var initial_state: STATE = STATE.IDLE
@export var behavior: EnemyBehavior
@export var roam_radius: float = 200.0

enum STATE {
	IDLE,
	## When enemy as search for the player but didn't found him, returns to his original point
	RETURNING,
	## Roam freely where it stands
	ROAMING,
	PATROLLING,
	ATTACKING,
	SEARCHING,
	FLEEING,
	DEAD
}

## This timer will be based on provided attack cooldown and will vary dynamicly for a more organic attack pattern
var next_attack_timer: float
var state: STATE

var _waypoints: Array = []
var _current_wp: int = 0

var _player_ref: Player

var _initial_facing_direction: Vector2
var _initial_position: Vector2

var _player_in_fov: bool = false
var _last_seen_pos: Vector2 = Vector2.ZERO

var roaming_target_position: Vector2
var roam_delay: float = 2.0
var _roam_timer: float = 0.0

func _ready() -> void:
	setup()
	call_deferred("late_setup")

func setup():
	set_physics_process(false)
	state = initial_state
	_player_ref = get_tree().get_first_node_in_group("player")
	_initial_facing_direction = animated_sprite_2d.global_transform.x.normalized()
	_initial_position = global_position
	_create_wp()

## A deffered setup for elements that need to be loaded before it
func late_setup():
	# This part is mandatory or else the physics_process movements occur before waypoints creations
	await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout
	call_deferred("set_physics_process", true)

func _physics_process(delta: float) -> void:
	_refresh_fov_poll()
	_handle_player_detection()
	_update_action_by_state(delta)
	_update_navigation()
	_update_facing(delta)  

## Set the state and next position based on player _last_seen_pos and if the player is detected or not
func _handle_player_detection():
	if not _player_in_fov:
		if state == STATE.ATTACKING:
			state = STATE.SEARCHING
			set_nav_to_position(_last_seen_pos)
		return
	
	if not _check_raycast_to_player():
		if state == STATE.ATTACKING:
			state = STATE.SEARCHING
			set_nav_to_position(_last_seen_pos)
		return
	
	_last_seen_pos = _player_ref.global_position
	if state == STATE.IDLE or state == STATE.RETURNING or state == STATE.ROAMING or state == STATE.PATROLLING or state == STATE.SEARCHING:
		state = STATE.ATTACKING

## Checks if user is in pov / field_view with overlaps_body, body_entered with area isn't enough
func _refresh_fov_poll() -> void:
	_player_in_fov = field_view.overlaps_body(_player_ref)

## Set the raycast to point to the player and check if there is no obstacle between
## It is only used when player is on fov to avoid too many recalculation
func _check_raycast_to_player() -> bool:
	ray_cast_2d.target_position = ray_cast_2d.to_local(_player_ref.global_position)
	ray_cast_2d.force_raycast_update()
	if not ray_cast_2d.is_colliding():
		return false
	
	var collider = ray_cast_2d.get_collider()
	if collider == null:
		return false
	if not collider.is_in_group("player"):
		return false

	return true

func _update_action_by_state(delta: float):
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

## @abstract
func process_idle() -> void:
	pass

## @abstract
func process_attacking(delta: float):
	set_nav_to_position(_player_ref.global_position)

## @abstract
func process_searching(delta: float):
	if not nav_agent.is_navigation_finished():
		return

	if initial_state == STATE.IDLE:
		state = STATE.RETURNING
		return

	state = STATE.PATROLLING

func perform_attack(delta: float) -> void:
	if not _can_attack():
		return
	## Hook: child does it's action here
	## The animation should be done before or when this function is called to avoid cooldown before animation ends
	var did_attack := _do_attack(delta)

	if did_attack:
		_apply_attack_cooldown()

func _can_attack() -> bool:
	return attack_timer.is_stopped()

func _apply_attack_cooldown() -> void:
	set_next_attack_timer()
	attack_timer.start(next_attack_timer)

## @abstract: To override by the child (return true if attack was launched)
func _do_attack(delta: float) -> bool:
	return false

func set_next_attack_timer():
	next_attack_timer = attack_cooldown + randf_range(-0.3, 0.3)

## @abstract
func process_fleeing(delta):
	var away = (global_position - _player_ref.global_position).normalized()
	var random_offset = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)).normalized()
	var flee_direction = (away + random_offset).normalized()

	nav_agent.target_position = global_position + flee_direction * 200

## @abstract
func process_roaming(delta: float) -> void:
	if not nav_agent.is_navigation_finished():
		return
	
	# cooldown before new destination
	_roam_timer -= delta
	if _roam_timer > 0.0:
		return
	
	# choose a random point around position
	var random_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(50.0, roam_radius)
	roaming_target_position = _initial_position + random_offset
	
	set_nav_to_position(roaming_target_position)
	_roam_timer = roam_delay + randf_range(0.5, 1.5) # variation for organic effectd

## @abstract
func process_patrolling() -> void:
	if nav_agent.is_navigation_finished() == true:
		_navigate_wp()

## @abstract
func process_returning() -> void:
	nav_agent.target_position = _initial_position
	if nav_agent.is_navigation_finished() == true:
		state = STATE.IDLE

## @abstract
func process_dead() -> void:
	pass

func _update_navigation() -> void:
	var next_vel := Vector2.ZERO
	if behavior and state == STATE.ATTACKING:
		# si possible, ton behavior devrait fournir un point-cible à mettre dans nav_agent.target_position
		# mais on garde ta version pour l’instant
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

## Set the nav_agent target to the next waypoint and goes reset to 0 if "parcour" is done
func _navigate_wp() -> void:
	if _current_wp >= len(_waypoints):
		_current_wp = 0
	nav_agent.target_position = _waypoints[_current_wp]
	_current_wp += 1

func _rotate_node_towards(node: Node2D, target: Vector2, delta: float) -> void:
	if node == null:
		return
	var desired := (target - node.global_position).angle()
	var current := node.global_rotation
	var turn := turn_speed_deg * delta / 180.0
	if turn > 1.0:
		turn = 1.0
	elif turn < 0.0:
		turn = 0.0
	node.global_rotation = lerp_angle(current, desired, turn)

func _update_facing(delta: float) -> void:
	# 1. Combat, turns to player
	if state == STATE.ATTACKING and _player_in_fov and _check_raycast_to_player():
		_rotate_node_towards(self, _player_ref.global_position, delta)
		return
	
	# 2. Search turns to last_seen_pos
	if state == STATE.SEARCHING:
		_rotate_node_towards(self, _last_seen_pos, delta)
		return
	
	if state == STATE.RETURNING:
		_rotate_node_towards(self, _initial_position, delta)
		return

	# 3. Patrol rotates toward the next point
	if state == STATE.PATROLLING and _waypoints.size() > 0:
		var target = _waypoints[_current_wp - 1] if _current_wp > 0 else _waypoints[0]
		_rotate_node_towards(self, target, delta)
		return
	
	if state == STATE.ROAMING:
		_rotate_node_towards(self, roaming_target_position, delta)
		return
	
	# 4. Idle / return → keep initial rotation
	if state == STATE.IDLE:
		_rotate_node_towards(self, global_position + _initial_facing_direction, delta)


func _on_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
