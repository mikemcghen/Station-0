extends Area2D

var value: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

# Placeholder visual — gold circle
func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.8, 0.1))
	draw_arc(Vector2.ZERO, 5.0, 0, TAU, 16, Color(1.0, 1.0, 0.4), 1.0)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		UpgradeManager.hub_credits += value
		EventBus.credits_changed.emit(UpgradeManager.hub_credits)
		queue_free()
