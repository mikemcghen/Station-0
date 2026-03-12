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

func _physics_process(delta: float) -> void:
	_tick_spawn_delay(delta)
	_find_player()
	_tick_contact(delta)
	_tick_flash(delta)
	_tick_slow(delta)
	if not is_active():
		return
	velocity = Vector2.ZERO
	_do_fire(delta)
	velocity *= get_slow_factor()
	move_and_slide()

# ---------------------------------------------------------------------------
# Stationary burst loop — fire 3 at player position, pause, repeat
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
		_shot_count = 0
		_shot_timer = BURST_PAUSE

func _fire_projectile() -> void:
	if _player == null:
		return
	AudioManager.play("enemy_shoot")
	# Fire at player's current position (not homing - player can dodge)
	var dir := (_player.global_position - global_position).normalized()
	var proj = ENEMY_PROJECTILE.instantiate()
	proj.position  = (get_parent() as Node2D).to_local(global_position)
	proj.direction = dir
	proj.speed     = 280.0
	proj.damage    = 1.0
	proj.max_range = 520.0
	get_parent().call_deferred("add_child", proj)