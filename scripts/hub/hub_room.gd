extends Node2D
class_name HubRoom

# ---------------------------------------------------------------------------
# Room types
# ---------------------------------------------------------------------------
enum HubRoomType {
	STAGING      = 0,
	ARMORY       = 1,
	CAFETERIA    = 2,
	SHOP         = 3,
	CONTROL_ROOM = 4,
	TROPHY_ROOM  = 5,
	PRACTICE     = 6,
}

# ---------------------------------------------------------------------------
# Constants — wall geometry identical to run rooms
# ---------------------------------------------------------------------------
const ROOM_W := 960.0
const ROOM_H := 540.0
const WALL_T := 32.0
const DOOR_W := 80.0
const DOOR_H := 80.0

const WALL_COLOR := Color(0.18, 0.18, 0.25)

const ROOM_NAMES := [
	"STAGING AREA",   # 0
	"ARMORY",         # 1
	"CAFETERIA",      # 2
	"SHOP",           # 3
	"CONTROL ROOM",   # 4
	"TROPHY ROOM",    # 5
	"PRACTICE ROOM",  # 6
]

const FLOOR_COLORS := [
	Color(0.14, 0.14, 0.20),   # STAGING      — neutral dark
	Color(0.14, 0.12, 0.10),   # ARMORY       — warm metal
	Color(0.10, 0.14, 0.10),   # CAFETERIA    — green tint
	Color(0.14, 0.10, 0.14),   # SHOP         — purple tint
	Color(0.08, 0.12, 0.18),   # CONTROL_ROOM — blue tint
	Color(0.16, 0.14, 0.08),   # TROPHY_ROOM  — warm gold tint
	Color(0.12, 0.16, 0.13),   # PRACTICE     — muted green
]

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _type:        int        = 0   # HubRoomType value
var _connections: Dictionary = {}  # "up"/"down"/"left"/"right" -> Vector2i
var _hub:         Node       = null
var _doors:       Dictionary = {}  # direction -> Area2D

var _player_at_armory: bool  = false
var _player_at_portal: bool  = false
var _player_at_atm:    bool  = false
var _armory_prompt:    Label = null
var _portal_prompt:    Label = null
var _atm_prompt:       Label = null

# Practice room state
var _player_at_boss_terminal: int = -1   # -1 = none, 0 = Warden, 1 = Relay, 2 = Supervisor
var _boss_prompts: Array[Label] = []
var _practice_boss: Node2D = null
var _practice_active: bool = false
var _reset_prompt: Label = null
var _status_popup: Label = null
var _status_timer: float = 0.0

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var floor_poly:    Polygon2D = $Floor
@onready var walls_node:    Node2D    = $Walls
@onready var door_triggers: Node2D    = $DoorTriggers
@onready var contents:      Node2D    = $Contents

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
func setup(room_type: int, connections: Dictionary, hub_ref: Node) -> void:
	_type        = room_type
	_connections = connections
	_hub         = hub_ref

	floor_poly.color = FLOOR_COLORS[_type]
	_build_walls()
	_build_door_triggers()
	_build_room_label()

	if _type == HubRoomType.STAGING:
		_build_run_portal()
		_build_atm()
	elif _type == HubRoomType.ARMORY:
		_build_armory_workbench()
	elif _type == HubRoomType.PRACTICE:
		_build_practice_room()
		# Connect simulation events
		EventBus.practice_player_died.connect(_on_practice_player_died)
		EventBus.boss_died.connect(_on_practice_boss_defeated)

# ---------------------------------------------------------------------------
# Process — handle status popup timer
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if _status_timer > 0.0:
		_status_timer -= delta
		if _status_timer <= 0.0 and _status_popup != null:
			_status_popup.visible = false

# ---------------------------------------------------------------------------
# Wall generation (same logic as room.gd)
# ---------------------------------------------------------------------------
func _build_walls() -> void:
	var hw  := ROOM_W / 2.0
	var hh  := ROOM_H / 2.0
	var hdw := DOOR_W / 2.0
	var hdh := DOOR_H / 2.0

	var has_up    := _connections.has("up")
	var has_down  := _connections.has("down")
	var has_left  := _connections.has("left")
	var has_right := _connections.has("right")

	if has_up:
		_make_wall(Rect2(-hw,  -hh,      hw - hdw, WALL_T))
		_make_wall(Rect2( hdw, -hh,      hw - hdw, WALL_T))
	else:
		_make_wall(Rect2(-hw, -hh, ROOM_W, WALL_T))

	if has_down:
		_make_wall(Rect2(-hw,  hh - WALL_T, hw - hdw, WALL_T))
		_make_wall(Rect2( hdw, hh - WALL_T, hw - hdw, WALL_T))
	else:
		_make_wall(Rect2(-hw, hh - WALL_T, ROOM_W, WALL_T))

	var inner_top := -hh + WALL_T
	var inner_bot :=  hh - WALL_T
	var top_seg_h := -hdh - inner_top
	var bot_seg_h :=  inner_bot - hdh
	var full_side :=  inner_bot - inner_top

	if has_left:
		_make_wall(Rect2(-hw, inner_top, WALL_T, top_seg_h))
		_make_wall(Rect2(-hw, hdh,       WALL_T, bot_seg_h))
	else:
		_make_wall(Rect2(-hw, inner_top, WALL_T, full_side))

	if has_right:
		_make_wall(Rect2(hw - WALL_T, inner_top, WALL_T, top_seg_h))
		_make_wall(Rect2(hw - WALL_T, hdh,       WALL_T, bot_seg_h))
	else:
		_make_wall(Rect2(hw - WALL_T, inner_top, WALL_T, full_side))


func _make_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask  = 0
	body.position        = rect.get_center()

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size  = rect.size
	cs.shape = rs
	body.add_child(cs)

	var poly := Polygon2D.new()
	var hx   := rect.size.x / 2.0
	var hy   := rect.size.y / 2.0
	poly.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy),
		Vector2( hx,  hy), Vector2(-hx, hy),
	])
	poly.color = WALL_COLOR
	body.add_child(poly)

	walls_node.add_child(body)

# ---------------------------------------------------------------------------
# Door triggers
# ---------------------------------------------------------------------------
func _build_door_triggers() -> void:
	var hw := ROOM_W / 2.0
	var hh := ROOM_H / 2.0

	var configs := {
		"up":    {"pos": Vector2(0,   -hh + WALL_T * 0.5), "size": Vector2(DOOR_W * 0.9, WALL_T * 1.5)},
		"down":  {"pos": Vector2(0,    hh - WALL_T * 0.5), "size": Vector2(DOOR_W * 0.9, WALL_T * 1.5)},
		"left":  {"pos": Vector2(-hw + WALL_T * 0.5, 0),   "size": Vector2(WALL_T * 1.5, DOOR_H * 0.9)},
		"right": {"pos": Vector2( hw - WALL_T * 0.5, 0),   "size": Vector2(WALL_T * 1.5, DOOR_H * 0.9)},
	}

	for dir in _connections.keys():
		var cfg = configs[dir]
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask  = 2
		area.name            = "Door_" + dir

		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size  = cfg["size"]
		cs.shape = rs
		area.add_child(cs)
		area.position = cfg["pos"]

		area.body_entered.connect(_on_door_entered.bind(dir))
		door_triggers.add_child(area)
		_doors[dir] = area


func _on_door_entered(body: Node, direction: String) -> void:
	if body.is_in_group("player"):
		_hub.call_deferred("transition_to", _connections[direction], direction)

# ---------------------------------------------------------------------------
# Room label
# ---------------------------------------------------------------------------
func _build_room_label() -> void:
	var lbl      := Label.new()
	lbl.text     = ROOM_NAMES[_type]
	lbl.position = Vector2(-60, -235)
	contents.add_child(lbl)

# ---------------------------------------------------------------------------
# Armory workbench
# ---------------------------------------------------------------------------
func _build_armory_workbench() -> void:
	# Visual — blue-grey bench
	var bench      := Polygon2D.new()
	bench.polygon   = PackedVector2Array([-50, -20, 50, -20, 50, 20, -50, 20])
	bench.color     = Color(0.30, 0.40, 0.60)
	bench.position  = Vector2(0, -100)
	contents.add_child(bench)

	var lbl      := Label.new()
	lbl.text     = "UPGRADE"
	lbl.position = Vector2(-30, -140)
	contents.add_child(lbl)

	_armory_prompt          = Label.new()
	_armory_prompt.text     = "[E] Open"
	_armory_prompt.position = Vector2(-30, -155)
	_armory_prompt.visible  = false
	contents.add_child(_armory_prompt)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 2

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size  = Vector2(100, 40)
	cs.shape = rs
	area.add_child(cs)
	area.position = Vector2(0, -100)

	area.body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			_player_at_armory = true
			_armory_prompt.visible = true)
	area.body_exited.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			_player_at_armory = false
			_armory_prompt.visible = false)
	contents.add_child(area)

# ---------------------------------------------------------------------------
# Staging Area run portal
# ---------------------------------------------------------------------------
func _build_run_portal() -> void:
	# Visual — bright green rectangle
	var poly      := Polygon2D.new()
	poly.polygon   = PackedVector2Array([-40, -30, 40, -30, 40, 30, -40, 30])
	poly.color     = Color(0.2, 0.9, 0.4)
	poly.position  = Vector2(0, -150)
	contents.add_child(poly)

	# Label above portal
	var lbl      := Label.new()
	lbl.text     = "START RUN"
	lbl.position = Vector2(-36, -195)
	contents.add_child(lbl)

	_portal_prompt          = Label.new()
	_portal_prompt.text     = "[E] Start Run"
	_portal_prompt.position = Vector2(-50, -210)
	_portal_prompt.visible  = false
	contents.add_child(_portal_prompt)

	# Trigger zone
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 2

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size  = Vector2(80, 60)
	cs.shape = rs
	area.add_child(cs)
	area.position = Vector2(0, -150)

	area.body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			_player_at_portal = true
			_portal_prompt.visible = true)
	area.body_exited.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			_player_at_portal = false
			_portal_prompt.visible = false)
	contents.add_child(area)

# ---------------------------------------------------------------------------
# Deposit machine — shows bank balance, lets player set withdrawal for next run
# ---------------------------------------------------------------------------
func _build_atm() -> void:
	# Visual — grey terminal with cyan screen
	var body      := Polygon2D.new()
	body.polygon   = PackedVector2Array([-28, -40, 28, -40, 28, 40, -28, 40])
	body.color     = Color(0.25, 0.28, 0.32)
	body.position  = Vector2(200, -150)
	contents.add_child(body)

	var screen      := Polygon2D.new()
	screen.polygon   = PackedVector2Array([-18, -28, 18, -28, 18, 0, -18, 0])
	screen.color     = Color(0.1, 0.8, 0.9, 0.85)
	screen.position  = Vector2(200, -150)
	contents.add_child(screen)

	var lbl      := Label.new()
	lbl.text     = "DEPOSIT"
	lbl.position = Vector2(172, -202)
	contents.add_child(lbl)

	_atm_prompt          = Label.new()
	_atm_prompt.text     = "[E] Deposit"
	_atm_prompt.position = Vector2(162, -215)
	_atm_prompt.visible  = false
	contents.add_child(_atm_prompt)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 2

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size  = Vector2(56, 80)
	cs.shape = rs
	area.add_child(cs)
	area.position = Vector2(200, -150)

	area.body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			_player_at_atm = true
			_atm_prompt.visible = true)
	area.body_exited.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			_player_at_atm = false
			_atm_prompt.visible = false)
	contents.add_child(area)

# ---------------------------------------------------------------------------
# Input — E to interact
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo):
		return
	if _player_at_portal:
		GameManager.call_deferred("start_run")
	elif _player_at_armory:
		_hub.call_deferred("open_armory")
	elif _player_at_atm:
		_hub.call_deferred("open_atm")
	elif _player_at_boss_terminal >= 0:
		_spawn_practice_boss(_player_at_boss_terminal)
	elif _practice_active and _reset_prompt != null and _reset_prompt.visible:
		_reset_practice()

# ---------------------------------------------------------------------------
# Practice room — boss training arena
# ---------------------------------------------------------------------------
const WARDEN_SCENE   = preload("res://scenes/enemies/warden.tscn")
const RELAY_SCENE    = preload("res://scenes/enemies/relay.tscn")
const HIVEMIND_SCENE = preload("res://scenes/enemies/hivemind.tscn")

const BOSS_NAMES := ["WARDEN", "RELAY", "HIVEMIND"]
const BOSS_COLORS := [
	Color(0.6, 0.35, 0.2),   # Warden — rust
	Color(0.15, 0.55, 0.65), # Relay — teal
	Color(0.5, 0.2, 0.6),    # Hivemind — purple
]

func _build_practice_room() -> void:
	# Title
	var title      := Label.new()
	title.text     = "BOSS PRACTICE"
	title.position = Vector2(-55, -230)
	contents.add_child(title)

	# Instructions
	var inst      := Label.new()
	inst.text     = "Select a boss to begin training"
	inst.position = Vector2(-110, -210)
	contents.add_child(inst)

	# Three boss terminals arranged horizontally
	var terminal_positions := [
		Vector2(-200, -100),  # Warden
		Vector2(0, -100),     # Relay
		Vector2(200, -100),   # Supervisor
	]

	for i in 3:
		_create_boss_terminal(i, terminal_positions[i])

	# Reset prompt (hidden until practice active)
	_reset_prompt          = Label.new()
	_reset_prompt.text     = "[E] Reset Practice"
	_reset_prompt.position = Vector2(-70, 200)
	_reset_prompt.visible  = false
	contents.add_child(_reset_prompt)

	# Status popup (centered, hidden until triggered)
	_status_popup          = Label.new()
	_status_popup.text     = ""
	_status_popup.position = Vector2(-100, 0)
	_status_popup.visible  = false
	_status_popup.add_theme_font_size_override("font_size", 24)
	contents.add_child(_status_popup)

func _create_boss_terminal(boss_idx: int, pos: Vector2) -> void:
	# Terminal visual — colored rectangle
	var poly      := Polygon2D.new()
	poly.polygon   = PackedVector2Array([-35, -25, 35, -25, 35, 25, -35, 25])
	poly.color     = BOSS_COLORS[boss_idx]
	poly.position  = pos
	contents.add_child(poly)

	# Boss name label
	var name_lbl      := Label.new()
	name_lbl.text     = BOSS_NAMES[boss_idx]
	name_lbl.position = pos + Vector2(-30, -50)
	contents.add_child(name_lbl)

	# Prompt label
	var prompt      := Label.new()
	prompt.text     = "[E] Fight " + BOSS_NAMES[boss_idx]
	prompt.position = pos + Vector2(-50, 35)
	prompt.visible  = false
	contents.add_child(prompt)
	_boss_prompts.append(prompt)

	# Trigger area
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 2

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size  = Vector2(80, 60)
	cs.shape = rs
	area.add_child(cs)
	area.position = pos

	area.body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("player") and not _practice_active:
			_player_at_boss_terminal = boss_idx
			prompt.visible = true)
	area.body_exited.connect(func(b: Node) -> void:
		if b.is_in_group("player") and _player_at_boss_terminal == boss_idx:
			_player_at_boss_terminal = -1
			prompt.visible = false)
	contents.add_child(area)

func _spawn_practice_boss(boss_idx: int) -> void:
	if _practice_active:
		return

	_practice_active = true

	# Hide all terminal prompts
	for p in _boss_prompts:
		p.visible = false
	_player_at_boss_terminal = -1

	# Lock doors during simulation
	_set_doors_locked(true)

	# Spawn the boss
	var scene: PackedScene
	match boss_idx:
		0: scene = WARDEN_SCENE
		1: scene = RELAY_SCENE
		_: scene = HIVEMIND_SCENE

	_practice_boss = scene.instantiate()
	contents.add_child(_practice_boss)
	_practice_boss.global_position = global_position + Vector2(0, 50)

	# Connect boss death to reset
	_practice_boss.tree_exited.connect(_on_practice_boss_died, CONNECT_DEFERRED)

	# Show reset prompt
	_reset_prompt.visible = true

func _on_practice_boss_died() -> void:
	_practice_boss = null
	# Keep reset prompt visible so player can spawn another

func _reset_practice() -> void:
	# Show disruption message only if simulation was active
	var was_active := _practice_active

	# Kill current boss if alive
	if _practice_boss != null and is_instance_valid(_practice_boss):
		_practice_boss.queue_free()
		_practice_boss = null

	# Clear all enemies (drifters spawned by Relay, etc.)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()

	# Clear any projectiles/nodes in contents that aren't permanent
	for child in contents.get_children():
		# Keep labels, polygons, and areas (the UI elements)
		if child is Label or child is Polygon2D or child is Area2D:
			continue
		# Remove everything else (projectiles, spawned enemies, etc.)
		child.queue_free()

	_practice_active = false
	_reset_prompt.visible = false

	# Unlock doors
	_set_doors_locked(false)

	# Heal player
	_heal_player()

	# Show disruption message if simulation was running
	if was_active:
		_show_status("SIMULATION DISRUPTED", Color(0.8, 0.6, 0.2))


func _on_practice_boss_defeated() -> void:
	if not _practice_active:
		return

	_practice_active = false
	_practice_boss = null
	_reset_prompt.visible = false

	# Clear any spawned enemies (drifters from Relay, etc.)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()

	# Clear projectiles
	for child in contents.get_children():
		if child is Label or child is Polygon2D or child is Area2D:
			continue
		child.queue_free()

	# Unlock doors
	_set_doors_locked(false)

	# Heal player
	_heal_player()

	# Show success message
	_show_status("SIMULATION PASSED", Color(0.2, 0.9, 0.4))


func _on_practice_player_died() -> void:
	if not _practice_active:
		return

	# Clear boss and enemies
	if _practice_boss != null and is_instance_valid(_practice_boss):
		_practice_boss.queue_free()
		_practice_boss = null

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()

	# Clear projectiles
	for child in contents.get_children():
		if child is Label or child is Polygon2D or child is Area2D:
			continue
		child.queue_free()

	_practice_active = false
	_reset_prompt.visible = false

	# Unlock doors
	_set_doors_locked(false)

	# Player already healed in player._die(), but ensure full health
	_heal_player()

	# Show failure message
	_show_status("SIMULATION FAILED", Color(0.9, 0.2, 0.2))


func _set_doors_locked(locked: bool) -> void:
	for area in _doors.values():
		(area as Area2D).monitoring = not locked


func _heal_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var stats = player.get_node_or_null("Stats")
		if stats != null and stats.has_method("heal"):
			stats.heal(999)
		EventBus.player_health_changed.emit(stats.current_health, stats.max_health)


func _show_status(text: String, color: Color) -> void:
	if _status_popup == null:
		return
	_status_popup.text = text
	_status_popup.modulate = color
	_status_popup.position = Vector2(-float(text.length()) * 6.0, 0)  # rough centering
	_status_popup.visible = true
	_status_timer = 2.5  # show for 2.5 seconds
