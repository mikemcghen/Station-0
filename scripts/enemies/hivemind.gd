extends EnemyBase

# ---------------------------------------------------------------------------
# Hivemind — Floor 3 Final Boss
# Phase 1: Assembly (spawn waves, enemies join core on death)
# Phase 2: Active (mimics Repeater spread, Warden sweep, Drifter projectiles)
# Phase 3: Unique (rotating beam, room pulse, homing projectiles)
# ---------------------------------------------------------------------------

enum Phase { ASSEMBLY, ACTIVE, UNIQUE, CLIMAX }

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const ROOM_HW := 480.0
const ROOM_HH := 270.0
const WALL_T  := 32.0

# Assembly phase
const WAVE_COUNT        := 3
const ENEMIES_PER_WAVE  := 3
const WAVE_DELAY        := 3.0
const ASSEMBLY_COMPLETE := 8   # kills needed to complete assembly

# Phase 2 attacks
const ATTACK_CD_P2      := 3.5
const SPREAD_COUNT      := 5
const SPREAD_ANGLE      := 0.6   # radians total spread
const SPREAD_SPEED      := 120.0
const SWEEP_SPEED       := 60.0
const SWEEP_PROJ_SPACE  := 22.0
const DRIFT_COUNT       := 4
const DRIFT_SPEED       := 45.0
const DRIFT_CURVE       := 0.8

# Phase 3 attacks
const ATTACK_CD_P3      := 2.5
const BEAM_ROT_SPEED    := 1.2   # rad/sec
const BEAM_DURATION     := 3.0
const BEAM_LENGTH       := 500.0
const BEAM_WIDTH        := 28.0
const PULSE_FORCE       := 350.0
const PULSE_CD          := 5.0
const HOMING_COUNT      := 3
const HOMING_SPEED      := 70.0
const HOMING_TURN       := 1.5   # rad/sec

const FREEZE_DURATION   := 2.0

const DRIFTER_SCENE  = preload("res://scenes/enemies/drifter.tscn")
const REPEATER_SCENE = preload("res://scenes/enemies/repeater.tscn")
const ANCHOR_SCENE   = preload("res://scenes/enemies/anchor.tscn")

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _phase: Phase = Phase.ASSEMBLY
var _room_center: Vector2

# Assembly
var _wave_index:       int   = 0
var _wave_timer:       float = 2.5   # initial delay before first wave
var _kills:            int   = 0
var _assembly_parts:   Array[Node2D] = []
var _spawned_enemies:  Array[Node] = []

# Core visual
var _core_visual: Node2D = null
var _core_poly:   Polygon2D = null

# Phase 2/3 attacks
var _attack_timer:   float = 2.0
var _attack_index:   int   = 0
var _projectiles:    Array[Dictionary] = []   # {node, vel, type, ...}

# Beam state
var _beam_active:    bool  = false
var _beam_angle:     float = 0.0
var _beam_timer:     float = 0.0
var _beam_node:      Node2D = null

# Pulse state
var _pulse_timer:    float = 3.0

# Climax
var _climax_timer:   float = 0.0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	super._ready()
	max_health     = 350.0
	current_health = max_health
	contact_damage   = 1.0
	contact_cooldown = 0.8

	_room_center = global_position
	_build_core_visual()
	_core_visual.visible = false   # hidden during assembly


func _physics_process(delta: float) -> void:
	_tick_spawn_delay(delta)
	if not is_active():
		return

	match _phase:
		Phase.ASSEMBLY:
			_tick_assembly(delta)
		Phase.ACTIVE:
			_tick_active(delta)
		Phase.UNIQUE:
			_tick_unique(delta)
		Phase.CLIMAX:
			_tick_climax(delta)

	_tick_projectiles(delta)
	_tick_flash(delta)
	velocity = Vector2.ZERO
	move_and_slide()


# ---------------------------------------------------------------------------
# Core Visual
# ---------------------------------------------------------------------------
func _build_core_visual() -> void:
	_core_visual = Node2D.new()
	_core_visual.position = Vector2.ZERO

	# Main body — irregular polygon
	_core_poly = Polygon2D.new()
	_core_poly.polygon = PackedVector2Array([
		Vector2(-35, -25), Vector2(-15, -40), Vector2(20, -35),
		Vector2(40, -10), Vector2(35, 20), Vector2(10, 40),
		Vector2(-25, 30), Vector2(-40, 5)
	])
	_core_poly.color = Color(0.25, 0.15, 0.35)
	_core_visual.add_child(_core_poly)

	# Eye/core indicator
	var eye := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0
		pts.append(Vector2(cos(a), sin(a)) * 12.0)
	eye.polygon = pts
	eye.color = Color(0.8, 0.2, 0.5)
	_core_visual.add_child(eye)

	add_child(_core_visual)


# ---------------------------------------------------------------------------
# Phase 1 — Assembly
# ---------------------------------------------------------------------------
func _tick_assembly(delta: float) -> void:
	_wave_timer -= delta
	if _wave_timer <= 0.0 and _wave_index < WAVE_COUNT:
		_spawn_wave()
		_wave_index += 1
		_wave_timer = WAVE_DELAY + randf_range(0.0, 1.0)

	# Check if assembly complete
	if _kills >= ASSEMBLY_COMPLETE:
		_enter_active()


func _spawn_wave() -> void:
	var scenes := [DRIFTER_SCENE, REPEATER_SCENE, ANCHOR_SCENE]
	var hw := ROOM_HW - WALL_T - 80.0
	var hh := ROOM_HH - WALL_T - 80.0

	for i in ENEMIES_PER_WAVE:
		var scene = scenes[randi() % scenes.size()]
		var enemy = scene.instantiate()
		var pos := Vector2(
			randf_range(-hw, hw),
			randf_range(-hh, hh)
		)
		# Avoid spawning too close to center
		if pos.length() < 100.0:
			pos = pos.normalized() * 100.0
		get_parent().add_child(enemy)
		enemy.global_position = _room_center + pos

		# Track enemy for assembly phase
		_spawned_enemies.append(enemy)
		enemy.tree_exited.connect(_on_enemy_died.bind(enemy), CONNECT_ONE_SHOT)


func _on_enemy_died(enemy: Node) -> void:
	if _phase != Phase.ASSEMBLY:
		return

	# Remove from tracked list
	_spawned_enemies.erase(enemy)
	_kills += 1

	# Create visual part flying to center (use last known position offset)
	var part := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 6:
		var a := TAU * i / 6.0
		pts.append(Vector2(cos(a), sin(a)) * randf_range(8.0, 14.0))
	part.polygon = pts
	part.color = Color(0.4, 0.2, 0.5, 0.8)
	# Position near center since enemy is already freed by now
	part.global_position = _room_center + Vector2(randf_range(-100, 100), randf_range(-100, 100))
	get_parent().add_child(part)
	_assembly_parts.append(part)

	# Tween to center
	var tw := get_tree().create_tween()
	tw.tween_property(part, "global_position", _room_center, 0.8).set_ease(Tween.EASE_IN)
	tw.tween_property(part, "modulate:a", 0.0, 0.3)
	tw.tween_callback(part.queue_free)


func _enter_active() -> void:
	_phase = Phase.ACTIVE
	_core_visual.visible = true
	_attack_timer = 1.5
	_attack_index = 0

	# Clean up any remaining assembly parts
	for part in _assembly_parts:
		if is_instance_valid(part):
			part.queue_free()
	_assembly_parts.clear()

	# Emit boss health bar start
	EventBus.boss_health_changed.emit(current_health, max_health)


# ---------------------------------------------------------------------------
# Phase 2 — Active (mimic attacks)
# ---------------------------------------------------------------------------
func _tick_active(delta: float) -> void:
	_find_player()
	_tick_contact(delta)

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_do_active_attack()
		_attack_index = (_attack_index + 1) % 3
		_attack_timer = ATTACK_CD_P2


func _do_active_attack() -> void:
	match _attack_index:
		0: _attack_spread()
		1: _attack_sweep()
		2: _attack_drift()


func _attack_spread() -> void:
	# Repeater-style spread shot toward player
	if _player == null:
		return

	var base_dir := ((_player.global_position) - global_position).normalized()
	var start_angle := base_dir.angle() - SPREAD_ANGLE * 0.5
	var step := SPREAD_ANGLE / float(SPREAD_COUNT - 1) if SPREAD_COUNT > 1 else 0.0

	for i in SPREAD_COUNT:
		var angle := start_angle + step * i
		var dir := Vector2.from_angle(angle)
		_spawn_projectile(global_position, dir * SPREAD_SPEED, "spread")


func _attack_sweep() -> void:
	# Warden-style horizontal sweep with gaps
	var inner_left  := -ROOM_HW + WALL_T
	var inner_right :=  ROOM_HW - WALL_T
	var sweep_dir   := 1.0 if randf() < 0.5 else -1.0
	var start_y     := _room_center.y + (-ROOM_HH + WALL_T) * -sweep_dir
	var vel         := Vector2(0.0, SWEEP_SPEED * sweep_dir)

	# One gap
	var gap_center := randf_range(inner_left + 80.0, inner_right - 80.0)
	var gap_width  := 90.0

	var x := inner_left
	while x <= inner_right:
		if abs(x - gap_center) > gap_width * 0.5:
			_spawn_projectile(Vector2(_room_center.x + x, start_y), vel, "sweep")
		x += SWEEP_PROJ_SPACE


func _attack_drift() -> void:
	# Drifter-style curving projectiles
	for i in DRIFT_COUNT:
		var angle := TAU * i / float(DRIFT_COUNT) + randf_range(-0.2, 0.2)
		var dir := Vector2.from_angle(angle)
		var curve := DRIFT_CURVE if randf() < 0.5 else -DRIFT_CURVE
		_spawn_projectile(global_position, dir * DRIFT_SPEED, "drift", {"curve": curve})


# ---------------------------------------------------------------------------
# Phase 3 — Unique attacks
# ---------------------------------------------------------------------------
func _enter_unique() -> void:
	_phase = Phase.UNIQUE
	_attack_timer = 1.0
	_attack_index = 0
	_pulse_timer = PULSE_CD * 0.5

	# Visual change — cracking/glowing
	_core_poly.color = Color(0.5, 0.15, 0.25)


func _tick_unique(delta: float) -> void:
	_find_player()
	_tick_contact(delta)

	# Rotating beam
	if _beam_active:
		_tick_beam(delta)
	else:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_do_unique_attack()
			_attack_index = (_attack_index + 1) % 3
			_attack_timer = ATTACK_CD_P3

	# Pulse on separate timer
	_pulse_timer -= delta
	if _pulse_timer <= 0.0:
		_attack_pulse()
		_pulse_timer = PULSE_CD


func _do_unique_attack() -> void:
	match _attack_index:
		0: _start_beam()
		1: _attack_homing()
		2: _attack_homing()   # double up on homing since beam takes time


func _start_beam() -> void:
	_beam_active = true
	_beam_timer = BEAM_DURATION
	_beam_angle = randf() * TAU

	_beam_node = Node2D.new()
	_beam_node.position = Vector2.ZERO

	var poly := Polygon2D.new()
	var hw := BEAM_WIDTH * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(0, -hw), Vector2(BEAM_LENGTH, -hw),
		Vector2(BEAM_LENGTH, hw), Vector2(0, hw)
	])
	poly.color = Color(1.0, 0.3, 0.4, 0.7)
	_beam_node.add_child(poly)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(BEAM_LENGTH, BEAM_WIDTH)
	cs.shape = rs
	cs.position = Vector2(BEAM_LENGTH * 0.5, 0)
	area.add_child(cs)
	area.body_entered.connect(_on_beam_hit)
	_beam_node.add_child(area)

	add_child(_beam_node)


func _tick_beam(delta: float) -> void:
	_beam_timer -= delta
	_beam_angle += BEAM_ROT_SPEED * delta
	if _beam_node != null:
		_beam_node.rotation = _beam_angle

	if _beam_timer <= 0.0:
		_end_beam()


func _end_beam() -> void:
	_beam_active = false
	if _beam_node != null:
		_beam_node.queue_free()
		_beam_node = null


func _on_beam_hit(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1.0)


func _attack_pulse() -> void:
	# Push player toward walls
	if _player == null or not is_instance_valid(_player):
		return

	var dir := (_player.global_position - global_position).normalized()
	if _player.has_method("apply_knockback"):
		_player.apply_knockback(dir * PULSE_FORCE)

	# Visual pulse ring
	var ring := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a), sin(a)) * 50.0)
	ring.polygon = pts
	ring.color = Color(0.8, 0.3, 0.5, 0.5)
	ring.global_position = global_position
	get_parent().add_child(ring)

	var tw := get_tree().create_tween()
	tw.tween_property(ring, "scale", Vector2(8.0, 8.0), 0.4)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.4)
	tw.tween_callback(ring.queue_free)


func _attack_homing() -> void:
	for i in HOMING_COUNT:
		var angle := TAU * i / float(HOMING_COUNT) + randf_range(-0.3, 0.3)
		var dir := Vector2.from_angle(angle)
		_spawn_projectile(global_position + dir * 30.0, dir * HOMING_SPEED, "homing")


# ---------------------------------------------------------------------------
# Projectile system
# ---------------------------------------------------------------------------
func _spawn_projectile(pos: Vector2, vel: Vector2, type: String, extra: Dictionary = {}) -> void:
	var proj := Node2D.new()

	var poly := Polygon2D.new()
	var size := 10.0 if type != "sweep" else 14.0
	var hs := size * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hs, -hs), Vector2(hs, -hs),
		Vector2(hs, hs), Vector2(-hs, hs)
	])

	match type:
		"spread": poly.color = Color(0.9, 0.5, 0.2)
		"sweep":  poly.color = Color(0.7, 0.3, 0.5)
		"drift":  poly.color = Color(0.5, 0.4, 0.8)
		"homing": poly.color = Color(1.0, 0.2, 0.4)

	proj.add_child(poly)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = hs
	cs.shape = circle
	area.add_child(cs)
	area.body_entered.connect(_on_proj_hit.bind(proj))
	proj.add_child(area)

	get_parent().add_child(proj)
	proj.global_position = pos  # Set AFTER add_child for correct transform

	var data := {"node": proj, "vel": vel, "type": type}
	data.merge(extra)
	_projectiles.append(data)


func _on_proj_hit(body: Node, proj: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1.0)
	if is_instance_valid(proj):
		proj.queue_free()


func _tick_projectiles(delta: float) -> void:
	var still_valid: Array[Dictionary] = []

	for p in _projectiles:
		var node: Node2D = p["node"]
		if not is_instance_valid(node):
			continue

		var vel: Vector2 = p["vel"]

		# Apply curve for drift projectiles
		if p["type"] == "drift" and p.has("curve"):
			var curve_rate: float = p["curve"]
			vel = vel.rotated(curve_rate * delta)
			p["vel"] = vel

		# Homing behavior
		if p["type"] == "homing" and _player != null and is_instance_valid(_player):
			var to_player := (_player.global_position - node.global_position).normalized()
			var current_dir := vel.normalized()
			var new_dir := current_dir.rotated(
				clampf(current_dir.angle_to(to_player), -HOMING_TURN * delta, HOMING_TURN * delta)
			)
			vel = new_dir * vel.length()
			p["vel"] = vel

		node.global_position += vel * delta

		# Bounds check
		var rel := node.global_position - _room_center
		if absf(rel.x) > ROOM_HW + 20.0 or absf(rel.y) > ROOM_HH + 20.0:
			node.queue_free()
		else:
			still_valid.append(p)

	_projectiles = still_valid


func _clear_projectiles() -> void:
	for p in _projectiles:
		if is_instance_valid(p["node"]):
			p["node"].queue_free()
	_projectiles.clear()


# ---------------------------------------------------------------------------
# Damage / Phase transitions
# ---------------------------------------------------------------------------
func take_damage(amount: float) -> void:
	if _phase == Phase.ASSEMBLY or _phase == Phase.CLIMAX:
		return   # invulnerable during assembly and climax

	current_health -= amount
	_flash_timer = 0.1
	EventBus.boss_health_changed.emit(maxf(current_health, 0.0), max_health)

	if current_health <= 0.0:
		_enter_climax()
		return

	if _phase == Phase.ACTIVE and current_health <= max_health * 0.3:
		_enter_unique()


func _tick_flash(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		_core_poly.color = Color(2.5, 2.5, 2.5)
	else:
		match _phase:
			Phase.ACTIVE:
				_core_poly.color = Color(0.25, 0.15, 0.35)
			Phase.UNIQUE:
				_core_poly.color = Color(0.5, 0.15, 0.25)


# ---------------------------------------------------------------------------
# Climax / Death
# ---------------------------------------------------------------------------
func _enter_climax() -> void:
	_phase = Phase.CLIMAX
	_climax_timer = FREEZE_DURATION
	velocity = Vector2.ZERO
	_end_beam()


func _tick_climax(delta: float) -> void:
	_climax_timer -= delta
	var blink := fmod(_climax_timer, 0.25) < 0.125
	_core_poly.color = Color(2.0, 0.3, 0.3) if blink else Color(0.2, 0.05, 0.08)

	if _climax_timer <= 0.0:
		_die()


func _die() -> void:
	_clear_projectiles()
	_end_beam()
	EventBus.boss_died.emit()
	queue_free()
