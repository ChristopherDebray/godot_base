extends Node

# TARGET_TYPE:
# - ENEMY: collide/target opposite faction
# - PLAYER: collide/target same faction (allies)
# - ALL:    collide/target both
enum TARGET_TYPE { ENEMY, PLAYER, ALL, SELF }

const ELEMENT_INDICATOR := preload("res://scenes/ui/components/element_indicator.tscn")
const ELEMENTS_ICONS := preload("res://assets/sprite_sheets/elements_icons.png")
const ELEMENT_ICONS_MAPPING := [
	0,
	1,
	2,
	3
]

var _element_icon_cache: Dictionary = {}
const ICON_CELL_SIZE: Vector2i = Vector2i(15, 16)
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
	if AbilityData.ABILITY_FACTION.ALL == data.faction or TARGET_TYPE.ALL == target_type:
		instance.configure_masks(COLLISION_MASKS_GROUPS[TARGET_TYPE.ALL])
	else:
		instance.configure_masks(COLLISION_MASKS_GROUPS[target_type])
	instance.init_ability_resource(data)
	
	var ctx
	if is_instance_of(sender, Player):
		sender = sender as Player
		ctx = AimContext.from_mouse(sender, instance)
	elif is_instance_of(sender, BaseNpc):
		sender = sender as BaseNpc
		var target_world = CastService._coerce_target_world(sender, target, instance.range)
		ctx = AimContext.from_npc(sender, instance, target_world)
	else:
		ctx = AimContext.from_context(instance, target, origin)

	if is_instance_of(instance, AoeInstantAbility):
		ctx.los_clamped_point = CastService._compute_aoe_spawn_with_los(sender, ctx, instance._get_aoe_radius())

	instance.init(data, ctx)

	if is_instance_of(instance, SelfAbility) or is_instance_of(instance, DashAbility):
		instance.start_from(origin, data.range)
		sender.add_child(instance)
	else:
		get_tree().current_scene.get_node("YsortLayer/Abilities").add_child(instance)

	instance.begin_cast_flow()

	if is_instance_of(instance, SelfAbility) and data.self_effect:
		sender.apply_effect(data.self_effect)

	return instance

func _get_element_icon_indicator(element_id: int) -> Control:
	var element_indicator = make_element_indicator(element_id)
	
	return element_indicator

func make_element_indicator(element_id: int) -> Control:
	var indicator := ELEMENT_INDICATOR.instantiate()
	indicator.icon_texture = get_icon(element_id)
	return indicator

func get_icon(element_id: int) -> Texture2D:
	if _element_icon_cache.has(element_id):
		return _element_icon_cache[element_id]
	var column = ELEMENT_ICONS_MAPPING[element_id]
	var at := AtlasTexture.new()
	at.atlas = ELEMENTS_ICONS
	at.region = Rect2(Vector2(column * ICON_CELL_SIZE.x, 0), ICON_CELL_SIZE)
	_element_icon_cache[element_id] = at
	return at
