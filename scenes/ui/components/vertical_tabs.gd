extends HBoxContainer

@export var tabs: Array[VTabSpec] = []

var _tab_buttons_box: VBoxContainer
var _content_panel: PanelContainer
var _content_holder: Node                # pure Node holder (works for Control or Node2D)
var _tab_labels_theme: Theme = null
var _content_theme: Theme = null

var _current_index: int = -1
var _instanced_nodes: Array[Node] = []

func _ready() -> void:
	_build_layout()
	_instanced_nodes.resize(tabs.size())
	for i in tabs.size():
		_create_tab_button(i, tabs[i].label)

	_select_tab(0)

func _build_layout() -> void:
	# Left side: vertical list of tab buttons
	_tab_buttons_box = VBoxContainer.new()
	_tab_buttons_box.theme = _tab_labels_theme
	_tab_buttons_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_tab_buttons_box.custom_minimum_size = Vector2(180, 0)  # fixed-ish left width
	add_child(_tab_buttons_box)

	# Right side: a panel that hosts the tab content
	_content_panel = PanelContainer.new()
	_content_panel.theme = _content_theme
	_content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_content_panel)

	# Holder is a plain Node so we can attach either UI (Control) or gameplay (Node2D) scenes.
	# If you ONLY host UI, make this a Control instead.
	_content_holder = Control.new()
	_content_holder.name = "ContentHolder"
	_content_panel.add_child(_content_holder)

func _create_tab_button(index: int, label_text: String) -> void:
	var btn := Button.new()
	btn.text = label_text
	btn.toggle_mode = true
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(func():
		_select_tab(index)
	)
	_tab_buttons_box.add_child(btn)

func _select_tab(index: int) -> void:
	if index < 0 or index >= tabs.size():
		return
	if index == _current_index:
		return

	# Update toggle states (visual feedback)
	for i in _tab_buttons_box.get_child_count():
		var child_btn := _tab_buttons_box.get_child(i)
		if child_btn is Button:
			(child_btn as Button).button_pressed = (i == index)

	# Hide previous content
	_clear_content_holder()

	# Ensure content instance exists (lazy instantiation)
	var node := _instanced_nodes[index]
	if node == null:
		var spec := tabs[index]
		if spec == null or spec.scene == null:
			push_warning("Tab %d has no scene assigned." % index)
			_current_index = index
			return
		node = spec.scene.instantiate()
		_instanced_nodes[index] = node

	# Parent the node under the holder (reparent if needed)
	if node.get_parent() != _content_holder:
		if node.get_parent():
			node.get_parent().remove_child(node)
		_content_holder.add_child(node)

	# If the node is a Control, stretch it in the panel
	if node is Control:
		var ctrl := node as Control
		ctrl.anchor_left = 0.0
		ctrl.anchor_top = 0.0
		ctrl.anchor_right = 1.0
		ctrl.anchor_bottom = 1.0
		ctrl.offset_left = 0.0
		ctrl.offset_top = 0.0
		ctrl.offset_right = 0.0
		ctrl.offset_bottom = 0.0

	_current_index = index

func _clear_content_holder() -> void:
	# Do not free cached nodes; just detach to keep state (lazy reuse).
	for child in _content_holder.get_children():
		_content_holder.remove_child(child)
