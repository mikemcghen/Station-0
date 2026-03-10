extends Control

# ---------------------------------------------------------------------------
# Layout constants
# ---------------------------------------------------------------------------
const MAP_SIZE := Vector2(150, 150)
const ROOM_SIZE := Vector2(26, 15)   # 16:9 aspect ratio like actual rooms
const ROOM_GAP := 4.0
const PADDING := 10.0
const CONNECTION_WIDTH := 2.0
const PARALLAX_STRENGTH := 4.0   # max pixels the map shifts with player movement

# Room dimensions (must match floor.gd)
const ROOM_W := 960.0
const ROOM_H := 540.0

# ---------------------------------------------------------------------------
# Colors (brightened versions of room.gd floor colors)
# ---------------------------------------------------------------------------
const ROOM_COLORS := {
	RoomData.RoomType.START:  Color(0.24, 0.24, 0.36),   # blue-grey
	RoomData.RoomType.COMBAT: Color(0.24, 0.24, 0.36),   # blue-grey
	RoomData.RoomType.ITEM:   Color(0.20, 0.32, 0.20),   # green
	RoomData.RoomType.SHOP:   Color(0.32, 0.24, 0.16),   # brown
	RoomData.RoomType.BOSS:   Color(0.40, 0.16, 0.16),   # red
}
const CURRENT_OUTLINE := Color(1.0, 1.0, 0.4)   # bright yellow
const CONNECTION_COLOR := Color(0.5, 0.5, 0.6)
const UNVISITED_ALPHA := 0.35
const BACKGROUND_COLOR := Color(0.08, 0.08, 0.10, 0.85)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _rooms_data: Dictionary = {}   # Vector2i -> RoomData
var _current_pos: Vector2i = Vector2i.ZERO
var _grid_min: Vector2i = Vector2i.ZERO
var _grid_max: Vector2i = Vector2i.ZERO
var _parallax_offset: Vector2 = Vector2.ZERO
var _player: Node2D = null

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Position in top-right corner
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -MAP_SIZE.x - PADDING
	offset_right = -PADDING
	offset_top = PADDING
	offset_bottom = MAP_SIZE.y + PADDING
	custom_minimum_size = MAP_SIZE

	# Connect signals
	EventBus.floor_map_ready.connect(_on_floor_map_ready)
	EventBus.room_entered_at.connect(_on_room_entered)
	EventBus.run_ended.connect(_on_run_ended)

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------
func _on_floor_map_ready(rooms_data: Dictionary) -> void:
	_rooms_data = rooms_data
	_compute_grid_bounds()
	queue_redraw()


func _on_room_entered(grid_pos: Vector2i) -> void:
	_current_pos = grid_pos
	queue_redraw()


func _on_run_ended(_reached_hub: bool) -> void:
	_rooms_data.clear()
	_player = null
	queue_redraw()


func _process(_delta: float) -> void:
	if _rooms_data.is_empty():
		return

	# Find player if not cached
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return

	# Calculate player position within current room (-0.5 to 0.5 range)
	var room_center := Vector2(_current_pos.x * ROOM_W, _current_pos.y * ROOM_H)
	var local_pos := _player.global_position - room_center
	var normalized := Vector2(
		clampf(local_pos.x / (ROOM_W * 0.5), -1.0, 1.0),
		clampf(local_pos.y / (ROOM_H * 0.5), -1.0, 1.0)
	)

	# Apply subtle parallax (inverted so map moves opposite to player)
	var new_offset := -normalized * PARALLAX_STRENGTH
	if not new_offset.is_equal_approx(_parallax_offset):
		_parallax_offset = new_offset
		queue_redraw()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _compute_grid_bounds() -> void:
	if _rooms_data.is_empty():
		_grid_min = Vector2i.ZERO
		_grid_max = Vector2i.ZERO
		return

	var first := true
	for pos in _rooms_data.keys():
		if first:
			_grid_min = pos
			_grid_max = pos
			first = false
		else:
			_grid_min.x = mini(_grid_min.x, pos.x)
			_grid_min.y = mini(_grid_min.y, pos.y)
			_grid_max.x = maxi(_grid_max.x, pos.x)
			_grid_max.y = maxi(_grid_max.y, pos.y)


func _get_visible_rooms() -> Dictionary:
	# Returns {Vector2i -> {"data": RoomData, "visited": bool}}
	var visible := {}
	var known_positions: Array[Vector2i] = []

	# First pass: collect visited rooms and their adjacent positions
	for pos in _rooms_data.keys():
		var room: RoomData = _rooms_data[pos]
		if room.visited:
			visible[pos] = {"data": room, "visited": true}
			for conn_pos in room.connections.values():
				if conn_pos not in known_positions:
					known_positions.append(conn_pos)

	# Second pass: add adjacent (known but unvisited) rooms
	for pos in known_positions:
		if pos not in visible and _rooms_data.has(pos):
			visible[pos] = {"data": _rooms_data[pos], "visited": false}

	return visible


func _grid_to_map_pos(grid_pos: Vector2i) -> Vector2:
	# Convert grid position to local drawing coordinates
	var cell_size := ROOM_SIZE + Vector2(ROOM_GAP, ROOM_GAP)
	var grid_size := Vector2i(_grid_max.x - _grid_min.x + 1, _grid_max.y - _grid_min.y + 1)
	var total_size := Vector2(grid_size.x, grid_size.y) * cell_size - Vector2(ROOM_GAP, ROOM_GAP)

	# Center the map within the control, apply parallax offset
	var centering := (MAP_SIZE - total_size) / 2.0 + _parallax_offset
	var offset := Vector2(
		(grid_pos.x - _grid_min.x) * cell_size.x,
		(grid_pos.y - _grid_min.y) * cell_size.y
	)
	return centering + offset

# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------
func _draw() -> void:
	if _rooms_data.is_empty():
		return

	# Background panel
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), BACKGROUND_COLOR)

	var visible := _get_visible_rooms()

	# Draw connections first (under rooms)
	for pos in visible.keys():
		var room: RoomData = visible[pos]["data"]
		var room_center := _grid_to_map_pos(pos) + ROOM_SIZE / 2.0
		for dir in room.connections.keys():
			var conn_pos: Vector2i = room.connections[dir]
			if visible.has(conn_pos):
				var conn_center := _grid_to_map_pos(conn_pos) + ROOM_SIZE / 2.0
				# Only draw each connection once (from lower to higher grid pos)
				if pos.x < conn_pos.x or (pos.x == conn_pos.x and pos.y < conn_pos.y):
					draw_line(room_center, conn_center, CONNECTION_COLOR, CONNECTION_WIDTH)

	# Draw rooms
	for pos in visible.keys():
		var info: Dictionary = visible[pos]
		var room: RoomData = info["data"]
		var is_visited: bool = info["visited"]
		var map_pos := _grid_to_map_pos(pos)
		var rect := Rect2(map_pos, ROOM_SIZE)

		# Room color with alpha based on visited state
		var color: Color = ROOM_COLORS.get(room.type, ROOM_COLORS[RoomData.RoomType.COMBAT])
		if not is_visited:
			color.a = UNVISITED_ALPHA
		draw_rect(rect, color)

		# Current room indicator - bright outline
		if pos == _current_pos:
			draw_rect(rect, CURRENT_OUTLINE, false, 2.0)
