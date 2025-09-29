extends Node2D
class_name BaseActionned

enum STATE { ACTIVE, INACTIVE, BROKEN }

@export var state: STATE = STATE.INACTIVE

## @abstract
func toggle_activation():
	if state == STATE.BROKEN:
		return
	pass
