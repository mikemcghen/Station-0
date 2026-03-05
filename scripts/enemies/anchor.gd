extends EnemyBase

# ---------------------------------------------------------------------------
# ANCHOR — Structural integrity corruption
# Drifts to a random floor point, anchors for a random duration while firing
# homing projectiles, then picks a new point. Invincible while drifting.
# ---------------------------------------------------------------------------

const ENEMY_PROJECTILE = preload("res://scenes/enemies/enemy_projectile.tscn")

enum State { DRIFTING, ANCHORED }

# Room interior half-extents (960×540 room, 32px walls, 16px gap buffer)
const INNER_HALF_X   := 432.0
const INNER_HALF_Y   := 222.0
# Margin from walls so it stays on the floor interior
const FLOOR_MARGIN   := 80.0

const SHOT_COOLDOWN   := 2.2
const ANCHOR_TIME_MIN := 3.0
const ANCHOR_TIME_MAX := 6.0

var _state:        State   = State.DRIFTING
var _target_pos:   Vector2
var _shot_timer:   float   = 1.0
var _anchor_timer: float   = 0.0

func _ready() -> void:
	max_health     = 40.0
	current_health = 40.0
	speed          = 95.0
	contact_damage = 0.5
	super._ready()
	_pick_floor_point()

# ---------------------------------------------------------------------------
# Pick a random point within the room interior
# ---------------------------------------------------------------------------
func _pick_floor_point() -> void:
	var room_center: Vector2 = (get_parent() as Node2D).global_position
	var rx: float = randf_range(-INNER_HALF_X + FLOOR_MARGIN, INNER_HALF_X - FLOOR_MARGIN)
	var ry: float = randf_range(-INNER_HALF_Y + FLOOR_MARGIN, INNER_HALF_Y - FLOOR_MARGIN)
	_target_pos = room_center + Vector2(rx, ry)

func _physics_process(delta: float) -> void:
	_find_player()
	_tick_contact(delta)
	_tick_flash(delta)
	_tick_slow(delta)

	match _state:
		State.DRIFTING:
			_do_seek()
		State.ANCHORED:
			_do_anchored(delta)

	velocity *= _slow_factor
	move_and_slide()

# ---------------------------------------------------------------------------
# Invincible while drifting
# ---------------------------------------------------------------------------
func take_damage(amount: float) -> void:
	if _state == State.DRIFTING:
		return
	super.take_damage(amount)

# ---------------------------------------------------------------------------
# Drift toward target floor point, then anchor
# ---------------------------------------------------------------------------
func _do_seek() -> void:
	var diff := _target_pos - global_position
	if diff.length() < 12.0:
		velocity      = Vector2.ZERO
		_state        = State.ANCHORED
		_shot_timer   = SHOT_COOLDOWN * 0.5
		_anchor_timer = randf_range(ANCHOR_TIME_MIN, ANCHOR_TIME_MAX)
	else:
		velocity = diff.normalized() * speed

# ---------------------------------------------------------------------------
# Anchored — fire homing projectiles; leave when anchor_timer expires
# ---------------------------------------------------------------------------
func _do_anchored(delta: float) -> void:
	velocity = Vector2.ZERO

	_anchor_timer -= delta
	if _anchor_timer <= 0.0:
		_state = State.DRIFTING
		_pick_floor_point()
		return

	_shot_timer -= delta
	if _shot_timer <= 0.0 and _player != null:
		_fire_at_player()
		_shot_timer = SHOT_COOLDOWN

func _fire_at_player() -> void:
	var dir  := (_player.global_position - global_position).normalized()
	var proj = ENEMY_PROJECTILE.instantiate()
	proj.position      = (get_parent() as Node2D).to_local(global_position)
	proj.direction     = dir
	proj.speed         = 120.0
	proj.damage        = 1.0
	proj.max_range     = 720.0
	proj.homing        = true
	proj.homing_target = _player
	get_parent().call_deferred("add_child", proj)