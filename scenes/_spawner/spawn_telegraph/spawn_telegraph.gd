extends Node2D

@onready var telegraph_spawn: Sprite2D = $TelegraphSpawn

func _ready() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_loops(3)
	tw.tween_property(telegraph_spawn, "modulate:a", 0.4, 0.2)
	tw.tween_property(telegraph_spawn, "modulate:a", 1.0, 0.2)
