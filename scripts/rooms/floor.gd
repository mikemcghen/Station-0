extends Node2D

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const ROOM_SCENE      = preload("res://scenes/run/rooms/room_base.tscn")
const ROOM_W          := 960.0
const ROOM_H          := 540.0
const TRANSITION_TIME := 0.25
const ENTRY_INSET     := 60.0    # how far from wall edge the player appears

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var rooms_container: Node2D   = $Rooms
@onready var camera:          Camera2D = $Camera2D
@onready var player:          Node2D   = $Player

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _rooms:           Dictionary = {}   # Vector2i -> Room
var _rooms_data:      Dictionary = {}   # Vector2i -> RoomData (for mini map)
var _current_grid:    Vector2i
var _transitioning:   bool = false

# ---------------------------------------------------------------------------
# Boot
# ---------------------------------------------------------------------------
func _ready() -> void:
	var floor_num: int = max(RunManager.current_floor, 1)
	_build_floor(FloorGenerator.generate(floor_num))


func _build_floor(floor_data: Array) -> void:
	var start_pos := Vector2i.ZERO

	for room_data in floor_data:
		var room_node: Room = ROOM_SCENE.instantiate()
		room_node.position = _grid_to_world(room_data.grid_pos)
		rooms_container.add_child(room_node)
		room_node.setup(room_data, self)
		_rooms[room_data.grid_pos] = room_node
		_rooms_data[room_data.grid_pos] = room_data

		if room_data.type == RoomData.RoomType.START:
			start_pos = room_data.grid_pos

	# Snap camera + player to start room
	var world_start := _grid_to_world(start_pos)
	camera.position        = world_start
	player.global_position = world_start
	_current_grid          = start_pos
	_rooms[start_pos].activate()

	# Emit signals for mini map
	EventBus.floor_map_ready.emit(_rooms_data)
	EventBus.room_entered_at.emit(start_pos)

# ---------------------------------------------------------------------------
# Transitions
# ---------------------------------------------------------------------------
func transition_to(target_grid: Vector2i, from_direction: String) -> void:
	if _transitioning:
		return
	_transitioning    = true
	_current_grid     = target_grid
	EventBus.room_entered_at.emit(target_grid)

	var new_world := _grid_to_world(target_grid)

	# Teleport player to the entry side of the new room immediately
	player.global_position = new_world + _entry_offset(from_direction)

	# Activate the room (may spawn enemies) — we're outside physics here
	_rooms[target_grid].activate()

	# Slide the camera
	var tween := create_tween()
	tween.tween_property(camera, "position", new_world, TRANSITION_TIME)
	tween.tween_callback(func(): _transitioning = false)


func _entry_offset(from_direction: String) -> Vector2:
	# Player exits through `from_direction`; they enter the new room
	# from the opposite side.
	var i := ENTRY_INSET
	match from_direction:
		"up":    return Vector2(0,    ROOM_H / 2.0 - i)   # enter at bottom
		"down":  return Vector2(0,   -ROOM_H / 2.0 + i)   # enter at top
		"left":  return Vector2( ROOM_W / 2.0 - i, 0)     # enter at right
		"right": return Vector2(-ROOM_W / 2.0 + i, 0)     # enter at left
	return Vector2.ZERO

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * ROOM_W, grid_pos.y * ROOM_H)


# Returns the RoomData.RoomType for the room at the given grid position.
# Returns -1 if no room exists at that position.
func get_room_type_at(grid_pos: Vector2i) -> int:
	if _rooms.has(grid_pos):
		return _rooms[grid_pos].data.type
	return -1
