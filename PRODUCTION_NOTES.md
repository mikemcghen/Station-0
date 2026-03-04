# Production Notes — Backing, Team & Funding

---

## Solo Dev Reality

Possible, but 5–8 years to do it properly. The game has four disciplines that each need to be excellent:

- Systems programming (roguelike, card rules engine, networking)
- Art (2D sprites, isometric assets, 3D assets, UI, animations)
- Writing (NPC dialogue, lore tapes, card flavor text)
- Audio (music, SFX)

The NPC dialogue and lore delivery are the core differentiator — weak writing will kill the game regardless of how good the systems are.

---

## Minimum Viable Team

**3–4 people | 2–3 years | ~$150k–$300k**

| Role | Priority | Why |
|---|---|---|
| Artist | Critical | Visual identity makes or breaks the Steam page |
| Writer | Critical | NPC dialogue and lore are the soul of this game |
| Second programmer | High | Card AI, networking, and roguelike systems in parallel is a lot |
| Composer/audio | Medium | Can be contracted per-milestone rather than full-time |

This gets to Phases 1–10 (full roguelike + card game with AI + lore + NPCs) without online PvP.

---

## Comfortable Team

**5–6 people | 2 years | ~$400k–$700k**

Adds dedicated QA and a proper audio lead. QA matters more than it sounds for a game this interconnected — a card game with AI opponents, online play, and a complex NPC state machine will generate serious edge-case bugs.

---

## Funding Paths

### Grants (No Equity — Best First Step)
- **Epic MegaGrants** — up to $500k, no strings attached
- **National/regional funds** — UK Games Fund, Canada Media Fund, Screen Australia, etc. (depending on location)
- Apply for these before approaching publishers. The architecture doc is unusually well-structured for a grant application.

### Publisher (Marketing + Porting Support)
Good fits for this game's tone and scope:

| Publisher | Why |
|---|---|
| Raw Fury | Narrative-heavy indie, strong aesthetic fit |
| Fellow Traveller | Story-driven games specifically |
| Devolver Digital | If the tone goes darker or weirder |
| Humble Games | Mid-tier indie, less creative interference |

Publishers typically fund $200k–$800k against a revenue share (usually 70/30 or 80/20 after recoup). You give up some control but gain QA, marketing, and often a console port — which can double lifetime revenue.

### Avoid
Equity/investment funding unless building toward a live service model. A premium indie doesn't need that pressure.

---

## Online PvP — Separate Budget Item

Online card PvP is **not a one-time development cost**. It requires:
- Server hosting (ongoing monthly)
- Anti-cheat
- Balance patches and moderation
- Customer support for trade disputes

This is a live service commitment. Treat it as a separate business decision, not just a phase on the build list.

---

## Priority Order

1. **Find an artist.** Without a strong visual identity you can't pitch, can't get funding, can't build an audience.
2. **Apply for grants** — the concept and architecture are already in good shape for an application.
3. **Build to Phase 6** (full run loop) before approaching publishers. A playable vertical slice is worth 10x more than a document.
4. **Decide on online PvP scope** before any publisher conversation — it changes the funding ask significantly.
