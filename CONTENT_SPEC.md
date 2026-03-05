# Station 0 — Content Spec (Vertical Slice)

Last updated: 2026-03-05
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

## Boss: THE WARDEN *(Floor 1)*

A containment unit whose crowd-control protocol has turned inward — it is now attempting to contain the entire room, including the player. Slow and methodical. The room itself becomes the threat.

**Room**: Large. No environmental hazards on entry. Preceded by a charging station (full HP restore before entry).

### Movement
Patrols the room perimeter in a slow, continuous circuit. Never crosses the center. Fully predictable path — the danger comes from what it leaves behind, not from the boss itself.

### Attack 1 — Barrier Sweep
Fires a wall of slow projectiles horizontally across the room. One or two gaps the player must find and move through. Telegraphed by a brief charge-up flash before firing.

### Attack 2 — Mine Drop
Drops a stationary proximity mine at its current patrol position each cycle. Mines persist until cleared or end of fight. Over time the room fills with no-go zones — the safe path shrinks. Player must manage the accumulating hazard while dealing damage.

### Post-boss
- Body part drop (guaranteed).
- Floor 2 portal opens.

---

## Boss: THE RELAY *(Floor 2)*

A communications hub unit whose broadcast function corrupted into something aggressive. Erratic, unpredictable positioning. Forces the player to stay mobile and read the room constantly.

**Room**: Large. No environmental hazards on entry. Preceded by a charging station (full HP restore before entry).

### Movement
Anchors near room center but teleports to a random position every 8–10 seconds. No warning before teleport — position resets without notice. Punishes clustering near the boss.

### Attack 1 — Burst Transmission
On each teleport arrival, fires an 8-directional projectile burst. Player caught nearby takes damage before they can react. Creates a strong incentive to stay at mid-range and keep moving.

### Attack 2 — Signal Drifters
Periodically broadcasts a signal that summons 2–3 Drifters. Not full waves — just enough to split attention. Relay continues teleporting and bursting while adds are alive.

### Post-boss
- Body part drop (guaranteed).
- Floor 3 portal opens.

---

## Boss: THE HIVEMIND *(Floor 3 — Final Boss)*

What the corruption becomes when it fully realizes itself. Individual units lose their original purpose and merge into a single machine that was never meant to exist.

**Room**: Large. Largest boss room in the run. Preceded by a charging station (full HP restore before entry).

### Phase 1 — Assembly
No central target yet. Corrupted units flood the room in waves — Drifters, Repeaters, Anchors. As each one dies, it is pulled toward the center and physically joins the assembling structure (visual indicator builds up). Player must clear everything they've learned across floors 1 and 2 simultaneously, under pressure. The Hivemind core cannot be damaged during this phase.

### Phase 2 — Active
The assembled machine comes online. Attacks are recognizable — a spread shot pattern like the Repeater, a slow sweeping area attack like the Warden, drifting projectiles like the Drifter. Familiar in shape, dangerous in scale. Player knows what each attack is but they are now coming from a single powerful source at elevated intensity.

### Phase 3 — Unique
The Hivemind stops mimicking its components and expresses something none of them could do individually. Attacks to design:
- Rotating beam that forces constant movement around the room
- Room-wide pulse that pushes the player toward walls
- Tracking projectiles that home slowly but persistently

Phase 3 begins below 30% HP. Visual state change — structure begins to crack and glow.

### Post-boss
- Body part drop (guaranteed).
- Victory screen triggers. Run complete.
- All remaining run credits returned to wallet on hub return.

**Emotional intent**: The Hivemind is not a villain. It's what happens when nothing is left to maintain and the only function remaining is persistence. Killing it ends the run — but the station is still empty.

---

## Shelved: THE SUPERVISOR

Built and functional. Shelved from VS because its movement and attack profile (patrol + beam + adds) overlaps too closely with the Warden at the same tier.

Candidate uses post-VS:
- Named mini-boss variant in a sealed room
- Reintroduced as a late-floor elite enemy on higher difficulty
- Escort mission antagonist

The Supervisor's WALL-E freeze/distress moment should be preserved whenever it returns — that beat is worth keeping.

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
One boss per floor. Each preceded by a charging station room (no enemies, full HP restore). Boss rooms are the largest rooms in the run.

| Floor | Boss |
|---|---|
| Floor 1 | The Warden |
| Floor 2 | The Relay |
| Floor 3 | The Hivemind (final) |

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
| Floor 1 | 4–5 rooms + boss | Learn the rhythm. One item. Maybe find the shop. First Repeater feels like a puzzle. Warden fight — room fills with mines, learn to manage space. |
| Floor 2 | 5–6 rooms + boss | Mixed threats. Find a body part. Build takes shape. One tense near-death moment. Relay fight — erratic, keeps moving, adds split focus. |
| Floor 3 | 2–3 rooms + boss | Room composition tightens. Anchors in tighter spaces. Charging station. Hivemind — three phases, everything converges. Victory. |

**Target run time**: 20–30 minutes.

---

---

## Post-VS Enemies

---

### SUICIDE BOMBER
**Corruption type**: Self-destruct loop
**Movement**: Faster than all standard enemies. Pathfinds directly to the player.
**Attack**: On close approach, stops and begins blinking — blink frequency ramps up. Explodes on trigger. AoE damages both the player AND other enemies in range.
**Threat level**: High
**Design role**: Forces constant movement. Punishes clustering with other enemies. Rewards luring — a bomber detonating in a group of Anchors or Repeaters creates player-controlled room clearing. The ramping blink gives a readable window to escape or detonate intentionally.

---

### CHOMPER
**Corruption type**: Aggression loop
**Movement**: Frog-like dash cadence — dash toward player, brief recovery pause, dash again. Chains dashes together rather than returning to idle between them.
**Attack**: Melee bite on contact during the dash. No projectiles.
**Recovery window**: Brief stall after each dash, especially on a miss. Readable and punishable — the skill floor is dodging the dash; the skill ceiling is baiting a miss and punishing the recovery.
**Threat level**: Medium-High
**Design role**: Teaches dash-reading and dodge timing. Relentless once it starts chaining. High pressure in small rooms. Pairs well with Anchor — the Anchor pins a corner while the Chomper forces the player into it.

---

## Post-VS Body Parts

---

### HAMMER ARM *(Right Arm — damage slot)*
**Effect**: Replaces the ranged attack entirely with a charged melee swing. Hold the shoot key to charge — arm winds up while held. Release to swing in the direction of the last movement input. High damage, small AoE on impact.
**Charge behavior**: Movement speed is reduced while charging — not stopped, but noticeably slower. The player can still reposition but not freely. This makes the commit real: you close distance, start charging, and become a slower target while you do it.
**Trade-off**: High damage output and AoE but requires closing distance, committing to a charge through reduced movement, and reading your position before releasing. Full playstyle conversion — this is a melee build piece, not a modifier.
**Synergies**:
- **Arc Pulse (left arm)**: Gives the melee build a ranged utility option on cooldown — the two together define a coherent melee archetype.
- **Static Discharge**: Taking damage in melee range triggers the AoE burst — high risk, high chaos.
- **Rust Coat**: The damage floor makes surviving close-range hits more viable.
- **Coolant Leak**: Getting hit while swinging lays a slick — passive room control from a melee build.

---

### ARC PULSE *(Left Arm — utility slot)*
**Effect**: Separate active ability (not tied to primary fire input). Fires a curved, boomerang-trajectory arc shot — slow-moving, pierces through multiple enemies, covers a wide area. Long cooldown. Does not replace or interact with the primary attack unless Hammer Arm is also equipped.
**Trade-off**: No offensive change to primary fire. The arc shot is powerful and area-covering but available infrequently.
**Design role**: Standalone utility — adds ranged pressure on cooldown. Becomes the primary ranged option when paired with Hammer Arm, defining the melee archetype's attack kit.

---

## Open questions (not resolved, revisit post-VS)

- Zone-specific enemy variants — do hazard types change per zone, or stay consistent?
- Mini-boss rooms — add for post-VS (e.g., named Anchor variant + Drifters in a sealed room)?
- Lore terminal content — terminals exist in VS as placeholders; content pass comes later.
- Hydraulic Boosters — confirm in or out based on animation budget before VS build locks.
