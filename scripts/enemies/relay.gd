extends EnemyBase

# ---------------------------------------------------------------------------
# Relay — Floor 2 boss
# Teleports around the room, fires burst projectiles, spawns Drifters.
# ---------------------------------------------------------------------------

enum Phase { ONE, TWO, CLIMAX }

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const ROOM_HW        := 480.0
const ROOM_HH        := 270.0
const WALL_T         := 32.0
const WALL_MARGIN    := 60.0

const TELEPORT_CD_P1_MIN := 6.0
const TELEPORT_CD_P1_MAX := 8.0
const TELEPORT_CD_P2_MIN := 4.0
const TELEPORT_CD_P2_MAX := 5.0

const FADE_OUT_TIME  := 0.1
const TRANSIT_TIME   := 0.4

const BURST_COUNT_P1 := 8
const BURST_COUNT_P2 := 12
const BURST_SPEED    := 150.0
const PROJ_SIZE      := 12.0

const HOMING_COUNT_P1    := 4
const HOMING_COUNT_P2    := 6
const HOMING_SPEED       := 100.0
const HOMING_TURN_SPEED  := 1.8   # radians per second
const HOMING_DELAY       := 0.3   # delay after radial burst before homing fires
const HOMING_LIFETIME    := 4.0   # seconds before homing projectiles expire

const DRIFTER_SPAWN_MIN := 2
const DRIFTER_SPAWN_MAX := 4
const DRIFTER_COUNT_P1_MIN := 2
const DRIFTER_COUNT_P1_MAX := 3
const DRIFTER_COUNT_P2_MIN := 3
const DRIFTER_COUNT_P2_MAX := 4
const DRIFTER_OFFSET_MIN := 40.0
const DRIFTER_OFFSET_MAX := 80.0

const FREEZE_DURATION := 1.5

const DRIFTER_SCENE = preload("res://scenes/enemies/drifter.tscn")

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _phase           : Phase = Phase.ONE
var _room_center     : Vector2
var _visual          : Node2D
var _contact_area    : Area2D

var _teleport_timer  : float = 3.0   # initial delay before first teleport
var _transit_timer   : float = 0.0
var _fade_timer      : float = 0.0

var _teleport_count  : int = 0
var _next_drifter_threshold : int = 0

var _burst_projs     : Array[Node2D] = []
var _homing_projs    : Array[Node2D] = []
var _homing_delay    : float = 0.0

var _climax_timer    : float = 0.0
var _blink_accum     : float = 0.0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	super._ready()
	max_health = 200.0
	current_health = max_health
	contact_damage = 1.0
	contact_cooldown = 0.8

	_visual = $Visual
	_contact_area = $ContactArea

	_room_center = global_position
	_roll_drifter_threshold()
	_teleport_timer = 2.5   # initial delay before first teleport

func _physics_process(delta: float) -> void:
	_tick_spawn_delay(delta)
	_find_player()
	if _phase == Phase.CLIMAX:
		_tick_climax(delta)
		return
	if not is_active():
		return

	_tick_teleport(delta)
	_tick_burst_projs(delta)
	_tick_homing_delay(delta)
	_tick_homing_projs(delta)

	velocity = Vector2.ZERO
	move_and_slide()

# ---------------------------------------------------------------------------
# Teleport cycle (fully timer-based, no tween callbacks)
# ---------------------------------------------------------------------------
enum TeleportState { IDLE, FADING_OUT, IN_TRANSIT }
var _tp_state: int = TeleportState.IDLE

func _tick_teleport(delta: float) -> void:
	match _tp_state:
		TeleportState.IDLE:
			_teleport_timer -= delta
			if _teleport_timer <= 0.0:
				_start_fade_out()
		TeleportState.FADING_OUT:
			_fade_timer -= delta
			_visual.modulate.a = _fade_timer / FADE_OUT_TIME
			if _fade_timer <= 0.0:
				_enter_transit()
		TeleportState.IN_TRANSIT:
			_transit_timer -= delta
			if _transit_timer <= 0.0:
				_reappear()

func _start_fade_out() -> void:
	_tp_state = TeleportState.FADING_OUT
	_fade_timer = FADE_OUT_TIME

func _enter_transit() -> void:
	_tp_state = TeleportState.IN_TRANSIT
	_contact_area.monitoring = false
	_contact_area.monitorable = false
	_visual.visible = false
	_visual.modulate.a = 0.0
	_transit_timer = TRANSIT_TIME

func _reappear() -> void:
	# Pick random position within room bounds
	var min_x := _room_center.x - ROOM_HW + WALL_T + WALL_MARGIN
	var max_x := _room_center.x + ROOM_HW - WALL_T - WALL_MARGIN
	var min_y := _room_center.y - ROOM_HH + WALL_T + WALL_MARGIN
	var max_y := _room_center.y + ROOM_HH - WALL_T - WALL_MARGIN

	global_position = Vector2(
		randf_range(min_x, max_x),
		randf_range(min_y, max_y)
	)

	# Show visual with white flash
	_visual.visible = true
	_visual.modulate = Color(2.0, 2.0, 2.0, 1.0)  # bright flash
	_contact_area.monitoring = true
	_contact_area.monitorable = true

	var tw := create_tween()
	var base_color := Color(0.3, 0.8, 1.0) if _phase == Phase.TWO else Color(1, 1, 1, 1)
	tw.tween_property(_visual, "modulate", base_color, 0.15)

	_tp_state = TeleportState.IDLE
	_teleport_count += 1

	# Fire radial burst immediately, then homing after delay
	_fire_burst()
	_homing_delay = HOMING_DELAY

	# Check drifter spawn
	if _teleport_count >= _next_drifter_threshold:
		_spawn_drifters()
		_teleport_count = 0
		_roll_drifter_threshold()

	_roll_teleport_cooldown()

func _roll_teleport_cooldown() -> void:
	if _phase == Phase.TWO:
		_teleport_timer = randf_range(TELEPORT_CD_P2_MIN, TELEPORT_CD_P2_MAX)
	else:
		_teleport_timer = randf_range(TELEPORT_CD_P1_MIN, TELEPORT_CD_P1_MAX)

func _roll_drifter_threshold() -> void:
	_next_drifter_threshold = randi_range(DRIFTER_SPAWN_MIN, DRIFTER_SPAWN_MAX)

# ---------------------------------------------------------------------------
# Burst Transmission
# ---------------------------------------------------------------------------
func _fire_burst() -> void:
	var count := BURST_COUNT_P2 if _phase == Phase.TWO else BURST_COUNT_P1
	var angle_step := TAU / float(count)

	for i in count:
		var angle := angle_step * i
		var dir := Vector2.from_angle(angle)
		_spawn_burst_proj(dir)

func _spawn_burst_proj(dir: Vector2) -> void:
	var proj := Node2D.new()
	proj.set_meta("dir", dir)

	var poly := Polygon2D.new()
	var hs := PROJ_SIZE * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hs, -hs), Vector2(hs, -hs),
		Vector2(hs, hs), Vector2(-hs, hs)
	])
	poly.color = Color(1.0, 0.7, 0.2)  # yellow-orange
	proj.add_child(poly)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = hs
	shape.shape = circle
	area.add_child(shape)
	proj.add_child(area)
	area.body_entered.connect(_on_burst_hit_player.bind(proj))

	get_parent().add_child(proj)
	proj.global_position = global_position  # Set AFTER add_child for correct transform
	_burst_projs.append(proj)

func _on_burst_hit_player(body: Node2D, proj: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1)
	if is_instance_valid(proj):
		proj.queue_free()

func _tick_burst_projs(delta: float) -> void:
	var still_valid: Array[Node2D] = []

	for proj in _burst_projs:
		if not is_instance_valid(proj):
			continue

		var dir: Vector2 = proj.get_meta("dir")
		proj.global_position += dir * BURST_SPEED * delta

		# Check bounds
		var rel := proj.global_position - _room_center
		if absf(rel.x) > ROOM_HW - WALL_T or absf(rel.y) > ROOM_HH - WALL_T:
			proj.queue_free()
		else:
			still_valid.append(proj)

	_burst_projs = still_valid

# ---------------------------------------------------------------------------
# Homing Projectiles
# ---------------------------------------------------------------------------
func _tick_homing_delay(delta: float) -> void:
	if _homing_delay <= 0.0:
		return
	_homing_delay -= delta
	if _homing_delay <= 0.0:
		_fire_homing()

func _fire_homing() -> void:
	var count := HOMING_COUNT_P2 if _phase == Phase.TWO else HOMING_COUNT_P1
	for i in count:
		var angle := TAU * float(i) / float(count)
		_spawn_homing_proj(angle)

func _spawn_homing_proj(start_angle: float) -> void:
	var proj := Node2D.new()
	proj.set_meta("angle", start_angle)
	proj.set_meta("age", 0.0)

	# Diamond shape visual
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(5, 0),
		Vector2(0, 8), Vector2(-5, 0)
	])
	poly.color = Color(0.9, 0.3, 0.9)  # purple/magenta
	proj.add_child(poly)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	area.add_child(shape)
	proj.add_child(area)
	area.body_entered.connect(_on_homing_hit_player.bind(proj))

	get_parent().add_child(proj)
	proj.global_position = global_position  # Set AFTER add_child
	_homing_projs.append(proj)

func _on_homing_hit_player(body: Node2D, proj: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1)
	if is_instance_valid(proj):
		proj.queue_free()

func _tick_homing_projs(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return

	var still_valid: Array[Node2D] = []

	for proj in _homing_projs:
		if not is_instance_valid(proj):
			continue

		# Age check
		var age: float = proj.get_meta("age") + delta
		proj.set_meta("age", age)
		if age >= HOMING_LIFETIME:
			proj.queue_free()
			continue

		var angle: float = proj.get_meta("angle")
		var to_player := (_player.global_position - proj.global_position).normalized()
		var desired_angle := to_player.angle()

		# Smoothly turn towards player
		var diff := angle_difference(angle, desired_angle)
		angle += clampf(diff, -HOMING_TURN_SPEED * delta, HOMING_TURN_SPEED * delta)
		proj.set_meta("angle", angle)

		# Move forward
		var dir := Vector2.from_angle(angle)
		proj.global_position += dir * HOMING_SPEED * delta
		proj.rotation = angle + PI / 2  # Point diamond forward

		# Check bounds
		var rel := proj.global_position - _room_center
		if absf(rel.x) > ROOM_HW - WALL_T or absf(rel.y) > ROOM_HH - WALL_T:
			proj.queue_free()
		else:
			still_valid.append(proj)

	_homing_projs = still_valid

# ---------------------------------------------------------------------------
# Signal Drifters
# ---------------------------------------------------------------------------
func _spawn_drifters() -> void:
	var count: int
	if _phase == Phase.TWO:
		count = randi_range(DRIFTER_COUNT_P2_MIN, DRIFTER_COUNT_P2_MAX)
	else:
		count = randi_range(DRIFTER_COUNT_P1_MIN, DRIFTER_COUNT_P1_MAX)

	for i in count:
		var drifter := DRIFTER_SCENE.instantiate()
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(DRIFTER_OFFSET_MIN, DRIFTER_OFFSET_MAX)
		get_parent().add_child(drifter)
		drifter.global_position = global_position + offset

# ---------------------------------------------------------------------------
# Damage / Phase
# ---------------------------------------------------------------------------
func take_damage(amount: float) -> void:
	if _tp_state != TeleportState.IDLE or _phase == Phase.CLIMAX:
		return

	current_health -= amount
	EventBus.boss_health_changed.emit(current_health, max_health)

	if current_health <= 5.0 and _phase != Phase.CLIMAX:
		_enter_climax()
		return

	if _phase == Phase.ONE and current_health <= max_health * 0.4:
		_enter_phase_two()

	_flash_damage()

func _enter_phase_two() -> void:
	_phase = Phase.TWO
	_visual.modulate = Color(0.3, 0.8, 1.0)

func _flash_damage() -> void:
	_visual.modulate = Color(1, 0.2, 0.2)
	var tw := create_tween()
	var base := Color(0.3, 0.8, 1.0) if _phase == Phase.TWO else Color(1, 1, 1)
	tw.tween_property(_visual, "modulate", base, 0.12)

# ---------------------------------------------------------------------------
# Climax / Death
# ---------------------------------------------------------------------------
func _enter_climax() -> void:
	_phase = Phase.CLIMAX
	_climax_timer = FREEZE_DURATION
	_blink_accum = 0.0
	velocity = Vector2.ZERO

func _tick_climax(delta: float) -> void:
	_climax_timer -= delta
	_blink_accum += delta

	if fmod(_blink_accum, 0.15) < 0.075:
		_visual.modulate = Color(1, 0.2, 0.2)
	else:
		_visual.modulate = Color(1, 1, 1)

	if _climax_timer <= 0.0:
		_die()

func _die() -> void:
	EventBus.boss_died.emit()

	# Cleanup burst projectiles
	for proj in _burst_projs:
		if is_instance_valid(proj):
			proj.queue_free()
	_burst_projs.clear()

	# Cleanup homing projectiles
	for proj in _homing_projs:
		if is_instance_valid(proj):
			proj.queue_free()
	_homing_projs.clear()

	queue_free()
