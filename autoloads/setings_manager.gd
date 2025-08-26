class_name SettingsManager
extends Node

signal changed(section: String, key: String, value)

const PATH := "user://settings.cfg"

var data := {
	"audio": {
		"master_volume": 0.8,
		"music_volume": 0.7,
		"sfx_volume": 0.9,
	},
	"video": {
		"fullscreen": false,
		"vsync": true,
		"resolution": Vector2i(1280, 720),
	},
	"gameplay": {
		"camera_shake": true,
		"damage_numbers": true,
	},
	"controls": {
		# on remplira quand on rebinde
	}
}
