extends Area2D

var part: BodyPartData = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and part != null:
		AudioManager.play("item_pickup")
		UpgradeManager.acquire_part(part)
		_show_pickup_label()
		queue_free()

func _show_pickup_label() -> void:
	var lbl        := Label.new()
	lbl.text        = part.display_name
	lbl.position    = global_position + Vector2(-40, -20)
	lbl.modulate    = Color(1.0, 0.85, 0.3)  # gold for body parts
	get_tree().current_scene.add_child(lbl)
	var tween := lbl.create_tween()
	tween.tween_property(lbl, "position", lbl.position + Vector2(0, -60), 1.2)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tween.tween_callback(lbl.queue_free)
