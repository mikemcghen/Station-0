extends Node

# ---------------------------------------------------------------------------
# Base stats — no upgrades equipped
# ---------------------------------------------------------------------------
const BASE_SPEED       := 200.0
const BASE_MAX_HEALTH  := 6.0   # 6 HP = 3 full hearts
const BASE_DAMAGE      := 3.5
const BASE_FIRE_RATE   := 3.5   # shots per second
const BASE_RANGE       := 400.0
const BASE_PROJ_SPEED  := 520.0

# ---------------------------------------------------------------------------
# Live stats (recalculated from base + equipped parts + run items)
# ---------------------------------------------------------------------------
var speed:          float = BASE_SPEED
var max_health:     float = BASE_MAX_HEALTH
var current_health: float = BASE_MAX_HEALTH
var damage:         float = BASE_DAMAGE
var fire_rate:      float = BASE_FIRE_RATE
var range_:         float = BASE_RANGE
var proj_speed:     float = BASE_PROJ_SPEED

# ---------------------------------------------------------------------------
# Run-item behavior flags (recomputed each recalculate — never saved)
# ---------------------------------------------------------------------------
var ricochet:          bool  = false
var scatter_count:     int   = 1
var scatter_spread_deg: float = 0.0
var explosive:         bool  = false
var explosion_radius:  float = 0.0
var explosion_damage:  float = 0.0

# New item flags
var coolant_leak:     bool  = false
var scrap_magnet:     bool  = false
var memory_spike:     bool  = false
var rust_coat:        bool  = false
var static_discharge: bool  = false
var fragmented_map:   bool  = false
var overclock:        bool  = false
var damage_reduction: float = 0.0
var discharge_radius: float = 64.0
var discharge_damage: float = 1.0
var magnet_radius:    float = 0.0

# ---------------------------------------------------------------------------
# Body-part behavior flags (recomputed each recalculate)
# ---------------------------------------------------------------------------
var shield_projector: bool = false

func _ready() -> void:
	EventBus.body_part_equipped.connect(_on_part_equipped)
	recalculate()
	if RunManager.player_health_carry > 0.0:
		current_health = minf(RunManager.player_health_carry, max_health)
		RunManager.player_health_carry = -1.0

func recalculate() -> void:
	speed      = BASE_SPEED      + UpgradeManager.get_stat_modifier("speed")
	max_health = BASE_MAX_HEALTH + UpgradeManager.get_stat_modifier("max_health")
	damage     = BASE_DAMAGE     + UpgradeManager.get_stat_modifier("damage")
	fire_rate  = BASE_FIRE_RATE  + UpgradeManager.get_stat_modifier("fire_rate")
	range_     = BASE_RANGE      + UpgradeManager.get_stat_modifier("range")
	proj_speed = BASE_PROJ_SPEED + UpgradeManager.get_stat_modifier("proj_speed")
	_apply_run_items()
	_apply_part_flags()
	current_health = minf(current_health, max_health)

func _apply_run_items() -> void:
	ricochet           = false
	scatter_count      = 1
	scatter_spread_deg = 0.0
	explosive          = false
	explosion_radius   = 0.0
	explosion_damage   = 0.0
	coolant_leak       = false
	scrap_magnet       = false
	memory_spike       = false
	rust_coat          = false
	static_discharge   = false
	fragmented_map     = false
	overclock          = false
	damage_reduction   = 0.0
	discharge_radius   = 64.0
	discharge_damage   = 1.0
	magnet_radius      = 0.0

	for item: RunItem in RunManager.run_items:
		match item.effect:
			RunItem.Effect.STAT_MOD:
				match item.stat_key:
					"speed":      speed      += item.stat_delta
					"max_health": max_health += item.stat_delta
					"damage":     damage     += item.stat_delta
					"fire_rate":  fire_rate  += item.stat_delta
					"range":      range_     += item.stat_delta
			RunItem.Effect.RICOCHET:
				ricochet = true
			RunItem.Effect.SCATTER:
				scatter_count      = maxi(scatter_count, item.scatter_count)
				scatter_spread_deg = maxf(scatter_spread_deg, item.scatter_spread_deg)
			RunItem.Effect.EXPLOSIVE:
				explosive        = true
				explosion_radius = maxf(explosion_radius, item.explosion_radius)
				explosion_damage = maxf(explosion_damage, item.explosion_damage)
			RunItem.Effect.COOLANT_LEAK:
				coolant_leak = true
			RunItem.Effect.SCRAP_MAGNET:
				scrap_magnet = true
				magnet_radius = maxf(magnet_radius, item.magnet_radius)
			RunItem.Effect.MEMORY_SPIKE:
				memory_spike = true
			RunItem.Effect.RUST_COAT:
				rust_coat = true
				damage_reduction = maxf(damage_reduction, item.damage_reduction)
			RunItem.Effect.STATIC_DISCHARGE:
				static_discharge = true
				discharge_radius = maxf(discharge_radius, item.discharge_radius)
				discharge_damage = maxf(discharge_damage, item.discharge_damage)
			RunItem.Effect.FRAGMENTED_MAP:
				fragmented_map = true
			RunItem.Effect.OVERCLOCK:
				overclock = true
				fire_rate *= 1.4

func _apply_part_flags() -> void:
	shield_projector = false
	# Scatter from body parts (accumulate with run item scatter)
	for slot in UpgradeManager.SLOTS:
		var part := UpgradeManager.get_equipped_part(slot)
		if part == null:
			continue
		if part.shield_projector:
			shield_projector = true
		if part.mod_scatter_count > 0:
			scatter_count      = maxi(scatter_count, part.mod_scatter_count)
			scatter_spread_deg = maxf(scatter_spread_deg, part.mod_scatter_spread_deg)

func heal(amount: float) -> void:
	current_health = minf(current_health + amount, max_health)

func _on_part_equipped(_part: Resource, _slot: String) -> void:
	recalculate()