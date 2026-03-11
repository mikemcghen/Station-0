extends Node2D
class_name Room

signal room_cleared

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const ROOM_W       := 960.0
const ROOM_H       := 540.0
const WALL_T       := 32.0    # wall thickness
const DOOR_W       := 80.0    # door opening on horizontal walls
const DOOR_H       := 80.0    # door opening on vertical walls
const SPAWN_MARGIN := 120.0   # keep enemies away from walls when spawning

const WALL_COLOR := Color(0.18, 0.18, 0.25)

const DRIFTER_SCENE     = preload("res://scenes/enemies/drifter.tscn")
const REPEATER_SCENE    = preload("res://scenes/enemies/repeater.tscn")
const ANCHOR_SCENE      = preload("res://scenes/enemies/anchor.tscn")
const SUPERVISOR_SCENE  = preload("res://scenes/enemies/supervisor.tscn")
const WARDEN_SCENE      = preload("res://scenes/enemies/warden.tscn")
const RELAY_SCENE       = preload("res://scenes/enemies/relay.tscn")
const HIVEMIND_SCENE    = preload("res://scenes/enemies/hivemind.tscn")
const BODY_PART_PICKUP  = preload("res://scenes/upgrades/body_part_pickup.tscn")
const RUN_ITEM_PICKUP   = preload("res://scenes/items/run_item_pickup.tscn")
const SHOP_PEDESTAL_SCR = preload("res://scripts/items/shop_item_pedestal.gd")
const STATION_DOOR_SCR  = preload("res://scripts/rooms/station_door.gd")

const ALL_PART_PATHS: Array[String] = [
	"res://data/body_parts/torso_reinforced_chassis.tres",
	"res://data/body_parts/torso_lightweight_frame.tres",
	"res://data/body_parts/left_arm_scatter_emitter.tres",
	"res://data/body_parts/left_arm_shield_projector.tres",
	"res://data/body_parts/right_arm_heavy_emitter.tres",
	"res://data/body_parts/right_arm_rapid_emitter.tres",
]

const ALL_ITEM_PATHS: Array[String] = [
	"res://data/run_items/coolant_leak.tres",
	"res://data/run_items/overclock_module.tres",
	"res://data/run_items/scrap_magnet.tres",
	"res://data/run_items/memory_spike.tres",
	"res://data/run_items/rust_coat.tres",
	"res://data/run_items/static_discharge.tres",
	"res://data/run_items/fragmented_map.tres",
	"res://data/run_items/patch_kit.tres",
	"res://data/run_items/plating_shard.tres",
	"res://data/run_items/range_booster.tres",
]

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var data:         RoomData = null
var _floor:       Node     = null   # reference to floor.gd node
var _enemy_count: int      = 0
var _doors:       Dictionary = {}   # direction -> Area2D trigger
var _physical_doors: Dictionary = {}  # direction -> RoomDoor
var _floor_exit_door: StationDoor = null  # boss room exit door

# ---------------------------------------------------------------------------
# Signal tracking for explicit cleanup (safer than relying on auto-cleanup)
# ---------------------------------------------------------------------------
var _enemy_death_connections: Array[Dictionary] = []  # [{node, callable}]
var _door_connections: Array[Dictionary] = []         # [{node, callable}]

# ---------------------------------------------------------------------------
# Node refs (set by room_base.tscn)
# ---------------------------------------------------------------------------
@onready var floor_poly:    Polygon2D = $Floor
@onready var walls_node:    Node2D    = $Walls
@onready var door_triggers: Node2D    = $DoorTriggers
@onready var doors_node:    Node2D    = $Doors
@onready var contents:      Node2D    = $Contents

# ---------------------------------------------------------------------------
# Setup — called by floor.gd after add_child
# ---------------------------------------------------------------------------
func setup(room_data: RoomData, floor_ref: Node) -> void:
	data   = room_data
	_floor = floor_ref
	_apply_floor_color()
	_build_walls()
	_build_door_triggers()
	_build_physical_doors()

# ---------------------------------------------------------------------------
# Activate — called on first (and repeat) entry
# ---------------------------------------------------------------------------
func activate() -> void:
	EventBus.room_entered.emit(data.id)
	if data.visited:
		_update_door_locks()
		return
	data.visited = true

	match data.type:
		RoomData.RoomType.COMBAT:
			_spawn_enemies()
		RoomData.RoomType.BOSS:
			_spawn_boss()
		RoomData.RoomType.ITEM:
			_spawn_run_item()
			data.cleared = true
		RoomData.RoomType.SHOP:
			_spawn_shop()
			data.cleared = true
		RoomData.RoomType.START:
			data.cleared = true
		_:
			data.cleared = true

	_update_door_locks()

# ---------------------------------------------------------------------------
# Floor colour by room type
# ---------------------------------------------------------------------------
func _apply_floor_color() -> void:
	match data.type:
		RoomData.RoomType.ITEM:  floor_poly.color = Color(0.10, 0.16, 0.10)
		RoomData.RoomType.SHOP:  floor_poly.color = Color(0.16, 0.12, 0.08)
		RoomData.RoomType.BOSS:  floor_poly.color = Color(0.20, 0.08, 0.08)
		_:                       floor_poly.color = Color(0.12, 0.12, 0.18)

# ---------------------------------------------------------------------------
# Wall generation
# ---------------------------------------------------------------------------
func _build_walls() -> void:
	var hw  := ROOM_W / 2.0   # 480
	var hh  := ROOM_H / 2.0   # 270
	var hdw := DOOR_W / 2.0   # 40 — half opening width  (top/bottom walls)
	var hdh := DOOR_H / 2.0   # 40 — half opening height (left/right walls)

	var has_up    := data.connections.has("up")
	var has_down  := data.connections.has("down")
	var has_left  := data.connections.has("left")
	var has_right := data.connections.has("right")

	# --- Top wall ---
	if has_up:
		_make_wall(Rect2(-hw,  -hh,      hw - hdw, WALL_T))   # left of gap
		_make_wall(Rect2( hdw, -hh,      hw - hdw, WALL_T))   # right of gap
	else:
		_make_wall(Rect2(-hw, -hh, ROOM_W, WALL_T))

	# --- Bottom wall ---
	if has_down:
		_make_wall(Rect2(-hw,  hh - WALL_T, hw - hdw, WALL_T))
		_make_wall(Rect2( hdw, hh - WALL_T, hw - hdw, WALL_T))
	else:
		_make_wall(Rect2(-hw, hh - WALL_T, ROOM_W, WALL_T))

	# Side walls occupy the strip between the horizontal walls
	# inner_top = -238,  inner_bot = 238,  gap spans -40 to +40
	var inner_top := -hh + WALL_T   # -238
	var inner_bot :=  hh - WALL_T   #  238
	var top_seg_h := -hdh - inner_top          # 198
	var bot_seg_h :=  inner_bot - hdh          # 198
	var full_side := inner_bot - inner_top     # 476

	# --- Left wall ---
	if has_left:
		_make_wall(Rect2(-hw, inner_top, WALL_T, top_seg_h))   # above gap
		_make_wall(Rect2(-hw, hdh,       WALL_T, bot_seg_h))   # below gap
	else:
		_make_wall(Rect2(-hw, inner_top, WALL_T, full_side))

	# --- Right wall ---
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
	var hw := ROOM_W / 2.0   # 480
	var hh := ROOM_H / 2.0   # 270

	# Triggers sit centered on the wall face at the door opening.
	# Slightly oversized so the player doesn't have to pixel-perfectly align.
	var configs := {
		"up":    {"pos": Vector2(0,   -hh + WALL_T * 0.5), "size": Vector2(DOOR_W * 0.9, WALL_T * 1.5)},
		"down":  {"pos": Vector2(0,    hh - WALL_T * 0.5), "size": Vector2(DOOR_W * 0.9, WALL_T * 1.5)},
		"left":  {"pos": Vector2(-hw + WALL_T * 0.5, 0),   "size": Vector2(WALL_T * 1.5, DOOR_H * 0.9)},
		"right": {"pos": Vector2( hw - WALL_T * 0.5, 0),   "size": Vector2(WALL_T * 1.5, DOOR_H * 0.9)},
	}

	for dir in data.connections.keys():
		var cfg = configs[dir]
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask  = 2   # player layer
		area.name            = "Door_" + dir

		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size  = cfg["size"]
		cs.shape = rs
		area.add_child(cs)
		area.position = cfg["pos"]

		# Use call_deferred so the transition runs outside the physics callback
		var callable := _on_door_entered.bind(dir)
		area.body_entered.connect(callable)
		_door_connections.append({"node": area, "signal": "body_entered", "callable": callable})
		door_triggers.add_child(area)
		_doors[dir] = area


func _on_door_entered(body: Node, direction: String) -> void:
	if body.is_in_group("player"):
		_floor.call_deferred(
			"transition_to", data.connections[direction], direction
		)

# ---------------------------------------------------------------------------
# Physical doors with lock barriers and indicator lights
# ---------------------------------------------------------------------------
func _build_physical_doors() -> void:
	const DOOR_THICKNESS := 12.0
	var hw := ROOM_W / 2.0
	var hh := ROOM_H / 2.0

	# Door positions and sizes per direction
	var configs := {
		"up":    {"pos": Vector2(0, -hh + WALL_T / 2.0), "size": Vector2(DOOR_W, DOOR_THICKNESS)},
		"down":  {"pos": Vector2(0, hh - WALL_T / 2.0),  "size": Vector2(DOOR_W, DOOR_THICKNESS)},
		"left":  {"pos": Vector2(-hw + WALL_T / 2.0, 0), "size": Vector2(DOOR_THICKNESS, DOOR_H)},
		"right": {"pos": Vector2(hw - WALL_T / 2.0, 0),  "size": Vector2(DOOR_THICKNESS, DOOR_H)},
	}

	for dir in data.connections.keys():
		var cfg = configs[dir]
		var adj_grid: Vector2i = data.connections[dir]
		var adj_type: int = _floor.get_room_type_at(adj_grid)
		if adj_type < 0:
			adj_type = RoomData.RoomType.COMBAT  # fallback

		var door := RoomDoor.new()
		door.position = cfg["pos"]
		door.setup(dir, cfg["size"], adj_type as RoomData.RoomType)
		doors_node.add_child(door)
		_physical_doors[dir] = door

# ---------------------------------------------------------------------------
# Enemy spawning
# ---------------------------------------------------------------------------

# Enemy pool and count scale with floor depth per CONTENT_SPEC
func _get_enemy_pool() -> Array:
	match RunManager.current_floor:
		1:   return [DRIFTER_SCENE, DRIFTER_SCENE, DRIFTER_SCENE, REPEATER_SCENE]
		2:   return [DRIFTER_SCENE, DRIFTER_SCENE, REPEATER_SCENE, ANCHOR_SCENE]
		_:   return [DRIFTER_SCENE, REPEATER_SCENE, ANCHOR_SCENE, ANCHOR_SCENE]

func _get_enemy_count() -> int:
	match RunManager.current_floor:
		1:   return randi_range(1, 3)
		2:   return randi_range(2, 4)
		_:   return randi_range(2, 3)

func _spawn_enemies() -> void:
	# Hazards first — added to contents before enemies so they draw underneath
	_spawn_hazards()

	var hw    := ROOM_W / 2.0 - SPAWN_MARGIN
	var hh    := ROOM_H / 2.0 - SPAWN_MARGIN
	var pool  := _get_enemy_pool()
	var count := _get_enemy_count()

	for i in count:
		var scene     = pool[randi() % pool.size()]
		var enemy     = scene.instantiate()
		var local_pos := Vector2(randf_range(-hw, hw), randf_range(-hh, hh))
		contents.add_child(enemy)
		enemy.global_position = to_global(local_pos)
		var callable := _on_enemy_died
		enemy.tree_exited.connect(callable, CONNECT_DEFERRED)
		_enemy_death_connections.append({"node": enemy, "signal": "tree_exited", "callable": callable})
		_enemy_count += 1


func _spawn_boss() -> void:
	var scene: PackedScene
	match RunManager.current_floor:
		1: scene = WARDEN_SCENE
		2: scene = RELAY_SCENE
		_: scene = HIVEMIND_SCENE
	var boss  = scene.instantiate()
	contents.add_child(boss)
	boss.global_position = to_global(Vector2.ZERO)   # room centre
	var callable := _on_enemy_died
	boss.tree_exited.connect(callable, CONNECT_DEFERRED)
	_enemy_death_connections.append({"node": boss, "signal": "tree_exited", "callable": callable})
	_enemy_count = 1

	# Spawn exit door on top wall (visible but closed until boss defeated)
	_spawn_floor_exit_door()


func _on_enemy_died() -> void:
	# Guard against deferred callback running after room is freed
	if not is_instance_valid(self) or not is_inside_tree():
		return
	_enemy_count -= 1
	if _enemy_count <= 0:
		data.cleared = true
		AudioManager.play("room_clear")
		if data.type == RoomData.RoomType.BOSS:
			_spawn_body_part_drop()
			_open_floor_exit()
		room_cleared.emit()
		EventBus.room_cleared.emit(data.id)
		_update_door_locks()


func _spawn_floor_exit_door() -> void:
	# Create the exit door on the top wall (closed until boss defeated)
	var is_final_floor := RunManager.current_floor >= 3

	_floor_exit_door = StationDoor.new()
	# Position on top wall, centered
	_floor_exit_door.position = Vector2(0, -ROOM_H / 2.0 + 80)

	if is_final_floor:
		_floor_exit_door.setup_evacuation_exit()
	else:
		_floor_exit_door.setup_sector_exit(RunManager.current_floor + 1)

	_floor_exit_door.door_entered.connect(_on_floor_exit_entered)
	contents.add_child(_floor_exit_door)
	# Door starts closed (setup functions already call close())


func _open_floor_exit() -> void:
	# Open the door now that boss is dead
	if _floor_exit_door != null:
		_floor_exit_door.open()


func _on_floor_exit_entered(body: Node) -> void:
	RunManager.player_health_carry = body.stats.current_health
	if RunManager.current_floor >= 3:
		RunManager.end_run(true)
	else:
		RunManager.advance_floor()
		get_tree().call_deferred("change_scene_to_file", "res://scenes/run/floor.tscn")


func _spawn_body_part_drop() -> void:
	# 50% drop chance so body parts feel more valuable
	if randf() > 0.5:
		return

	# Drop a random part the player hasn't yet acquired
	var unacquired: Array[String] = []
	for path in ALL_PART_PATHS:
		if path not in UpgradeManager.acquired_part_paths:
			unacquired.append(path)

	if unacquired.is_empty():
		return  # player has every part

	var chosen: String = unacquired[randi() % unacquired.size()]
	var pickup          = BODY_PART_PICKUP.instantiate()
	pickup.part         = load(chosen)
	pickup.position     = Vector2.ZERO   # center of this room
	contents.add_child(pickup)

func _spawn_run_item() -> void:
	# Exclude Patch Kit from item rooms (shop-only item)
	const PATCH_KIT_PATH := "res://data/run_items/patch_kit.tres"
	var item_pool: Array[String] = []
	for p in ALL_ITEM_PATHS:
		if p != PATCH_KIT_PATH:
			item_pool.append(p)

	var chosen: String = item_pool[randi() % item_pool.size()]
	var pickup         = RUN_ITEM_PICKUP.instantiate()
	pickup.item        = load(chosen)
	pickup.position    = Vector2.ZERO
	contents.add_child(pickup)

# ---------------------------------------------------------------------------
# Environmental hazards — spawned in combat rooms
# ---------------------------------------------------------------------------
func _spawn_hazards() -> void:
	# Oil slicks — 0-2 random puddles in the room interior
	var hw := ROOM_W / 2.0 - SPAWN_MARGIN
	var hh := ROOM_H / 2.0 - SPAWN_MARGIN
	for i in randi_range(0, 2):
		_make_oil_slick(Vector2(randf_range(-hw, hw), randf_range(-hh, hh)))

	# Exposed wiring — 0-2 sections along walls
	for i in randi_range(0, 2):
		_make_exposed_wiring()

func _make_oil_slick(pos: Vector2) -> void:
	var slick := Area2D.new()
	slick.collision_layer = 0
	slick.collision_mask  = 2 | 8   # player (2) + enemies (8)
	slick.position        = pos

	# Oval dimensions — wider than tall
	var radius_x: float = randf_range(55.0, 85.0)
	var radius_y: float = randf_range(35.0, 50.0)

	# Use rectangle shape for collision (approximates oval)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(radius_x * 1.6, radius_y * 1.6)  # slightly smaller than visual
	cs.shape = sh
	slick.add_child(cs)

	# Visual — oval shape
	var poly := Polygon2D.new()
	var pts  := PackedVector2Array()
	var segs := 16
	for i in segs:
		var a := i * TAU / segs
		pts.append(Vector2(cos(a) * radius_x, sin(a) * radius_y))
	poly.polygon = pts
	poly.color   = Color(0.04, 0.07, 0.14, 0.78)
	slick.add_child(poly)

	slick.body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("player") and b.has_method("enter_slick"):
			b.enter_slick()
		elif b.is_in_group("enemies") and b.has_method("apply_slow"):
			b.apply_slow(999.0, 0.35))
	slick.body_exited.connect(func(b: Node) -> void:
		if b.is_in_group("player") and b.has_method("exit_slick"):
			b.exit_slick()
		elif b.is_in_group("enemies") and b.has_method("clear_slows"):
			b.clear_slows())

	contents.add_child(slick)

func _make_exposed_wiring() -> void:
	var hw         := ROOM_W / 2.0 - WALL_T
	var hh         := ROOM_H / 2.0 - WALL_T
	var wire_len   := randf_range(80.0, 150.0)
	var wire_thick := 14.0
	var inset      := wire_thick / 2.0 + 2.0
	var half       := wire_len / 2.0
	var hdw        := DOOR_W / 2.0   # 40 — half door gap on horiz walls
	var hdh        := DOOR_H / 2.0   # 40 — half door gap on vert walls

	# Build candidates: {wall, min, max} for center position along the wall.
	# Door walls get two segments (one each side of gap); non-door walls get one full segment.
	var wall_dirs  := ["up", "down", "left", "right"]
	var candidates : Array = []
	for wall_id in 4:
		var has_door  := data.connections.has(wall_dirs[wall_id])
		var is_horiz  := wall_id <= 1
		var extent    := hw if is_horiz else hh
		var door_half := hdw if is_horiz else hdh
		if has_door:
			var a_min := -extent + half; var a_max := -door_half - half
			var b_min :=  door_half + half; var b_max := extent - half
			if a_min <= a_max: candidates.append({"wall": wall_id, "min": a_min, "max": a_max})
			if b_min <= b_max: candidates.append({"wall": wall_id, "min": b_min, "max": b_max})
		else:
			var s_min := -extent + half; var s_max := extent - half
			if s_min <= s_max: candidates.append({"wall": wall_id, "min": s_min, "max": s_max})

	if candidates.is_empty():
		return

	var chosen: Dictionary = candidates[randi() % candidates.size()]
	var wall   := chosen["wall"] as int
	var along  := randf_range(chosen["min"], chosen["max"])

	var pos:  Vector2
	var size: Vector2
	match wall:
		0:  pos = Vector2(along, -hh + inset); size = Vector2(wire_len, wire_thick)
		1:  pos = Vector2(along,  hh - inset); size = Vector2(wire_len, wire_thick)
		2:  pos = Vector2(-hw + inset, along); size = Vector2(wire_thick, wire_len)
		_:  pos = Vector2( hw - inset, along); size = Vector2(wire_thick, wire_len)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 2   # player layer
	area.position        = pos

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size  = size
	cs.shape = rs
	area.add_child(cs)

	# Visual — bright yellow-orange strip
	var poly := Polygon2D.new()
	var hx   := size.x / 2.0
	var hy   := size.y / 2.0
	poly.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy),
		Vector2( hx,  hy), Vector2(-hx,  hy),
	])
	poly.color = Color(1.0, 0.85, 0.05, 0.90)
	area.add_child(poly)

	# Continuous damage while overlapping — timer ticks damage, player iframes limit actual hits
	var overlapping_players: Array[Node] = []
	var damage_timer := Timer.new()
	damage_timer.wait_time = 0.3
	damage_timer.autostart = true
	damage_timer.timeout.connect(func() -> void:
		for b in overlapping_players:
			if is_instance_valid(b) and b.has_method("take_damage"):
				b.take_damage(1.0))
	area.add_child(damage_timer)

	area.body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			overlapping_players.append(b)
			if b.has_method("take_damage"):
				b.take_damage(1.0))
	area.body_exited.connect(func(b: Node) -> void:
		overlapping_players.erase(b))

	contents.add_child(area)

# ---------------------------------------------------------------------------
# Shop spawning — 2 random items + 1 Patch Kit, spaced horizontally
# ---------------------------------------------------------------------------
func _spawn_shop() -> void:
	# Item slot paths (exclude Patch Kit from the random pool)
	const PATCH_KIT_PATH := "res://data/run_items/patch_kit.tres"
	var item_pool: Array[String] = []
	for p in ALL_ITEM_PATHS:
		if p != PATCH_KIT_PATH:
			item_pool.append(p)
	item_pool.shuffle()

	# Positions: left item, center item, right = Patch Kit
	var positions: Array[Vector2] = [
		Vector2(-200, 0),
		Vector2(   0, 0),
		Vector2( 200, 0),
	]

	var chosen: Array[String] = [
		item_pool[0],
		item_pool[1],
		PATCH_KIT_PATH,
	]
	var prices: Array[int] = [20, 20, 10]

	for i in 3:
		var pedestal       := Area2D.new()
		pedestal.set_script(SHOP_PEDESTAL_SCR)
		pedestal.position   = positions[i]
		pedestal.set("item",  load(chosen[i]))
		pedestal.set("price", prices[i])
		contents.add_child(pedestal)

# ---------------------------------------------------------------------------
# Door locking
# ---------------------------------------------------------------------------
func _update_door_locks() -> void:
	var is_combat := data.type == RoomData.RoomType.COMBAT \
				  or data.type == RoomData.RoomType.BOSS
	var locked := data.visited and not data.cleared and is_combat

	# Update door triggers (for transitions)
	for area in _doors.values():
		(area as Area2D).monitoring = not locked

	# Update physical door barriers
	var was_unlocked := false
	for door in _physical_doors.values():
		if not door.is_locked():
			was_unlocked = true
			break
	for door in _physical_doors.values():
		if locked:
			door.lock()
		else:
			door.unlock()
	if locked and was_unlocked:
		AudioManager.play("door_close")

# ---------------------------------------------------------------------------
# Explicit signal cleanup on exit (safer than relying on Godot auto-cleanup)
# ---------------------------------------------------------------------------
func _exit_tree() -> void:
	# Disconnect enemy death signals
	for conn in _enemy_death_connections:
		var node = conn["node"]  # untyped to avoid error on freed instances
		if is_instance_valid(node) and node.is_connected(conn["signal"], conn["callable"]):
			node.disconnect(conn["signal"], conn["callable"])
	_enemy_death_connections.clear()

	# Disconnect door trigger signals
	for conn in _door_connections:
		var node = conn["node"]  # untyped to avoid error on freed instances
		if is_instance_valid(node) and node.is_connected(conn["signal"], conn["callable"]):
			node.disconnect(conn["signal"], conn["callable"])
	_door_connections.clear()
