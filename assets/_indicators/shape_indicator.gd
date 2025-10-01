extends Node2D
class_name TelegraphPolygon

const FILL_COLOR_ALPHA = 0.35
const OUTLINE_COLOR_ALPHA = 0.9
const FLASH_COLOR_ALPHA = 0.70

@export var shape: Shape2D
@export var outline_width: float = 2.0
@export var circle_segments: int = 48                  # more = smoother circles/capsules

var fill_poly: Polygon2D
var outline_line: Line2D

var fill_color: Color
var outline_color: Color

func _ready() -> void:
	# Create children lazily (keeps scene clean if you add this as script-only)
	fill_poly = Polygon2D.new()
	fill_poly.color = fill_color
	_pulse(self, fill_color)
	add_child(fill_poly)

	outline_line = Line2D.new()
	outline_line.width = outline_width
	outline_line.default_color = outline_color
	outline_line.closed = true
	outline_line.antialiased = true
	add_child(outline_line)

	_rebuild_from_shape()

func _rebuild_from_shape() -> void:
	if shape == null:
		if fill_poly: fill_poly.polygon = PackedVector2Array()
		if outline_line: outline_line.points = PackedVector2Array()
		return

	var pts := _shape_to_points(shape)
	if pts.size() < 2:
		fill_poly.polygon = PackedVector2Array()
		outline_line.points = PackedVector2Array()
		return

	# Apply to children
	fill_poly.polygon = pts
	outline_line.points = pts

# Convert a Shape2D into a closed polygon (CCW)
func _shape_to_points(s: Shape2D) -> PackedVector2Array:
	if s is CircleShape2D:
		var r := (s as CircleShape2D).radius
		return _build_circle_points(Vector2.ZERO, r, circle_segments)

	elif s is RectangleShape2D:
		var size := (s as RectangleShape2D).size
		var hx := size.x * 0.5
		var hy := size.y * 0.5
		var pts := PackedVector2Array()
		pts.append(Vector2(-hx, -hy))
		pts.append(Vector2(hx, -hy))
		pts.append(Vector2(hx, hy))
		pts.append(Vector2(-hx, hy))
		return pts

	elif s is CapsuleShape2D:
		var cap := s as CapsuleShape2D
		return _build_capsule_points(cap.radius, cap.height * 0.5, circle_segments)

	elif s is ConvexPolygonShape2D:
		var pts_convex := (s as ConvexPolygonShape2D).points
		# Assumes the resource points already describe a convex polygon in order.
		return pts_convex

	# Segment and Concave cannot be "filled" trivially.
	# For Segment, you can turn it into a thin rectangle with a given thickness if needed.
	return PackedVector2Array()

# Helpers

func _build_circle_points(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var seg = max(8, segments)
	for i in range(seg):
		var t := float(i) / float(seg) * TAU
		pts.append(center + Vector2(cos(t), sin(t)) * radius)
	return pts

# Capsule oriented along local Y axis, centered on (0,0)
# half_body is half the straight cylinder length (excluding the semicircles)
func _build_capsule_points(radius: float, half_body: float, segments: int) -> PackedVector2Array:
	var seg = max(8, segments)
	var pts := PackedVector2Array()
	var top := Vector2(0, -half_body)
	var bottom := Vector2(0, half_body)

	# Top semicircle CCW from left to right
	for i in range(seg + 1):
		var t := float(i) / float(seg)
		var ang := PI + t * PI
		pts.append(top + Vector2(cos(ang), sin(ang)) * radius)

	# Bottom semicircle CCW from right to left
	for i in range(seg + 1):
		var t := float(i) / float(seg)
		var ang := (1.0 - t) * PI
		pts.append(bottom + Vector2(cos(ang), sin(ang)) * radius)

	return pts

static func generate_telegraph(collision_shape_2d: CollisionShape2D, target_type: AbilityManager.TARGET_TYPE):
	var telegraph := TelegraphPolygon.new()
	var telegraph_colors = get_color_from_type(target_type)
	telegraph.fill_color = telegraph_colors[0]
	telegraph.fill_color.a = FILL_COLOR_ALPHA
	telegraph.outline_color = telegraph_colors[1]
	telegraph.outline_color.a = OUTLINE_COLOR_ALPHA
	telegraph.shape = collision_shape_2d.shape
	#telegraph.global_transform = collision_shape_2d.global_transform
	telegraph.global_position = collision_shape_2d.position

	return telegraph

static func get_color_from_type(target_type: AbilityManager.TARGET_TYPE) -> Array[Color]:
	var new_fill_color: Color
	var new_outline_color: Color

	match target_type:
		AbilityManager.TARGET_TYPE.PLAYER:
			new_fill_color = Color(0, 0, 1)
			new_outline_color = Color(0, 0, 1)
		_:
			new_fill_color = Color(1, 0, 0)
			new_outline_color = Color(1, 0, 0)
	
	return [
		new_fill_color,
		new_outline_color
	]

func _pulse(target, color: Color) -> void:
	var duration = 20
	var tw = create_tween()
	var color_tween = color
	color_tween.a = FLASH_COLOR_ALPHA
	tw.set_loops(ceil(duration / 0.5))
	tw.tween_property(target, "modulate", fill_color, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(target, "modulate", color_tween, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
