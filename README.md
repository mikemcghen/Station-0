# Station 0

> *You're the last robot. The others are out there. Bring them home. Then play cards and uncover what happened.*

Station 0 is a roguelike + card game hybrid built in Godot 4. You play as an amnesiac maintenance robot on the last surviving human monitoring station — orbiting a planet that humanity destroyed through neglect and then abandoned entirely. Thousands of years have passed. Most robots are corrupted. A few survive with their memories intact.

Your job is to find them.

---

## What makes this different

Most roguelikes give you a hub to return to. Station 0 gives you a reason to care about it.

**The NPC-Card-Lore triangle:**
- You find a surviving robot during a run and risk bringing them along
- If they make it back, they settle into the hub's cafeteria
- Their card deck is their personality — built from the ecological zone they were designed to monitor
- Playing cards against them is how you learn what they remember about what happened
- Their dialogue reacts to being lost, found again, and brought home

No other game does this. The card game is the relationship layer. The lore is delivered through play, not cutscenes.

---

## The two game modes

### Roguelike
BOI-style top-down combat across six ecological zones of the station (Botanical, Aquatic, Atmospheric, Mineral, Arctic, Volcanic) plus rare Data floors. The player robot has a modular body — five equipment slots (Head, Torso, Left Arm, Right Arm, Legs) that accept maintenance tool attachments found throughout the station. Permanent upgrades survive death. Everything else is a live bet on your own survival.

Key mechanic: **early exit**. At any point in a run, the player can abandon and return to the hub, keeping everything found so far. The risk/reward tension is active the entire run, not just at the start.

### Card Game
A deck-based TCG with auto-battler combat resolution, played in the hub cafeteria against rescued NPC robots. No in-match shop — the strategic layer lives in deck construction and hand management. Cards represent species that once lived on the planet. Each zone has its own card series. The robots who built these cards were grieving. The player inherits that grief without knowing it.

---

## Emotional foundation

The narrative structure is WALL-E: no villain, no attack, just the slow weight of what happens when something loved is taken for granted until it's too late. The station was built not in triumph but in guilt — a vigil. The creatures on the cards are beautiful and clearly once-living. Players feel the loss before they read a word of lore.

The surviving robots have intact memory cards. They remember everything. They've had thousands of years to process it alone. Each one has a different relationship to what happened. Bringing them home — and playing cards with them — is how the player assembles the picture.

---

## Current status

Active development. Vertical slice in progress (Godot 4 / GDScript).

**Built:**
- Player movement, combat, iframes, death loop
- Modular body part system with stat modifiers
- Procedural floor generation (random walk + BFS boss placement)
- Room system with door locking, enemy spawning, floor transitions
- Run manager (death vs. early exit correctly split)
- Hub world foundation
- Save system (body parts, credits, NPC states, lore — all persistent)
- HUD (procedurally drawn hearts, credit counter)
- EventBus signal architecture

**In progress:**
- Enemy variants (Drifter, Repeater, Anchor — distinct corrupted behaviors)
- The Supervisor boss (multi-phase encounter)
- Run item system (8 items with synergies)
- Environmental hazards
- Hub staging area and deposit machine

---

## Design documentation

Full design documentation is in this repository:

- [ARCHITECTURE.md](ARCHITECTURE.md) — complete systems and technical design
- [DESIGN_NOTES.md](DESIGN_NOTES.md) — tone, differentiation, emotional vision
- [CONTENT_SPEC.md](CONTENT_SPEC.md) — enemies, boss, items, body parts, room content
- [PRODUCTION_NOTES.md](PRODUCTION_NOTES.md) — team structure and funding paths

---

## Engine

**Godot 4** — GDScript
No third-party dependencies. Scene-based architecture maps cleanly to the room/run/hub structure.

---

## Contact

Solo developer. United States.
Grant inquiries and collaboration: [add contact]
