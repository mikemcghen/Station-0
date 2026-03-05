extends Node2D

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const HUB_ROOM_SCENE  = preload("res://scenes/hub/rooms/hub_room_base.tscn")
const ROOM_W          := 960.0
const ROOM_H          := 540.0
const TRANSITION_TIME := 0.25
const ENTRY_INSET     := 60.0

# Fixed hub layout — 7 rooms arranged as:
#
#  [Control(-1,-1)]
#         |
#  [Armory(-1,0)]-[Staging(0,0)]-[Shop(1,0)]
#         |               |              |
#  [Practice(-1,1)]-[Cafeteria(0,1)]-[Trophy(1,1)]
#
# HubRoomType: STAGING=0, ARMORY=1, CAFETERIA=2, SHOP=3, CONTROL_ROOM=4, TROPHY_ROOM=5, PRACTICE=6
const LAYOUT := [
	{"type": 0, "grid": Vector2i( 0,  0)},   # STAGING
	{"type": 4, "grid": Vector2i(-1, -1)},   # CONTROL_ROOM
	{"type": 1, "grid": Vector2i(-1,  0)},   # ARMORY
	{"type": 3, "grid": Vector2i( 1,  0)},   # SHOP
	{"type": 6, "grid": Vector2i(-1,  1)},   # PRACTICE
	{"type": 2, "grid": Vector2i( 0,  1)},   # CAFETERIA
	{"type": 5, "grid": Vector2i( 1,  1)},   # TROPHY_ROOM
]

const DIRS := {
	"up":    Vector2i( 0, -1),
	"down":  Vector2i( 0,  1),
	"left":  Vector2i(-1,  0),
	"right": Vector2i( 1,  0),
}

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var rooms_container: Node2D      = $Rooms
@onready var camera:          Camera2D    = $Camera2D
@onready var player:          Node2D      = $Player
@onready var armory_ui:       CanvasLayer = $ArmoryUI
@onready var atm_ui:          CanvasLayer = $AtmUI

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _rooms:         Dictionary = {}   # Vector2i -> HubRoom
var _current_grid:  Vector2i
var _transitioning: bool = false

# ---------------------------------------------------------------------------
# Boot
# ---------------------------------------------------------------------------
func _ready() -> void:
	_build_hub()


func _build_hub() -> void:
	var connections := _compute_connections()

	for entry in LAYOUT:
		var grid_pos: Vector2i = entry["grid"]
		var room_type: int      = entry["type"]
		var conn: Dictionary    = connections.get(grid_pos, {})

		var room_node: HubRoom = HUB_ROOM_SCENE.instantiate()
		room_node.position = _grid_to_world(grid_pos)
		rooms_container.add_child(room_node)
		room_node.setup(room_type, conn, self)
		_rooms[grid_pos] = room_node

	# Start in Staging Area; player spawns below center so the portal is visible
	var staging_world := _grid_to_world(Vector2i(0, 0))
	camera.position        = staging_world
	player.global_position = staging_world + Vector2(0, 80)
	_current_grid          = Vector2i(0, 0)


func _compute_connections() -> Dictionary:
	var grid := {}
	for entry in LAYOUT:
		grid[entry["grid"]] = true

	var result := {}
	for entry in LAYOUT:
		var pos: Vector2i = entry["grid"]
		var conn := {}
		for dir_name in DIRS:
			var nb: Vector2i = pos + DIRS[dir_name]
			if grid.has(nb):
				conn[dir_name] = nb
		result[pos] = conn

	return result

# ---------------------------------------------------------------------------
# Transitions (identical pattern to floor.gd)
# ---------------------------------------------------------------------------
func transition_to(target_grid: Vector2i, from_direction: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	_current_grid  = target_grid

	var new_world := _grid_to_world(target_grid)
	player.global_position = new_world + _entry_offset(from_direction)

	var tween := create_tween()
	tween.tween_property(camera, "position", new_world, TRANSITION_TIME)
	tween.tween_callback(func(): _transitioning = false)


func _entry_offset(from_direction: String) -> Vector2:
	var i := ENTRY_INSET
	match from_direction:
		"up":    return Vector2(0,    ROOM_H / 2.0 - i)
		"down":  return Vector2(0,   -ROOM_H / 2.0 + i)
		"left":  return Vector2( ROOM_W / 2.0 - i, 0)
		"right": return Vector2(-ROOM_W / 2.0 + i, 0)
	return Vector2.ZERO

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * ROOM_W, grid_pos.y * ROOM_H)

# ---------------------------------------------------------------------------
# Armory
# ---------------------------------------------------------------------------
func open_armory() -> void:
	armory_ui.open()

func open_atm() -> void:
	atm_ui.open()
