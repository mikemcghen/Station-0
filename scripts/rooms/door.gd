extends Node2D
class_name RoomDoor

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const DOOR_THICKNESS := 12.0
const INDICATOR_SIZE := 10.0
const INDICATOR_OFFSET := 20.0  # distance above door

# Indicator light colors - only for special rooms, matching floor colors but brighter
const INDICATOR_COLORS := {
	RoomData.RoomType.ITEM:   Color(0.2, 0.45, 0.2),   # green (brighter version of 0.10, 0.16, 0.10)
	RoomData.RoomType.SHOP:   Color(0.9, 0.75, 0.1),   # yellow
	RoomData.RoomType.BOSS:   Color(0.7, 0.15, 0.15),  # red (brighter version of 0.20, 0.08, 0.08)
}

# Room types that should show indicator lights
const SPECIAL_ROOM_TYPES := [
	RoomData.RoomType.ITEM,
	RoomData.RoomType.SHOP,
	RoomData.RoomType.BOSS,
]

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var direction: String = ""  # "up", "down", "left", "right"
var door_size: Vector2 = Vector2.ZERO
var adjacent_room_type: RoomData.RoomType = RoomData.RoomType.COMBAT

var _barrier: StaticBody2D = null
var _barrier_collision: CollisionShape2D = null
var _barrier_visual: Polygon2D = null
var _indicator: Polygon2D = null
var _is_locked: bool = false

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
func setup(dir: String, size: Vector2, adj_type: RoomData.RoomType) -> void:
	direction = dir
	door_size = size
	adjacent_room_type = adj_type

	_build_barrier()
	_build_indicator()

	# Start unlocked (open)
	unlock()


func _build_barrier() -> void:
	_barrier = StaticBody2D.new()
	_barrier.collision_layer = 1  # world layer - blocks player
	_barrier.collision_mask = 0

	_barrier_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = door_size
	_barrier_collision.shape = shape
	_barrier.add_child(_barrier_collision)

	# Visual - solid rectangle
	_barrier_visual = Polygon2D.new()
	var hx := door_size.x / 2.0
	var hy := door_size.y / 2.0
	_barrier_visual.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy),
		Vector2(hx, hy), Vector2(-hx, hy),
	])
	_barrier_visual.color = Color(0.4, 0.35, 0.3)  # metallic brown
	_barrier.add_child(_barrier_visual)

	add_child(_barrier)


func _build_indicator() -> void:
	# Only show indicators for special rooms (ITEM, SHOP, BOSS)
	if adjacent_room_type not in SPECIAL_ROOM_TYPES:
		return

	_indicator = Polygon2D.new()

	# Small diamond shape for indicator
	var s := INDICATOR_SIZE
	_indicator.polygon = PackedVector2Array([
		Vector2(0, -s), Vector2(s, 0),
		Vector2(0, s), Vector2(-s, 0),
	])

	# Position based on door direction
	var offset := Vector2.ZERO
	match direction:
		"up":    offset = Vector2(0, -door_size.y / 2.0 - INDICATOR_OFFSET)
		"down":  offset = Vector2(0, door_size.y / 2.0 + INDICATOR_OFFSET)
		"left":  offset = Vector2(-door_size.x / 2.0 - INDICATOR_OFFSET, 0)
		"right": offset = Vector2(door_size.x / 2.0 + INDICATOR_OFFSET, 0)

	_indicator.position = offset
	_indicator.color = INDICATOR_COLORS[adjacent_room_type]

	add_child(_indicator)


# ---------------------------------------------------------------------------
# Lock/Unlock
# ---------------------------------------------------------------------------
func lock() -> void:
	_is_locked = true
	_barrier_collision.disabled = false
	_barrier_visual.visible = true


func unlock() -> void:
	_is_locked = false
	_barrier_collision.disabled = true
	_barrier_visual.visible = false


func is_locked() -> bool:
	return _is_locked
