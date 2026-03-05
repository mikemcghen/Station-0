extends EnemyBase

# ---------------------------------------------------------------------------
# REPEATER — Task-loop corruption
# Snaps to the nearest wall on spawn and stays there forever.
# Fires a rotating burst loop indefinitely — a stationary turret.
# ---------------------------------------------------------------------------

const ENEMY_PROJECTILE = preload("res://scenes/enemies/enemy_projectile.tscn")

# Room interior half-extents (960×540 room, 32px walls, 16px gap buffer)
const INNER_HALF_X := 432.0
const INNER_HALF_Y := 222.0

const BURST_SIZE    := 3        # shots per burst
const SHOT_INTERVAL := 0.18     # seconds between shots within a burst
const BURST_PAUSE   := 1.8      # seconds after burst before rotating
const ROTATE_STEP   := 0.3491   # 20° in radians

var _fire_angle: float = 0.0
var _shot_count: int   = 0
var _shot_timer: float = 1.0   # initial delay before first burst

func _ready() -> void:
	max_health     = 30.0
	current_health = 30.0
	speed          = 0.0
	contact_damage = 0.5
	super._ready()
	_fire_angle = randf() * TAU
	_snap_to_wall()

# ---------------------------------------------------------------------------
# Snap to the nearest wall face at spawn
# ---------------------------------------------------------------------------
func _snap_to_wall() -> void:
	var room_center: Vector2 = (get_parent() as Node2D).global_position
	var lp:          Vector2 = global_position - room_center

	var d_left:  float = lp.x - (-INNER_HALF_X)
	var d_right: float = INNER_HALF_X - lp.x
	var d_up:    float = lp.y - (-INNER_HALF_Y)
	var d_down:  float = INNER_HALF_Y - lp.y
	var md:      float = minf(minf(d_left, d_right), minf(d_up, d_down))

	var wall_pos: Vector2
	if md == d_left:
		wall_pos = room_center + Vector2(-INNER_HALF_X, lp.y)
	elif md == d_right:
		wall_pos = room_center + Vector2( INNER_HALF_X, lp.y)
	elif md == d_up:
		wall_pos = room_center + Vector2(lp.x, -INNER_HALF_Y)
	else:
		wall_pos = room_center + Vector2(lp.x,  INNER_HALF_Y)

	global_position = wall_pos

func _physics_process(delta: float) -> void:
	_find_player()
	_tick_contact(delta)
	_tick_flash(delta)
	_tick_slow(delta)
	velocity = Vector2.ZERO
	_do_fire(delta)
	velocity *= _slow_factor
	move_and_slide()

# ---------------------------------------------------------------------------
# Stationary burst loop — fire 3, pause, rotate 20° CW, repeat
# ---------------------------------------------------------------------------
func _do_fire(delta: float) -> void:
	_shot_timer -= delta
	if _shot_timer > 0.0:
		return

	if _shot_count < BURST_SIZE:
		_fire_projectile()
		_shot_count += 1
		_shot_timer = SHOT_INTERVAL
	else:
		_fire_angle += ROTATE_STEP
		_shot_count = 0
		_shot_timer = BURST_PAUSE

func _fire_projectile() -> void:
	var proj = ENEMY_PROJECTILE.instantiate()
	proj.position  = (get_parent() as Node2D).to_local(global_position)
	proj.direction = Vector2.from_angle(_fire_angle)
	proj.speed     = 280.0
	proj.damage    = 1.0
	proj.max_range = 520.0
	get_parent().call_deferred("add_child", proj)