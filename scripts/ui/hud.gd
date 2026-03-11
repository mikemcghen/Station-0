extends CanvasLayer

const MiniMapScript = preload("res://scripts/ui/mini_map.gd")

# ---------------------------------------------------------------------------
# Heart geometry — two polygons per slot: background (dark) + fill (red)
# ---------------------------------------------------------------------------

# Full heart, centered at origin, ~40 wide x 36 tall
var HEART_FULL := PackedVector2Array([
	Vector2( 0,  18), Vector2(-15,  3), Vector2(-20, -6),
	Vector2(-15, -15), Vector2(-6, -18), Vector2(-2, -14),
	Vector2(  0, -11),
	Vector2(  2, -14), Vector2( 6, -18), Vector2(15, -15),
	Vector2( 20,  -6), Vector2(15,   3),
])

# Left half only — used for the half-heart fill
var HEART_HALF := PackedVector2Array([
	Vector2( 0,  18), Vector2(-15,  3), Vector2(-20, -6),
	Vector2(-15, -15), Vector2(-6, -18), Vector2(-2, -14),
	Vector2(  0, -11),
])

const FULL_COLOR  := Color(0.90, 0.10, 0.10)   # bright red
const EMPTY_COLOR := Color(0.18, 0.04, 0.04)   # dark maroon (background)

const HEART_SPACING := 52   # px between heart centers
const ORIGIN        := Vector2(32, 32)   # center of first heart (screen px)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
# Each entry: { "bg": Polygon2D, "fill": Polygon2D }
var _slots: Array = []
var _credits_label: Label
var _mini_map: Control

# ---------------------------------------------------------------------------
# Boot
# ---------------------------------------------------------------------------
func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.credits_changed.connect(_on_credits_changed)
	EventBus.save_loaded.connect(_on_save_loaded)
	_build_credits_label()
	_build_mini_map()
	# Initialise once the scene is fully set up
	call_deferred("_init_from_player")


func _init_from_player() -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p:
		_rebuild(p.stats.max_health, p.stats.current_health)
	else:
		_rebuild(6.0, 6.0)

# ---------------------------------------------------------------------------
# Build / rebuild all heart slots
# ---------------------------------------------------------------------------
func _rebuild(max_hp: float, current_hp: float) -> void:
	for slot in _slots:
		slot["bg"].queue_free()
		slot["fill"].queue_free()
	_slots.clear()

	var num_hearts := int(max_hp / 2.0)

	for i in num_hearts:
		var center := ORIGIN + Vector2(i * HEART_SPACING, 0)

		# Background — always visible, shows the "empty" container
		var bg       := Polygon2D.new()
		bg.polygon    = HEART_FULL
		bg.color      = EMPTY_COLOR
		bg.position   = center
		add_child(bg)

		# Fill — overlaid on top; polygon shape changes per fill level
		var fill      := Polygon2D.new()
		fill.polygon   = HEART_FULL
		fill.color     = FULL_COLOR
		fill.position  = center
		add_child(fill)

		_slots.append({"bg": bg, "fill": fill})

	_update_display(current_hp)

# ---------------------------------------------------------------------------
# Update fill polygons to reflect current health
# ---------------------------------------------------------------------------
func _update_display(current_hp: float) -> void:
	for i in _slots.size():
		var fill: Polygon2D = _slots[i]["fill"]
		var hp_in_slot := current_hp - i * 2.0

		if hp_in_slot >= 2.0:
			fill.polygon = HEART_FULL
			fill.visible  = true
		elif hp_in_slot >= 1.0:
			fill.polygon = HEART_HALF
			fill.visible  = true
		else:
			fill.visible  = false

# ---------------------------------------------------------------------------
# Credits label
# ---------------------------------------------------------------------------
func _build_credits_label() -> void:
	_credits_label          = Label.new()
	_credits_label.position = Vector2(16, 72)
	var amount := RunManager.run_credits if RunManager.run_active else UpgradeManager.wallet_credits
	_credits_label.text     = "SCRAP: %d" % amount
	add_child(_credits_label)


func _build_mini_map() -> void:
	_mini_map = Control.new()
	_mini_map.set_script(MiniMapScript)
	add_child(_mini_map)

func _on_credits_changed(new_total: int) -> void:
	_credits_label.text = "SCRAP: %d" % new_total

func _on_save_loaded() -> void:
	var amount := RunManager.run_credits if RunManager.run_active else UpgradeManager.wallet_credits
	_credits_label.text = "SCRAP: %d" % amount

# ---------------------------------------------------------------------------
# Signal handler
# ---------------------------------------------------------------------------
func _on_health_changed(current_hp: float, max_hp: float) -> void:
	var num_hearts := int(max_hp / 2.0)
	if num_hearts != _slots.size():
		_rebuild(max_hp, current_hp)
	else:
		_update_display(current_hp)
