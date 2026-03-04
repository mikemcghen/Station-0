extends CharacterBody2D

# ---------------------------------------------------------------------------
# The Supervisor — Phase 1/2/Climax boss
# Corrupted supervisor protocol attempting to decommission the player.
# ---------------------------------------------------------------------------

enum Phase { ONE, TWO, CLIMAX }

const DRIFTER_SCENE = preload("res://scenes/enemies/drifter.tscn")

# ---------------------------------------------------------------------------
# Stats
# ---------------------------------------------------------------------------
var max_health:       float = 200.0
var current_health:   float = 200.0
var contact_damage:   float = 1.0
var contact_cooldown: float = 0.8

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
# Internal state
# ---------------------------------------------------------------------------
var _phase:         Phase  = Phase.ONE
var _player:        Node2D = null

var _patrol_points: Array[Vector2] = []
var _patrol_index:  int   = 0

var _contact_timer: float = 0.0
var _flash_timer:   float = 0.0

# Beam state
var _beam_timer:     float  = 1.5    # initial delay before first beam check
var _beam_active:    bool   = false
var _beam_node:      Node2D = null
var _beam_dur_timer: float  = 0.0

# Wind-up state
var _winding_up:   bool    = false
var _wind_up_timer: float  = 0.0
var _wind_up_dir:   Vector2 = Vector2.RIGHT   # locked direction when wind-up starts

var _drifter_spawned: bool  = false
var _freeze_timer:    float = 0.0

@onready var visual: Node2D = $Visual

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	add_to_group("enemies")
	$ContactArea.body_entered.connect(_on_contact_entered)
	var c := global_position
	_patrol_points = [
		c + Vector2(-PATROL_W, -PATROL_H),
		c + Vector2( PATROL_W, -PATROL_H),
		c + Vector2( PATROL_W,  PATROL_H),
		c + Vector2(-PATROL_W,  PATROL_H),
	]

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
	elif _phase == Phase.TWO and pct <= 0.20:
		_enter_climax()

	match _phase:
		Phase.ONE:
			# Stop and lock on during wind-up
			if _winding_up:
				velocity = Vector2.ZERO
			else:
				_do_patrol(PATROL_SPEED_P1)
		Phase.TWO:
			if _winding_up:
				velocity = Vector2.ZERO
			else:
				_do_chase(PATROL_SPEED_P2)
			_maybe_spawn_drifter()
		Phase.CLIMAX:
			_do_climax(delta)

	move_and_slide()

# ---------------------------------------------------------------------------
# Player lookup
# ---------------------------------------------------------------------------
func _find_player() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

# ---------------------------------------------------------------------------
# Phase transitions
# ---------------------------------------------------------------------------
func _enter_phase_two() -> void:
	_phase = Phase.TWO
	_winding_up = false

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
# Phase 2 — spawn one Drifter
# ---------------------------------------------------------------------------
func _maybe_spawn_drifter() -> void:
	if _drifter_spawned:
		return
	_drifter_spawned = true
	var drifter = DRIFTER_SCENE.instantiate()
	drifter.position = (get_parent() as Node2D).to_local(global_position + Vector2(0, 130))
	get_parent().call_deferred("add_child", drifter)

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

	# Active beam — count down duration
	if _beam_active:
		_beam_dur_timer -= delta
		if _beam_dur_timer <= 0.0:
			_beam_active = false
			if is_instance_valid(_beam_node):
				_beam_node.queue_free()
				_beam_node = null
		return

	# Wind-up — boss is stopped and flashing; fires when timer expires
	if _winding_up:
		_wind_up_timer -= delta
		if _wind_up_timer <= 0.0:
			_winding_up = false
			_fire_beam()
			var cd := BEAM_COOLDOWN_P1 if _phase == Phase.ONE else BEAM_COOLDOWN_P2
			_beam_timer = cd
		return

	# Cooldown between beams
	if _beam_timer > 0.0:
		_beam_timer -= delta
		return

	# Check sensor cone — start wind-up if player is in range
	if _player_in_sensor_cone():
		_winding_up    = true
		_wind_up_timer = WIND_UP_DURATION
		# Lock the fire direction to current heading at the moment of detection
		_wind_up_dir   = velocity.normalized() if velocity.length() > 1.0 else Vector2.RIGHT
	else:
		_beam_timer = 0.3   # recheck soon

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

	var forward  := _wind_up_dir   # use direction locked at wind-up start
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
# Damage / death
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
	_spawn_drop()
	queue_free()

func _spawn_drop() -> void:
	var orb = preload("res://scenes/enemies/currency_orb.tscn").instantiate()
	orb.position = (get_parent() as Node2D).to_local(global_position)
	get_parent().call_deferred("add_child", orb)

# ---------------------------------------------------------------------------
# Contact damage
# ---------------------------------------------------------------------------
func _on_contact_entered(body: Node) -> void:
	if body.is_in_group("player") and _contact_timer == 0.0:
		body.take_damage(contact_damage)
		_contact_timer = contact_cooldown

func _tick_contact(delta: float) -> void:
	_contact_timer = maxf(_contact_timer - delta, 0.0)

# ---------------------------------------------------------------------------
# Visual — flash on hit, wind-up warning pulse, phase tints, climax strobe
# ---------------------------------------------------------------------------
func _tick_flash(delta: float) -> void:
	if _phase == Phase.CLIMAX:
		return   # climax handles its own visual in _do_climax

	# Wind-up: rapid yellow-white warning pulse — overrides everything else
	if _winding_up:
		var pulse := fmod(_wind_up_timer, 0.18) < 0.09
		var base  := Color(1.0, 0.65, 0.2) if _phase == Phase.TWO else Color(1.0, 1.0, 1.0)
		visual.modulate = Color(2.4, 2.1, 0.3) if pulse else base
		return

	# Hit flash
	if _flash_timer > 0.0:
		_flash_timer -= delta
		visual.modulate = Color(2.5, 2.5, 2.5)
		return

	# Resting tint per phase
	if _phase == Phase.TWO:
		visual.modulate = Color(1.0, 0.65, 0.2)
	else:
		visual.modulate = Color(1.0, 1.0, 1.0)
