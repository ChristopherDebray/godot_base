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
		activate_element(ELEMENTS.FIRE)
	if Input.is_action_just_pressed("y_2_action"):
		activate_element(ELEMENTS.WATER)
	if Input.is_action_just_pressed("b_3_action"):
		activate_element(ELEMENTS.WIND)
	
	if Input.is_action_just_pressed("validate"):
		print("validate");

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
#
#func get_aim_direction() -> Vector2:
	#if Input.get_connected_joypads().size():
		#var stick_direction: Vector2 = Vector2.RIGHT
		#stick_direction.x = Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left")
		#stick_direction.y = Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
		#return Vector2.ZERO.direction_to(stick_direction)
	#
	#return global_position.direction_to(get_global_mouse_position())
