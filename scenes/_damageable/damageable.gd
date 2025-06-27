extends Node2D

class_name Damageable

@export var health: float = 10.0
@export var defense: float = 10.0
@export var speed: float = 10.0
@export var immunity_effects: Array[EffectsManager.EFFECTS] = []
@export var immunity_elements: Array[SpellsManager.ELEMENTS] = []
@export var resistence_elements: Array[SpellsManager.ELEMENTS] = []

var active_effects: Array[Dictionary] = []

func _process(delta: float) -> void:
	for entry in active_effects:
		entry["remaining_time"] -= delta
		entry["last_tick"] += delta
		if entry["last_tick"] >= entry["effect"].tick_rate:
			entry["effect"].apply_tick(self)
			entry["last_tick"] = 0.0
	
	active_effects = active_effects.filter(func(effect): return effect["remaining_time"] > 0)

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
	print(effect.name)
	for entry in active_effects:
		if entry["effect"].name == effect.name:
			entry["remaining_time"] = effect.duration
			return
	
	active_effects.append({
		"effect": effect,
		"remaining_time": effect.duration,
		"last_tick": 0.0
	})

# Can be supercharged
func on_death():
	queue_free()

func modify_speed(amount: float):
	speed += amount
	print("Speed modified by ", amount, " -> new speed: ", speed)

func modify_defense(amount: float):
	defense += amount
	print("Defense modified by ", amount, " -> new defense: ", defense)
