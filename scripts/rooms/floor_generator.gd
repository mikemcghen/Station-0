class_name FloorGenerator

const GRID_START := Vector2i(5, 5)
const MIN_ROOMS  := 8
const MAX_ROOMS  := 12

const DIRS := {
	"up":    Vector2i( 0, -1),
	"down":  Vector2i( 0,  1),
	"left":  Vector2i(-1,  0),
	"right": Vector2i( 1,  0),
}
const OPPOSITE := {
	"up": "down", "down": "up", "left": "right", "right": "left",
}

# Returns Array of RoomData covering one floor layout.
static func generate(floor_number: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var rooms: Dictionary = {}   # Vector2i -> RoomData

	# --- Start room ---
	var start := RoomData.new()
	start.type     = RoomData.RoomType.START
	start.grid_pos = GRID_START
	rooms[GRID_START] = start

	var queue:  Array = [GRID_START]
	var target: int   = rng.randi_range(MIN_ROOMS, MAX_ROOMS)

	# --- Random walk ---
	while rooms.size() < target and queue.size() > 0:
		var pos: Vector2i = queue[rng.randi() % queue.size()]

		for dir_name in _shuffled(rng, ["up", "down", "left", "right"]):
			if rooms.size() >= target:
				break

			var next: Vector2i = pos + DIRS[dir_name]
			if rooms.has(next):
				continue

			# Skip if the candidate cell already has >1 existing neighbor
			# (prevents overly dense clusters)
			var neighbor_count := 0
			for d in DIRS.values():
				if rooms.has(next + d):
					neighbor_count += 1
			if neighbor_count > 1:
				continue

			var r := RoomData.new()
			r.type     = RoomData.RoomType.COMBAT
			r.grid_pos = next
			rooms[next] = r
			queue.append(next)

			# Bidirectional connection
			rooms[pos].connections[dir_name]          = next
			r.connections[OPPOSITE[dir_name]]         = pos

	# --- Boss: farthest room from start ---
	var boss_pos := _farthest(GRID_START, rooms)
	rooms[boss_pos].type = RoomData.RoomType.BOSS

	# --- Item + Shop: dead-end COMBAT rooms ---
	var dead_ends: Array = []
	for p in rooms:
		var rd: RoomData = rooms[p]
		if rd.type == RoomData.RoomType.COMBAT and rd.connections.size() == 1:
			dead_ends.append(p)
	dead_ends.shuffle()

	if dead_ends.size() >= 1:
		rooms[dead_ends[0]].type = RoomData.RoomType.ITEM
	if dead_ends.size() >= 2:
		rooms[dead_ends[1]].type = RoomData.RoomType.SHOP

	return rooms.values()


static func _shuffled(rng: RandomNumberGenerator, arr: Array) -> Array:
	var result := arr.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j    := rng.randi() % (i + 1)
		var tmp   = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result


static func _farthest(start: Vector2i, rooms: Dictionary) -> Vector2i:
	var visited: Dictionary = {}
	var queue:   Array      = [[start, 0]]
	var farthest := start
	var max_dist := 0

	while queue.size() > 0:
		var entry  = queue.pop_front()
		var pos: Vector2i = entry[0]
		var dist: int     = entry[1]

		if visited.has(pos):
			continue
		visited[pos] = true

		if dist > max_dist:
			max_dist = dist
			farthest = pos

		var rd: RoomData = rooms[pos]
		for connected in rd.connections.values():
			if not visited.has(connected):
				queue.append([connected, dist + 1])

	return farthest
