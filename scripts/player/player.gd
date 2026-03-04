extends CharacterBody2D

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var stats:        Node     = $Stats
@onready var body:         Node2D   = $Body
@onready var shoot_origin: Marker2D = $ShootOrigin

const PROJECTILE       = preload("res://scenes/player/projectile.tscn")
const IFRAME_DURATION  := 0.8

var _shoot_timer: float = 0.0
var _iframe_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")

# ---------------------------------------------------------------------------
# Physics
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_shooting(delta)
	_handle_iframes(delta)
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
	if stats.scatter_count <= 1:
		_spawn_projectile(direction)
	else:
		var spread := deg_to_rad(stats.scatter_spread_deg)
		var step   := spread / float(stats.scatter_count - 1)
		var start  := direction.angle() - spread / 2.0
		for i in stats.scatter_count:
			_spawn_projectile(Vector2.from_angle(start + step * i))

func _spawn_projectile(dir: Vector2) -> void:
	var proj: Area2D = PROJECTILE.instantiate()
	proj.global_position  = shoot_origin.global_position
	proj.direction        = dir
	proj.damage           = stats.damage
	proj.max_range        = stats.range_
	proj.ricochet         = stats.ricochet
	proj.explosive        = stats.explosive
	proj.explosion_radius = stats.explosion_radius
	proj.explosion_damage = stats.explosion_damage
	get_parent().add_child(proj)

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
	stats.current_health -= amount
	_iframe_timer = IFRAME_DURATION
	EventBus.player_health_changed.emit(stats.current_health, stats.max_health)
	if stats.current_health <= 0.0:
		_die()

func _die() -> void:
	RunManager.end_run(false)
