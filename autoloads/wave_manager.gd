extends Node

## Budget is "spend" to spawn enemies
var budget_base: float = 10
var wave_index: int
var rng_seed: String

signal on_wave_completed()

func _ready() -> void:
	on_wave_completed.connect(_on_wave_completed)

func _on_wave_completed():
	budget_base += 10
