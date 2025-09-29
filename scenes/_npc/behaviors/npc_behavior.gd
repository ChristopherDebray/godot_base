# Base
class_name NpcBehavior
extends Resource

@export var preferred_range: float = 160.0
@export var stop_range: float = 120.0
@export var strafe_bias: float = 0.6
@export var jitter: float = 0.25

func compute_target(npc: BaseNpc) -> Vector2:
	if npc._ability_target and is_instance_valid(npc._ability_target):
		return npc._ability_target.global_position
	return npc.global_position

# 2) Local steering (optional) to mix with path velocity
func steering(npc: BaseNpc, delta: float, path_velocity: Vector2) -> Vector2:
	return Vector2.ZERO

func try_ability(npc: BaseNpc, delta: float) -> bool:
	return is_in_ability_range(npc)

func is_in_ability_range(npc: BaseNpc) -> bool:
	var target := npc._ability_target
	if target == null or not is_instance_valid(target):
		return false
	return npc.global_position.distance_to(target.global_position) <= preferred_range
