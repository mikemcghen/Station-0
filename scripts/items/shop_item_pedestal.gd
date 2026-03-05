extends Area2D

# ---------------------------------------------------------------------------
# Shop Item Pedestal
# Player walks up → prompt appears → press E to buy
# ---------------------------------------------------------------------------

var item:  RunItem = null
var price: int     = 20

var _sold:           bool  = false
var _player_in_range: bool = false
var _prompt_label:   Label = null
var _info_label:     Label = null

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 2   # player layer

	var cs := CollisionShape2D.new()
	var rs := CircleShape2D.new()
	rs.radius = 36.0
	cs.shape  = rs
	add_child(cs)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Item name + price above pedestal
	_info_label          = Label.new()
	_info_label.text     = "%s\n%d SCRAP" % [item.display_name if item else "???", price]
	_info_label.position = Vector2(-48, -56)
	add_child(_info_label)

	# Buy prompt — hidden until player is in range
	_prompt_label          = Label.new()
	_prompt_label.text     = "[E] Buy"
	_prompt_label.position = Vector2(-20, -76)
	_prompt_label.modulate = Color(1.0, 0.9, 0.3)
	_prompt_label.visible  = false
	add_child(_prompt_label)

	queue_redraw()

func _draw() -> void:
	# Pedestal base
	var col := Color(0.25, 0.25, 0.25) if _sold else Color(0.85, 0.70, 0.10)
	draw_rect(Rect2(-14, -14, 28, 28), col)
	# Sold X
	if _sold:
		draw_line(Vector2(-10, -10), Vector2(10, 10), Color(0.5, 0.5, 0.5), 2.0)
		draw_line(Vector2(10, -10),  Vector2(-10, 10), Color(0.5, 0.5, 0.5), 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if _sold or not _player_in_range:
		return
	if event.is_action_pressed("ui_accept"):
		_attempt_purchase()
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and key.physical_keycode == KEY_E:
			_attempt_purchase()

func _attempt_purchase() -> void:
	if RunManager.run_credits < price:
		_flash_no_funds()
		return

	RunManager.spend_credits(price)

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	RunManager.collect_item(item)
	if item.heal_on_pickup > 0.0:
		player.stats.heal(item.heal_on_pickup)
	player.stats.recalculate()
	EventBus.player_health_changed.emit(player.stats.current_health, player.stats.max_health)

	_sold            = true
	_player_in_range = false
	if _prompt_label:
		_prompt_label.visible = false
	if _info_label:
		_info_label.text = "%s\n[SOLD]" % (item.display_name if item else "???")
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not _sold:
		_player_in_range = true
		if _prompt_label:
			_prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if _prompt_label:
			_prompt_label.visible = false

func _flash_no_funds() -> void:
	if _prompt_label == null:
		return
	_prompt_label.text    = "Need %d SCRAP" % price
	_prompt_label.modulate = Color(1.0, 0.2, 0.2)
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(self) and not _sold:
		_prompt_label.text    = "[E] Buy"
		_prompt_label.modulate = Color(1.0, 0.9, 0.3)