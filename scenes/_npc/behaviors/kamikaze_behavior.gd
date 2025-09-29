class_name KamikazeBehavior
extends NpcBehavior

# Kamikaze wants to collide: push stop ranges very low.
@export var impact_distance: float = 6.0

func _init() -> void:
	preferred_range = 20.0
	stop_range = 0.0
	strafe_bias = 0.0
	jitter = 0.0

func compute_nav_goal(npc: BaseNpc) -> Vector2:
	# Goal is the target itself
	return compute_target(npc)

func path_weight(npc: BaseNpc, dist_to_target: float) -> float:
	# Always follow path hard (no kiting)
	return 1.0

func desired_distances() -> Dictionary:
	return {
		"target_desired_distance": impact_distance,
		"path_desired_distance": impact_distance
	}

func steering(npc: BaseNpc, delta: float, path_velocity: Vector2) -> Vector2:
	# No local steering; pure pathing
	return Vector2.ZERO
