extends CharacterBody2D

# ---------------------------------------------------------------------------
# REPEATER — Task-loop corruption
# Drifts to last known player position, stops, fires a rotating burst loop.
# Does not re-track the player — stuck completing a subroutine.
# ---------------------------------------------------------------------------

const ENEMY_PROJECTILE = preload("res://scenes/enemies/enemy_projectile.tscn")

enum State { DRIFTING, FIRING }

var max_health:      float = 24.0
var current_health:  float = 24.0
var speed:           float = 60.0
var contact_damage:  float = 0.5
var contact_cooldown: float = 0.8

const BURST_SIZE    := 3        # shots per burst
const SHOT_INTERVAL := 0.18     # seconds between shots within a burst
const BURST_PAUSE   := 1.8      # seconds after burst completes before rotating
const ROTATE_STEP   := 0.3491   # 20° in radians

var _player:        Node2D = null
var _state:         State  = State.DRIFTING
var _target_pos:    Vector2
var _target_set:    bool   = false
var _fire_angle:    float  = 0.0
var _shot_count:    int    = 0
var _shot_timer:    float  = 0.0
var _contact_timer: float  = 0.0
var _flash_timer:   float  = 0.0

@onready var visual: Node2D = $Visual

func _ready() -> void:
	add_to_group("enemies")
	$ContactArea.body_entered.connect(_on_contact_entered)
	_fire_angle = randf() * TAU   # random initial burst direction

func _physics_process(delta: float) -> void:
	_find_player()
	_tick_contact(delta)
	_tick_flash(delta)
	match _state:
		State.DRIFTING:
			_do_drift()
		State.FIRING:
			_do_fire(delta)
	move_and_slide()

func _find_player() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

# ---------------------------------------------------------------------------
# Drift toward last known position, then lock and fire
# ---------------------------------------------------------------------------
func _do_drift() -> void:
	if _player == null:
		velocity = Vector2.ZERO
		return
	# Capture target position once
	if not _target_set:
		_target_pos = _player.global_position
		_target_set = true

	var diff := _target_pos - global_position
	if diff.length() < 12.0:
		velocity = Vector2.ZERO
		# Aim first burst toward player
		if _player != null:
			_fire_angle = (_player.global_position - global_position).angle()
		_state = State.FIRING
		_shot_count = 0
		_shot_timer = 0.0
	else:
		velocity = diff.normalized() * speed

# ---------------------------------------------------------------------------
# Stationary burst loop — fire 3, pause, rotate 20° CW, repeat
# ---------------------------------------------------------------------------
func _do_fire(delta: float) -> void:
	velocity = Vector2.ZERO
	_shot_timer -= delta
	if _shot_timer > 0.0:
		return

	if _shot_count < BURST_SIZE:
		_fire_projectile()
		_shot_count += 1
		_shot_timer = SHOT_INTERVAL
	else:
		# Burst done — rotate 20° clockwise and reset
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
