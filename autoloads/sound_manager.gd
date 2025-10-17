# File: SfxManager.gd (autoload)
extends Node

class_name SfxManager

# --- Tag configuration container ---
class TagConfig:
	var max_simultaneous: int
	var min_interval_ms: int
	var audible_radius: float
	var priority: int
	var pitch_variation: float
	var bus_name: String

	func _init(max_simultaneous: int = 8, min_interval_ms: int = 0, audible_radius: float = 1600.0, priority: int = 0, pitch_variation: float = 1.4, bus_name: String = "SFX"):
		self.max_simultaneous = max_simultaneous
		self.min_interval_ms = min_interval_ms
		self.audible_radius = audible_radius
		self.priority = priority
		self.pitch_variation = pitch_variation
		self.bus_name = bus_name

@export var initial_world_voices: int = 24
@export var initial_ui_voices: int = 8

var _world_pool: Array[AudioStreamPlayer2D] = []
var _ui_pool: Array[AudioStreamPlayer] = []
var _tag_configs: Dictionary = {}
var _tag_last_time: Dictionary = {}           # tag -> last played time (ms)
var _tag_active_count: Dictionary = {}        # tag -> active count

func _ready() -> void:
	# Prewarm pools
	for i in initial_world_voices:
		var p := AudioStreamPlayer2D.new()
		p.autoplay = false
		p.bus = "SFX"
		add_child(p)
		_world_pool.append(p)

	for i in initial_ui_voices:
		var u := AudioStreamPlayer.new()
		u.autoplay = false
		u.bus = "UI"
		add_child(u)
		_ui_pool.append(u)

	# Default configs (tune these to your game)
	_tag_configs["arrow"] = TagConfig.new(12, 0, 1400.0, 5, 0.2, "Sfx")
	_tag_configs["spell_cast"] = TagConfig.new(8, 0, 1600.0, 8, 0.2, "Sfx")
	_tag_configs["impact"] = TagConfig.new(10, 0, 1400.0, 9, 0.2, "Sfx")
	_tag_configs["footstep"] = TagConfig.new(4, 90, 800.0, 1, 0.2, "Sfx") # very conservative
	_tag_configs["ui"] = TagConfig.new(6, 0, 1e9, 10, 0.1, "UI")

func set_tag_config(tag_name: String, config: TagConfig) -> void:
	_tag_configs[tag_name] = config

# -------- Public API --------

func play_ui(stream: AudioStream, volume_db: float = 0.0, pitch_variation_override: float = -1.0) -> void:
	var player := _get_free_ui_player()
	if player == null:
		player = _force_steal_ui_player()
	if player == null:
		return
	player.stream = stream
	player.volume_db = volume_db
	if pitch_variation_override > 0.0:
		player.pitch_scale = randf_range(0.8, pitch_variation_override)
	else:
		player.pitch_scale = 1.0
	player.play()

func play_tag_at(tag_name: String, stream: AudioStream, world_position: Vector2, volume_db: float = 0.0) -> void:
	if stream == null:
		return

	var cfg: TagConfig = _tag_configs.get(tag_name, null)
	if cfg == null:
		# Fallback: default config
		cfg = TagConfig.new()

	# Distance culling (camera center assumed at viewport center)
	var listener_pos := _get_listener_position()
	if listener_pos.distance_squared_to(world_position) > cfg.audible_radius * cfg.audible_radius:
		return

	# Per-tag rate limit
	var now_ms := Time.get_ticks_msec()
	var last_ms := int(_tag_last_time.get(tag_name, -999999))
	if now_ms - last_ms < cfg.min_interval_ms:
		return

	# Per-tag concurrency cap
	var active := int(_tag_active_count.get(tag_name, 0))
	if active >= cfg.max_simultaneous:
		# Try steal a lower priority / farther voice
		var stolen := _try_steal_world_voice(cfg.priority, listener_pos)
		if stolen == null:
			return
		_config_and_play(stolen, stream, world_position, volume_db, cfg, tag_name)
		return

	# Normal path: take a free player
	var p := _get_free_world_player()
	if p == null:
		# Burst: steal something if possible
		p = _try_steal_world_voice(cfg.priority, listener_pos)
		if p == null:
			return
	_config_and_play(p, stream, world_position, volume_db, cfg, tag_name)
	_tag_last_time[tag_name] = now_ms

# -------- Internals --------

func _config_and_play(player: AudioStreamPlayer2D, stream: AudioStream, pos: Vector2, volume_db: float, cfg: TagConfig, tag_name: String) -> void:
	player.set_meta("tag_name", tag_name)
	player.set_meta("tag_priority", cfg.priority)  # Bonus
	player.stop()
	player.global_position = pos
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = _rand_pitch(1, cfg.pitch_variation)
	player.bus = cfg.bus_name
	player.play()
	# Track active per tag
	_tag_active_count[tag_name] = int(_tag_active_count.get(tag_name, 0)) + 1
	player.finished.connect(func():
		_tag_active_count[tag_name] = max(0, int(_tag_active_count.get(tag_name, 1)) - 1)
		# Nettoyer les metas pour le prochain usage
		player.remove_meta("tag_name")
		player.remove_meta("tag_priority")
		, Object.CONNECT_ONE_SHOT)

func _get_free_world_player() -> AudioStreamPlayer2D:
	for p in _world_pool:
		if not p.playing:
			return p
	# Optional: allocate on demand
	var extra := AudioStreamPlayer2D.new()
	extra.bus = "SFX"
	add_child(extra)
	_world_pool.append(extra)
	return extra

func _get_free_ui_player() -> AudioStreamPlayer:
	for p in _ui_pool:
		if not p.playing:
			return p
	return null

func _force_steal_ui_player() -> AudioStreamPlayer:
	# Steal the first UI voice (very rare)
	for p in _ui_pool:
		return p
	return null

func _try_steal_world_voice(min_priority: int, listener_pos: Vector2) -> AudioStreamPlayer2D:
	# Strategy: steal the farthest low-priority voice if any
	var candidate: AudioStreamPlayer2D = null
	var best_score := -1.0
	for p in _world_pool:
		if not p.playing:
			continue
		
		if not p.has_meta("tag_name"):
			# Player jamais utilisé ou pas configuré correctement
			# On peut le voler sans souci (pas de priorité)
			var dist2 := listener_pos.distance_squared_to(p.global_position)
			if dist2 > best_score:
				best_score = dist2
				candidate = p
			continue

		var tag = p.get_meta("tag_name")
		var tag_cfg: TagConfig = _tag_configs.get(tag, null)
		if tag_cfg == null:
			var dist2 := listener_pos.distance_squared_to(p.global_position)
			if dist2 > best_score:
				best_score = dist2
				candidate = p
			continue
		# Ne voler que les sons de priorité inférieure ou égale
		if tag_cfg.priority > min_priority:
			continue
		# Score = distance to listener
		var dist2 := listener_pos.distance_squared_to(p.global_position)
		if dist2 > best_score:
			best_score = dist2
			candidate = p
	if candidate != null:
		candidate.stop()
	return candidate

func _rand_pitch(base_pitch: float, variation: float) -> float:
	if variation <= 0.0:
		return base_pitch
	var min_pitch := base_pitch - variation
	var max_pitch := base_pitch + variation
	return randf_range(min_pitch, max_pitch)

func _get_listener_position() -> Vector2:
	# Simple: center of current viewport
	var vp := get_viewport()
	if vp:
		return vp.get_visible_rect().size * 0.5 + vp.get_canvas_transform().origin
	return Vector2.ZERO
