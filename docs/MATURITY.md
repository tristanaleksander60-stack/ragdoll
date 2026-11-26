# Maturity questionnaire: what the game really contains (NOW item 5, 26 Nov 2026)

**Deadline:** resubmit by Fri 27 Nov 2026 17:34 UTC. **The owner submits.** Claude has not seen Roblox's mail or the old answers: paste them in the next session and the draft below gets checked against Roblox's exact questions.

## What is in the game today (from the code and Config, 26 Nov 2026)

| Area | What players see | Switch |
|---|---|---|
| Weapons | Toy-named guns (Popper, Buzz Blaster ...), melee (bat, axe, katana), explosives, a nuke. Realistic gun sounds. Shooting human-shaped grey mannequins. | `TOY_NAMES` true |
| Blood | **Purple** blood: splashes, drips, purple hurt limbs. Not red. | `BLOOD = "purple"` |
| Body damage | **Limbs come off** after enough rounds (stumps, bones showing), heads burst into pieces after big-gun head shots, a body can be cut in half at the waist, X-ray bones. | `SEVERING = true`, `XRAY_REPLAY` |
| Death words | "Dead", "no pulse", "bled out" on the hit card and the body card; a hospital-style monitor. Dead mannequins lie 20-30 s, then get up again. | `MILD_TEXT` true (body regions, no organ names) |
| Creatures | A spider, plant, frog, shark etc. that eat mannequins and spit out bones. | `LAB_CREATURES` |
| Player vs player | Players can grab and throw each other; no damage to players except angry dummies' punches (small). | - |
| Text | No free-form text from players in the world; chat is Roblox's own. | - |
| Money | Game passes and developer products, weapons for Robux, a Starter Crate. No paid random items (eggs are free). | - |

## Honest answers (draft)

- **Violence:** Yes, realistic weapons used on human-like characters (mannequins), with blood and dismemberment → this is the "strong" / "Moderate violence + blood" level, not "mild".
- **Blood:** Yes, but **not red** (purple). Roblox still counts non-red blood as blood.
- **Gore / dismemberment:** Yes (limbs off, bones, bursting heads) while `SEVERING` is on.
- **Crude humour, fear:** Mild (creatures eating dummies, cartoon tone).
- **Gambling:** No. **Romance, alcohol, drugs, swearing:** No.

## The choice (owner)

1. **Keep everything** → answer honestly as above. Expect a 13+ (or 17+ for the gore) label, like now.
2. **Aim for 9+ / all ages** (Bloody Ragdoll Physics went from 2.5k to 21k CCU after its label change). Claude switches, in one commit:
   - `SEVERING = false` (no limbs off, no bursting heads, no halves),
   - `BLOOD = "off"` (or keep purple only as small hit sparks),
   - words "Dead" / "bled out" → "KO" / "Out cold" (`MILD_TEXT` extended),
   - creatures spit out stars instead of bones.
   Then answer: violence "mild/unrealistic", no blood, no gore.

Recommendation: option 2. The phone audience is young, and the label is the biggest single lever on discovery.
