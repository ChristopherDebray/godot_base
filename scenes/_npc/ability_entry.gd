extends Resource
class_name AbilityEntry

enum ICD_ON {
	START,
	END
}

@export var ability: AbilityData
@export var weight: float = 1.0            # "indice" frequence of use
@export var min_range: float = 0.0
@export var max_range: float = 9999.0
@export var requires_los: bool = true
@export var cooldown_override: float = -1.0 # -1 => uses ability.cooldown

## wind-up (s)
@export var cast_time: float = 0.0
## wind-down (s)
@export var recovery_time: float = 0.0
@export var lock_movement_during_cast: bool = false
@export var interruptible: bool = true
@export var start_icd_on: ICD_ON = ICD_ON.END  # "start" ou "end"
@export var telegraph_fx: PackedScene      # optionnal: node VFX on ground
@export var animation_name: String = ""    # optionnal: anim to play during cast
