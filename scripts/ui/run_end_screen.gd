extends CanvasLayer

# ---------------------------------------------------------------------------
# Run End Screen
# Instantiated by GameManager on run_ended. Call show_result(bool) after
# adding to tree. Calls GameManager.go_to_hub() when ready.
# ---------------------------------------------------------------------------

const FADE_IN_TIME  := 0.3
const FADE_OUT_TIME := 0.3
const DEATH_HOLD    := 2.5

var _root: Control  = null
var _bg:   ColorRect = null

func _ready() -> void:
	layer        = 10
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_result(reached_hub: bool) -> void:
	if reached_hub:
		_show_victory()
	else:
		_show_death()


# ---------------------------------------------------------------------------
# Death screen — auto-advances after DEATH_HOLD seconds
# ---------------------------------------------------------------------------
func _show_death() -> void:
	_build_root(Color(0, 0, 0, 0.85))

	_add_label("SYSTEMS OFFLINE", 36, Vector2(0, -80))
	_add_label("FLOOR %d" % RunManager.current_floor, 20, Vector2(0, 0))
	_add_label("ALL RUN DATA LOST", 16, Vector2(0, 40))

	_fade_in()
	await get_tree().create_timer(DEATH_HOLD).timeout
	_fade_out_then_hub()


# ---------------------------------------------------------------------------
# Victory screen — player must click to continue
# ---------------------------------------------------------------------------
func _show_victory() -> void:
	_build_root(Color(0, 0, 0, 0.75))

	_add_label("RUN COMPLETE", 36, Vector2(0, -100))
	_add_label("FLOOR %d CLEARED" % RunManager.current_floor, 20, Vector2(0, -40))
	_add_label("SCRAP RETURNED:  %d" % UpgradeManager.wallet_credits, 18, Vector2(0, 10))

	var btn        := Button.new()
	btn.text        = "RETURN TO HUB"
	btn.position    = Vector2(-80, 70)
	btn.pressed.connect(_fade_out_then_hub)
	_root.add_child(btn)

	_fade_in()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _build_root(bg_color: Color) -> void:
	if _root:
		_root.queue_free()

	_bg              = ColorRect.new()
	_bg.color         = bg_color
	_bg.anchor_right  = 1.0
	_bg.anchor_bottom = 1.0
	_bg.mouse_filter  = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_CENTER)
	_bg.add_child(_root)


func _add_label(text: String, font_size: int, offset: Vector2) -> void:
	var lbl                         := Label.new()
	lbl.text                         = text
	lbl.horizontal_alignment         = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.position                     = offset + Vector2(-200, 0)
	lbl.custom_minimum_size          = Vector2(400, 0)
	_root.add_child(lbl)


func _fade_in() -> void:
	_bg.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_bg, "modulate:a", 1.0, FADE_IN_TIME)


func _fade_out_then_hub() -> void:
	var tw := create_tween()
	tw.tween_property(_bg, "modulate:a", 0.0, FADE_OUT_TIME)
	tw.tween_callback(func(): GameManager.go_to_hub())
