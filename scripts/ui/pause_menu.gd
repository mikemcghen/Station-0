extends CanvasLayer

# ---------------------------------------------------------------------------
# Pause menu — opened with Escape during a run
# Buttons: Resume | Return to Hub | Quit to Desktop
# ---------------------------------------------------------------------------

var _root: Control = null

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

func _build_ui() -> void:
	_root = ColorRect.new()
	_root.color              = Color(0, 0, 0, 0.65)
	_root.anchor_right       = 1.0
	_root.anchor_bottom      = 1.0
	_root.offset_right       = 0.0
	_root.offset_bottom      = 0.0
	_root.mouse_filter       = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var vbox             := VBoxContainer.new()
	vbox.anchor_left      = 0.5
	vbox.anchor_top       = 0.5
	vbox.anchor_right     = 0.5
	vbox.anchor_bottom    = 0.5
	vbox.offset_left      = -120.0
	vbox.offset_top       = -80.0
	vbox.offset_right     =  120.0
	vbox.offset_bottom    =  80.0
	vbox.add_theme_constant_override("separation", 16)
	_root.add_child(vbox)

	_add_button(vbox, "RESUME",          _on_resume)
	_add_button(vbox, "RETURN TO HUB",   _on_return_to_hub)
	_add_button(vbox, "QUIT TO DESKTOP", _on_quit)

func _add_button(parent: Node, text: String, callback: Callable) -> void:
	var btn        := Button.new()
	btn.text        = text
	btn.custom_minimum_size = Vector2(240, 48)
	btn.pressed.connect(callback)
	parent.add_child(btn)

# ---------------------------------------------------------------------------
# Input — Escape toggles open/close
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_on_resume()
		else:
			_open()

func _open() -> void:
	visible = true
	get_tree().paused = true

# ---------------------------------------------------------------------------
# Button callbacks
# ---------------------------------------------------------------------------
func _on_resume() -> void:
	visible = false
	get_tree().paused = false

func _on_return_to_hub() -> void:
	visible = false
	get_tree().paused = false
	RunManager.end_run(true)

func _on_quit() -> void:
	get_tree().quit()