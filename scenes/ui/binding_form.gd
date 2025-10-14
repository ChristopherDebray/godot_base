extends Control
class_name OptionsBindings

@export var actions_to_expose: Array[StringName] = [
	"ui_up","ui_down","ui_left","ui_right",
	"ui_accept","ui_cancel","ui_start",
	"ui_focus_next","ui_focus_prev",
	"move_up","move_down","move_left","move_right",
	"use_spell","spell_1","spell_2","spell_3"
]

@onready var rows_container: VBoxContainer = $RowsContainer
@onready var scroll: VScrollBar = $VScrollBar
@onready var btn_reset: Button = $ResetDefaultsButton

const REBIND_ROW = preload("res://scenes/ui/components/rebind_row.tscn")

func _ready() -> void:
	_build_rows()
	btn_reset.pressed.connect(_on_reset_pressed)

func _build_rows() -> void:
	for a in actions_to_expose:
		if not InputMap.has_action(a):
			continue
		var row := REBIND_ROW.instantiate() as RebindRow
		row.action_name = a
		rows_container.add_child(row)

	# initial focus on first row's rebind button
	await get_tree().process_frame
	var first := rows_container.get_child(0)
	if first and first.has_node("%RebindButton"):
		first.get_node("%RebindButton").grab_focus()

func _on_reset_pressed() -> void:
	RebindManager.reset_to_defaults(true)
	_build_rows()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_page_down"):
		scroll.scroll_vertical += 300
	elif event.is_action_pressed("ui_page_up"):
		scroll.scroll_vertical -= 300
