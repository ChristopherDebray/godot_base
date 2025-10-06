## Owns the picker and the active weather instance for the level.
extends Node
class_name WeatherController

@export var loadout: WeatherLoadout
@export var rules: Array[WeightRule] = [] # e.g. [WeatherBiomeRule, WeatherTimeOfDayRule, WeatherPersistenceRule]
@export var min_state_duration_sec: float = 60.0
@export var pick_interval_sec: float = 10.0
@export var initial_biome: EnvironmentManager.BIOME = EnvironmentManager.BIOME.PLAINS
@export var random_intensity_range: Vector2 = Vector2(0.8, 1.3)

@onready var picker: WeatherPicker = $WeatherPickerComponent
@onready var pick_timer: Timer = $PickTimer

var current_weather: BaseWeather = null
var current_weather_id: EnvironmentManager.WEATHER_TYPE = EnvironmentManager.WEATHER_TYPE.CLEAR
var time_in_state: float = 0.0
var biome: EnvironmentManager.BIOME = EnvironmentManager.BIOME.PLAINS
var hour: int = 12

var target_camera: Camera2D = null

func setup(camera: Camera2D, initial_hour: int = 12, initial_biome_in: EnvironmentManager.BIOME = EnvironmentManager.BIOME.PLAINS) -> void:
	target_camera = camera
	if initial_biome_in != EnvironmentManager.BIOME.PLAINS:
		biome = initial_biome_in
	else:
		biome = initial_biome

	hour = initial_hour

	# Init picker
	picker.setup(loadout, rules)
	picker.set_context(biome, hour, current_weather_id, time_in_state)

	# First pick immediately
	_switch_weather_if_allowed(true)

	# Start periodic checks
	pick_timer.wait_time = pick_interval_sec
	pick_timer.start()

func _process(delta: float) -> void:
	if current_weather != null:
		time_in_state += delta

	# Update time in context; allows rules like Persistence
	picker.set_context(biome, hour, current_weather_id, time_in_state)

func _switch_weather_if_allowed(force: bool) -> void:
	if not force and time_in_state < min_state_duration_sec:
		return

	var entry: WeatherEntry = picker.pick()
	if entry == null:
		return

	if entry.id == current_weather_id and not force:
		# Keep current weather; optionally you can randomize intensity only
		_randomize_intensity()
		return

	# Replace current weather
	_set_weather(entry)

func _set_weather(entry: WeatherEntry) -> void:
	# Clean previous
	if current_weather != null and is_instance_valid(current_weather):
		current_weather.disable()
		current_weather.queue_free()
		current_weather = null

	# Instance new
	if entry.scene == null:
		push_warning("WeatherEntry '%s' has no scene." % entry.id)
		return

	var node = entry.scene.instantiate()
	if node == null or not (node is BaseWeather):
		push_warning("Weather scene for '%s' is not a BaseWeather." % entry.id)
		return

	add_child(node)
	current_weather = node
	current_weather_id = entry.id
	time_in_state = 0.0

	# Camera + intensity + enable
	if target_camera != null:
		current_weather.setup_for_camera(target_camera)

	_randomize_intensity()
	current_weather.enable()

func _randomize_intensity() -> void:
	if current_weather == null:
		return
	var min_i = max(0.5, random_intensity_range.x)
	var max_i = max(min_i, random_intensity_range.y)
	var r := randf_range(min_i, max_i)
	current_weather.set_intensity(r)

# Optional public API
func set_biome(new_biome: EnvironmentManager.BIOME) -> void:
	biome = new_biome
	picker.set_context(biome, hour, current_weather_id, time_in_state)

func set_hour(new_hour: int) -> void:
	hour = new_hour
	picker.set_context(biome, hour, current_weather_id, time_in_state)

func _on_pick_timer_timeout() -> void:
	_switch_weather_if_allowed(false)
