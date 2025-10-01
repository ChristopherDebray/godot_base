extends Node

enum RESOURCE_TYPE { LIFE }

var current_health: float
var max_health: float
var player: Player
var camera_shake_noise: FastNoiseLite

func _ready() -> void:
	camera_shake_noise = FastNoiseLite.new()

func modify_current_health(amount: float):
	current_health = current_health + amount

func set_player_health(amount: float):
	current_health = amount
	max_health = amount

func shake_camera(intensity: float):
	var tween = create_tween()
	tween.tween_method(shake_camera_animation, intensity, 1, .5)

func shake_camera_animation(intensity: float):
	var camera_offset = camera_shake_noise.get_noise_1d(Time.get_ticks_msec()) * intensity
	player.camera_player.offset = Vector2(camera_offset, camera_offset)
