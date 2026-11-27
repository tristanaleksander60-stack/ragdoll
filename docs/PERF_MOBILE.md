# Phones and tablets: much less lag, much smoother, keep the cool stuff (owner, 26 Nov 2026)
> "Lig en plan for at telefon og tablet især, får meget mindre lag og alt kører meget mere smooth, uden at fjerne fede detaljer og sådan noget som holder dem derinde, medmindre det fucker dem helt."

**Principle:** keep every feature that keeps players in (purple splatter, X-ray, the dog, impacts, machines, talking ragdolls, the big lab). Make each one CHEAPER (fewer copies, pooled, nearer only, simpler far away). Remove a detail only if it alone breaks the frame rate on phones.

**Targets:**

| Device | Frame rate | Memory |
|---|---|---|
| mid phone (iPhone 11 / Galaxy A52 class) | 60 fps in the lab, never under 30 in events | under about 900 MB |
| low phones | a steady 30 | |
| tablets | 60 | |

No hitch over 100 ms when machines run, a big event starts or the lab loads.

## 1. Measure first (no owner testing needed)
- **Read the Creator Hub's Performance page** (FPS, memory, crashes and join time by device) for the last 7 days. Write the numbers here as "before".
- **The game's own Perf sampler** (Systems/Perf, Session_v1): log, by device tier:
  - FPS p50 and p10;
  - memory;
  - physics-active parts;
  - ragdoll count;
  - UI object count;
  - BillboardGui count;
  - particles alive.
- **Studio:** the phone emulator plus the MicroProfiler. Find the top 5 costs in the lab, in an event and with 10 ragdolls flying. Fix the biggest first. (The emulator is only a guide; the live numbers decide.)

## 2. The usual big costs, and the fix for each

| Cost | Fix |
|---|---|
| **Ragdoll physics:** each ragdoll is many parts plus constraints, a Humanoid and AnimationConstraints | phones: max full ragdolls (the existing caps); everything far (over 60 studs) is a light stand-in (`docs/ALWAYS3.md`); sleeping bodies (Anchored when still for 3 s, woken on touch); disable unused Humanoid states; collision between a ragdoll's own limbs only where needed; no extra welds |
| **Humanoids everywhere** (watchers, stand-ins, NPCs) | stand-ins use an AnimationController, not a Humanoid; Humanoid only on full ragdolls |
| **Per-object loops:** many scripts each with their own Heartbeat/RenderStepped | ONE central update loop per system, updating only objects within range, at a lower rate for far ones (10 Hz for far, 30 Hz for mid, every frame only for the nearest) |
| **UI objects** (it was 22.7k; the WEAPONS shelf alone 8.7k) | build menus only when opened, destroy or reuse after closing; recycle list rows; target under 5k UI objects in play on phones |
| **BillboardGuis** (bubbles, signs, TRY, names) | one pool; max about 8 on phones; MaxDistance about 60; none behind walls |
| **Particles and effects** | pooled emitters (no new instances per hit); phones get half the counts, a per-second cap and only within 60-90 studs; no particles off screen |
| **Shadows and light** | CastShadow off on small and far parts, decoration and debris; few lights (FX_CAPS lights by tier); post effects (Bloom, SunRays, DepthOfField) off on low tier |
| **Parts and meshes** | the 10x lab must stay inside the budget (`docs/LAB_TARGET.md`); decoration as few meshes with CollisionFidelity Box/Hull, CanQuery and CanTouch off; RenderFidelity Automatic; LOD meshes for trees and hills |
| **Textures and memory** | resize decals and images to the size they are seen at (512 or 256, not 1024); reuse textures; unload far ones |
| **StreamingEnabled** | tune the stream radius for the big lab (stream out far zones); every machine and script must cope with parts not being there; persistent only where needed |
| **Network** | fewer replicated property and attribute changes per frame (batch them); remotes throttled; ragdoll network ownership to the nearest player; no per-frame server CFrame writes on many parts |
| **Sounds** | pooled; max about 12 playing on phones; far sounds not started |
| **Terrain and water** | the water in the tanks as a simple part with a moving texture (no terrain water); terrain decoration (grass blades) off on phones |

## 3. An automatic quality governor (`Config.AUTO_QUALITY = true`)
- **The start tier** comes from the device (DeviceTier, as now).
- **Every 5 s it checks FPS.** Below 45 for 10 s, one step down; above 58 for 30 s, one step up (never above the device's tier).
- **Each step lowers, in this order:**
  1. far stand-in animation rate;
  2. particles;
  3. shadows;
  4. lights;
  5. the number of full ragdolls;
  6. the draw distance.

  **Never removed:** the splatter on your own hit, the ragdolls you are hitting, the machine you use, the goal line, the dog.
- **The player can still choose** Low / Auto / High in Settings.

## 4. Join and loading
- **First frame fast:** the cover until the lab is in, as now. Stream the near zone first; the rest after.
- **No hitch at join:** spread lab building over frames (no single 200 ms frame).
- **Measure the join time by device** before and after.

## 5. Check
- **The phone emulator and the MicroProfiler,** before and after, at the same 3 spots (the spawn, the busiest machine zone, an event). Write the numbers here.
- **After publishing:** compare the Creator Hub FPS and memory by device over 2 days.
- **Test selv** (Danish) in the run's one list: play 5 minutes on a phone and an iPad; does it feel smooth?

## 6. LAG-FREE 2 (owner, 27 Nov late: "Sørg for ALT er lagfri på telefon og tablet, tænk dybt og smartest")
**Where:** OVERVIEW WHAT IS LEFT 11c, right after `FIXES_27NOV_LATE.md` and `MILD_EXTRAS.md`. Build in this order. Each item has its own Config switch (`LAGFREE_*`, on). One quick Play each; the owner tests on a phone and an iPad at the end.

**Bar:**
- phone: 60 fps in the lab with 8 ragdolls in view, never under 40 in a pile, the boxing, an event or a car crash;
- tablet: 60 fps;
- no frame over 50 ms;
- memory: under 900 MB after 10 minutes (low phones under 700 MB).

**Keep the cool stuff** (§ Principle): v6 on every body in view (the owner's choice, AUDIT 38), the splatter, the X-ray, the dog, the faces. Make them cheaper, never remove them.

### What the cloud found in the code (27 Nov late): the real causes, biggest first
1. **The phone runs its whole lab's physics.**
   - Every lab's ragdolls are simulated by that lab player's own device for their whole life (`DummyControl.giveParts`, `DeviceTier`).
   - Each body is about 16 parts, 15 AnimationConstraints, BallSockets, NoCollision pairs, an AlignOrientation, an AlignPosition and a LinearVelocity.
   - `ActiveRagdoll` has no sleep. A dead pile of 10 bodies keeps all 10 in the phone's solver **and uploads their CFrames** on a phone's mobile link.
2. **The server never knows a phone is struggling.**
   - `QualityGovernor` sets the `Quality` attribute on the LocalPlayer. A client-set attribute never replicates, so no server script reads it (checked: no server reference).
   - The server's caps stay at the device default however low the FPS gets: `RagdollDirector.CAP`, `Config.DEVICE_CAPS` visitors/chasers, Chase, the background boxing.
3. **The governor reaches only 5 things:** particles, PathWalkers (removed), shadows, light range and RealHands. It does not reach:
   - SmoothBody, the DummyLife LOD and ActiveRagdoll `LOD_PHONE`;
   - BloodFx, Highlights, sounds and Birds;
   - the server caps.
4. **SmoothBody v6 runs every frame** (`SmoothBody.step`, RenderStepped):
   - per body: 3-4 `GetAttribute` reads and a new `cfs` table in `drive()` (garbage every frame);
   - bodies within 45 studs are driven every frame even **behind the camera** (DummyLife already skips those);
   - a body lying dead still is driven every frame.
5. **Highlights are made in 17 places:**
   - DummySkins (X-ray), GrabController, HospitalCharts, FirstTwo, GuardDogClient, PlayerGrabClient;
   - NpcTalk, MinuteMoments, FirstVisit, FxController, BuildController, NpcGlow;
   - GoldenRun and MapMachines (server).

   Each visible Highlight costs an extra full-screen pass, heavy on phones and worst on an iPad's big screen. Roblox draws at most 31.
6. **Effects are made new on each hit:** `Instance.new("ParticleEmitter"/"PointLight")` at FxController ~1541 and FeelV2 ~180/~560/~779. These must come from a pool.
7. **Small per-frame waste:**
   - DummyLife `lookWhileTalking` scans every dummy for each chatter every frame;
   - foot IK casts 2 rays per near standing body every frame;
   - `{ "Right", "Left" }` is a new table every call in `layers()`;
   - HospitalCharts has 2 RenderStepped loops and HudV3 one; check that each returns at once when its screen is closed.
8. **The server has about 15 Heartbeat loops** (VehicleService 3, Creatures 3, ToyService, Knockables, GuardDog, CrowdService, ...), and GroundGuard/Unstick query every body. A slow server tick shows on every device as rubber-banding (AUDIT 39 is the same item).

### The fixes (build in this order)
0. **DONE v1385 (with item 1):** Systems/PerfReport + Client/QualityGovernor; remote PerfReport; custom events Fps_p50, Fps_p10, Hitches, MemoryMb with the device in CustomField01 (not in Studio). **`LAGFREE_TELEMETRY`: measure live first** (small, and it gives the owner before/after numbers without testing).
   - Every 60 s the client sends one small packet through `Net`: FPS p50 and p10 over the minute, frames over 50 ms, `Stats:GetTotalMemoryUsageMb()`, bodies it simulates, and the Quality level.
   - The remote is `Perf.Report` (validator: numbers clamped and integer, rate 1 per 30 s).
   - The server logs `AnalyticsService:LogCustomEvent` (`Fps_p10`, `Fps_p50`, `Hitches`, `MemoryMb`) with the device as a custom field, so the Creator Hub shows them per device.
   - The same remote carries item 1's level.
1. **DONE v1385:** the level reaches the server (PerfLevel, seen 2 in Studio); RagdollDirector near cap -1/-2 at levels 1/0 (never under 3); no background boxing at 0. LEFT: visitors and chasers by level. **`LAGFREE_SERVER_KNOWS`: the server follows the real FPS.**
   - The client sends its level (0-3) only when it changes, at most once per 5 s. The server stores it as the player's `PerfLevel` and decides with it.
   - Levels 3 and 2: the device caps as now.
   - Level 1: the near cap -1 and visitors -1.
   - Level 0: the near cap -2, no background boxing, chasers at most 4.
   - Never fewer than `ALWAYS3`'s 3 living near you.
   - Over the cap, the extras walk away as now; they are never popped.
2. **PART DONE v1386 (DummyControl):** a dead or knocked-out body lying still 1.5 s sleeps (anchored, Asleep attribute); hit/push/nudge/move/reset/heal wake it first, a Vital/Held/Mood/Seat/InMachine change wakes it, a fast body or player within 6 studs wakes it (5 Hz); waking hands it back to its owner (seen in Play: sleeps, wakes on revive). LEFT: step 2 (far standing bodies on phones), SmoothBody/DummyLife/GroundGuard skipping Asleep. 2. **`LAGFREE_SLEEP`: sleeping bodies (the biggest win).**
   - **When it sleeps** (decided on the server, from the owner client's report through the existing DummySim report): the body is down (Ragdoll/Out/Dead/lying) and calm (torso under `CALM_SPEED` for 1.5 s). It is not held, not seated or riding, not in water, not in a machine, and not on a moving part.
   - **What sleeping does:** the server anchors every part in its exact pose, so it costs the phone nothing and nothing is uploaded.
   - **It wakes at once on:**
     - a hit or shot, or a blast in range (HitService/Blasts wake it BEFORE they send the hit command);
     - a grab, CPR, a revive or a vital change;
     - a moving body or vehicle within 6 studs. Use `limpMoving` plus the vehicles, checked at 5 Hz, not Touched on every part.
   - **Waking:** unanchor, then `DummyControl.giveParts(owner)` again. Anchoring drops ownership, so it must be given back, or the server simulates the body and it stutters.
   - **Step 2, phones and tablets at level ≤2 only:** a living body that only stands, more than 40 studs away and off screen for 3 s, sleeps standing. DummyLife leaves it. It wakes when it is within 35 studs, on screen, or targeted.
   - **The rest skip sleeping bodies:** SmoothBody drives it once, then not again. DummyLife, GroundGuard and Unstick skip it.
3. **PART DONE v1387:** behind/beside the camera (dot < 0.25, past 6 studs) a near body is driven at FAR_RATE only; a sleeping body is drawn once. LEFT: reach/rate by level, attribute caching, the cfs table reuse, the v6 LITE mesh. 3. **`LAGFREE_SKIN`: SmoothBody costs a third.** v6 stays on every body in view.
   - Behind or beside the camera (the DummyLife dot test): FAR_RATE only.
   - Asleep: no drive.
   - By level: ANIM_REACH 45/35/28/22, and FAR_RATE 15/12/10/8 Hz for levels 3/2/1/0.
   - Attributes (`MachineHidden`, `XRayOn`, the X-ray state) are cached with `GetAttributeChangedSignal`, not read every frame.
   - The `cfs` table is reused, and the Head drive index is worked out once.
   - **A v6 LITE mesh** from Blender: the same shape, UV, colours and bones, about half the triangles, at most 2 bone influences per vertex. It is used beyond 25 studs or at level ≤1, so it looks the same and is cheap. Write the triangle counts here: v6 near target ≤4k, lite ≤2k.
4. **PART DONE v1393:** `Config.PERF_LEVELS` (skin reach/rate per level, read by `QualityGovernor.get`, `.Changed`), smarter steps (5 s under 40 or 3 hitches in 5 s down, 45 s over 58 up, no steps in the first 30 s, a phone over 1200 MB starts at 1). LEFT: move the other modules' numbers into PERF_LEVELS. 4. **`LAGFREE_BUDGET`: one budget table for everything.**
   - `Config.PERF_LEVELS[0..3]` holds every number:
     - skin reach and rate;
     - DummyLife LOD_NEAR, LOD_FAR and MID_RATE;
     - the ActiveRagdoll LOD distance;
     - the particle factor;
     - holes per body on phones (24 now, AUDIT 37) and splats on screen;
     - Highlights, sounds playing, birds and BillboardGuis;
     - shadows, light range and hands.
   - `QualityGovernor.get(key)` plus a `Changed` signal; every system above reads from it.
   - **Smarter steps:**
     - step down after 5 s under 40 fps, or 3 frames over 50 ms within 5 s (hitches, not only the average);
     - step up only after 45 s over 58;
     - a phone that already uses over 700 MB at join starts at level 1.
5. **PART DONE v1389 (Client/HighlightCap):** every Highlight in the place is watched; at most 3/5/10 drawn by priority (held, X-ray, dog, rest), off-screen ones off; only its own CapOff ones are turned back on (seen: an off-screen one switched off). LEFT: Neon X-ray bones on phones instead of a Highlight. 5. **`LAGFREE_HIGHLIGHT`: one Highlight pool.**
   - At most 3 at once on phones, 5 on tablets and 10 on PC.
   - Priority: what you hold or aim at, then the shot limb's X-ray bones, then the dog, then glows and hints.
   - One Highlight per model (Adornee = the model), never one per part. Off screen means off.
   - On phones the X-ray bones use a bright Neon material on the bone parts instead of a Highlight: the same look, no extra pass.
6. **PART DONE v1390:** the FeelV2 shot light is pooled (12 kept), the FxController gold sparks are one emitter moved; FeelV2 emitters were already pooled (the ~560 PointLight is dead code). LEFT: splat cap 40 and the 12-sound cap on phones. 6. **`LAGFREE_POOLS`: no `Instance.new` on a hit.**
   - The emitters and lights in FxController and FeelV2 are pooled: made at join, idle in a folder, re-parented and `:Emit()`ed.
   - Splat decals at most 40 on a phone; the oldest fades.
   - Sounds: at most 12 playing on phones, and a far sound is never started.
7. **PART DONE v1388:** DummyLife: the chat partner kept 0.5 s, foot IK rays at 20 Hz on touch, SIDES hoisted. LEFT: the Active.bind pass over the 66 RenderStepped files. 7. **`LAGFREE_SMALL`:**
   - The DummyLife chat partner is looked up every 0.5 s and kept, not searched every frame.
   - Foot IK rays at 20 Hz on touch devices.
   - The `layers()` table literal is hoisted.
   - **Every RenderStepped/Heartbeat/BindToRenderStep in `Client/` (66 files) returns at once, or is unbound, when its feature is idle** (no screen open, not building, not in a vehicle, no bow). One pass: `grep -l RenderStepped`, and add a small `Active.bind(name, fn)` / `Active.unbind(name)` helper. Examples: HospitalCharts, BuildController, GodMode, MechArmsClient, Cockpit, Speedometer, VehicleFeel, BowClient, AmmoClient and MapBoardClient.
8. **PART DONE v1392:** sleeping bodies are skipped by Unstick (GroundGuard already skips anchored ones). LEFT: the one body scheduler with rates and slices. 8. **`LAGFREE_SERVER_TICK` (= AUDIT 39):**
   - One body scheduler in the RagdollDirector tick. GroundGuard, Unstick, the vitals checks and Creatures each register a callback with a rate (2-5 Hz) and a slice (N bodies a frame, 2 ms a frame in all), round-robin.
   - Sleeping bodies are skipped.
   - The server Heartbeat time goes into item 0's report.
9. **PART CHECKED v1390 (no change needed):** StreamingEnabled on, target radius 400, min 64, Opportunistic stream-out; no lab or map model is Persistent (only the 40 bodies PersistentPerPlayer for their simulating owner, and 1 other); LoadCover already calls RequestStreamAroundAsync at the lab on join. LEFT: texture sizes, background sound preload, 2 ragdolls a frame in big moments. 9. **`LAGFREE_MEMORY` and the join:**
   - PlotPrivacy takes other labs off the screen (no drawing, no physics), but they stay in memory. Check that `StreamingEnabled` streams far labs out: no lab model set to Persistent, `StreamingTargetRadius` set to the lab size, and `RequestStreamAroundAsync` at your lab on join.
   - Hole, face and decal pictures at 256-512, never 1024.
   - Preload only the first minute's sounds; the rest in the background.
   - Big moments (an event start, the boxing, the machine demos, the lab surprise): build at most 2 ragdolls a frame and warm the pools at join idle time, so nothing hitches.
10. **DONE v1391 (`LAGFREE_IPAD`):** an iPad with a keyboard was treated as a PC (PhoneDiet checks KeyboardEnabled); now the server's Device "tablet" also turns off Bloom, SunRays, depth of field and shadows. 10. **The iPad's big screen** (pixels cost there):
    - the full-screen extras (Highlights, Bloom, SunRays, DepthOfField, Blur) follow the level; PhoneDiet already turns them off on touch devices without a keyboard;
    - check that an iPad with a keyboard is still treated as a tablet (`Device` from the server, not `KeyboardEnabled`).

### Done when
- Every item is DONE or PARKED (only for a real Roblox limit).
- Telemetry (item 0) is live.
- The final "Test selv" asks: 5 minutes on a phone and an iPad with 10 ragdolls, a dead pile of 10, X-ray, the boxing and a car. Smooth? Any stutter?
- After publishing: the Creator Hub custom events `Fps_p10` by device over 2 days, before and after. Write the numbers here.
