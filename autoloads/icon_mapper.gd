## IconMapper.gd (singleton)
#extends Node
#
#const ICONS := {
	#SCHEME.XBOX: {
		#"Joypad Button 0": preload("res://icons/xbox/button_a.png"),
		#"Joypad Button 1": preload("res://icons/xbox/button_b.png"),
		## ...
	#},
	#SCHEME.PLAYSTATION: {
		#"Joypad Button 0": preload("res://icons/ps/button_cross.png"),
		#"Joypad Button 1": preload("res://icons/ps/button_circle.png"),
		## ...
	#},
	#SCHEME.KEYBOARD: {
		#"W": preload("res://icons/keyboard/key_w.png"),
		#"Space": preload("res://icons/keyboard/key_space.png"),
		## ...
	#}
#}
#
#func get_icon_for_event(event: InputEvent, scheme: InputScheme.SCHEME) -> Texture2D:
	#var key := event.as_text()
	#if ICONS[scheme].has(key):
		#return ICONS[scheme][key]
	#return null  # Fallback sur texte

## DANS L4UI

#func _update_button_prompt(action: StringName) -> void:
	#var events = InputMap.action_get_events(action)
	#if events.is_empty():
		#return
	#
	#var event = events[0]  # Premier binding
	#var icon = IconMapper.get_icon_for_event(event, InputScheme.current_scheme)
	#
	#if icon:
		#$ButtonIcon.texture = icon
		#$ButtonLabel.hide()
	#else:
		#$ButtonLabel.text = event.as_text()
		#$ButtonIcon.hide()
