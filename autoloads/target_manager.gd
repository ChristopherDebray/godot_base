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

# Decide what this Area2D should detect, based on the caller's faction + target filter
func set_detection_mask_for(faction: int, filter: int, area: Area2D) -> void:
	var masks: Array[int] = []

	match filter:
		AbilityManager.TARGET_TYPE.ENEMY:
			# Opponents only
			if faction == Damageable.FACTION.ENEMY:
				masks = [DETECTION_MASKS["PLAYER"]]
			else:
				masks = [DETECTION_MASKS["NPC"]]

		AbilityManager.TARGET_TYPE.PLAYER:
			# Allies only (keep enum naming for compatibility)
			if faction == Damageable.FACTION.ENEMY:
				masks = [DETECTION_MASKS["NPC"]]
			else:
				masks = [DETECTION_MASKS["PLAYER"]]

		AbilityManager.TARGET_TYPE.ALL:
			masks = [DETECTION_MASKS["PLAYER"], DETECTION_MASKS["NPC"]]

		_:
			masks = []

	_set_collision_masks(area, masks)

func _set_collision_masks(area: Area2D, mask_bits: Array[int]) -> void:
	# Clear all mask bits
	for i in range(1, 33):
		area.set_collision_mask_value(i, false)
	# Apply new ones
	for bit in mask_bits:
		area.set_collision_mask_value(bit, true)

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
