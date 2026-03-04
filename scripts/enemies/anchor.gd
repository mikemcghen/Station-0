extends CharacterBody2D

# ---------------------------------------------------------------------------
# ANCHOR — Structural integrity corruption
# Pathfinds to nearest wall, locks in. Fires slow homing projectiles.
# Does not move once anchored.
# ---------------------------------------------------------------------------

const ENEMY_PROJECTILE = preload("res://scenes/enemies/enemy_projectile.tscn")

enum State { SEEKING, ANCHORED }

var max_health:      float = 40.0
var current_health:  float = 40.0
var speed:           float = 95.0
var contact_damage:  float = 0.5
var contact_cooldown: float = 0.8

const SHOT_COOLDOWN  := 2.2
# Room interior half-extents (960×540 room, 32px walls, 16px gap buffer)
const INNER_HALF_X   := 432.0
const INNER_HALF_Y   := 222.0

var _player:        Node2D = null
var _state:         State  = State.SEEKING
var _target_wall:   Vector2
var _shot_timer:    float  = 1.0   # initial fire delay
var _contact_timer: float  = 0.0
var _flash_timer:   float  = 0.0

@onready var visual: Node2D = $Visual

func _ready() -> void:
	add_to_group("enemies")
	$ContactArea.body_entered.connect(_on_contact_entered)
	_compute_wall_target()

# ---------------------------------------------------------------------------
# Find the nearest wall face and set it as the target
# ---------------------------------------------------------------------------
func _compute_wall_target() -> void:
	var room_center: Vector2 = (get_parent() as Node2D).global_position
	var lp:          Vector2 = global_position - room_center

	var d_left:  float = lp.x - (-INNER_HALF_X)
	var d_right: float = INNER_HALF_X - lp.x
	var d_up:    float = lp.y - (-INNER_HALF_Y)
	var d_down:  float = INNER_HALF_Y - lp.y
	var md:      float = minf(minf(d_left, d_right), minf(d_up, d_down))

	if md == d_left:
		_target_wall = room_center + Vector2(-INNER_HALF_X, lp.y)
	elif md == d_right:
		_target_wall = room_center + Vector2( INNER_HALF_X, lp.y)
	elif md == d_up:
		_target_wall = room_center + Vector2(lp.x, -INNER_HALF_Y)
	else:
		_target_wall = room_center + Vector2(lp.x,  INNER_HALF_Y)

func _physics_process(delta: float) -> void:
	_find_player()
	_tick_contact(delta)
	_tick_flash(delta)
	match _state:
		State.SEEKING:
			_do_seek()
		State.ANCHORED:
			_do_anchored(delta)
	move_and_slide()

func _find_player() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

# ---------------------------------------------------------------------------
# Move toward the nearest wall, then lock in
# ---------------------------------------------------------------------------
func _do_seek() -> void:
	var diff := _target_wall - global_position
	if diff.length() < 12.0:
		velocity = Vector2.ZERO
		_state = State.ANCHORED
	else:
		velocity = diff.normalized() * speed

# ---------------------------------------------------------------------------
# Stationary — fire slow homing projectiles at the player
# ---------------------------------------------------------------------------
func _do_anchored(delta: float) -> void:
	velocity = Vector2.ZERO
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

func take_damage(amount: float) -> void:
	current_health -= amount
	_flash_timer = 0.1
	if current_health <= 0.0:
		_die()

func _die() -> void:
	_spawn_drop()
	queue_free()

func _spawn_drop() -> void:
	var orb = preload("res://scenes/enemies/currency_orb.tscn").instantiate()
	orb.position = (get_parent() as Node2D).to_local(global_position)
	get_parent().call_deferred("add_child", orb)

func _on_contact_entered(body: Node) -> void:
	if body.is_in_group("player") and _contact_timer == 0.0:
		body.take_damage(contact_damage)
		_contact_timer = contact_cooldown

func _tick_contact(delta: float) -> void:
	_contact_timer = maxf(_contact_timer - delta, 0.0)

func _tick_flash(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		visual.modulate = Color(2.5, 2.5, 2.5)
	else:
		visual.modulate = Color(1.0, 1.0, 1.0)
