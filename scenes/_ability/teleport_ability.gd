extends BaseAbility
class_name TeleportAbility

@export var offset_local: Vector2 = Vector2(200, 0)
@export var wall_margin: float = 6.0
@export var use_ray_safety: bool = true

func on_impact_start() -> void:
	if not sender or not is_instance_valid(sender):
		on_ability_timeout(); return

	var body := sender as Node2D
	var from := body.global_position
	var to := from + offset_local

	if use_ray_safety:
		var space := get_world_2d().direct_space_state
		var params := PhysicsRayQueryParameters2D.create(from, to)
		params.exclude = [body]
		params.collide_with_areas = false
		var hit := space.intersect_ray(params)
		if hit:
			var dir := (to - from).normalized()
			to = hit.position - dir * wall_margin

	body.global_position = to
	on_ability_timeout()
