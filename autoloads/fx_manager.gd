extends Node

const FX_LIFETIME_SECONDS = .8

const DEATH_CLOUD := preload("res://scenes/fx/death/death_cloud.tscn")

func _ready() -> void:
	SignalManager.died.connect(spawn_death_fx)

func spawn_death_fx(target: Damageable):
	var fx_scene: Node2D = DEATH_CLOUD.instantiate()
	var fx = fx_scene.get_node('Particules') as CPUParticles2D
	fx.global_position = target.global_position
	fx.visible = true
	fx.emitting = true
	fx.restart()

	# auto-release after lifetime
	var lifetime := FX_LIFETIME_SECONDS + 0.05
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = lifetime
	timer.autostart = true
	fx.add_child(timer)
	timer.timeout.connect(func():
		fx.emitting = false
		fx_scene.queue_free()
	)
	get_tree().current_scene.get_node("YsortLayer/Npcs").add_child(fx_scene)
