extends Control

@onready var icon: TextureRect = $Panel/Icon

var icon_texture: AtlasTexture

func _ready():
	icon.texture = icon_texture
