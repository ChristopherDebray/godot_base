extends Node

var projectile: PackedScene

func shoot(_player_ref: Player, shooter_position: Vector2) -> void:
	get_tree().root.add_child(instanciate_projectile(_player_ref, shooter_position))

func instanciate_projectile(_player_ref: Player, shooter_position: Vector2) -> Node:
	var target = _player_ref.global_position
	var projectileInstance = projectile.instantiate()
	projectileInstance.init(target, shooter_position)
	return projectileInstance
