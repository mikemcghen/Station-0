extends Area2D

var value: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

# Placeholder visual — gold circle
func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.8, 0.1))
	draw_arc(Vector2.ZERO, 5.0, 0, TAU, 16, Color(1.0, 1.0, 0.4), 1.0)

func _physics_process(delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var pstats: Node = player.get_node_or_null("Stats")
	if pstats == null or not pstats.get("scrap_magnet"):
		return
	var dist: float = global_position.distance_to(player.global_position)
	if dist <= float(pstats.get("magnet_radius")) and dist > 1.0:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		global_position += dir * 240.0 * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		RunManager.earn_credits(value)
		queue_free()