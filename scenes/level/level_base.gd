extends Node2D

@onready var wave_spawner: WaveSpawner = $WaveSpawner
@onready var player: Player = $YsortLayer/Players/Player
#@onready var weather: BaseWeather = $Weather

func _ready() -> void:
	#rain_weather.setup_for_camera(player.camera_player)
	wave_spawner.spawn_wave()
