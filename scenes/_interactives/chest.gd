extends ManualInteractive

@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D

var _relic_selection_ui: Control

func setup(relic_selection_ui: Control):
	_relic_selection_ui = relic_selection_ui

func interact():
	animated_sprite_2d.frame = 2
	cpu_particles_2d.emitting = false
	MenuManager.push(_relic_selection_ui)
	_relic_selection_ui.roll_relics()
	_relic_selection_ui.show()
	get_tree().paused = true
