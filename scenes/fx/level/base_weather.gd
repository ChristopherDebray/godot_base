extends Node2D
class_name BaseWeather

@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var timer: Timer = $Timer
@onready var color_rect: ColorRect = $CanvasLayer/ColorRect

@export var environment_ability: AbilityData
@export var ability_cooldown: float = 10
@export var player: Player = null

var target_camera: Camera2D = null
var _enabled: bool = false
var _intensity: float = 1.0  # 0.8..1.2

func _ready() -> void:
	timer.wait_time = ability_cooldown * _intensity
	if not environment_ability:
		timer.stop()

func setup_for_camera(cam: Camera2D) -> void:
	target_camera = cam
	_on_camera_ready()

func set_intensity(mult: float) -> void:
	_intensity = clamp(mult, 0.5, 2.0)
	_on_intensity_changed(_intensity)

func enable() -> void:
	_enabled = true
	set_process(true)
	_on_enabled()

func disable() -> void:
	_enabled = false
	set_process(false)
	_on_disabled()

static func pick_attack_point_in_view(camera: Camera2D, avoid_pos: Vector2, min_dist := 96.0, margin := 24.0) -> Vector2:
	# Pick a random point inside the current camera view (with a safe margin).
	var viewport := camera.get_viewport_rect().size
	var half := viewport * 0.5 - Vector2(margin, margin)
	var screen_center_position := camera.get_screen_center_position()

	var spawn_position := Vector2(
		randf_range(screen_center_position.x - half.x, screen_center_position.x + half.x),
		randf_range(screen_center_position.y - half.y, screen_center_position.y + half.y)
	)

	# Retry a few times if too close to the player (or any avoid_pos)
	for try in 6:
		if spawn_position.distance_to(avoid_pos) >= min_dist:
			return spawn_position
		spawn_position.x = randf_range(screen_center_position.x - half.x, screen_center_position.x + half.x)
		spawn_position.y = randf_range(screen_center_position.y - half.y, screen_center_position.y + half.y)
	return spawn_position

# Hooks to implement
func _on_camera_ready() -> void: pass
func _on_intensity_changed(value: float) -> void: pass
func _on_enabled() -> void: pass
func _on_disabled() -> void: pass

func _on_timer_timeout() -> void:
	var point = pick_attack_point_in_view(target_camera, Vector2(0, 0))
	SignalManager.use_ability.emit(environment_ability, point, point, AbilityManager.TARGET_TYPE.ALL)
