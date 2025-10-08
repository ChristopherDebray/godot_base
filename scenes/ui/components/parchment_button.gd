extends TextureButton

@onready var label: Label = $Label

@export var label_text: String

func _ready() -> void:
	label.text = label_text
