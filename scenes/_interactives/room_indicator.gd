extends ManualInteractive

@onready var indicator: Sprite2D = $Indicator
@onready var particles: CPUParticles2D = $Particles
@onready var bubble: Sprite2D = $Bubble
@onready var bubble_reflect: Sprite2D = $BubbleReflect

const CHEST = preload("res://assets/objects/chest.png")
const QUESTION_MARK = preload("res://assets/objects/question_mark.png")
const COIN = preload("res://assets/objects/coin.png")
const BLOOD = preload("res://assets/objects/blood.png")

var _room_type: BaseLevel.ROOM_TYPE

func _ready() -> void:
	var texture
	match _room_type:
		BaseLevel.ROOM_TYPE.CHEST:
			texture = CHEST
		BaseLevel.ROOM_TYPE.SHOP:
			texture = COIN
		BaseLevel.ROOM_TYPE.COIN:
			texture = COIN
		BaseLevel.ROOM_TYPE.MYSTERY:
			texture = QUESTION_MARK
		BaseLevel.ROOM_TYPE.BLOOD:
			texture = BLOOD
	
	indicator.texture
	indicator.texture = texture
	start_floaty_tween()

func setup(room_type: BaseLevel.ROOM_TYPE):
	_room_type = room_type

func interact():
	var tween = create_tween()
	pop_bubble(tween)
	GameManager.next_room_type = _room_type
	tween.finished.connect(func ():
		GameManager.load_level('level_farm_two')
	)

func pop_bubble(tween: Tween):
	particles.emitting = true
	bubble_reflect.hide()
	bubble.hide()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(indicator, "modulate", Color(1,1,1, 0), .6)

func start_floaty_tween(duration_sec: float = 20.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var amplitude := rng.randf_range(5.0, 10.0)   # pixels
	var period    := rng.randf_range(0.28, 0.42)   # secondes par demi-oscillation
	var phase     := rng.randf_range(0.0, period)  # décalage de départ

	var loops := int(ceil(duration_sec / (period * 2.0))) # up + down = 2 demi-périodes

	var tw := create_tween()
	tw.set_loops(loops)

	tw.tween_property(self, "position:y", -amplitude, period) \
		.as_relative() \
		.set_delay(phase) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position:y", +amplitude, period) \
		.as_relative() \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
