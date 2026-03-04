extends Resource
class_name BodyPartData

@export var slot:         String = ""   # "head" | "torso" | "left_arm" | "right_arm" | "legs"
@export var display_name: String = ""

# ---------------------------------------------------------------------------
# Stat modifiers — additive bonuses stacked across all equipped parts.
# Field names mirror the stat keys used in player_stats.gd.
# ---------------------------------------------------------------------------
@export var mod_speed:      float = 0.0
@export var mod_max_health: float = 0.0
@export var mod_damage:     float = 0.0
@export var mod_fire_rate:  float = 0.0
@export var mod_range:      float = 0.0
@export var mod_proj_speed: float = 0.0   # flat delta; e.g. -104 = -20% of base 520

# ---------------------------------------------------------------------------
# Scatter (left arm slot)
# mod_scatter_count > 0 enables multi-shot spread from this part
# ---------------------------------------------------------------------------
@export var mod_scatter_count:      int   = 0
@export var mod_scatter_spread_deg: float = 0.0

# ---------------------------------------------------------------------------
# Shield Projector (left arm slot)
# Active block on cooldown — absorbs one hit per activation
# ---------------------------------------------------------------------------
@export var shield_projector: bool = false