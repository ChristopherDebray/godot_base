extends CharacterBody2D

class_name Damageable

enum FACTION { PLAYER, ENEMY, NEUTRAL }

@export var faction: FACTION = FACTION.ENEMY
@export var health: float = 10.0
@export var defense: float = 10.0
@export var speed: float = 90.0
@export var immunity_effects: Array[EffectsManager.EFFECTS] = []
@export var immunity_elements: Array[SpellsManager.ELEMENTS] = []
@export var resistence_elements: Array[SpellsManager.ELEMENTS] = []

@onready var status_fx: AnimatedSprite2D = $StatusFx
@onready var ray_cast_ability: RayCast2D = $RayCastAbility

var current_target: Damageable

var active_effects: Array[Dictionary] = []
var is_alive := true

func _process(delta: float) -> void:
	var still_active: Array[Dictionary] = []
	
	for entry in active_effects:
		var effect: EffectData = entry["effect"]
		var rate := effect.tick_rate

		entry["remaining_time"] -= delta
		var remaining = entry["remaining_time"]

		## if rate is 0 or less, only one tick (for buff or debuff) which is done on apply effect
		if rate > 0.0:
			entry["accum"] = entry.get("accum", 0.0) + delta
			while entry["accum"] >= rate and remaining > 0.0:
				entry["accum"] -= rate
				effect.apply_tick(self)
		
		if remaining <= 0.0:
			_unapply_effect(entry)
		else:
			still_active.append(entry)

	active_effects = active_effects.filter(func(effect): return effect["remaining_time"] > 0)
	update_fx_visual()

func _do_tick(entry: Dictionary) -> void:
	var effect: EffectData = entry["effect"]
	var res: Dictionary = effect.apply_tick(self)

	# Memorise what is reversible
	if res.has("applied"):
		entry["applied_mods"] = entry.get("applied_mods", {})
		for k in res["applied"].keys():
			entry["applied_mods"][k] = entry["applied_mods"].get(k, 0.0) + res["applied"][k]

func _unapply_effect(entry: Dictionary) -> void:
	# Cancel stat effects
	if entry.has("applied_mods"):
		for k in entry["applied_mods"].keys():
			var v: float = entry["applied_mods"][k]
			match k:
				"speed":
					modify_speed(-v)
				"defense":
					modify_defense(-v)
				_:
					pass

	# Cancel control effects
	if entry.has("applied_mods"):
		if entry["applied_mods"].has("freeze"):
			freeze(false)
		if entry["applied_mods"].has("root"):
			root(false)
		if entry["applied_mods"].has("charm"):
			charm(false)

func apply_elemental_damage(spellResource: AbilityData, amount: float) -> void:
	if spellResource.main_element in immunity_elements:
		return
	
	apply_damage(amount)

func apply_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		on_death()
	if is_instance_of(self, Player):
		GameManager.modify_current_health(-amount)
		SignalManager.resource_value_change.emit(amount, GameManager.RESOURCE_TYPE.LIFE)

func apply_effect(effect: EffectData) -> void:
	if not effect or effect.name_enum in immunity_effects:
		return
	
	# Reset duration if same effect already exists
	for entry in active_effects:
		if entry["effect"].name == effect.name:
			entry["remaining_time"] = effect.duration
			entry["accum"] = 0.0
			entry.erase("applied_mods")
			if effect.tick_rate <= 0.0:
				_do_tick(entry)
			return
	
	var new_entry := {
		"effect": effect,
		"remaining_time": effect.duration,
		"accum": 0.0
	}
	active_effects.append(new_entry)
	
	if effect.tick_rate <= 0.0:
		_do_tick(new_entry)

# Can be supercharged
func on_death():
	is_alive = false
	SignalManager.died.emit(self)
	queue_free()

func update_fx_visual():
	if active_effects.is_empty():
		status_fx.stop()
		status_fx.visible = false
		return

	for entry in active_effects:
		var effect = entry["effect"]
		if !effect.fx_sprite_frames:
			return

		if status_fx.sprite_frames == effect.fx_sprite_frames and status_fx.visible:
			return

		status_fx.sprite_frames = effect.fx_sprite_frames
		status_fx.play("default")
		status_fx.visible = true
		return

	status_fx.stop()
	status_fx.visible = false

func freeze(state: bool = true) -> void:
	set_physics_process(!state)
	locomotion_freeze(!state)

func root(state: bool = true) -> void:
	locomotion_freeze(!state)

func charm(state: bool = true) -> void:
	pass

func locomotion_freeze(state: bool = true):
	pass

func modify_speed(amount: float):
	speed += amount
	print("Speed modified by ", amount, " -> new speed: ", speed)

func modify_defense(amount: float):
	defense += amount
	print("Defense modified by ", amount, " -> new defense: ", defense)

func raycast_ability_to(to_position: Vector2):
	ray_cast_ability.target_position = ray_cast_ability.to_local(to_position)
	ray_cast_ability.force_raycast_update()

func on_hit():
	pass
