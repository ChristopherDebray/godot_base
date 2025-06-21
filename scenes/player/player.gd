extends CharacterBody2D

class_name Player

#@onready var item_handler: Node2D = $ItemHandler

const SPEED: float = 230.0
const PROBE_SIZE = Vector2(50, 50)

func _ready() -> void:
	await get_tree().process_frame

func _physics_process(_delta: float) -> void:
	var transform = Transform2D()
	transform = transform.translated(-global_position + PROBE_SIZE/2)
	
	get_movement_input()
	#get_action_input()
	move_and_slide()
	rotation = velocity.angle()

func get_movement_input() -> void:
	var nv: Vector2 = Vector2.ZERO
	# Returns a value from 0 to 1, depending on the "strength" used mostly for controllers
	nv.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	nv.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	velocity = nv.normalized() * SPEED

#func get_action_input() -> void:
	#detect_input_item_handler()
#
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
