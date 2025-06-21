extends CharacterBody2D

class_name Player

#@onready var item_handler: Node2D = $ItemHandler
@onready var first_element: AnimatedSprite2D = $FirstElement
@onready var second_element: AnimatedSprite2D = $SecondElement
@onready var timer_first_element: Timer = $TimerFirstElement
@onready var timer_second_element: Timer = $TimerSecondElement

var active_elements: Array[int] = []

enum ELEMENTS {
	WATER,
	FIRE,
	EARTH,
	WIND,
}

var spell_book := {
	[ELEMENTS.FIRE, ELEMENTS.FIRE]: "Fireball",
	[ELEMENTS.WATER, ELEMENTS.WATER]: "Ice Lance",
	[ELEMENTS.EARTH, ELEMENTS.EARTH]: "Stone Shield",
	[ELEMENTS.WIND, ELEMENTS.WIND]: "Gust",

	[ELEMENTS.FIRE, ELEMENTS.WATER]: "Steam Burst",
	[ELEMENTS.FIRE, ELEMENTS.EARTH]: "Magma Wave",
	[ELEMENTS.WATER, ELEMENTS.WIND]: "Blizzard",
	[ELEMENTS.EARTH, ELEMENTS.WIND]: "Sandstorm",
	[ELEMENTS.FIRE, ELEMENTS.WIND]: "Flame Tornado",
	[ELEMENTS.WATER, ELEMENTS.EARTH]: "Mud Trap",
}

const SPEED: float = 230.0
const PROBE_SIZE = Vector2(50, 50)

func _ready() -> void:
	await get_tree().process_frame

func _physics_process(_delta: float) -> void:
	var transform = Transform2D()
	transform = transform.translated(-global_position + PROBE_SIZE/2)
	
	get_movement_input()
	detect_action_inputs()
	move_and_slide()
	rotation = velocity.angle()

func get_movement_input() -> void:
	var nv: Vector2 = Vector2.ZERO
	# Returns a value from 0 to 1, depending on the "strength" used mostly for controllers
	nv.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	nv.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	velocity = nv.normalized() * SPEED

func detect_action_inputs() -> void:
	detect_interaction_inputs();
	#detect_input_item_handler()

func detect_interaction_inputs() -> void:
	if Input.is_action_just_pressed("x_1_action"):
		activate_element(ELEMENTS.WATER)
	if Input.is_action_just_pressed("y_2_action"):
		activate_element(ELEMENTS.FIRE)
	if Input.is_action_just_pressed("b_3_action"):
		activate_element(ELEMENTS.EARTH)
	
	if Input.is_action_just_pressed("validate"):
		print("validate");
	
	if Input.is_action_just_pressed("use_spell"):
		use_spell()

func activate_element(element: ELEMENTS) -> void:
	if active_elements.size() >= 2:
		_remove_element(0)

	active_elements.append(element)
	_update_elements_display()

func _remove_element(index: int) -> void:
	active_elements.remove_at(index)
	if index == 0:
		first_element.hide()
		timer_first_element.stop()
	else:
		second_element.hide()
		timer_second_element.stop()

func _update_elements_display() -> void:
	if active_elements.size() >= 1:
		first_element.frame = active_elements[0]
		first_element.show()
		timer_first_element.start()

	if active_elements.size() == 2:
		second_element.frame = active_elements[1]
		second_element.show()
		timer_second_element.start()
	else:
		second_element.hide()
		timer_second_element.stop()

func get_aim_direction() -> Vector2:
	if Input.get_connected_joypads().size():
		var stick_direction: Vector2 = Vector2.RIGHT
		stick_direction.x = Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left")
		stick_direction.y = Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
		return Vector2.ZERO.direction_to(stick_direction)
	
	return global_position.direction_to(get_global_mouse_position())

func use_spell() -> void:
	var spell_name = get_spell_from_elements(active_elements)
	print("Casting spell:", spell_name)
	_remove_element(1)
	_remove_element(0)

func get_spell_from_elements(elements: Array[int]) -> String:
	if elements.is_empty():
		return "No spell"

	var combo = elements.duplicate()
	combo.sort() # ignore l’ordre d’activation

	if spell_book.has(combo):
		return spell_book[combo]
	
	if combo.size() == 1 and spell_book.has([combo[0]]):
		return spell_book[[combo[0]]]

	return "Unknown combination"

func _on_timer_first_element_timeout() -> void:
	if active_elements.size() > 0:
		_remove_element(0)
		_update_elements_display()

func _on_timer_second_element_timeout() -> void:
	if active_elements.size() > 1:
		_remove_element(1)
		_update_elements_display()

#func detect_input_item_handler():
	#if Input.is_action_just_pressed("use_item"):
		#item_handler.use_item(get_aim_direction())
	#
	#if Input.is_action_just_pressed("switch_item_next"):
		#item_handler.switch_item(1)
	#
	#if Input.is_action_just_pressed("switch_item_prev"):
		#item_handler.switch_item(-1)
