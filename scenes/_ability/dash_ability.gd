extends BaseAbility
class_name DashAbility

@export var dash_speed: float = 1000.0
@export var dash_distance: float = 200.0
@export var stop_on_collision: bool = true
@export var keep_facing: bool = true

var _dir: Vector2 = Vector2.ZERO
var _npc: BaseNpc
var _body: CharacterBody2D

func _ready() -> void:
	super._ready()

func init(ability_data: AbilityData, ctx: AimContext) -> void:
	_dir = ctx.desired_dir.normalized()
	duration = dash_distance / max(1.0, dash_speed) + 0.02

func on_impact_start() -> void:
	if sender is BaseNpc: _npc = sender
	if sender is CharacterBody2D: _body = sender
	if not _npc or not _body:
		on_ability_timeout()
		return

	if keep_facing:
		_npc.animated_sprite_2d.flip_h = (_dir.x < -0.01)

	_npc.locomotion.begin_forced_move(_body, _dir, dash_speed, dash_distance, stop_on_collision)

func on_hit() -> void:
	if stop_on_collision and _npc:
		_npc.locomotion.interrupt_forced_move()
	on_ability_timeout()

func _on_forced_done(body: CharacterBody2D, interrupted: bool) -> void:
	if body != _body:
		return  # ignorer les dashes des autres NPC
	if SignalManager.forced_motion_finished.is_connected(_on_forced_done):
		SignalManager.forced_motion_finished.disconnect(_on_forced_done)
	on_ability_timeout()
