extends Node

# ---------------------------------------------------------------------------
# Player / Run lifecycle
# ---------------------------------------------------------------------------
signal player_died
signal player_health_changed(current: float, maximum: float)
signal run_started
signal run_ended(reached_hub: bool)
signal floor_cleared(floor_number: int)

# ---------------------------------------------------------------------------
# Rooms
# ---------------------------------------------------------------------------
signal room_entered(room_id: String)
signal room_cleared(room_id: String)

# ---------------------------------------------------------------------------
# Items & Loot
# ---------------------------------------------------------------------------
signal item_collected(item: Resource)
signal card_pack_found(pack: Resource)
signal body_part_found(part: Resource)
signal body_part_equipped(part: Resource, slot: String)
signal credits_changed(new_total: int)

# ---------------------------------------------------------------------------
# NPCs
# ---------------------------------------------------------------------------
signal npc_found(npc: Resource)
signal npc_saved(npc: Resource)
signal npc_lost(npc: Resource)

# ---------------------------------------------------------------------------
# Lore
# ---------------------------------------------------------------------------
signal lore_discovered(lore_id: String)

# ---------------------------------------------------------------------------
# Card Game
# ---------------------------------------------------------------------------
signal card_game_started(opponent: Resource)
signal card_game_ended(player_won: bool)

# ---------------------------------------------------------------------------
# Boss
# ---------------------------------------------------------------------------
signal boss_health_changed(current: float, maximum: float)
signal boss_died

# ---------------------------------------------------------------------------
# Perspective / View
# ---------------------------------------------------------------------------
signal view_switching_to_topdown
signal view_switching_to_isometric
signal view_switching_to_3d(scene_path: String)
signal view_switching_to_2d
