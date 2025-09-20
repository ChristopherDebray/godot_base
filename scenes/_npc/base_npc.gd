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
@onready var muzzle: Marker2D = $Muzzle

@onready var targeting: TargetingComponent = $Targeting
@onready var locomotion: LocomotionComponent = $Locomotion

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

var can_move: bool = true

func _ready() -> void:
	ability_runner.setup(self)
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

	var entry := select_ability()
	if entry == null:
		return

	# snapshot origin/target/dir on cast
	var target_pos := Vector2.ZERO
	if _ability_target and is_instance_valid(_ability_target):
		target_pos = _ability_target.global_position
	var origin := muzzle.global_position
	var dir := origin.direction_to(target_pos)
	
	var started := ability_runner.start(entry, target_pos, origin, dir)
	if started:
		_apply_ability_cooldown()

func _cooldown_for(entry: AbilityEntry) -> float:
	if entry.cooldown_override > 0.0:
		return entry.cooldown_override
	return entry.ability.cooldown

func select_ability() -> AbilityEntry:
	if _ability_target == null or not is_instance_valid(_ability_target):
		return null

	var target_pos := _ability_target.global_position
	var dist := global_position.distance_to(target_pos)

	# 1) filter on ICD, range, LoS
	var ability_candidates: Array[AbilityEntry] = []
	for entry in ability_loadout.entries:
		if entry.ability == null:
			continue
		if not cooldowns.can_use(entry.ability):
			continue
		if dist < entry.min_range or dist > entry.max_range:
			continue
		if entry.requires_los and not targeting._has_line_of_sight(_ability_target):
			continue
		ability_candidates.append(entry)

	if ability_candidates.is_empty():
		return null

	# 2) weighting : base weight * context adjustement
	var weighted: Array = [] #qs [entry, cumulative]
	var total_weight := 0.0
	for entry in ability_candidates:
		var weight = max(0.001, entry.weight)
		# Bonus if in "perfect" / mid range
		var mid := (entry.min_range + entry.max_range) * 0.5
		var range_fit = 1.0 - min(1.0, abs(dist - mid) / max(1.0, entry.max_range - entry.min_range))
		weight += range_fit * 0.5

		# Penality if capacity was used recently (avoids spamming
		var remaining := cooldowns.remaining(entry.ability)
		if remaining == 0.0:
			# on peut utiliser le time-since-last-start si tu le stockes, sinon légère pénalité nulle
			pass

		total_weight += weight
		weighted.append({"entry": entry, "cum": total_weight})

	# 3) random weighting
	var roll := randf() * total_weight
	for item in weighted:
		if roll <= item["cum"]:
			return item["entry"]
	return weighted.back()["entry"]

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
