extends Node

const CONFIG_PATH := "user://controls.cfg"
const SECTION := "bindings"

# === Defaults: edit this to your game ===
const DEFAULTS := {
	# UI / menus
	"ui_up":        [KEY_UP, KEY_Z, JOY_BUTTON_DPAD_UP],
	"ui_down":      [KEY_DOWN, KEY_S, JOY_BUTTON_DPAD_DOWN],
	"ui_left":      [KEY_LEFT, KEY_Q, JOY_BUTTON_DPAD_LEFT],
	"ui_right":     [KEY_RIGHT, KEY_D, JOY_BUTTON_DPAD_RIGHT],
	"ui_accept":    [KEY_ENTER, KEY_SPACE, JOY_BUTTON_A],
	"ui_cancel":    [KEY_ESCAPE, JOY_BUTTON_B],
	"ui_start":     [KEY_ESCAPE, JOY_BUTTON_START],
	"pause":        [KEY_ESCAPE, JOY_BUTTON_START],
	"ui_focus_next": [KEY_TAB, JOY_BUTTON_RIGHT_SHOULDER],
	"ui_focus_prev": [KEY_TAB | KEY_MASK_SHIFT, JOY_BUTTON_LEFT_SHOULDER],
	"ui_page_up":   [KEY_PAGEUP, JOY_BUTTON_LEFT_STICK],
	"ui_page_down": [KEY_PAGEDOWN, JOY_BUTTON_RIGHT_STICK],

	# Gameplay - UTILISE LES VRAIS NOMS DE TON PROJET !
	"up":           [KEY_W, KEY_UP, {"axis": JOY_AXIS_LEFT_Y, "value": -1.0}],
	"down":         [KEY_S, KEY_DOWN, {"axis": JOY_AXIS_LEFT_Y, "value": 1.0}],
	"left":         [KEY_A, KEY_LEFT, {"axis": JOY_AXIS_LEFT_X, "value": -1.0}],
	"right":        [KEY_D, KEY_RIGHT, {"axis": JOY_AXIS_LEFT_X, "value": 1.0}],
	"use_spell":    [MOUSE_BUTTON_LEFT, {"axis": JOY_AXIS_TRIGGER_RIGHT, "value": 1.0}],
	"element_1":    [KEY_1, JOY_BUTTON_X],
	"element_2":    [KEY_2, JOY_BUTTON_Y],
	"element_3":    [KEY_3, JOY_BUTTON_B],
	"validate":     [KEY_E, JOY_BUTTON_A],
}

var _capturing_action: StringName = &""
var _on_captured: Callable = Callable()

func _ready() -> void:
	# IMPORTANT : Toujours créer les actions en premier !
	_ensure_actions_exist()
	
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)
	if err != OK:
		print("No config file found, creating defaults...")
		reset_to_defaults(true)
	else:
		print("Loading bindings from config...")
		load_bindings()
	
	# DEBUG: Afficher toutes les actions et leurs bindings
	print("\n=== Current InputMap actions ===")
	for action in InputMap.get_actions():
		var events = InputMap.action_get_events(action)
		print(action, " -> ", events.size(), " events")
		for e in events:
			print("  - ", e.as_text())
	print("================================\n")

func _ensure_actions_exist() -> void:
	"""S'assure que toutes les actions de DEFAULTS existent dans InputMap"""
	for action in DEFAULTS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			print("Created missing action: ", action)

func start_capture(action: StringName, on_captured: Callable) -> void:
	_capturing_action = action
	_on_captured = on_captured

func cancel_capture() -> void:
	_capturing_action = &""
	_on_captured = Callable()

func _input(event: InputEvent) -> void:
	# Ne rien faire si on ne capture pas
	if _capturing_action == &"":
		return

	# Ignore noisy events
	if event is InputEventMouseMotion:
		return
	if event is InputEventJoypadMotion:
		if abs(event.axis_value) < 0.6:
			return

	# Only accept pressed events
	if not event.is_pressed():
		return

	# On capture ! Consommer l'event pour pas qu'il aille ailleurs
	get_viewport().set_input_as_handled()
	
	print("Captured event: ", event, " for action: ", _capturing_action)
	_apply_binding(_capturing_action, event)
	var done_action := _capturing_action
	var captured_event := event
	_capturing_action = &""
	
	if _on_captured.is_valid():
		_on_captured.call(done_action, captured_event)
	_on_captured = Callable()

func _apply_binding(action: StringName, new_event: InputEvent) -> void:
	for e in InputMap.action_get_events(action):
		if new_event.is_match(e):
			return

	for other in InputMap.get_actions():
		if other == action:
			continue
		for e in InputMap.action_get_events(other):
			if new_event.is_match(e):
				InputMap.action_erase_event(other, e)
				break

	_clear_action(action)
	InputMap.action_add_event(action, new_event)
	save_bindings()

func _clear_action(action: StringName) -> void:
	var to_erase := InputMap.action_get_events(action)
	for e in to_erase:
		InputMap.action_erase_event(action, e)

# === Persistence (VERSION SIMPLE avec var_to_str) ===

func save_bindings() -> void:
	var cfg := ConfigFile.new()
	for action in InputMap.get_actions():
		var events_array: Array = []
		for e in InputMap.action_get_events(action):
			# Godot sérialise automatiquement l'InputEvent !
			events_array.append(var_to_str(e))
		cfg.set_value(SECTION, StringName(action), events_array)
	cfg.save(CONFIG_PATH)

func load_bindings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)
	if err != OK:
		return

	for action in InputMap.get_actions():
		_clear_action(action)
		var events_data: Array = cfg.get_value(SECTION, StringName(action), [])
		for serialized_str in events_data:
			if serialized_str is String:
				var ev = str_to_var(serialized_str)
				if ev is InputEvent:
					InputMap.action_add_event(action, ev)
	
	# Si une action n'a aucun event après le load, utiliser les defaults
	for action in DEFAULTS.keys():
		if InputMap.action_get_events(action).is_empty():
			print("Action '", action, "' has no bindings, applying defaults...")
			var bindings: Array = DEFAULTS[action]
			for binding in bindings:
				var ev := _create_event_from_default(binding)
				if ev:
					InputMap.action_add_event(action, ev)

# === Defaults ===

func reset_to_defaults(save_file: bool) -> void:
	for action in DEFAULTS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		_clear_action(action)
		
		var bindings: Array = DEFAULTS[action]
		for binding in bindings:
			var ev := _create_event_from_default(binding)
			if ev:
				InputMap.action_add_event(action, ev)
	
	if save_file:
		save_bindings()

func _create_event_from_default(binding) -> InputEvent:
	"""Crée un InputEvent depuis les valeurs dans DEFAULTS"""
	
	# Si c'est un dictionnaire -> JoypadMotion
	if binding is Dictionary:
		if binding.has("axis"):
			var joy_motion := InputEventJoypadMotion.new()
			joy_motion.axis = binding["axis"]
			joy_motion.axis_value = binding.get("value", 1.0)
			return joy_motion
	
	# Si c'est un int, on détecte le type
	elif binding is int:
		# Mouse button (1-9 généralement)
		if binding >= MOUSE_BUTTON_LEFT and binding <= MOUSE_BUTTON_XBUTTON2:
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = binding
			mouse_event.pressed = true
			return mouse_event
		
		# Joypad button (commence à partir de JOY_BUTTON_A = 0)
		elif binding >= JOY_BUTTON_A and binding <= JOY_BUTTON_MAX:
			var joy_button := InputEventJoypadButton.new()
			joy_button.button_index = binding
			joy_button.pressed = true
			return joy_button
		
		# Key (avec potentiel modifier mask)
		else:
			var key_event := InputEventKey.new()
			# Extraire les modifiers si présents
			if binding & KEY_MASK_SHIFT:
				key_event.shift_pressed = true
			if binding & KEY_MASK_CTRL:
				key_event.ctrl_pressed = true
			if binding & KEY_MASK_ALT:
				key_event.alt_pressed = true
			if binding & KEY_MASK_META:
				key_event.meta_pressed = true
			
			# Le keycode sans les masks
			key_event.keycode = binding & KEY_CODE_MASK
			key_event.pressed = true
			return key_event
	
	return null
