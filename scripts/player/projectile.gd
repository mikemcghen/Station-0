extends Area2D

# Set by player on spawn
var direction:        Vector2 = Vector2.RIGHT
var damage:           float   = 3.5
var speed:            float   = 520.0
var max_range:        float   = 400.0

# Behavior flags (set from player stats)
var ricochet:         bool    = false
var explosive:        bool    = false
var explosion_radius: float   = 64.0
var explosion_damage: float   = 2.5

var _distance_traveled: float = 0.0
var _bounces_left:      int   = 1
var _bounce_cooldown:   float = 0.0   # grace period after bounce to avoid re-trigger

func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_bounce_cooldown = maxf(_bounce_cooldown - delta, 0.0)
	if ricochet and _bounces_left > 0 and _bounce_cooldown == 0.0:
		_check_wall_bounce(delta)
	var move := direction * speed * delta
	position += move
	_distance_traveled += move.length()
	if _distance_traveled >= max_range:
		queue_free()

# ---------------------------------------------------------------------------
# Ricochet — raycast lookahead to get wall normal before physically touching
# ---------------------------------------------------------------------------
func _check_wall_bounce(delta: float) -> void:
	var space  := get_world_2d().direct_space_state
	var reach  := speed * delta + 6.0
	var params := PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direction * reach,
		1   # collision_mask: walls on layer 1
	)
	var result := space.intersect_ray(params)
	if result and result["collider"] is StaticBody2D:
		direction      = direction.bounce(result["normal"])
		rotation       = direction.angle()
		_bounces_left -= 1
		_bounce_cooldown = 0.1

# ---------------------------------------------------------------------------
# Placeholder visual — yellow circle
# ---------------------------------------------------------------------------
func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.85, 0.2))

# ---------------------------------------------------------------------------
# Collision — differentiate walls from enemies
# ---------------------------------------------------------------------------
func _on_body_entered(body: Node) -> void:
	if body is StaticBody2D:
		# Wall hit — ignore during bounce cooldown (already reflected by raycast)
		if _bounce_cooldown > 0.0:
			return
		if not ricochet or _bounces_left <= 0:
			queue_free()
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)
		if explosive:
			_explode()
		queue_free()

# ---------------------------------------------------------------------------
# Explosive — AoE damage to all enemies in radius
# ---------------------------------------------------------------------------
func _explode() -> void:
	var space  := get_world_2d().direct_space_state
	var query  := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius   = explosion_radius
	query.shape     = circle
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 1
	for r in space.intersect_shape(query):
		var c = r["collider"]
		if c.has_method("take_damage"):
			c.take_damage(explosion_damage)
