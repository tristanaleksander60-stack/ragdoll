# RUN.md: the ONE ordered to-do list (from 28 Nov)
This file replaces every banner in OVERVIEW and NOW and the item lists in FIXES_27NOV_LATE and FIXES_28NOV as the place that says what to do next. Those docs stay as background (grep them for detail). If anything else disagrees with this file, this file wins.

## Rules for every run (no exceptions)
1. **Preflight** (always first; nothing else before it):
   1. `git pull --rebase`.
   2. List the `.luau` files that commits NOT made by you changed since your last commit: `git log <your last commit>..HEAD --format=%ae --name-only`, keeping the authors that are not your own email.
   3. Push each of those files into Studio through the MCP, with a length check.
   4. Parse every one before pushing: `stylua --syntax Luau - < file > /dev/null` (a non-zero exit is a syntax error: fix it first).
   5. One Play. Read the output. Fix every error before anything else.
2. **Small batches.** Do the next batch below (about 5-8 items, 1-2 hours), then STOP. The final message is a short Danish test list for exactly that batch: at most 12 numbered lines, phone first, each saying where to go and what must happen.
3. **DONE = proof.** An item is DONE only with:
   - a capture taken from the angle the item names, showing it working;
   - one line saying what the capture shows.

   Code that is merely "in" is not DONE. If you cannot get a capture that shows it working, the item is NOT DONE: say so in the final message.
4. **Root cause first.** Before changing code for an item, find the exact cause in the code: the file, the function and why it produces what the item describes. Write it in the item's State line. A change without a found cause is not allowed.
5. **No plain-part art** for anything a player looks at (machines, arms, props, signs, creatures): use a Blender model with the quality gate, or a malware-checked Creator Store model.
6. **No dead ends:** no blocked stairs, no pit or tank without a way out, no prompt that does nothing.
7. **Every new behaviour behind a Config switch.** Every remote through `Net`. The server decides.
8. **Phones first:** every item is also checked in the phone emulator (a capture).
9. **Never:**
   - publish;
   - force-push;
   - restart servers;
   - write to live DataStores beyond the game's own saving;
   - delete owner content without a backup.
10. **After each item:** commit, push, and update its State here (DONE with the capture's line, or LEFT with the reason).

## STATUS KEY
`TODO` not started · `CLOUD` code written by the cloud, untested (push and prove it) · `BUILT` built by the PC, not yet proven · `FAILED` the owner's test showed it still broken (the cause was not found: find it) · `DONE` proven with a capture

---

## BATCH 1 (do now)

### 1.1 First-person arms: TODO
- **Cause found:** in `Client/Viewmodel.luau` the arms are two plain `Part` blocks (`Forearm`, `SupportArm`) stretched between fixed points, and the right one is not at the grip. The owner's capture shows a floating pistol and a white block.
- **Build:**
  - a viewmodel Model in the camera with its own Humanoid;
  - clones of the player's own R15 arm and hand MeshParts, with a copy of the character's Shirt so the sleeves draw;
  - two-bone IK: the right hand on the weapon's grip, and the left hand on the fore-grip for two-handed weapons;
  - the weapon at about 0.55 of today's size, low right, never covering the middle third of the screen; on a phone 0.45 and clear of SHOOT;
  - sway, recoil, the reload dip and ADS kept;
  - `Forearm` and `SupportArm` deleted.
- **Proof:** captures of the pistol, rifle, minigun, a melee weapon, the fart gun and a throwable, on PC and on a phone. The hands are visibly on the weapon; nothing white or blocky.

### 1.2 Leaving first person with V and the eye: CLOUD (`FP_EXIT_FIX`, FirstPerson, FirstShotFP)
- **Cause found:** the camera kept for leaving was itself first person (LockFirstPerson, or a max zoom squeezed by the weapon-pick glide). V hid the gun and kept the camera in the head.
- **Proof** (a capture after each step):
  - on PC: pick a weapon (in), V (out: the camera behind you, the gun in your hand), shoot (still out), V (in), V (out), pick another weapon (in);
  - the same on a phone with the eye.

### 1.3 Walking upright: CLOUD (`UPRIGHT_WALK`, ActiveRagdoll)
- **Causes found:**
  - the walk lean went BACK on any slowing or turn (`R.lean` from negative acceleration);
  - only the pelvis was held upright, so the chest hung back when the drive pushed the hips.
- **Now:** the lean is forward-only (about 2 degrees at a walk, about 6 at a run). A `ChestBalance` holds the chest to the pelvis's upright, ONLY while the drive is on (walking or fleeing), so CPR, the bench, the newspaper and the boxing crouch keep their bend.
- **Proof:** side captures of 5 walking, one running to you, one stopping and turning, a CPR, a bench sit and a boxer. None leans back; the bends are unchanged; standing still does not rock.

### 1.4 The face on the round head: CLOUD (`FACE_ON_SKIN`, SmoothBody)
- **Cause found:** the face was a flat SurfaceGui on a ball. It touches only the front point and sticks out from the side.
- **Now:** a Decal on the ball, following every expression; the crash marks are on the ball; a far (dropped) body gets its gui face back.
- **Proof:** 3 ragdolls from the front, 45 degrees and the side, talking and changing face. If the decal stretches badly at the edges, use a sphere MeshPart with a front-cap UV and the face on it. Never a flat gui on a round head.

### 1.5 Too many ragdolls by you: FAILED before; now CLOUD (`NEARBY_CAP_V2`, RagdollDirector `capStepV2` + `room()`, `SPAWN_ROOM` in VisitorService)
- **Causes found:**
  - almost everyone near was exempt from the cap: running to you, shot in the last 60 s, any Role3, any watcher;
  - bodies sent away were called back by about 35 systems that write `Home`.
- **Now:**
  - counted: every living body within 45 studs, plus the ones on their way to you;
  - kept: held, in a machine or the ring, a demo or TRY, shot in the last 8 s, and the 2 nearest talkers;
  - the extras walk 90 studs away, and for 30 s any `Home` set near a player is put back.
- **Watch for this risk:** ALWAYS3 may pick a body that was just sent away and keep re-picking it. If it does, make its picker skip a model with an active send-away (expose `RagdollDirector.leaving(m)`).
- **Proof:** stand 2 minutes at the spawn, at a machine and at the ring; one capture each, counted. Never more than the cap (phone 5 / tablet 6 / PC 8) plus the machine's own bodies.

### 1.6 The bike and motorbike rider: FAILED (`BIKE_WELD` built), now CLOUD (`BIKE_SEAT_FIT`, BikeService)
- **Cause found:** the rider was welded at a fixed offset (0, 2.4, 1.1) from the physics box, which is behind the saddle on these models. Now the pelvis sits on the vehicle's own seat part.
- **Also check:**
  - the seat part is at the saddle on the bicycle AND the motorbike (move the seat part if not);
  - the hands reach the handlebar grips (IK, as in 1.1);
  - the feet are on the pedals or pegs.
- **Proof:** side and front captures of both rides, riding and turning.

### 1.7 The leaderboards scroll: CLOUD (`BOARD_SCROLL`, Client/BoardScroll)
- **Cause found:** a SurfaceGui in the Workspace gets no input. Every `Board` gui is now moved into the PlayerGui, adorned to its panel.
- **Proof:** scroll each board with the wheel on PC and by drag on a phone. Captures before and after the scroll.

### 1.8 Animals really take ragdolls in the mouth: CLOUD (`CREATURE_GRIP`, Systems/CreatureGrip + AnimalCove, DropSpots)
- **Causes found** (`AnimalCove.luau`):
  - the bear's HUG and the T-rex's bite teleported the body to a guessed point every 0.1 s (`DummyControl.move`) while the lab player's screen simulated it, so it jittered behind the animal;
  - no wound was ever given;
  - the bear "shook" by tilting its whole anchored model;
  - the bear's DROP HERE sat on its box middle (`DropSpots.scan` "BearPoke"), on top of the bear.
- **Now:**
  - `CreatureGrip.grab` finds the animal's real mouth (a part or Bone named Jaw / LowerJaw / Mouth / Snout / Head) and joins the bitten limb to an anchored grip in the mouth with a BallSocket. The server simulates the body while held, so it dangles and swings;
  - real bite wounds (VitalsService, mild, no severing);
  - `release` throws it and gives it back to its player's screen;
  - the bear: half the time a MAUL (lunge, chest in the mouth, 3 shakes, thrown), else a SWAT with claw wounds;
  - the T-rex: head down, the waist in its jaws, lifted, whipped left and right 4 times, tossed;
  - the bear's DROP HERE is on the ground in front of its mouth.
- **Check:**
  - the mouth is found on both models (print which part or Bone is used; if it is the wrong one, name the right one in `MOUTH_NAMES`);
  - the body never sits inside or behind the animal.
- **Proof:** captures mid-maul and mid-whip from the side, and the wounds after.
- **NEXT for 9/10:**
  - **Every killer gets its own real animated choreography:**
    - rigged models (Bones or Motor6D for the head, jaw, legs, tail) and AnimationController clips: idle, walk, charge, rear, bite-shake, roar, eat;
    - the bear stands on its hind legs, swipes, mauls and drags the body into its cave;
    - the T-rex stalks, roars, bites, sometimes gulps and spits the body out later;
    - the crocodile does a death roll with a leg in its jaws and drags the body under;
    - the spider wraps the body in a cocoon;
    - the plant chews.
  - Each one unique, with wounds, bone breaks (2.3) and sounds.
  - List every machine and animal that "kills", and give each its own choreography, worst first.

### 1.9 TRY and machine buttons: the ragdoll walks there and hops in: CLOUD (`TRY_WALK`; MachineDemos.tryAt, Bowling, MapMachines)
- **Causes found:**
  - TRY's `pickDummy` skipped every Role3 (the ragdolls standing by you) and only searched an old list of machines, so the new map's machines were never found;
  - Bowling's and MapMachines' callers skipped watchers, anyone within 8 studs of a player and anyone in a mood, within only 40 studs, and gave up after 8 s ("No ragdoll near!" with one right there);
  - after walking up, the body was TELEPORTED in (`DummyControl.move`), which looks like a spawn.
- **Now:**
  - TRY takes the nearest DROP HERE spot in your lab (every machine has one) and the nearest free ragdoll to YOU (talkers too);
  - it walks there and HOPS in with a real jump onto the spot; the machine takes it as if you had dropped it;
  - Bowling and the map machines look 70-80 studs out, allow one by you and give it 16 s, and Bowling hops onto the lane instead of teleporting.
- **Proof:** TRY at 4 machines, each with one ragdoll standing by you; captures of the walk and the hop. No "No ragdoll near" with one in 40 studs.

---

## BATCH 2 (after the owner's test of batch 1)

### 2.1 Sitting ON the bench, not behind it: TODO
- **Find the cause** in BenchService: how the sit point is computed, and that it does not use the bench model's real seat. **Fix:** every bench gets seat slots from its seat surface (a free slot per 2 studs of seat), and the pelvis is placed on the seat top, facing out, with the v6 hip height.
- **Proof:** captures of 3 benches with sitters, from the front and the side.

### 2.2 Bandages and plasters that sit right and can be seen: FAILED (FIXES_28NOV 11 built)
- **Find the cause:** the capture shows a gauze floating as a flat box off the arm, and no plaster at all.
- **Build:**
  - **the bandage:** a ring mesh around the v6 limb, its axis along the bone, its radius the v6 limb radius at that point (BodyShape) + 0.02, moved with the bone in SmoothBody's drive;
  - **the plaster:** a small rounded beige patch mesh ON the skin at the wound point, aligned to the surface, visible from 30 studs.
- **Proof:** a patched-up arm, leg, chest and head from 3 m and 10 m.

### 2.3 Bones break by weapon and by number of hits: TODO
- **Find the cause:** why no bone breaks today. Check that the server's BoneStages attribute changes on hits (BONES_V2), and that the X-ray and the joint read it.
- **The rules (`Config.BONE_BREAK`, a table by weapon):**

  | Weapon | Hits on one bone to crack it | Hits to break it |
  |---|---|---|
  | Fists | 3 | 6 |
  | Bat or melee | 1 | 2 |
  | Pistol | 1 | 3 |
  | Rifle | 1 | 2 |
  | Shotgun, minigun burst, rocket blast, a fall from over 30 studs | — | 1 |

  - The hit count is per bone, kept for 60 s.
- **What a break looks like:**
  - in the X-ray, the bone shows a crack line, then two pieces with a gap and a 15-degree bend;
  - the limb's joint goes loose (broken);
  - a crack sound;
  - the ragdoll limps or holds the arm.
- **Proof:** an X-ray capture of each stage on an arm and a leg; walking with a broken leg.

### 2.4 The whole skull in the X-ray: FAILED (half the skull shows)
- **Cause to confirm:** the skull is built at the OLD head's centre and size, so it sits low inside the bigger round head and its top is missing.
- **Fix:** build the skull in the round head's frame (the ball's centre, about 0.85 of its radius), with the cranium top, eye holes and jaw, all inside the ball.
- **Proof:** X-ray captures from the front, the side and above.

### 2.5 SPAWN_V2: how ragdolls spawn and gather, done properly (see the design below). Steps 2-3 in this batch.

---

## BATCH 3 and on
- **`RAGDOLL_V7.md`:** animated until hit. The V7-1 spike, then STOP for the owner. This is the lasting cure for jitter, lean and leg bugs; 1.3 is a stopgap.
- **`PERF_MOBILE.md` §6:** lag-free 2, the items not yet built.
- **`MILD_EXTRAS.md`:** finishing.
- **The rest of OVERVIEW's ORDER,** at THE FINISH LINE's bar.
- **DOG3 last.**

---

## SPAWN_V2: one population system (design)
**What exists now** (from the code, 28 Nov):
- **About 12 spawners**, each with its own count:
  - Lab (7-40 per device);
  - VisitorService (1-3 plus VIP);
  - CrowdService;
  - GreeterService;
  - EventService (a crowd of up to 12);
  - ChaseService (4-10);
  - HordeService;
  - StreamerService, MinigameService and ShootingRange;
  - GOD MODE (DummySpawn).
- **About 35 systems** write `Home` (where a body walks) directly.
- **Two crowd rules** (NO_CROWD in Lab, and the near cap in RagdollDirector) correct things AFTER they go wrong, while the other systems keep undoing them. That is why the crowding came back every round.

**The design: one owner of every body, `RagdollDirector`:**
1. **Budgets.**
   - A TOTAL per lab by device: phone 12, tablet 16, PC 30, lower at a low PerfLevel. Every spawner shares it, GOD MODE included; GOD MODE may take visitors' places.
   - A NEAR cap per player: phone 5, tablet 6, PC 8, within 45 studs, the incoming counted.
2. **Slots, not random points.**
   - Every place a body may be is a slot, built once from the map plan:
     - bench seats (from the seat surface);
     - the newspaper stand, phone spots and the parking lot;
     - watch rings round each machine (at most 3 a machine);
     - event rings;
     - chat pairs on the plaza;
     - walking lanes.
   - Each slot holds ONE body. Slots are at least 4 studs apart, and no 20 x 20 cell holds more than 4 slots in use.
3. **Spawning.**
   - Only when under the total budget;
   - only at a free slot at least 40 studs from every player and out of every camera (`inView`);
   - on the ground, found from just above, never inside geometry (a `GetPartBoundsInBox` check).
4. **Jobs.**
   - Each body has ONE job: Activity (at its slot), Walk, Talk (at most 2 per player), Watch (in a machine's ring slots), Event, Chase, Ride, Machine, or Held.
   - Systems never write `Home`. They call `RagdollDirector.request(job, player, n, target)`.
   - The director grants bodies: idle ones first, a spawn only if under budget, never beyond the near cap. It returns the granted bodies. `release(m)` returns a body to an activity slot.
5. **The dead.** At most 4 dead bodies within 45 studs of a player. Beyond that, the oldest unseen ones fade out after 20 s (`mayRemove`).
6. **Out of view only:** every removal, every park and every spawn happens out of every camera.

**Steps:**
1. `room()` plus SPAWN_ROOM in VisitorService (CLOUD, done in code). Add the same check to Lab FAST_THREE, GreeterService, EventService's crowd, Watchers, Personas and NearbyTwo.
2. The slot table (from `OwnerMapPlan.luau` plus the bench and machine models), and spawning only at free unseen slots. This also fixes 2.1.
3. `request` / `release`. Migrate the 8 systems that bring bodies to a player first: Lab ALWAYS3 and FAST_THREE, GreeterService, NearbyTwo, Watchers, EventService, Personas, VisitorService. The rest follow in batch 3.
4. **Proof:**
   - the same 3 standing tests as in 1.5;
   - no 2 bodies inside one slot;
   - a bench sitter on every bench in view;
   - a capture of the plaza from above.

---

## KNOWN RISKS IN THE CLOUD CODE (check these during the preflight Play)
- **ChestBalance:** it follows `Balance`, but only while `Drive` is enabled. If a state walks with the drive off (a push, a tow), it gets no chest help (fine). If any body falls over more easily, compare with `UPRIGHT_WALK = false`.
- **FACE_ON_SKIN:** confirm the Decal is drawn on the curved surface of a Ball part.
- **BoardScroll:** if LeaderboardService rebuilds a board by making a new `Board` gui, the client moves the new one too. Check there are no duplicates after a refresh.
- **PlayerSwim:** on touch, the jump button's release resets "rising". Check that holding it rises.
- **DropSpots:** the PC wired `DropSpots.scan`. Check each machine still shows ONE sign.
- **WORLD_POPS:** a machine whose text comes from another BillboardGui (not a `pop()`) still shows text: find it and put it behind the switch.
