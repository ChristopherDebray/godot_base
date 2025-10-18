extends BaseWeather

const THUNDERSTRIKE = preload("res://data/spells/spell_ressources/thunderstrike.tres")

@export var screen_margin: Vector2 = Vector2(128, 128)
@export var density_per_px2: float = 0.00010
@export var base_tint: Color = Color(0.10, 0.12, 0.18, 0.18)

func _ready() -> void:
	environment_ability = environment_ability_entry.ability
	environment_ability.base_cast_time = environment_ability_entry.cast_time
	super._ready()
	timer.wait_time = 6

func _physics_process(delta: float) -> void:
	global_position = target_camera.global_position

func _on_camera_ready() -> void:
	_update_emission_rect()
	_update_amount()
	_update_overlay()

func _on_intensity_changed(value: float) -> void:
	_update_amount()
	_update_overlay()

func _on_enabled() -> void:
	cpu_particles_2d.emitting = true
	if audio_stream_player_2d.stream:
		audio_stream_player_2d.play()

func _on_disabled() -> void:
	cpu_particles_2d.emitting = false
	if audio_stream_player_2d.playing:
		audio_stream_player_2d.stop()
	queue_free()

func _update_emission_rect() -> void:
	var viewport := get_viewport_rect().size
	var half := viewport * 0.5 + screen_margin
	cpu_particles_2d.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	cpu_particles_2d.emission_rect_extents = half

func _update_amount() -> void:
	var viewport := get_viewport_rect().size
	var area := viewport.x * viewport.y
	var target := int(area * density_per_px2 * _intensity)
	cpu_particles_2d.amount = clamp(target, 300, 4000)

func _update_overlay() -> void:
	var color := base_tint
	color.a = base_tint.a * _intensity
	color_rect.color = color
	color_rect.show()
	
