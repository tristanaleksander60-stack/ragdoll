# LAB TARGET: build the lab to the reference look (owner, 26 Nov 2026)

> "Okay nej det dumt at lave en helt nye chat, bare lav den bedst mulige prompt så vi kommer mod det her map PRÆSICT."

**References:** the owner's 5 screenshots of the target lab, in `art/store/look_target/lab_ref/`:
- `ref_1.webp`: the spawn plaza with 4 leaderboards;
- `ref_2.webp`: the street view of the tower, rocket and cars;
- `ref_3.webp`: the cars, boxing ring, pool and cave;
- `ref_4.webp`: top view south;
- `ref_5.webp`: top view over the tower.

**Open them first and keep them open.** Every step is compared to them side by side.

**This replaces** the cartoon "crash test lab" look of LAB10 rounds 1-2 (yellow and black hazard, orange, white slab). These stay from round 2:
- attract mode (`ATTRACT_MODE`);
- the "try me" chain;
- harsh scoring.

**These are the OWNER'S OWN OLD MAP, not another game** (owner, 26 Nov 2026: "Det skal ligne mit gamle map, det ikke en anden brugers"). Copy it EXACTLY: same plots, same order, same size, same props. See ROUND 2 below. Sections 1-4 are kept only as background.

## ROUND 2: bring back the owner's old map EXACTLY (do this, not a rebuild by eye)
> "Mappet er stadig lille og ligner slet ikke det samme. Det skal ligne mit gamle map, det ikke en anden brugers."

The 0.56.0 park was rebuilt by eye inside the LAB10 frame (about 190 x 200 studs). It is too small and does not look like the references. Rebuilding by eye will never be exact. **Get the real old map back and use it.**

### Step 0: find the old map (do it yourself, in this order)
The references show an older build:
- HUD: Shop / Tools / Lab / Multiplayer on the left;
- Maps and Events squares top right;
- "Unlock: Lasso 38/40" pill;
- C Fall / Distance / Push / Grab;
- R Revive / G Spawn / V Scan;
- a 1-0 hotbar starting with a hand.

Use these to recognise the right version. Look in this order:
1. **The place's version history.** Creator Hub → the experience → Places → the start place (126037745825106) → Version History. Also check the universe's other places (for example the multiplayer place). Open older versions in Studio (File → Open from Roblox, or download the version) and find the newest one whose lab matches the 5 references.
2. **Local backups:** `Documents\RagdollLab-backups\*.rbxl`, and Studio's recent files.
3. **Other experiences or places on the owner's account** (Creator Hub → Creations) with that lab.
4. **Only if none is found:** stop the lab work and send the owner ONE Danish line: "Jeg kan ikke finde det gamle map. Hvilket spil/hvilken version er det fra? (navn eller link)". Do the rest of NOW.md meanwhile.

### Step 1: copy it 1:1 into the current place
1. Open the old version **as a separate file**; never publish it.
2. **If the map is stored geometry:** select every world piece of the lab (ground, plots, walkways, plaza, tower, slide, railway, terrain hills, trees, rocks, tanks, cave, walls, board frames…). Copy it into the current place as `ServerStorage.OldLabMap` (one Model), with the spawn as PrimaryPart.
3. **If that version BUILT the lab from code:** press Play in the old file, select the built lab in Workspace while it runs, copy, Stop, then paste it into the current place as `ServerStorage.OldLabMap`. This bakes it exactly.
4. **Terrain** (the hills): copy the Terrain region with the Terrain editor's region copy (or `Terrain:CopyRegion` / `PasteRegion`), or bake the hills as smooth meshes.
5. **Clean-up:**
   - remove every Script, LocalScript and ModuleScript from `OldLabMap` (the old game's code; malware pass);
   - keep only geometry, decals, textures and lights;
   - write down what was removed.
6. **Lighting:** copy the old Lighting, Atmosphere, Sky and post effects values into `ZoneLighting` as preset `OLDMAP`.

### Step 2: use it as the lab
- **The switch:** `Config.LAB_OLDMAP = true` (supersedes `LAB_PARK` and `LAB_V10`'s frame; `false` = the 0.56 park).
- **Building:** the lab builder clones `OldLabMap` at each lab's origin, at the old size (1:1, never scaled down: the size is the point), instead of LabV10's floor, wall, park and frame.
- **Machine positions:** every current machine stands **exactly where its counterpart stood in the old map**. Read the positions from the copied models (tower, slide, rocket, cars and bays, boxing ring, tanks, spider, frog, plant, chicken, washer, press, fan/vacuum, cannon, mole, slingshot + target, lava, sand pit, trampoline, wooden ramp, red buttons, the 4 leaderboards, the MAPS board, portals). Put them in `LabLayout10.OLD`, which every builder reads as now.
  - If the old map had a machine we no longer have, keep its geometry as decoration.
  - If we have a machine the old map did not have, give it the nearest free plot in the same style.
- **The old tower and slide** become the real tower and slide (climb, slide, sky deck). Hide today's code-built tower.
- **Kept from rounds 1-2:**
  - the TRY! ring and the goal line;
  - attract mode, only where it does not change the look.
- **Removed:** the LAB10 frame (park floor, wall, railway copy, skyline). The old map has its own.

### Step 3: performance
- **Count the parts** of `OldLabMap`.
- **If one lab is over about 5,000 parts:**
  - make small decoration CanCollide off, CanQuery off and CastShadow off;
  - merge static groups into meshes where it is safe;
  - put far trees and hills on low detail.
- **Never shrink or move things** to save parts.
- **Check FPS** on the phone emulator.

### Step 4: check (it must be THE SAME map)
1. Capture the same 5 angles as `ref_1` … `ref_5` and save them as `art/store/lab10/old_*.jpg`.
2. Put each beside its reference and score "is this the same map", 0-10: size, plot order, every prop in place, the tower and slide, the plaza with 4 boards, the railway, the hills, the light.
3. The bar is **9.5**; only the HUD may differ. Fix and capture again (max 3 rounds).
4. One quick Play, publish once, and give ONE Danish "Test selv" list.

## 1. What makes the reference good (copy these principles exactly)
1. **A grid of plots.**
   - The lab is a rectangle cut into plots of grass by a grid of wide light-concrete walkways.
   - Each plot holds ONE attraction, filling it.
   - Nothing stands loose in a walkway; nothing floats in open grass.
2. **One tall hero in the middle.** A grey steel scaffold stair tower (4-5 floors with railings, an open stairwell and a roof deck) with a long steel slide/jump ramp curving down from the top. Visible from everywhere.
3. **A raised spawn plaza at one end:**
   - a large concrete platform, 2-3 studs high, with a railing;
   - a wide stair or ramp down;
   - a row of 4 big leaderboards on posts along its back edge;
   - the MAPS board at its side;
   - benches.
4. **Realistic, calm materials, not cartoon colours:**
   - light concrete with tile joints;
   - green grass;
   - grey galvanised steel;
   - red brick;
   - natural wood;
   - clear blue water in glass tanks;
   - grey rock.
   - Colour comes from the objects themselves (red barrels, green truck, blue car, lava, sand), never from painted stripes.
5. **Real-looking props in sensible groups:**
   - cars parked in painted bays in a row, next to a brick crash wall with red barrels;
   - a boxing ring on its own plot;
   - glass-walled water tanks for sea creatures;
   - a sand pit;
   - a lava strip with a rock edge;
   - a rocket on a steel launch gantry;
   - a big industrial fan machine;
   - an archery target;
   - a trampoline;
   - a wooden ramp.
6. **The edge:**
   - a railway track running round the whole lab (just the track, as a border);
   - low concrete walls in places;
   - outside: rolling green hills, groups of round low-poly trees and pines, a few grey boulders.
   - No fog wall, no empty flat field.
7. **Light:** soft daylight, light hazy sky, gentle shadows, natural colours (no saturation boost, no bloom).
8. **Scale:** objects are realistic and large (cars at real size, the tower about 45-55 studs high). The player feels small. Plots are big (about 36-50 studs), walkways wide (about 12-16 studs) with tile lines.
9. **Density:** from any high view, every plot is full and every part of the screen has something to look at.

## 2. Our plot plan (top view, our own order)
Spawn plaza in the NORTH, facing south toward the tower. About 7 columns x 4 rows of plots, framed by the railway.

```
 N  [Creature: frog]   [Shark glass tank]   [SPAWN PLAZA: 4 boards, MAPS]   [Whale/pool tank]   [Spider pit, web]
    [Cars: bays + brick wall + barrels]     [Boxing ring]   (wide walkway)   [Big fan = Vacuum]  [Sand pit]
    [Rocket on gantry]   [ TOWER + SLIDE (hero, centre, 2x2 plots) ]   [Wooden ramp/plank]   [Archery target + slingshot]
 S  [Trampoline]   [Compressor/Press]   [Test floor: dummies + RED BUTTON]   [Washer]   [Mole]   [Lava strip]   [Cannon]
    railway all round; weapon range and portal at the south edge; shop booths along the plaza's sides
```

- The spawn looks down the wide central walkway at the tower: the first view shows the tower, slide, rocket, cars and some dummies.
- **Dummies** stand on the test-floor plot and along the walkways in small groups, never floating.
- **Every existing machine gets a plot.** If something has no plot, it goes behind its switch (hidden, not deleted). Machine to plot:

  | Machine | Plot |
  |---|---|
  | wrecking ball | next to the brick wall |
  | stretch machine | beside the boxing ring |
  | mech arms | on the test floor |
  | chicken | a fenced pen |
  | plant | a garden plot |
  | launch pads | in front of the brick crash wall |

## 3. How to build it
- **The switch:** `Config.LAB_PARK = true`, which supersedes `LAB_V10`'s look. `false` brings back LAB10. The positions live in `Shared/LabLayout10` (rename the table `PARK`, or add a `PARK` table); every builder reads it as now.
- **Assets:** Creator Store models in a realistic low-poly style, one style only:
  - a steel scaffold stair tower;
  - a steel slide/ramp;
  - railway track pieces;
  - a brick wall;
  - red oil barrels;
  - low-poly trees (round and pine);
  - boulders;
  - glass tanks;
  - a sand pit;
  - leaderboard frames;
  - an industrial fan.

  Put them in `V3Assets` (place file only). **Malware pass on every insert: delete all scripts.**
- **The tower:**
  - Replace today's stairs, bridge, slide and sky deck with the steel scaffold tower and slide, at the centre.
  - The existing functions (climb, slide, push off, sky deck) move onto it.
  - Its top deck is the highest standing point in the lab.
- **The ground:**
  - walkways in light concrete with a tile texture (TextureLength about 8-10, tile joints visible);
  - plots in grass, with a thin concrete kerb;
  - the spawn plaza raised with a railing and a wide stair;
  - textures, not stacked thin parts (no flicker, no grey strips).
- **Terrain outside:** rolling hills (Terrain or big smooth meshes), tree groups and boulders. The railway as the border.
- **Light** (`ZoneLighting` PARK):
  - ClockTime about 14, Brightness about 2;
  - soft OutdoorAmbient;
  - Atmosphere Density about 0.3, Haze about 1 (light hazy distance, like the reference);
  - no strong saturation.
- **Leaderboards:** our 4 boards (KOs, time played, and the 2 VIP ones if we have them; otherwise our 4 best) as one row on posts on the plaza's back edge.
- **Remove the LAB10 cartoon frame** behind the switch: hazard walls, orange posts, the white slab and the teal domes.
- **Performance:**
  - a lab at most 3,500 parts;
  - meshes over parts;
  - trees and hills cheap (no collisions, no shadows on small ones);
  - check on the phone emulator.
- **Keep from round 2:**
  - attract mode on each machine;
  - the "try me" glow + "TRY!" hand and the goal line "Next: try the X!".

## 4. Check (harsh, against the references)
1. Capture the same 5 angles as the references and save them in `art/store/lab10/park_*.jpg`:
   - the spawn plaza;
   - street level toward the tower;
   - a high corner view;
   - top view south;
   - top view over the tower.
2. Put each next to its reference and score how close it is, 0-10, on:
   - style and materials;
   - density;
   - the hero tower;
   - the plot grid and walkways;
   - the edge and landscape;
   - the light;
   - phone readability.
3. Anything under 9: fix it and capture again (max 3 rounds). When unsure, score lower.
4. One quick Play (no errors), publish ONCE through RELEASE.md, and give ONE Danish "Test selv" list with the 5 side-by-side captures named.

## State (26 Nov 2026, release 0.56.0, place saved v1113, NOT published yet: the owner presses Alt+P)
**Round 1 built** behind `Config.LAB_PARK = true`, on top of LAB_V10's spots. `false` gives the LAB10 cartoon look back.
- **The park look** (`Systems/LabV10` `park()`):
  - a light concrete field with tile joints;
  - a grass plot with a concrete kerb under every attraction (worked out from each machine's own box);
  - a test floor in plain concrete with one white ring.
- **The raised spawn plaza** (1.4 high, so the spawn at +4 never lands inside it):
  - a wooden railing and a wide ramp to the lab;
  - **4 lab boards** in a row on its back edge (`LeaderboardService`; KOs, time and both VIP boards).
- **A railway round the lab:** gravel bed, sleepers and rails; none of it collides.
- **Outside:** tree groups and boulders; the tower and its heights re-skinned in galvanised steel, the slide grey-green; the crash wall in brick.
- **Light** (`ZoneLighting` PARK): ClockTime 14, Brightness 2, haze 1, density 0.3, no saturation boost, light clouds.
- **Kept from LAB10 round 2:**
  - attract mode (`Client/LabShowcase`);
  - the TRY! chain (`Tried_<kind>` from ExperimentService);
  - 8 dummies roaming on the test floor.
- **Captures:**
  - `art/store/lab10/park_high.jpg` and `park_spawn_pc.jpg`;
  - R2: `r2_spawn_pc.jpg`.

**Harsh score against the references:**

| | Score |
|---|---|
| style and materials | 7 |
| density | 5 |
| hero tower | 4 (it is the old stair tower in steel, not a 50-stud scaffold) |
| plot grid and walkways | 6 (plots follow the machines, not a true grid) |
| edge and landscape | 7 |
| light | 7 (a little greenish-hazy) |
| phone | not captured |

**Left (next round):**
- a real steel scaffold tower (4-5 floors, about 50 studs) with a long slide in the middle;
- machines moved into a true plot grid (7x4), and the open concrete filled;
- the 5 reference angles captured side by side;
- the phone capture;
- the haze a touch lighter.
- **Known issue:** creatures that eat a dummy by themselves count as "tried" for the lab's owner (ExperimentService credits the owner).
