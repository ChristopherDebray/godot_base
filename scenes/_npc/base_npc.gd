## Base class for all npc in the game.
##
## Handles shared logic such as detection, navigation,
## abilities cooldowns and basic state machine.
## Extend this class to create specific npc.
class_name BaseNpc
extends Damageable

@onready var sprite_container: Node2D = $SpriteContainer
@onready var animated_sprite_2d: AnimatedSprite2D = $SpriteContainer/AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavAgent
@onready var ray_cast_2d: RayCast2D = $Detection/RayCast2D
@onready var field_view: Area2D = $SpriteContainer/FieldView
@onready var ability_timer: Timer = $AbilityTimer
@onready var muzzle: Node2D = $Muzzle

@onready var targeting: TargetingComponent = $TargetingComponent
@onready var locomotion: LocomotionComponent = $LocomotionComponent
@onready var movement_particles: CPUParticles2D = $MovementParticles

@onready var ability_picker: AbilityPicker = $AbilityPickerComponent
@onready var ability_runner: AbilityRunner = $AbilityRunnerComponent
@onready var cooldowns: CooldownBank = $CooldownBankComponent

## FOV rotation speed (deg/sec)
@export var turn_speed_deg: float = 3000.0

@export var ability_cooldown: float = 2.0
@export var initial_state: STATE = STATE.IDLE
## Behavior is used to indicate the way the npc will act in battle, archerBehavior, etc
@export var behavior: NpcBehavior
@export var roam_radius: float = 200.0
## A non zone locked enemy will not go back to its initial location after searching
@export var is_zone_locked: bool = true
@export var walk_anim_name := "default"
@export var idle_frame_index := 0
@export var ability_loadout: AbilityLoadout
@export var use_global_cooldown: bool = true
@onready var collision_polygon_2d: CollisionPolygon2D = $SpriteContainer/FieldView/CollisionPolygon2D

var facing_follow_speed: float = 8.0   # how fast the sprite reacts (higher = snappier)
var facing_deadzone: float = 0.2       # hysteresis around 0 to avoid jitter
var facing_flip_cooldown: float = 0.35

var _facing_smoothed: float = 1.0              # smoothed signed direction in [-1, 1]
var _last_flip_time: float = -10.0             # last time we flipped
var _last_facing_sign: int = 1

var _hit_tween: Tween = null

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

var next_ability_timer: float
var state: STATE
var _ability_target: Damageable = null
var _initial_facing_direction: Vector2
var _last_seen_pos: Vector2 = Vector2.ZERO

var roaming_target_position: Vector2
var roam_delay: float = 2.0
var _roam_timer: float = 0.0

func _ready() -> void:
	ability_runner.setup(self)
	setup()
	locomotion.setup(self, nav_agent)
	targeting.setup(self, field_view, ray_cast_2d)
	
	_last_facing_sign = 1
	if animated_sprite_2d.flip_h:
		_last_facing_sign = -1
	_facing_smoothed = float(_last_facing_sign)
	
	# Picker setup (pass NPC RNG if you already created one)
	var npc_rng := RandomNumberGenerator.new()
	npc_rng.seed = int(get_instance_id()) % 2147483647
	ability_picker.setup(self, targeting, cooldowns, npc_rng)
	
	call_deferred("late_setup")
	
	if animated_sprite_2d.material is ShaderMaterial:
		var mat := (animated_sprite_2d.material as ShaderMaterial)
		if !mat.resource_local_to_scene:
			mat = mat.duplicate() # deep copy is OK ici
			mat.resource_local_to_scene = true
			animated_sprite_2d.material = mat
	else:
		push_error("AnimatedSprite2D must have a ShaderMaterial assigned.")

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
	ability_picker.rebuild_if_needed()
	_update_action_by_state(delta)
	locomotion._update_navigation()
	_update_sprite_facing(delta)
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
			if behavior == null or behavior.try_ability(self, delta):
				perform_ability(delta)
		STATE.FLEEING:
			process_fleeing(delta)
		STATE.DEAD:
			process_dead()

# ----- Hooks to be overridden by child classes -----

func process_idle() -> void:
	pass

func process_attacking(delta: float) -> void:
	if _ability_target and is_instance_valid(_ability_target):
		locomotion.set_nav_to_position(_ability_target.global_position)

func process_searching(delta: float) -> void:
	if not nav_agent.is_navigation_finished():
		return
	if initial_state == STATE.IDLE or initial_state == STATE.ROAMING:
		## A non zone locked npc will be able to roam or idle freely where he stands
		if not is_zone_locked:
			state = initial_state
			locomotion.initial_position = global_position
			return
		state = STATE.RETURNING
		return
	state = STATE.PATROLLING

func perform_ability(delta: float) -> void:
	if not _can_use_abilities():
		return

	var entry := ability_picker.pick_entry()
	if entry == null:
		return

	# snapshot origin/target/dir on cast
	var target_pos := Vector2.ZERO
	if _ability_target and is_instance_valid(_ability_target):
		target_pos = _ability_target.global_position
	var origin := muzzle.global_position
	var self_positioned_ability_kind = [AbilityData.ABILITY_KIND.SELF, AbilityData.ABILITY_KIND.MOVEMENT]
	var dir := origin.direction_to(target_pos)
	if self_positioned_ability_kind.has(entry.ability.kind):
		origin = animated_sprite_2d.global_position
	
	var started := ability_runner.start(entry, target_pos, origin, dir)
	if started:
		_apply_ability_cooldown()

func _cooldown_for(entry: AbilityEntry) -> float:
	if entry.cooldown_override > 0.0:
		return entry.cooldown_override
	return entry.ability.cooldown

func _can_use_abilities() -> bool:
	if not ability_timer.is_stopped():
		return false
	if ability_runner.is_busy():
		return false
	return true

func _apply_ability_cooldown() -> void:
	set_next_ability_timer()
	ability_timer.start(next_ability_timer)

## @abstract
func _do_ability(delta: float) -> bool:
	return false

func set_next_ability_timer():
	next_ability_timer = ability_cooldown + randf_range(-0.3, 0.3)

func process_fleeing(delta: float) -> void:
	var pivot
	if (_ability_target and is_instance_valid(_ability_target)):
		pivot = _ability_target.global_position
	else:
		pivot = locomotion.initial_position

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
	roaming_target_position = locomotion.initial_position + random_offset
	locomotion.set_nav_to_position(roaming_target_position)
	_roam_timer = roam_delay + randf_range(0.5, 1.5)

func process_patrolling() -> void:
	if nav_agent.is_navigation_finished():
		locomotion._navigate_wp()

func process_returning() -> void:
	locomotion.set_nav_to_position(locomotion.initial_position)
	if nav_agent.is_navigation_finished():
		state = initial_state

func process_dead() -> void:
	pass

func _compute_desired_facing() -> float:
	# Priority 1: target (combat intent)
	if _ability_target != null and is_instance_valid(_ability_target):
		var dx = _ability_target.global_position.x - global_position.x
		if abs(dx) > 1.0:
			if dx > 0.0:
				return 1.0
			else:
				return -1.0

	# Priority 2: movement (non-combat)
	# Use navigation/physics velocity but ignore tiny jitter
	if abs(velocity.x) > 8.0:
		if velocity.x > 0.0:
			return 1.0
		else:
			return -1.0

	# No strong hint → keep current smoothed direction
	return _facing_smoothed

func _update_sprite_facing(delta: float) -> void:
	var desired = _compute_desired_facing()
	
	# Exponential smoothing toward desired (clamped slope)
	var torward = clamp(delta * facing_follow_speed, 0.0, 1.0)
	_facing_smoothed = lerp(_facing_smoothed, desired, torward)
	var sign_now: int = _last_facing_sign
	
	if _facing_smoothed > facing_deadzone:
		sign_now = 1
		movement_particles.position.x = -(collision_polygon_2d.scale.x) * abs(global_scale.x)
		movement_particles.rotation = -90
	elif _facing_smoothed < -facing_deadzone:
		sign_now = -1
		movement_particles.position.x = (collision_polygon_2d.scale.x) * abs(global_scale.x)
		movement_particles.rotation = 90
	else:
		# inside deadzone → keep previous sign
		sign_now = _last_facing_sign

	# Flip cooldown: avoid left-right-left in a few frames during strafes
	var time_now = Time.get_ticks_msec() / 1000.0
	var can_flip = (time_now - _last_flip_time) >= facing_flip_cooldown

	if sign_now != _last_facing_sign and can_flip:
		animated_sprite_2d.flip_h = (sign_now == -1)
		_last_facing_sign = sign_now
		_last_flip_time = time_now

func _update_sprite_anim() -> void:
	var moving := velocity.length_squared() > 1.0
	if moving:
		if animated_sprite_2d.animation != walk_anim_name or not animated_sprite_2d.is_playing():
			animated_sprite_2d.play(walk_anim_name)
			movement_particles.emitting = true
	else:
		if animated_sprite_2d.is_playing():
			animated_sprite_2d.stop()
			movement_particles.emitting = false
		animated_sprite_2d.frame = idle_frame_index

func _pulse_red(duration: float = 2.0) -> void:
	var tw = create_tween()
	tw.set_loops(ceil(duration / 0.5))
	tw.tween_property(animated_sprite_2d, "modulate", Color(1,0.3,0.3), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(animated_sprite_2d, "modulate", Color(1,1,1), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func locomotion_freeze(state: bool = true):
	locomotion.set_can_move(state)
	animated_sprite_2d.pause()

func on_hit():
	animated_sprite_2d.material.set_shader_parameter('mix_amount', 1)
	
	var tween := create_tween()
	tween.tween_property(
		animated_sprite_2d.material, 
		"shader_parameter/mix_amount", 
		0.0,
		0.25 # duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func pulse_tint(tint: Color = Color(1,0,0), up_time: float = 0.08, down_time: float = 0.18) -> void:
	var mat := animated_sprite_2d.material as ShaderMaterial
	if mat == null:
		return
	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill()

	mat.set_shader_parameter("tint_color", tint)
	mat.set_shader_parameter("mix_amount", 0.0)

	_hit_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hit_tween.tween_property(mat, "shader_parameter/mix_amount", 1.0, up_time)
	_hit_tween.tween_property(mat, "shader_parameter/mix_amount", 0.0, down_time)
	_hit_tween.tween_callback(func():
		mat.set_shader_parameter("tint_color", Color(1,1,1,1)) # optional reset
	)
