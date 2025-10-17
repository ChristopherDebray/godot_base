extends Node

enum RESOURCE_TYPE { LIFE }
enum CONTROLS_TYPE { XBOX, PLAYSATION, KEYBOARD }

var current_health: float
var max_health: float
var player: Player
var camera_shake_noise: FastNoiseLite
var used_controls := CONTROLS_TYPE.KEYBOARD
var current_weather_type: EnvironmentManager.WEATHER_TYPE

func _ready() -> void:
	camera_shake_noise = FastNoiseLite.new()
	RelicManager.on_add_relic.connect(_on_add_relic)
	set_used_controls()

func _on_add_relic(relic: BaseRelic):
	get_tree().paused = false
	load_level('level_farm_two')

func modify_current_health(amount: float):
	current_health = current_health + amount

func set_player_health(amount: float):
	current_health = amount
	max_health = amount

func shake_camera(intensity: float):
	var tween = create_tween()
	tween.tween_method(shake_camera_animation, intensity, 1, .5)

func shake_camera_animation(intensity: float):
	if !player:
		return
	var camera_offset = camera_shake_noise.get_noise_1d(Time.get_ticks_msec()) * intensity
	player.camera_player.offset = Vector2(camera_offset, camera_offset)

func load_main_scene() -> void:
	var scene = load("res://scenes/ui/main_menu_ui/main_menu_ui.tscn")
	get_tree().change_scene_to_packed(scene)

func load_level(level: String):
	var level_path = "res://scenes/level/levels/%s.tscn" % level
	if false == ResourceLoader.exists(level_path, "PackedScene"):
		load_main_scene()
		return
	
	var level_scene = load(level_path)
	get_tree().change_scene_to_packed(level_scene)

func set_used_controls():
	if Input.get_connected_joypads().is_empty():
		used_controls = CONTROLS_TYPE.KEYBOARD
	elif !Input.get_connected_joypads().is_empty():
		used_controls = CONTROLS_TYPE.XBOX
