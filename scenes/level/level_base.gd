extends Node2D

@onready var wave_spawner: WaveSpawner = $WaveSpawner
@onready var player: Player = $YsortLayer/Players/Player
@onready var weather_controller_component: WeatherController = $WeatherControllerComponent

func _ready() -> void:
	wave_spawner.spawn_wave()
	weather_controller_component.setup(player.camera_player)
