extends Node2D

@onready var wave_spawner: WaveSpawner = $WaveSpawner
@onready var player: Player = $YsortLayer/Players/Player

func _ready() -> void:
	wave_spawner.spawn_wave()
