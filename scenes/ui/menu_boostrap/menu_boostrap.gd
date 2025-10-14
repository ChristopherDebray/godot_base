extends Control

@export var initial_focus: NodePath    # ex: %PlayButton Or first option button
@export var fallback_scope: NodePath   # ex: %CurrentTabPanel, if initial_focus is empty

func _on_open_menu() -> void:
	await get_tree().process_frame  # wait one frame so layout is ready
	_grab_initial_focus()

func _grab_initial_focus() -> void:
	var node: Control = null
	if initial_focus != NodePath():
		node = get_node(initial_focus) as Control
	if node == null or not is_instance_valid(node) or node.focus_mode == Control.FOCUS_NONE or not node.visible:
		node = _find_first_focusable_in_scope()
	if node:
		node.grab_focus()

func _find_first_focusable_in_scope() -> Control:
	var scope: Node = self
	if fallback_scope != NodePath():
		scope = get_node(fallback_scope)
	return _deep_first_focusable(scope)

func _deep_first_focusable(root: Node) -> Control:
	for c in root.get_children():
		if c is Control and c.visible and c.focus_mode != Control.FOCUS_NONE:
			return c
		var deep := _deep_first_focusable(c)
		if deep:
			return deep
	return null
