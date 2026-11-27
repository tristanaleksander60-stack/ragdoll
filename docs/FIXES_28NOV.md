# FIXES 28 NOV: the owner's test on the evening of 27 Nov (TOP PRIORITY, before everything else)
> The owner was angry, and rightly so: "det her ligner noget en 3-årig har lavet", "lad mig teste, så det ikke tager 10 timer", "jeg har bedt dig fikse det 5. gang i dag".

## HOW THIS RUN WORKS (the owner's newest order, it wins over every older one)
- **SMALL BATCHES, THEN STOP.** Batch A below, then STOP and give the owner a short Danish "Test selv" list (at most 10 lines, phone first). Wait for the owner before batch B. Never a 10-hour run again.
- **DONE means SEEN.** An item is DONE only when you have:
  - one Play capture that shows it working, from the owner's own angle (the same spot as the owner's screenshot);
  - compared that capture with the owner's complaint, written in one line.

  "The code is in" is not DONE.
- **NO PRIMITIVE-PART ART, EVER, for anything a player looks at** (machines, rides, props, vehicles' bays, signs):
  - use a real model from Blender (with the quality gate) or a malware-checked Creator Store model;
  - if a capture looks like plain blocks and cylinders, it is NOT done;
  - list every machine still built from plain parts in this doc and replace them, worst first.
- **Never "safety" placeholders that look broken:** no fence across a stair, no glass wall a player can fall behind without a way out, no tank without a way out.

## CLOUD CODE ALREADY WRITTEN (push into Studio first, length check, one Play)
1. **The 5 vehicle passes** (`Systems/VehicleService.luau`):
   - GoKart 2098603396;
   - Police 2098855450;
   - MonsterTruck 2099065438;
   - Bulldozer 2098381516;
   - FireTruck 2101716732.

   They now say Drive and prompt the pass. Check each plaque shows its price.
2. **No floating world texts** (`Config.WORLD_POPS = false`):
   - every pop() returns at once: Playground (the machines' scores and "28 stud DROP!" via DropScore), PlayerCPR, LaunchPads, TargetRun, WhaleSpout ("TAIL SLAP!"), AnimalCove and BoxingMatch;
   - FxController bonePop ("CRACK!");
   - the RocketRide countdown board stays empty.

   Check: no "stud DROP!", "TAIL SLAP!", "SMASH!", RPM/G or CRACK text anywhere. If another machine still shows a floating text, find its BillboardGui and put it behind WORLD_POPS too.
3. **Carried ragdolls no longer fly to the top of machines or the tower** (`Config.CARRY_FLOOR_RAY`, `Client/GrabController.luau`).
   - **The cause:** "never through the floor" cast its ray from 30 studs ABOVE the body, so under a canopy, roof or upper tower floor it hit the roof first and put the body on top.
   - **Now:** the ray starts just above the body, and in the player view the body is carried at most 3 studs over your middle (the camera is above you).
   - `Systems/Unstick.luau`: never the sky ray with GROUND_INSIDE_ONLY; the own-floor ray reaches 60 down.
   - Check with captures:
     - carry a ragdoll into the bowling lane under its canopy;
     - carry one up the tower stairs to each floor;
     - carry one into 3 other roofed machines.
4. **BUILT v1419 (DropSpots.scan, started in Main):** 18 spots per lab, found by each machine's load part (Stretch, Boxing canvas, Press bed, Fan mouth, Rocket/Gyro/Sweeper pads, Shredder pit, Seesaw, T-rex ground, Bear, Whale, Tesla, the tower's top floor, the bowling lane start, 3 wheelchairs); heights checked in Play. The sign itself shows only while carrying: OWNER CHECK. **DROP HERE at EVERY machine** (`Systems/DropSpots.luau` new, `Client/LabGuideClient.luau`).
   - **The cause:** the sign only knew the old guide rings (the creatures, the old StationPads and 4 old machine names), and none of the new map's machines had one.
   - **Now:** any part tagged `DropSpot` counts. TO DO in this batch: call `DropSpots.add(machineModel, exactLoadPoint, name)` in EVERY machine that takes a carried ragdoll, at the point where a dropped body is taken:
     - Bowling (the lane start);
     - the tower (DropScore's top floor);
     - the gyro (MapMachines hub pad);
     - StretchMachine, Compressor (Bed), FanMachine and RocketRide (pad);
     - WhaleSpout and AnimalCove;
     - the BoxingMatch canvas;
     - WheelchairRide;
     - every StationPad, LavaPool, CannonPad, TrampolinePad and the creatures (these already have rings).

     Grep for every ProximityPrompt that loads a ragdoll, so none is missed.
   - Check: a capture at each machine while carrying shows ONE sign, at a fixed size on screen, over that machine only.
5. **Swim out of the aquarium** (`Config.PLAYER_SWIM`, `Client/PlayerSwim.luau` new, started in Main).
   - **The cause:** the tanks are part water, so the Humanoid never swims and a player stood stuck on the bottom.
   - **Now:**
     - you float and swim: move with the stick or WASD, hold JUMP to rise, let go and you sink slowly;
     - JUMP at the surface climbs you out onto the floor outside the nearest side;
     - a safety net sets you outside after 25 s in the tank, or 6 s still on the bottom.
   - Check: jump in, swim, get out on each side. Also on a phone (the jump button).

5b. **Time speed chips "stuck on 2x"** (cloud code: `Client/TimeDial.luau` and `Client/HudV3.luau`):
   - **The cause:** the 2x chip was always orange (a fixed colour), so it looked chosen, and a tap within the server's 0.25 s gap was dropped without a word.
   - **Now:** only the speed that is really on is lit, there is a 1x chip to go back to normal, and the LAST tap is always sent.
   - Check: 0.25x, 0.5x, 1x, 2x and STOP, in any order and fast.

5c. **No way out of build mode** (cloud code: `Client/BuildController.luau`, `Config.BUILD_DONE_ALWAYS`):
   - **The cause:** the way out was the column's SANDBOX tile, which the new HUD no longer has.
   - **Now:** the big green DONE shows on every device while building.
   - Check: on PC, phone and tablet, BUILD then DONE. Also add a 1-line hint at the start: "Tap DONE to stop building".

5d. **First person when you switch weapons or shoot, and the eye on phones** (cloud code: `Client/FirstShotFP.luau`, `Client/FirstPerson.luau`, `Client/PhoneClean.luau`, `Client/HudSlots.luau`; `Config.FP_AUTO`, `Config.FP_EYE_PHONE`):
   - **The causes:**
     - only the very first shot ever put you in first person, so later shots and weapon picks never did;
     - `PhoneClean` hid the eye button (`FirstPersonTouch`) on every touch screen.
   - **Now:**
     - picking a weapon glides you into first person (0.4 s); a shot puts you in at once, and the shot still lands;
     - leaving with V, the eye, a pinch out or a scroll out holds until your NEXT weapon pick;
     - never in the lab view, seated, building, Director, with the mech arms, or while a window is open (a pick from the menu waits until it closes);
     - the eye is back on phones and tablets: 52 px in the top-right safe corner on a phone, brighter while first person is on.
   - **Phone check (our biggest group):**
     - pick a weapon, then shoot;
     - leave with the eye and shoot again: you stay out;
     - pick another weapon: you go in;
     - check that the touch look-drag and SHOOT work in first person;
     - check that the eye never covers Roblox's own top-right buttons or the X-RAY chip. If it does, move it (HudSlots `Eye`).

5e. **The hotbar** (owner's screenshot: the slots lie on top of each other, the selected one has a turning 3D gun off-centre):
   - **cloud code:** `Config.HOTBAR_3D = false` (PokeController): no turning 3D model in the selected slot and no spring on selecting. The drawn icon stays in the middle of the box, selected or not.
   - **TO DO:**
     - find why the slots overlap on a phone (the owner's capture: the selected orange slot under slot 2): check PokeController.plan's cell and GAP on a phone at the MiniBar's 0.6 rest size AND opened, the ring (UIStroke) thickness, and the ammo chip ("30/30") width;
     - every slot at least 6 px apart in every state, the ammo chip inside its own slot's top edge, the icon centred;
     - check with captures on a phone: rest, opened, each slot selected.

## CLOUD CODE ROUND 2 (27 Nov late, after the PC's round 2): push these into Studio FIRST (length check), one Play
- **`Shared/Ragdoll/ActiveRagdoll.luau` + `Config.UPRIGHT_WALK`** (the owner, the 3rd time: "de læner sig virkelig mærkeligt bagud nogle gange og går"). Two causes were found in the code:
  1. **The walk lean leaned BACK whenever a body slowed down or turned** (`R.lean` from a negative acceleration, up to -0.1 rad). It is now forward only: about 2 degrees at a walk, about 6 at a run, plus a little more while speeding up.
  2. **Only the pelvis was held upright** (Balance on LowerTorso), so when the drive pushed the hips forward, the chest hung back on the waist joint alone. A `ChestBalance` AlignOrientation on UpperTorso now follows the pelvis balance exactly (the same upright, half the torque, on and off with it, so limp states are untouched).
  - **Check, with captures from the side:**
    - 5 ragdolls walking, one running to you, one stopping and turning;
    - none leans back;
    - standing still is unchanged (no new rocking);
    - a hit still knocks them down as before.
- **`Client/FirstPerson.luau` + `Client/FirstShotFP.luau` + `Config.FP_EXIT_FIX`** (the owner: "man kan trykke V, men våbnet forsvinder bare og man bliver i first person").
  - **The cause:** the camera kept for leaving could itself be first person: LockFirstPerson, or a max zoom squeezed to the head by the weapon-pick glide.
  - **Now:**
    - leaving first person ALWAYS gives the normal camera behind you, pushed out to about 10 studs;
    - only a real third-person camera is kept;
    - no zoom glide on a weapon pick (a plain switch);
    - scrolling in does not pull you back in for 1.5 s after leaving.
  - **Check on PC:**
    - pick a weapon (in), V (out, the camera behind you, the gun in your hand), shoot (you stay out), V (in), V (out);
    - pick another weapon (in);
    - on a phone, the same with the eye.
- **Also from round 1, if not yet pushed:**
  - `Client/TimeDial.luau`, `Client/HudV3.luau` (5b);
  - `Client/BuildController.luau` (5c);
  - `Client/PhoneClean.luau`, `Client/HudSlots.luau` (5d);
  - `Client/PokeController.luau` (5e).

## BATCH A (build now, then STOP for the owner's test)
**Round 1 done (v1418-1423), STOPPED for the owner's test:** cloud code in Studio (20 files + FP_AUTO, a Config syntax break fixed), 4 DROP HERE, 6 stairs, 7 parking lot, 9 X-ray, 12 crowding. **Next round:** 10-11 holes and bandages on the v6 skin, 13 no block ragdolls, 14 bike riders welded, then 15/16/8 the real models (weapon testing building, T-rex, gyro).
15. **PART DONE v1428 (`RANGE_CLEAR`, ShootingRange), SEEN:** the range stands just outside the compact plan where the hills begin (terrain y 7 to 40 across its depth); 10 s and 25 s after start (after the landscape fills the hills) the terrain round it (its box + 6 studs, floor up 90) is made air; captures: the whole facade and the open entrance stand free, inside a concrete firing line with a grass backstop where the hill was cut. LEFT: the plain-part shell -> a real model (next step). **WEAPON TESTING is half inside a mountain** (the building by the railway):
    - move it onto flat open ground, or cut the hill back, so the whole building and its entrance stand free with a path to the door;
    - replace its plain-part shell with a real model: a proper firing-range building with a sign, doors and a roof (Blender or a checked Creator Store model);
    - check every other building on the map for clipping into hills: one capture per building.
16. **DONE v1429 (`REX_ANIM`), SEEN:** V3Assets "TRex" is now a real skinned T-rex (Creator Store 12948588771, "T REX Dinosaur", 1 MeshPart, 33 bones, NO scripts: malware pass clean; scaled to 38 long to fit the 37 x 47 pen, facing the gate). The old block T-rex is kept in ServerStorage.OwnerBackup.TRex_OldBlocks_28Nov. Client/RexAnim plays the model's own clips on its bones (idle loop, walk while it moves, the roar every 20-40 s); the rampage, feeding and DropSpot work as before (it moves by PivotTo). Captures: a textured dinosaur in the pen, mouth open, head over the gate wall; the head bone moves. **The T-rex is made of plain blocks with a leaf material.**
    - Replace it with a real dinosaur model: Blender with the quality gate ≥ 8.5, or a malware-checked Creator Store T-rex with real proportions and a mesh skin, at the same pen.
    - Give it an idle animation (breathing, a head turn, a roar every 20-40 s) and keep its feeding (DropSpot).
    - The same goes for every other creature or prop made of blocks: list them here and replace them, worst first.

6. **DONE v1420 (`STAIR_OPENING`, LabOwnerMap), SEEN:** the stair-side rail now stops at a post 5 studs short of the stair, so the top step leads straight onto the platform (capture from the stair top: open, rails only on the drop sides). Every stair on the map checked in Play (the space past each top step): the feeding stair, the tower (60 steps), the plaza steps and both lab/plaza stairs are open; the only "blocked" one is the spectator stand, whose top row has its back wall and guard (correct). **The aquarium stairs:** the platform at the top of the aquarium stairs has a railing ACROSS the stair, so you cannot walk onto it.
   - Make a 5-stud opening where the stair lands, and keep the rails only on the open drop sides.
   - Check every stair on the map for the same fault (a rail or wall across a stair landing).
7. **DONE v1421 (`PARKING_STRAIGHT`), SEEN:** the causes: the 45-degree bays overlapped (7 vehicles pushed off their bays by the home check), the row started on the spawn statue, the plaques had a fixed offset, and the home check counted the NEIGHBOUR vehicle as a block (its comment said it must not). Now straight bays left to right (BICYCLE, SILVIA, FORD TRUCK, PANZER, GO-KART, POLICE CAR, MONSTER TRUCK, BULLDOZER, FIRE TRUCK), each its vehicle's width + 3.5, starting past the statue, every vehicle facing the walkway with its plaque on the kerb in front of it (top-down capture: one straight row; walkway capture: FORD TRUCK, PANZER, GO-KART, POLICE under their own vehicles). The bicycle is ridden off by the ragdoll cyclist and comes home when idle. **The parking lot (the owner's screenshot):**
   - each vehicle stands exactly centred in its own bay, facing out;
   - its plaque is on the kerb right in front of ITS vehicle, with the right name and price:
     - SILVIA in front of the Silvia, not a statue;
     - the TRUCK plaque in front of the Ford;
     - GO-KART in front of the go-kart, not the police car;
     - BICYCLE in front of the bicycle;
   - nothing else in a bay: no statue, no ragdoll standing in the bicycle bay;
   - order the bays left to right and size each bay to its vehicle;
   - check with ONE top-down capture of the whole lot plus one from the walkway.
8. **The gyro** ("the yellow thing that spins round with an orange line and a black box in the middle": `MapMachines`).
   - Replace the plain-part build with a real model:
     - a proper gyroscope ride: 3 nested painted steel rings that spin on different axes;
     - a padded seat with straps at the centre;
     - a raised platform with steps, a safety fence with a gate;
     - a small control booth with the big red button;
     - lights on the rings.
   - From Blender (quality gate ≥ 8.5, capture next to a real gyro ride photo) or a malware-checked Creator Store model.
   - Then list EVERY other machine still built from plain parts here, and replace the worst 3 in this batch.
9. **DONE v1422 (`XRAY_CALM`), SEEN:** the body was near-clear light glass with the living face (eyes, red cheeks) drawn over the skull, and a second skull from DummySkins on v6 bodies. Now the v6 body is a dark blue see-through silhouette at 0.6 (the SurfaceAppearance map tinted: it draws over Color), the face hidden in X-ray, the bones pale ivory, one skull (SmoothBody's), and a shot limb's bones show as a soft ivory fill with NO outline, eased in over 0.3 s. Captures (front and back, X-RAY on): ivory skull, ribs, spine and limb bones in a calm blue body. **The X-ray (2/10, "hurts the eyes"):**
   - the classic X-ray look: the body a dark navy, see-through silhouette (about 0.6 transparent), the bones a soft pale ivory or blue-white;
   - NO Neon, NO glowing Highlight outlines, nothing white-hot, no flicker;
   - real bone shapes in every limb, the head and the hands and feet: a skull with eye holes and a jaw, a ribcage with separate ribs, the spine, the pelvis, two bones in each forearm and shin, and hand and foot bones;
   - the shot limb (3 in a row) fades in over 0.3 s, holds 2 s and fades out over 1 s, as before;
   - check: a capture next to a real X-ray reference image. It must be calm to look at for 10 s.
10. **DONE v1427 (`HOLES_EVERYWHERE`), SEEN:** head holes now sit on the round v6 head (they lay on the hidden small physics head, and a "burst head" rule released them every time SmoothBody re-hid it; severing is off, so v6 bodies skip that rule); capture: two dark holes on the round head. BRUISE_PATCH (my purple bruise discs of v1405) is OFF: purple only in the hole picture and the drips. **Bullet holes everywhere on the skin, never a purple blob:**
    - a hole must show at every hit point: the round head, hands, feet, the joints, the back and the sides;
    - the purple 3D discs and blobs are removed completely: purple shows only as the wet inside of the hole picture and the 3 newest holes' drips;
    - check: 20 shots spread over one body, with a capture from the front and the back.
11. **DONE v1427, SEEN:** the gauze looked up its body through limb.Parent, which is the Skins folder, so the v6 size never applied and the rings (0.58-0.74 across) sat inside the v6 limb; now 0.77-0.90 across at v6's radius + 0.05; capture: white gauze on the forearm and the shin. **Plasters and bandages visible:**
    - they sit on the hidden block parts (SmoothBody `hideBlocks`) or inside the thicker v6 skin;
    - draw them on the v6 surface (a ring or patch mesh at the limb's v6 radius, moved with the bone in SmoothBody's drive);
    - check: a capture of a patched-up body.
12. **BUILT v1423 (`NO_CROWD`, Lab):** spreadSpot skips a spot with 3 goals within 10 studs or a 20 x 20 cell holding 4; every 3 s a free standing ragdoll with more than 3 others within 10 studs (or in a cell of more than 4) picks a new spot (watchers, the ALWAYS3 trio, TRY calls, commanded and mood ones stay). Play (Studio = phone, 9 bodies): biggest 10-stud clump 2. OWNER CHECK on PC (40 bodies). **No crowding:**
    - at most 3 ragdolls per activity spot, at least 4 studs apart, at most 4 in any 20 x 20 stud cell;
    - the owner's screenshot showed 8 around the rock;
    - the RagdollDirector enforces it, sending the extras on to another spot.
13. **BUILT v1425 (`V6_EVERYONE`):** the crowd people (Mannequin false) now wear the v6 body too, tinted by their role's shirt (CrowdTint; X-ray keeps the tint after); phones draw 20 v6 bodies within 100 studs (was 12 within 80, the old blocks beyond). The v6 LITE mesh for the far ones stays PARKED (an upload). **No old block ragdolls in view** (until V7 makes it impossible):
    - the crowd people (`CrowdService` calls `removeMarks`, so `Mannequin = false`) get the v6 body too, tinted by their role colour;
    - SmoothBody builds a body BEFORE it is shown (a new body stays invisible until its mesh is ready);
    - the far ones beyond the reach get the v6 LITE mesh (`PERF_MOBILE.md` §6 item 3).
14. **BUILT v1425 (`BIKE_WELD`):** the rider's pelvis is welded to the saddle and the bike is simulated by the rider's own screen (one assembly, one simulator; the server's steering targets still drive it); the ride's end removes the weld. Play: a ride started in 9 s, pelvis on the saddle (0.00 off), owner = the lab player, 12 studs/s; a capture shows the grey v6 rider on the bike. OWNER CHECK: no jitter while riding. **The bike riders** jitter on the bike and are sometimes the old body.
    - **The cause:** the server steers the bike (AlignPosition targets over the network) while the lab player's client simulates the rider and holds them over the saddle with forces.
    - **Fix now:** weld the rider to the saddle in a pedal pose (one assembly), and let the server own and steer both bike and rider. A hit breaks the weld and the rider falls off.
    - Also check why a rider is drawn as the old body (Ride/seated state or the MachineHidden attribute in SmoothBody).

## BATCH B (after the owner's OK on A): the ragdolls themselves = `RAGDOLL_V7.md`
- The jitter while standing, leaning back when walking, the legs bugging: these come from the always-balancing physics body. They are not tuned again (5 failed rounds). V7 replaces it: animated until hit.
- Build V7-1 (the spike), STOP, owner test; then V7-2, STOP, owner test; and so on.
