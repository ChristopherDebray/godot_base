extends Node

enum TARGET_TYPE { ENEMY, PLAYER, ALL }

const DETECTION_MASKS = {
	'PLAYER': 3,
	'NPC': 4,
}

const DETECTION_MASKS_GROUPS = {
	TARGET_TYPE.PLAYER: [DETECTION_MASKS.PLAYER],
	TARGET_TYPE.ENEMY: [DETECTION_MASKS.NPC],
	TARGET_TYPE.ALL: [DETECTION_MASKS.PLAYER, DETECTION_MASKS.NPC]
}

func set_detection_mask_group(target_type: TARGET_TYPE, detection_field: Area2D):
	var detection_masks = get_detection_mask_group(target_type)
	set_collision_masks(detection_masks, detection_field)

func get_detection_mask_group(target_type: TARGET_TYPE):
	return DETECTION_MASKS_GROUPS[target_type]

func set_collision_masks(collision_masks: Array, detection_field: Area2D):
	reset_collision_masks(detection_field)
	
	for n in collision_masks:
		detection_field.set_collision_mask_value(n, true)

func reset_collision_masks(area2d: Area2D):
	for n in range(1, 32):
		area2d.set_collision_mask_value(n, false)
