extends Node2D

@onready var _timer: Timer = $Timer

@export var enemy_scene: PackedScene
@export var player: Node2D
@export var spawn_points_container: Node2D
## Min distance with player to authorize spawn
@export var min_player_distance: float = 250.0
## Seconds between spawn
@export var spawn_interval: float = 1.2
## Length of wave
@export var total_to_spawn: int = 10
## Limit of simultanous enemy
@export var max_alive_at_once: int = 6

var _markers: Array[Marker2D] = []
var _spawned_count := 0
var _alive_count := 0
var _spawning := false

func _ready() -> void:
	if spawn_points_container:
		for c in spawn_points_container.get_children():
			if c is Marker2D:
				_markers.append(c)
	else:
		push_warning("spawn_points_container isn't assigned.")

	_timer.wait_time = spawn_interval
	SignalManager.died.connect(_on_died)

	# Sanity checks
	if enemy_scene == null:
		push_error("enemy_scene non assigned.")
	if player == null:
		push_error("player non assigned.")
	if _markers.is_empty():
		push_warning("No marker found.")
	
	_spawn_wave()

func _spawn():
	var spawn_point: Marker2D = _markers.pick_random()
	var instance: BaseNpc = enemy_scene.instantiate()
	instance.is_zone_locked = false
	instance.global_position = spawn_point.global_position
	
	get_tree().current_scene.get_node("YsortLayer/Npcs").add_child(instance)
	instance.state = BaseNpc.STATE.ATTACKING
	_spawned_count += 1
	_alive_count += 1
	
func _on_spawn_tick() -> void:
	if !_spawning:
		return
	
	if _spawned_count > _alive_count:
		return

	if _spawned_count >= total_to_spawn:
		_timer.stop()
		_spawning = false
		_check_wave_cleared()
		return
	
	_spawn()

func _spawn_wave():
	_spawning = true
	_timer.start()

func stop_wave() -> void:
	_spawning = false
	_timer.stop()

func _check_wave_cleared() -> bool:
	if total_to_spawn != _spawned_count:
		return false
	
	if _alive_count > 0:
		return false
	
	return true

func end_game():
	print("FINISH")

func _on_died(target: Damageable):
	_alive_count -= 1
	var is_wave_cleared = _check_wave_cleared()
	if is_wave_cleared:
		stop_wave()
		end_game()
