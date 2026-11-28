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
2. **NEVER END THE RUN EARLY.** OWNER CHECK, "could not be staged", "batch closed", "needs the cloud" are NOT stop reasons (see klar.md "These are NOT reasons to stop"). The run ends only when every item in every batch and every ledger line is DONE or LEFT.
2b. **Do ALL batches in one run, without stopping between them. NEVER stop for an owner test, an owner question or a "next step needs the owner".** Put it under OWNER CHECK or Questions in the final list, pick the safe default behind its switch, and go on. The owner checks only at the end. The final message is ONE Danish test list for everything built, numbered, phone first, each line saying where to go and what must happen. Stop early only if Studio or the MCP cannot be reached after 3 tries.
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
11. **WHY THE SAME BUGS CAME BACK 10 TIMES (read this; the owner asked):**
    - **One root cause was patched 10 times instead of fixed once.** The v6 body you SEE is not where its hidden physics parts are (the arms and legs are 0.4-0.5 studs off and turned). Everything stuck on a body (holes, bandages, plasters, X-ray bones, the newspaper and phone, the face) was built on the physics part, and each report got its own offset tweak. 28 Nov: holes, X-ray, bandages and props all had this same cause. **Rule now:** anything attached to a v6 body is placed through SmoothBody's drawn frames (the stick/drive or props path: `V7_ON_AXIS`, `WRAP_ON_SKIN`, `HAND_PROPS`), never by a fixed offset from a physics part.
    - **Guesses instead of measurements.** Sway, legs and flying got 8+ patch systems, none measured which writer moves the body. **Rule now:** a physics bug is fixed only after a probe names its cause (`SWAY_PROBE`, `CALM_GUARD`); the probe's line goes in the State.
    - **DONE without the owner's case.** Captures were taken where it worked (a standing body, one angle), not where the owner saw it fail (lying, walking, the side he looked from). **Rule now:** DONE needs a capture of the OWNER'S situation from his screenshot (same place, same angle, same action) before and after.
    - **Items fell between plan docs** (FIXES_26NOV, 27NOV_LATE, 28NOV, NOW, OVERVIEW): "PART DONE" items were never picked up again (the weapon range). **Rule now:** the OWNER REQUEST LEDGER below is the checklist; a line is ticked only with a capture.
    - **The cloud broke things it did not test** (V7_SAME_FRAME hid the holes on arms and legs). **Rule now:** the SMOKE ROUND after every batch includes holes, X-ray, bandages and props on arms and legs, standing and lying.

## HOW TO PROVE THINGS THE MCP CANNOT CLICK (learned 28 Nov: the MCP's mouse does not reach the game view)
- **Drive it from code during Play** (the command bar or a temporary test script, removed after):
  - fire the REAL remote the button fires (for example the Session "Try" remote, `Net.event(...)`);
  - or call the module function the input calls (for example `TimeDial.quick(0.5)`, `FirstPerson.toggle()`);
  - then read the state (attributes, positions, CFrames) AND take the capture.
- **Phone:** if the MCP can switch Studio's device emulator, capture in it. If it cannot, say so once, and for touch-only items read the touch layout from code (`HudSlots.context(true, false)` with a 390 x 844 viewport) and put the item under "OWNER CHECK: phone" in the final list.
- **Feel items** (scrolling with a real wheel or finger, steering, pinch, how smooth it feels): build them, prove what code can prove, mark them `OWNER CHECK` and list them first in the final test list. Never write DONE for a feel item.

## HOW TO STAGE WHAT DOES NOT HAPPEN BY ITSELF (instead of "OWNER CHECK: could not be staged")
- **A bandage:** wounds make the wrap, from 2 wounds on one arm or leg of a LIVING body (DummySkins `showHurt`: `count >= 2`, and fewer than 3 shots on that piece). On the server: `VitalsService.wound(model, model.LeftLowerArm, model.LeftLowerArm.Position, nil, 0.3)` twice (low power so it lives); same for a shin and the head. Then capture.
- **A plaster:** `ActiveRagdoll.addPlaster(model.RightLowerLeg)` on the server (the screen draws PLASTER_SKIN on it), or break a bone with Bones.hit until BreakReq.
- **CPR / mourning by a bench:** spawn a body 2 studs from a bench, kill it, and put a friend 6 studs away; set the mourning chance to 1 for the test (read Mourning: its job start, or a temporary Config value), then set it back.
- **The angry friend:** `Mourning.provoke(model, player, near)` on a body by the player.
- **A ragdoll sitting on a bench:** BenchService's seat booking, called for a body next to a bench.
- **Anything with a random chance or a timer:** set the chance to 1 or the timer to 1 s for the test, then back. Write in the State what you set.

## SMOKE ROUND (after EACH batch: about 3 minutes, catches what one item broke in another)
One Play, then all 15, with a capture each and errors read from the output:
1. Spawn: no error in the output.
2. Shoot a ragdoll 5 times: holes and blood, and it falls.
3. Grab one and drop it into the nearest machine: the DROP HERE sign, and the machine takes it.
4. Drop a ragdoll on the gyro pad: it rides in the seat (no TRY any more: 0.4).
5. X-ray on and off.
6. Ride the bicycle 10 s.
7. First person in and out (V).
8. Stand 30 s at the spawn: count the ragdolls within 45 studs.
9. A standing ragdoll from the side (upright).
10. FPS at the spawn.
11. Punch a ragdoll and walk after it 10 s: it never moves away from you (0.2).
12. Read the output: every `[CALM_GUARD]` line is a bug with its cause named; fix it (0.1).
13. X-ray on: shoot an arm and a leg: the bones lie inside the limbs (0.7).
14. A bandaged forearm, a plaster, the newspaper carrier: all on the drawn body, standing and lying (0.11, 0.12).
15. Read the output for `[SWAY]` lines (0.13).

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

## BATCH 0 (28 Nov morning: the owner's newest reports; do these FIRST, then batch 1 on)
All cloud code below is pushed (`c3ab25e` and the commit after it). For each item: push the files, one Play, confirm the cause in that Play, then the proof. A cause that turns out wrong: write the real one in the State and fix that.

### 0.1 Ragdolls bug about and fly round everywhere: CLOUD (`CALM_GUARD`, ActiveRagdoll `calmGuard`)
- **PC 28 Nov (preflight: all 21 cloud files pushed, lengths match, Play clean):** CALM_GUARD caught 2 flings in about 5 min of Play, both "Standing, 42-43 studs/s sideways, vy 0, no hit": one touching OwnerGrass, OwnerRim and BaseplateEast (the map's edge), one OwnerRailPost, OwnerPlaza and OwnerGrass. Lab also logged "dummy 1/9 moving impossibly fast; sent home". So the fling source is bodies at the map's rim and by the plaza rail posts being pushed out sideways. NEXT: find what presses them there (the rim's collision or a Home set inside a post) and fix it at the source. The 2-minute capture series is not made yet.
- **PC 28 Nov, try 2: LEFT, with the findings for the cloud.**
  - **Built anyway, ON (`SETDOWN_FREE`, `RagdollDirector.setDownSpot`):** the 3 set-downs behind a player (Lab FAST_THREE, NearbyTwo, Watchers' runner) now go only onto level floor with room to stand (5 tries, else it walks in). FAST_THREE took ANY ray hit before.
  - **After it, 2.5 min of Play:** still 3 CALM_GUARD flings (33, 47, 42 studs/s). So the set-downs were not the main cause.
  - **"touch=OwnerRim" is not a clue:** OwnerRim is ONE ground slab under the whole map (857 x 2 x 800, top at -0.1), so every body standing on the ground touches it.
  - **The best lead:** SWAY_PROBE logged a Standing body with `liftMoved=61.44`, its lift's target moved 61 studs within one second while it stayed "Standing". A STAND_HOLD lift (AlignPosition, MaxVelocity 30, horizontal force 3 g) pulled to a far new spot drags the body sideways at 30-47 studs/s: exactly the flings' speed, vy 0, no hit. NEXT (cloud): find which caller moves `lift.Position` of a Standing body far (a Home change while Standing?) and make it walk instead.
  - **CALM_GUARD fault:** it stopped a body hit by a car (`touch=LabTruck.Bumper,Body,Headlight,Wheel`, v=33). A vehicle hit must count as a hit.
- **PC 28 Nov, try 3: 3 flings down to 1 in 2.5 min.**
  - **The cloud's SHOO_TO_SLOT (a948008) was missing from Studio:** it came in during a pull and was not preflighted. It is now pushed (RagdollDirector and Config match disk).
  - **New, ON (`TELEPORT_LIFT_RESET`, ActiveRagdoll step):** when a standing body's pelvis jumps over 6 studs in one step (a set-down or any server teleport), its stand-hold lift moves with it at once and the body starts still. Before, the lift kept pulling it back to the old spot until think() looked again; `liftMoved=61` in the SWAY log was that.
  - **With SHOO_TO_SLOT, SETDOWN_FREE and TELEPORT_LIFT_RESET together, the same 2.5 min Play:** 1 CALM_GUARD fling, at 12 s during start-up, right after a FAST_THREE set-down (touch EntranceBayLine, EntranceRowSlab). Before: 3.
  - The SWAY list is unchanged (boxers and walking turns: 0.13).
- **PC 28 Nov: the CALM_GUARD car fault FIXED (`CALM_GUARD_CARS`).** When a part of a vehicle (a model holding a VehicleSeat) is within 3.5 studs of the flying body, it is a real hit: the guard lets it fly and does not count it. 60 s of Play: no errors, 0 flings. With BOX_SOFT_PLACE the last two runs had 0 CALM_GUARD flings in 3.5 min in all (before: 3 in 2.5 min). The 2-minute capture series asked for is the owner's test (PC and phone).
- **Cloud 28 Nov, cause found from that log (`SHOO_TO_SLOT`, RagdollDirector `capStepV2`/`slotAway`):** the near cap (NEARBY_CAP_V2) sent each extra body 90 studs STRAIGHT away from the player with no check of where that is: into the map's rim, the railway, fences and the plaza rails. The lift and drive pressed it against them until the solver threw it out sideways at 40+ studs/s (exactly the two logged spots). Now it goes to a free watch slot by a machine (Slots: checked level floor, free cell) far from every player; if none is free it stays where it is. **PC:** Play 5 min again; no `[CALM_GUARD]` line at the rim or rails. Any other line: fix its source the same way.
- **What the owner sees:** standing and walking ragdolls suddenly jump and fly off with nothing hitting them.
- **Cause: NOT found yet (cloud could not see it without Studio).** No single cause was found in the code (GroundGuard, the lift, poses and props are all suspects). So the cloud built a guard that catches it AND names the cause:
  - an upright living body (Standing, Walking, Fleeing) that nothing hit, shoved, held, rides or has in a machine, and that goes over 25 studs/s sideways or 16 up, is stopped and put back where it last stood calmly;
  - it writes why on the body: the attribute `FlingWhy` (state, speed, what it touched, Watch, Mood, Pose, Activity) and warns once per 10 s per body: `[CALM_GUARD] <name> flung with no hit: ...`.
- **Your job (PC):** Play 3 minutes in the lab (walk round, shoot, grab, drop into machines). Collect every `[CALM_GUARD]` line. Each distinct cause (for example "touch=Bench.Seat", "pose=CPR", "touch=Lamp") is a REAL bug: fix it at its source (the pose, the spot, the prop's collision), not in the guard. List each in the State with its fix.
- **Proof:** the warning list before and after; 2 minutes of a capture series with no ragdoll flying without a hit; `ActiveRagdoll.calmFlings` printed at the end (near 0).

### 0.2 A punched ragdoll goes 20 m away and keeps going further as you walk to it: CLOUD (`CAP_NEVER_YOURS`, RagdollDirector `capStepV2`)
- **PC 28 Nov: DONE.** Punched 5 times with the real HitRequest ("Punch"), then followed for 20 s, moving up to it every 2 s. The distance went 11, then 5, 5, 5 ... 5, 3 studs: it never walked or slid away, and its Home stayed by me. Capture punch_follow: the punched ragdoll beside the player on the plaza.
- **Cause found (cloud):** the too-many-near cap (`NEARBY_CAP_V2`) sends extra bodies 90 studs away from the player. It kept a body only if the SERVER stamped a hit on it in the last 8 s (`ServerHitAt`), but a punch on a body your own screen simulates is reported by your screen and never stamped. So the body you punched was sent away, and sent away again every time you walked near it.
- **Now:** a body within 25 studs of you, in your view, or hit/touched in the last 60 s (its `Hits` count went up) is never sent off, and one already walking off stops when you go to it. Only bodies you cannot see are sent away.
- **Proof:** punch one 5 times, walk after it for 20 s: it never walks or slides away from you (capture series); stand at the spawn 60 s: the count within 45 studs stays at the cap, and nobody walks off in view.

### 0.3 The gyro: bodies bounce up and down and fly out; it needs E: CLOUD (`GYRO_RIDE`, `GYRO_AUTO`, MapMachines `spin`/`wireGyro`, Client/GyroRideClient)
- **PC 28 Nov: DONE.** A ragdoll put on the gyro's pad from the server was taken by itself 0.2 s later (GyroRide set, no prompt) and held at the hub (y 18.6). Capture gyro_ride2: the ragdoll in the middle of the rings, no E prompt anywhere.
- **Cause found (cloud):** `spin()` teleported the client-simulated body to the hub 20 times a second (`DummyControl.move`), while its own screen let gravity pull it between the teleports: it bounced and was thrown out. And it never sat in the seat: the rings and the seat turn only on each screen (GateMotion "Spin").
- **Now:** the server anchors the body for the ride (`GyroRide` attribute) and every screen holds it in the nearest turning `GyroSeat` (Client/GyroRideClient), so it turns WITH the rings. No E prompt: the gyro takes every ragdoll dropped on its pad or walked in (`GYRO_AUTO`).
- **Proof:** a capture series of a dropped ragdoll riding in the seat, turning with the rings, then flung out; no prompt visible; on the phone too.

### 0.4 TRY removed completely: CLOUD (`TRY_OFF`, FirstTwo, LabShowcase, SessionStats)
- **PC 28 Nov: DONE.** Standing by 5 machines (their DropSpots) for 2.5 s each: no TRY button, no "Try ..." line and no "TRY!" in any visible GUI. Capture try_gone: the HUD without TRY.
- No TRY button, no E for it, no "Try CANNON 0/6" goal line; the server ignores a "Try". The bowling FTUE line stays. Item 1.9 and the SMOKE ROUND's step 4 are replaced by 0.3's drop test.
- **Proof:** walk past 5 machines on PC and phone: no TRY anywhere.

### 0.5 The head floats up in the compressor: CLOUD (`PRESS_HOLD`, Compressor `pancake`; DummyLife: no speech while MachineHidden)
- **PC 28 Nov: DONE (trace).** A body on the bed, `Compressor.press` called on the server: for the whole press (4.8 s) all 16 of its parts were anchored and it was MachineHidden; after, all 16 parts were unanchored and whole. So nothing can be squeezed up through the plate. (The capture press_hold shows the press from the side.)
- **Cause found (cloud):** under the pancake copy the real body stayed a live physics body; the plate squeezed it and the solver pushed its parts up through the thin plate, where the head was left floating; its speech bubble floated there too.
- **Now:** the hidden body is frozen where it lay (anchored, no collision, invisible on every screen) for the whole press, and let go after (owner reasserted); a hidden body says nothing.
- **Proof:** press 3 ragdolls: nothing above the bed during the press; each comes back whole after.

### 0.6 The old block ragdoll when the spider takes one: CLOUD (`SPIDER_REAL_BODY`, LabCreatures `BUILD.Spider`)
- **PC 28 Nov (2): DONE, all three in the phone emulator.**
  - **The washer (`WASHER_REAL_BODY` + `WASHER_DOOR_FIT`).** Two causes:
    - the drum spun a block `puppet`;
    - the washer model's pivot is its MIDDLE (12 tall), so the door at `base * (0, 6, -6)` sat on the top front edge. The glass disc floated over the machine, the drum lay ON TOP of it, and the take-box was too high for bodies standing on the floor.

    Now the door sits on the model's own round glass (`(0, -0.8, -3.6)`), with the drum 2.2 behind it. The REAL body is anchored, pulled in to 0.55, and turns with the spin, then is let go 2.5 studs out of the door. Pins use `SpiderPin`, so the failure path frees them too.
    - Capture `washer_real_body3`: a body taken from the floor, its v6 skin, face and emblem tumbling behind the glass.
    - After the cycle: 0 pins, no puppet parts, the body 12 studs out in front.
  - **The chick (`CHICK_REAL`).** The egg hatched a block `puppet` and the follower was plain balls.
    - Now both are a real chick model, `ServerStorage.V3Assets.MChick`: the Creator Store "Baby Chick" 87231622565290 by cube3D. Malware pass: one MeshPart, 0 scripts, 0 remotes. **Save the place.**
    - Hatch seen on the server (the MChick was made in the yard).
    - Capture `chick_follow`: the real chick on the grass behind the player.
  - **The spider.** Capture `spider_real_body2`: the caught body behind the spider in the web is the v6 skin (white skin, crash-test emblem), not blocks. 16 parts pinned.
- **PC 28 Nov: PART (data).** A body put in the web was caught (InMachine Spider) and its REAL parts pinned in the web at the catch spot, visible (Transparency 0). The old block copy is no longer made. From both sides the spider sat in front of it, so the capture spider_real_body does not show the body clearly. The washer and the chick were not captured.
- **Cause found (cloud):** the still copy in the web was cloned from the body's physics parts, which on a v6 body are the hidden OLD blocks.
- **Now:** the real body hangs in the web, anchored in its caught pose (its own v6 skin, face, holes); hidden only when the cocoon closes; let go if the sequence fails.
- **Also (PC):** the same old-block look in two more places: the washer's spinning drum shows a block `puppet` and the egg hatches a block `puppet` chick (LabCreatures `puppet`). Replace both: the washer spins the REAL body anchored in the drum (same method as the spider: anchored, turned by the server, or by each screen like the gyro), the chick is a small real chick model (Creator Store, malware pass). Search for any other copy made from body parts (`Instance.new("Part")` with `p.Size` of a body part) and fix it the same way.
- **Proof:** a capture of the spider's catch in the web (the new body), the washer drum mid-spin, the chick.

### 0.7 X-ray bones turned wrong in arms and legs; holes not seen on arms and legs: CLOUD (`V7_ON_AXIS`, SmoothBody `stick`/`drive`)
- **PC 28 Nov (2): the side capture of a hole LEFT after 2 tries.** 6 Blaster shots from the body's right side gave 4 BulletHole parts on RightLowerArm and 2 on RightUpperLeg, 0.42 studs from the forearm part's centre, decal facing Right.
  - Capture 1 (`hole_arm_side`) was taken from behind the body.
  - Capture 2 was taken along the hole's normal and saw the inside of something.

  The X-ray part stays DONE.
- **PC 28 Nov: the X-ray DONE, the holes PART.** A body killed with 8 chest shots, then 3 shots each on the right upper arm, forearm, thigh and shin. Only the 4 newest holes stayed, all on the thigh (holes fade after 4 shots), 0.74 studs from the thigh's centre: on the drawn skin, not inside it.
  - Capture xray_thigh_top (X-ray on, from above): the whole skeleton inside the lying body, the arm bones along the drawn arms to the hand bones, nothing turned or sticking out.
  - Capture hole_thigh_top: from above the thigh holes face down and are not seen. A capture of a hole on an arm or a leg from its own side is still missing.
- **Cause found (cloud):** the DRAWN v6 arm or leg does not lie on its hidden physics part: its axis runs from its joint bone to the next joint, 0.4-0.5 studs off the part on the upper arms, and turned with the pose. The X-ray limb bones (DummySkins `xrayBone`) were built and welded on the physics part, so they stuck out of the limb at an angle; and under RAGDOLL_V7 the cloud's own V7_SAME_FRAME left the holes on the weld too (stick skipped V7), so they were inside or beside the arms and legs.
- **Now:** holes AND the X-ray arm/leg bones follow the drawn limb axis every frame, V7 or not.
- **Proof:** shoot an upper arm, a forearm, a thigh and a shin 3 times each (X-ray off, then on), standing and lying: every hole on the skin, every bone inside its limb along it; captures from 2 m.

### 0.8 Weapon testing still in the mountain: CLOUD (`KEEP_CLEAR`, new Systems/TerrainClear, Landscape, ShootingRange)
- **PC 28 Nov: DONE.** Capture range_clear (from the plaza side, 70 studs out): the WEAPON TESTING building stands free, facade, roof and sides clear, open grass round it, the hill only further back.
- **Cause found (cloud):** the range stands just outside the compact plan, inside the ring of grass hills round the map (LabOwnerMap `hills`, balls up to 100 studs wide). RANGE_CLEAR cut only 6 studs round its walls, so the hill still rose against its sides and roof; on the old map the slow Landscape fill even put the hill back after the cut.
- **Now:** the range is tagged `KeepTerrainClear`: it stands in an open terraced site (flat 14 studs round it, then 5 terraces stepping up 5 studs every 9 studs), cut at once and again at 4/20/60/120 s; Landscape never fills there and puts no trees there.
- **Also (PC):** tag every other building that touches a hill (walk the map edge: one capture per building) and give the range its real model (1.19). Make sure the path to its door is clear of trees (the owner could not get in because trees covered it).
- **Proof:** the range from the plaza and from its door: whole facade, roof and sides free.

### 0.9 CPR kneeling into a bench: CLOUD (`CPR_CLEAR`, Mourning `freeKneel`)
- **PC 28 Nov (2): why try 1 failed.** `VitalsService.wound` called from execute_luau runs in execute_luau's own require cache, whose Mourning never started (`running = false`), so no mourning could begin. The cloud's code is not at fault there. Stage it again by killing the body through the client's HitRequest (head shots).
- **PC 28 Nov (3), try 3 through the real path: LEFT for the cloud.** JOIN_CHANCE and CPR_CHANCE were set to 1 (back to 0.85 and 0.5 after; Mourning matches disk).
  - Setup: a lab-slot body (Slot 1, LabOwner the player) was set 2.4 studs off a ParkBench, with 2 friends set 6 studs off. It was killed by head shots through the client's HitRequest and went Dead.
  - In 25 s no CPR or Mourn mood appeared. One living slot body stood 5 studs away, and the 2 placed friends had `CommandedBy = -6`, so `free()` says no.
  - Later the victim was Alive and Standing again. Something revived it without CPR; most likely the `mourned[body]` pass never ran for it.
  - NEXT (cloud): a debug line in the "New mourners" pass (dead bodies seen, `near` count per body), or a `Mourning.testStart(body)` hook. Also: who sets `CommandedBy = -6` on placed bodies?
- **PC 28 Nov, STAGED twice: LEFT.** For the test JOIN_CHANCE and CPR_CHANCE were set to 1 in the Studio source (put back to 0.85 and 0.5 after; Mourning matches disk again, 32975).
  - **Try 1:** a body 2.2 studs in front of a ParkBench and 2 friends set 6 studs from it, killed with `VitalsService.wound` (no killer). It died, but no friend mourned in 30 s; only one body stayed within 30 studs, with no mood.
  - **Try 2:** the same with the friends 5 studs off, Home held, the player 12 studs away shooting it through the real HitRequest (Blaster, up to 12 shots). It went Unconscious, not Dead, and no mood started.
  - So mourning did not start in either staged case. NEXT (cloud): name the exact start condition in Mourning (a death by a player? the lab owner near? the friends' own state?) so the PC can stage it, e.g. a `Mourning.startFor(body, friend)` test hook.
- **PC 28 Nov: OWNER CHECK.** I killed a body 2.2 studs in front of a ParkBench (at 1038, 173). No mourner came within 40 s (mourning only starts by chance), so the kneel spot could not be seen. The code (`CPR_CLEAR`, `freeKneel`) is pushed and the Play is clean.
- **Cause found (cloud):** the kneel spot was always 1.6 studs off the chest on the near side, whatever stood there; the kneeling legs were posed into the bench and thrown out.
- **Now:** a knee-sized box must be free of anything solid; else the other side, then the head end; else no CPR there.
- **Proof:** kill a ragdoll next to a bench: its friend kneels on the open side.

### 0.11 Bandages and plasters can't be seen; they hang in the air: CLOUD (`WRAP_ON_SKIN`, `PLASTER_SKIN`, SmoothBody `stick`/`drive`/`plasterOn`)
- **PC 28 Nov, STAGED: FAILED, LEFT for the cloud.** On the server `VitalsService.wound(body, limb, limb.Position, nil, 0.3)` twice each on a living body's LeftLowerArm, RightLowerLeg and Head (it stayed Alive). On the client 10 Bandage parts were made within 1 s: rings on the left forearm and the right shin, about 1.0-1.1 across, 0.3-0.4 studs from the PHYSICS limb parts, anchored (WRAP_ON_SKIN took them over). No head wrap.
  - Capture bandage_forearm: the white ring hangs in front of the body's chin and chest, facing out like a disc, NOT round the drawn forearm.
  - Likely cause: with RAGDOLL_V7 on, the drawn forearm lies on its BONE (the physics part times the bone offset `d.off`), not on the physics part. The wrap's `rec.off` is taken from the physics limb, and the `r.xray` frame turns the ring with the bone axis from `boneCf`, while its offset still comes from the physics block. So it sits off the skin and turned.
  - NEXT (cloud): build the wrap's offset in the bone/drawn frame (or skip `rec.off` and place the ring at a point along `boneCf` A to B at the wound's t, radius from BodyShape, axis along the bone), then the PC stages it again.
- **PC 28 Nov: OWNER CHECK.** No body in the lab had a bandage in 60 s of Play. 2 shots each on a forearm and a shin killed the body, and no bandage came in 25 s: the wraps are drawn from a LIVING wounded body after first aid, which a test cannot stage quickly. The code (`WRAP_ON_SKIN`, `PLASTER_SKIN`) is pushed and the Play is clean.
- **Causes found (cloud), three:**
  1. DummySkins welds a bandage to the old SKIN piece (the Skins folder), not to the body's limb. SmoothBody took it over with that skin piece as its limb, but the drawn frames are keyed by the physics parts, so it was anchored once and never moved: left hanging in the air.
  2. It sat on the physics axis with BodyShape's radius, about 25 % smaller than the drawn mesh (the PC found `HOLE_AXIS_SCALE` 1.25 for the holes), so it was inside the limb.
  3. The plasters are the server's block-sized strips and are switched off (`PLASTER_VISIBLE = false`): nothing showed.
- **Now:** a bandage is carried by the body part of the same name on the DRAWN limb axis, its rings as wide as the drawn limb (x HOLE_AXIS_SCALE), a head wrap round the round head; nothing is ever left without a frame (it follows its limb at worst). Each screen puts a plaster ON the drawn limb (two crossed beige strips at the skin) wherever the server marked one, and removes it with it.
- **Proof:** a patched-up forearm, shin and head and a plastered (broken) limb, standing, walking and lying, from 3 m and 10 m, PC and phone. If the rings look too thick or thin, tune `HoleAxisScale` live (workspace attribute) and write the value in Config.

### 0.12 The newspaper, the phone and other props are not in the hand (4th report): CLOUD (`HAND_PROPS`, SmoothBody `scanProps`/`placeProps`)
- **PC 28 Nov: DONE (data).** The paper lay loose on a car until a carrier took it 3 s later; then it sat 0.43 studs from the carrier's RIGHT hand (2.39 from the left), anchored on this screen: HAND_PROPS has taken it over and draws it in the drawn hand. Capture paper_in_hand2 (the white sheet at the left edge, in a hand; the camera framed the carrier's chest).
- **Cause found (cloud):** a held prop is welded to the hidden PHYSICS hand with an offset made for the OLD body (`Newspaper.gripOf`: "DummySkins draws it lower"; the FilmPhone in DummyLife: `hand * (0, -0.45, -0.1)`). On the v6 body the DRAWN hand sits elsewhere and moves with the drawn arm (its axis is off the physics arm, see 0.7), so the prop hung beside the body.
- **Now:** every screen takes each prop welded to a v6 body's hand over (weld off and anchored on that screen only) and puts it each frame at the v6 grip point (BodyShape.HAND.grip) carried by the drawn hand bone, keeping its turn against the hand; when the server lets go (the weld goes) it is given back.
- **Check (PC):** the prop's centre sits in the curl of the fingers (HAND_POSES grip). If the paper is held by its middle but should be held by its edge, add a per-prop offset (attribute `GripOffset` on the prop, read in placeProps). Check every prop a ragdoll holds: newspaper, phone, tweezers (PickOut), the shovel/tools (Mourning, NpcCommand).
- **Proof:** the newspaper carrier walking and reading, a filming ragdoll, from the front and the side at 3 m, PC and phone: each prop in the hand, never beside it.

### 0.13 A standing ragdoll still sways side to side now and then: CLOUD probe (`SWAY_PROBE`, ActiveRagdoll `swayProbe`)
- **Cause: NOT known.** Six writers move a standing body (the balance turn, the lift's spot, the drive, the pose, turning to a person, the stand hold), and every earlier fix guessed one. Stop guessing.
- **The probe** samples each upright body every step and, when its sideways speed flips 3+ times in 1 s, warns `[SWAY] <name> flips= amp= state= stateSwitches= liftMoved= headTurn= drive= pose= mood= firm= chestBal= feet=` (also the attribute `SwayWhy`).
- **Your job (PC):** Play 5 minutes in the lab with 18 bodies; collect every `[SWAY]` line. The writer with the large number is the cause (for example `stateSwitches=4`: Standing/Walking toggling; `headTurn=70 firm=yes`: turning to the player; `liftMoved=1.4`: the stand hold re-set; `feet=Dummy.LeftFoot`: standing on another body). Fix THAT writer at its source; then Play again until no `[SWAY]` line comes in 5 minutes. Write each cause and fix in the State. Then `SWAY_PROBE = false`.
- **Proof:** the `[SWAY]` list before and after, and a 60 s side capture of 5 standing bodies with no sway.
- **PC 28 Nov: the probe's list, 2 runs of about 2.5 min each (35 `[SWAY]` lines).**
  - **The biggest group, half of them, is the BOXERS:** Standing, `mood=Box`, `feet=BoxingRing.RingCanvas`, chestBal off, liftMoved 0, amplitude 2-18 studs/s. The background boxing match is the main standing sway; their footwork is not held. Once `liftMoved=61.44`.
  - **Next, WALKERS turning:** Walking, `headTurn` 42-151 degrees, drive 4-12, chestBal on. A walking turn swings the hips side to side.
  - **One bike rider:** `mood=Ride`, liftMoved 9.7.
  - **No standing body outside the ring swayed with stateSwitches > 1:** the state toggle is NOT the cause.
  - NEXT (cloud): the boxers' sideways footwork (BoxingMatch) and the turn rate while walking. The 60 s side capture comes after that fix.
- **PC 28 Nov: the boxers FIXED (`BOX_SOFT_PLACE`, BoxingMatch `place`).**
  - **Cause:** before every exchange both boxers were TELEPORTED onto their ring spots (`DummyControl.move`), even 0.4 studs away, while their own screen simulated them.
  - **Now:** they are only moved when a knock sent them over 2 studs off; else they step there.
  - **The same 2.5 min Play:** boxer SWAY events 6-8 down to 3 (amplitude 1-10, was up to 18), and **0 CALM_GUARD flings** in the whole run.
  - **What is left in the list:** the bike rider (`mood=Ride`, the bike turning under it, 8 lines) and walking turns (headTurn 50-150), both moving bodies, not standing ones.

### 0.10 The plan doc itself (PC, at the end of the run)
- Every item you touch: the State line says DONE + the capture line, or LEFT + the exact reason. No "PART" without saying exactly what is missing.

---

## OWNER REQUEST LEDGER (26-28 Nov): every request the owner made, so nothing is skipped
The owner said things were skipped. This is the full list from the chat since 26 Nov. For each line, during the run: find where it stands (item, switch) and VERIFY it with one capture. If it works: tick it with the capture's line. If it does not, or it was never built: build it (behind a switch, cause found first) and prove it. Lines marked **NEW** were in no plan before 28 Nov.
- Ragdolls and physics:
  - stand still without jitter; walk upright (no leaning back, no "bodybuilder" elbows); legs never flicker on turns; heads stay on the neck walking (1.3, 1.10, 1.12, V7-2);
  - fall realistically by shots, blood loss; get up, fail to get up (V7 doc 3.2);
  - never walk into things or each other; never stuck in hedges or walls (**NEW check**: a 60 s capture at a busy spot);
  - pick the bullets out after waking up (only the shots stay, no injuries);
  - bones break by weapon and number of hits, belly and back bones too, the bullet visible in the bone where it hit (2.3);
  - the angry friend shoves 1-3 times and punches the player (1.22);
  - at most 2-3 holes drip, the newest; a purple splash per hit; holes fade after 4 shots;
  - thicker bodies, real hands (fingers), no black or purple stripes, neck not too big;
  - no frozen bodies in the air when they die (1.23);
  - ragdolls at every machine, 3 alive near you, a runner comes when there are 2 (SPAWN_V2);
  - nobody disappears in your view (0.2, SPAWN_V2).
- Machines and creatures:
  - DROP HERE the right size, one machine at a time (1.19);
  - carried ragdolls never sent to the top of the tower or machines (1.19 CARRY_FLOOR_RAY);
  - T-rex and bear really take the ragdoll in the mouth; the bear's DROP HERE in front of its mouth (1.8);
  - every killer its own creative death (2.6) and good idle animations (Blender is on);
  - the stretcher stretches limbs long, lets go, the long limb shrinks back over 30 s (**verify**);
  - the cannon: the ragdoll goes INTO the cannon, the plate never launches the player; the cannonball spot where you lay a ragdoll works (**NEW check**);
  - bowling: the ragdoll curls up fast and flies into the pins (the hook);
  - the washer: in and out through the door (0.6);
  - boxing: drop one in, an opponent runs in, they fight to the death; 2 ragdolls start a fight within 15 s of joining (**verify** BOXING_V2);
  - the shark tank: the shark is in the water, not in the concrete; a thrown ragdoll swims or drowns; the water is visible through the glass but not drawn through it (**NEW check**);
  - the cave: a real hill and entrance, no black flat wall, no puddle over the land (**verify** caveV2);
  - the chicken is not by the spawn; something that hooks people is (**NEW check**);
  - the slide ("rutsjebanen"): the problem in the owner's capture of 26 Nov (**NEW check**: ride it, fix what breaks);
  - the wall: brick by brick with gravity, a car breaks it, it resets after 10-15 s; concrete walls and crates too.
- Map:
  - no building inside a hill (0.8); paths connect to things; nothing on the paths (lamps, props); the aquarium not half in a wall or the spawn;
  - trees: you can walk through them; none in front of the weapon range's door (**NEW check**);
  - the stairs work indoors too; the path wall has an opening;
  - the water button removed, the water always on (**verify**);
  - the flower beds are real beds, not flickering circles (**NEW check**);
  - the parking lot: each vehicle straight over its plaque (1.19);
  - no orange boxes; banners clear of the arch; the plant faces the path (1.14-1.16).
- Vehicles:
  - you are never kicked out of a car while driving (**NEW check**); launch pads launch cars (`PAD_CARS`); vehicles never poke through things (wheelchairs through the ground);
  - the bicycle: you face forward, never fly over it, no car sound; riders sit right (1.6); the motorbike never stuck (1.24);
  - the 5 vehicle passes prompt the right ids (1.19).
- UI and phone:
  - phone first; the hotbar small until tapped; no keybind letters on the phone (J on the gift); no "Multipla"; REVIVE centred over Shop and Weapon; icons centred, no overlap; no 3D turning icons (1.20);
  - notices centred and clean (1.21); no floating words anywhere (1.24);
  - first person on a weapon pick and a shot; V leaves it even holding a weapon; the eye button on the phone (1.2);
  - the time dial chips work (not stuck on 2x); build mode has a DONE button on every device (1.19);
  - leaderboards: scroll to top 20, face the right way, no text over them, the owner kept off them;
  - X-ray: the key on PC, the button on the phone only; a limb glows only after 3 shots in a row on it, fades after 2 s over 1 s; toggled on it stays (2.4, 0.7).
- Other: funnels follow the new map; every event fits the new map (nobody feels scammed).
- **Ledger checks, PC 28 Nov (Play, phone emulator):**
  - **"the chicken is not by the spawn": TICKED.** Trigger distances from the player's spawn point:
    - the chicken is 293 studs away;
    - nearest are the shark/whale pool (83, 84), the mole (113), the plant (121) and the bear (152).
  - **"no trees in front of the weapon range's door": TICKED.**
    - 0 trees within 12 studs of any of the range's 4 faces.
    - Capture `range_door_trees`: the WEAPON TESTING front from 45 studs, the doorway and sign free, open grass.
  - **"the shark is in the water, not in the concrete": TICKED by data.**
    - The PoolWhale's centre is inside `PoolWaterVolume`.
    - Capture `shark_tank`: the pool full of water inside its concrete rim. The whale is under the surface, not seen from this angle.
    - It is an open pool, not a glass tank, so the "water through the glass" line does not apply.
  - **"the flower beds are real beds, not flickering circles": FIXED (`JUNCTION_ONCE`, LabOwnerMap `ground`).**
    - There are no flower beds left on the owner map; the only round shapes on the ground are the paved road junction discs.
    - Cause: roads share end points, and each road laid its own disc at every point, so 8 of the 16 discs lay on another disc at exactly the same height and flickered (z-fighting).
    - Now there is one disc a point (the widest): 12 discs, 0 on another.
    - Capture `junction_once`: a junction by the spawn, clean and even.
  - **"never walk into things or each other; never stuck in hedges or walls": TICKED (a 60 s check).**
    - Every walking body was sampled every 6 s for 60 s; stuck means moving under 1 stud while its Home was over 5 studs away.
    - Result: 1 stuck once, by the spawn plaza's edge, and the next sample had it standing 2.7 studs from its Home.
    - Capture `busy_spot`: the spawn plaza and the bowling lane from above, the bodies apart, none in a wall.
  - **"the cannon: the ragdoll goes INTO the cannon, the plate never launches the player": TICKED.**
    - Launch plate: `CANNON_MUZZLE_LOAD` leaves no plate; the old pad is invisible and has no touch.
    - Loading (`CANNON_HOPPER`): a body the player let go over the funnel slid down it, was hidden in the barrel, and fired at 173 studs/s, flying 157 studs. The player stayed put.
    - Capture `cannon_hopper`: the cannon with its striped funnel.
    - **Staging lesson:** do NOT call `DummyControl.setOwner` from execute_luau (it is a copy). The live module still thinks the client owns the body, so the cannon's push went to the client while the server owned the physics, and the body stuck in the barrel. Move a client-simulated body from the CLIENT instead, with `Held` set on the server.
  - **"the slide: ride it, fix what breaks": TICKED, nothing broke.** SLIDE_V2 is one chute of 23 SlideBed pieces from the tower roof (y 52) to the ground (y 1).
    - The player, set at the top and walked piece to piece at walking speed, reached the bottom (piece 23) in 3.7 s, with no stop longer than 0 s and no fall off.
    - Capture `slide_top`: the chute leaving the roof edge by the SLIDE sign.
    - Capture `slide_ride`: the player half way down the green chute.
    - Note for proofs: `Humanoid:Move` from execute_luau does nothing (the game's control code resets it each frame); drive the root's velocity instead.
  - **"you are never kicked out of a car while driving": TICKED.**
    - Under CAR_STAY a driven car counts as "off" only when it falls out of the world or is over 700 studs from its home. The farthest map corner from any vehicle's home is 565 studs (FireTruck), so the map never reaches that edge.
    - Test: the player sat in LabCar, which was moved 484 studs to the farthest corner, and after 4 s was still its driver.
    - Capture `car_far_corner`: the driver HUD (speedometer, gear N, INSIDE) at the map's far corner.
  - **"no Multipla": a Studio artifact, not a phone bug.** The caption reads "Online" when the player's `Device` is phone or tablet.
    - After the MCP sent key presses, Studio's emulator reported a keyboard too (`TouchEnabled` and `KeyboardEnabled`), so `Device` became "pc" and the caption "Multiplayer", cut to "Multipla" in the narrow phone layout.
    - A real phone has no keyboard: "phone", "Online" (as in this run's earlier captures).
  - **"the water button removed, the water always on": TICKED.** There is no part named like a water button or switch and no ProximityPrompt about water on the whole map. The pool shows its water at once (capture `shark_tank`, earlier in this list).
  - **"the cave: a real hill and entrance, no black flat wall, no puddle over the land": TICKED.** CAVE_V2 is on (CaveDark, CaveRoot x5, CaveLog, CaveStump, CaveEye x2).
    - Capture `bear_cave2`, from the bear's yard: a grassy rock hill with a dark arched opening, rocks and a log in front, the bear before it, no flat black wall, no puddle.
  - **"boxing: 2 ragdolls start a fight" (BOXING_V2): SEEN running.** At the start 2 bodies were already boxing; capture `boxing_v2` shows the two in guard, close, in the middle of the ring.
    - A third body dropped in did not join: one fight at a time, by design. So the "drop ONE in, an opponent runs in" path was not staged separately this run.
  - **"the stretcher stretches limbs long, lets go, the long limb shrinks back": LEFT after 2 staging tries, for the cloud.**
    - The code path reads right: after the release a limb holds 30 s (`HOLD_LONG`), then shrinks over 10 s (`SHRINK`, eased); the owner asked for 30 s.
    - Staged in Play: a client-simulated body let go on DropSpot_Stretch (`Held` set on the server) was locked (`InMachine = Stretch`, 4 springs on), then "Pull all four" was fired from the client next to it.
    - After 10 s every limb's `StretchK` was still 1.00. Capture `stretch_long`: the body STANDING upright in the middle of the machine, its cables on, saying "Just stretching my legs".
    - Likely cause: the trunk is not held down and lifted (HOLD/LIFT) while the standing balance keeps the body upright, so the body walks with the claws and the joint-to-claw distance never grows. Or `may(player)` / phase refused the press; there is no log line to tell which.
    - NEXT (cloud): a `[Stretch]` debug line for phase, pulling and K each second, and make sure a locked body is put in `Ragdoll` state (lying, held at LIFT) before the arms pull.
    - Try 1 was spoiled by me: I fired every prompt, Release included.
  - **"the wall: brick by brick with gravity, it resets after 10-15 s": FIXED (`WALL_FAST_RESET`, BrickWall).**
    - Cause: the wall rebuilt 45 s after the last hit (`REBUILD = 45`), and its loose bricks faded after 30 s.
    - Now: rebuild at 12 s, fade at 10 s.
    - In Play a body thrown into it at 90 studs/s 3 times broke it from 4 panels into 60 parts.
      - Capture `wall_broken`: bricks out, a stepped hole.
      - It was whole again (4 panels) about 13 s after the last hit; capture `wall_rebuilt`: the wall smooth again from the same spot.
    - Not checked: concrete walls and crates.
  - **"bowling: the ragdoll curls up fast and flies into the pins": TICKED.**
    - Staged: a client-simulated body set on DropSpot_Bowling, then the "Bowl!" lever pulled from the client.
    - It curled at once (`Curl`) and rolled down the lane. Capture `bowling_roll2`: the curled body on the lane right before the pins.
    - 4 s later 5 of the 10 pins lay down. Capture `bowling_pins`: the pins scattered at the lane's end.
  - **"the time dial chips work (not stuck on 2x)": OWNER CHECK.** The MCP cannot press the chips (clicks and keys do not reach the game view in the emulator), and `require(TimeDial)` from execute_luau is a copy.


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
- **PC 28 Nov (2): DONE (phone emulator).** The player stood 40 s each by the boxing ring and by the press; living bodies within 45 studs were counted every 5 s, as free + the machine's own.
  - Ring: 1, 0, 0, 1, 1, 1, 1, 2 free (+ 0 to 2 boxers).
  - Press: 1, 1, 2, 2, 3, 3, 3, 4 free.
  - Never over the phone cap of 5. The spawn was proven before (2 at most).
  - Capture `crowd_press` (from above, the press in the middle): a few bodies spread round it, no crowd.
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
- **PC 28 Nov (2): OWNER CHECK (a feel item), drawing proven.** In Play, the 4 Board guis are in the PlayerGui, adorned to the Lab1 panels; each list's canvas is 768 tall.
  - Capture `board_before` (MOST TAKEDOWNS, top 5 shown).
  - With `CanvasPosition` set to 320 from code, capture `board_after` shows the list moved on (ranks 10-15) inside the frame, with the scrollbar lower.
  - Note: the ScrollingFrame's `Active` is false. If the owner's wheel or drag does nothing, set `Active = true` first.
- **State (PC, 28 Nov, v1431):** in Studio. All 4 Board guis are in the PlayerGui, adorned, with no duplicates and none left in Workspace; the list is 768 tall in a 196 window. Two tries with the MCP mouse wheel did not reach the board (the injected mouse does not land in the game view), so the scroll itself is unproven: the owner tests it.
- **Cause found:** a SurfaceGui in the Workspace gets no input. Every `Board` gui is now moved into the PlayerGui, adorned to its panel.
- **Proof:** scroll each board with the wheel on PC and by drag on a phone. Captures before and after the scroll.

### 1.8 Animals really take ragdolls in the mouth: PART (`CREATURE_GRIP` + PC MouthBone)
- **PC 28 Nov (2): the bear DONE (phone emulator), plus a new cause fixed (`DROPSPOT_STABLE`).**
  - **Cause:** the bear's DROP HERE stood **53 studs** from the bear (its reach is 16), so a body dropped there was never taken.
    - `DropSpots.scan` runs several times and parents each spot inside the machine's model.
    - Every later scan's `GetBoundingBox` took the old spot in, so the spot crept 4+ studs further out each time. The stretch machine's spot crept up the same way.
  - **Now:** a model is measured without its own DropSpot children (`boxOf`).
    - After 40 s of scans the bear's spot is 7.6 studs from the bear, and the stretch spot stays 1.0 over the top.
  - **The bear, staged:** bodies set on its DROP HERE, the BearPoke prompt fired from the client.
    - Woken, it either swats (claw wounds, the body Ragdoll) or mauls.
    - Capture `bear_maul3`: the maul, the body held up at the bear's mouth ("My heart!", purple blood), its v6 skin.
  - The T-rex's whip keeps its earlier `rex_grip` state (MouthBone fixed); a mid-whip capture is still missing.
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

### 1.9 TRY and machine buttons: the ragdoll walks there and hops in: SUPERSEDED for TRY (removed, 0.4); the machine buttons keep `TRY_WALK` (`CALLED_WALKS`, TRY_REACH 80)
- **State (PC, 28 Nov late): captured.** At the shredder, through the real Session "Try" remote: a ragdoll was given Watch "Demo" within 8 s and was 6 studs from the spot 1.5 s later. Capture try_walk: the ragdoll in mid-jump over the shredder's rail into the pit. Proven at 1 machine (the item asks 4; the trace at the bowling lane, v1432, is a second).
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

### 1.11 Heavy lag on a good PC, not every ragdoll drawn: PART (`LAB_DUMMIES_PC` 18, SmoothBody 28/200)
- **State (PC, 28 Nov, v1436):** Studio PC: 60 FPS at the spawn; 18 lab dummies; in view within 200 studs, 3 of 3 in v6 (capture spawn_v6_fps). 0 bodies asleep at that moment. NOT done: the MicroProfiler top 5 and the phone-emulator numbers.
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

### 1.12 The legs still bug: LEFT (`LEG_ONE_WRITER` + PC `LEGS_WHILE_MOVING`, `STANDING_RUN_GAIT`)
- **State (PC, 28 Nov, after V7 step 1):** a "Standing" body that really moves (over 2.5 studs/s across the ground) now runs DummyLife's walk cycle instead of the idle stance (`STANDING_RUN_GAIT`), and its ground speed is no longer zeroed each frame. 75 s of Play: still 2 knee events, like before. Both read "Standing, speed 13, feet on Body": the detector's speed includes the vertical, so these are bodies FALLING onto another ragdoll while still "Standing" (a set-down or a fall), not running watchers. The TURN TWIST events (walking turns, 5-6 foot slips a second, and 13-19 rad/s spins while Standing) are unchanged. NEXT: put a Standing body that is in the air (no ground under the feet for 0.2 s) into the Falling pose; the lasting cure stays V7-2 (animated walking). Try 3 (`FEET_GLIDE`, now OFF): upright feet with friction 0 instead of 0.25. 75 s of Play: still 6 walking-turn TURN TWIST events with 5-7 foot slips a second, as before, so the slip is not physical friction; it is most likely the DRAWN foot (DummyLife's foot planting) the detector reads. Also: the "Standing, speed 13" knee events are not only falls (one was "feet on OwnerRoad", pace 1.3). Three tries: LEFT for V7-2.
- **State (PC, 28 Nov, v1439):** cause (a) found and fixed. The knee flipping every frame ("N rev/s" = knee reversals at 70% of the fps) came from ActiveRagdoll.applyPose: a Standing body with the REST pose that MOVES (a watcher running to its spot at Pace 1.8) got its legs straightened each physics step, while DummyLife drew the run gait. LEG_ONE_WRITER excluded REST. Now REST leaves the legs to DummyLife while the body moves over 2 studs/s. Counted: before, 3 "rev/s" events in 75 s; after, 0 in 90 s. LEFT: (b) "TURN TWIST" (12 in 90 s), slow walking turns of about 1 rad/s with 5-7 foot stick-slips a second, which is DummyLife's foot planting. The lasting cure is RAGDOLL_V7.
- **State (PC, 28 Nov, v1436):** 60-75 s at the spawn with LEG_ONE_WRITER on: 9 LegJitter events of two kinds:
  - (a) "N rev/s, state=Standing" with Pace 1.8 (a watcher running to its spot, e.g. EntranceVehicles#2, RagdollBowling#2), speed 13 and 20-30 rev/s, once "feet on Body" (standing on another ragdoll);
  - (b) "TURN TWIST" while Walking at 1 rad/s with 5-8 foot stick-slips a second.

  So a fast-running watcher spins, and slow walking turns slip the feet. The lasting cure is RAGDOLL_V7 (animated until hit). NEXT: for (a), cap a Standing body's spin when Pace >= 1.4 (the run drive vs the balance yaw).
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

### 1.13 Bullet holes and bandages shown wrong: DONE for holes (`ON_SKIN` + PC `HOLE_V6_GRAZE`, `HOLE_ON_AXIS`, `HOLE_AXIS_SCALE` 1.25)
- **State (PC, 28 Nov, v1440):** measured: the floating upper-arm hole was 0.67-0.83 studs from the DRAWN arm's axis (shoulder bone to elbow bone) where the v6 radius is 0.36. Causes:
  - (1) ON_SKIN carried the hole's offset from the physics limb, but the drawn upper arm runs about 0.5 off the physics one;
  - (2) on a skinned body, a graze step moved the hole onto the OLD thicker skin.

  Now:
  - a limb hole is kept as (how far down, which way round) and redrawn each frame on the drawn axis at the v6 radius x 1.25 (the mesh surface);
  - the graze step is skipped on v6.

  Measured on the axis: 0.36 vs r 0.35. Capture holes_axis_fixed: holes on the upper arm, forearm and thigh, all on the skin. Bandages keep the old ON_SKIN way (not re-checked).
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
- **Owner 28 Nov: still not seen on legs and arms.** Cause found (cloud): ON_SKIN anchored the holes and moved them in SmoothBody, but with V7 step 1 they were placed from the old FK chain the skin no longer follows, so they hung off or inside the limbs. Fixed by `V7_SAME_FRAME`, and under V7 the holes stay welded. Prove it again: 5 shots per arm and leg, captures from 3 studs while it walks.
### 1.14 The spawn arch banners half inside the pillars: DONE (`BANNER_CLEAR`)
- **State (PC, 28 Nov, v1434):** capture banner_side: the banner hangs from its rod, clear of the pillar's face.
- **Cause found:** the banner hung 0.075 studs off the pillar, and its "Swing" (0.06 rad round its top) moved its bottom about 0.5 studs, into the stone.
- **Now:** it hangs from a steel rod 0.5 studs out and sways at 0.02 rad.
- **Also:** check every other part tagged "Swing" (flags and banners) the same way: gap > Amp x length + 0.1.
- **Proof:** captures of all 4 banners from the side, 10 s apart.

### 1.15 Orange boxes round the map: DONE (`YARD_CONE_MODEL`)
- **State (PC, 28 Nov, v1436):** found in Play with a ray through the capture's pixel: they are "YardCone", plain 1.4 x 2.4 x 1.4 orange blocks from LabOwnerMap's yard props. Now a real traffic cone (Creator Store 8952512774, 3 meshes, no scripts) in V3Assets.TrafficCone. Capture cone_model shows a real cone; 6 placed, 0 blocks left. SAVE THE PLACE (the model is in the place file).
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

### 1.17 The round X-RAY button on PC: DONE (`XRAY_BUTTON_TOUCH_ONLY` + `TOUCH_FIRST_DEVICE`)
- **State (PC, 28 Nov, v1436):** PC: there is no round button in the toast_v2 and spawn captures (X-ray is in the bottom-left list). Phone: hud_phone2 shows it.
- **State (PC, 28 Nov, v1432):** Phone: the round button shows (hud_phone2). PC: OWNER CHECK, because the MCP cannot switch the emulator off. In code, Device "pc" hides it.
- On a computer, X-RAY is already in the bottom-left list (the I key), so the round button now shows on touch screens only.
- **Proof:** a PC capture without it, and a phone capture with it.

### 1.18 The rocket: PART: the cloud part DONE (`ROCKET_WHOLE`, `ROCKET_WALK`), the PILOT not built
- **State (PC, 28 Nov late): ROCKET_WHOLE and ROCKET_WALK proven.**
  - **Why the earlier tries failed:** the prompt was OFF while a demo flight ran. It is `Enabled = false` only while `busy`, and 30 s later it was on again.
  - **The press:** with the character next to it, `InputHoldBegin/End` on the client fired it; the prompt went off, so a flight started. Capture rocket_walkup: a ragdoll at the rocket's foot.
  - **The flight:** 17 strap and body-copy parts rode with it, 119 studs up after 1 s. Capture rocket_liftoff: the WHOLE rocket in the air, the nose and capsule on top included, the ragdoll strapped on.
- **State (PC, 28 Nov late): the PILOT BUILT and ON (`ROCKET_PILOT`, RocketRide + new Client/RocketPilot, Net RocketSteer and RocketBoom).**
  - **How it works:** it keeps the server's anchored flight (`place`). The server holds the nose and turns it toward the pilot's wanted direction at most 90 degrees a second; below 12 studs up it never points lower than 0.4 up, and later never steeper than -0.25 down. Thrust ramps to 90 studs/s. The flight ends on a hit (a ray ahead of the nose), after 10 s of fuel, past 700 studs, or on BOOM; the burst, the parachute and the throw are as before, at the rocket's nose.
  - **The client** (while the player attribute PilotRocket is set): a chase camera behind and above the rocket along its nose; WASD or the phone stick (the PlayerModule move vector), camera-relative, sent about 10 a second; a HUD with height, speed and a BOOM button. Your character stands still meanwhile.
  - **The remotes:** the server hears only the current pilot; the steer must be a finite Vector3 of length 0.5-1.5, at most about 25 a second.
  - **Proof:**
    - Capture rocket_pilot_1: the HUD "71 studs up, 95 studs/s", BOOM, the chase camera behind the climbing rocket.
    - A steered flight's path (studs from the tower, every 0.5 s): straight up to (0,205,0) at 3.1 s, then after a sideways steer bending to (81,638,0) at 8.1 s. That is the server turning on the pilot's remote. It turned only part way, because the pilot client also sends "straight on" ten times a second without a key.
    - The real D key's run did not lift off in time, so the key steering is an OWNER CHECK.
  - **Moved:** BOOM sat on top of X-RAY on the phone; it is now beside the hotbar.
  - **PC 28 Nov late, round 2: the KEY steering FIXED and proven, the blast hold built.**
    - **Cause:** this game has no PlayerModule in PlayerScripts (its own controls), so the pilot's `GetMoveVector` was always 0 and WASD did nothing.
    - **Now:** WASD and the arrow keys are read from UserInputService; on a phone the stick comes through the character's MoveDirection (camera-relative).
    - **Proof, the real D key held 2.5 s:** the path goes straight up to (0,386,0) at 5.1 s, then bends hard sideways and round, to (-94,588,-154) at 9.7 s, then the burst. Capture rocket_pilot_steer: the HUD "533 studs up" and BOOM beside the hotbar.
    - **The blast hold:** the server sets the player's PilotBlast (the burst point) before it ends the flight; the client's camera looks at it for 2 s, then lets go. Seen: the flight ended with PilotBlast set.
    - **The HUD speed** read 0 (the server moves the rocket less often than the screen draws); it is now measured over 0.25 s, not seen yet.
- **State (PC, 28 Nov, v1436):** the rocket's "Strap a ragdoll on" prompt could not be fired from the MCP (two tries: the E key and InputHoldBegin; Triggered never fired on the server), so ROCKET_WHOLE and ROCKET_WALK are unproven. The PILOT (steering, chase camera, BOOM remote) is not built this run: a new client and server system. OWNER CHECK: press E at the rocket.
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

### 1.22 The angry friend punches the air instead of you: OWNER CHECK (`ANGRY_HITS_REAL`, `ANGRY_MORE`)
- **PC 28 Nov, STAGED through the real shot path: WORKS by data, capture missed.** The player shot bodies twice each through HitRequest (the planned first anger, ANGRY_FIRST).
  - The angry one went Ragdoll, then GettingUp, Standing and Walking, and came from 8 to 2 studs. It switched to Box (punching), and the player's health went 100 -> 77. It backed off and came again (6, 5, 4 studs).
  - The capture came 1 s late: by then it had run ("It got away!"), so no picture of the punch.
  - **Staging lesson:** `require(Mourning)` inside execute_luau is a SEPARATE copy (its own `running = false`), so `Mourning.provoke` and `VitalsService.wound` called from execute_luau never reach the live Mourning. Stage through the client's HitRequest instead.
- **State (PC, 28 Nov, v1436):** in Studio, no error; not triggered from the MCP (the anger is a dice roll on the server's own shot handling).
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

### 1.24 Floating words over bodies; the motorbike stuck in things: CLOUD (`WORLD_POPS` now also HitWords + StuntHud; `BIKE_UNSTUCK`)
- **Words:** "Knocked out", "Dizzy" and "Wobbly" came from `Client/HitWords` and the live flight count from `Client/StuntHud`. Neither was behind WORLD_POPS. Now both return at once when WORLD_POPS is false.
  - **Check:** in Play, list every BillboardGui that shows text over a body or in the air. The speech lines (DummyLife) are the only ones allowed (TRY is gone: 0.4). Put anything else behind WORLD_POPS.
- **Motorbike:**
  - **cause found (cloud):** BikeService only dodged ragdolls and players (`clearOf`), never walls, fences, posts or machines, and nothing noticed when it stopped moving;
  - **now:** a ray 8 studs ahead at knee height turns it to the clearer side, and if it has moved under 1.5 studs in 1.8 s it turns round and takes a new goal.
- **Proof:** a capture series of the motorbike meeting a fence and a lamp post and getting free; 2 minutes of riding without a stuck stop over 2 s.

### 1.19 Carried over from FIXES_28NOV: re-check each one (they were built, the owner did not confirm them all)
For each: one capture showing it working, and the switch. If it is broken, find the cause and fix it here. A line per item in the final message.
- `WORLD_POPS` off: no floating texts at any machine (DROP, SMASH, TAIL SLAP, RPM, CRACK, the rocket countdown).
 **PC 28 Nov:** one was left, the fan's "FAN: || 2" board (FanMachine made its BillboardGui without the switch). Fixed; a scan of every enabled BillboardGui with text in Lab1 found only that one.
- `CARRY_FLOOR_RAY`: carry a ragdoll under the bowling canopy and up every tower floor; it stays in front of you, never on a roof.
- DROP HERE (`DropSpots`): ONE sign at each machine when carrying, the bear's in front of its mouth.
- `PLAYER_SWIM`: fall into the aquarium, swim, and jump out on every side; the 25 s safety net.
- `STAIR_OPENING`: walk up the aquarium stairs onto the platform.
- `PARKING_STRAIGHT`: a top-down capture of the lot; each plaque in front of its vehicle.
 **PC 28 Nov (v1441):** the tank (LabMuscleCar, 12.8 wide) had an 11 bay; it was pushed into the Ford and rode up on it, tilted 13 degrees. `PANZER_BAY_FIT` gives it 13.5, and it now stands flat (1 degree). Capture parking_top: every vehicle over its own plaque, straight.
- **PC 28 Nov (2), the passes: TICKED by code.** `VehicleService.PASSES` holds exactly the owner's ids:
  - GoKart 2098603396, Police 2098855450, MonsterTruck 2099065438, Bulldozer 2098381516, FireTruck 2101716732;
  - Car 2092302232 and MuscleCar 2093220108; the Ford (Truck) 0 = free.

  A SOON vehicle reads "Coming soon" only while its pass is 0, so all 5 say "Drive" and prompt their own pass. `HOTBAR_3D = false` (no turning 3D gun). The plaque prices still need one look in Play.
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
  - **PC 28 Nov (2): the T-rex TICKED.** RexAnim adopted it: AnimSaves has idle, walk and attacc on the client, 33 bones. In 0.6 s 3 of the 21 bones the idle clip moves had changed their Transform (a slow breathing idle; the roar comes every 20-40 s). Capture `rex_idle`: the real skinned T-rex in its pen.
  - **PC 28 Nov (2): the plaque prices TICKED.** Lab1's vehicle plaques show 8 prices: R$ 25, 149, 49, 199, 49, 99, 125, 149. The plaque capture landed under a truck; the earlier `parking_top` shows each plaque in front of its vehicle.

---

## BATCH 2 (straight after batch 1, no stop)

### 2.1 "Sitting behind the bench": OWNER CHECK (`HIDE_TALL_COVER`)
- **State (PC, 28 Nov, v1438):** no ragdoll sat on a bench or hid in 25 s of Play (18 lab bodies), so there was nothing to capture. The BenchService seat height on v6 is not checked.
- **Cause found (cloud):** the owner's capture is a SCARED ragdoll HIDING (SCARED_HIDE). It took the nearest anchored part at least 3 studs tall and 2 wide as cover, and benches, lamp posts and signs counted, so it stood behind a bench and peeked over it.
- **Now:** cover must be taller than its head, at least 1.5 studs thick both ways, and never a bench.
- **Also check** the real bench sitting (BenchService). Its seat height comes from the OLD limb sizes. On the thicker v6 body, check in a side capture that the hips are on the planks and the back is not inside the backrest; if not, add the v6 hip depth to `seatHeight` and move the seat point 0.25 studs forward.
- **Proof:** a scared ragdoll hiding behind a wall or tree; 3 benches with sitters, from the front and the side.

### 2.2 Bandages and plasters that sit right and can be seen: see 0.11 (cause found 28 Nov)
- **Find the cause:** the capture shows a gauze floating as a flat box off the arm, and no plaster at all.
- **Build:**
  - **the bandage:** a ring mesh around the v6 limb, its axis along the bone, its radius the v6 limb radius at that point (BodyShape) + 0.02, moved with the bone in SmoothBody's drive;
  - **the plaster:** a small rounded beige patch mesh ON the skin at the wound point, aligned to the surface, visible from 30 studs.
- **Proof:** a patched-up arm, leg, chest and head from 3 m and 10 m.

### 2.3 Bones break by weapon and by number of hits: PART (`BONES_RETUNE`)
- **PC 28 Nov (2): the break PROVEN in Play by the real shot path; the X-ray crack line is an OWNER CHECK.**
  - Blaster through the client's HitRequest on a living body:
    - try 1, 3 shots on the right lower leg: `BrokenJoints = RightHip`, the card "Right leg: CRACKED", the body Ragdoll;
    - try 2, 4 shots on the left lower leg: `BrokenJoints = LeftHip`, the card "Left leg: SHATTERED", and the body still Walking, Alive at 73 %.
  - Capture `bone_broken_xray5` (X-ray on, phone emulator): the skeleton inside the walking body.
    - A crack line on the shin bone can't be told apart at this size, so the CRACKED and BROKEN look is the owner's check.
  - **New, `XRAY_TEST_HOOK` (XRayToggle):** a local player attribute `XRayWant` true/false turns this player's X-ray on and off like the button.
    - Why: the MCP's I key, a mouse click on the X-RAY button and its own `require(DummySkins)` copy all failed to switch the X-ray in the phone emulator.
    - For proofs: `game.Players.LocalPlayer:SetAttribute("XRayWant", true)`.
- **State (PC, 28 Nov, v1438):** Bones.CLASS retuned as the table. Hits counted to the break on a fresh right lower leg (Bones.hit, Play): Blaster 3, Deagle 2, SMG 6, DMR 2, Shotgun 1, Bat at full charge 2, Punch at full 6; each sets BreakReq. NOT proven by capture: the crack line and broken bone in X-ray, the dangle and the limp (the capture was unclear; the body still walked with BoneStages 4).
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

### 2.4 The whole skull in the X-ray: DONE (`XRAY_SKULL_MESH`)
- **State (PC, 28 Nov, v1437):** in Play the whole skull showed (the half top did not reproduce: XraySkull parts were at T0 inside the 0.6 glass ball). The real gap was the look: a plain ball, two ball eyes and a block jaw. Now a real skull mesh (Creator Store 16315382028: cranium, cheekbones, eye holes, a jaw with teeth; 2 meshes, no scripts) in ReplicatedStorage.XrayAssets.Skull, 1.3 studs tall, centred in the round head. Capture skull_mesh_front: full skulls with jaws and teeth inside the X-ray heads. (A second Creator Store skull, 84446245122458, carried two scripts, one 35 KB "ScreenBuilder": it was deleted, not used.) SAVE THE PLACE.
- **What the code does:** the skull (SmoothBody `roundHead`) is a 1.22-stud bone ball centred inside the 1.7 round head, with eye holes and a jaw, so the code alone does not explain a missing top.
- **Test in ONE Play** (X-ray on, a capture after each):
  1. the old Head's X-ray glass shell (DummySkins) drawn opaque over the top: set it to Transparency 1;
  2. the round head ball not taking the X-ray transparency at the top (an accessory lifted by `raise`, a hat);
  3. a CrashMark gui on the ball covering it in X-ray.
- **Fix the one that shows the top.** Make it read as a skull: a cranium, cheekbones, the eye holes, and the jaw with teeth.
- **Proof:** X-ray captures from the front, the side and above.

### 2.5 SPAWN_V2: how ragdolls spawn and gather, done properly (see the design below). Steps 2-3 in this batch.
- **State (PC, 28 Nov): step 1 DONE (`SPAWN_ROOM`).** `RagdollDirector.room(player)` (the near cap minus the living bodies within 45 studs or on their way) is now asked by:
  - VisitorService (already);
  - Lab ALWAYS3/FAST_THREE (`missing` is capped by room);
  - GreeterService.send (no greeter when room is 0; asked again later);
  - NearbyTwo's refill.

  Not done: EventService's crowd, Watchers and Personas (they do not bring bodies TO a player). Play, 60 s at the spawn: the living bodies within 45 studs every 5 s were 4,4,3,3,3,3,3,3,2,2,4,3. The cap is 5 (the emulator counts as a phone), so it was never over. No errors. Capture spawn_room_above: a few ragdolls under the arch, no crowd. Steps 2-3 (the slot table, request/release) are next.
- **State (PC, 28 Nov): step 2 PART (`SPAWN_SLOTS`, new `Systems/Slots.luau`).**
  - **Built:** the slot table for watching. There are 3 WATCH places round every machine's DropSpot (19 machines), 7-9 studs out, on level free floor (its own ray and room check). Bench seats stay with BenchService, which already books one body a seat. A slot is free when no living body's Home is within 4 studs and its 20 x 20 cell holds fewer than 4. API: `Slots.watchSlots`, `Slots.isFree`, `Slots.watchSpot(owner, near, maxD)`.
  - **Proof in Play:** 41 slots on the map, all free; `watchSpot` by the player gives the free slot 9 studs away, looking at its machine.
  - **Wired to:** VisitorService (a visitor's goal is a free watch slot, looking at the machine).
  - **Found:** on the OWNER MAP VisitorService never walks anyone in. Its `floorAt` needs an old lab plot: `Lab.originFor` is (0,0,0) and `Lab.ownerAt` is nil there, so every spot fails (0 visitors in Play).
  - NEXT (step 3): ask Slots from the systems that DO place bodies on this map (Lab rounds, Watchers, EventService), then the capture of spread-out watchers.
- **State (PC, 28 Nov): step 3 LEFT.** Watchers already use their own authored places (`Shared/WatchSpots`: one body a spot, pairs 2.6 studs apart), so they need no Slots. The real step 3, moving the 8 systems to `RagdollDirector.request/release`, is a rewrite of how every system gets its bodies; it is left for its own run. The near cap (step 1) keeps the crowding down meanwhile: 2-4 living bodies near the player in 60 s, cap 5.

### 2.6 Every killer has its own real, creative death: DONE for 5 in this run (`CHICKEN_GRIP`, `FROG_TONGUE_JOINT`, `MOLE_DRAG`, `WASHER_PULL`, `PLANT_LIFT`; `VACUUM_SUCK` not on this map)
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
- **State (PC, 28 Nov): 1 of 5 DONE, the CHICKEN (`CHICKEN_GRIP`, LabCreatures BUILD.Chicken).**
  - **Cause:** after 3 pecks, `hideBody` made the body vanish and `hold` kept it invisible over the nest while the egg grew: a teleport, no real harm.
  - **Now:** each peck is a real wound (`CreatureGrip.bite`). The hen takes the body by the HEAD in her beak (`CreatureGrip.grab`: a real joint, the server simulates it, it dangles), waddles it to the nest, bites once more and drops it beside the nest. Then the egg gag and the throw run as before. If the grab fails, the old way runs.
  - **Proof (a body put in the coop from the server):** the trace shows it held in the jaws 1.0-2.6 s, lifted to beak height (7.4) and carried 4 studs to the nest (x 1068 to 1064), then dropped and thrown. Captures: chicken_grip_2 (the HUD: "Belly: HAIRLINE, 12 % health, OUT COLD" after the pecks, the egg growing) and chicken_drag (the ragdoll hanging by its head from the hen's beak). The TRY button's Session "Try" "Chicken" did not start the hen within 25 s (1.9 is still PART).
- **State (PC, 28 Nov): 2 of 5 DONE, the FROG (`FROG_TONGUE_JOINT`, LabCreatures BUILD.Frog).**
  - **Cause:** the frog already does its idea in 3 beats: the tongue, the gulp with a kicking lump in the belly, the burp with slime and bones, then the body is spat out. The one teleport was the reel: `hold` moved the body to the tongue tip every frame.
  - **Now:** the body is really stuck. There is a BallSocket from the sticky tip to its chest, it counts as Held (no lift fighting) and the server simulates it while the tongue pulls it in. The tongue's slap is a real wound. The joint goes when the tongue does, and the body's player gets it back. Being inside the frog (hidden while the lump kicks) is the swallow itself and stays.
  - **Proof:** a body put 10 studs in front of the frog was stuck 0.9 s later. Capture frog_tongue: the pink tongue stretched from the frog to the ragdoll on its tip, purple blood at the chest, the HUD "Chest, 92 % health". No errors.
- **State (PC, 28 Nov): 3 of 5 DONE, the MOLE (`MOLE_DRAG`, LabCreatures BUILD.Mole).**
  - **Cause:** the hole opened under the body and `hideBody` made it vanish at once.
  - **Now:** the mole bites it by the LEFT FOOT (CreatureGrip, a real wound) and sinks over 1.8 s, pulling it down feet first into the hole. The body's collision is off meanwhile, so the earth lets it through; it gets it back when it bursts out elsewhere. Only then is it hidden for the trip underground, and the burst-out is as before.
  - **Proof:** the trace of one drag: foot 1.8 to -2.1, head 6.3 to 2.3 (half the body under the ground) before it was hidden. Capture mole_drag3: the mole up out of its hole, biting, the HUD "Left foot, 96 % health". The drag was 1.1 s, too fast to see; it is now 1.8 s.
- **State (PC, 28 Nov): 4 of 5 DONE, the WASHER (`WASHER_PULL`, LabCreatures BUILD.Washer).**
  - **Cause:** the body vanished the moment the door opened, and a small puppet spun in the drum.
  - **Now:** the drum takes the body by the chest at the open door (a real joint, server-simulated, Held) and pulls it in over 0.8 s. Its collision is off and comes back when it is spat out. Then the spin cycle with the puppet runs as before (the real body is too big for the drum).
  - **Proof:** caught 0.7 s after it was put at the door, chest at z 92.4 on its way from the door (91.5) to the drum (95.6). Capture washer_pull: the ragdoll at the washer's open front.
- **The VACUUM (`VACUUM_SUCK`): built, NOT proven.** The nozzle catches the body by the foot (a real wound) and sucks it in feet first while the robot shakes, then the spin and spit-out as before. But this map has NO vacuum robot (the CreatureYard holds Spider, Frog, Plant, Chicken, Whale, Washer, Compressor, Mole and Slingshot), so it cannot be seen here. It stays behind its switch for a map that has one.
- **State (PC, 28 Nov): 5 of 5 DONE, the PLANT (`PLANT_LIFT`, LabCreatures BUILD.Plant).**
  - **Cause:** the plant already chews and spits out bones, but the body vanished the moment its jaws shut.
  - **Now:** the jaws hold it (a joint at the chest, server-simulated, a 2-tooth bite), and it hangs from them while the plant pulls back up (0.9 s). Only then is it swallowed (hidden) for the chewing; it is spat out as before.
  - **Proof:** held 0.9 s after it was put by the plant, its chest lifted from y 4 to y 14.9 into the plant's head. Capture plant_lift: the plant with the ragdoll up in its jaws, the HUD "Belly, 79 % health". No errors.
- **2.6 in this run: DONE for 5 (chicken, frog, mole, washer, plant), plus the vacuum built but not on this map.** Left for a later run: Spider (already a cocoon), Whale, Slingshot, the animals (bear and T-rex already use CreatureGrip; crocodile) and the machines.

### 2.7 No more plain-part machines or creatures: STARTED
- **PC 28 Nov (v1439), the GYRO: DONE (`GYRO_MODELS`).** Studio's generate_mesh makes good meshes in the place (no upload step), so it is the pipeline for the rest of 2.7:
  - V3Assets.GyroPlatform: a round steel deck with a yellow railing and a gate, scaled to 24 wide;
  - V3Assets.GyroBooth: a red and white striped control booth with its desk and red button;
  - the stands are now painted round yellow posts;
  - the old pad and button are invisible gameplay parts.

  Capture gyro_models: the rings on the railed platform with the booth beside it.
- **PC 28 Nov (v1440), the PRESS: DONE (`PRESS_MODEL`).** V3Assets.PressFrame is a generated hydraulic press frame: yellow columns, a hazard-striped crossbeam and the big cylinder. It is fitted round the bed (width S + 2.6, height to the old top beam) and scaled with the machine; the plain pillars, braces, sleeves, beam, bolts, hoses, ram, lamp and sign are hidden; the bed, the moving plate and the footing stay. Capture press_front.
- **PC 28 Nov (v1441), the STRETCHER: DONE (`STRETCH_MODEL`, `STRETCH_FRAME_SPREAD` 1.55).** V3Assets.StretchFrame is a generated steel gantry: four posts with motor housings and orange bands, top rails. It is turned a quarter and spread so its posts stand on the machine's corners (the mesh's posts sit inside its box); the plain posts, bands, motors and rails are hidden; the drums, booms, claws, lamps and levers stay. Capture stretch_model2: the levers on the posts, the booms hanging in from the rails.
- **PC 28 Nov (v1442), the TESLA COIL: DONE (`TESLA_MODEL`).** V3Assets.TeslaTower is a generated Tesla coil: a metal base, a tall copper-wound column and a horizontal toroid, 24 tall. The plain base, column and disc are invisible gameplay parts (sparks, DROP HERE). Capture tesla_model. A first generation had the toroid standing on edge: it was rejected and remade.
- **PC 28 Nov (v1443), the ARCHERY TARGET: DONE (`ARCHERY_MODEL`).** V3Assets.ArcheryTarget is a generated straw boss with a printed ring face on a red wooden easel, its face to the shooting side (-Z). The old legs and faces are invisible hit parts (TargetRun and LabCreatures look for TargetFace). Capture archery_model.
- **PC 28 Nov (v1444), the SWEEPER: DONE (`SWEEPER_MODEL`).** V3Assets.SweeperHub is a steel motor housing with fins, bolts and hazard stripes. The arm is 4 x V3Assets.SweeperArmPiece (striped steel with a rubber bumper) end to end, moved with the beam in its turn loop. The plain cube and beam are hidden; the beam still hits. Capture sweeper_model.
- **PC 28 Nov (v1445), LAMPS AND BENCHES: DONE (`PROP_MODELS`).** A count of plain Parts by name in Lab1 showed the park furniture as the biggest plain art: 63 lamps and 34 benches. Now V3Assets.ParkLamp (a cast-iron lamp with a glass globe) and V3Assets.ParkBench (wooden slats and iron side frames, stretched along the seat to 6.2) are drawn over them; the old blocks are invisible (BenchService sits on them, and the lamp light stays). In Play: 63 lamps and 34 benches swapped, 0 old ones visible. Capture bench_close.
- Generation note: generate_mesh only works in EDIT mode ("should only be called from the server").
- **2.7 summary (PC 28 Nov): DONE.** "Replace the 5 worst" is met many times over: the gyro, press, stretcher, Tesla coil, archery target, sweeper, spider web, shredder control box, lamps, benches, crates, barrels and bins. Looked at and kept as they are: the tower (capture tower_now: a steel scaffold with diamond-plate stairs and slides reads as a real steel tower) and the WEAPON TESTING range (capture range_front: a plain building with its sign). Left: the shredder pit is closed, so its rollers cannot be seen (an open pit needs a way out: owner question).
- **PC 28 Nov (v1449), the SPIDER WEB: DONE (`SPIDER_WEB_MODEL`, LabCreatures BUILD.Spider).** The web was 8 neon sticks and 40 neon ring pieces. Now V3Assets.SpiderWebModel, a generated flat silk web (the first try came out as a ball and was deleted), is fitted to the same 26 x 26 face; the sticks are invisible. Capture spider_web_model: the web between its posts with the spider on it.
- **Studio caps one script at 200000 characters.** LabOwnerMap reached 201367 and Studio refused it. The model dressing for the gyro, the Tesla coil, the archery target and the shredder now lives in `Systems/LabProps.luau`, called from the same spots; LabOwnerMap is back to 194655.
- **PC 28 Nov (v1447), the SHREDDER: PART (`SHREDDER_MODEL`).** A real control box with its lever, red button and hazard stickers (V3Assets.ShredderControl) stands at the old lever (capture shredder_model2). Two toothed rollers (V3Assets.ShredderRollers) sit in the pit but cannot be seen: the "pit" is a dark slab on a solid concrete frame, not a real hole. NEXT: cut a real open pit if the owner wants the rollers seen.
- **PC 28 Nov (v1446), CRATES, BARRELS, BINS: DONE (`PROP_MODELS`, LabOwnerMap.dressProp).** V3Assets PropCrate, PropBarrel and PropBin are drawn over the block props, fitted to each box; the blocks are invisible. In Play: 27 crates, 15 barrels and 30 bins swapped, 0 old ones visible. Capture crate_cone_after.
- SAVE THE PLACE. NEXT: the range shell (an interior: needs care), then the LabCreatures/Playground plain parts.
- **State (PC, 28 Nov, v1438):** the yard cones are done (1.15).
  - Creator Store search for the gyro's booth and fence gave only junk: "Fireball" is 180 loose plain parts; a ticket booth carried two 614 KB "LED SCRIPT V5" scripts and broke without them; a cube3D fence is a generator placeholder box without its scripts. All were deleted, none used.
  - The compressor capture (m_compressor) shows a plain-part press that reads as a press.
  - NEXT: Blender 5.3 is installed. Build the gyro booth + fence, the stretcher frame and the range shell with the roblox-blender-modeling gate, upload them (rbx-import-asset), and swap them in behind switches.
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
- **`RAGDOLL_V7.md`:** V7 step 1 is ON (the engine skins v6 from the physics parts).
  - **Cloud fix 28 Nov (`V7_SAME_FRAME`, SmoothBody):** the round head, the holes and the bandages now use the PHYSICS parts too. The head hung off the walking body, and holes slid off or into the limbs, because SmoothBody still placed them from the old FK chain the skin no longer follows. (28 Nov later: wrong for arms and legs, whose drawn axis is off the physics part: `V7_ON_AXIS` puts holes and X-ray bones on the drawn axis under V7 too; see 0.7.)
  - **`RAGDOLL_V7_ANIMATED` is OFF:** slice 1 held walking bodies rigid with their legs off the floor, carried by the lift, so the legs froze in one pose and the body GLIDED (the owner's test). The balancing walk with UPRIGHT_WALK and LEG_ONE_WRITER is back until the real thing works.
  - **V7-2 done right (the least laggy walk that looks real on every device):**
    1. An `AnimationController` + `Animator` in every dummy.
    2. REAL walk and run clips: made in the Animation Editor or Blender, or the official Roblox R15 walk and run animations (they fit R15 names), published as assets the game owns.
    3. While Standing, Walking or Fleeing, the Motor6D-style pose comes from the clip through the AnimationConstraints (`Transform` from the Animator's pose: sample the playing track's pose each frame into the joint targets), speed-matched: clip speed = ground speed / the clip's stride speed, so the feet do not slide.
    4. The feet stay planted: the legs collide again; foot IK keeps each planted foot on the ground.
    5. The root is moved by the drive at the real walking speed (no glide): stride length x step rate = speed.
    6. Every screen plays the clip locally from the replicated speed and state, so the network sends no joint data and phones pay only for the clip.
    7. A hit switches to physics at the same pose (as now).
  - **Proof:** a side capture series of a walk and a run (feet planted, no sliding, no glide, the head on the neck), FPS on a phone, and the SMOKE ROUND. Only then `RAGDOLL_V7_ANIMATED = true`.
- **`PERF_MOBILE.md` §6:** lag-free 2, the items not yet built.
  - **State (PC, 28 Nov):** checked against §6: items 0, 1 and 10 are DONE; 2-9 are PART DONE v1386-v1400 (sleep, the off-screen skin rate, PERF_LEVELS, HighlightCap, the pools, the loop checks, the GroundGuard slices). What is left needs a phone: the standing sleep for far living bodies (item 2 step 2) and the v6 LITE mesh (item 3, PARKED). The owner's phone and iPad test in the final list is the proof.
- **`MILD_EXTRAS.md`:** finishing.
  - **State (PC, 28 Nov, v1448): DONE.** CRUDE_HUMOR and BOO_MASK are on. The one gap was the Play log line "[N7Models] no Weapons model 'FartGun'": the fart gun was a built stand-in. Now ReplicatedStorage.N7Assets.Weapons.FartGun is a generated cartoon toy (a lime-green blaster with a gas tank on top and a purple grip; capture gen_fartgun_side), 2.2 long, facing -Z like the others. The warning is gone in Play. Before publishing: the questionnaire (crude humour Mild, fear mild).
- **The rest of OVERVIEW's ORDER,** at THE FINISH LINE's bar.
- **DOG3 last.**
  - **State (PC, 28 Nov): BUILT in Blender, NOT in the game.**
    - The script is `art/models/dog/build_shepherd_v3.py`; v1 is kept. It gives 9,090 tris, the same 24 bone names, 6.45 studs long.
    - The 7 points:
      1. real hind legs with the dog's Z (the stifle forward, the hock back and up, a near-vertical metatarsus; a second round moved the hock and shrank the haunch so the angle shows);
      2. flat paws with 4 toe pads;
      3. a longer muzzle with a black nose and a mouth line;
      4. a short, thick neck;
      5. a deeper, broader chest (from the front: one broad body);
      6. a crisper saddle edge (still a little frayed where the mesh is coarse);
      7. a long, bushy tail.
    - Renders: `art/models/dog/review_v3/` (side, three_quarter, front, closeup_head).
    - **Found:** the GAME's guard dog is still `V3Assets.GermanShepherd`, the Creator Store K9 mesh (asset 432602064, no bones). The Blender v1 was only imported once as a loose `Workspace.shepherd` model.
    - NEXT: upload `shepherd_v3.fbx` (Open Cloud, a permanent asset on the owner's account), then make GuardDog use it behind a switch. Owner question.

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
