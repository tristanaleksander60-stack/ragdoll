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

## NEVER ZERO: if no ragdoll is near you, one comes RUNNING at once (owner, 26 Nov 2026: "Gør så hvis der er 0 ragdolls ved en så skal der altid minimum komme 1 løbende")
A hard safety net on top of the 3-near rule. It works EVERYWHERE on the map:
- in every room;
- on the roads;
- at the racetrack and the station;
- on the plaza;
- in solo and in multiplayer (for each player).

**The trigger:** a check every 0.5 s. If a player has **0 living ragdolls within 35 studs for more than 1 s**, one comes RUNNING straight away:
1. **The nearest free living ragdoll** sprints to the player (pace about 34) on a pathfinding route, starting within 0.5 s.
2. **If none is free** (or all are more than 150 studs away): spawn a new one STANDING (`Spawn standing` rules), out of view about 50-80 studs away (behind trees, a building or a corner), and it sprints in.
3. **While it runs,** the next ones follow, until the 3-near rule is met again.

**Edge cases:**
- **High places** (the tower top, the grandstand): it runs up the stairs; or, if that takes over 8 s, it waits at the foot and waves, and a second one spawns at the top stair's landing, out of view.
- **The player is in a car, on the F1 car, on a bike or in a machine:** wait until they get out (no chasing cars).
- **The first seconds after joining:** the 3 standing spawns cover it.
- **The caps:** if the phone cap is full, the oldest knocked-out body far away is cleaned up first, so there is always room for this one.

**Funnel:** count "NeverZero" triggers per session (Metrics). Many triggers in one area means more ragdolls should roam there; note it in State.

**Check:**
- walk to the far corners of every room, the racetrack and the station, and stand still;
- knock out everyone near you;
- within about 1.5 s one is always running toward you.

## LOOK AT YOU when they talk to you (owner, 26 Nov 2026: "Gør så ragdolls kigger på en når de snakker til dig")
- **When a ragdoll says a line TO the player:** the comer, a watcher's line, a walker's "Hi!", the TRY ragdoll, the angry dummy, the revenge line, or a recruit arriving.
  - **Eyes:** first its eyes move to the player.
  - **Head:** then its head turns (the neck joint, max about 70°, smooth over 0.2 s).
  - **Body:** if the player is more than about 70° to the side, the whole body turns on the spot to face the player (small steps, not a spin).
  - **While talking:** it keeps looking at the player's head (tracking smoothly if the player moves), with small natural motions: a nod, the eyebrows, a hand gesture toward the player.
  - **After the line:** it holds the look 1 s, then goes back to what it was doing.
- **When ragdolls talk to EACH OTHER** (the chatters, the road walkers): they look at each other, not at the player. The listener nods.
- **Never:**
  - the head turned past a natural angle (no owl heads);
  - looking through the body;
  - turning while knocked out, ragdolled or in a machine.
- **Built with:** the active-ragdoll pose system (the neck and torso targets), plus the face decal's eyes (an eyes-left/right/up variant, or a moving pupil if the face supports it). Client-side look-at for smoothness; the server only says who talks to whom.
- **Phones:** only ragdolls within about 40 studs do the look-at.
- **Check:** walk round a talking ragdoll in a circle; its head and then its body follow you smoothly while it talks.

## Ragdolls never walk through or into each other (owner, 26 Nov 2026: "Gør så ragdolls ikke går igennem hinanden/ind i hinanden")
- **Collision:**
  - standing and walking ragdolls collide with each other (a collision group pair ON for their torsos and legs, at least);
  - knocked-out and flying ragdolls collide fully (they pile up, `RAGDOLL_FEEL.md` piles).
- **Avoidance while walking** (they should never even bump by accident):
  - each walker keeps a personal space of about 2.5 studs;
  - a soft separation steer away from the others near its path;
  - groups walk side by side or in a line, never inside each other;
  - pathfinding with an agent radius of 2;
  - at narrow spots one waits a moment or steps aside.
- **If two still bump:** a small shoulder-bump reaction (a half step back) and sometimes a line ("Excuse me!", "Watch it!", "Sorry!"), looking at each other.
- **Spawning:** never on top of another ragdoll (the `Spawn standing` clear-spot rule).
- **Performance:** the avoidance runs at about 5 Hz on the server for walkers; stand-ins far away use simple spacing only.
- **Check:** watch the plaza and a busy road for 2 minutes. No ragdoll may pass through another.

## Ragdolls never walk INTO things (owner, 26 Nov 2026: "Fiks så at ragdolls ikke går ind i ting")
**Today** walking ragdolls bump into and push through trees, benches, lamps, machines, walls, fences and the tree belts. They probably walk in straight lines (MoveTo to a target) without a path, or with collisions off on their walking body.

**The fix (`RAGDOLL_NAV = true`):**
1. **Real paths:**
   - every walk uses PathfindingService, with agent parameters fitted to a ragdoll (radius about 2, height about 5.5, AgentCanJump false, AgentCanClimb false; stairs are walkable ramps or steps);
   - recompute the path when blocked;
   - walk waypoint to waypoint, smoothing the corners.
2. **Costs and no-go areas:**
   - `PathfindingModifier` labels on the map: Walkway (cheap), Grass (medium), and Water, Lava, MachineFloor, Belt (tree belts), Flowerbed, Track (the racetrack surface, except at crossings) and Rail (except at crossings) all not passable;
   - machines, benches, lamps, trees, fences, the cars and props are obstacles (CanCollide parts, or invisible PathfindingModifier boxes round decoration that has CanCollide off).
3. **Only valid targets:** the roam, chat and watch spots are picked from a pre-sampled list of free walkable points (paths, plazas, courtyards, lawns, the watcher spots in front of machines), never a random point inside an object.
4. **Bodies collide with the world while walking:** the walking body has CanCollide on against the map, so even a bad path cannot push through a wall or a machine.
5. **Stuck guard:** if a walker makes less than 1 stud of progress in 1.5 s, it steps back, sidesteps, and recomputes. After 3 failures it picks a new target. It never pushes on into the object.
6. **Moving obstacles:**
   - it waits for cars, the train, the cyclist and the player, or steps aside;
   - it never walks into a running machine (except the demo walker climbing in on purpose, F31).
7. **Performance:**
   - paths are computed on the server, max about 6 per second in total, and cached for common routes (spawn to rooms);
   - far stand-ins follow the same paths without physics.

**Check:** follow 5 walkers each for 1 minute through busy rooms (Machine Hall, Fun Fair, the plaza). None may walk into or through a tree, bench, lamp, fence, machine, wall, water or flower bed.

## ALWAYS 3 ALIVE, refilled FAST (owner, 26 Nov 2026: "Gør så de 3 ragdolls kommer meget hurtigere hvis der kun er 1 eller 2, der skal altid være 3 til stede i live ved en")
**Today:** the refill takes too long when 1 or 2 are left.

**The rule:** within 35 studs there are ALWAYS 3 LIVING ragdolls (standing or walking; not knocked out, not busy in a machine, a burial, CPR or being carried). The moment the count drops below 3, the missing ones are on their way.

**Fast refill:**
1. **No waiting:**
   - check every 0.25 s (not 0.5);
   - start a recruit at once for EACH missing one (2 missing = 2 recruits in parallel);
   - no 1 s delay (that is only for NEVER ZERO's "0 near" fallback).
2. **Reserves already close:** the `RagdollDirector` keeps 2 RESERVE ragdolls trailing the player, out of view about 40-60 studs away (behind belts, trees or buildings, walking along the paths with the player), so a refill arrives in about 1-2 s.
   - When a reserve is used, the director sends a new reserve from the pool, out of view.
   - The reserves count toward the device pool (phone 10, tablet 14, PC 20).
3. **They come FAST:** recruits SPRINT at about 40 (faster than the player's walk of 30) on the shortest path, then slow to a walk for the last 6 studs and stop 8-14 studs away (the chatters and comer roles).
4. **Spawn closer if needed:** if no reserve or free ragdoll can arrive within 3 s, place one out of view at 25-40 studs (behind the nearest cover) and sprint it in.
5. **Knocked out does not count as alive:** a knocked-out ragdoll near you does NOT count toward the 3, so the refill starts the moment one is knocked out, even while its body is still there (CPR or burial may run beside the new ones).
6. **Caps:** if the pool is full, the oldest knocked-out body out of view returns to the pool first; never the 3 alive near you, never a pinned one.

**Check:**
- knock out 1, then 2, then all 3 near you, in a room, on a road and on the plaza;
- each time, the missing ones are visibly on their way within 0.5 s and arrive within about 2-3 s;
- count the time and write it in State;
- check on the phone emulator, with no lag.

## Do NOT spawn new ones when there are already many around (owner, 26 Nov 2026: "når der er mange i nærheden, så skal der ikke spawne 1 ny ragdoll bare fordi der ikke er 3 lige ved siden af en")
**Two different counts:**
- **NEAR:** living within 35 studs (the "3 near you" goal).
- **AROUND:** living within 70 studs, OR visible on the player's screen within 100 studs (the camera direction from the client).

**The rule:**
1. **If NEAR < 3 but AROUND ≥ 3:** do NOT spawn and do NOT bring reserves. Instead, call the nearest free living ragdolls from AROUND to walk (or jog) closer, until NEAR is 3. Use the comer and chatter roles; never pull watchers away from their machines unless there is nothing else.
2. **Only if AROUND < 3:** spawn or bring reserves (the fast refill above, NEVER ZERO), for the missing number up to 3 AROUND.
3. **Knocked-out, busy, pinned and in-machine ragdolls** count for neither.
4. **Hysteresis against flicker:** a new spawn needs AROUND < 3 for at least 0.5 s. A ragdoll just called closer is not called again for 6 s.
5. **Events and crowds** (event extras, the plaza at the start, road walkers passing): they count in AROUND, so a busy area never gets extra spawns.

**Check:** stand in a busy spot (the plaza, an event, near walkers) and knock out one ragdoll next to you. No new ragdoll appears; one of the nearby ones walks over instead. In an empty spot, the fast refill still happens.

## FINAL RULE for getting ragdolls to you (owner, 26 Nov 2026: "Den skal kun spawne 1 om bag ved med en cooldown, hvis der ikke er nogen i nærheden, og første prioritet er at sende en løbende")
This OVERRIDES the earlier refill details where they disagree: no parallel spawns, and no pre-spawned reserves.

**Priority 1, always first: SEND ONE RUNNING.**
- When the player needs ragdolls (NEAR < 3 and AROUND < 3, or NEVER ZERO), take the nearest FREE living ragdoll that already exists, up to about 150 studs away (walkers, idle ones; watchers only if nothing else), and send it SPRINTING to the player (pace about 40).
- More are missing? Send the next nearest existing one, one by one, every 0.5 s.

**Priority 2, only if nobody can be sent:** that is, no free living ragdoll exists within about 150 studs.
- **Spawn ONE** ragdoll **BEHIND the player**, out of view: about 30-50 studs behind the camera, on walkable ground, hidden (out of the camera's view, or behind cover), standing (the spawn-standing rules). It runs to the player.
- **Cooldown:** after a spawn, no other spawn for this player for 8 s. During the cooldown only Priority 1 is used.
- **Never more than 1 spawn at a time,** and never in front of the player or on screen.

**Removed:** the 2 "reserves" trailing the player (they were extra spawned ragdolls). The pool (`RAGDOLL_DIRECTOR.md`) still reuses parked ragdolls for the Priority 2 spawn, so it costs nothing extra.

**Check:**
- in an empty spot, knock out everyone near: one existing ragdoll comes running first; if none exist, exactly one appears from behind you, then the cooldown;
- in a busy spot, nothing spawns; nearby ones come over.

## BUG: the 3rd only comes after ALL 3 are knocked out (owner, 26 Nov 2026: "Sørg for, at med det samme der kun er 2 i nærheden af en, så kommer den 3. løbende, så man ikke skal dræbe dem alle 3, før der kommer en løbende")
**Today:** the refill seems to wait for 0 near (only NEVER ZERO fires).

**The fix (this is the trigger, written as plainly as possible):**
- **The moment** the number of LIVING ragdolls within 35 studs of the player drops from 3 to 2, or to 1, ONE ragdoll starts RUNNING to the player within 0.25 s. It does not wait for 0. It does not wait for the others to die.
  - A ragdoll that was just knocked out stops counting at once, even while its body still lies there.
- **Who comes:** the FINAL RULE order:
  1. an existing free ragdoll from AROUND (within 70 studs, or on screen), which now RUNS over (a jog at about 30, a sprint at about 40 if it is far), not walks;
  2. else an existing free one within 150 studs, sprinting;
  3. else ONE spawned behind the player out of view (the 8 s cooldown).
- **Each missing one** gets its own runner, started 0.5 s apart.
- **Check the code path:**
  - the refill logic must run on the "count < 3" condition, not only on "count == 0";
  - the knocked-out state must remove the ragdoll from the count immediately;
  - the cooldown and hysteresis from the other sections must not block priority 1 (sending an existing one).
- **Check:** knock out ONE of the 3 near you. Within half a second another is visibly running toward you. Do the same with 2.

## THE 2 NEARBY: there are always 2 more close by, and one WALKS over when one of the 3 dies (owner, 26 Nov 2026: "Sørg for at der hele tiden er 2 ragdolls i nærheden så hvis en af de 3 dør så kommer en af de andre 2 gående naturligt fra nærheden")
This OVERRIDES the FINAL RULE's "no reserves" and the BUG section's "it RUNS over" for the first one to come. The reserves here are NOT extra ragdolls trailing you. They are 2 ordinary living ragdolls going about their own life close by.

**Today:** there are 3 near you (within 35 studs). When one is knocked out, a ragdoll is sent RUNNING from further away, or one is spawned behind you.

**The new rule** (behind `Config.NEARBY_TWO = true`; in Lab alwaysThree / the RagdollDirector):
- **Two rings round each player:**
  - **NEAR:** 3 living ragdolls within 35 studs (as now);
  - **CLOSE BY:** 2 more living, free ragdolls 35-60 studs away.
- **What the 2 close by do:** they live their own normal life there:
  - walking, idle actions (LIFE_IDLE), chatting with each other, looking at a machine;
  - not following you in a line, not staring at you, not standing still waiting.

  When you move on, they drift along with you naturally: every 6-10 s each picks a new free spot in the 35-60 ring, ahead of the way you walk (`NavTarget.snap`, F72). They walk there at a normal pace. They are often in view, so the place feels alive.
- **When one of the 3 dies** (is knocked out):
  - within 0.5 s, the nearest of the 2 close by notices: it turns its head to you or the body;
  - then it WALKS over naturally, at a brisk walk (Pace about 1.3), and joins the 3. It can say one line (TalkLines: "What happened here?", "Whoa, is he okay?") when it arrives.
  - It jogs (Pace about 1.8) only if it is more than 45 studs away.
  - If 2 of the 3 die, both of the 2 close by come, 0.5 s apart.
- **Then the close-by ring is refilled, quietly:**
  1. within 2 s, the nearest free existing ragdoll 60-150 studs away walks into the 35-60 ring (it walks; nobody sees a hurry);
  2. if there is none, ONE is placed out of view, behind you, at about 55-70 studs (the FINAL RULE's spawn rules: standing, on walkable ground, never on screen, the 8 s cooldown), and walks into the ring.
- **Priority order now:**
  1. the close-by one WALKS in (this section);
  2. if the close-by ring is empty: the FINAL RULE / BUG order (an existing one RUNS in from up to 150 studs);
  3. else one spawn behind you (the 8 s cooldown).

  NEVER ZERO still sends a runner if the near ring hits 0 and nobody close by can come.
- **Limits:**
  - 3 + 2 = 5 is under the nearby cap on every device (phone 7, tablet 9, PC 12, `RAGDOLL_DIRECTOR.md` Part C);
  - on phones the 2 close by may be in light mode (the 60/75 border), which is cheap;
  - the 2 close by are never machine watchers (those stay at their machine), never in your vehicle's way, and are paused while you drive, fly or ride (they reform 2 s after you stop);
  - the "Do NOT spawn new ones when many are around" rule still holds: if AROUND already has enough free ones, use them, never spawn.
- **Check:** stand still. There are 3 near you and you see 2 more pottering about a bit further away. Knock out one of the 3: one of the 2 looks over and walks in calmly, and a few seconds later a new one strolls into the ring further away. Walk across the map: the 2 come along naturally, never in a line behind you.

## DRAWN TO YOU: every free ragdoll drifts toward you along the paths, but keeps a polite distance (owner, 26 Nov 2026: "Sørg for alle ragdolls generelt er tiltrukket af mig og går på de stier hen mod mig og nærheden af mig/brugeren uden at gå ind i mig/helt op til mit ansigt nødvendigvis")
**Today** a free ragdoll (not one of the 3 near, not the 2 close by, not a watcher) roams to random spots in its room, so most of them are far away and walk anywhere.

**The new rule** (behind `Config.DRAWN_TO_YOU = true`; server, in the RagdollDirector and the roam picker):
- **Every free ragdoll is pulled toward its nearest player.** When it picks its next roam goal (every 8-15 s, as now), it picks a spot that is closer to the player than where it is now, in this band:
  - the 3 NEAR: within 35 studs (as now);
  - the 2 CLOSE BY: 35-60 studs (THE 2 NEARBY);
  - everyone else: 60-120 studs, the AROUND band. They mill about there (idle actions, chatting, looking at a machine) and keep drifting along as you move. They never push into the near rings themselves: only the refill rules call them in.
- **They walk ON THE PATHS:**
  - the goal is a point on the map's path network (the walkways and plazas from `OwnerMapPlan`, the path nodes and legs), or a free spot right beside a path (a bench, a lawn edge, a machine's watcher spot);
  - the route follows the paths: PathfindingModifier costs Walkway 1, Plaza 1, Grass 5, so the path is always the cheap way, and they only cross grass for the last few studs;
  - they keep to the right half of a path when others come the other way (`avoidDummies` passing side, with F72's hysteresis);
  - every goal goes through `NavTarget.snap` (F72).
- **Spread out, not a column:**
  - each one reserves its goal spot (no two within 4 studs);
  - the spots are spread round the player by angle (a free ragdoll takes the emptiest direction), so they come from different paths and stand in small groups, never in a line behind you.
- **A polite distance from you:**
  - **never closer than 5 studs** to a player unless it has a reason: talking to you (stops at 5-6 studs, facing you; LOOK AT YOU), the TRY lesson, the angry dummy's shove (F-items with 1-3 shoves), CPR, the dog. Inside 3.5 studs it always steps back, like `avoidDummies`' personal space but for players;
  - **never walks INTO you:** you are a moving obstacle for F72 step 6 (it stops, waits or steps aside; if you walk at it, it steps out of your way);
  - **never in your face or in your view:**
    - it never stops between your camera and your character within 12 studs;
    - in first person, it never stands inside a cone 6 studs in front of your camera (60 degrees);
    - one that ends up there steps aside within 1 s.
- **Limits:**
  - the nearby cap per device (`RAGDOLL_DIRECTOR.md` Part C: phone 7, tablet 9, PC 12 within 45 studs) always wins. The AROUND band starts at 60 studs, so the drifting ones never break the cap; extras over the cap walk away out of view as before;
  - they pause while you drive, fly or ride, and drift again 2 s after you stop;
  - machine watchers stay at their machine; demo walkers (F31) and event roles keep their jobs;
  - in a shared lab each ragdoll is drawn to its nearest player;
  - cost: one goal pick every 8-15 s per ragdoll; paths share the existing budget (about 6 a second); far stand-ins without physics follow the same paths.
- **Check:** stand in the plaza for 1 minute. Ragdolls you could see far away come your way along the paths (not over the flower beds), spread out, and settle 60-120 studs off in small groups, with 2 closer and 3 near you. None walks into you or stops in front of your camera. Walk to another room: they follow along the paths, loosely.


## SPREAD OUT + PERSONALITIES: curious, scared, heroes (owner, 26 Nov 2026 late: "Sørg for alle ragdolls ikke samles 1 sted, men går rundt omkring på mappet og nogle bliver tiltrukket af skud, andre bliver bange og løber, nogle prøver at være the hero")
**This changes DRAWN TO YOU:**
- only the 3 NEAR, the 2 CLOSE BY and at most 3 more in the AROUND band are pulled toward the player;
- every other ragdoll lives ALL OVER the map;
- the earlier "never afraid of weapons" rule now holds only for the CHILL and HERO personalities.

**1. Spread over the whole map, never one clump** (server, the roam picker; `Config.SPREAD_LIFE = true`):
- **Hangout spots:** every attraction's front, every bench, the round tower plaza, the pools, the leaderboard plaza and the walkway corners (from `OwnerMapPlan`).
- **Each spot has a cap:** at most 3 ragdolls idling there, and a chat group at most 3.
- **A wanderer's next goal** (every 10-25 s) is picked at random, weighted toward the EMPTIEST spots and ones far from where it is, so they cross the map along the walkways (F72 nav).
- **Anti-clump:** never more than 5 ragdolls inside any 25-stud circle, except at a show (a machine running, a fight, CPR), and then only while it lasts.
- **Phones:** the pool is small, so the far spots are filled by the PATH WALKERS (`LIFE_IDLE.md` 4). The map still looks lived-in everywhere without more physics bodies.

**2. A personality for every ragdoll** (an attribute `Persona`, given when it is made or reused):

| Persona | Share | Everyday | When a shot, blast or hit happens nearby (pistol 50 studs, rifle 80, shotgun 60, explosion 120) |
|---|---|---|---|
| **CURIOUS** | about 35% | wanders, looks at machines, watches demos | stops, turns to the sound, WALKS closer to 12-18 studs, watches; points, "Whoa!", "Do it again!"; sometimes holds up a phone and "films" (a small phone prop); leaves after 10-15 s without a new shot |
| **SCARED** | about 30% | jumpy: flinches at loud machines | covers its head, a short scream ("Aaah!", "Not again!"), RUNS AWAY along the walkways (F72: never into things), HIDES behind the nearest cover (a wall, a car, a machine, the grandstand) and peeks out now and then; after 15 s of quiet it walks back to its life |
| **HERO** | about 15% | walks with a straight back, helps others up | runs TO the victim: drags a hurt ragdoll by the arm to cover; gives CPR to a knocked-out one (F86 kneel); or steps between you and the victim with its arms out ("Stop!", "Leave him alone!"). If you keep shooting, it takes the hits for the victim; once in a while it shoves you (the angry shove rules, 1-3 shoves, a cooldown) |
| **CHILL** | about 20% | sits on benches, eats, reads | ignores it, maybe a shrug ("Every day…") and goes on |

**3. Rules for all of them:**
- **The reactions use the new walking** (F72, F73, S1) and the faces of `BODY_V2` 4b (curious = wide eyes, scared = terrified, hero = determined, chill = bored).
- **The 3 near and the refill keep working:** a SCARED one that is fleeing does not count as "near" and is not called as a recruit for 15 s; CURIOUS and HERO ones count and can be called.
- **No vanishing in view, the nearby caps, the never-walk-into-you rules:** all as before.
- **The personality also tunes small things:** a scared one walks a little faster and looks round more; a hero's TRY and machine lines are braver; a curious one comes to watch your machine demos.
- **Lines:** each persona gets its own set of 6+ lines in `Shared/TalkLines`, never twice in a row.

**Check (the owner):**
- walk round the map: ragdolls everywhere in small groups, never one big crowd;
- fire a few shots: some come to look and film, some run and hide and peek, one hero runs in to help the victim or stands in your way, and a few on the benches do not care.
