extends Node

# TARGET_TYPE:
# - ENEMY: collide/target opposite faction
# - PLAYER: collide/target same faction (allies)
# - ALL:    collide/target both
enum TARGET_TYPE { ENEMY, PLAYER, ALL, SELF }

const COLLISION_MASKS = {
	'TILES': 1,
	'PLAYER': 3,
	'NPC': 4,
	'HOLES': 8,
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
		push_error("AbilityData invalid or missing scene: %s" % (data))
		return null
	
	var instance = data.scene.instantiate() as BaseAbility
	instance.sender = sender
	instance.target_type = target_type
	instance.configure_masks(COLLISION_MASKS_GROUPS[target_type])
	instance.init_ability_resource(data)
	
	var ctx
	if is_instance_of(sender, Player):
		sender = sender as Player
		ctx = AimContext.from_mouse(sender, instance)
	else:
		var npc := sender as BaseNpc
		var target_world = CastService._coerce_target_world(sender, target, instance.range)
		ctx = AimContext.from_node(npc, instance, target_world)
		if is_instance_of(instance, DashAbility):
			var dir := target
			if dir.length() < 0.001:
				dir = Vector2.RIGHT
				if npc.animated_sprite_2d.flip_h:
					dir = Vector2.LEFT
			ctx = AimContext.new()
			ctx.desired_dir = dir.normalized()

	instance.init(data, ctx)

	if is_instance_of(instance, SelfAbility):
		sender.add_child(instance)
	elif is_instance_of(instance, DashAbility):
		sender.add_child(instance)
	else:
		get_tree().current_scene.get_node("YsortLayer/Abilities").add_child(instance)

	instance.start_from(origin, data.range)
	instance.begin_cast_flow()

	if is_instance_of(instance, SelfAbility) and data.self_effect:
		sender.apply_effect(data.self_effect)

	return instance
