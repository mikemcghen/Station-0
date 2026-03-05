extends CanvasLayer

# ---------------------------------------------------------------------------
# Layout constants (screen space: 1920 x 1080)
# ---------------------------------------------------------------------------
const SCREEN_W   := 1920.0
const SCREEN_H   := 1080.0
const PANEL_W    := 620.0
const PANEL_H    := 500.0
const LINE_H     := 36.0
const LIST_PAD_X := 24.0
const LIST_PAD_Y := 60.0

const BG_COLOR       := Color(0.06, 0.07, 0.12, 0.94)
const CURSOR_COLOR   := Color(0.9, 0.85, 0.3, 1)
const NORMAL_COLOR   := Color(0.75, 0.75, 0.85, 1)
const EQUIPPED_COLOR := Color(0.4, 0.9, 0.6, 1)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _items:       Array = []         # Array[BodyPartData] — sorted by slot
var _cursor:      int   = 0
var _item_labels: Array = []         # Array[Label]

# ---------------------------------------------------------------------------
# UI nodes (built once in _ready)
# ---------------------------------------------------------------------------
var _bg:        Polygon2D
var _title_lbl: Label
var _hint_lbl:  Label
var _list_root: Node2D   # parent for item labels (positioned in screen space)

# ---------------------------------------------------------------------------
# Boot
# ---------------------------------------------------------------------------
func _ready() -> void:
	_build_static_ui()
	hide()


func _build_static_ui() -> void:
	var cx := SCREEN_W / 2.0
	var cy := SCREEN_H / 2.0
	var hw := PANEL_W / 2.0
	var hh := PANEL_H / 2.0

	# Background panel
	_bg          = Polygon2D.new()
	_bg.polygon  = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2( hw,  hh), Vector2(-hw, hh),
	])
	_bg.color    = BG_COLOR
	_bg.position = Vector2(cx, cy)
	add_child(_bg)

	# Title
	_title_lbl          = Label.new()
	_title_lbl.text     = "— ARMORY —"
	_title_lbl.position = Vector2(cx - 60, cy - hh + 14)
	add_child(_title_lbl)

	# Hint bar
	_hint_lbl          = Label.new()
	_hint_lbl.text     = "[↑↓] Navigate   [Enter] Equip   [Esc] Close"
	_hint_lbl.position = Vector2(cx - hw + LIST_PAD_X, cy + hh - 30)
	add_child(_hint_lbl)

	# Container node for item labels
	_list_root          = Node2D.new()
	_list_root.position = Vector2(cx - hw + LIST_PAD_X, cy - hh + LIST_PAD_Y)
	add_child(_list_root)


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_up"):
		_cursor = wrapi(_cursor - 1, 0, maxi(1, _items.size()))
		_refresh_labels()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_cursor = wrapi(_cursor + 1, 0, maxi(1, _items.size()))
		_refresh_labels()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_equip_selected()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Open — call from hub.gd
# ---------------------------------------------------------------------------
func open() -> void:
	_rebuild_items()
	_cursor = 0
	_refresh_labels()
	show()


# ---------------------------------------------------------------------------
# Rebuild item list from UpgradeManager
# ---------------------------------------------------------------------------
func _rebuild_items() -> void:
	_items.clear()

	for path: String in UpgradeManager.acquired_part_paths:
		if path == "":
			continue
		var part := load(path) as BodyPartData
		if part:
			_items.append(part)

	# Sort by slot order so the list groups naturally
	var slot_order := UpgradeManager.SLOTS
	_items.sort_custom(func(a, b): return slot_order.find(a.slot) < slot_order.find(b.slot))

	# Destroy old labels
	for lbl: Label in _item_labels:
		lbl.queue_free()
	_item_labels.clear()

	# Create one label per item
	for i in _items.size():
		var lbl      := Label.new()
		lbl.position  = Vector2(0, i * LINE_H)
		_list_root.add_child(lbl)
		_item_labels.append(lbl)


func _refresh_labels() -> void:
	for i in _item_labels.size():
		var part: BodyPartData    = _items[i]
		var equipped_path: String = UpgradeManager.equipped_parts.get(part.slot, "")
		var is_equipped           := equipped_path == part.resource_path
		var is_cursor             := i == _cursor

		var slot_tag   := "[%s]" % part.slot.to_upper()
		var equip_tag  := " ✓" if is_equipped else ""
		var lbl: Label = _item_labels[i]
		lbl.text = ("%s %s%s" % [slot_tag, part.display_name, equip_tag]).lstrip("")

		if is_cursor:
			lbl.add_theme_color_override("font_color", CURSOR_COLOR)
		elif is_equipped:
			lbl.add_theme_color_override("font_color", EQUIPPED_COLOR)
		else:
			lbl.add_theme_color_override("font_color", NORMAL_COLOR)


# ---------------------------------------------------------------------------
# Equip the part under the cursor
# ---------------------------------------------------------------------------
func _equip_selected() -> void:
	if _items.is_empty():
		return
	var part: BodyPartData = _items[_cursor]
	UpgradeManager.equip_part(part)
	SaveManager.save()
	_refresh_labels()
