extends CanvasLayer

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
# Boss bar
# ---------------------------------------------------------------------------
const BOSS_BAR_W   := 400.0
const BOSS_BAR_H   := 18.0
const BOSS_BAR_POS := Vector2(280.0, 490.0)   # top-left corner (960×540 viewport)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
# Each entry: { "bg": Polygon2D, "fill": Polygon2D }
var _slots: Array = []
var _credits_label: Label

# Boss bar nodes (null when not active)
var _boss_bar_root:  Node2D    = null
var _boss_bar_fill:  Polygon2D = null
var _boss_bar_label: Label     = null
var _boss_max_hp:    float     = 1.0

# ---------------------------------------------------------------------------
# Boot
# ---------------------------------------------------------------------------
func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.credits_changed.connect(_on_credits_changed)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.boss_died.connect(_on_boss_died)
	_build_credits_label()
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
	_credits_label.text     = "SCRAP: %d" % UpgradeManager.hub_credits
	add_child(_credits_label)

func _on_credits_changed(new_total: int) -> void:
	_credits_label.text = "SCRAP: %d" % new_total

# ---------------------------------------------------------------------------
# Signal handler
# ---------------------------------------------------------------------------
func _on_health_changed(current_hp: float, max_hp: float) -> void:
	var num_hearts := int(max_hp / 2.0)
	if num_hearts != _slots.size():
		_rebuild(max_hp, current_hp)
	else:
		_update_display(current_hp)

# ---------------------------------------------------------------------------
# Boss health bar
# ---------------------------------------------------------------------------
func _on_boss_health_changed(current_hp: float, max_hp: float) -> void:
	if _boss_bar_root == null:
		_build_boss_bar(max_hp)
	_boss_max_hp = max_hp
	_update_boss_bar(current_hp)

func _on_boss_died() -> void:
	if _boss_bar_root != null:
		_boss_bar_root.queue_free()
		_boss_bar_root  = null
		_boss_bar_fill  = null
		_boss_bar_label = null

func _build_boss_bar(max_hp: float) -> void:
	_boss_max_hp = max_hp

	_boss_bar_root = Node2D.new()
	_boss_bar_root.position = BOSS_BAR_POS
	add_child(_boss_bar_root)

	# Name label
	_boss_bar_label = Label.new()
	_boss_bar_label.text     = "THE SUPERVISOR"
	_boss_bar_label.position = Vector2(0, -22)
	_boss_bar_root.add_child(_boss_bar_label)

	# Background
	var bg       := Polygon2D.new()
	bg.polygon    = PackedVector2Array([
		Vector2(0, 0), Vector2(BOSS_BAR_W, 0),
		Vector2(BOSS_BAR_W, BOSS_BAR_H), Vector2(0, BOSS_BAR_H),
	])
	bg.color = Color(0.15, 0.05, 0.05)
	_boss_bar_root.add_child(bg)

	# Fill
	_boss_bar_fill          = Polygon2D.new()
	_boss_bar_fill.polygon  = PackedVector2Array([
		Vector2(0, 0), Vector2(BOSS_BAR_W, 0),
		Vector2(BOSS_BAR_W, BOSS_BAR_H), Vector2(0, BOSS_BAR_H),
	])
	_boss_bar_fill.color = Color(0.85, 0.1, 0.1)
	_boss_bar_root.add_child(_boss_bar_fill)

func _update_boss_bar(current_hp: float) -> void:
	if _boss_bar_fill == null:
		return
	var pct  := clampf(current_hp / _boss_max_hp, 0.0, 1.0)
	var w    := BOSS_BAR_W * pct
	_boss_bar_fill.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(w, 0),
		Vector2(w, BOSS_BAR_H), Vector2(0, BOSS_BAR_H),
	])
