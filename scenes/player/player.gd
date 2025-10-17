extends Damageable

class_name Player

#@onready var item_handler: Node2D = $ItemHandler
@onready var first_element: Sprite2D = $FirstElement
@onready var second_element: Sprite2D = $SecondElement
@onready var first_element_icon: Sprite2D = $FirstElement/Sprite2D
@onready var second_element_icon: Sprite2D = $SecondElement/Sprite2D

@onready var timer_first_element: Timer = $TimerFirstElement
@onready var timer_second_element: Timer = $TimerSecondElement
@onready var spell_book: Node2D = $SpellBook
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Node2D = $Muzzle
@onready var camera_player: Camera2D = $CameraPlayer
@onready var movement_particles: CPUParticles2D = $MovementParticles

@onready var relic_inventory: RelicInventory = $RelicInventory
@onready var aim_component: Node2D = $AimComponent

var run_anim_name := "default" 
var idle_frame_index := 1
var active_elements: Array[SpellsManager.ELEMENTS] = []
var input_to_element = {
	"element_1": SpellsManager.ELEMENTS.WATER,
	"element_2": SpellsManager.ELEMENTS.FIRE,
	"element_3": SpellsManager.ELEMENTS.WIND
}
var muzzle_initial_position: float = 27
var facing_direction: Vector2 = Vector2.RIGHT

const MUZZLE_INVERTION_POS: float = -10

func _ready() -> void:
	await get_tree().process_frame
	GameManager.set_player_health(health)
	GameManager.player = self
	spell_book.setup(self)
	relic_inventory.setup(self)
	RelicManager.restore_player_relics(self)

func _physics_process(_delta: float) -> void:
	get_movement_input()
	detect_action_inputs()
	move_and_slide()
	
	_update_facing()
	_update_anim()

func _update_facing() -> void:
	var aim_dir := get_aim_direction()

	if aim_dir.x < -0.05:
		animated_sprite_2d.flip_h = true
		muzzle.position.x = MUZZLE_INVERTION_POS
		movement_particles.position.x = muzzle_initial_position
		movement_particles.rotation = -90
		facing_direction = Vector2.LEFT
	elif aim_dir.x > 0.05:
		animated_sprite_2d.flip_h = false
		muzzle.position.x = muzzle_initial_position
		movement_particles.position.x = MUZZLE_INVERTION_POS
		movement_particles.rotation = 90
		facing_direction = Vector2.RIGHT
		

func _update_anim() -> void:
	# seuil pour éviter de “jouer/arrêter” quand la vitesse est quasi nulle
	var moving := velocity.length_squared() > 1.0
	#move_toward()

	if moving:
		if animated_sprite_2d.animation != run_anim_name or !animated_sprite_2d.is_playing():
			animated_sprite_2d.play(run_anim_name)
			movement_particles.emitting = true
	else:
		if animated_sprite_2d.is_playing():
			animated_sprite_2d.stop()
			movement_particles.emitting = false
		animated_sprite_2d.frame = idle_frame_index

func get_movement_input() -> void:
	var nv: Vector2 = Vector2.ZERO
	# Returns a value from 0 to 1, depending on the "strength" used mostly for controllers
	nv.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	nv.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	velocity = nv.normalized() * speed

func detect_action_inputs() -> void:
	detect_interaction_inputs()
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
		first_element_icon.texture = AbilityManager.get_icon(active_elements[0])
		first_element.show()
		timer_first_element.start()

	if active_elements.size() == 2:
		second_element_icon.texture = AbilityManager.get_icon(active_elements[1])
		second_element.show()
		timer_second_element.start()
	else:
		second_element.hide()
		timer_second_element.stop()

func get_aim_direction() -> Vector2:
	return global_position.direction_to(get_aim_world_position())

func use_spell() -> void:
	if active_elements.size() < 2:
		var fireboltElement: Array[SpellsManager.ELEMENTS] = [SpellsManager.ELEMENTS.FIRE]
		spell_book.use_spell(fireboltElement, get_aim_direction())
		return
	spell_book.use_spell(active_elements, get_aim_direction())
	_remove_element(1)
	_remove_element(0)

func add_relic(relic: BaseRelic):
	relic_inventory.add_relic(relic)
	RelicManager.relics.push_front(relic)

func get_aim_world_position() -> Vector2:
	return aim_component.get_aim_world_position()

func _on_timer_first_element_timeout() -> void:
	if active_elements.size() > 0:
		_remove_element(0)
		_update_elements_display()

func _on_timer_second_element_timeout() -> void:
	if active_elements.size() > 1:
		_remove_element(1)
		_update_elements_display()

func on_hit():
	animated_sprite_2d.material.set_shader_parameter('mix_amount', 1)
	
	var tween := create_tween()
	tween.tween_property(
		animated_sprite_2d.material, 
		"shader_parameter/mix_amount", 
		0.0,
		0.25 # duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

#func detect_input_item_handler():
	#if Input.is_action_just_pressed("use_item"):
		#item_handler.use_item(get_aim_direction())
	#
	#if Input.is_action_just_pressed("switch_item_next"):
		#item_handler.switch_item(1)
	#
	#if Input.is_action_just_pressed("switch_item_prev"):
		#item_handler.switch_item(-1)
