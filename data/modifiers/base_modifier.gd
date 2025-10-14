extends Resource
class_name BaseModifier

enum ModifierType {
	DAMAGE_MULTIPLIER,      # Multiplie les dégâts
	DAMAGE_FLAT,            # Ajoute des dégâts fixes
	SIZE_MULTIPLIER,        # Augmente la taille (AOE)
	PROJECTILE_COUNT,       # Ajoute des projectiles
	PIERCING,               # Ajoute du piercing
	CHAIN_COUNT,            # Ajoute des rebonds/chains
	COOLDOWN_MULTIPLIER,    # Réduit le cooldown
	SPEED_MULTIPLIER,       # Vitesse du projectile
	DURATION_MULTIPLIER,    # Durée des effets
	CAST_TIME_MULTIPLIER,   # Temps de cast
}

@export var type: ModifierType
@export var value: float = 1.0
@export var tags_required: Array[String] = []  # ["wind", "projectile", "aoe"]
@export var weather_condition: String = ""     # "rain", "storm", etc.
@export var is_multiplicative: bool = true     # true = * value, false = + value

func applies_to(ability_tags: Array[String], current_weather: String = "") -> bool:
	# Vérifier les tags
	if tags_required.size() > 0:
		for tag in tags_required:
			if tag not in ability_tags:
				return false
	
	# Vérifier la météo
	if weather_condition != "" and weather_condition != current_weather:
		return false
	
	return true

func get_final_value(rarity_multiplier: float = 1.0) -> float:
	return value * rarity_multiplier
