extends Node2D
class_name StationDoor

# Station door for floor transitions - bulkhead/airlock style visuals
# Can be decorative (entry doors) or functional (exit doors with triggers)

signal door_entered(body: Node)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const DOOR_WIDTH := 100.0
const DOOR_HEIGHT := 120.0
const FRAME_THICKNESS := 16.0
const PANEL_GAP := 4.0  # gap between door panels when open

# Colors
const FRAME_COLOR := Color(0.25, 0.25, 0.32)  # dark metal frame
const PANEL_COLOR := Color(0.35, 0.32, 0.28)  # door panel (closed)
const PANEL_OPEN_COLOR := Color(0.2, 0.2, 0.25)  # recessed panel (open)
const LIGHT_OFF := Color(0.3, 0.15, 0.15)  # indicator off
const LIGHT_LOCKED := Color(0.9, 0.2, 0.2)  # red locked
const LIGHT_UNLOCKED := Color(0.2, 0.9, 0.3)  # green unlocked
const EXIT_LIGHT := Color(0.2, 0.95, 0.4)  # bright green exit

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
enum DoorType { ENTRY, SECTOR_EXIT, EVACUATION_EXIT }

var door_type: DoorType = DoorType.ENTRY
var sector_label: String = ""  # "SECTOR 2", "SECTOR 3", or "EXIT"
var is_functional: bool = false  # if true, has trigger area

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _is_open: bool = false
var _left_panel: Polygon2D = null
var _right_panel: Polygon2D = null
var _indicator_light: Polygon2D = null
var _label: Label = null
var _trigger_area: Area2D = null

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
func setup_entry_door() -> void:
	# Decorative open door - shows "you came from here"
	door_type = DoorType.ENTRY
	is_functional = false
	_build_frame()
	_build_panels()
	_build_indicator()
	open()  # entry doors are always open

func setup_sector_exit(sector_num: int) -> void:
	# Sector transition door - "SECTOR 2" or "SECTOR 3"
	door_type = DoorType.SECTOR_EXIT
	sector_label = "SECTOR %d" % sector_num
	is_functional = true
	_build_frame()
	_build_panels()
	_build_indicator()
	_build_label()
	_build_trigger()
	close()  # starts closed until boss dies

func setup_evacuation_exit() -> void:
	# Final exit after Hivemind - green EXIT lighting
	door_type = DoorType.EVACUATION_EXIT
	sector_label = "EXIT"
	is_functional = true
	_build_frame()
	_build_panels()
	_build_indicator()
	_build_label()
	_build_trigger()
	close()  # starts closed until boss dies

# ---------------------------------------------------------------------------
# Build components
# ---------------------------------------------------------------------------
func _build_frame() -> void:
	# Outer frame - bulkhead style
	var frame := Polygon2D.new()
	var hw := DOOR_WIDTH / 2.0 + FRAME_THICKNESS
	var hh := DOOR_HEIGHT / 2.0 + FRAME_THICKNESS
	var inner_hw := DOOR_WIDTH / 2.0
	var inner_hh := DOOR_HEIGHT / 2.0

	# Outer rectangle with inner cutout (using polygon)
	# Top frame
	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, -inner_hh), Vector2(-hw, -inner_hh)
	])
	top.color = FRAME_COLOR
	add_child(top)

	# Bottom frame
	var bottom := Polygon2D.new()
	bottom.polygon = PackedVector2Array([
		Vector2(-hw, inner_hh), Vector2(hw, inner_hh),
		Vector2(hw, hh), Vector2(-hw, hh)
	])
	bottom.color = FRAME_COLOR
	add_child(bottom)

	# Left frame
	var left := Polygon2D.new()
	left.polygon = PackedVector2Array([
		Vector2(-hw, -inner_hh), Vector2(-inner_hw, -inner_hh),
		Vector2(-inner_hw, inner_hh), Vector2(-hw, inner_hh)
	])
	left.color = FRAME_COLOR
	add_child(left)

	# Right frame
	var right := Polygon2D.new()
	right.polygon = PackedVector2Array([
		Vector2(inner_hw, -inner_hh), Vector2(hw, -inner_hh),
		Vector2(hw, inner_hh), Vector2(inner_hw, inner_hh)
	])
	right.color = FRAME_COLOR
	add_child(right)

func _build_panels() -> void:
	# Two sliding door panels
	var panel_w := DOOR_WIDTH / 2.0 - PANEL_GAP
	var panel_h := DOOR_HEIGHT
	var hh := panel_h / 2.0

	_left_panel = Polygon2D.new()
	_left_panel.polygon = PackedVector2Array([
		Vector2(-panel_w, -hh), Vector2(0, -hh),
		Vector2(0, hh), Vector2(-panel_w, hh)
	])
	_left_panel.color = PANEL_COLOR
	add_child(_left_panel)

	_right_panel = Polygon2D.new()
	_right_panel.polygon = PackedVector2Array([
		Vector2(0, -hh), Vector2(panel_w, -hh),
		Vector2(panel_w, hh), Vector2(0, hh)
	])
	_right_panel.color = PANEL_COLOR
	add_child(_right_panel)

func _build_indicator() -> void:
	# Small indicator light above the door
	_indicator_light = Polygon2D.new()
	var light_size := 8.0
	_indicator_light.polygon = PackedVector2Array([
		Vector2(-light_size, -light_size / 2.0),
		Vector2(light_size, -light_size / 2.0),
		Vector2(light_size, light_size / 2.0),
		Vector2(-light_size, light_size / 2.0)
	])
	_indicator_light.position = Vector2(0, -DOOR_HEIGHT / 2.0 - FRAME_THICKNESS - 6)
	_indicator_light.color = LIGHT_OFF
	add_child(_indicator_light)

func _build_label() -> void:
	_label = Label.new()
	_label.text = sector_label
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-40, -DOOR_HEIGHT / 2.0 - FRAME_THICKNESS - 30)

	# Style the label
	if door_type == DoorType.EVACUATION_EXIT:
		_label.add_theme_color_override("font_color", EXIT_LIGHT)
	else:
		_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))

	add_child(_label)

func _build_trigger() -> void:
	_trigger_area = Area2D.new()
	_trigger_area.collision_layer = 0
	_trigger_area.collision_mask = 2  # player layer
	_trigger_area.monitoring = false  # disabled until door opens

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(DOOR_WIDTH - 20, DOOR_HEIGHT - 20)
	cs.shape = rs
	_trigger_area.add_child(cs)

	_trigger_area.body_entered.connect(_on_body_entered)
	add_child(_trigger_area)

# ---------------------------------------------------------------------------
# Open / Close
# ---------------------------------------------------------------------------
func open() -> void:
	if _is_open:
		return
	_is_open = true

	# Slide panels outward
	var slide_dist := DOOR_WIDTH / 2.0 + PANEL_GAP
	if _left_panel:
		_left_panel.position.x = -slide_dist
		_left_panel.color = PANEL_OPEN_COLOR
	if _right_panel:
		_right_panel.position.x = slide_dist
		_right_panel.color = PANEL_OPEN_COLOR

	# Update indicator
	if _indicator_light:
		if door_type == DoorType.EVACUATION_EXIT:
			_indicator_light.color = EXIT_LIGHT
		else:
			_indicator_light.color = LIGHT_UNLOCKED

	# Enable trigger
	if _trigger_area:
		_trigger_area.monitoring = true

func close() -> void:
	if not _is_open and _left_panel != null:
		return
	_is_open = false

	# Center panels
	if _left_panel:
		_left_panel.position.x = 0
		_left_panel.color = PANEL_COLOR
	if _right_panel:
		_right_panel.position.x = 0
		_right_panel.color = PANEL_COLOR

	# Update indicator
	if _indicator_light:
		_indicator_light.color = LIGHT_LOCKED

	# Disable trigger
	if _trigger_area:
		_trigger_area.monitoring = false

func is_open() -> bool:
	return _is_open

# ---------------------------------------------------------------------------
# Trigger callback
# ---------------------------------------------------------------------------
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		door_entered.emit(body)
