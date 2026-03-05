extends EnemyBase

# ---------------------------------------------------------------------------
# DRIFTER — Locomotion corruption
# Moves in slow arcs and wide curves. Never charges straight. Contact only.
# ---------------------------------------------------------------------------

var _wobble_time:  float = 0.0
var _wobble_phase: float = 0.0   # random start so groups don't sync

func _ready() -> void:
	max_health     = 24.0
	current_health = 24.0
	speed          = 100.0
	contact_damage = 1.0
	super._ready()
	_wobble_phase = randf() * TAU

func _physics_process(delta: float) -> void:
	_find_player()
	_tick_contact(delta)
	_tick_flash(delta)
	_tick_slow(delta)
	_do_arc_chase(delta)
	velocity *= _slow_factor
	move_and_slide()

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