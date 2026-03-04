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
const BODY_PART_PICKUP  = preload("res://scenes/upgrades/body_part_pickup.tscn")
const RUN_ITEM_PICKUP   = preload("res://scenes/items/run_item_pickup.tscn")

const ALL_PART_PATHS: Array[String] = [
	"res://data/body_parts/head_sensor_array.tres",
	"res://data/body_parts/torso_reinforced_plating.tres",
	"res://data/body_parts/left_arm_rapid_fire.tres",
	"res://data/body_parts/right_arm_cannon.tres",
	"res://data/body_parts/legs_servo_boost.tres",
]

const ALL_ITEM_PATHS: Array[String] = [
	"res://data/run_items/plating_shard.tres",
	"res://data/run_items/range_booster.tres",
	"res://data/run_items/overclock_chip.tres",
	"res://data/run_items/ricochet_module.tres",
	"res://data/run_items/scatter_core.tres",
	"res://data/run_items/volatile_round.tres",
]

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var data:         RoomData = null
var _floor:       Node     = null   # reference to floor.gd node
var _enemy_count: int      = 0
var _doors:       Dictionary = {}   # direction -> Area2D trigger

# ---------------------------------------------------------------------------
# Node refs (set by room_base.tscn)
# ---------------------------------------------------------------------------
@onready var floor_poly:    Polygon2D = $Floor
@onready var walls_node:    Node2D    = $Walls
@onready var door_triggers: Node2D    = $DoorTriggers
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

# ---------------------------------------------------------------------------
# Activate — called on first (and repeat) entry
# ---------------------------------------------------------------------------
func activate() -> void:
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
		area.body_entered.connect(_on_door_entered.bind(dir))
		door_triggers.add_child(area)
		_doors[dir] = area


func _on_door_entered(body: Node, direction: String) -> void:
	if body.is_in_group("player"):
		_floor.call_deferred(
			"transition_to", data.connections[direction], direction
		)

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
		enemy.tree_exited.connect(_on_enemy_died, CONNECT_DEFERRED)
		_enemy_count += 1


func _spawn_boss() -> void:
	var boss = SUPERVISOR_SCENE.instantiate()
	contents.add_child(boss)
	boss.global_position = to_global(Vector2.ZERO)   # room centre
	boss.tree_exited.connect(_on_enemy_died, CONNECT_DEFERRED)
	_enemy_count = 1


func _on_enemy_died() -> void:
	_enemy_count -= 1
	if _enemy_count <= 0:
		data.cleared = true
		if data.type == RoomData.RoomType.BOSS:
			_spawn_body_part_drop()
			_spawn_floor_exit()
		room_cleared.emit()
		_update_door_locks()


func _spawn_floor_exit() -> void:
	# Visual — bright teal portal offset from body part drop (which is at center)
	var poly     := Polygon2D.new()
	poly.polygon  = PackedVector2Array([-35, -50, 35, -50, 35, 50, -35, 50])
	poly.color    = Color(0.2, 0.85, 0.9)
	poly.position = Vector2(120, 0)
	contents.add_child(poly)

	var lbl      := Label.new()
	lbl.text     = "NEXT FLOOR"
	lbl.position = Vector2(85, -75)
	contents.add_child(lbl)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 2

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size  = Vector2(70, 100)
	cs.shape = rs
	area.add_child(cs)
	area.position = Vector2(120, 0)

	area.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			RunManager.player_health_carry = body.stats.current_health
			RunManager.advance_floor()
			get_tree().call_deferred("change_scene_to_file", "res://scenes/run/floor.tscn"))
	contents.add_child(area)


func _spawn_body_part_drop() -> void:
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
	var chosen: String = ALL_ITEM_PATHS[randi() % ALL_ITEM_PATHS.size()]
	var pickup         = RUN_ITEM_PICKUP.instantiate()
	pickup.item        = load(chosen)
	pickup.position    = Vector2.ZERO
	contents.add_child(pickup)

# ---------------------------------------------------------------------------
# Door locking
# ---------------------------------------------------------------------------
func _update_door_locks() -> void:
	var is_combat := data.type == RoomData.RoomType.COMBAT \
				  or data.type == RoomData.RoomType.BOSS
	var locked := data.visited and not data.cleared and is_combat
	for area in _doors.values():
		(area as Area2D).monitoring = not locked
