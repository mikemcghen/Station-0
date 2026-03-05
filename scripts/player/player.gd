extends CharacterBody2D

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var stats:        Node     = $Stats
@onready var body:         Node2D   = $Body
@onready var shoot_origin: Marker2D = $ShootOrigin

const PROJECTILE       = preload("res://scenes/player/projectile.tscn")
const IFRAME_DURATION  := 0.8
const SHIELD_COOLDOWN  := 3.0

var _shoot_timer:  float = 0.0
var _iframe_timer: float = 0.0

# Overclock — counts shots fired; every 3rd deals 0 damage
var _overclock_counter: int = 0

# Memory Spike — first projectile per room deals 3x damage
var _memory_spike_available: bool = true

# Shield Projector — active block, absorbs one hit
var _shield_ready:    bool  = true
var _shield_active:   bool  = false
var _shield_cd_timer: float = 0.0

# Oil slick — count of slick zones currently overlapping player
var _slick_count: int = 0

func _ready() -> void:
	add_to_group("player")
	EventBus.room_entered.connect(_on_room_entered)
	EventBus.room_cleared.connect(_on_room_cleared)

# ---------------------------------------------------------------------------
# Physics
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_shooting(delta)
	_handle_iframes(delta)
	_handle_shield(delta)
	move_and_slide()

# ---------------------------------------------------------------------------
# Movement — WASD, 8-directional (direct key checks, no input map needed)
# ---------------------------------------------------------------------------
func _handle_movement() -> void:
	var input_dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): input_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S): input_dir.y += 1
	if Input.is_physical_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D): input_dir.x += 1
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	if _slick_count > 0:
		# Oil slick — momentum-based: velocity slowly drifts toward desired direction
		velocity = velocity.lerp(input_dir * stats.speed, 0.08)
	else:
		velocity = input_dir * stats.speed

	if input_dir.x != 0.0:
		body.scale.x = sign(input_dir.x)

# ---------------------------------------------------------------------------
# Shooting — Arrow keys via built-in ui_ actions (always available in Godot)
# ---------------------------------------------------------------------------
func _handle_shooting(delta: float) -> void:
	_shoot_timer = maxf(_shoot_timer - delta, 0.0)

	var shoot_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		shoot_dir = Vector2.UP
	elif Input.is_action_pressed("ui_down"):
		shoot_dir = Vector2.DOWN
	elif Input.is_action_pressed("ui_left"):
		shoot_dir = Vector2.LEFT
	elif Input.is_action_pressed("ui_right"):
		shoot_dir = Vector2.RIGHT

	if shoot_dir != Vector2.ZERO and _shoot_timer == 0.0:
		_fire(shoot_dir)
		_shoot_timer = 1.0 / stats.fire_rate

func _fire(direction: Vector2) -> void:
	# Overclock: every 3rd shot deals 0 damage
	var is_zeroed_shot := false
	if stats.overclock:
		_overclock_counter += 1
		if _overclock_counter >= 3:
			_overclock_counter = 0
			is_zeroed_shot = true

	if stats.scatter_count <= 1:
		_spawn_projectile(direction, is_zeroed_shot)
	else:
		var spread := deg_to_rad(stats.scatter_spread_deg)
		var step   := spread / float(stats.scatter_count - 1) if stats.scatter_count > 1 else 0.0
		var start  := direction.angle() - spread / 2.0
		for i in stats.scatter_count:
			_spawn_projectile(Vector2.from_angle(start + step * i), is_zeroed_shot)

func _spawn_projectile(dir: Vector2, zero_damage: bool = false) -> void:
	var proj: Area2D = PROJECTILE.instantiate()
	proj.global_position  = shoot_origin.global_position
	proj.direction        = dir
	proj.speed            = stats.proj_speed
	proj.max_range        = stats.range_
	proj.ricochet         = stats.ricochet
	proj.explosive        = stats.explosive
	proj.explosion_radius = stats.explosion_radius
	proj.explosion_damage = stats.explosion_damage

	if zero_damage:
		proj.damage = 0.0
	elif stats.memory_spike and _memory_spike_available:
		proj.damage = stats.damage * 3.0
		_memory_spike_available = false
	else:
		proj.damage = stats.damage

	get_parent().add_child(proj)

# ---------------------------------------------------------------------------
# Shield Projector — Space to activate; absorbs one hit, SHIELD_COOLDOWN
# ---------------------------------------------------------------------------
func _handle_shield(delta: float) -> void:
	if not stats.shield_projector:
		_shield_active   = false
		_shield_ready    = true
		_shield_cd_timer = 0.0
		return

	if _shield_cd_timer > 0.0:
		_shield_cd_timer -= delta
		if _shield_cd_timer <= 0.0:
			_shield_ready = true

	if _shield_ready and Input.is_physical_key_pressed(KEY_SPACE):
		_shield_active = true

# ---------------------------------------------------------------------------
# Iframes — flash body during invincibility
# ---------------------------------------------------------------------------
func _handle_iframes(delta: float) -> void:
	if _iframe_timer <= 0.0:
		body.modulate = Color(1, 1, 1, 1)
		return
	_iframe_timer -= delta
	# Visible flash every 0.1s
	body.modulate = Color(1, 1, 1, 0.25) if fmod(_iframe_timer, 0.2) < 0.1 else Color(1, 1, 1, 1)

# ---------------------------------------------------------------------------
# Damage / death
# ---------------------------------------------------------------------------
func take_damage(amount: float) -> void:
	if _iframe_timer > 0.0:
		return

	# Shield Projector — absorb one hit
	if _shield_active:
		_shield_active   = false
		_shield_ready    = false
		_shield_cd_timer = SHIELD_COOLDOWN
		return

	# Rust Coat — reduce damage (min 1)
	var actual := amount
	if stats.rust_coat:
		actual = maxf(actual - stats.damage_reduction, 1.0)

	stats.current_health -= actual
	_iframe_timer = IFRAME_DURATION
	EventBus.player_health_changed.emit(stats.current_health, stats.max_health)

	# Reactive effects on taking damage
	if stats.static_discharge:
		_trigger_static_discharge()
	if stats.coolant_leak:
		_spawn_coolant_zone()

	if stats.current_health <= 0.0:
		_die()

func _die() -> void:
	RunManager.end_run(false)

# ---------------------------------------------------------------------------
# Static Discharge — instant AoE damage to enemies in radius
# ---------------------------------------------------------------------------
func _trigger_static_discharge() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= stats.discharge_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(stats.discharge_damage)

# ---------------------------------------------------------------------------
# Coolant Leak — spawn a temporary slow zone at player position (1s)
# ---------------------------------------------------------------------------
func _spawn_coolant_zone() -> void:
	var zone := Area2D.new()
	zone.collision_layer = 0
	zone.collision_mask  = 8   # enemy CharacterBody2D layer

	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 24.0
	cs.shape  = sh
	zone.add_child(cs)
	zone.position = (get_parent() as Node2D).to_local(global_position)

	zone.body_entered.connect(func(b: Node) -> void:
		if b.has_method("apply_slow"):
			b.apply_slow(2.0, 0.4))

	get_parent().call_deferred("add_child", zone)
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		if is_instance_valid(zone):
			zone.queue_free())

# ---------------------------------------------------------------------------
# Oil slick — called by hazard Area2D nodes
# ---------------------------------------------------------------------------
func enter_slick() -> void:
	_slick_count += 1

func exit_slick() -> void:
	_slick_count = maxi(_slick_count - 1, 0)

# ---------------------------------------------------------------------------
# Room event handlers
# ---------------------------------------------------------------------------
func _on_room_entered(_room_id: String) -> void:
	_memory_spike_available = true
	_overclock_counter      = 0

func _on_room_cleared(_room_id: String) -> void:
	if stats.fragmented_map:
		EventBus.room_revealed.emit()