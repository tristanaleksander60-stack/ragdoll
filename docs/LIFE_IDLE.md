# Ragdolls behave like people when idle, and a cyclist rides round the lab (owner, 26 Nov 2026)
> "Sørg for de nogle gange bevæger deres fingre, strækker sig, ting som normale mennesker gør. Tilføj en der cykler rundt"

## 1. Human idle behaviour (`Config.IDLE_LIFE = true`)
Every living ragdoll that is standing, waiting or watching does a small human action now and then:
- **Timing:** each ragdoll every 8-20 s at random, never the same action twice in a row, and never two neighbours at the same moment.
- **The actions:**
  - wiggles or drums its fingers (uses the finger bones, `docs/BODY_V2.md` 4c);
  - cracks its knuckles;
  - stretches both arms over its head with a big yawn;
  - rolls its neck and shoulders;
  - shifts its weight from foot to foot;
  - scratches its head;
  - rubs its eyes;
  - looks at its wrist as if checking a watch;
  - looks at its fingernails;
  - crosses its arms;
  - puts its hands on its hips;
  - taps a foot;
  - kicks a pebble;
  - bends down to tie a shoe;
  - sneezes (a small head jerk plus a sound);
  - waves at the player;
  - turns its head to look at a sound, an explosion or a machine running.
- **Hurt ragdolls** (`docs/BODY_V2.md` 4b) use hurt versions instead: rubbing the sore limb, a limp shift, checking the bandage.
- **How it is built:** short layered animations on the upper body only (the legs keep standing), blended in and out (0.2 s), on the existing active-ragdoll pose system. A hit interrupts any idle at once.
- **Phones:** only ragdolls within about 40 studs do idles; far ones and stand-ins stay simple (`docs/PERF_MOBILE.md`).

## 2. A cyclist (`Config.CYCLIST = true`)
- **The existing BikeService** has a lab ragdoll riding the **Bike vehicle** (speed 44, the motorbike) round the lab. Keep that.
- **Add a separate pedal BICYCLE** (a realistic bicycle model from the Creator Store, malware pass) ridden by a lab ragdoll round the walkway loop of the big lab, at a calm 14-16 studs/s.
- **The rider:**
  - feet on the pedals, pedalling in time with the speed (the crank turns, the legs follow);
  - hands on the handlebars;
  - leaning into turns;
  - now and then it rings a bell, waves, or rides with no hands for a moment.
- **It stops for things:** it slows for and steers round the player and other ragdolls. It stops at the spawn plaza for a few seconds and rides on.
- **Knocked off:** any hit, a shot, a grab, the lasso, the dog or a car knocks the rider off with full ragdoll physics. The bicycle tips over and skids.
- **It gets back on:** when the rider gets up, it limps back to the bike, lifts it up and rides on (after about 10 s). If the rider is knocked out, another ragdoll comes for the bike after 30 s.
- **The player can ride it** when it is free: press E at the bicycle. The same calm speed, and pedalling uses the same animation.
- **Phones:** one bicycle per lab; simple collision.
- **Check:** one quick Play. Watch it ride the loop, knock the rider off, see it get back on, and ride it yourself.

## 3. Ragdolls walking the roads out there and chatting (owner, 26 Nov 2026: "der skal gå ragdolls rundt på vejene derude og snakke med hinanden")
- **The walkers:**
  - about 10-14 lab ragdolls walk the roads in 2s and 3s: the outer avenues, the cross roads, the boulevard, the road to the station, and the paths by the racetrack and the grandstands;
  - they walk at a calm pace, keep to the walkway (never on the grass edge or in the middle of a junction), and step aside for the player, cars and the cyclist.
- **They talk:**
  - every 20-40 s a group stops (at a bench, a junction, a lamp or a view) and chats for 6-12 s;
  - bubble lines in turn, with gestures (nodding, pointing at things nearby, laughing, shrugging);
  - lines fit where they are, using `Shared/TalkLines`, plus small talk:
    - "Nice day for it."
    - "Did you see the T-rex?"
    - "I'm going to the race later."
    - "My cousin went in the washer once."
    - "Is that the new tower?"
  - then they walk on;
  - sometimes one waves at the player or says "Hi!" as you pass.
- **Hits:** knock one over and the others react (shocked, help it up, or CPR when it is knocked out). They do not run away from weapons.
- **Phones and far away:**
  - walkers more than about 60 studs away are light stand-ins (animated, no physics, no talk); they become full ragdolls when you come close (`docs/ALWAYS3.md`);
  - talk bubbles only within about 40 studs;
  - this keeps the phone caps.

## 4. PEOPLE ON EVERY PATH, on every device, without lag (owner, 26 Nov 2026: "Der skal altid gå folk på stierne her uanset enhed, alle stier" and "Gør det smart på telefon så det ikke lagger men får samme effekt af at man aldrig føler sig alene")
**Today:** the owner's screenshot of the wide boulevard from the spawn shows it EMPTY as far as the eye can see. Section 3's road walkers are real ragdolls (physics, network), so on a phone only a few can exist, and most paths are empty.

**The idea (how big open-world games do crowds):** two kinds of people that look EXACTLY the same.
- **Real ragdolls:** the 3 near, the 2 close by, DRAWN TO YOU and the watchers (`ALWAYS3.md`). They have full physics and are on the server.
- **PATH WALKERS:** cheap people that only YOUR screen draws (client-only, anchored, no physics, no network), walking along every path you can see.
  - They are the same grey lab ragdoll: the same body, colours, face and size (the F45 rule: never yellow, never different).
  - **Anything you can touch is real:** a path walker that you come close to, aim at, hit or drive at becomes a real ragdoll before you can tell (step 5).

**Build** (behind `Config.PATH_LIFE = true`; a new `Client/PathLife.luau` and a small server part):
1. **Where they walk:** every road, plaza and inner path of `OwnerMapPlan` (ROADS, INNER, PLAZAS), as lanes:
   - each walker keeps to the right half of its path, about 1.5-3 studs from the kerb, never on the grass or in a junction's middle;
   - at a junction it picks a next leg (mostly straight on, sometimes a turn), so they spread over ALL paths;
   - they never walk through a machine, a bench or a lamp: the lanes come from the plan's path legs, and anything standing on a path is avoided by a sideways lane offset;
   - pairs and threes walk side by side.
2. **How many** (per device, measured in Studio and on the phone emulator):

   | Device | Path walkers alive | Full animation | Simple animation | Far (no limbs moving) |
   |---|---|---|---|---|
   | Phone | 14 | within 50 studs, 15 Hz | 50-120 studs, 8 Hz | 120-250 studs, 4 Hz |
   | Tablet | 20 | within 60, 20 Hz | 60-150, 10 Hz | 150-300, 5 Hz |
   | PC | 30 | within 80, every frame | 80-180, 15 Hz | 180-350, 6 Hz |

   The quality governor (`PERF_MOBILE.md`) may lower these numbers when the FPS drops. It does so by letting walkers leave out of view, never by deleting them in view.
3. **Placed where you look:**
   - **Never an empty path in view:** the scheduler checks the paths within the camera's view (the frustum, up to the far band) every 2 s. A visible path leg with no walker gets one, placed where you do not see it appear: behind a tree belt, round a corner, at the far end of the leg beyond the fog, or behind the camera.
   - The boulevard from the spawn always has 4-8 in view.
   - **Recycled, never popped:** a walker that has walked out of view and is more than 60 studs away goes back to the pool and is placed again somewhere useful. Nothing appears or vanishes on screen (`RAGDOLL_DIRECTOR.md` Part C rule 1).
4. **Cheap by design:**
   - one pool, made once at start (the model cloned N times);
   - every part Anchored, CanCollide, CanQuery, CanTouch and CastShadow off;
   - moved with ONE `Workspace:BulkMoveTo` per update for all roots;
   - limbs posed with Motor6D `Transform` only in the full and simple bands; a shared walk cycle with a per-walker phase;
   - updates staggered over frames (a walker's update rate by its band);
   - no sounds and no bubbles (the real ragdolls talk);
   - a MicroProfiler label `PathLife`; the budget is under 0.6 ms a frame on a phone with all walkers.
5. **The swap to a real ragdoll (invisible):**
   - When a path walker comes within 30 studs of you (or 45 in front of your moving vehicle), or you aim at it (crosshair or touch aim within 2 studs), your client asks the server (`Net` remote `PathLife.Real`, validated: the position must be on a plan path within 60 studs of you, rate-limited to 2 a second) for a pooled real ragdoll at the same spot, heading and walk phase.
   - The real one appears standing in the same pose, and the fake hides in the same frame as the real one replicates. They look identical, so nobody sees a swap.
   - The real one walks on along the same lane and is a normal ragdoll (DRAWN TO YOU, the caps).
   - **The caps win:** if the nearby cap is full, the walker turns off the path onto a side leg before 30 studs, instead of becoming real.
   - A shot at a fake that hits before the real one exists is applied to the real one at once (the server spawns it at that spot and applies the hit).
6. **Behaviour that makes it feel alive:**
   - a calm walk, varied speed (0.85-1.15), now and then stopping at a bench, a fountain or a junction to chat in a pair (gestures only, no bubbles: the real ones talk);
   - one waves at you from far away;
   - they step aside for you, other walkers and vehicles, and wait at road crossings for cars.
7. **Every device:**
   - the same people on phone, tablet, PC and console; only the numbers in step 2 differ;
   - in the multiplayer lab each client draws its own path walkers; only the real ones are shared.
8. **Section 3's real road walkers** keep their role close to you (they ARE the real ones); beyond about 60 studs, the path walkers do this job.

**Check:**
- **phone emulator:** walk out of the spawn. The boulevard has people walking on it far ahead; every path you look down has someone on it; the FPS stays where it was without them. Walk up to one: it is a real ragdoll you can hit;
- **PC:** the same, with more of them;
- no one appears or vanishes in view; no one walks on grass, in flower beds or through things.

