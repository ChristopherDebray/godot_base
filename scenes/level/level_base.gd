class_name BaseLevel
extends Node2D

@onready var wave_spawner: WaveSpawner = $WaveSpawner
@onready var player: Player = $YsortLayer/Players/Player
@onready var weather_controller_component: WeatherController = $WeatherControllerComponent
@onready var relic_selection_ui: Control = $CanvasLayer/RelicSelectionUi
@onready var timer: Timer = $Timer
@onready var end_level_block: Node2D = $EndLevelBlock
@onready var reward_spawn: Marker2D = $YsortLayer/RewardSpawn

const BLOOD = preload("res://scenes/_interactives/blood.tscn")
const CHEST = preload("res://scenes/_interactives/chest.tscn")
const GOLD = preload("res://scenes/_interactives/gold.tscn")
const ROOM_INDICATOR = preload("res://scenes/_interactives/room_indicator.tscn")

enum ROOM_TYPE {
	CHEST,
	SHOP,
	COIN,
	MYSTERY,
	BLOOD
}

const MYSTERY_ROOM_TYPES = [
	ROOM_TYPE.BLOOD,
	ROOM_TYPE.CHEST,
	ROOM_TYPE.COIN
]

var room_type: ROOM_TYPE
var room_reward_instance

func _ready() -> void:
	wave_spawner.spawn_wave()
	weather_controller_component.setup(player.camera_player)
	WaveManager.on_wave_completed.connect(_on_wave_completed)
	var next_room_type = GameManager.next_room_type
	if (not next_room_type):
		next_room_type = pick_random_room_type()
	set_room_type(next_room_type)

func pick_random_room_type() -> ROOM_TYPE:
	return ROOM_TYPE[ROOM_TYPE.keys()[randi() % ROOM_TYPE.size()]]

func set_room_type(new_room: ROOM_TYPE):
	room_type = new_room
	GameManager.current_room_type = new_room

func _on_wave_completed():
	spawn_reward(room_type)
	spawn_next_level_path()

func spawn_reward(current_room_type):
	match current_room_type:
		ROOM_TYPE.CHEST:
			room_reward_instance = CHEST.instantiate()
			room_reward_instance.setup(relic_selection_ui)
		ROOM_TYPE.SHOP:
			room_reward_instance = GOLD.instantiate()
		ROOM_TYPE.COIN:
			room_reward_instance = GOLD.instantiate()
		ROOM_TYPE.MYSTERY:
			spawn_reward(MYSTERY_ROOM_TYPES.pick_random())
			return
		ROOM_TYPE.BLOOD:
			room_reward_instance = BLOOD.instantiate()
	reward_spawn.add_child(room_reward_instance)

func spawn_next_level_path():
	var paths = end_level_block.get_children()
	for path in paths:
		var room_indicator = ROOM_INDICATOR.instantiate()
		room_indicator.setup(pick_random_room_type())
		path.add_child(room_indicator)
