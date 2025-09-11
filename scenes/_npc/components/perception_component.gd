extends Area2D
class_name PerceptionComponent

var npc: BaseNpc
signal candidate_entered(dmg: Damageable)
signal candidate_exited(dmg: Damageable)

func setup(owner: BaseNpc) -> void:
	npc = owner
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func set_detection_for(faction: int, filter: int) -> void:
	TargetManager.set_detection_mask_for(faction, filter, self)

func _on_body_entered(body: Node) -> void:
	if body != npc and body is Damageable:
		emit_signal("candidate_entered", body)

func _on_body_exited(body: Node) -> void:
	if body is Damageable:
		emit_signal("candidate_exited", body)
