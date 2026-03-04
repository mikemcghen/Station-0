extends Area2D

var item: RunItem = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

# Placeholder visual — cyan diamond
func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -14), Vector2(10, 0), Vector2(0, 14), Vector2(-10, 0)
	]), Color(0.2, 0.9, 0.85))
	draw_arc(Vector2.ZERO, 16.0, 0, TAU, 24, Color(0.5, 1.0, 0.95), 1.5)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or item == null:
		return
	RunManager.collect_item(item)
	if item.heal_on_pickup > 0.0:
		body.stats.heal(item.heal_on_pickup)
	body.stats.recalculate()
	EventBus.player_health_changed.emit(body.stats.current_health, body.stats.max_health)
	_show_pickup_label()
	queue_free()

func _show_pickup_label() -> void:
	var lbl        := Label.new()
	lbl.text        = item.display_name
	lbl.position    = global_position + Vector2(-40, -20)
	lbl.modulate    = Color(0.2, 1.0, 0.85)
	get_tree().current_scene.add_child(lbl)
	var tween := lbl.create_tween()
	tween.tween_property(lbl, "position", lbl.position + Vector2(0, -60), 1.2)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tween.tween_callback(lbl.queue_free)
