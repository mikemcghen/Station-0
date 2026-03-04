extends Resource
class_name RunItem

enum Effect {
	STAT_MOD         = 0,   # flat stat modifier
	RICOCHET         = 1,   # projectiles bounce off walls once
	SCATTER          = 2,   # fire N projectiles in a spread
	EXPLOSIVE        = 3,   # projectiles explode on hit
	HEAL             = 4,   # immediate HP restore on pickup, no ongoing effect
	COOLANT_LEAK     = 5,   # leaves a slow zone on taking damage
	SCRAP_MAGNET     = 6,   # scrap tokens auto-attract within magnet_radius
	MEMORY_SPIKE     = 7,   # first projectile per room deals 3x damage
	RUST_COAT        = 8,   # incoming damage reduced by damage_reduction (min 1)
	STATIC_DISCHARGE = 9,   # AoE burst (discharge_radius) on taking damage
	FRAGMENTED_MAP   = 10,  # reveals one unexplored room on each combat clear
	OVERCLOCK        = 11,  # fire rate x1.4; every 3rd shot deals 0 damage
}

@export var display_name:       String = ""
@export var description:        String = ""
@export var effect:             Effect = Effect.STAT_MOD

# STAT_MOD
@export var stat_key:           String = ""     # "speed"|"max_health"|"damage"|"fire_rate"|"range"
@export var stat_delta:         float  = 0.0

# SCATTER
@export var scatter_count:      int    = 3
@export var scatter_spread_deg: float  = 20.0

# EXPLOSIVE
@export var explosion_radius:   float  = 64.0
@export var explosion_damage:   float  = 2.5

# HEAL — immediate HP restored on pickup (separate from stat_delta)
@export var heal_on_pickup:     float  = 0.0

# RUST_COAT
@export var damage_reduction:   float  = 1.0

# STATIC_DISCHARGE
@export var discharge_radius:   float  = 64.0
@export var discharge_damage:   float  = 1.0

# SCRAP_MAGNET
@export var magnet_radius:      float  = 192.0