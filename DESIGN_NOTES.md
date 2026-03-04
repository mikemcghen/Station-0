# Design Notes — Standing Out in the Roguelike Market

---

## The Core Differentiator: The NPC-Card-Lore Triangle

This is the thing no other game does, and it needs to be the centerpiece of everything:

- You find a survivor in a run. You risk bringing them along. They die. You mourn them.
- You find them again in a future run — different floor, maybe a different disposition. Did they remember?
- You bring them home. They sit in your cafeteria. Their card deck *is their personality*. Their dialogue tells you what they know about what happened.

No other game does this. Not Hades, not Slay the Spire, not BOI. The card game being the relationship layer — where you play against characters you rescued — is the emotional hook.

**This only works if the NPCs feel like real characters**, not systems. They need:
- Distinct voices and personalities
- Dialogue that reacts to being lost and found again
- Responses to run outcomes ("you almost didn't make it back")
- Their deck reflecting what they know and who they are

The Hades lesson: the loop is only meaningful if the people waiting at home are real.

---

## The Mystery Has a Shape Now

**What happened:** Humanity damaged and ultimately destroyed the planet they lived on — through accumulated neglect, overuse, and a failure to change course in time. The station was built not in triumph but in guilt: a vigil. Humans and robots worked together here, watching the vital signs of a dying world, until the humans were gone too.

The emotional structure is WALL-E: not a villain, not an attack, just the slow weight of what people do when they love something and take it for granted until it's too late.

**Why this works for the mystery:**
- The player doesn't know any of this at the start (memory corruption)
- The lore delivery is archaeological — fragments, not explanations
- Each Archive card is a piece of a picture the player assembles themselves
- NPC robots with intact memories are unreliable narrators in an interesting way: they remember everything but have had thousands of years to process it alone, and each has a different relationship to what happened
- The creatures on the cards are beautiful and clearly once-living — the tragedy is present in the game's most visible layer before the player even reads a lore entry

**What the reveal feels like:** Not a twist. A confirmation of what the player already suspects, delivered with weight. Inscryption's lesson applies: the systems point at the answer before it's spoken. A player who finishes the game should feel like they understood it before the last lore card told them.

---

## The Body Part System Has Untapped Potential

Currently parts are stat modifiers + sprite swaps. What would make them memorable:

**Parts that are recognizable.**
If you find an arm in the wreckage and a lore tape later names the robot it belonged to, that part now has weight. You're not just wearing an upgrade — you're carrying a piece of someone.

**Parts with personality or drawbacks.**
The best BOI items have costs or consequences. Pure stat buffs aren't memorable. Examples:
- A head that gives massive range but narrows vision
- A torso that boosts speed but makes you louder (enemy detection range increases)
- An arm that overclocks fire rate but generates heat (cooldown penalty)

**Enemies using the same modular system.**
The player is an adaptive maintenance unit — and so are most of the corrupted robots they fight. This is the horror of it: you're fighting yourself, or what you could have become. Corrupted maintenance units should visibly reflect their degraded state through their parts. Players read an enemy's loadout the same way they read their own. Salvaging parts from defeated enemies ties combat directly to progression and reinforces that you're cannibalizing a graveyard of former colleagues.

---

## The Hub Needs to Feel Lonely Before It Feels Alive

The emotional impact of bringing NPCs home is proportional to how empty the hub feels without them.

Early game:
- Most terminals offline
- Flickering lights
- Distant mechanical sounds, no voices
- Cafeteria completely empty

As you progress:
- Lights come on in populated areas
- NPCs animate the spaces they inhabit
- The cafeteria becomes a place you want to return to

That contrast — from isolated to inhabited — is the emotional arc of the whole game.

---

## Visual Identity — Reference Locked: FireRed/LeafGreen Remake Aesthetic

**The reference:** The remade FireRed/LeafGreen games for Switch/Switch 2. Clean, vibrant, readable. Bold outlines, warm palette, expressive sprites without excess detail. Animations that are economical but feel alive. UI that is simple and trustworthy.

**What this means in practice:**
- Top-down world uses clean sprite work — nothing gritty or hyper-detailed
- Characters (robots) are readable at small sizes but have personality at full scale
- The card game UI should feel like a natural extension of this aesthetic — bright, clean, legible
- The planet's creatures (on cards) should feel like they belong in this visual language: fantastical and expressive, not photorealistic

**Creature aesthetic — Vivisteria reference:**
Creatures are earth-adjacent but not from Earth. Think bioluminescent, organic, beautiful — the kind of design that reads as "alive" even in still card art. Pixar's Elementals (specifically the Vivisteria) is the target emotional register: something that looks like it belongs in nature but is unmistakably from somewhere else. Not Pokemon-mechanical (type matchup grids) but Pokemon-adjacent in the sense that each creature has a clear identity, a silhouette you can read, and a feeling you could attach to.

The creatures carry the emotional weight of the game in a visual layer: they're on every card, they're beautiful, and they're all extinct or endangered. Players should feel that before they read a word of lore.

**Robot visual identity:**
- Modular body system = genuinely unique appearance per run
- Part visual language communicates origin zone: Botanical parts look organic/green, Mineral parts look crystalline, Volcanic parts look heat-scarred, etc.
- Corrupted enemies should look like recognizable robots in degraded state — you can read what they used to be
- NPC robots are clearly zone-matched: the Botanical robot looks like a caretaker, the Mineral robot looks like a surveyor, etc.

**The robot aesthetic is crowded** (Roboquest, etc.). The zone-matched visual language for parts and NPCs, combined with the FRLG aesthetic, is what creates distinction: this doesn't look like a shooter-robot game, it looks like a world where robots became curators.

---

## The Card Game as Emotional Core

The card game isn't a side activity. It's the robots' way of holding on.

After humanity ended, surviving robots had access to everything humans recorded — every species catalogued, every habitat surveyed, every ecosystem studied. They couldn't bring any of it back. They couldn't fix what happened. What they could do was build something that kept it alive in a different form: a game where the creatures of a dead planet are remembered as powerful, beautiful, worth caring about.

Every card in the game is an act of preservation. The robots who built these series were grieving. The player inherits that grief without knowing it, and discovers it through play.

**This is why the card game has to be good.** It needs to stand on its own as a system worth engaging with — not because the lore forces you to, but because you want to. The emotional layer only lands if the mechanical layer already has you.

---

## The Pitch in One Line

**Station 0**
> *"You're the last robot. The others are out there. Bring them home. Then play cards and uncover what happened."*

That's a game with a clear identity. Lead with this.

**On the title:** Station 0 is the first monitoring station ever built by humanity — the original vigil. It is also the last one standing. "Zero" carries three meanings simultaneously: the station's designation as the first of its kind, the count of humans remaining, and the player's starting state — no memory, no context, nothing but function. It doesn't explain itself. That's the right kind of title for a game about piecing things together.

---

## Scope Recommendation for v1.0

Cut 3D moments and online PvP from the initial release scope. Ship:
- Full roguelike loop (Phases 1–7)
- NPC system (Phase 8)
- Card game with AI opponents (Phase 9)
- Lore system (Phase 10)

3D moments and online PvP are features. The NPC-card-lore triangle is the soul. Get the soul right first.
