extends VBoxContainer


# Window project settings:
#  - Stretch mode is set to `canvas_items` (`2d` in Godot 3.x)
#  - Stretch aspect is set to `expand`
@onready var world_environment := $WorldEnvironment
@onready var directional_light := $Node3D/DirectionalLight3D
@onready var camera := $Node3D/Camera3D
@onready var fps_label := $FPSLabel
@onready var resolution_label := $ResolutionLabel

var counter := 0.0

# When the screen changes size, we need to update the 3D
# viewport quality setting. If we don't do this, the viewport will take
# the size from the main viewport.
var viewport_start_size := Vector2(
	ProjectSettings.get_setting(&"display/window/size/viewport_width"),
	ProjectSettings.get_setting(&"display/window/size/viewport_height")
)

var is_compatibility := false


func _ready() -> void:
	get_viewport().size_changed.connect(update_resolution_label)
	update_resolution_label()

	# Disable V-Sync to uncap framerate on supported platforms. This makes performance comparison
	# easier on high-end machines that easily reach the monitor's refresh rate.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _process(delta: float) -> void:
	pass
	#counter += delta
	# Hide FPS label until it's initially updated by the engine (this can take up to 1 second).
	#fps_label.visible = counter >= 1.0
	#fps_label.text = "%d FPS (%.2f mspf)" % [Engine.get_frames_per_second(), 1000.0 / Engine.get_frames_per_second()]
	# Color FPS counter depending on framerate.
	# The Gradient resource is stored as metadata within the FPSLabel node (accessible in the inspector).
	#fps_label.modulate = fps_label.get_meta("gradient").sample(remap(Engine.get_frames_per_second(), 0, 180, 0.0, 1.0))

func update_resolution_label() -> void:
	pass
	#var viewport_render_size = get_viewport().size * get_viewport().scaling_3d_scale
	#resolution_label.text = "3D viewport resolution: %d × %d (%d%%)" \
			#% [viewport_render_size.x, viewport_render_size.y, round(get_viewport().scaling_3d_scale * 100)]

# Video settings.
func _on_ui_scale_option_button_item_selected(index: int) -> void:
	# For changing the UI, we take the viewport size, which we set in the project settings.
	var new_size := viewport_start_size
	if index == 0: # Smaller (66%)
		new_size *= 1.5
	elif index == 1: # Small (80%)
		new_size *= 1.25
	elif index == 2: # Medium (100%) (default)
		new_size *= 1.0
	elif index == 3: # Large (133%)
		new_size *= 0.75
	elif index == 4: # Larger (200%)
		new_size *= 0.5
	get_tree().root.set_content_scale_size(new_size)

func _on_filter_option_button_item_selected(index: int) -> void:
	# Viewport scale mode setting.
	if index == 0: # Bilinear (Fastest)
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		# FSR Sharpness is only effective when the scaling mode is FSR 1.0 or 2.2.
		%FSRSharpnessLabel.visible = false
		%FSRSharpnessSlider.visible = false
	elif index == 1: # FSR 1.0 (Fast)
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
		# FSR Sharpness is only effective when the scaling mode is FSR 1.0 or 2.2.
		%FSRSharpnessLabel.visible = true
		%FSRSharpnessSlider.visible = true
	elif index == 2: # FSR 2.2 (Fast)
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
		# FSR Sharpness is only effective when the scaling mode is FSR 1.0 or 2.2.
		%FSRSharpnessLabel.visible = true
		%FSRSharpnessSlider.visible = true


func _on_fsr_sharpness_slider_value_changed(value: float) -> void:
	# Lower FSR sharpness values result in a sharper image.
	# Invert the slider so that higher values result in a sharper image,
	# which is generally expected from users.
	get_viewport().fsr_sharpness = 2.0 - value


func _on_vsync_option_button_item_selected(index: int) -> void:
	# Vsync is enabled by default.
	# Vertical synchronization locks framerate and makes screen tearing not visible at the cost of
	# higher input latency and stuttering when the framerate target is not met.
	# Adaptive V-Sync automatically disables V-Sync when the framerate target is not met, and enables
	# V-Sync otherwise. This prevents stuttering and reduces input latency when the framerate target
	# is not met, at the cost of visible tearing.
	if index == 0: # Disabled (default)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	elif index == 1: # Adaptive
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
	elif index == 2: # Enabled
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)

func _on_msaa_option_button_item_selected(index: int) -> void:
	# Multi-sample anti-aliasing. High quality, but slow. It also does not smooth out the edges of
	# transparent (alpha scissor) textures.
	if index == 0: # Disabled (default)
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	elif index == 1: # 2×
		get_viewport().msaa_3d = Viewport.MSAA_2X
	elif index == 2: # 4×
		get_viewport().msaa_3d = Viewport.MSAA_4X
	elif index == 3: # 8×
		get_viewport().msaa_3d = Viewport.MSAA_8X


func _on_taa_option_button_item_selected(index: int) -> void:
	# Temporal antialiasing. Smooths out everything including specular aliasing, but can introduce
	# ghosting artifacts and blurring in motion. Moderate performance cost.
	get_viewport().use_taa = index == 1

func _on_fxaa_option_button_item_selected(index: int) -> void:
	# Fast approximate anti-aliasing. Much faster than MSAA (and works on alpha scissor edges),
	# but blurs the whole scene rendering slightly.
	get_viewport().screen_space_aa = int(index == 1) as Viewport.ScreenSpaceAA

func _on_fullscreen_option_button_item_selected(index: int) -> void:
	# To change between window, fullscreen and other window modes,
	# set the root mode to one of the options of Window.MODE_*.
	# Other modes are maximized and minimized.
	if index == 0: # Disabled (default)
		get_tree().root.set_mode(Window.MODE_WINDOWED)
	elif index == 1: # Fullscreen
		get_tree().root.set_mode(Window.MODE_FULLSCREEN)
	elif index == 2: # Exclusive Fullscreen
		get_tree().root.set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)

# Effect settings.
func _on_brightness_slider_value_changed(value: float) -> void:
	# This is a setting that is attached to the environment.
	# If your game requires you to change the environment,
	# then be sure to run this function again to make the setting effective.
	# The slider value is clamped between 0.5 and 4.
	world_environment.environment.set_adjustment_brightness(value)
