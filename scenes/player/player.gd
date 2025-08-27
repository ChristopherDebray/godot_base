extends Damageable

class_name Player

#@onready var item_handler: Node2D = $ItemHandler
@onready var first_element: AnimatedSprite2D = $FirstElement
@onready var second_element: AnimatedSprite2D = $SecondElement
@onready var timer_first_element: Timer = $TimerFirstElement
@onready var timer_second_element: Timer = $TimerSecondElement
@onready var spell_book: Node2D = $SpellBook
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var run_anim_name := "default" 
var idle_frame_index := 1
var active_elements: Array[int] = []
var input_to_element = {
	"x_1_action": SpellsManager.ELEMENTS.WATER,
	"y_2_action": SpellsManager.ELEMENTS.FIRE,
	"b_3_action": SpellsManager.ELEMENTS.WIND
}

const PROBE_SIZE = Vector2(50, 50)

func _ready() -> void:
	await get_tree().process_frame

func _physics_process(_delta: float) -> void:
	var transform = Transform2D()
	transform = transform.translated(-global_position + PROBE_SIZE/2)
	
	get_movement_input()
	detect_action_inputs()
	move_and_slide()
	
	_update_facing()
	_update_anim()

func _update_facing() -> void:
	var aim_dir := get_aim_direction()

	if aim_dir.x < -0.05:
		animated_sprite_2d.flip_h = true
	elif aim_dir.x > 0.05:
		animated_sprite_2d.flip_h = false

func _update_anim() -> void:
	# seuil pour éviter de “jouer/arrêter” quand la vitesse est quasi nulle
	var moving := velocity.length_squared() > 1.0

	if moving:
		if animated_sprite_2d.animation != run_anim_name or !animated_sprite_2d.is_playing():
			animated_sprite_2d.play(run_anim_name)
	else:
		if animated_sprite_2d.is_playing():
			animated_sprite_2d.stop()
		animated_sprite_2d.frame = idle_frame_index

func get_movement_input() -> void:
	var nv: Vector2 = Vector2.ZERO
	# Returns a value from 0 to 1, depending on the "strength" used mostly for controllers
	nv.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	nv.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	velocity = nv.normalized() * speed

func detect_action_inputs() -> void:
	detect_interaction_inputs();
	#detect_input_item_handler()

func detect_interaction_inputs() -> void:
	for input_name in input_to_element.keys():
		if Input.is_action_just_pressed(input_name):
			activate_element(input_to_element[input_name])
	
	if Input.is_action_just_pressed("validate"):
		print("validate");
	
	if Input.is_action_just_pressed("use_spell"):
		use_spell()

func activate_element(element: SpellsManager.ELEMENTS) -> void:
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
	if active_elements.size() < 2:
		var fireboltElement: Array[SpellsManager.ELEMENTS] = [SpellsManager.ELEMENTS.FIRE]
		spell_book.use_spell(fireboltElement, get_aim_direction())
		return
	spell_book.use_spell(active_elements, get_aim_direction())
	_remove_element(1)
	_remove_element(0)

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
