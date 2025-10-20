extends Node2D
## An interactive is something that will trigger / interact other element, a button, a pressure plate for instance
class_name BaseInteractive

@export var actionneds: Array[BaseActionned]

@onready var area_2d: Area2D = $Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func interact():
	for actionned in actionneds:
		actionned.toggle_activation()
