extends EnemyBase

# ---------------------------------------------------------------------------
# The Supervisor — Phase 1/2/Climax boss
# Corrupted supervisor protocol attempting to decommission the player.
# ---------------------------------------------------------------------------

enum Phase { ONE, TWO, CLIMAX }

const DRIFTER_SCENE = preload("res://scenes/enemies/drifter.tscn")

# ---------------------------------------------------------------------------
# Patrol (Phase 1)
# ---------------------------------------------------------------------------
const PATROL_W        := 200.0
const PATROL_H        := 100.0
const PATROL_SPEED_P1 := 75.0

# ---------------------------------------------------------------------------
# Chase (Phase 2)
# ---------------------------------------------------------------------------
const PATROL_SPEED_P2 := 105.0

# ---------------------------------------------------------------------------
# Calibration beam
# ---------------------------------------------------------------------------
const BEAM_RANGE       := 240.0
const BEAM_HALFANG     := 0.50    # ~28.6° half-angle for sensor cone
const BEAM_COOLDOWN_P1 := 3.5
const BEAM_COOLDOWN_P2 := 2.2
const BEAM_DURATION    := 0.75    # active damage window (shorter = more dodgeable)

# Wind-up before firing — boss stops and flashes a warning
const WIND_UP_DURATION := 0.65   # seconds of warning before beam fires

# ---------------------------------------------------------------------------
# Climax freeze
# ---------------------------------------------------------------------------
const FREEZE_DURATION := 2.0

# ---------------------------------------------------------------------------
# Phase 2 Drifter spawning — one at a time, over a fixed window
# ---------------------------------------------------------------------------
const DRIFTER_SPAWN_COUNT    := 4      # total drifters spawned in phase 2
const DRIFTER_SPAWN_INTERVAL := 8.0   # seconds between each spawn

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------
var _phase:         Phase  = Phase.ONE

var _patrol_points: Array[Vector2] = []
var _patrol_index:  int   = 0

# Beam state
var _beam_timer:     float  = 1.5    # initial delay before first beam check
var _beam_active:    bool   = false
var _beam_node:      Node2D = null
var _beam_dur_timer: float  = 0.0

# Wind-up state
var _winding_up:    bool    = false
var _wind_up_timer: float   = 0.0
var _wind_up_dir:   Vector2 = Vector2.RIGHT   # locked direction when wind-up starts

# Phase 2 Drifter spawning
var _drifters_spawned: int   = 0
var _drifter_timer:    float = DRIFTER_SPAWN_INTERVAL

var _freeze_timer: float = 0.0

# Facing indicator — Line2D child added to visual at runtime
var _facing_indicator: Line2D = null

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	max_health       = 200.0
	current_health   = 200.0
	contact_damage   = 1.0
	contact_cooldown = 0.8
	super._ready()
	var c := global_position
	_patrol_points = [
		c + Vector2(-PATROL_W, -PATROL_H),
		c + Vector2( PATROL_W, -PATROL_H),
		c + Vector2( PATROL_W,  PATROL_H),
		c + Vector2(-PATROL_W,  PATROL_H),
	]
	_build_facing_indicator()

# ---------------------------------------------------------------------------
# Facing indicator — arrow line attached to the visual node
# ---------------------------------------------------------------------------
func _build_facing_indicator() -> void:
	var arrow := Line2D.new()
	arrow.width         = 3.0
	arrow.default_color = Color(1.0, 0.9, 0.3, 0.85)
	arrow.add_point(Vector2(0.0, 0.0))
	arrow.add_point(Vector2(22.0, 0.0))
	visual.add_child(arrow)
	_facing_indicator = arrow

func _update_facing(dir: Vector2) -> void:
	if _facing_indicator != null:
		_facing_indicator.rotation = dir.angle()

# ---------------------------------------------------------------------------
# Physics loop
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_find_player()
	_tick_contact(delta)
	_tick_beam(delta)
	_tick_flash(delta)

	var pct := current_health / max_health
	if _phase == Phase.ONE and pct <= 0.55:
		_enter_phase_two()
	elif _phase == Phase.TWO and current_health <= 5.0:
		_enter_climax()

	match _phase:
		Phase.ONE:
			if _winding_up:
				velocity = Vector2.ZERO
			else:
				_do_patrol(PATROL_SPEED_P1)
		Phase.TWO:
			if _winding_up:
				velocity = Vector2.ZERO
			else:
				_do_chase(PATROL_SPEED_P2)
			_tick_drifter_spawns(delta)
		Phase.CLIMAX:
			_do_climax(delta)

	# Update facing indicator (hidden during climax)
	if _phase != Phase.CLIMAX:
		if _facing_indicator != null:
			_facing_indicator.visible = true
		var facing: Vector2
		if _winding_up:
			facing = _wind_up_dir
		elif velocity.length() > 1.0:
			facing = velocity.normalized()
		elif _player != null:
			facing = (_player.global_position - global_position).normalized()
		else:
			facing = Vector2.RIGHT
		_update_facing(facing)
	else:
		if _facing_indicator != null:
			_facing_indicator.visible = false

	move_and_slide()

# ---------------------------------------------------------------------------
# Phase transitions
# ---------------------------------------------------------------------------
func _enter_phase_two() -> void:
	_phase            = Phase.TWO
	_winding_up       = false
	_drifters_spawned = 0
	_drifter_timer    = DRIFTER_SPAWN_INTERVAL * 0.5   # first spawn sooner

func _enter_climax() -> void:
	_phase = Phase.CLIMAX
	velocity = Vector2.ZERO
	_freeze_timer = FREEZE_DURATION
	_winding_up = false
	if is_instance_valid(_beam_node):
		_beam_node.queue_free()
		_beam_node = null
	_beam_active = false

# ---------------------------------------------------------------------------
# Phase 1 — rectangular patrol
# ---------------------------------------------------------------------------
func _do_patrol(spd: float) -> void:
	if _patrol_points.is_empty():
		return
	var target := _patrol_points[_patrol_index]
	var diff   := target - global_position
	if diff.length() < 10.0:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()
	else:
		velocity = diff.normalized() * spd

# ---------------------------------------------------------------------------
# Phase 2 — direct player chase
# ---------------------------------------------------------------------------
func _do_chase(spd: float) -> void:
	if _player == null:
		velocity = Vector2.ZERO
		return
	velocity = (_player.global_position - global_position).normalized() * spd

# ---------------------------------------------------------------------------
# Phase 2 — spawn Drifters one at a time on a fixed interval
# ---------------------------------------------------------------------------
func _tick_drifter_spawns(delta: float) -> void:
	if _drifters_spawned >= DRIFTER_SPAWN_COUNT:
		return
	_drifter_timer -= delta
	if _drifter_timer <= 0.0:
		var drifter = DRIFTER_SCENE.instantiate()
		drifter.position = (get_parent() as Node2D).to_local(global_position + Vector2(0, 130))
		get_parent().call_deferred("add_child", drifter)
		_drifters_spawned += 1
		_drifter_timer = DRIFTER_SPAWN_INTERVAL

# ---------------------------------------------------------------------------
# Climax — frozen distress signal, then die
# ---------------------------------------------------------------------------
func _do_climax(delta: float) -> void:
	velocity = Vector2.ZERO
	_freeze_timer -= delta
	var blink := fmod(_freeze_timer, 0.3) < 0.15
	visual.modulate = Color(2.0, 0.3, 0.3) if blink else Color(0.25, 0.08, 0.08)
	if _freeze_timer <= 0.0:
		_die()

# ---------------------------------------------------------------------------
# Calibration beam — with wind-up warning
# ---------------------------------------------------------------------------
func _tick_beam(delta: float) -> void:
	if _phase == Phase.CLIMAX:
		return

	if _beam_active:
		_beam_dur_timer -= delta
		if _beam_dur_timer <= 0.0:
			_beam_active = false
			if is_instance_valid(_beam_node):
				_beam_node.queue_free()
				_beam_node = null
		return

	if _winding_up:
		_wind_up_timer -= delta
		if _wind_up_timer <= 0.0:
			_winding_up = false
			_fire_beam()
			var cd := BEAM_COOLDOWN_P1 if _phase == Phase.ONE else BEAM_COOLDOWN_P2
			_beam_timer = cd
		return

	if _beam_timer > 0.0:
		_beam_timer -= delta
		return

	if _player_in_sensor_cone():
		_winding_up    = true
		_wind_up_timer = WIND_UP_DURATION
		_wind_up_dir   = velocity.normalized() if velocity.length() > 1.0 else Vector2.RIGHT
	else:
		_beam_timer = 0.3

func _player_in_sensor_cone() -> bool:
	if _player == null:
		return false
	var to_player := _player.global_position - global_position
	if to_player.length() > BEAM_RANGE:
		return false
	var forward := velocity.normalized() if velocity.length() > 1.0 else Vector2.RIGHT
	return absf(forward.angle_to(to_player.normalized())) < BEAM_HALFANG

func _fire_beam() -> void:
	_beam_active    = true
	_beam_dur_timer = BEAM_DURATION

	var forward  := _wind_up_dir
	var beam_len := BEAM_RANGE
	var beam_w   := 30.0
	var offset   := 24.0

	var beam := Node2D.new()
	beam.position = (get_parent() as Node2D).to_local(global_position)
	beam.rotation = forward.angle()

	var poly    := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(offset,            -beam_w * 0.5),
		Vector2(offset + beam_len, -beam_w * 0.5),
		Vector2(offset + beam_len,  beam_w * 0.5),
		Vector2(offset,             beam_w * 0.5),
	])
	poly.color = Color(1.0, 0.9, 0.3, 0.60)
	beam.add_child(poly)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size     = Vector2(beam_len, beam_w)
	cs.shape    = rs
	cs.position = Vector2(offset + beam_len * 0.5, 0.0)
	area.add_child(cs)
	area.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			body.take_damage(1.0))
	beam.add_child(area)

	get_parent().call_deferred("add_child", beam)
	_beam_node = beam

# ---------------------------------------------------------------------------
# Damage / death — override base to emit boss signals; no drop (room handles it)
# ---------------------------------------------------------------------------
func take_damage(amount: float) -> void:
	current_health -= amount
	_flash_timer = 0.1
	EventBus.boss_health_changed.emit(maxf(current_health, 0.0), max_health)
	if current_health <= 0.0:
		_die()

func _die() -> void:
	EventBus.boss_died.emit()
	if is_instance_valid(_beam_node):
		_beam_node.queue_free()
	queue_free()   # no drop — room.gd spawns the guaranteed body part

# ---------------------------------------------------------------------------
# Visual — overrides base _tick_flash with phase-aware tints
# ---------------------------------------------------------------------------
func _tick_flash(delta: float) -> void:
	if _phase == Phase.CLIMAX:
		return   # climax handles its own visual in _do_climax

	if _winding_up:
		var pulse := fmod(_wind_up_timer, 0.18) < 0.09
		var base  := Color(1.0, 0.65, 0.2) if _phase == Phase.TWO else Color(1.0, 1.0, 1.0)
		visual.modulate = Color(2.4, 2.1, 0.3) if pulse else base
		return

	if _flash_timer > 0.0:
		_flash_timer -= delta
		visual.modulate = Color(2.5, 2.5, 2.5)
		return

	if _phase == Phase.TWO:
		visual.modulate = Color(1.0, 0.65, 0.2)
	else:
		visual.modulate = Color(1.0, 1.0, 1.0)