extends CharacterBody2D

# ---------------------------------------------------------------------------
# Stats — override in derived enemy types
# ---------------------------------------------------------------------------
var max_health:       float = 10.0
var current_health:   float = 10.0
var speed:            float = 60.0
var contact_damage:   float = 1.0
var contact_cooldown: float = 0.8

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------
var _contact_timer: float = 0.0
var _flash_timer:   float = 0.0
var _player: Node2D = null

@onready var visual: Node2D = $Visual

func _ready() -> void:
	add_to_group("enemies")
	$ContactArea.body_entered.connect(_on_contact_entered)

func _physics_process(delta: float) -> void:
	_contact_timer = maxf(_contact_timer - delta, 0.0)
	_tick_flash(delta)
	_chase_player()
	move_and_slide()

# ---------------------------------------------------------------------------
# AI — simple chaser
# ---------------------------------------------------------------------------
func _chase_player() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player != null:
		velocity = (_player.global_position - global_position).normalized() * speed
	else:
		velocity = Vector2.ZERO

# ---------------------------------------------------------------------------
# Damage / death
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Contact damage
# ---------------------------------------------------------------------------
func _on_contact_entered(body: Node) -> void:
	if body.is_in_group("player") and _contact_timer == 0.0:
		body.take_damage(contact_damage)
		_contact_timer = contact_cooldown

# ---------------------------------------------------------------------------
# Hit flash
# ---------------------------------------------------------------------------
func _tick_flash(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		visual.modulate = Color(2.5, 2.5, 2.5)
	else:
		visual.modulate = Color(1.0, 1.0, 1.0)
