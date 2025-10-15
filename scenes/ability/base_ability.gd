extends Node2D

class_name BaseAbility

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var delay_timer: Timer = $DelayTimer
@onready var hitbox: Area2D = $Hitbox
@onready var area_of_effect: Area2D = $AreaOfEffect
@onready var area_of_effect_collision_shape: CollisionShape2D = $AreaOfEffect/CollisionShape2D
@onready var loop_particles: CPUParticles2D = $LoopParticles
@onready var impact_particles: CPUParticles2D = $ImpactParticles

@export var abilityName: String
@export var aoe_enabled: bool = true
@export var must_delay_ability: bool = false
@export var windup_time: float = 0
@export var duration: float = 2.0
@export var tags: Array[AbilityData.ABILITY_TAG] = []
@export var base_size: float = 1.0
@export var base_projectile_count: int = 1
@export var base_piercing: int = 0
@export var base_chain_count: int = 0
@export var base_damage: float = 10.0

# Canalisation (optionnal)
@export var is_channeled: bool = false
@export var channel_tick_rate: float = 0.5 # tick effect during channel
@export var max_channel_duration: float = 3.0

var damage: float
var aoe_damage: float
var effect: EffectData
var range: float = 30.0
var target_type: AbilityManager.TARGET_TYPE
var aoe_triggered := 0

var sender: Node
var _has_hit: bool = false
var ability_resource: AbilityData
var _pending_masks: Array

var _origin: Vector2 = Vector2.ZERO
var _max_range_sq: float = 0.0

# Stats finales après modifiers
var final_damage: float
var final_size: float
var final_projectile_count: int
var final_piercing: int
var final_chain_count: int

# Piercing/Chain tracking
var _piercing_hits_left: int = 0
var _chain_bounces_left: int = 0
var _hit_targets: Array[Node] = []

func init(data: AbilityData, ctx: AimContext) -> void:
	# Appliquer les modifiers si le sender a un RelicInventory
	if sender and sender.has_node("RelicInventory"):
		var inventory: RelicInventory = sender.get_node("RelicInventory")
		var weather = GameManager.weather_system.current_weather if GameManager.weather_system else ""
		var stats = inventory.get_modifiers_for_ability(data, weather)
		_apply_modifier_stats(stats)
	else:
		# Pas de reliques = utiliser les valeurs de base
		final_damage = base_damage
		final_size = base_size
		final_projectile_count = base_projectile_count
		final_piercing = base_piercing
		final_chain_count = base_chain_count
	
	# Initialiser les compteurs
	_piercing_hits_left = final_piercing
	_chain_bounces_left = final_chain_count
	
	# Appliquer la taille
	scale = Vector2.ONE * final_size

func _apply_modifier_stats(stats: ModifierStats) -> void:
	final_damage = stats.apply_to_damage(base_damage)
	final_size = stats.apply_to_size(base_size)
	final_projectile_count = base_projectile_count + stats.get_bonus_projectiles()
	final_piercing = base_piercing + stats.get_bonus_piercing()
	final_chain_count = base_chain_count + stats.get_bonus_chains()

func configure_masks(masks: Array) -> void:
	_pending_masks = masks

func _ready():
	if _pending_masks:
		set_hitboxes_targets(_pending_masks)

func init_ability_resource(ability_data: AbilityData) -> void:
	ability_resource = ability_data
	damage = ability_data.damage
	aoe_damage = ability_data.aoe_damage
	effect = ability_data.effect
	range = ability_data.range

func _on_hitbox_body_entered(body):
	if body != sender:
		on_ability_hit(body)

func on_ability_hit(body):
	if body in _hit_targets:
		return
	
	if body is Damageable:
		apply_damage_and_effect(body, final_damage)

		# Notify enemies in a generic way (no player ref needed)
		if body is BaseNpc:
			var enemy := body as BaseNpc
			# Prefer the true instigator; fallback to this ability node
			var instigator: Node
			if (sender != null):
				instigator = sender
			else:
				instigator = self
			enemy.targeting.on_alert_from(instigator)

	if _piercing_hits_left > 0:
		_piercing_hits_left -= 1
		on_pierce_hit(body)
		return
	
	# No more pierce = check chain
	if _chain_bounces_left > 0:
		_try_chain_to_next_target(body)
	else:
		# Nothing = destroy
		_has_hit = true
		on_last_hit(body)
	
	if (not tags.has(AbilityData.ABILITY_TAG.PIERCE)):
		_has_hit = true
		on_hit()
		return
	
	if (is_instance_of(body, TileMapLayer)):
		_has_hit = true
		on_hit()
		return

## @abstract ovveride for visuals or other effects
func on_pierce_hit(body: Node) -> void:
	pass

## Called on last hit (no more piercing / chain)
func on_last_hit(body: Node) -> void:
	on_hit()

func _try_chain_to_next_target(from_body: Node) -> void:
	"""Trouve la prochaine cible pour chain"""
	var nearest_target: Node = null
	var nearest_dist := INF
	var search_radius := 300.0  # À ajuster
	
	# Chercher dans les bodies à portée
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = search_radius
	query.shape = circle
	query.transform = Transform2D(0, from_body.global_position)
	query.collision_mask = hitbox.collision_mask
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var target = result.collider
		if target in _hit_targets or target == from_body:
			continue
		if not (target is Damageable):
			continue
		
		var dist = global_position.distance_to(target.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_target = target
	
	if nearest_target:
		_chain_bounces_left -= 1
		_chain_to_target(nearest_target)
	else:
		# Pas de cible = fin
		on_last_hit(from_body)

func _chain_to_target(target: Node) -> void:
	"""Redirige le projectile vers la nouvelle cible"""
	# Pour un projectile : changer la direction
	if self is ProjectileAbility:
		var projectile := self as ProjectileAbility  # ← Cast explicite
		var dir = (target.global_position - global_position).normalized()
		projectile._dir_of_travel = dir
		# Effet visuel de chain
		_spawn_chain_effect(target.global_position)
	
	elif self is AoeInstantAbility:
		var new_ability = duplicate()
		new_ability.global_position = target.global_position
		new_ability._chain_bounces_left = _chain_bounces_left
		new_ability._hit_targets = _hit_targets.duplicate()
		get_parent().add_child(new_ability)
		queue_free()

## @abstract visual effect of chain, implement with Line2D + particules
func _spawn_chain_effect(target_pos: Vector2) -> void:
	pass

func _on_area_of_effect_body_entered(body: Node2D) -> void:
	on_aoe_hit()

func on_aoe_hit():
	if aoe_triggered > 0:
		return
	for receiver in area_of_effect.get_overlapping_bodies():
		if receiver is Damageable:
			apply_damage_and_effect(receiver, aoe_damage)
			if receiver is BaseNpc:
				var enemy := receiver as BaseNpc
				var instigator: Node
				if (sender != null):
					instigator = sender
				else:
					instigator = self
				enemy.targeting.on_alert_from(instigator)
	aoe_triggered = aoe_triggered + 1

func activate_aoe():
	area_of_effect.monitoring = true

func is_aoe_activated() -> bool:
	return area_of_effect.monitoring

func apply_damage_and_effect(target: Damageable, damageValue):
	var has_been_hit = target.apply_elemental_damage(ability_resource, damageValue)
	if sender and has_been_hit:
		target.knock_back_particules(sender.global_position)

	if !effect:
		return
	target.apply_effect(effect)

func set_hitboxes_targets(collision_masks: Array):
	reset_collision_masks(hitbox)
	reset_collision_masks(area_of_effect)
	
	for n in collision_masks:
		hitbox.set_collision_mask_value(n, true)
		area_of_effect.set_collision_mask_value(n, true)

func reset_collision_masks(area2d: Area2D):
	for n in range(1, 32):
		area2d.set_collision_mask_value(n, false)

func start_from(origin: Vector2, max_range: float) -> void:
	global_position = origin
	_origin = origin
	_max_range_sq = max_range * max_range

func has_exceeded_range(current_pos: Vector2) -> bool:
	return (current_pos - _origin).length_squared() >= _max_range_sq

func begin_cast_flow() -> void:
	if must_delay_ability and windup_time > 0.0:
		on_windup_start()
		delay_timer.start(windup_time)
	else:
		_start_impact_phase()

func _start_impact_phase() -> void:
	on_impact_start()
	if duration > 0.0:
		lifetime_timer.start(duration)
	else:
		on_ability_timeout()

func apply_modifiers(stats: ModifierStats) -> Dictionary:
	return {
		"damage": stats.apply_to_damage(base_damage),
		"size": stats.apply_to_size(base_size),
		"projectile_count": base_projectile_count + stats.get_bonus_projectiles(),
		"piercing": base_piercing + stats.get_bonus_piercing(),
		"chain_count": base_chain_count + stats.get_bonus_chains(),
	}

## @abstract
func on_hit():
	pass

func _on_lifetime_timer_timeout():
	# Call the supercharged in the children
	on_ability_timeout()

## @abstract: by default just delete the element but could be used for effect on duration over
func on_ability_timeout():
	queue_free()

func _on_delay_timer_timeout() -> void:
	_start_impact_phase()

## @abstract
func on_windup_start() -> void:
	pass

## @abstract
func on_impact_start() -> void:
	pass
