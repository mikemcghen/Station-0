extends EnemyBase

# ---------------------------------------------------------------------------
# Warden — Floor 1 boss
# Orbits the room center. Barrier sweeps + proximity mines.
# ---------------------------------------------------------------------------

enum Phase { ONE, TWO, CLIMAX }

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const ORBIT_RADIUS   := 220.0
const ROOM_HW        := 480.0
const ROOM_HH        := 270.0
const WALL_T         := 32.0

const ORBIT_SPEED_P1 := 0.55    # rad/sec ≈ 31 deg/sec
const ORBIT_SPEED_P2 := 0.85    # rad/sec ≈ 49 deg/sec

const TELEGRAPH_TIME := 0.8
const PASS_DELAY     := 1.2

const SWEEP_SPEED_P1 := 50.0
const SWEEP_SPEED_P2 := 85.0
const SWEEP_CD_P1    := 6.5
const SWEEP_CD_P2    := 4.5
const PROJ_SPACING   := 18.0
const GAP_W          := 90.0

const MINE_CD_P1     := 5.5
const MINE_CD_P2     := 3.5
const MINE_RADIUS    := 22.0
const MINE_CAP       := 10

const FREEZE_DURATION := 1.5

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _phase: Phase = Phase.ONE

var _room_center: Vector2 = Vector2.ZERO
var _orbit_angle: float   = 0.0

# Sweep
var _sweep_cd_timer:   float = 3.0   # initial delay before first sweep
var _telegraphing:     bool  = false
var _telegraph_timer:  float = 0.0
var _passes_total:     int   = 0
var _passes_fired:     int   = 0
var _pass_delay_timer: float = 0.0
var _sweep_dir:        float = 1.0   # 1 = downward, -1 = upward
var _sweep_projs:      Array = []    # [{node: Node2D, vel: Vector2}]

# Mines
var _mine_cd_timer: float = MINE_CD_P1
var _mines:         Array = []       # [Node2D]

# Climax
var _freeze_timer: float = 0.0

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	max_health       = 150.0
	current_health   = 150.0
	contact_damage   = 1.0
	contact_cooldown = 0.8
	super._ready()
	_room_center    = global_position
	_orbit_angle    = 0.0
	global_position = _room_center + Vector2(ORBIT_RADIUS, 0.0)

# ---------------------------------------------------------------------------
# Physics loop
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_find_player()
	_tick_contact(delta)
	_tick_flash(delta)
	_tick_sweep_projs(delta)

	if _phase == Phase.ONE and current_health / max_health <= 0.4:
		_enter_phase_two()

	match _phase:
		Phase.ONE, Phase.TWO:
			_do_orbit(ORBIT_SPEED_P2 if _phase == Phase.TWO else ORBIT_SPEED_P1, delta)
			_tick_sweep(delta)
			_tick_mines(delta)
		Phase.CLIMAX:
			_do_climax(delta)

	move_and_slide()

# ---------------------------------------------------------------------------
# Phase transitions
# ---------------------------------------------------------------------------
func _enter_phase_two() -> void:
	_phase          = Phase.TWO
	_sweep_cd_timer = SWEEP_CD_P2 * 0.6   # first P2 sweep sooner

func _enter_climax() -> void:
	_phase        = Phase.CLIMAX
	velocity      = Vector2.ZERO
	_freeze_timer = FREEZE_DURATION
	_telegraphing = false

# ---------------------------------------------------------------------------
# Orbit — position set directly; velocity stays zero so move_and_slide is no-op
# ---------------------------------------------------------------------------
func _do_orbit(angular_speed: float, delta: float) -> void:
	if _telegraphing:
		velocity = Vector2.ZERO
		return
	_orbit_angle    += angular_speed * delta
	global_position  = _room_center + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * ORBIT_RADIUS
	velocity         = Vector2.ZERO

# ---------------------------------------------------------------------------
# Barrier Sweep — multi-pass horizontal wall with gaps
# ---------------------------------------------------------------------------
func _tick_sweep(delta: float) -> void:
	# Telegraph: boss pauses + flashes yellow, then fires first pass
	if _telegraphing:
		_telegraph_timer -= delta
		if _telegraph_timer <= 0.0:
			_telegraphing     = false
			_passes_fired     = 0
			_pass_delay_timer = 0.0
			_fire_sweep_pass()
		return

	# Waiting between passes
	if _passes_fired > 0 and _passes_fired < _passes_total:
		_pass_delay_timer -= delta
		if _pass_delay_timer <= 0.0:
			_fire_sweep_pass()
		return

	# All passes done — start cooldown
	if _passes_total > 0 and _passes_fired >= _passes_total:
		_passes_total   = 0
		_passes_fired   = 0
		_sweep_cd_timer = SWEEP_CD_P2 if _phase == Phase.TWO else SWEEP_CD_P1
		return

	# Cooldown ticking
	_sweep_cd_timer -= delta
	if _sweep_cd_timer <= 0.0:
		_telegraphing    = true
		_telegraph_timer = TELEGRAPH_TIME
		_passes_total    = randi_range(2, 4) if _phase == Phase.TWO else randi_range(1, 3)
		_sweep_dir       = 1.0 if randf() < 0.5 else -1.0


func _fire_sweep_pass() -> void:
	_passes_fired    += 1
	_pass_delay_timer = PASS_DELAY

	var proj_speed  := SWEEP_SPEED_P2 if _phase == Phase.TWO else SWEEP_SPEED_P1
	var move_vel    := Vector2(0.0, proj_speed * _sweep_dir)
	var inner_left  := -ROOM_HW + WALL_T
	var inner_right :=  ROOM_HW - WALL_T
	var room_w      := inner_right - inner_left
	var num_gaps    := randi_range(1, 3)

	# Gap centers evenly spaced
	var gaps: Array[float] = []
	for i in num_gaps:
		gaps.append(inner_left + room_w * float(i + 1) / float(num_gaps + 1))

	# Start Y: outside the wall at the entering edge
	var start_y: float
	if _sweep_dir > 0.0:
		start_y = _room_center.y - ROOM_HH + WALL_T - 10.0   # top, moving down
	else:
		start_y = _room_center.y + ROOM_HH - WALL_T + 10.0   # bottom, moving up

	var x := inner_left
	while x <= inner_right:
		var in_gap := false
		for gx in gaps:
			if abs(x - gx) < GAP_W * 0.5:
				in_gap = true
				break
		if not in_gap:
			_spawn_sweep_proj(Vector2(_room_center.x + x, start_y), move_vel)
		x += PROJ_SPACING


func _spawn_sweep_proj(world_pos: Vector2, vel: Vector2) -> void:
	var proj := Node2D.new()

	var rect       := ColorRect.new()
	rect.size       = Vector2(14.0, 14.0)
	rect.position   = Vector2(-7.0, -7.0)
	rect.color      = Color(0.9, 0.7, 0.1, 0.9)
	proj.add_child(rect)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size  = Vector2(12.0, 12.0)
	cs.shape = rs
	area.add_child(cs)
	area.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			body.take_damage(1.0)
			proj.queue_free())
	proj.add_child(area)

	get_parent().add_child(proj)
	proj.global_position = world_pos   # set after add_child so global_position resolves
	_sweep_projs.append({"node": proj, "vel": vel})


func _tick_sweep_projs(delta: float) -> void:
	var i := _sweep_projs.size() - 1
	while i >= 0:
		var entry: Dictionary = _sweep_projs[i]
		var node              = entry["node"]   # untyped — prevents crash on freed instance
		if not is_instance_valid(node):
			_sweep_projs.remove_at(i)
			i -= 1
			continue
		node.global_position += entry["vel"] * delta
		if absf(node.global_position.y - _room_center.y) > ROOM_HH + 30.0:
			node.queue_free()
			_sweep_projs.remove_at(i)
		i -= 1

# ---------------------------------------------------------------------------
# Mine Drop — stationary proximity mine at current orbit position
# ---------------------------------------------------------------------------
func _tick_mines(delta: float) -> void:
	# Prune freed references
	_mines = _mines.filter(func(m: Node) -> bool: return is_instance_valid(m))

	_mine_cd_timer -= delta
	if _mine_cd_timer <= 0.0:
		_mine_cd_timer = MINE_CD_P2 if _phase == Phase.TWO else MINE_CD_P1
		if _mines.size() < MINE_CAP:
			_spawn_mine(global_position)


func _spawn_mine(world_pos: Vector2) -> void:
	var mine := Node2D.new()

	# Visual — dark red polygon circle
	var poly := Polygon2D.new()
	var pts  := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		pts.append(Vector2(cos(a), sin(a)) * MINE_RADIUS)
	poly.polygon = pts
	poly.color   = Color(0.55, 0.05, 0.05, 0.9)
	mine.add_child(poly)

	var area   := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 2
	var cs     := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = MINE_RADIUS
	cs.shape      = circle
	area.add_child(cs)
	area.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			body.take_damage(1.0)
			mine.queue_free())
	mine.add_child(area)

	get_parent().add_child(mine)
	mine.global_position = world_pos
	_mines.append(mine)


func _clear_mines() -> void:
	for mine in _mines:
		if is_instance_valid(mine):
			mine.queue_free()
	_mines.clear()

# ---------------------------------------------------------------------------
# Climax — freeze + blink, then die
# ---------------------------------------------------------------------------
func _do_climax(delta: float) -> void:
	velocity       = Vector2.ZERO
	_freeze_timer -= delta
	var blink      := fmod(_freeze_timer, 0.3) < 0.15
	visual.modulate = Color(2.0, 0.3, 0.3) if blink else Color(0.25, 0.08, 0.08)
	if _freeze_timer <= 0.0:
		_die()

# ---------------------------------------------------------------------------
# Damage / death
# ---------------------------------------------------------------------------
func take_damage(amount: float) -> void:
	if _phase == Phase.CLIMAX:
		return   # already dying
	current_health -= amount
	_flash_timer    = 0.1
	EventBus.boss_health_changed.emit(maxf(current_health, 0.0), max_health)
	if current_health <= 0.0:
		_enter_climax()


func _die() -> void:
	_clear_mines()
	for entry in _sweep_projs:
		if is_instance_valid(entry["node"]):
			entry["node"].queue_free()
	_sweep_projs.clear()
	EventBus.boss_died.emit()
	queue_free()

# ---------------------------------------------------------------------------
# Visual — phase-aware tints (overrides EnemyBase._tick_flash)
# ---------------------------------------------------------------------------
func _tick_flash(delta: float) -> void:
	if _phase == Phase.CLIMAX:
		return   # _do_climax owns the visual

	# Telegraph: yellow warning pulse (same pattern as Supervisor wind-up)
	if _telegraphing:
		var pulse := fmod(_telegraph_timer, 0.18) < 0.09
		var base  := Color(1.0, 0.65, 0.2) if _phase == Phase.TWO else Color(1.0, 1.0, 1.0)
		visual.modulate = Color(2.4, 2.1, 0.3) if pulse else base
		return

	# Hit flash
	if _flash_timer > 0.0:
		_flash_timer   -= delta
		visual.modulate = Color(2.5, 2.5, 2.5)
		return

	# Idle tint
	visual.modulate = Color(1.0, 0.65, 0.2) if _phase == Phase.TWO else Color(1.0, 1.0, 1.0)
