extends Node2D

@onready var wave_spawner: WaveSpawner = $WaveSpawner
@onready var player: Player = $YsortLayer/Players/Player
@onready var weather_controller_component: WeatherController = $WeatherControllerComponent
@onready var relic_selection_ui: Control = $CanvasLayer/RelicSelectionUi
@onready var timer: Timer = $Timer

func _ready() -> void:
	wave_spawner.spawn_wave()
	weather_controller_component.setup(player.camera_player)
	WaveManager.on_wave_completed.connect(_on_wave_completed)

func _on_wave_completed():
	MenuManager.push(relic_selection_ui)
	relic_selection_ui.roll_relics()
	relic_selection_ui.show()
	#timer.start()
		#get_tree().paused = true
	#)
