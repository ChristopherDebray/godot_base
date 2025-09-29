extends Node2D
## An interactive is something that will trigger / interact other element, a button, a pressure plate for instance
class_name BaseInteractive

@export var actionneds: Array[BaseActionned]

func interact():
	for actionned in actionneds:
		actionned.toggle_activation()
