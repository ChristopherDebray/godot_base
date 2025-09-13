extends Node

# TARGET_TYPE:
# - ENEMY: collide/target opposite faction
# - PLAYER: collide/target same faction (allies)
# - ALL:    collide/target both
enum TARGET_TYPE { ENEMY, PLAYER, ALL }

const COLLISION_MASKS = {
	'TILES': 1,
	'PLAYER': 3,
	'NPC': 4,
}

const COLLISION_MASKS_GROUPS = {
	TARGET_TYPE.ENEMY: [COLLISION_MASKS.TILES, COLLISION_MASKS.PLAYER],
	TARGET_TYPE.PLAYER: [COLLISION_MASKS.TILES, COLLISION_MASKS.NPC],
	TARGET_TYPE.ALL: [COLLISION_MASKS.TILES, COLLISION_MASKS.PLAYER, COLLISION_MASKS.NPC]
}

func _ready():
	SignalManager.use_ability.connect(_on_use_ability)

func _on_use_ability(data: AbilityData, target: Vector2, origin: Vector2, target_type: TARGET_TYPE, sender: Damageable = null):
	if data == null or data.scene == null:
		push_error("AbilityData invalid or missing scene: %s" % (data and data.id))
		return null
	
	var instance = data.scene.instantiate() as BaseAbility
	instance.sender = sender
	instance.configure_masks(COLLISION_MASKS_GROUPS[target_type])
	instance.initAbilityResource(data)
	
	var target_world := CastService._coerce_target_world(sender, target, instance.range)
	var ctx
	if is_instance_of(sender, Player):
		ctx = AimContext.from_mouse(sender, instance)
	else:
		ctx = AimContext.from_node(sender, instance, target_world)
	
	if is_instance_of(instance, ProjectileAbility):
		instance.init(data, ctx)
	elif is_instance_of(instance, AoeInstantAbility):
		ctx.los_clamped_point = CastService._compute_aoe_spawn_with_los(sender, ctx, instance._get_aoe_radius())
		instance.init(data, ctx)
	
	get_tree().current_scene.add_child(instance)
	
	return instance
