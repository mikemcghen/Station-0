extends Area2D

# ---------------------------------------------------------------------------
# Shared enemy projectile — used by Repeater (linear) and Anchor (homing)
# ---------------------------------------------------------------------------

var direction:      Vector2  = Vector2.RIGHT
var speed:          float    = 200.0
var damage:         float    = 1.0
var max_range:      float    = 500.0

# Homing — disabled by default
var homing:         bool     = false
var homing_target:  Node2D   = null

const HOMING_STRENGTH := 2.0   # radians/second turn rate

var _distance_traveled: float = 0.0

func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if homing and homing_target != null and is_instance_valid(homing_target):
		var to_target := (homing_target.global_position - global_position).normalized()
		direction = direction.lerp(to_target, HOMING_STRENGTH * delta).normalized()
		rotation = direction.angle()

	var move := direction * speed * delta
	position += move
	_distance_traveled += move.length()
	if _distance_traveled >= max_range:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)
		queue_free()
	elif body is StaticBody2D:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.4, 0.1))
