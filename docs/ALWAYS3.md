# Always 3 living ragdolls near you (owner, 26 Nov 2026)
> "Sørg for der altid er 3 levende ragdolls lige i nærheden af en og hvis man dræber alle 1 skal der komme en ny løbende hvis han er langt væk, eller gående hen og sige noget hvis de er tæt på, så der altid er 3 levende."

Behind `Config.ALWAYS_THREE = true`. The server decides (DummyControl / DummySpawn / Lab dummies).

## The rule
- **Near** = within 35 studs of the player. **Living** = not knocked out, not busy (CPR, burial, carried, in a machine, revenge).
- Check every 0.5 s per player. **If fewer than 3 living ragdolls are near: call one in, within 1 s of the knockout.** One recruit per missing ragdoll, never more than 3 on the way at once.

## Who comes, and how
1. **Pick the nearest free living lab ragdoll that is not already near.**
   - **More than 60 studs away:** it RUNS to the player (sprint speed, arms pumping, a small dust puff per step).
   - **Within 60 studs:** it WALKS over, and on arrival says ONE short line in its talk bubble. Pick at random:
     - "Did somebody call me?"
     - "What happened here?!"
     - "I heard noises."
     - "Oh no. Not again."
     - "Hi! Am I next?"
     - "I'm just here for the snacks."
     - "Is it safe? It's not safe, is it."
     - "Reporting for duty."
2. **If no free ragdoll is left in the lab** (all knocked out or busy): spawn a new one out of view, 60-80 studs away (behind a building, the tower, a wall or a gate; never popping in on screen), and it RUNS in.
3. **Arrival:**
   - it stops about 10-15 studs from the player, spread out (not on top of the others);
   - it turns to the player and idles (looks around, shifts its weight).
   - It keeps its normal behaviour after that: the half that flee from guns still flee, and a ragdoll that runs off further than 35 studs is replaced by the same rule.

## Limits
- **Stay inside the lab caps** (phones 9, tablets 13 living lab ragdolls).
  - If a new one is needed and the cap is full, the oldest knocked-out body far from the player is cleaned up first (fade out), then the new one comes.
- **No recruits while the player is in a car, in a machine, in a menu at the start, or on another map without ragdolls.** On maps with ragdolls the same rule applies.
- **Lines:** max one recruit line every 4 s per player, so they do not talk over each other.
- **Newcomers** (first visit): the same, from the first second.

## Check
- One quick Play: knock out all 3 near you. Each time one is called within about 1 s; a far one runs, a near one walks and talks.
- Then stand still for 30 s: there are always 3 living ragdolls within 35 studs.
- Test selv (Danish) in the run's one list: on phone and PC.
