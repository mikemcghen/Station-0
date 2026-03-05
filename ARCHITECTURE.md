# Game Architecture Plan
*Working title: Station 0 — roguelike + card game hybrid*

---

## Concept Summary
You play as a robot aboard the last surviving human monitoring station, orbiting a planet that humanity once inhabited. Thousands of years after humanity's extinction — caused by their own damage to the planet — most robots have become corrupted. You survive, but with significant memory card corruption: you have your functions but not your history. Each run takes you deeper into the station. Permanent body part upgrades are truly permanent — never lost on death. A full card game (auto-battler format with hybrid card types) runs as a standalone minigame in the hub's cafeteria, played against other surviving robots you rescue and bring back. The hub world IS the main menu — no traditional start screen.

---

## Narrative Foundation

**Setting:** A space station built by humanity to monitor the vital signs of a planet they inhabited and ultimately destroyed. The station was the first of its kind, and is now the last surviving one. Humans worked alongside their robots here — the last joint effort before humanity disappeared entirely.

**Timeframe:** Thousands of years have passed since humanity went extinct. The station has been running in degraded state for so long that most robots are corrupted beyond recovery. A handful remain functional with their memory cards intact.

**The Player:** A surviving robot with partial memory card corruption. Not hostile — just amnesiac. They have their physical functions and basic operational knowledge, but their history and context are gone. This is the player's natural state for learning the world alongside the player.

**The Mystery:** The player uncovers what happened to the planet and to humanity through: data floor lore cards (fragmented archival records), NPC robots with intact memories, and card flavor text across all series. The answer is WALL-E in emotional structure — humans damaged what they loved until it couldn't recover — but expressed through the lens of fantastical alien ecology and robot grief.

**The Secret Creature — Late-Game Narrative Arc**
Deep in the station, in an area the player eventually discovers, is a living creature from the old world. Humanity was conducting classified research on it — the data was never released, never archived, never shared with the monitoring robots. No NPC has ever seen it. No card exists for it. The Rogue Robot Compendium has no entry. It is completely unknown — to everyone except the shopkeeper, who heard things through the counter over thousands of years and may hint at it in their lore drops before the player ever finds it.

The interaction is non-verbal. The player cannot fight it, cannot speak to it. The goal is to understand what it needs and help it reach a state of happiness — through observation, environment, and action. The specific mechanic is TBD (the creature design is undecided). The emotional logic: the player has spent the entire game learning about extinct life through cards and data. This is the first time they encounter something still alive.

On completion of the arc, the creature comes to live in the hub. It joins the community of survivors — robots who remember, a shopkeeper who observed, and now one living thing from the world they've all been mourning.

The player receives a **1/1 card** of the creature — the only one in existence, made by the player after the interaction. Whether to use it in a deck is entirely the player's choice. It is mechanically valid but emotionally weighted. Its flavor text is written by the player's robot, not from archival data — the first card ever created from a living encounter rather than a memory.

**The Card Game (in-universe):** After humanity ended, the surviving robots developed an affinity for the life forms recorded in the station's archives. They used the data humans collected to create trading cards representing the species that lived on the planet — a game born from grief and preservation instinct. Each station zone has its own card series tied to the ecological region it monitored.

---

## Engine
**Godot 4** — GDScript
- Handles 2D (top-down/isometric) and 3D natively in one project
- Built-in networking for online card game
- Scene-based architecture maps cleanly to room/run/hub structure

---

## Project Folder Structure

```
/project
  /scenes
    /hub/             — Hub world (multi-room, abandoned station feel)
      /control_room/
      /armory/
      /cafeteria/     — Card game played here
      /shop/
      /trophy_room/
      /staging_area/  — Upgrades + entrance to station
    /run/             — Dungeon run scenes
      /rooms/         — Room types (combat, item, shop, boss, secret, card_pack, lore, npc)
      /floors/        — Floor-level containers
    /card_game/       — Card game minigame
    /ui/              — Shared UI (HUD, minimap, menus, lore viewer)
    /player/          — Player scene + modular body parts
    /enemies/         — Enemy scenes
    /npcs/            — Companion NPC scenes
    /effects/         — Visual effects, transitions
    /3d_moments/      — 3D challenge/puzzle/fight scenes

  /scripts
    /player/
    /enemies/
    /npcs/
    /rooms/
    /cards/
    /upgrades/
    /network/
    /save/
    /lore/

  /resources
    /items/           — RunItem resources
    /cards/           — Card resources
    /upgrades/        — BodyPart resources
    /enemies/         — EnemyDefinition resources
    /npcs/            — NPCDefinition resources
    /lore/            — LoreTape resources
    /cosmetics/       — Cosmetic resources

  /assets
    /sprites/
    /audio/
    /shaders/
    /fonts/
```

---

## Singletons (Autoloads)

| Singleton | Responsibility |
|-----------|---------------|
| `GameManager` | Global state, scene transitions, session flow |
| `RunManager` | Active run state (floor, room, items/NPCs this run) |
| `SaveManager` | Read/write persistent data to disk |
| `UpgradeManager` | Tracks equipped body parts and all previously acquired ones |
| `CardCollection` | Player's full card collection and decks |
| `NPCManager` | Tracks all NPC states (in hub, on run with player, lost) |
| `LoreManager` | Tracks discovered lore tapes, syncs to player's "cloud" |
| `EventBus` | Decoupled signal hub — all cross-system events |
| `NetworkManager` | Multiplayer connection, matchmaking (Phase 9) |

---

## Core Systems

### 1. Player System

**Robot Designation: Adaptive Maintenance Unit**

The player is an adaptive maintenance robot — a class designed specifically to swap tool components in and out for different repair and monitoring tasks. This is diegetically why the modular body part system exists: it's not a gameplay abstraction, it's what the robot was built to do.

This also means the majority of corrupted enemies the player encounters are the same model — other maintenance units that have degraded beyond recovery. The player is fighting what they could become. The modular body part system works both ways: enemy maintenance robots visually reflect their degraded state through their parts, and the player can read a corrupted robot's loadout the same way they read their own.

Body parts found in the station are maintenance tool attachments that have been sitting dormant for thousands of years. Finding and equipping them is the player doing their job.

**Modular Robot Body**
- 5 equipment slots: `Head`, `Torso`, `LeftArm`, `RightArm`, `Legs`
- Each slot is a child Node2D with a Sprite2D — swapping a part changes the sprite
- `BodyPart` resource defines: slot, sprite(s), stat modifiers, optional special ability
- Default "base maintenance chassis" parts equipped at game start — worn, functional, generic

**Player Stats (calculated dynamically)**
```
base_stats + sum(equipped_part_modifiers) + sum(run_item_modifiers)
```
- Health, Speed, MoveControl, Damage, FireRate, Range, Luck

**Combat system** — BOI-style; large variety of items that modify combat in diverse ways.
Developed fully in Phase 6 once core loop exists.

---

### 2. Death & Persistence

**On death, you LOSE:**
- Any run items found during that run
- Any card packs found during that run
- Any scrap tokens — both those found in the run AND any you brought from the hub
- Any buff items you brought into the run
- Any NPCs who were on an escort run with you (they get "lost" — must be found again in future runs)

**On death, you KEEP:**
- All permanent body part upgrades (always — no exceptions)
- All lore discovered (tapes synced to archive, never lost)
- Everything in the hub: card collection, cosmetics, hub token balance, NPCs who stayed behind

**Early exit — the alternative to death:**
At any point during a run, the player can choose to exit early and return to the hub. On early exit, you keep everything you found during the run — items, card packs, tokens — exactly as if you had completed it successfully. You simply don't get whatever was deeper in. This is a meaningful strategic choice, not a fallback.

**Player agency:** Before a run, the player decides: which NPCs to bring (risk losing them on escort runs), how many tokens to withdraw from the hub bank (lost on death, spent in run shops/vending machines), and which buff items to carry in. The early exit option means the decision space continues throughout the run, not just at the start.

**Implication:** The risk/reward tension is active the entire time you're in a run. Body parts are true permanent progression. Everything else is a live bet on your own survival.

---

### 3. NPC / Companion System

This is a major system that ties the run, hub, card game, and lore together.

**NPC States:**
```
undiscovered → found (in run) → saved (in hub) → lost (died on a run with player)
           ↑_______________________________________↓
```

**During runs:**
- NPCs are found in specific room types or hidden areas
- Player can choose to bring them along on the run
- They provide passive buffs or active abilities during the run
- If the player dies with them, they are "lost" — their hub slot becomes empty and they must be found again (may appear in a different location next time)

**In the hub (cafeteria):**
- Saved NPCs become card game opponents
- Each has their own deck and difficulty
- They also deliver lore through dialogue

**NPC classes and abilities**
NPCs have their own fixed class and abilities — the player cannot modify them. Each NPC's class reflects their original station job and zone. Their combat ability (when they join on escort runs) and their card deck are expressions of who they were built to be, not something the player customizes.

**NPC development progression**
Each NPC has a development track that advances through interactions: card matches played against them, dialogue conversations, and quests completed. Development gates what the NPC will offer the player over time:

1. **Early (newly saved):** Settles into the hub. Basic dialogue. Will play card matches.
2. **Developing:** Opens up lore. Gives fetch quests (player goes solo, retrieves something from a run).
3. **Trusted:** Offers escort quests — the NPC joins the player on a run to reach a specific location.
4. **Established:** Deeper lore unlocks. May offer new card series, unlock new hub areas, or open permanent new options.

**Quest types**
- **Fetch quests:** NPC stays in the hub. Player retrieves a specific item or reaches a specific location in a run. Reward: lore, new cards, advancement on NPC development track.
- **Escort quests:** NPC joins the player on a run as a companion. Player must reach a destination with the NPC alive. Reward: unlocks new cards, new areas of the hub, or major lore reveals. High risk — if the player or NPC dies, the NPC is lost.

**Lost state during escort quests**
If the player dies OR the NPC is defeated during an escort run, the NPC enters the "lost" state:
- Their hub slot becomes empty
- They are re-seeded into future runs (different floor, possibly different location than originally found)
- When found again: all their data persists — same deck, same lore, same development progress, same dialogue memory
- The NPC remembers what happened. Their dialogue reflects it.

**The Compass — consumable item**
A rare run item. When used, it activates a homing signal that allows a lost NPC to navigate back to the hub on their own — without the player needing to escort them again. Consumed on use. Finding one feels meaningful because its value is entirely social: it's not a combat item, it's a rescue tool.

**NPC persistence:**
- `NPCManager` tracks: name, state, hub location, deck, lore lines, development stage, quest state
- "Lost" NPCs are re-seeded into runs (not necessarily same floor or location)
- All NPC data persists through lost state — nothing resets on being lost and found again

---

### 4. Hub World

A multi-room physical space. Feels like an abandoned station — dark, dusty, only partially functional. The player navigates between rooms on foot.

**Hub layout — 7 rooms**
```
[ Control   ][    (empty)  ][   (empty)   ]
[ Armory    ][   Staging   ][    Shop     ]
[ Practice  ][  Cafeteria  ][ Trophy Room ]
```
Grid coordinates (col, row): Control=(-1,-1), Armory=(-1,0), Staging=(0,0), Shop=(1,0), Practice=(-1,1), Cafeteria=(0,1), Trophy=(1,1).
Run entrance is on the **top wall** of the Staging Area (no room above it — door leads directly to run).

| Room | Purpose |
|------|---------|
| **Staging Area** | Run entrance (top wall). ATM deposit machine. Talk to NPCs before a run. |
| **Cafeteria** | Card game tables. Rescued NPC robots sit here and can be challenged. |
| **Armory / Storage** | Equip body parts, browse acquired parts. Card storage and (later) consumable storage. Combined inventory hub. |
| **Shop** | Buy cosmetics, card packs, curated items. **Locked until shopkeeper NPC is rescued.** Before rescue: doors open, lights off, "NO KEEPER" sign, nothing to buy. |
| **Control Room** | Lore terminals, station status overview, Rogue Robot Compendium terminal. |
| **Trophy Room** | Collectibles and cosmetics unlocked during runs. Card Compendium terminal. |
| **Practice Room** | Spawn enemies from your Enemy Compendium to practice their attack patterns. Empty until at least one enemy type has been killed. |

**Shopkeeper NPC**
The shopkeeper is a found NPC — discovered in a run and rescued like any other robot. They are not present at game start.
- Before rescue: shop room is physically accessible but non-functional. Rundown aesthetic, "NO KEEPER" sign visible.
- After rescue: shopkeeper moves in, shop becomes fully functional.
- Shop upgrades by bringing the shopkeeper on escort runs — standard escort risk applies (shopkeeper can be lost if the run goes badly).
- The shopkeeper plays the card game. Their deck is commerce/trade-themed — quirky, mechanically clever, reflects that they've spent thousands of years studying the cards as items to sell rather than as creatures to appreciate. They exploit game mechanics in ways other NPCs don't. High skill ceiling opponent.
- **Lore profile: wide but shallow.** The shopkeeper has been stationary for thousands of years running the shop — every robot in the station passed through at some point. They've overheard things, noticed what people were buying before they disappeared, watched the station decline from behind a counter. Their lore drops are ambient and observational: fragments, rumors, second-hand accounts. Interesting and often surprising, but never deep — they were never out there. They know a lot about what happened to everyone else without fully understanding what any of it meant.

**Practice Room — Rogue Robot Compendium integration + Repair**
The practice room pulls directly from the Rogue Robot Compendium. When the player kills an enemy, that type's entry populates in the Compendium (lore + original designation). That same entry makes the enemy type available to spawn in the practice room. One system, two outputs: narrative log and freeform training. No door locking, no stakes — player can exit any time.

The practice room requires repair to reach full functionality:
- **Base repair item** — found in the early game world (not a drop, a placed item). Repairing with it unlocks standard enemy simulation (Drifters, Repeaters, Anchors, and any non-boss enemies unlocked in the Compendium).
- **Boss simulation components** — each boss has its own simulation component. Chance drop after the *first* time the player defeats that boss. Finding and installing it unlocks simulation for that specific boss. New players face bosses without practice first — the mechanic rewards experience, not preparation.

**| Rogue Robot Compendium** | Terminal (Control Room). Narrative log of every corrupted robot encountered — original designation, zone assignment, what happened to them. |
**| Card Compendium** | Terminal (Trophy Room). Every card ever seen or acquired, organized by zone series. Includes flavor text and artwork. |

The hub evolves as the player progresses:
- More lore terminals light up
- NPCs populate the cafeteria
- Trophy room fills in
- Shop unlocks when shopkeeper is rescued
- Practice room populates as enemy types are encountered
- Certain rooms may unlock new areas as story progresses

---

### 5. Economy — Scrap Tokens

**Single unified currency.** Scrap tokens move freely between runs and the hub — there is no split currency. The same token you find in a run is the one you spend in the hub shop, and vice versa. This creates meaningful choices at every level of play.

Visually: old machine-stamped transit tokens — brass, worn, inscribed. Remnants of the station's original infrastructure repurposed by the surviving robots as an informal economy.

**Earning tokens**
- **In runs:** dropped by enemies, found in rooms, found in destructible objects
- **In the hub:** NPC quest rewards (fetch and escort completion), card match wins against NPCs

**Spending tokens**
- **In runs:** vending machines and run shops (see below)
- **In the hub:** hub shop (cosmetics, card packs, curated permanent items)

**The Hub Deposit Machine**
A physical terminal in the hub — the station's original resource dispensary, repurposed as a token bank. Visually distinct and always in the same location. Mechanics:
- Deposit tokens when returning from a run (or any time in the hub)
- Withdraw any amount freely before or during your time in the hub — no penalty, no bombing required
- Your total token balance is always visible on the machine

This is the connective tissue of the economy. Tokens you earn anywhere feed into the same pool. The machine makes that tangible.

**Taking tokens into runs**
Before entering a run, the player can withdraw tokens from the machine to bring with them:
- Useful if there's a specific shop item they're saving for, or if they want to buy multiple card packs
- Tokens brought into a run are lost on death — this is a deliberate risk/reward choice
- The player always knows their hub balance before deciding how much to risk

**Early run exit**
The player can choose to abandon a run at any point and return to the hub, keeping:
- All tokens collected during the run
- All items and card packs found during the run (same as a successful run completion)
- Any body parts found (permanent — always kept)

This creates a push-your-luck layer: every moment in a run is a live decision between cashing out now or pushing deeper. A player who has found great loot and a lot of tokens has real incentive to exit early. A player who has found nothing has incentive to push further.

**In-run economy — two tiers**

| Type | Location | Quality | Stock | Purpose |
|---|---|---|---|---|
| **Vending machines** | Scattered throughout floors | Lower quality, random | Large, randomized per machine | Impulse buys, consumables, zone card pulls |
| **Run shops** | Dedicated shop rooms (guaranteed per floor) | Higher quality, curated | Limited (3–5 items), refreshes rarely | Planned purchases, rare items, card packs |

*Vending machines:* Old dispensary units, still partially functional. Stock is randomized per machine per run — some may be broken, some have zone-specific or unusual inventory. Cheap, disposable, accessible.

*Run shops:* Automated retail rooms. No NPC present — just a terminal and a small curated selection. Higher cost, higher quality. Similar in feel to BOI shops, but with the station's aesthetic: terminal interface, items behind glass panels, purchased via token input.

**Token flow summary**
```
Hub bank ←→ Run (bring tokens in, bring tokens back if you survive or exit early)
Run drops → Hub bank (deposited on return)
Hub activities (card matches, NPC quests) → Hub bank
Hub bank → Hub shop (spend on cosmetics, packs, etc.)
```

---

### 6. Run System

**Visual perspective — three modes**
- **Primary: top-down 2D** — the default for most rooms and floors
- **Secondary: isometric 2D** — specific rooms use isometric perspective for visual depth and theming; transitions between top-down and isometric rooms are handled per-room at the scene level
- **Tertiary: 3D** — challenge rooms and full floor replacements (see Section 7)

All three can exist in a single run. The game never commits to only one look.

**Level generation — hybrid BOI + Spelunky style**
- Grid-based room layout (like BOI)
- Rooms have procedurally generated content within them (like Spelunky)
- Each floor generates fresh every run — fully random
- Guaranteed room types per floor: at least 1 item room, 1 shop, 1 boss room
- Special rooms (lore, NPC, card pack, secret) placed by weighted RNG
- Isometric rooms are flagged as a room variant — any room type can be isometric

**Floor structure — Station Zones**

Each zone is a distinct section of the station with its own ecological monitoring assignment. The zone determines: enemy type, environmental aesthetic, NPC robot personality/job, and card series found there.

| Zone | Station Role | Creature Theme | Card Series |
|---|---|---|---|
| **Botanical** | Tracked surface flora and terrestrial ecosystems | Earth, plant, and land creatures | Verdant Series |
| **Aquatic** | Deep-water and ocean system monitoring | Ocean, river, deep-sea creatures | Tidal Series |
| **Atmospheric** | Sky, weather, and aerial ecosystem monitoring | Sky, wind, and aerial creatures | Aether Series |
| **Mineral** | Geological activity and subterranean monitoring | Rock, crystal, and cave creatures | Stratum Series |
| **Arctic** | Polar region and ice ecosystem monitoring | Ice, tundra, and cold-climate creatures | Frost Series |
| **Volcanic** | Thermal vent and magma zone monitoring | Fire, heat, and deep-earth creatures | Ember Series |
| **Data** | Archival and records systems | All series (weighted random) + Legendary fragments | Archive Series (fragments) |

**Data Floors** are rare and special:
- Access weighted random cards from ALL zone series
- Contain fragmented Archive cards — pieces of lore explaining what happened to the planet and humanity
- Feature stronger/legendary species not found in standard zone packs
- May contain terminals with deeper lore than standard rooms
- No NPC trainer is assigned to Data floors — they are discovery floors, not social ones

**Zone floor order — randomized with spawning rules**

Zones do not follow a fixed linear progression. Which zone appears next is determined by weighted RNG, making each run feel like exploring a different section of the station. The station's zones are not stacked floors — they're different wings and departments, and the player is navigating between them.

Confirmed rules:
- Zone order is random per run
- No two identical zones back-to-back
- Data floors cannot appear on the first floor of a run
- Data floors become more likely the deeper the run goes

Spawning rules TBD (to be determined through playtesting):
- Whether certain zones are weighted toward earlier or later floors
- Whether there are zone adjacency rules (e.g. Volcanic never adjacent to Aquatic)
- Whether zone appearance is capped per run (e.g. at most 2 Botanical floors per run)

**Floor transition**
- When moving to a new floor, there is a chance the entire next floor is replaced by a 3D section (challenge floor)
- Otherwise, normal 2D floor generation continues

**Early run exit**
The player can exit a run at any time from any cleared room by accessing the staging return terminal (or equivalent). On exit:
- All tokens, items, and card packs found during the run are kept
- Body parts are always kept regardless
- The run is abandoned — no further progress that run
- This is a deliberate push-your-luck decision, not a failsafe

**Room lifecycle**
1. Player enters → enemies spawn (procedurally placed)
2. Doors lock while enemies are alive
3. All enemies dead → doors open, drops appear
4. Room flagged cleared (no re-spawn on re-entry)

---

### 6. Minimap System

BOI-style minimap with 3 zoom stages, toggled by a key.

| Stage | Detail |
|-------|--------|
| Stage 1 (small) | Dots only — shows room positions, current room highlighted |
| Stage 2 (medium) | Room shapes visible, door connections shown |
| Stage 3 (large) | Full map with room type icons (boss skull, item star, shop bag, etc.) |

Icons on the map are only shown for rooms already visited (fog of war).
Special items (Compass equivalent) can reveal boss room; others reveal all rooms or secret rooms.

---

### 7. 3D Moment System

Two types of 3D content:

**Type A — Secret rooms within a floor**
- Hidden in 2D floors, found by exploring or by special item/ability
- Each is a self-contained 3D challenge: platforming, puzzle, or big fight
- Fundamentally different gameplay from 2D rooms
- Reward is significant (rare part, legendary card, lore tape)

**Type B — Full 3D floor replacement**
- When transitioning between floor sections, RNG can replace an entire floor with a 3D section
- The whole floor plays out in 3D (multiple connected 3D challenges/areas)
- Acts like a "bonus world" — higher difficulty, higher reward
- More frequent in deeper floors (Floors 7+)

**Technical implementation**
- `ViewManager` handles transitions: fade out, swap scene, fade in, remap controls
- 3D scenes are Godot 3D sub-scenes, loaded independently
- Player stats carry over but are translated to 3D equivalents
- On completion, transition back to 2D (next floor or back to cleared room)

---

### 8. Lore System

**Delivery methods:**
1. **Terminals with tapes** — found in control room (hub) and lore rooms in runs. Watch the tape → it syncs to the player's archive (accessible from hub terminal AND pause menu lore log)
2. **NPCs** — saved companions deliver lore through dialogue in the hub cafeteria; gated by development stage
3. **Card flavor text** — all cards have lore in their flavor text; Archive/Fragmented cards are the primary story delivery mechanism
4. **Rogue Robot Compendium** — enemy log. Every corrupted robot encountered in the station gets an entry: original designation, assigned zone, their role, and what happened to them. Tracked in the hub. Accessible from pause menu.
5. **Card Compendium** — full collection log. Every card ever seen or acquired, organized by zone series. Includes flavor text, artwork, and series notes. Tracked in the hub. Accessible from pause menu.
6. **Environmental** — readable notes, station signage, wall markings (secondary, ambient method)

**Access:** All discovered lore is accessible in two places:
- **In-hub terminals** (Control Room / Trophy Room) — the primary experience, feels like an event
- **Pause menu archive tab** — always available, for reference during play

**LoreManager** tracks:
- Which tapes discovered/watched
- Which NPC lore lines triggered
- Which Compendium entries unlocked (robot encounters + card acquisitions)
- Lore is never lost — persists through all deaths

---

### 9. Card Game System (Full Minigame — Phase 7+)

**Format: Deck-based TCG with Auto-battler Combat Resolution**

A traditional deck-based card game where the combat phase resolves automatically. No in-match shop — the strategic layer lives in deck construction (before the match) and hand/board management (during). Closer to a TCG than Hearthstone Battlegrounds, with auto-battler combat as the payoff.

**Match structure**
- Each player starts with a full deck and draws an opening hand of ~10 cards
- **Prep phase**: Players play cards from hand to build their board — creatures placed, items/upgrades attached, support cards set, arena cards committed, trainer cards used for utility actions
- **Combat phase**: Boards auto-resolve — creatures fight by priority/left-to-right
- Cards played move to discard pile. Players draw more next prep phase.
- When deck is empty → reshuffle discard pile and continue
- First player to win [TBD] combat rounds wins the match — match length scales with NPC tier

**The meta layer:** Trainer cards are the engine of a deck. They let you draw more, search for specific cards, recover discarded pieces, or disrupt the opponent's hand. The strategic ceiling of deck construction is: how consistently can you access what you need, when you need it?

**Match win condition**
- Base: first player to win 3 combat rounds wins the match
- Certain rare cards can modify this rule mid-match (see Protocol cards below)
- This means match length is not fixed — it's a live variable that both players can influence through their decks

**Card Types**

| Type | Role |
|---|---|
| **Creature** | Core auto-battle units. Represent species from the planet. Have Attack, Health, and a passive trait or triggered ability. |
| **Item / Upgrade** | Attach to a specific creature. Modifies its stats or grants a new behavior in combat. Equipment analogue. |
| **Trainer** | One-time prep phase action. Draw extra cards, search deck, disrupt opponent's hand, recover a creature. |
| **Support** | Persistent passive that stays on your side for multiple rounds. Auras, structures, environmental benefits. |
| **Arena** | Battlefield modifier. Changes the rules of combat for the round. Weather, terrain, gravity, lighting effects. |
| **Protocol** | Rare. Changes the fundamental rules of the match itself. Win condition modifiers, turn structure changes, scoring alterations. |

**Protocol cards — match rule modifiers**
Protocol cards are the rarest card type. They alter the match's win condition or structural rules rather than affecting the battlefield directly. Examples:
- *Extended Session*: "+1 win required for both players this match" (extends the match)
- *Sudden Resolution*: "Next combat round is worth 2 wins" (compresses the match)
- *Deadlock Protocol*: "Tied combat rounds now count as wins for the leading player"

These are Epic or Legendary rarity and are found primarily in Data floors and as boss rewards. Because they are rare, match length variance increases naturally as players acquire more cards over time — the challenge scales with collection depth rather than a preset difficulty mode. Building a deck around Protocol manipulation is a distinct high-skill strategy.

**Card resource — per card**
- Name, artwork, zone series, rarity (Common/Rare/Epic/Legendary/Fragmented)
- Type (Creature/Item/Upgrade/Trainer/Support/Arena)
- Stat block (creatures only: Attack, Health, trait)
- Effect text
- Flavor text — lore-connected, written from the perspective of a robot who has studied the data

**Fragmented / Archive cards**
- Found only in Data floors and deep lore rooms
- Represent partial archival records — they may depict extinct species, lost habitats, or pieces of the planet's final years
- Flavor text is the story delivery mechanism — each fragment tells a piece of what happened
- Mechanically powerful (Legendary tier) but also lore-complete entries in the archive log

**Zone series**
- Each zone has its own card series with creatures matching that ecological theme
- Players build decks around zone affinities or mix across zones
- Saved NPC robots have decks built from their zone's series — their deck is an expression of who they are and what they monitored

**Opponents**
- NPCs saved and brought to hub sit in cafeteria and can be challenged
- Each NPC has a unique deck built from their zone series + personality
- AI difficulty scales with NPC tier and floor depth they were found on
- NPC dialogue before/after matches delivers lore (intact memory cards = they remember everything)

**In-match card flow**
- Draw from personal deck (built and brought to the match)
- Cards played → discard pile
- Deck emptied → shuffle discard → new draw pile (no interruption to match)
- Trainer cards are the primary way to accelerate access: draw extra cards, search deck, recover from discard

**Card acquisition (outside matches)**
- Zone-specific packs found in runs (survive to bring them back)
- Packs bought in hub shop
- Rare/Legendary cards as boss or deep-floor rewards
- Archive fragments exclusively from Data floors and lore rooms

**Online PvP (Phase 9 — deferred)**
- NetworkManager handles connection and matchmaking
- Trading via hub trading board

---

### 10. Save System

**SaveManager** persists to disk:
- Body parts equipped (survive runs) and those in armory/hub
- Card collection and deck configs
- Cosmetics in trophy room
- NPC states (in hub, lost, undiscovered)
- Lore tapes discovered (cloud log)
- Currency in hub shop
- Run history / stats

**NOT saved:**
- Mid-run state (no mid-run saves — death is final for that run)
- Items/parts/packs found during an in-progress run (only saved on successful return to hub)

---

### 11. EventBus (Signal Hub)

Key signals:
```gdscript
signal player_died
signal run_started
signal run_ended(reached_hub: bool)
signal room_cleared(room_id)
signal item_collected(item: RunItem)
signal card_pack_found(pack: CardPack)
signal body_part_found(part: BodyPart)
signal body_part_equipped(part: BodyPart)
signal floor_cleared(floor_number: int)
signal npc_found(npc: NPCDefinition)
signal npc_lost(npc: NPCDefinition)
signal npc_saved(npc: NPCDefinition)
signal lore_discovered(lore_id: String)
signal card_game_started(opponent)
signal card_game_ended(winner)
signal view_switching_to_3d(scene_path: String)
signal view_switching_to_2d
```

---

## Build Order

| Phase | Milestone |
|-------|----------|
| 1 | Player: movement, shooting placeholder, modular body (stat system) |
| 2 | Single test room: enemies, basic combat, drops |
| 3 | Room generation: multi-room floors, door system, room types |
| 4 | Hub world: all 7 rooms, physical navigation |
| 5 | Permanent upgrade system: body parts found in runs, survive to keep |
| 6 | Full run loop: 3 floors, 3 bosses (Warden → Relay → Hivemind), death screen, victory screen, return to hub with rewards |
| 7 | Combat depth: BOI-style item variety, status effects, projectile behaviors |
| 8 | NPC system: find in runs, bring to hub, card opponents, lore dialogue |
| 9 | Card game: rules engine, deck builder, AI opponents |
| 10 | Lore system: terminals, tapes, cloud log, NPC lore, card flavor |
| 11 | 3D moment rooms: secret challenges + floor replacement type |
| 12 | Minimap: 3-stage BOI style |
| 13 | Online card game: networking, matchmaking, trading |
| 14 | Cosmetics, trophy room, polish, audio |

---

## Open Questions / Still To Decide

- [x] Game title — **Station 0.** The first station built (Station Zero = prototype, origin). Last surviving. Zero humans remaining. Player starts at zero — no memory, no context. Clean as a logo, doesn't over-explain.
- [x] Player robot's designation — **Adaptive Maintenance Unit. Designed to swap tool-part components. Explains modular body system diegetically. Memory card corrupted (amnesia), not hostile. Most enemies are corrupted maintenance units of the same class.**
- [x] What caused the incident — **humanity destroyed the planet through neglect/overuse (WALL-E structure). Station was built to monitor the planet's vital signs. Robots outlived their creators by thousands of years.**
- [x] Card game theme — **in-universe game built by robots using human archival data. Cards represent species that lived on the planet. Born from grief and preservation instinct.**
- [x] Top-down vs isometric — **primary top-down, isometric rooms as variants, 3D for challenges**
- [x] What do NPCs look like — **other robots, each designed for their zone's job (botanical NPC looks like a gardening/analysis robot, mineral NPC looks like a geological survey robot, etc.)**
- [x] Card game shop — **no shop. Deck-based draw with discard pile reshuffle. Trainer cards are the access engine. Strategic layer is in deck construction, not in-match economy.**
- [x] Zone floor order — **randomized per run with spawning rules. No fixed progression. Station zones are different wings, not stacked floors. Rules TBD through playtesting.**
- [x] Hub permanent currency — **single unified currency (scrap tokens). Found in runs, earned in hub (NPC quests, card matches). Stored in hub deposit machine. Freely withdrawn into runs. Lost on death. Spent in both in-run economy (vending machines, run shops) and hub shop. Early run exit lets player cash out and keep everything found so far.**
- [x] NPC role during runs — **quest-gated. Fixed classes the player cannot modify. Fetch quests (solo) and escort quests (NPC joins run). Escort: if player or NPC dies, NPC gets lost but all data persists. Compass consumable (rare, one-time use) lets a lost NPC find their own way home.**
- [x] Lore archive access — **both: hub terminals (Control Room / Trophy Room) for the full experience, and pause menu archive tab for reference during play.**
- [x] Match win condition — **base: first to 3 wins. Protocol cards (rare) can modify this mid-match. Challenge scales with card collection depth, not preset modes.**
- [x] Visual style scope — **FRLG remake aesthetic applies to the whole game. Top-down world, hub, card game UI, and creature art all share the same visual language.**
- [x] Zone spawning weight rules — **fully random. Data floors at lower spawn rate. Adjacency and weight rules TBD through playtesting.**
- [x] Run currency — **scrap tokens. Old machine-stamped transit tokens. Found in runs, spent at vending machines (temporary buffs, cards, consumables), lost on death.**

---

## Performance Notes

Identified risks and mitigation strategies.

| Area | Risk | Severity | Mitigation |
|---|---|---|---|
| 2D↔3D transitions | Hitch/freeze if 3D scene loads synchronously | **High** | Use `ResourceLoader.load_threaded_request()` to background-load 3D scenes well before the transition fires. Design this in from Phase 11, not as an afterthought. |
| NetworkManager autoload | Startup delay + wasted memory in all non-online phases | **Medium** | Don't connect/initialize in `_ready()`. Make it fully lazy — only activate when the card game requests a connection. |
| Card game AI | Frame stall if AI decision runs on main thread | **Medium** | Run AI logic in a `Thread` or via coroutine. Never block the main thread for card evaluation. |
| Procedural room/floor generation | Possible hitch on floor entry if generated synchronously | **Low–Medium** | Generate the next floor in the background while the player is still clearing the current one. |
| Hub world sub-rooms | Hitch on room transition if scenes load on demand | **Low** | Pre-load adjacent hub rooms or load the full hub as one scene with visibility toggling. |

**Non-issues (look complex, aren't):**
- Modular body (5 Sprite2Ds) — trivially cheap
- Dynamic stat recalculation — fine if event-driven, not per-frame
- Save/load — disk I/O on explicit events only
- Card collection size — even 500+ Resource entries is negligible in memory