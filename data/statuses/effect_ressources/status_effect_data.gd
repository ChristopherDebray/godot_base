extends Resource
class_name StatusEffectData

@export var name: String
@export var stat: String           # ex: "speed", "life", "defense"
@export var value_type: String     # "flat", "percent"
@export var value: float
@export var duration: float
@export var damage_over_time: float
@export var effect_timer: float    # every 2 sec you take the effect
@export var overlay_color: Color
