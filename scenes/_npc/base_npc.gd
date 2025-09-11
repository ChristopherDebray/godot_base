## Base class for all enemies in the game.
##
## Handles shared logic such as detection, navigation,
## attack cooldowns and basic state machine.
## Extend this class to create specific enemy types (Archer, Melee, Mage...).
class_name BaseNpc
extends Damageable

@onready var sprite_container: Node2D = $SpriteContainer
@onready var animated_sprite_2d: AnimatedSprite2D = $SpriteContainer/AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavAgent
@onready var ray_cast_2d: RayCast2D = $Detection/RayCast2D
@onready var field_view: Area2D = $SpriteContainer/FieldView
@onready var attack_timer: Timer = $AttackTimer
@onready var muzzle: Marker2D = $Muzzle
@onready var targeting: TargetingComponent = $Targeting
@onready var locomotion: LocomotionComponent = $Locomotion

## FOV rotation speed (deg/sec)
@export var turn_speed_deg: float = 3000.0

@export var attack_cooldown: float = 2.0
@export var initial_state: STATE = STATE.IDLE
@export var behavior: NpcBehavior
@export var roam_radius: float = 200.0
## A non zone locked enemy will not go back to its initial location after searching
@export var is_zone_locked: bool = true
@export var walk_anim_name := "default"
@export var idle_frame_index := 0

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

var _attack_target: Damageable = null
var _waypoints: Array = []
var _current_wp: int = 0

var _initial_facing_direction: Vector2

var _last_seen_pos: Vector2 = Vector2.ZERO

var roaming_target_position: Vector2
var roam_delay: float = 2.0
var _roam_timer: float = 0.0

var can_move: bool = true

func _ready() -> void:
	setup()
	locomotion.setup(self, nav_agent)
	targeting.setup(self, field_view, ray_cast_2d)
	call_deferred("late_setup")

func setup():
	set_physics_process(false)
	state = initial_state

	_initial_facing_direction = animated_sprite_2d.global_transform.x.normalized()

## Deferred setup for nodes that need a ready world (navigation, etc.)
func late_setup():
	locomotion._create_wp()
	await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout
	call_deferred("set_physics_process", true)

func _physics_process(delta: float) -> void:
	targeting._handle_targeting_poll(delta)
	targeting._handle_detection_and_state(delta)
	_update_action_by_state(delta)
	locomotion._update_navigation()
	_update_facing(delta)
	_update_sprite_facing()
	_update_sprite_anim()

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
		locomotion.set_nav_to_position(_attack_target.global_position)

func process_searching(delta: float) -> void:
	if not nav_agent.is_navigation_finished():
		return
	if initial_state == STATE.IDLE or initial_state == STATE.ROAMING:
		if not is_zone_locked:
			state = initial_state
			locomotion._initial_position = global_position
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
		pivot = locomotion._initial_position

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
	roaming_target_position = locomotion._initial_position + random_offset
	locomotion.set_nav_to_position(roaming_target_position)
	_roam_timer = roam_delay + randf_range(0.5, 1.5)

func process_patrolling() -> void:
	if nav_agent.is_navigation_finished():
		locomotion._navigate_wp()

func process_returning() -> void:
	locomotion.set_nav_to_position(locomotion._initial_position)
	if nav_agent.is_navigation_finished():
		state = initial_state

func process_dead() -> void:
	pass

# ----- Navigation / visuals -----

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
		_rotate_node_towards(field_view, locomotion._initial_position, delta)
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

func _pulse_red(duration: float = 2.0) -> void:
	var tw = create_tween()
	tw.set_loops(ceil(duration / 0.5))
	tw.tween_property(animated_sprite_2d, "modulate", Color(1,0.3,0.3), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(animated_sprite_2d, "modulate", Color(1,1,1), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
