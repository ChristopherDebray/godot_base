extends ZoneInteractive

var quantity: int
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	quantity = rng.randi_range(1, 10)

func _on_area_2d_body_entered(body: Node2D) -> void:
	super._on_area_2d_body_entered(body)
	#SoundManager.play_tag_at("spell_cast", BEAR_TRAP, global_position, -4.0)
	interact()
	queue_free()

func interact():
	GameManager.add_blood(quantity)
