extends EnemyBase

# ---------------------------------------------------------------------------
# Hivemind — Floor 3 Final Boss
# Phase 1: Assembly (spawn waves, enemies join core on death, core grows)
# Phase 2: Active (teleports like Relay, orbiting projectiles follow)
# Phase 3: Unique (rotating beam, room pulse, homing projectiles)
# ---------------------------------------------------------------------------

enum Phase { ASSEMBLY, ACTIVE, UNIQUE, CLIMAX }

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const ROOM_HW := 480.0
const ROOM_HH := 270.0
const WALL_T  := 32.0
const WALL_MARGIN := 80.0

# Assembly phase
const WAVE_COUNT       := 3
const ENEMIES_PER_WAVE := 3
const WAVE_DELAY       := 3.5

# Teleport (like Relay)
const TELEPORT_CD_MIN  := 5.0
const TELEPORT_CD_MAX  := 7.0
const FADE_OUT_TIME    := 0.15
const TRANSIT_TIME     := 0.5

# Orbiting projectiles (6 static orbiters, no decay)
const ORBIT_COUNT      := 6
const ORBIT_RADIUS     := 60.0
const ORBIT_SPEED      := 2.0   # rad/sec
const ORBIT_PROJ_SIZE  := 10.0
const ORBIT_TRANSITION_SPEED := 200.0  # how fast orbiters follow after teleport

# Sweep attack (from Warden)
const SWEEP_CD         := 4.5
const SWEEP_SPEED      := 65.0
const SWEEP_PROJ_SPACE := 22.0
const SWEEP_GAP_W      := 90.0

# Phase 3 attacks
const ATTACK_CD_P3     := 2.5
const BEAM_TELEGRAPH   := 0.8   # warning time before beam fires
const BEAM_ROT_SPEED   := 1.2   # rad/sec
const BEAM_DURATION    := 3.0
const BEAM_LENGTH      := 500.0
const BEAM_WIDTH       := 28.0
const PULSE_FORCE      := 350.0
const PULSE_CD         := 5.0
const PULSE_RADIUS     := 200.0
const HOMING_COUNT     := 4
const HOMING_SPEED     := 120.0
const HOMING_TURN      := 1.8   # rad/sec
const HOMING_LIFETIME  := 7.0   # seconds before homing projectiles expire

const FREEZE_DURATION  := 2.0

const ORBITER_DAMAGE     := 1.0
const SWEEP_PROJ_DAMAGE  := 1.0
const BEAM_DAMAGE        := 1.0
const HOMING_PROJ_DAMAGE := 1.0

const DRIFTER_SCENE  = preload("res://scenes/enemies/drifter.tscn")
const REPEATER_SCENE = preload("res://scenes/enemies/repeater.tscn")
const ANCHOR_SCENE   = preload("res://scenes/enemies/anchor.tscn")
const BODY_PART_PICKUP = preload("res://scenes/upgrades/body_part_pickup.tscn")
const RUN_ITEM_PICKUP  = preload("res://scenes/items/run_item_pickup.tscn")

const ALL_PART_PATHS: Array[String] = [
	"res://data/body_parts/torso_reinforced_chassis.tres",
	"res://data/body_parts/torso_lightweight_frame.tres",
	"res://data/body_parts/left_arm_scatter_emitter.tres",
	"res://data/body_parts/left_arm_shield_projector.tres",
	"res://data/body_parts/right_arm_heavy_emitter.tres",
	"res://data/body_parts/right_arm_rapid_emitter.tres",
]

const ALL_ITEM_PATHS: Array[String] = [
	"res://data/run_items/coolant_leak.tres",
	"res://data/run_items/overclock_module.tres",
	"res://data/run_items/scrap_magnet.tres",
	"res://data/run_items/memory_spike.tres",
	"res://data/run_items/rust_coat.tres",
	"res://data/run_items/static_discharge.tres",
	"res://data/run_items/fragmented_map.tres",
	"res://data/run_items/plating_shard.tres",
	"res://data/run_items/range_booster.tres",
]

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _phase: Phase = Phase.ASSEMBLY
var _room_center: Vector2

# Assembly
var _wave_index:       int   = 0
var _wave_enemies:     Array[Node] = []  # enemies from current wave
var _spawned_enemies:  Array[Node] = []  # all spawned enemies (for tracking)
var _core_scale:       float = 0.3   # starts small, grows to 1.0
var _wave_spawned:     bool  = false  # has current wave been spawned?

# Core visual
var _core_visual: Node2D = null
var _core_poly:   Polygon2D = null
var _contact_area: Area2D = null
var _collision_shape: CollisionShape2D = null

# Teleport state
enum TeleportState { IDLE, FADING_OUT, IN_TRANSIT }
var _tp_state:        int   = TeleportState.IDLE
var _teleport_timer:  float = 3.0
var _fade_timer:      float = 0.0
var _transit_timer:   float = 0.0

# Orbiting projectiles
var _orbiters:        Array[Dictionary] = []  # {node, angle, transitioning}
var _orbit_angle:     float = 0.0

# Sweep attack
var _sweep_timer:     float = 3.0
var _sweep_projs:     Array[Dictionary] = []

# Phase 3 attacks
var _attack_timer:    float = 2.0
var _attack_index:    int   = 0
var _homing_projs:    Array[Dictionary] = []

# Beam state
var _beam_telegraphing: bool  = false
var _beam_active:       bool  = false
var _beam_angle:        float = 0.0
var _beam_timer:        float = 0.0
var _beam_node:         Node2D = null
var _telegraph_node:    Node2D = null
var _telegraph_timer:   float = 0.0

# Pulse state
var _pulse_timer:     float = 3.0

# Climax
var _climax_timer:    float = 0.0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	super._ready()
	max_health     = 350.0
	current_health = max_health
	contact_damage   = 1.5
	contact_cooldown = 0.8

	_room_center = global_position

	# Get scene collision nodes
	_contact_area = $ContactArea
	_collision_shape = $Collision

	_build_core_visual()
	_core_visual.visible = false   # hidden during assembly
	_core_visual.scale = Vector2(_core_scale, _core_scale)

	# During assembly: disable all collision (no hitbox until boss appears)
	if _contact_area:
		_contact_area.monitoring = false
		_contact_area.monitorable = false
	if _collision_shape:
		_collision_shape.disabled = true

	# Never collide with player via CharacterBody2D - use Area2D for contact damage only
	# This prevents the "attach" bug where player pushes boss around
	collision_mask = 1  # walls only


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

	_tick_orbiters(delta)
	_tick_sweep_projs(delta)
	_tick_homing_projs(delta)
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

	# Connect scene's contact area to damage handler
	if _contact_area:
		_contact_area.body_entered.connect(_on_contact_hit)


func _on_contact_hit(body: Node) -> void:
	if _phase == Phase.ASSEMBLY:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)


# ---------------------------------------------------------------------------
# Phase 1 — Assembly
# ---------------------------------------------------------------------------
func _tick_assembly(_delta: float) -> void:
	# Spawn first wave immediately, subsequent waves after previous is cleared
	if not _wave_spawned and _wave_index < WAVE_COUNT:
		_spawn_wave()
		_wave_spawned = true

	# Check if assembly complete: all waves spawned AND all enemies dead
	if _wave_index >= WAVE_COUNT and _spawned_enemies.size() == 0:
		_enter_active()


func _spawn_wave() -> void:
	AudioManager.play("hivemind_pulse")
	var scenes := [DRIFTER_SCENE, REPEATER_SCENE, ANCHOR_SCENE]
	var hw := ROOM_HW - WALL_T - 80.0
	var hh := ROOM_HH - WALL_T - 80.0

	_wave_enemies.clear()

	for i in ENEMIES_PER_WAVE:
		var scene = scenes[randi() % scenes.size()]
		var enemy = scene.instantiate()
		var pos := Vector2(
			randf_range(-hw, hw),
			randf_range(-hh, hh)
		)
		# Avoid spawning too close to center
		if pos.length() < 120.0:
			pos = pos.normalized() * 120.0
		get_parent().add_child(enemy)
		enemy.global_position = _room_center + pos

		# Track enemy for assembly phase
		_spawned_enemies.append(enemy)
		_wave_enemies.append(enemy)
		enemy.tree_exited.connect(_on_enemy_died.bind(enemy), CONNECT_ONE_SHOT)


func _on_enemy_died(enemy: Node) -> void:
	if _phase != Phase.ASSEMBLY:
		_spawned_enemies.erase(enemy)
		_wave_enemies.erase(enemy)
		return

	# Remove from tracked lists
	_spawned_enemies.erase(enemy)
	_wave_enemies.erase(enemy)

	# Play assembly sound per enemy absorbed
	AudioManager.play("hivemind_assembly")

	# Defer visual effect to avoid tree manipulation errors
	call_deferred("_spawn_soul_particle")

	# Check if wave is cleared — spawn next wave
	if _wave_enemies.size() == 0 and _wave_index < WAVE_COUNT:
		_wave_index += 1
		_wave_spawned = false  # allow next wave to spawn


func _spawn_soul_particle() -> void:
	if not is_inside_tree():
		return

	# Create purple dot flying to center
	var part := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 6:
		var a := TAU * i / 6.0
		pts.append(Vector2(cos(a), sin(a)) * randf_range(8.0, 14.0))
	part.polygon = pts
	part.color = Color(0.5, 0.2, 0.6, 0.9)
	part.global_position = _room_center + Vector2(randf_range(-150, 150), randf_range(-150, 150))
	get_parent().add_child(part)

	# Tween to center and grow the core
	var tw := get_tree().create_tween()
	tw.tween_property(part, "global_position", _room_center, 0.6).set_ease(Tween.EASE_IN)
	tw.tween_callback(_grow_core)
	tw.tween_property(part, "modulate:a", 0.0, 0.2)
	tw.tween_callback(part.queue_free)


func _grow_core() -> void:
	# Each kill grows the core toward full size
	var total_enemies := WAVE_COUNT * ENEMIES_PER_WAVE
	var growth_per_kill := 0.7 / float(total_enemies)  # grows from 0.3 to 1.0
	_core_scale = minf(_core_scale + growth_per_kill, 1.0)

	# Show core once it starts growing, and enable scaled collision
	if not _core_visual.visible:
		_core_visual.visible = true
		# Enable collision now that visual is appearing
		if _collision_shape:
			_collision_shape.disabled = false

	_core_visual.scale = Vector2(_core_scale, _core_scale)

	# Scale collision to match visual
	if _collision_shape:
		_collision_shape.scale = Vector2(_core_scale, _core_scale)
	if _contact_area:
		_contact_area.scale = Vector2(_core_scale, _core_scale)


func _enter_active() -> void:
	_phase = Phase.ACTIVE
	_core_visual.visible = true
	_core_visual.scale = Vector2(1.0, 1.0)

	# Enable contact area for damage detection (Area2D handles player contact)
	if _contact_area:
		_contact_area.monitoring = true
		_contact_area.monitorable = true
		_contact_area.scale = Vector2(1.0, 1.0)
	if _collision_shape:
		_collision_shape.disabled = false
		_collision_shape.scale = Vector2(1.0, 1.0)
	# Keep collision_mask = 1 (walls only) to prevent "attach" bug

	_teleport_timer = 2.0
	_sweep_timer = 3.0

	# Spawn 6 static orbiting projectiles
	_spawn_orbiters()


# ---------------------------------------------------------------------------
# Phase 2 — Active (teleport + orbiters + sweep)
# ---------------------------------------------------------------------------
func _tick_active(delta: float) -> void:
	_find_player()
	_tick_contact(delta)
	_tick_teleport(delta)

	# Sweep attack on timer (only when idle)
	if _tp_state == TeleportState.IDLE:
		_sweep_timer -= delta
		if _sweep_timer <= 0.0:
			_attack_sweep()
			_sweep_timer = SWEEP_CD


func _tick_teleport(delta: float) -> void:
	match _tp_state:
		TeleportState.IDLE:
			# Don't start teleport during beam attack
			if _beam_telegraphing or _beam_active:
				return
			_teleport_timer -= delta
			if _teleport_timer <= 0.0:
				_start_fade_out()
		TeleportState.FADING_OUT:
			_fade_timer -= delta
			_core_visual.modulate.a = _fade_timer / FADE_OUT_TIME
			if _fade_timer <= 0.0:
				_enter_transit()
		TeleportState.IN_TRANSIT:
			_transit_timer -= delta
			if _transit_timer <= 0.0:
				_reappear()


func _start_fade_out() -> void:
	AudioManager.play("hivemind_teleport")
	_tp_state = TeleportState.FADING_OUT
	_fade_timer = FADE_OUT_TIME


func _enter_transit() -> void:
	_tp_state = TeleportState.IN_TRANSIT
	_core_visual.visible = false
	_core_visual.modulate.a = 0.0
	if _contact_area:
		_contact_area.monitoring = false
	if _collision_shape:
		_collision_shape.disabled = true
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

	# Show visual with flash
	_core_visual.visible = true
	_core_visual.modulate = Color(2.0, 2.0, 2.0, 1.0)
	if _contact_area:
		_contact_area.monitoring = true
	if _collision_shape:
		_collision_shape.disabled = false

	var tw := create_tween()
	var base_color := Color(0.5, 0.15, 0.25) if _phase == Phase.UNIQUE else Color(1, 1, 1, 1)
	tw.tween_property(_core_visual, "modulate", base_color, 0.15)

	_tp_state = TeleportState.IDLE

	# Set orbiters to transition toward new position (don't teleport with boss)
	for orb in _orbiters:
		orb["transitioning"] = true

	_roll_teleport_cooldown()


func _roll_teleport_cooldown() -> void:
	_teleport_timer = randf_range(TELEPORT_CD_MIN, TELEPORT_CD_MAX)


# ---------------------------------------------------------------------------
# Orbiting Projectiles
# ---------------------------------------------------------------------------
func _spawn_orbiters() -> void:
	# Spawn 6 static orbiters evenly spaced
	for i in ORBIT_COUNT:
		var angle := TAU * i / float(ORBIT_COUNT)
		var orb := _create_orbiter(angle)
		_orbiters.append(orb)


func _create_orbiter(angle: float) -> Dictionary:
	var proj := Node2D.new()

	var poly := Polygon2D.new()
	var hs := ORBIT_PROJ_SIZE * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hs, -hs), Vector2(hs, -hs),
		Vector2(hs, hs), Vector2(-hs, hs)
	])
	poly.color = Color(0.6, 0.3, 0.7)
	proj.add_child(poly)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = hs
	cs.shape = circle
	area.add_child(cs)
	area.body_entered.connect(_on_orbiter_hit.bind(proj))
	proj.add_child(area)

	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2.from_angle(angle) * ORBIT_RADIUS

	return {"node": proj, "angle": angle, "transitioning": false}


func _on_orbiter_hit(body: Node, _proj: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(ORBITER_DAMAGE)


func _tick_orbiters(delta: float) -> void:
	if _phase == Phase.ASSEMBLY:
		return

	_orbit_angle += ORBIT_SPEED * delta

	# Simple orbit movement (no decay)
	for orb in _orbiters:
		var node: Node2D = orb["node"]
		if not is_instance_valid(node):
			continue

		var angle: float = orb["angle"] + _orbit_angle
		var target_pos := global_position + Vector2.from_angle(angle) * ORBIT_RADIUS

		if orb["transitioning"]:
			# Move toward target position after teleport
			var dir := (target_pos - node.global_position).normalized()
			var dist := node.global_position.distance_to(target_pos)
			if dist < ORBIT_TRANSITION_SPEED * delta:
				node.global_position = target_pos
				orb["transitioning"] = false
			else:
				node.global_position += dir * ORBIT_TRANSITION_SPEED * delta
		else:
			# Normal orbit
			node.global_position = target_pos


func _clear_orbiters() -> void:
	for orb in _orbiters:
		if is_instance_valid(orb["node"]):
			orb["node"].queue_free()
	_orbiters.clear()


# ---------------------------------------------------------------------------
# Sweep Attack (from Warden)
# ---------------------------------------------------------------------------
func _attack_sweep() -> void:
	AudioManager.play("hivemind_sweep")
	var inner_left  := -ROOM_HW + WALL_T
	var inner_right :=  ROOM_HW - WALL_T
	var sweep_dir   := 1.0 if randf() < 0.5 else -1.0

	# Fix: sweep_dir 1 = moving DOWN, so start at TOP
	var start_y: float
	if sweep_dir > 0.0:
		start_y = _room_center.y - ROOM_HH + WALL_T - 10.0  # top edge
	else:
		start_y = _room_center.y + ROOM_HH - WALL_T + 10.0  # bottom edge

	var vel := Vector2(0.0, SWEEP_SPEED * sweep_dir)

	# One gap
	var gap_center := randf_range(inner_left + 100.0, inner_right - 100.0)

	var x := inner_left
	while x <= inner_right:
		if abs(x - gap_center) > SWEEP_GAP_W * 0.5:
			_spawn_sweep_proj(Vector2(_room_center.x + x, start_y), vel)
		x += SWEEP_PROJ_SPACE


func _spawn_sweep_proj(pos: Vector2, vel: Vector2) -> void:
	var proj := Node2D.new()

	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-7, -7), Vector2(7, -7),
		Vector2(7, 7), Vector2(-7, 7)
	])
	poly.color = Color(0.7, 0.3, 0.5)
	proj.add_child(poly)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	cs.shape = circle
	area.add_child(cs)
	area.body_entered.connect(_on_sweep_hit.bind(proj))
	proj.add_child(area)

	get_parent().add_child(proj)
	proj.global_position = pos

	_sweep_projs.append({"node": proj, "vel": vel})


func _on_sweep_hit(body: Node, proj: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(SWEEP_PROJ_DAMAGE)
	if is_instance_valid(proj):
		proj.queue_free()


func _tick_sweep_projs(delta: float) -> void:
	var still_valid: Array[Dictionary] = []

	for p in _sweep_projs:
		if not p.has("node") or not p.has("vel"):
			continue

		# Check validity on raw value before casting
		var raw_node = p["node"]
		if raw_node == null or not is_instance_valid(raw_node):
			continue

		var node := raw_node as Node2D
		if node == null:
			continue

		var vel: Vector2 = p["vel"]
		node.global_position += vel * delta

		# Bounds check
		if absf(node.global_position.y - _room_center.y) > ROOM_HH + 30.0:
			node.queue_free()
		else:
			still_valid.append(p)

	_sweep_projs = still_valid


# ---------------------------------------------------------------------------
# Phase 3 — Unique attacks
# ---------------------------------------------------------------------------
func _enter_unique() -> void:
	_phase = Phase.UNIQUE
	_attack_timer = 1.5
	_attack_index = 0
	_pulse_timer = PULSE_CD * 0.5

	# Visual change — cracking/glowing
	_core_poly.color = Color(0.5, 0.15, 0.25)


func _tick_unique(delta: float) -> void:
	_find_player()
	_tick_contact(delta)
	_tick_teleport(delta)

	# Only attack when not teleporting
	if _tp_state != TeleportState.IDLE:
		return

	# Beam telegraph phase
	if _beam_telegraphing:
		_tick_beam_telegraph(delta)
	elif _beam_active:
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
		2: _attack_sweep()


func _start_beam() -> void:
	AudioManager.play("hivemind_beam")
	# Start with telegraph phase
	_beam_telegraphing = true
	_telegraph_timer = BEAM_TELEGRAPH
	_beam_angle = randf() * TAU

	# Create thin flashing telegraph line
	_telegraph_node = Node2D.new()
	_telegraph_node.position = Vector2.ZERO

	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(0, -2), Vector2(BEAM_LENGTH, -2),
		Vector2(BEAM_LENGTH, 2), Vector2(0, 2)
	])
	poly.color = Color(1.0, 0.5, 0.5, 0.8)
	poly.name = "TelegraphLine"
	_telegraph_node.add_child(poly)

	_telegraph_node.rotation = _beam_angle
	add_child(_telegraph_node)


func _tick_beam_telegraph(delta: float) -> void:
	_telegraph_timer -= delta

	# Flash the telegraph line
	if _telegraph_node != null:
		var line := _telegraph_node.get_node_or_null("TelegraphLine") as Polygon2D
		if line:
			var flash := fmod(_telegraph_timer, 0.15) < 0.075
			line.color = Color(1.0, 0.3, 0.3, 0.9) if flash else Color(1.0, 0.7, 0.7, 0.5)

	if _telegraph_timer <= 0.0:
		_end_telegraph_start_beam()


func _end_telegraph_start_beam() -> void:
	_beam_telegraphing = false

	# Remove telegraph
	if _telegraph_node != null:
		_telegraph_node.queue_free()
		_telegraph_node = null

	# Now spawn the actual beam
	_beam_active = true
	_beam_timer = BEAM_DURATION

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

	_beam_node.rotation = _beam_angle
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
	_beam_telegraphing = false
	if _beam_node != null:
		_beam_node.queue_free()
		_beam_node = null
	if _telegraph_node != null:
		_telegraph_node.queue_free()
		_telegraph_node = null


func _on_beam_hit(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(BEAM_DAMAGE)


func _attack_pulse() -> void:
	AudioManager.play("hivemind_knockback")
	if _player == null or not is_instance_valid(_player):
		return

	# Only apply knockback if player is within pulse radius
	var dist := global_position.distance_to(_player.global_position)
	if dist <= PULSE_RADIUS:
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
		_spawn_homing_proj(angle)


func _spawn_homing_proj(start_angle: float) -> void:
	var proj := Node2D.new()
	proj.set_meta("angle", start_angle)

	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(5, 0),
		Vector2(0, 8), Vector2(-5, 0)
	])
	poly.color = Color(1.0, 0.2, 0.4)
	proj.add_child(poly)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	cs.shape = circle
	area.add_child(cs)
	area.body_entered.connect(_on_homing_hit.bind(proj))
	proj.add_child(area)

	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2.from_angle(start_angle) * 30.0

	_homing_projs.append({"node": proj, "angle": start_angle, "age": 0.0})


func _on_homing_hit(body: Node, proj: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(HOMING_PROJ_DAMAGE)
	if is_instance_valid(proj):
		proj.queue_free()


func _tick_homing_projs(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		# Player died or invalid — clear all homing projectiles
		for p in _homing_projs:
			var raw_node = p.get("node")
			if raw_node != null and is_instance_valid(raw_node):
				raw_node.queue_free()
		_homing_projs.clear()
		return

	var still_valid: Array[Dictionary] = []

	for p in _homing_projs:
		# Check validity on raw value before typed assignment to avoid error
		var raw_node = p.get("node")
		if raw_node == null or not is_instance_valid(raw_node):
			continue

		var node := raw_node as Node2D
		if node == null:
			continue

		# Age check
		p["age"] += delta
		if p["age"] >= HOMING_LIFETIME:
			node.queue_free()
			continue

		var angle: float = p["angle"]
		var to_player := (_player.global_position - node.global_position).normalized()
		var desired_angle := to_player.angle()

		var diff := angle_difference(angle, desired_angle)
		angle += clampf(diff, -HOMING_TURN * delta, HOMING_TURN * delta)
		p["angle"] = angle

		var dir := Vector2.from_angle(angle)
		node.global_position += dir * HOMING_SPEED * delta
		node.rotation = angle + PI / 2

		# Bounds check
		var rel := node.global_position - _room_center
		if absf(rel.x) > ROOM_HW - WALL_T or absf(rel.y) > ROOM_HH - WALL_T:
			node.queue_free()
		else:
			still_valid.append(p)

	_homing_projs = still_valid


# ---------------------------------------------------------------------------
# Damage / Phase transitions
# ---------------------------------------------------------------------------
func take_damage(amount: float) -> void:
	if _phase == Phase.ASSEMBLY or _phase == Phase.CLIMAX:
		return   # invulnerable during assembly and climax
	if _tp_state != TeleportState.IDLE:
		return   # invulnerable while teleporting

	current_health -= amount
	_flash_timer = 0.1
	AudioManager.play("enemy_hit")

	if current_health <= 0.0:
		_enter_climax()
		return

	if _phase == Phase.ACTIVE and current_health <= max_health * 0.3:
		_enter_unique()


func _tick_flash(delta: float) -> void:
	if _phase == Phase.ASSEMBLY:
		return
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
	AudioManager.play("boss_death")
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
	AudioManager.play("enemy_death")
	_clear_orbiters()
	_end_beam()

	for p in _sweep_projs:
		if is_instance_valid(p["node"]):
			p["node"].queue_free()
	_sweep_projs.clear()

	for p in _homing_projs:
		if is_instance_valid(p["node"]):
			p["node"].queue_free()
	_homing_projs.clear()

	# Clear any remaining spawned enemies from assembly
	for enemy in _spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_spawned_enemies.clear()
	_wave_enemies.clear()

	# Always spawn item pickup
	_spawn_item_drop()
	# Also spawn body part if player doesn't have all
	_spawn_body_part_drop()

	EventBus.boss_died.emit()
	queue_free()

func _spawn_item_drop() -> void:
	# Filter out already collected items
	var available: Array[String] = []
	for path in ALL_ITEM_PATHS:
		var already_collected := false
		for collected in RunManager.run_items:
			if collected.resource_path == path:
				already_collected = true
				break
		if not already_collected:
			available.append(path)
	if available.is_empty():
		return
	var chosen: String = available[randi() % available.size()]
	var pickup = RUN_ITEM_PICKUP.instantiate()
	pickup.item = load(chosen)
	var spawn_pos := global_position + Vector2(-30, 0)
	get_parent().call_deferred("add_child", pickup)
	pickup.set_deferred("global_position", spawn_pos)

func _spawn_body_part_drop() -> void:
	var unacquired: Array[String] = []
	for path in ALL_PART_PATHS:
		if path not in UpgradeManager.acquired_part_paths:
			unacquired.append(path)
	if unacquired.is_empty():
		return
	var chosen: String = unacquired[randi() % unacquired.size()]
	var pickup = BODY_PART_PICKUP.instantiate()
	pickup.part = load(chosen)
	var spawn_pos := global_position + Vector2(30, 0)
	get_parent().call_deferred("add_child", pickup)
	pickup.set_deferred("global_position", spawn_pos)
