extends CharacterBody2D

# ---------------------------------------------------------------------------
# DRIFTER — Locomotion corruption
# Moves in slow arcs and wide curves. Never charges straight. Contact only.
# ---------------------------------------------------------------------------

var max_health:      float = 16.0
var current_health:  float = 16.0
var speed:           float = 80.0
var contact_damage:  float = 1.0
var contact_cooldown: float = 0.8

var _player:        Node2D = null
var _contact_timer: float  = 0.0
var _flash_timer:   float  = 0.0
var _wobble_time:   float  = 0.0
var _wobble_phase:  float  = 0.0   # random start so groups don't sync

@onready var visual: Node2D = $Visual

func _ready() -> void:
	add_to_group("enemies")
	$ContactArea.body_entered.connect(_on_contact_entered)
	_wobble_phase = randf() * TAU

func _physics_process(delta: float) -> void:
	_find_player()
	_tick_contact(delta)
	_tick_flash(delta)
	_do_arc_chase(delta)
	move_and_slide()

func _find_player() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

# ---------------------------------------------------------------------------
# Arcing movement — sinusoidal perpendicular drift applied to toward-player dir
# ---------------------------------------------------------------------------
func _do_arc_chase(delta: float) -> void:
	if _player == null:
		velocity = Vector2.ZERO
		return
	var toward := (_player.global_position - global_position).normalized()
	var perp   := toward.rotated(PI * 0.5)
	_wobble_time += delta
	var wobble  := sin(_wobble_time * 1.8 + _wobble_phase) * 0.75
	velocity = (toward + perp * wobble).normalized() * speed

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
