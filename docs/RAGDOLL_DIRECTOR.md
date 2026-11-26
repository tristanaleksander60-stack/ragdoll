# RAGDOLL DIRECTOR + LAG EMERGENCY (owner, 26 Nov 2026)
> "Der skal være ægte ragdolls ved hver maskine og rundt omkring mere, men de skal bare spawne hvor man er, så det ikke lagger, og forsvinde hvis man ikke bruger dem. Tænk rigtig smart her, fordi alt lagger lige nu."

Two parts:
- **Part A:** find and fix what makes EVERYTHING lag now. Measure first.
- **Part B:** one smart system that decides where the REAL ragdolls are (`RagdollDirector`), so there are more of them around you while far fewer exist at once.

Both come BEFORE any other work in OVERVIEW (item 0.1).

## Part A: LAG EMERGENCY (measure, then fix the biggest)
1. **Measure in Studio** (Play, the phone emulator, and PC), at 3 spots: the spawn, the Machine Hall, and Tower Square with an event running. Write the numbers in State:
   - **frame time split:** MicroProfiler, Render vs Physics vs Scripts (Heartbeat/Stepped);
   - **counts in Workspace:** BaseParts, MeshParts (triangles if the Stats show them), Lights (PointLight/SpotLight/SurfaceLight, and how many have Shadows on), ParticleEmitters, Beams, BillboardGuis, SurfaceGuis, Humanoids, Constraints and Attachments, Sounds;
   - **ragdolls:** how many exist; how many are simulating physics (not sleeping);
   - **scripts:** each system's per-frame cost (`debug.profilebegin` labels round every Heartbeat/RenderStepped loop); how many connections run every frame;
   - **network:** Data Send/Receive kb/s; how many property changes per second come from the server;
   - **memory:** total and by category (Graphics, PhysicsParts, Instances, Sounds, Gui).
2. **Likely culprits on the new map** (check each and fix):
   - **Trees:** hundreds of high-poly stylised trees with full collision.
     - Use CollisionFidelity Box, CanCollide false for the leaves, CastShadow off for all but the nearest, RenderFidelity Automatic.
     - Use StreamingEnabled with the groves as Models with ModelStreamingMode "Nonatomic" and a low-detail StreamingMesh far away.
     - Halve the belt trees where the bushes hide the gaps anyway.
   - **Lamp lights:** 141 lamps; if each has a PointLight, that is far too many. Lights only near the player (the nearest 8, client side), Shadows off on all lamp lights, and none by day.
   - **Decoration with collisions:** every decoration part has CanCollide, CanTouch and CanQuery off unless needed.
   - **Moving or animated parts updated by the server** (gyro rings, gates, fans, flags, bulbs, water jets): ALL animation on the client, only when within about 120 studs and in view. No server CFrame writes every frame.
   - **The chasing bulbs** (80 on the arch plus the board frames): one client loop and one shared material; turn them off on low tier.
   - **Billboard and Surface GUIs:** the 44 signs plus boards. Use the lowest PixelsPerStud that stays crisp, MaxDistance on all, and a shared font.
   - **Terrain:** no decoration grass on phones; a sensible water-wave setting.
   - **StreamingEnabled:** ON, a StreamingTargetRadius of about 384 (phone) to 768 (PC), the right persistent models (the spawn, the player's lab core), and no scripts that hold the whole map loaded.
3. **Fix the top 5** by measured cost first. Re-measure after each fix and write before and after numbers.
   - **Target:** a mid phone holds 60 fps at the spawn and in a room, and 30+ in an event; PC 60+.
   - **Parts in view:** no more than about 15k parts streamed in at once on a phone.

## Part B: the RAGDOLL DIRECTOR (more ragdolls around you, fewer in total)
**The idea:** real ragdolls exist only near the player. A fixed POOL of ready ragdolls is reused (never destroyed and re-made: building a rig with all its joints is the expensive part). The director keeps moving pooled ragdolls to where they matter: around you, at the machines near you, on the road you are on. When you leave, they quietly go back to the pool.

1. **Pool size by the player's device tier:**

   | Device | Real ragdolls | At least near you |
   |---|---|---|
   | phone | 10 | 3 |
   | tablet | 14 | 3 |
   | PC | 20 | 3 |

   In the solo place it is the player's tier. In the multiplayer place, each player gets their share from a server cap of about 40.

   All the existing systems ask the director for a ragdoll instead of making their own: the 3-near (ALWAYS3), the watchers, the road walkers, demos, TRY, events, CPR helpers and bullet pickers.
2. **Slots, by priority**, refreshed every 0.5 s:
   1. a ragdoll the player is touching, grabbing, shooting, or has just knocked out (PINNED: it never despawns while in use, nor for 30 s after);
   2. the 3 near the player (NEVER ZERO);
   3. the watchers at the machines within about 90 studs, nearest first (1 each; 2-3 at the busiest);
   4. walkers on the road or path the player is on, ahead of the player;
   5. event extras, when an event runs (they take from the pool; the event minimum in `EVENTS_NEWMAP.md` is met by temporarily borrowing slots 3-4).
3. **Spawn without popping:**
   - a ragdoll is (re)placed only where the player cannot see it: outside the camera's view (the client reports its camera direction every 0.5 s), or behind a tree belt, building or wall (a raycast from the camera is blocked);
   - it then WALKS or RUNS into place (`ALWAYS3` rules, standing spawn);
   - if no hidden spot exists, it waits.
4. **Despawn without popping:**
   - a ragdoll whose slot is gone (you walked away, more than about 110 studs, not pinned) walks off and is returned to the pool once it is out of view;
   - a knocked-out body that nobody uses fades after 20 s once it is out of view, or 40 s if visible.
5. **Reset on reuse:** a returned ragdoll is reset (pose standing, injuries, holes, bones, bandages and X-ray slugs cleared, the face neutral), then parked hidden (anchored, under the map, no physics, no scripts running) until it is used again.
6. **Physics budget:**
   - only ragdolls within about 60 studs and in view run full active-ragdoll physics;
   - others in the pool are either parked or walking with a light mode (animation, simple movement, no limb physics) until you get close;
   - a hit always wakes one at once.
7. **One loop:** the director and every ragdoll behaviour run in ONE scheduled update (staggered: each ragdoll's brain every 0.2-0.5 s, not every frame); pathfinding max 6 per second (`ALWAYS3.md` nav).
8. **Spikes:** at most 2 spawns or reuses per second, spread over frames, so there is no hitch.

**What the player sees:**
- there are always ragdolls round them;
- every machine they walk up to has its watcher;
- the roads they walk have walkers;
- nothing pops in or out in view;
- and it is smooth.

## Check
- **Part A:** before and after numbers for every measure at the 3 spots, phone and PC.
- **Part B:**
  - walk the whole map for 5 minutes on the phone emulator: every machine you reach has a real watcher; never 0 near you; no pop-in in view; FPS at target; the ragdoll count never above the pool size;
  - knock out 5 and walk away: they are cleaned up out of view, and new ones are near you at the next machine.

## State
- v1144 part A step 1 (`LAG_GUARD`, Client/LagGuard). MEASURED (start place, Play, spawn): server physics 0.9 ms, heartbeat 0.4 ms (the server is not the problem); Workspace 18372 BaseParts (Lab1 10776, Plaza 279), 7005 MeshParts, 105 lights (56 with shadows: car headlamps, booth lamps, board lamps), 443 SurfaceGuis (209 3D letters, 160 signs) and 27 billboards all WITHOUT a view distance, 739 constraints, 17 humanoids, 10 dummies; client streamed 6841 parts (radius 400); server-moved anchored parts only 3/s (GuideRing, GuidePoint, SweeperBeam). Studio's fps/render numbers are not usable for before/after (the unfocused Studio window throttles to ~15 fps and the render time swings 10-27 ms). FIXED: 0 shadow lights, lights beyond 140 studs off, every SurfaceGui/map billboard has MaxDistance 150 (spawn title 350), phone canopies cast no shadow; the 46 tree meshes (V3Assets/YTrees) set to CollisionFidelity Box + RenderFidelity Automatic, canopies CanCollide/CanQuery/CanTouch off. NEXT: the sweeper beam to the client; the ragdoll director (part B); a real phone FPS check by the owner.
- v1145 part B step 1 (`RAGDOLL_DIRECTOR`, Systems/RagdollDirector + Shared/Ragdoll/ActiveRagdoll): every lab ragdoll 140+ studs from every player and not in use (held, in a machine, demo/NEVER ZERO runner, moving, hit in 10 s) is Parked; the simulating screen skips its whole brain + pose update; woken within 120 (max 8 changes a tick). Measured at the spawn: 16 of 19 ragdolls parked. NEXT: the pool by device tier, hidden re-placing, fading unused bodies.
