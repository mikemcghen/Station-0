# Station 0 — Content Spec (Vertical Slice)

Last updated: 2026-03-03
Scope: Vertical slice only. All content here is confirmed for VS unless marked **[OPTIONAL]**.

---

## Enemies

All enemies are corrupted Adaptive Maintenance Units — same chassis class as the player, visually degraded. Their corruption manifests in their function, not their form.

---

### DRIFTER
**Corruption type**: Locomotion
**Movement**: Pathfinding broken. Moves in slow arcs and wide curves. Never charges in a straight line.
**Attack**: Contact damage only. No projectiles.
**Threat level**: Low-Medium
**Design role**: Individually harmless. Disruptive in groups — fills the room with unpredictable bodies, cuts off escape routes. Forces players to unlearn "dodge in a straight line" habits.

---

### REPEATER
**Corruption type**: Task-loop
**Movement**: Slow. Drifts toward last known player position, stops, then executes its loop.
**Attack**: Fires a burst of 3 projectiles in a fixed direction, rotates ~20° clockwise, fires again, repeats indefinitely. Does not track the player — it is completing a stuck subroutine.
**Threat level**: Medium
**Design role**: Pattern recognition. First enemy that teaches players to observe before moving. Dangerous in confined rooms or when combined with other threats.

---

### ANCHOR
**Corruption type**: Structural integrity
**Movement**: Pathfinds to the nearest wall or corner and locks in. Does not move once anchored.
**Knockback**: Immune to knockback while anchored.
**Attack**: Fires slow homing projectiles at the player until destroyed. Projectiles are individually easy to outrun but accumulate.
**Threat level**: High
**Design role**: Changes room geometry. Turns safe corners into bad positions. Forces aggressive play. Punishes passivity.

---

## Boss: THE SUPERVISOR

A larger maintenance unit whose supervisor protocol has fully overridden all other functions. It does not perceive the player as an enemy — it perceives them as a malfunctioning unit and is attempting to decommission them.

**Room**: Large. No environmental hazards. Preceded by a charging station in the hallway (full HP restore before entry).

### Phase 1 (100%–55% HP)
- Patrols a fixed rectangular path around the room.
- When the player enters a forward sensor cone, fires a sweeping calibration beam (slow AoE line that leaves a brief floor hazard — clears within ~1 second, nothing lingering).
- Freely damageable from behind and sides.
- No adds. Room feels almost too easy — players get overconfident.

### Phase 2 (55%–20% HP)
- Patrol pattern collapses. Supervisor begins tracking the player directly.
- Moves faster. Calibration beam fires more frequently at tighter arcs.
- Spawns one Drifter from a maintenance hatch.
- Visual state change: one arm hanging, sparking.

### Climax (below 20% HP)
- Supervisor freezes mid-room. Broadcasts a distress signal (visual + audio cue).
- Frozen for ~2 seconds. Not invulnerable — can be killed during the freeze.
- No lore triggered on death.
- On death: guaranteed body part drop, then powers down.

**Emotional intent**: The freeze is not a mechanic — it's a beat. Players will kill it without thinking, then maybe feel it a second later. WALL-E tone.

### Post-boss
- Body part drop (guaranteed).
- Explicit early exit prompt offered.
- Hub door opens.

---

## Run Items

8 items for VS. Populate item rooms and shops. BOI-style: diverse effects, some synergies, not just stat buffs.

| Item | Effect |
|---|---|
| **Coolant Leak** | Leaves a slick trail for 1s when you take damage. Enemies that touch it are slowed for 2s. |
| **Overclock Module** | Fire rate +40%. Every 3rd shot deals 0 damage. |
| **Scrap Magnet** | Scrap tokens auto-collect within 3 tiles. |
| **Memory Spike** | First projectile fired in each room deals 3× damage. |
| **Rust Coat** | Reduce all incoming damage by 1 (min 1). |
| **Static Discharge** | On taking damage, emit a short-range AoE burst (1 tile radius). |
| **Fragmented Map** | Each time you clear a combat room, one unexplored room on the floor map is revealed. |
| **Patch Kit** | Consumed on pickup: restore 2 HP immediately. |

### Synergies worth noting
- **Coolant Leak + Static Discharge**: Taking damage becomes room control.
- **Memory Spike + Overclock Module**: Active tension — sacrificing your free first shot on dead 3rd shots.
- **Rust Coat + Lightweight Frame** (body part): Glass cannon with a floor on incoming damage.

---

## Body Parts

8 non-default upgrades across 4 active slots for VS. All slots have a default (baseline, no stat change) that is never listed as a pickup.

Trade-offs are required — no pure upgrades.

### HEAD
| Part | Effect |
|---|---|
| **Wide-Angle Lens** | Vision radius +30%. Projectile speed -20%. |
| **Targeting Spike** | Projectile speed +40%, range +25%. Field of view -20%. |

### TORSO
| Part | Effect |
|---|---|
| **Reinforced Chassis** | Max HP +2. Move speed -10%. |
| **Lightweight Frame** | Move speed +20%. Max HP -1. |

### LEFT ARM (utility/shield slot)
| Part | Effect |
|---|---|
| **Scatter Emitter** | Fires 3-way spread instead of single shot. Each projectile deals 60% damage. |
| **Shield Projector** | Active block on cooldown (3s): absorbs one hit. No offensive change. |

### RIGHT ARM (damage slot)
| Part | Effect |
|---|---|
| **Heavy Emitter** | Damage +60%. Fire rate -40%. |
| **Rapid Emitter** | Fire rate +50%. Damage -30%. |

### LEGS **[OPTIONAL — include if bandwidth allows]**
| Part | Effect |
|---|---|
| **Hydraulic Boosters** | Move speed +15%. Deceleration takes longer. Brief i-frames on dash through enemies. |

---

## Room Content Spec

### Room types

**Combat rooms**
Doors lock on entry. Unlock when all enemies are defeated.

| Floor depth | Enemy count | Composition |
|---|---|---|
| Floor 1, rooms 1–3 | 1–2 | Drifters only |
| Floor 1, rooms 4+ | 2–3 | Drifters + 1 Repeater |
| Floor 2 | 2–4 | Mix of all three types |
| Floor 3 (pre-boss) | 2–3 | Include Anchor; rooms tighter |

Enemy count capped by room size — small rooms get -1 enemy.

**Item rooms**
One item on a pedestal. No enemies. Safe. 20% chance to also contain a lore terminal (not wired to any lore content for VS — terminal present, content placeholder).

**Shop rooms**
Unmanned. No NPC keeper. Sells 2 items + 1 consumable at fixed scrap prices. No haggling. Purely transactional — all NPC personality lives in the hub.

**Boss room**
See Boss section above.

---

### Environmental Hazards

Both hazard types included in VS.

**Oil slick**
- Slippery surface. Reduces player movement control (momentum-based sliding).
- Enemies unaffected.
- Appears as puddles in combat rooms.

**Exposed wiring**
- Deals 1 HP on contact.
- Blocks movement paths — functions as impassable terrain with a damage border.
- Appears as sparking floor sections along walls.

---

### Run arc (VS target)

| Floor | Room count | Beat |
|---|---|---|
| Floor 1 | 4–5 rooms | Learn the rhythm. One item. Maybe find the shop. First Repeater feels like a puzzle. |
| Floor 2 | 5–6 rooms | Mixed threats. Find a body part. Build takes shape. One tense near-death moment. |
| Floor 3 | 2 rooms + boss | Charging station. Supervisor fight. The freeze. Kill it. Hub door opens. |

**Target run time**: 20–30 minutes.

---

## Open questions (not resolved, revisit post-VS)

- Zone-specific enemy variants — do hazard types change per zone, or stay consistent?
- Mini-boss rooms — add for post-VS (e.g., named Anchor variant + Drifters in a sealed room)?
- Lore terminal content — terminals exist in VS as placeholders; content pass comes later.
- Hydraulic Boosters — confirm in or out based on animation budget before VS build locks.
