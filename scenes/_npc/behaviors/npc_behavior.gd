class_name NpcBehavior
extends Resource

## Preferred range to use it's abilities
@export var preferred_range: float = 160.0
## Distance to stop before the player
@export var stop_range: float = 120.0
## Strafe variation
@export var strafe_bias: float = 0.6
## Seconds between variations
@export var jitter: float = 0.25

## @abstract: Returns the position to go to, by default returns the player position
func compute_target(npc: BaseNpc) -> Vector2:
	if npc._ability_target:
		return npc._ability_target.global_position
	return npc.global_position

## @abstract: Returns the velocity used to move by default returns a simple chase velocity
func compute_desired_velocity(npc: BaseNpc, delta: float) -> Vector2:
	var target := compute_target(npc)
	return (target - npc.global_position).normalized() * npc.SPEED[npc.state]

## @abstract: used to indicate if npc can ability (by default check if npc is in range)
func try_ability(npc: BaseNpc, delta: float) -> bool:
	return is_in_ability_range(npc)

## @abstract: Returns true if the player is in range of ability
func is_in_ability_range(npc: BaseNpc) -> bool:
	var player = npc._ability_target
	if player == null:
		return false
	var dist := npc.global_position.distance_to(player.global_position)
	return dist <= preferred_range
