extends Node2D

@export var sensitivity: float = 800.0   # pixels/sec à stick=1
@export var deadzone: float = 0.25
@export var return_to_center_on_idle: bool = true
@export var max_radius: float = 350.0         # maximum distance from player
@export var use_stick_magnitude: bool = true

var velocity: Vector2 = Vector2.ZERO
var player: Player = null

func _ready() -> void:
	if player == null:
		player = get_parent() as Player
	velocity = player.facing_direction
	InputSchemeManager.scheme_changed.connect(_on_scheme_changed)
	_refresh_visual()

func _on_scheme_changed(scheme: InputSchemeManager.SCHEME):
	_refresh_visual()

func _refresh_visual():
	var scheme := InputSchemeManager.current_scheme
	var joypad_scheme = [InputSchemeManager.SCHEME.XBOX, InputSchemeManager.SCHEME.PLAYSTATION]
	if not joypad_scheme.has(scheme):
		visible = false
		set_process(false)
		return
	
	set_process(true)
	visible = true
	return
	

func _process(delta: float) -> void:
	var vx := Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left")
	var vy := Input.get_action_strength("aim_down")  - Input.get_action_strength("aim_up")
	var input_vec := Vector2(vx, vy)

	if input_vec.length() < deadzone:
		if return_to_center_on_idle and player != null:
			global_position = player.global_position + player.facing_direction
			visible = false
		else:
			visible = false
		return

	visible = true
	position += input_vec * sensitivity * delta

	var dir := input_vec.normalized()
	var radius := max_radius
	if use_stick_magnitude:
		# Map magnitude [deadzone..1] to [0..1]
		var t = clamp((input_vec.length() - deadzone) / (1.0 - deadzone), 0.0, 1.0)
		radius = t * max_radius
	
	# Snap instantly (no lag)
	global_position = player.global_position + dir * radius
	rotation = dir.angle()

	# (optionnel) si tu veux aussi bouger la vraie souris sur desktop :
	# Input.warp_mouse(position)

func get_aim_world_position():
	if InputSchemeManager.SCHEME.KEYBOARD == InputSchemeManager.current_scheme:
		return get_global_mouse_position()
	
	return global_position
