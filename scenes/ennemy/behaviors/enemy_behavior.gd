class_name EnemyBehavior
extends Resource

## Preferred range mostly for attacks
@export var preferred_range: float = 160.0
## Distance to stop before touching the player
@export var stop_range: float = 120.0
## Strafe variation
@export var strafe_bias: float = 0.6
## Seconds between variations
@export var jitter: float = 0.25

## @abstract: Returns the position to go to, by default returns the player position
func compute_target(enemy: BaseEnemy) -> Vector2:
	if enemy._attack_target:
		return enemy._attack_target.global_position
	return enemy.global_position

## @abstract: Returns the velocity used to move by default returns a simple chase velocity
func compute_desired_velocity(enemy: BaseEnemy, delta: float) -> Vector2:
	var target := compute_target(enemy)
	return (target - enemy.global_position).normalized() * enemy.SPEED[enemy.state]

## @abstract: used to indicate if enemy can attack (by default check if enemy is in range)
func try_attack(enemy: BaseEnemy, delta: float) -> bool:
	return is_in_attack_range(enemy)

## @abstract: Returns true if the player is in range of attack
func is_in_attack_range(enemy: BaseEnemy) -> bool:
	var player = enemy._attack_target
	if player == null:
		return false
	var dist := enemy.global_position.distance_to(player.global_position)
	return dist <= preferred_range
