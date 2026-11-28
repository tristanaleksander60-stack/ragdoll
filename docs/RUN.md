# RUN.md: the ONE ordered to-do list (from 28 Nov)
This file replaces every banner in OVERVIEW and NOW and the item lists in FIXES_27NOV_LATE and FIXES_28NOV as the place that says what to do next. Those docs stay as background (grep them for detail). If anything else disagrees with this file, this file wins.

## WHO DOES WHAT
- **The cloud session** reads the code, finds the causes, and writes most code changes. It cannot run Studio.
- **Claude Code on the PC** does what needs Studio:
  - pushing and running the code (one Play);
  - tuning numbers by looking;
  - models: Blender and the Creator Store;
  - animation clips;
  - captures and proofs.
- **When an item says "Cause found (cloud)"**, do not search again: confirm it in one Play, then build and prove it. If the confirmation shows the cause is wrong, say so in the State, find the real one, and fix that.

## Rules for every run (no exceptions)
1. **Preflight** (always first; nothing else before it):
   1. `git pull --rebase`.
   2. List the `.luau` files that commits NOT made by you changed since your last commit: `git log <your last commit>..HEAD --format=%ae --name-only`, keeping the authors that are not your own email.
   3. Push each of those files into Studio through the MCP, with a length check.
   4. Parse every one before pushing: `stylua --syntax Luau - < file > /dev/null` (a non-zero exit is a syntax error: fix it first).
   5. One Play. Read the output. Fix every error before anything else.
2. **Do ALL batches in one run, without stopping between them.** The owner checks only at the end. The final message is ONE Danish test list for everything built, numbered, phone first, each line saying where to go and what must happen. Stop early only if Studio or the MCP cannot be reached after 3 tries.
3. **DONE = proof.** An item is DONE only with:
   - a capture taken from the angle the item names, showing it working;
   - one line saying what the capture shows.

   Code that is merely "in" is not DONE. If you cannot get a capture that shows it working, the item is NOT DONE: say so in the final message.

   **Before the final message,** run the SMOKE ROUND one last time. In the test list, put the `OWNER CHECK` items first and every LEFT item with what is missing.
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

## HOW TO PROVE THINGS THE MCP CANNOT CLICK (learned 28 Nov: the MCP's mouse does not reach the game view)
- **Drive it from code during Play** (the command bar or a temporary test script, removed after):
  - fire the REAL remote the button fires (for example the Session "Try" remote, `Net.event(...)`);
  - or call the module function the input calls (for example `TimeDial.quick(0.5)`, `FirstPerson.toggle()`);
  - then read the state (attributes, positions, CFrames) AND take the capture.
- **Phone:** if the MCP can switch Studio's device emulator, capture in it. If it cannot, say so once, and for touch-only items read the touch layout from code (`HudSlots.context(true, false)` with a 390 x 844 viewport) and put the item under "OWNER CHECK: phone" in the final list.
- **Feel items** (scrolling with a real wheel or finger, steering, pinch, how smooth it feels): build them, prove what code can prove, mark them `OWNER CHECK` and list them first in the final test list. Never write DONE for a feel item.

## SMOKE ROUND (after EACH batch: about 3 minutes, catches what one item broke in another)
One Play, then all 10, with a capture each and errors read from the output:
1. Spawn: no error in the output.
2. Shoot a ragdoll 5 times: holes and blood, and it falls.
3. Grab one and drop it into the nearest machine: the DROP HERE sign, and the machine takes it.
4. TRY at a machine.
5. X-ray on and off.
6. Ride the bicycle 10 s.
7. First person in and out (V).
8. Stand 30 s at the spawn: count the ragdolls within 45 studs.
9. A standing ragdoll from the side (upright).
10. FPS at the spawn.

If any step fails, fix it before the next batch: it is a regression from this batch.

## WORK ORDER INSIDE A BATCH (saves Studio pushes)
Group the items that touch the same files and do them together:
- **SmoothBody, DummySkins and BloodFx:** 1.13 holes + 2.2 bandages + 2.4 skull.
- **Viewmodel and IK:** 1.1 arms, then reuse the same IK for 1.6 bike hands.
- **ActiveRagdoll, DummyLife and Poses:** 1.10 + 1.12.
- **Lab, RagdollDirector and Watchers:** 1.5 + 1.11 + SPAWN_V2.

## STATUS KEY
`TODO` not started · `CLOUD` code written by the cloud, untested (push and prove it) · `BUILT` built by the PC, not yet proven · `FAILED` the owner's test showed it still broken (the cause was not found: find it) · `DONE` proven with a capture

---

## BATCH 1 (do now)

### 1.1 First-person arms: DONE on PC (`FP_REAL_ARMS`, Viewmodel)
- **State (PC, 28 Nov, v1434):** captures fp_arms_sky (pistol) and fp_arms_bow show the player's own dark R15 arms: the right hand on the grip, the left under the barrel or by the bow; the weapon low right and clear of the middle. Phone: OWNER CHECK (the emulator was off in this run).
- **State (PC, 28 Nov, v1433):** built as written:
  - the player's own R15 arm and hand MeshParts, cloned at 0.6 (phone 0.52), in the viewmodel Model with a Humanoid, BodyColors and the Shirt;
  - two-bone IK, with each shoulder placed behind and below its hand at 92% of reach, so it always reaches;
  - the weapon at 0.55 of the old size (phone 0.45), low right;
  - a 2.5-stud wall ray pulls it back and down;
  - Forearm/SupportArm are hidden.

  Measured in Play (phone emulator, the pistol): the right hand is 0.14 from the grip and the left hand 0.16 from the fore-grip; no errors. NO CAPTURE: the Studio viewport stopped drawing 3D (white in every capture, Play and Edit) from this point, so it is not proven. OWNER CHECK, and the next run captures it.
- **Cause found:** in `Client/Viewmodel.luau` the arms are two plain `Part` blocks (`Forearm`, `SupportArm`) stretched between fixed points, and the right one is not at the grip. The owner's capture shows a floating pistol and a white block.
- **Build:**
  - a viewmodel Model in the camera with its own Humanoid;
  - clones of the player's own R15 arm and hand MeshParts, with a copy of the character's Shirt so the sleeves draw;
  - two-bone IK: the right hand on the weapon's grip, and the left hand on the fore-grip for two-handed weapons;
  - the weapon at about 0.55 of today's size, low right, never covering the middle third of the screen; on a phone 0.45 and clear of SHOOT;
  - sway, recoil, the reload dip and ADS kept: in ADS the weapon's sight lines up with the crosshair;
  - every viewmodel part is in the Camera, with `CanQuery`, `CanTouch` and `CastShadow` off (nothing in the world hits or shadows it);
  - near a wall (a ray 2.5 studs ahead hits), the weapon pulls back and down instead of poking through the wall;
  - the real character's arms stay hidden in first person (LocalTransparencyModifier), so there is never a double arm;
  - `Forearm` and `SupportArm` deleted.
- **Proof:** captures of the pistol, rifle, minigun, a melee weapon, the fart gun and a throwable, on PC and on a phone. The hands are visibly on the weapon; nothing white or blocky.

### 1.2 Leaving first person with V and the eye: DONE on PC (`FP_EXIT_FIX`, FirstPerson, FirstShotFP)
- **State (PC, 28 Nov, v1431):** in Studio. Keys V in/out/in/out: the camera goes 12.5 → 0.5 (LockFirstPerson, the gun in view) → 10.0 (Classic, behind you, the gun in your hand) → 0.5 → 10.0. Captures fp_in2 and fp_out show it. The phone eye is not tested.
- **Cause found:** the camera kept for leaving was itself first person (LockFirstPerson, or a max zoom squeezed by the weapon-pick glide). V hid the gun and kept the camera in the head.
- **Proof** (a capture after each step):
  - on PC: pick a weapon (in), V (out: the camera behind you, the gun in your hand), shoot (still out), V (in), V (out), pick another weapon (in);
  - the same on a phone with the eye.

### 1.3 Walking upright: DONE (`UPRIGHT_WALK`, ActiveRagdoll)
- **State (PC, 28 Nov, v1431):** in Studio. ChestBalance is on 9 bodies; of 3 moving bodies, 0 lean back (all lean forward). A follow capture shows a walker upright mid-stride. CPR, bench and boxer are not checked.
- **Causes found:**
  - the walk lean went BACK on any slowing or turn (`R.lean` from negative acceleration);
  - only the pelvis was held upright, so the chest hung back when the drive pushed the hips.
- **Now:** the lean is forward-only (about 2 degrees at a walk, about 6 at a run). A `ChestBalance` holds the chest to the pelvis's upright, ONLY while the drive is on (walking or fleeing), so CPR, the bench, the newspaper and the boxing crouch keep their bend.
- **Proof:** side captures of 5 walking, one running to you, one stopping and turning, a CPR, a bench sit and a boxer. None leans back; the bends are unchanged; standing still does not rock.

### 1.4 The face on the round head: DONE (`FACE_ON_SKIN`, SmoothBody)
- **State (PC, 28 Nov, v1431):** in Studio. The FaceSkin Decal is on the Ball part. Captures from 30 and 45 degrees show the face on the curved head, not sticking out.
- **Cause found:** the face was a flat SurfaceGui on a ball. It touches only the front point and sticks out from the side.
- **Now:** a Decal on the ball, following every expression; the crash marks are on the ball; a far (dropped) body gets its gui face back.
- **Proof:** 3 ragdolls from the front, 45 degrees and the side, talking and changing face. If the decal stretches badly at the edges, use a sphere MeshPart with a front-cap UV and the face on it. Never a flat gui on a round head.

### 1.5 Too many ragdolls by you: PART (`NEARBY_CAP_V2`, RagdollDirector `capStepV2` + `room()`, `SPAWN_ROOM` in VisitorService)
- **State (PC, 28 Nov, v1431):** in Studio. At the spawn: 2 bodies within 45 studs in every 5 s sample for 40 s (phone cap 5); a capture from above shows no crowd. NOT checked: a machine or the ring.
- **Causes found:**
  - almost everyone near was exempt from the cap: running to you, shot in the last 60 s, any Role3, any watcher;
  - bodies sent away were called back by about 35 systems that write `Home`.
- **Now:**
  - counted: every living body within 45 studs, plus the ones on their way to you;
  - kept: held, in a machine or the ring, a demo or TRY, shot in the last 8 s, and the 2 nearest talkers;
  - the extras walk 90 studs away, and for 30 s any `Home` set near a player is put back.
- **Watch for this risk:** ALWAYS3 may pick a body that was just sent away and keep re-picking it. If it does, make its picker skip a model with an active send-away (expose `RagdollDirector.leaving(m)`).
- **Proof:** stand 2 minutes at the spawn, at a machine and at the ring; one capture each, counted. Never more than the cap (phone 5 / tablet 6 / PC 8) plus the machine's own bodies.

### 1.6 The bike and motorbike rider: DONE (`BIKE_SEAT_FIT` + PC `RIDE_ARMS_FIT`)
- **State (PC, 28 Nov, v1434):** Motorbike capture bike_follow: on the saddle, hands on the bars, feet on the pegs. Bicycle: the cause of hands in the air past the bar was Poses.ride's one fixed reach (shoulder 80, elbow 10). Fixed: RideArms (52, 34) for the bicycle, read by DummyLife and ActiveRagdoll. Capture bicycle_arms shows the hands at the grips. Also found: the newspaper carrier could be picked as a rider (BikeService.free did not check Paper) and rode off holding the paper; now excluded.
- **Cause found:** the rider was welded at a fixed offset (0, 2.4, 1.1) from the physics box, which is behind the saddle on these models. Now the pelvis sits on the vehicle's own seat part.
- **Also check:**
  - the seat part is at the saddle on the bicycle AND the motorbike: VehicleService's seat may sit in the middle of the physics box. Find the saddle in the LOOK model (a part named Seat or Saddle, else the highest part between the two wheels) and move the seat part to its top, then capture it;
  - the hands reach the handlebar grips (IK, as in 1.1);
  - the feet are on the pedals or pegs.
- **Proof:** side and front captures of both rides, riding and turning.

### 1.7 The leaderboards scroll: LEFT, scroll not proven (`BOARD_SCROLL`, Client/BoardScroll)
- **State (PC, 28 Nov, v1431):** in Studio. All 4 Board guis are in the PlayerGui, adorned, with no duplicates and none left in Workspace; the list is 768 tall in a 196 window. Two tries with the MCP mouse wheel did not reach the board (the injected mouse does not land in the game view), so the scroll itself is unproven: the owner tests it.
- **Cause found:** a SurfaceGui in the Workspace gets no input. Every `Board` gui is now moved into the PlayerGui, adorned to its panel.
- **Proof:** scroll each board with the wheel on PC and by drag on a phone. Captures before and after the scroll.

### 1.8 Animals really take ragdolls in the mouth: PART (`CREATURE_GRIP` + PC MouthBone)
- **State (PC, 28 Nov, v1435):** cause found: CreatureGrip.mouthOf matched only parts or bones named Jaw/Mouth/Head, but the real T-rex's bones are "Bone.008" and the like, so the grip fell to the box's front and the body hung at its chest (capture rex_grip). Fixed: a "MouthBone" attribute (TRex = Bone.023, the jaw tip) plus "MouthOffset" (0, -1.5, -3.5), set on V3Assets.TRex in the place file. Capture rex_grip3: the body is held at the open jaws. The bear is NOT re-checked.
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
- **NEXT for 9/10: see 2.6** (every killer gets its own choreography). Detail kept here:
  - **Every killer gets its own real animated choreography:**
    - rigged models (Bones or Motor6D for the head, jaw, legs, tail) and AnimationController clips: idle, walk, charge, rear, bite-shake, roar, eat;
    - the bear stands on its hind legs, swipes, mauls and drags the body into its cave;
    - the T-rex stalks, roars, bites, sometimes gulps and spits the body out later;
    - the crocodile does a death roll with a leg in its jaws and drags the body under;
    - the spider wraps the body in a cocoon;
    - the plant chews.
  - Each one unique, with wounds, bone breaks (2.3) and sounds.
  - List every machine and animal that "kills", and give each its own choreography, worst first.

### 1.9 TRY and machine buttons: the ragdoll walks there and hops in: PART (`TRY_WALK` + cloud `CALLED_WALKS`, TRY_REACH 80)
- **State (PC, 28 Nov, v1432):** Re-test through the real Session "Try" remote at the bowling lane: the trace is 5/h5 Standing Demo, then 1/h5 Ragdoll, then Getting up, then Standing. So the body now walks to the spot and hops onto it, which confirms CALLED_WALKS is the cause of the "stands still" bug. No capture: the Studio viewport stopped drawing 3D (white) at this point. OWNER CHECK.
- **State (PC, 28 Nov, v1431):** in Studio, through the real Session "Try" remote. Found:
  - (a) tryWalk returns false, and the OLD call runs (Home by the player), when no DROP HERE spot is within TRY_REACH 45 of you or no free body is within PICK_REACH 120;
  - (b) next to the Shredder with a free body 24 studs away, tryWalk sets Watch=Demo and Home = the spot + 5, but the body stays Standing and never walks; after about 3 s walkIn's loop ends and clears Watch.

  NEXT: find why a body with Watch="Demo" and a new Home does not walk (client DummyLife / RagdollNav for Watch bodies?), and why walkIn's loop breaks early (RagdollState?).
- **Causes found:**
  - TRY's `pickDummy` skipped every Role3 (the ragdolls standing by you) and only searched an old list of machines, so the new map's machines were never found;
  - Bowling's and MapMachines' callers skipped watchers, anyone within 8 studs of a player and anyone in a mood, within only 40 studs, and gave up after 8 s ("No ragdoll near!" with one right there);
  - after walking up, the body was TELEPORTED in (`DummyControl.move`), which looks like a spawn.
- **Now:**
  - TRY takes the nearest DROP HERE spot in your lab (every machine has one) and the nearest free ragdoll to YOU (talkers too);
  - it walks there and HOPS in with a real jump onto the spot; the machine takes it as if you had dropped it;
  - Bowling and the map machines look 70-80 studs out, allow one by you and give it 16 s, and Bowling hops onto the lane instead of teleporting.
- **Proof:** TRY at 4 machines, each with one ragdoll standing by you; captures of the walk and the hop. No "No ragdoll near" with one in 40 studs.
- **Cloud, after the PC's finding (28 Nov):**
  - **Cause of "stays Standing and never walks":** `ActiveRagdoll.standsFirm`. A body near a player holding a weapon stands firm, facing the gun, and never walks, and the player pressing TRY always holds one. Now (`CALLED_WALKS`), a body with TryFor, Watch "Demo" or a Pace set by its caller never stands firm.
  - `walkIn` no longer gives up on a short Flinch or Fleeing.
  - `TRY_REACH` is 45 -> 80 (at 45+ studs TRY found no machine).
  - Prove it again.


### 1.10 Standing ragdolls suddenly leaning far back: DONE (`UPRIGHT_POSES`)
- **State (PC, 28 Nov, v1434):** in the toast_v2 and banner captures every standing ragdoll stands upright; none leans back.
- **Cause found:** a positive Waist X bends BACKWARDS (CPR leans forward with -43). Several standing poses had the wrong sign or far too much:
  - the Scared persona: +14, ALWAYS while standing still, the main culprit;
  - the LookBack and HoldSide gestures, meant as a hunch;
  - shock, gasp, peek and point;
  - the head flinch: Waist +14 with Neck +42.
- **Now:**
  - the hunches bend forward;
  - shock, gasp and point stay upright;
  - the head flinch snaps the head back but the body only 3 degrees.
- **The previous proof missed this:** it measured walking bodies only.
- **Proof:** side captures of a standing Scared persona, a LookBack, a shocked one (BOO), a gasp, a peek, a point and a head flinch (shoot the head). Also count, over 60 s, the standing bodies whose chest is more than 6 degrees back: it must be 0.

### 1.11 Heavy lag on a good PC, not every ragdoll drawn: CLOUD part (`LAB_DUMMIES_PC` 40 -> 18; SmoothBody PC 28 bodies within 200)
- **Causes found:**
  - the PC simulated 40 balancing ragdolls itself (each lab's bodies belong to its player's computer);
  - only the nearest 24 within 120 studs got the v6 body; the rest showed the old block body ("not all load in").
- **Now:** 18 lab ragdolls on a PC, and every one in view (up to 28 within 200 studs) wears v6.
- **TO DO:**
  - one MicroProfiler capture at the spawn on PC and in the phone emulator, before and after: name the top 5 costs in the item's State and fix the biggest;
  - check `LAGFREE_SLEEP` really anchors still bodies (count the asleep ones);
  - with 18 bodies on a PC, check the jobs still add up: ALWAYS3's 3 near you, the watchers (WATCH_EVERY) and the walkers. If the watchers take most bodies, cap them at 1 per machine and only at the machines within 120 studs of you;
  - telemetry `Fps_p10` by device.
- **Proof:** the profiler numbers and an FPS counter capture at the spawn with every ragdoll in view drawn in v6.

### 1.12 The legs still bug: CLOUD (`LEG_ONE_WRITER`, ActiveRagdoll `applyPose`)
- **Cause found (cloud):** two writers set the same leg joints.
  - `ActiveRagdoll.applyPose` writes EVERY joint each physics step, and a joint the pose does not name is set to straight. Mood poses (Angry, Box, gestures) name only the upper body.
  - `DummyLife` sets the walk or stance on the hips, knees and ankles every frame.
  - So while a mood was on, or on a frame where DummyLife skipped the body (its LOD), the legs flipped between straight and bent: the bursts of leg jitter, worst on the angry ones.
- **Now:** while a body stands, walks or flees, `applyPose` leaves the leg joints a pose does not name to DummyLife. REST and the full-body poses (falls, sitting, kneeling) still set them.
- **Confirm with the detector already in the game** (`LEG_JITTER_LOG`: the output and the player attribute `LegJitterLast`):
  1. 60 s with `LEG_ONE_WRITER = false` near an angry ragdoll and a crowd, counting the events;
  2. 60 s with it true;
  3. the count must drop to about 0. Paste both counts in the State.
- **If events remain:** the log names the state, role and Home changes; fix that cause.
- **Proof:** the two counts, and a capture series of an angry ragdoll walking with steady legs.

### 1.13 Bullet holes and bandages shown wrong: CLOUD (`ON_SKIN`, SmoothBody `watchSkin`/`drive`)
- **Cause found (cloud):** the "two bodies" problem.
  - Holes, stress rings and bandages are WELDED to the hidden physics limb.
  - The visible v6 mesh is drawn from an FK bone chain, so the drawn limb is often a few centimetres to tenths of a stud away from the physics limb.
  - So every hole and bandage sat under or over the drawn skin and slid as the body moved.
- **Now:**
  - on a v6 body, every BulletHole, BulletStress, Bandage, Plaster, Gauze and BruisePatch (or any part with the attribute `OnSkin`) welded to a limb is taken over: its weld is switched off, it is anchored, and each frame `drive()` moves it with the DRAWN limb (`BulkMoveTo`), keeping the offset it was welded at;
  - a body that drops its v6 mesh (far away) gets its welds back.
- **Still to build:**
  - bandages sized to the v6 limb radius (`BodyShape.radius`), not the old block's size (`DummySkins` uses `limb.Size`);
  - a visible plaster patch.
- **Proof:** 20 shots spread over one body; captures from the front, the back and while it walks; a patched-up body from 3 and 10 studs.

- **Two more causes found (cloud, 28 Nov late), now CLOUD (`HOLE_CURVE_FIT`, BulletHoles):**
  1. **Half inside the arm:** a v6 arm is round with radius 0.3-0.375, and a flat 0.35 hole picture lay only 0.005 off it, so its rim was about 0.05 studs inside the arm. Now the picture is at most 0.8 x the radius across and lifted by the curve's sag, so its rim touches the skin all round (the round head too).
  2. **Not shown at all:** a v6 body WITHOUT the old skins (the crowd, V6_EVERYONE) got the hole on the physics block's flat face, inside the round limb. Now it goes on the v6 limb's round surface round the part's axis.
- **Proof:** 5 shots on each arm and each leg of a lab ragdoll AND a crowd person; captures from 3 studs, front and side.
### 1.14 The spawn arch banners half inside the pillars: DONE (`BANNER_CLEAR`)
- **State (PC, 28 Nov, v1434):** capture banner_side: the banner hangs from its rod, clear of the pillar's face.
- **Cause found:** the banner hung 0.075 studs off the pillar, and its "Swing" (0.06 rad round its top) moved its bottom about 0.5 studs, into the stone.
- **Now:** it hangs from a steel rod 0.5 studs out and sways at 0.02 rad.
- **Also:** check every other part tagged "Swing" (flags and banners) the same way: gap > Amp x length + 0.1.
- **Proof:** captures of all 4 banners from the side, 10 s apart.

### 1.15 Orange boxes round the map: TODO (the source is not in the code the cloud could find: find it in Play)
- **The cloud checked:** WorldDress crates, the LabOwnerMap crates (brown wood), Breakables (wood), Knockables, Surprises and ToyService. None is a plain orange cube, so it is most likely a placed model (V3Assets or LabDress) or a player-built Crate (BuildService).
- **Find it** by pasting this in the command bar during Play:

  ```lua
  for _, p in workspace:GetDescendants() do if p:IsA("BasePart") then local h, sat = p.Color:ToHSV() if h > 0.05 and h < 0.12 and sat > 0.5 and p.Size.Magnitude > 3 and p.Size.Magnitude < 12 then print(p:GetFullName(), p.Size) end end end
  ```
- **Then remove them at their source** behind `Config.NO_ORANGE_BOXES` (never delete from the place file).
- **Proof:** the printed list empty, and captures of the spots.

### 1.16 The man-eating plant: DONE (`PLANT_REAL`)
- **State (PC, 28 Nov, v1434):** capture plant_front: only the real plant model, no floating part jaws. PLANT_YAW is left at 0: OWNER CHECK whether the mouth should face the path more.
- **Causes found:**
  - plain-part jaws (green boxes, a red inside, white teeth) floated 14 studs above the real plant model: the ugly plant;
  - the real model was placed with a fixed yaw of 180, so it faced the wrong way.
- **Now:** the part jaws are hidden when the model exists, and the model faces its spot's direction plus `PLANT_YAW`.
- **TO DO:**
  - set `PLANT_YAW` so its mouth faces the path, using a capture from the path;
  - make the model itself do the bite: lean down over the body (PivotTo), `CreatureGrip.grab` into its real mouth, chew (small squeezes), spit it out.
- **Proof:** captures from the path, and mid-bite.

### 1.17 The round X-RAY button on PC: PART (`XRAY_BUTTON_TOUCH_ONLY` + `TOUCH_FIRST_DEVICE`)
- **State (PC, 28 Nov, v1432):** Phone: the round button shows (hud_phone2). PC: OWNER CHECK, because the MCP cannot switch the emulator off. In code, Device "pc" hides it.
- On a computer, X-RAY is already in the bottom-left list (the I key), so the round button now shows on touch screens only.
- **Proof:** a PC capture without it, and a phone capture with it.

### 1.18 The rocket: the whole rocket flies, a ragdoll walks to it, and YOU steer it: CLOUD part + TODO
- **Causes found** (`RocketRide.luau`):
  - `rocketParts` only took parts within 0.8 column widths, narrower than 1.5 widths and below 1.6 x the stack, so the capsule and nose on top stayed on the tower;
  - the nearest dummy was never walked over: a still copy was strapped on at once;
  - the flight is a fixed server animation with no steering and no camera.
- **CLOUD:**
  - `ROCKET_WHOLE`: every part over the rocket's footprint, narrower than 2.2 widths, up to 3 widths over the stack, flies;
  - `ROCKET_WALK`: the chosen ragdoll walks to the rocket's foot (up to 14 s), then it is strapped on.
- **TODO, the PILOT** (`Config.ROCKET_PILOT`; build and prove it in Studio):
  1. **At ignition:** weld the flying set into ONE unanchored assembly (the rocket, the strapped body copy, the straps), give it a `LinearVelocity` thrust along its nose (ramping up to about 90 studs/s) and an `AlignOrientation`, and `SetNetworkOwner(player)` so the pilot's screen flies it smoothly.
  2. **Client `RocketPilot`** (while the player's attribute `Piloting` is set):
     - **the camera** is a CHASE camera: behind and a little above the RAGDOLL on the rocket, looking along the nose, so you see where you steer (never first person);
     - **steering:** mouse or WASD on PC; on a phone, the move stick (or tilt); they turn the `AlignOrientation` target (turn rate about 90 degrees/s, it cannot loop under the ground);
     - **a small HUD:** height, speed and a BOOM button (detonate now).
  3. **The end:**
     - it hits something (a Touched on the nose, or a ray ahead each frame), or the fuel runs out (10 s), or BOOM is pressed;
     - the client sends `Rocket.Boom(position)` through `Net` (validator: within 30 studs of the server's view of the rocket, once per flight);
     - the server makes a big explosion with fire and smoke, knocks nearby ragdolls flying, flings the real body out of the blast (wounds, mild), and the camera stays on the blast for 2 s, then returns;
     - the rocket fades back onto its tower after 4 s.
  4. **Safety:**
     - only the lab's owner pilots;
     - a flight that leaves the map's bounds explodes;
     - the server checks every remote.
- **Proof:**
  - a capture series: the walk-up, the strap-on, the lift-off with the whole rocket (the top included), the chase camera mid-flight on PC and on a phone, and the explosion;
  - steering left, right and up must visibly change the flight.

### 1.20 The phone's left buttons and the hotbar icons: DONE in the phone emulator (`REVIVE_OVER_SHOP`, `MP_SHORT_LABEL`, `HOTBAR_ICON_CENTER`, + PC `TOUCH_FIRST_DEVICE`)
- **State (PC, 28 Nov, v1432):** Cause found (PC): every phone-only rule asked "TouchEnabled and not KeyboardEnabled", which is false in Studio's phone emulator and on a tablet with a keyboard, so the rules never switched on there. Fixed: Shared/TouchFirst reads the Device attribute (phone/tablet) first (`TOUCH_FIRST_DEVICE`), used by XRayToggle, HudV3, PortalUI and PokeController. The capture hud_phone2 shows "Online" (not "Multipla"), no More gear in the top bar, the round X-RAY button, and hotbar pictures centred. REVIVE only shows when needed, so it is not in the capture.
- **REVIVE:**
  - **cause:** a fixed offset (142, 66) put it to the right of Weapon;
  - **now:** it is measured from where Shop and Weapon really are, centred over the two of them, right above them.
- **"Multipla":**
  - **cause:** the caption "Multiplayer" was cut off on a phone;
  - **now:** it reads "Online" on touch screens; the button keeps its name.
- **The hotbar icon:**
  - **cause:** a slot whose word was not empty put its picture at the left (`placePicture`'s else branch), small, in the top-left of the selected box;
  - **now:** on touch screens every picture is centred. Also measure the slot gaps at rest and open (at least 6 px apart; the ammo chip inside its slot). If they still overlap, find the cause in `PokeController.plan` (the cell and GAP at the MiniBar's 0.6 scale) and fix it.
- **The extra "More" gear** (`MORE_GEAR_PC_ONLY`): on phones and tablets the round More gear in the top bar duplicated Menu in the left stack, so it now shows on computers only. Check that `gearGui` is not used to place anything else on touch screens (it is disabled there, not removed).
- **Proof:** phone captures of the top-left buttons and the hotbar at rest, opened and with each slot selected.

### 1.21 Notices: DONE on PC (`TOAST_V2`)
- **State (PC, 28 Nov, v1434):** capture toast_v2: "EARTHQUAKE +5 KOs" centred under the top bar, as a rounded pill, the reward in gold.
- **Cause found:**
  - `HudSlots.toastBox` placed the middle between the old chaos meter and the View/Replay slots, so it was off centre;
  - the card had a coloured strip down its left edge.
- **Now:**
  - always the screen's middle;
  - a rounded dark pill with a thin edge in the message's colour;
  - centred text;
  - "NAME: +N KOs!" reads "NAME  +N KOs", with the reward in gold.
- **Also check:**
  - every other notice still fits (long lines wrap, 14 px at the least);
  - it never covers the KO pill at the top or the hotbar.
- **Proof:** captures of 3 different notices on PC and on a phone (upright too).

### 1.22 The angry friend punches the air instead of you: CLOUD (`ANGRY_HITS_REAL`, Mourning; RagdollDirector `keptV2`)
- **Causes found:**
  1. NEARBY_CAP_V2 counted the revenge attacker as an extra near you and sent it away, and for 30 s put its Home back away from you, so it stood off and punched the air. Now any body with a Mood (angry, mourning, CPR...) or CommandedBy is kept.
  2. Its shoves set the player's `AssemblyLinearVelocity` on the server, but the player's body belongs to their own screen, so nothing moved. Now the shove and every 2nd landed punch go through `PlayerRagdoll.knock` (the player's own screen), with the damage as before.
- **Proof:** kill a ragdoll next to its friend; capture the friend coming to you, landing punches and knocking you over; the health bar going down.

### 1.23 Dead ragdolls frozen in the air; turning to the shooter; madder when shot: CLOUD (`SLEEP_LYING`, `FACE_SHOOTER`, `ANGRY_MORE`)
- **Frozen in the air.** Cause found (cloud): LAGFREE_SLEEP anchored ANY dead or knocked-out body that was still for 1.5 s (`DummyControl.canSleep`), also one propped on a friend's hand, leaning, or mid-fall, so it hung frozen in that pose. Now it sleeps only when the chest is near flat and has ground within 2.5 studs under it, and is not lying on another ragdoll.
- **Turning to the shooter.** Cause found (cloud): after a hit, `standsFirm` faced the NEAREST person within 70 studs, often someone else, and never a far shooter. Now it faces the player who shot it (`ServerHitBy`), up to 160 studs. Scared ones (runners) still run.
- **Madder.** The chance to get mad when shot is now 15 % fresh, rising to 60 % near death (was 3-35 %); up to 3 mad at once in a lab.
- **Proof:**
  - knock one out while another holds it: it falls and lies, never hangs;
  - shoot one from 60 and from 120 studs: it turns to you;
  - shoot 10 ragdolls each twice: count the mad ones (about 2-4).

### 1.19 Carried over from FIXES_28NOV: re-check each one (they were built, the owner did not confirm them all)
For each: one capture showing it working, and the switch. If it is broken, find the cause and fix it here. A line per item in the final message.
- `WORLD_POPS` off: no floating texts at any machine (DROP, SMASH, TAIL SLAP, RPM, CRACK, the rocket countdown).
- `CARRY_FLOOR_RAY`: carry a ragdoll under the bowling canopy and up every tower floor; it stays in front of you, never on a roof.
- DROP HERE (`DropSpots`): ONE sign at each machine when carrying, the bear's in front of its mouth.
- `PLAYER_SWIM`: fall into the aquarium, swim, and jump out on every side; the 25 s safety net.
- `STAIR_OPENING`: walk up the aquarium stairs onto the platform.
- `PARKING_STRAIGHT`: a top-down capture of the lot; each plaque in front of its vehicle.
- The 5 vehicle passes:
  - each prompts the right pass id;
  - each plaque shows its price;
  - the Ford follows its pass when it is on sale.
- The time chips (5b): 0.25x, 0.5x, 1x, 2x and STOP, in any order; the lit chip is the real speed.
- Build mode (5c): the DONE button on every device.
- `FP_AUTO` (5d): a weapon pick puts you in first person; after V out, a shot keeps you out until the next pick. The eye button is on the phone.
- `HOTBAR_3D` off (5e): no turning 3D gun. The slots never overlap at rest or open, on a phone: measure the gaps (at least 6 px).
- **Plain-part buildings and machines:**
  - the gyro (`GYRO_STYLE`) and the weapon range (`RANGE_CLEAR`): the range must stand free with a path to its door, and its shell must be a real model, not plain parts;
  - the T-rex (`REX_ANIM`): it idles and roars.

---

## BATCH 2 (straight after batch 1, no stop)

### 2.1 "Sitting behind the bench": CLOUD part (`HIDE_TALL_COVER`, Personas `hide`)
- **Cause found (cloud):** the owner's capture is a SCARED ragdoll HIDING (SCARED_HIDE). It took the nearest anchored part at least 3 studs tall and 2 wide as cover, and benches, lamp posts and signs counted, so it stood behind a bench and peeked over it.
- **Now:** cover must be taller than its head, at least 1.5 studs thick both ways, and never a bench.
- **Also check** the real bench sitting (BenchService). Its seat height comes from the OLD limb sizes. On the thicker v6 body, check in a side capture that the hips are on the planks and the back is not inside the backrest; if not, add the v6 hip depth to `seatHeight` and move the seat point 0.25 studs forward.
- **Proof:** a scared ragdoll hiding behind a wall or tree; 3 benches with sitters, from the front and the side.

### 2.2 Bandages and plasters that sit right and can be seen: FAILED (FIXES_28NOV 11 built) (now done as 1.13)
- **Find the cause:** the capture shows a gauze floating as a flat box off the arm, and no plaster at all.
- **Build:**
  - **the bandage:** a ring mesh around the v6 limb, its axis along the bone, its radius the v6 limb radius at that point (BodyShape) + 0.02, moved with the bone in SmoothBody's drive;
  - **the plaster:** a small rounded beige patch mesh ON the skin at the wound point, aligned to the surface, visible from 30 studs.
- **Proof:** a patched-up arm, leg, chest and head from 3 m and 10 m.

### 2.3 Bones break by weapon and by number of hits: TODO (cause found by the cloud: the numbers)
- **Cause found (cloud):** the bone system works (`Systems/Bones.luau`, BONES_V2): 0 integrity means BROKEN, `BreakReq` set, and the joint broken. But with the current numbers a body dies or is revived before a bone breaks:
  - a light pistol (`Blaster` 18 x factor about 1.1) needs about 5 shots on one lower leg;
  - an auto weapon needs about 10;
  - every heal or revive resets the bones.

  On v6 bodies the crack visuals must also show on the X-ray bones in use.
- **Fix: retune `Bones.CLASS`** so a fresh limb bone breaks after:

  | Weapon | Hits on one bone to break it |
  |---|---|
  | light pistol | 3 |
  | heavy pistol | 2 |
  | auto | 6 |
  | rifle | 2 |
  | shotgun or sniper | 1 |
  | bat or club, at full charge | 2 |
  | fists | 6 |

  - Example values: Blaster 32, Deagle 48, SMG 16, DMR 50, Shotgun 100, Bat {30, 55}, Punch {6, 18}.
- **Check that a limb hit does not kill the body before the bone goes** (VitalsService blood loss per limb round). If it does, lower the limb blood loss, not the bone numbers.
- **Visible:**
  - the CRACKED and BROKEN stages on the v6 X-ray bones;
  - a dangling broken limb;
  - a limp;
  - the crack sound.
- **Proof:** shots counted to the break for each class; X-ray captures of cracked and broken; a limp walk.

### 2.4 The whole skull in the X-ray: FAILED (half the skull shows); cause candidates from the cloud
- **What the code does:** the skull (SmoothBody `roundHead`) is a 1.22-stud bone ball centred inside the 1.7 round head, with eye holes and a jaw, so the code alone does not explain a missing top.
- **Test in ONE Play** (X-ray on, a capture after each):
  1. the old Head's X-ray glass shell (DummySkins) drawn opaque over the top: set it to Transparency 1;
  2. the round head ball not taking the X-ray transparency at the top (an accessory lifted by `raise`, a hat);
  3. a CrashMark gui on the ball covering it in X-ray.
- **Fix the one that shows the top.** Make it read as a skull: a cranium, cheekbones, the eye holes, and the jaw with teeth.
- **Proof:** X-ray captures from the front, the side and above.

### 2.5 SPAWN_V2: how ragdolls spawn and gather, done properly (see the design below). Steps 2-3 in this batch.

### 2.6 Every killer has its own real, creative death: TODO (the list from the cloud)
**The killers:**
- **Creatures** (`LabCreatures BUILD.*`): Chicken, Frog, Mole, Plant, Slingshot, Spider, Vacuum, Washer, Whale.
- **Animals** (`AnimalCove`): Bear, Crocodiles, T-rex (bear and T-rex already use CreatureGrip).
- **Machines:** MapMachines (the Gyro and the map machines), StretchMachine, Compressor, FanMachine, WhaleSpout, LavaPit, RocketRide, BrickWall, Bowling, BoxingMatch.

**The rule for all:**
- the body is taken by the killer's real part (mouth, claws, rollers, jaws, web) through `CreatureGrip` or a weld, never teleported;
- real wounds and bone breaks (2.3);
- a unique sound;
- no floating text;
- at least 3 beats: the approach, the kill, the aftermath.

**Ideas, one each:**
- Spider: wraps the body in a cocoon that hangs and wriggles.
- Frog: its tongue grabs from 15 studs, then a swallow and a burp, and the body is spat out.
- Plant: swallows the body and spits out bones.
- Mole: drags the body under the ground.
- Washer: a spin cycle; the body comes out dizzy.
- Vacuum: sucks the body in feet first and spits it out flat.
- Whale: swallows the body and blows it out of its spout.
- Chicken: pecks the body down.
- Crocodile: a death roll and a drag under water.
- Bear: drags the body into its cave.
- T-rex: sometimes gulps and spits the body out later.

**Proof:** 4 captures per killer, worst first; at least 5 in this run.

### 2.7 No more plain-part machines or creatures: TODO (the list from the cloud)
**Built mostly from plain parts** (parts made in the file / models placed):
- StretchMachine: 21 / 0
- ShootingRange (WEAPON TESTING): 34 / 0
- Bowling: 29 / 0
- Compressor: 23 / 2
- Playground: 83 / 6
- LabCreatures: 47 / 16
- the LabOwnerMap machines (Gyro, Sweeper, Shredder, Seesaw, the T-rex pen) and the WorldDress dressing.

**Do this:**
1. Capture each one.
2. Score it against a real reference photo.
3. Replace the 5 worst with Blender (quality gate at 8.5 or more) or malware-checked Creator Store models, keeping the gameplay parts invisible.

**Proof:** before and after captures.

---

## BATCH 3 and on
- **`RAGDOLL_V7.md`:** animated until hit, the lasting cure for jitter, lean and leg bugs (1.3, 1.10 and 1.12 are stopgaps).
  - Build ONLY the V7-1 spike in this run: the natively skinned v6 in a test model in ServerStorage (`V7Spike`), never in the live game, behind `Config.RAGDOLL_V7 = false`.
  - Make captures of 6 poses and a limp fall next to the current v6 and save them in `docs/captures/v7/`.
  - Do NOT switch the game over: the owner decides from the captures, and it goes in the final message as a question. No stop: go on with the next items.
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
   - **Visible life:** at any moment within 60 studs of you, at most 2 bodies are talking to you. Every other living body you can see is DOING something at a slot: reading the newspaper, on the phone, sitting on a bench, watching a machine, chatting in a pair, or walking a lane. None stands idle facing you. Prove it with one capture of the plaza and one of a machine area, with each body's job printed.
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
