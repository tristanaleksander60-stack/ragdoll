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

## Spectators at every machine (owner, 26 Nov 2026)
> "Der skal være en ragdoll ved hver maskine og stå og kigge, nogle gange flere, men minimum 1"

Behind `Config.MACHINE_WATCHERS = true`.
- **Every machine** (cannon, rocket, gyro cage, fan, press, washer, shredder, tesla coil, boxing ring, trampoline, slide, tower, creature tanks/pens, crash wall, lava…) always has **at least 1 ragdoll standing and watching**.
  - About a third of the machines have 2-3 (random, changes now and then).
  - They stand 6-10 studs from the machine, facing it, spread out, never in its path or its launch line.
- **What they do:**
  - **While watching:** they look around, shift their weight, point at the machine and nudge each other.
  - **When the machine runs** (a player or attract mode): they react. They cheer, cover their eyes, step back, laugh, or wince with the pain face.
  - **When the player comes close:** a watcher may say a line ("Have you tried it?", "Go on, press it.", "I'm not going in there.", "I've seen things."). Max one line every 6 s per player.
- **Replacing them:** if a watcher is knocked out, used in the machine, or called to the player (the 3-near rule), another lab ragdoll walks over within about 10 s, so the minimum of 1 always comes back.
  - With none free, a new one walks in from out of view.
- **Phone budget** (caps: 9 on phones, 13 on tablets):
  - watchers further than about 60 studs from the player are **light stand-ins**: anchored, animated, no physics, no talk;
  - a stand-in turns into a full ragdoll the moment the player comes within 60 studs, or shoots or touches it (swap in place, no pop);
  - full ragdolls further than 60 studs go back to stand-ins.
  - So every machine has its watcher, while the physics count stays inside the caps.
- **Check:**
  - One Play: walk round the whole lab; every machine has at least 1 watcher.
  - Knock one out; within about 10 s a new one stands there.
  - Phone emulator: the physics ragdoll count stays within the cap.

## Update (owner, 26 Nov 2026): not afraid of weapons; 2 chat, 1 comes all the way; they come FAST
> "Dummies skal ikke være bange for våben i sig selv, de 3 skal komme hen meget hurtigt, de 2 andre skal bare stå og snakke, 1 skal gå helt hen, og det skal skifte lidt."

- **Not afraid of weapons as such.** No fleeing, no hands up and no scared face just because a gun is held, pointed or fired near them:
  - set `FLEE_MAX = 0` (or a new `FEAR_WEAPONS = false`);
  - no "Is that a gun?" hands-up.
  They react only when actually hit (flinch, pain face, injury stages) or when hurt badly (stage 3 may limp away).
- **They come VERY fast:** a recruit sprints at about 34 (the player walks 28, `LAB_TARGET` RUN FASTER) and starts within 0.5 s of the knockout.
- **Roles of the 3 near you:**
  - **2 CHATTERS:** they stand together 8-14 studs from you, facing each other, and talk. Short bubble lines in turn, with gestures (nodding, shrugging, pointing at you), max one bubble every 4 s. Lines:
    - "Did you see that?"
    - "Nope. Didn't see a thing."
    - "Nice weather for it."
    - "I'm on my break."
    - "He looks friendly."
    - "Is this a test?"
  - **1 COMER:**
    - walks all the way up to you (stops about 4 studs away, facing you);
    - waves, leans in or pokes your shoulder (cartoon, no harm);
    - says one line: "Hi!", "Can I help you?", "You dropped something.", "Are you new here?"
  - **It changes a little:** every 15-25 s (random) the comer walks back to the chatters and one of the chatters becomes the comer. Sometimes (1 in 4) nobody comes for a while and all 3 chat.
- When one is knocked out, the rule refills to 3. The new arrival takes the free role.

## Spawn standing, never lying down (bug, owner 26 Nov 2026: "ragdollsne spawner væltede ved siden af en når man joiner")
**The bug:** when you join, the ragdolls next to you appear knocked over. The likely causes:
- spawned at the old floor height (the plaza is raised 4 studs), so they drop and topple, or spawn inside the plaza and get pushed out;
- spawned with zero tone, or in the ragdoll state;
- overlapping each other or a prop;
- spawned before the plaza streamed in, so they fall through, and then GroundGuard lifts them.

**The fix (`SPAWN_UPRIGHT = true`):**
1. **Ground:** for each spawn spot, raycast down from 20 studs above it against the real built ground (the plaza included). Place the ragdoll so its feet are exactly on that surface.
2. **Standing:** upright, in the standing state, with full tone; facing the player or its chat partner.
3. **Held:** anchor the root for the first 0.5 s (or until the ground under it exists on that client and the server), then release.
4. **Clear spot:** keep at least 4 studs from each other and from props; never inside a part (check with GetPartBoundsInBox, try the next spot if blocked).
5. **Safety:** if one still falls in its first 3 s, it gets up at once with no injury and no KO count.
6. **The same for every spawn:** recruits, walkers, watchers, TRY ragdolls and respawns.

**Check:** join 5 times (solo place and multiplayer place, PC and phone emulator). All 3 stand up straight every time.
