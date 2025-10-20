extends Node2D

@onready var indicator: Sprite2D = $Indicator

const CHEST = preload("res://assets/objects/chest.png")
const QUESTION_MARK = preload("res://assets/objects/question_mark.png")
const COIN = preload("res://assets/objects/coin.png")
const BLOOD = preload("res://assets/objects/blood.png")


func setup(room_type: BaseLevel.ROOM_TYPE):
	var texture
	match room_type:
		BaseLevel.ROOM_TYPE.CHEST:
			texture = CHEST
		BaseLevel.ROOM_TYPE.SHOP:
			texture = COIN
		BaseLevel.ROOM_TYPE.COIN:
			texture = COIN
		BaseLevel.ROOM_TYPE.MYSTERY:
			texture = QUESTION_MARK
		BaseLevel.ROOM_TYPE.BLOOD:
			texture = BLOOD
	
	indicator.texture = texture
