extends Node

enum RESOURCE_TYPE { LIFE }

var current_health: float
var max_health: float

func modify_current_health(amount: float):
	current_health = current_health + amount

func set_player_health(amount: float):
	current_health = amount
	max_health = amount
