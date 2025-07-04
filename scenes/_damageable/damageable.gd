extends Node2D

class_name Damageable

@export var health: float = 10.0
@export var defense: float = 10.0
@export var speed: float = 10.0
@export var immunity_effects: Array[EffectsManager.EFFECTS] = []
@export var immunity_elements: Array[SpellsManager.ELEMENTS] = []
@export var resistence_elements: Array[SpellsManager.ELEMENTS] = []

@onready var status_fx: AnimatedSprite2D = $StatusFx

var active_effects: Array[Dictionary] = []
var to_remove_effects: Array[Dictionary] = []

func _process(delta: float) -> void:
	for entry in active_effects:
		entry["remaining_time"] -= delta
		entry["last_tick"] += delta
		if entry["is_one_shot"] && entry["has_ticked"]: continue
		
		if entry["last_tick"] >= entry["effect"].tick_rate:
			entry["has_ticked"] = true
			entry["effect"].apply_tick(self)
			entry["last_tick"] = 0.0

	to_remove_effects = active_effects.filter(func(effect): return effect["remaining_time"] <= 0)
	active_effects = active_effects.filter(func(effect): return effect["remaining_time"] > 0)
	remove_ended_effects()
	update_fx_visual()

func remove_ended_effects() -> void:
	for entry in to_remove_effects:
		entry["effect"].remove_effect(self)
	to_remove_effects.clear()

func apply_elemental_damage(spellResource: SpellData, amount: float) -> void:
	if spellResource.main_element in immunity_elements:
		print("Immune to damage of type", spellResource.name)
		return
	
	apply_damage(amount)

func apply_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		on_death()

func apply_effect(effect: EffectData) -> void:
	if effect.name_enum in immunity_effects:
		print("Immune to effect", effect.name)
		return
	
	# Reset duration if same effect already exists
	for entry in active_effects:
		if entry["effect"].name == effect.name:
			entry["remaining_time"] = effect.duration
			return
	
	active_effects.append({
		"effect": effect,
		"remaining_time": effect.duration,
		"last_tick": 0.0,
		"has_ticked": false,
		"is_one_shot": effect.is_one_shot,
	})

# Can be supercharged
func on_death():
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

func freeze():
	pass

func unfreeze():
	pass

func modify_speed(amount: float):
	speed += amount
	print("Speed modified by ", amount, " -> new speed: ", speed)

func modify_defense(amount: float):
	defense += amount
	print("Defense modified by ", amount, " -> new defense: ", defense)
