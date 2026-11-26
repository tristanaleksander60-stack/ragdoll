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
