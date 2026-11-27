# NOW: the current work list (read this first on every /klar)

**READ `docs/OVERVIEW.md` FIRST:** it is the one-page map of the whole plan (order, docs, done, left). This file holds the details and history.

**All weak points, ranked:** `docs/WEAKNESSES.md` (26 Nov). After LAB10 round 2, take its "Order to fix" from item 3.

**Next after the lab:** `docs/STAY_LONGER.md` (session length). Build items 1-8 in one run. Item 1, the quiet gift timer on phones, goes first.

## >>> GO NOW: THE MAP (owner, 26 Nov 2026, late). Do this FIRST in every /klar until it is finished. It is NOT parked. <<<
> "Mappet har stadig ikke fået den store opdatering hvor det er blevet præcis som det jeg viste, sørg lige for den forstår planen korrekt og den kører nu indtil den er helt færdig"

**What the owner wants, in plain words:**
1. **The lab looks EXACTLY like the owner's own screenshots:**
   - `art/store/look_target/lab_ref/ref_6` … `ref_10` (the main ones), plus `ref_1` … `ref_5` and the close-ups described in `docs/LAB_TARGET.md` R3.1b.
   - The same zones, in the same places relative to each other, with the same objects, look, materials, light, hills and railway.
   - It is NOT "inspired by". It is that map.
2. **It is BIGGER: 10x the area,** about 950 x 820 studs.
   - "1:1" and "10x bigger" do not conflict. Keep the SAME arrangement and proportions as the screenshots; stretch all distances by about 3.2.
   - Make the big set pieces 1.5-2x (`docs/LAB_TARGET.md` R3.2 SIZE).
   - Fill the extra space with the same kinds of things (tree groups, boulders, benches, lamps, ragdolls). Never leave empty flat areas.
3. **Every existing machine and system works in the new map,** on its spot.
4. **The player walks faster** (28) and can SPRINT (42); this is already in R3.2 RUN FASTER.

**How to run it (several sessions are fine; never park it, never stop to ask):**
- Work through the phases below in order. After EACH phase:
  - one quick Play;
  - a capture compared with its reference;
  - commit and push;
  - write one line in "MAP RUN STATE" below.
- **A new /klar continues** from the first phase not marked done.
- **Behind `Config.LAB_OWNERMAP = true`;** false brings back today's lab.
- **Save the place after every phase** (the models live in the place file).

| Phase | What | Compare with |
|---|---|---|
| M1 | The ground: 950 x 820 base; grass plots cut by the light-concrete walkway grid (6-stud tile look, 20-24 wide walkways); the raised spawn/leaderboard plaza with its granite wall, cap and pipe railing, its stair and 4 boards; the railway loop; the ring of soft green hills (terrain or cheap meshes) | ref_10 (top), ref_1 |
| M2 | The hero: the 5-floor steel scaffold stair tower (about 90-100 high), the green steel slide on its truss, the wooden plank bridge, the grey grandstand with wooden seats | ref_5, ref_8, ref_10, ref_14 close-ups |
| M3 | North row: the rock cave with the bear and its stone-ringed yard, the glass aquarium (shark), the leaderboard plaza (from M1), the open pool (whale), the fenced dirt pen | ref_6, ref_7, ref_10 |
| M4 | West: car bays with the tank, monster truck and blue car; red barrels; the boxing ring; the long brick crash wall; the garage with the rail car; the rocket on its round pad and gantry; the concrete slab; the walled T-rex pen with its gate; the crocodile pond with the speaker wall | ref_6, ref_9, ref_10 |
| M5 | East: the giant fan, the sandcastle tower with crates and fence, the yellow sandbox, the round sand circle, the archery target, the wooden seesaw, the GYRO CAGE (with its red button), the raised trampoline, the long lava strip with the sunken stone trench, the turf square, the TESLA COIL | ref_7, ref_8, ref_10, close-ups |
| M6 | South: the round sweeper pad with its beam; the shredder pit with the railing, lever and button | ref_8, ref_9 |
| M7 | Hook up EVERYTHING to the new spots (`LabLayout10.OWNER`): every machine, the cannon load, the creatures, cars, bike and cyclist route, the doghouse, spawns, the 3-near ragdolls and the watchers, TRY and the first machine (FIRST_2_MIN), the MAPS board, the portals (hidden ones stay hidden), benches, the weapon range | a Play through every machine |
| M8 | Dressing and light: tree groups (round low-poly trees + pines), boulders, the soft daylight with the light green-grey haze on the hills (as in the shots); the extra space filled | ref_6-ref_10 |
| M9 | Performance: StreamingEnabled tuned for the big lab, decoration cheap, the part budget (`docs/PERF_MOBILE.md`), phone FPS checked | the phone emulator |
| M10 | The side-by-side check: the same 5 camera spots as ref_6-ref_10, list every difference, fix, recapture (max 4 rounds). Bar 9.5 "same map". Then publish (or ask for Alt+P in the final message) | ref_6-ref_10 |

### OWNER (26 Nov, late): "Labbet er stadig ikke ændret … alt står som det plejer, det ikke større. Det skal ændres KOMPLET præcist til de screenshots"
The owner only sees M1's ground, while the OLD lab still stands in the middle (it moves in M7). **Change the order so the change is visible at once, and do ALL phases in one go:**
1. **M7 right after M1:**
   - hide the whole old lab frame (LAB10 / park floor, wall, old tower set, old garden, old paths) under `LAB_OWNERMAP`;
   - move every machine and system to its new spot on the big map (`LabLayout10.OWNER`), at the 3.2x distances.
2. **Then M2-M6:** the set pieces, each placed exactly as in the screenshots.
3. **Then M8, M9 and M10.**
4. **Do not end the session after one phase.** Keep going phase after phase until M10 is done. Only the final message goes to the owner.
5. **Nothing of the old lab may be visible** in the owner's view when you finish. Check it with the 5 reference angles.

### DEFINITION OF DONE for the map (all must be true before you say "done"; otherwise keep working)
1. **Nothing from the old lab is visible.** No LAB10/park floor, wall, old tower set, old paths, old garden or old props, from any of the 5 reference angles.
2. **The size is right.** Measure the built map's bounding box in Studio and print it: about 950 x 820 studs, with every zone at its 3.2x spot.
3. **Every object in `docs/LAB_TARGET.md` R3.1 and R3.1b exists** and stands where the screenshots show it. Check it item by item and print the checklist with ✓ or ✗; any ✗ means keep working.
4. **Every machine works** on its new spot (one Play through all of them).
5. **The 5 captures** from the same spots as ref_6-ref_10 are saved in `art/store/lab10/own_6.jpg` … `own_10.jpg`, each scored "same map" 9.5+.
6. **The owner gets the 5 captures** named in the final message, next to their reference names.

**Until all 6 are true:**
- work on nothing else (no F-items, no other steps);
- do not end the run;
- do not say "done".

### MAP ROUND 3 (owner, 26 Nov late: "Det her map er 1/10 … det kan du godt, you got this!"). THIS IS THE MAP JOB NOW
- Rebuild the layout from the finished master plan: `docs/MAP_MASTERPLAN.md` + `Shared/OwnerMapPlan.luau` (generated by `tools/masterplan.py`, linted) + `art/store/lab10/masterplan.png`.
- The design: rooms walled by tree belts that you explore, a boulevard from the raised spawn plaza to the Tower Square, big connected paths that end at every attraction, new good trees, lamps only along path edges.
- Keep the built set pieces (tower, cave, pools, etc.). MOVE them to their plan spots, and remove all the old paving.
- It replaces the grid layout of round 2. Round 2's small fixes (mech arms off, top 20, TRY once, spawn and MAPS at the plaza) stay.

### MAP ROUND 2: the owner's feedback on the built map (26 Nov, late). Part of GO NOW; do it before M9/M10
> "Fjern de 4 arme, da de ikke virker længere. Gør så man kan scrolle ned på leaderboards til top 20. Fjern TRY efter man har prøvet den 1 gang. Mappet er bedre nu, men ser meget tomt ud rundt omkring. Lav spawnpointet ved leaderboardsne og sæt maps der også. Lav en plan for at udfylde alt det tomme plads. Og fiks så at ingen ting står på stierne, og at de ligner dem fra mit screenshot. Se mine referencebilleder igen for inspiration, brug alt der og tilføj det vi mangler."

**The owner's 2 screenshots show:**
- large plain grass plots with one small thing each, far apart;
- walkways in a small brick-pattern paving, very wide, crossing at odd places;
- the blue mat with red barrels lying ON a walkway;
- a yellow lasso/rope line across the grass;
- the sandcastle tower tilted and half on a walkway;
- the mech-arm stand (the "4 arms") by the wrecking ball.

**R2.1 Small fixes (do first):**
- **Remove the 4 MECH ARMS** (`MECH_ARMS = false`, hide the stand; they no longer work).
- **Leaderboards: top 20.** Each of the 4 boards shows 20 rows in a scrollable list (a ScrollingFrame on the SurfaceGui). It scrolls with the mouse wheel when pointed at, and by touch-drag on phones. Rank, name and value per row; your own row highlighted, even when you are outside the top 20 (shown pinned at the bottom).
- **TRY disappears for good after one try** (F1 again; make sure it really works):
  - the server saves `Tried_<kind>` in the player data the moment a machine runs with the player's ragdoll;
  - the TRY button and the outline check it every time;
  - after a rejoin, tried machines show NO TRY.
  - Test it by trying 2 machines, leaving and rejoining.
- **The SPAWN moves to the raised leaderboard plaza,** at its front edge, facing down the stair toward the tower. **The MAPS board stands on the plaza** next to the boards. The 3-near ragdolls and the first goal ("Hit a dummy!") start there.
- **Nothing on the walkways:**
  - move every object off them (the blue mat and barrels, the sandcastle, benches, crates, lamps, trees, ragdoll spawn points);
  - a check script raycasts every walkway and lists anything above it, and it must be empty;
  - objects stand at least 2 studs from a walkway edge.
- **The sandcastle tower stands upright** on its own plot.
- **No stray rope line on the grass:** a lasso or rope left behind is removed when not held.

**R2.2 Walkways like the owner's screenshots** (ref_1, ref_2, ref_3, ref_6, ref_10):
- **Large plain light-grey concrete slabs** (about 12 x 6 studs at the original scale; scale with the map), with thin dark joints, a slight variation in tone, and a low concrete kerb on both edges. NOT small brick-pattern paving.
- **Width:** about 14-16 studs (not 22).
- **Layout:** a clean straight grid like ref_10. The walkways run BETWEEN the plots and meet at right angles. Every walkway leads to a plot entrance or the plaza; no odd diagonal crossings.
- **Textures, not parts per tile** (cheap; no flicker).

**R2.3 FILL THE EMPTY SPACE** (the plan the owner asked for; build all of it). The rule: from any normal view, no empty grass bigger than about 40 x 40 studs inside the compound. Every plot is at least 60 % used.
1. **Bigger set pieces where the screenshots show them big:** the cave, the aquarium, the pool, the fan, the gyro cage, the rocket gantry, the brick wall, the T-rex pen, the grandstand and the lava strip at 1.5-2x, so each fills its plot as in ref_10.
2. **Every plot gets a dressed yard round its machine** (as in the refs):
   - a concrete or dirt pad under it, with a low kerb or fence round the plot;
   - 2 lamp posts at the plot entrance;
   - 1-2 benches facing the machine;
   - a small cluster of fitting props: crates, barrels, cones, a tool cart, a sign with its pictogram;
   - the watcher ragdolls (`docs/ALWAYS3.md`).
3. **Add what the refs have that we still miss** (check each against ref_1 … ref_10 and the close-ups):
   - the bleacher seats by the tower (if missing);
   - the wooden ramp/plank pieces;
   - the archery target set;
   - the brown sedan by the brick wall;
   - small sheds;
   - the speaker wall;
   - the garage with the rail car;
   - the T-rex behind its gate;
   - the crocodiles in their pond;
   - the white Tesla pad;
   - the green turf square;
   - the round sweeper;
   - the shredder lever box;
   - picnic tables;
   - fenced paddocks.
4. **More of the good stuff, in empty plots:**
   - a car park with 4-6 more parked cars (in bays);
   - a second, smaller pool with sun loungers;
   - a picnic and grill corner;
   - a small playground (slide, swings) where ragdolls play;
   - a training yard with tyres and hurdles;
   - a parked train on the railway;
   - a hangar with its doors open and a forklift;
   - a water tower;
   - a control tower;
   - a few portable toilets and a snack kiosk.

   All are static or lightly animated decoration in the same realistic low-poly style (Creator Store, malware pass).
5. **Tree groves and boulders** between zones and along the outer edge (more than now), with flower beds at the plaza.
6. **Life:**
   - ragdolls walking the walkways in twos;
   - some sitting on benches and the grandstand;
   - the cyclist and the motorbike rider on the loop;
   - birds;
   - the dog at its house.
7. **Performance:** use decoration as cheap meshes; streaming must work; keep inside the part budget of `docs/PERF_MOBILE.md`.

**R2.4 Check:**
- capture the owner's 2 angles (a high view from the north-east plaza corner; a high view over the brick wall) plus ref_6-ref_10;
- no empty grass over about 40 x 40;
- the walkways are clean and look like the refs;
- the spawn and MAPS are at the plaza.
- These are part of the DEFINITION OF DONE.

### MAP RUN STATE
- OWNER (26 Nov, late): "vent til det er helt færdig": do NOT ask for Alt+P or publish until the map meets the DEFINITION OF DONE. Keep saving the place only.
- M1 part 1 DONE 0.78.0 (multiplayer place v55): `LAB_OWNERMAP` on, Systems/LabOwnerMap (330 parts): 950x820 grass base at CENTER (-30,24), walkway grid 22 wide (rows z -82/-18/58/104 x S, columns x -100/-55/0/28/68/112 x S, S=3.2), spawn circle, raised granite leaderboard plaza at z -304 with cap, pipe railing and stair, railway loop west+south (ballast, rails, sleepers), Terrain hill ring. Zones.PLOT_SPACING 1100 under the switch. Capture ScreenCapture_M1 vs ref_10: grid and hills match; the old lab still sits in the middle until M7. Left in M1: walkway tile seams, grass plot edges, the 4 boards on the new plaza (M7).
- M7 part 1 (multiplayer place v56): under `LAB_OWNERMAP` Config.LAB_SPREAD x3.2 (every machine, creature, ragdoll and path spot 3.2x further out through the code's own S, so their logic stays right) and LabLayout10 spots x3.2; LabOwnerMap.hideOld hides LabV10, zone pads, garden, paths and the plot's floor, plaza, rim, edges, barriers, cones and signs. Measured: the machines span 801 x 540 studs (ground 950 x 820). Capture ScreenCapture_M7a: no old compound left, machines spread on the grid. Left: walkway/Zones/HazardRim/Guide leftovers check, the 4 boards onto the new plaza, the set pieces (M2-M6) and their bigger sizes.
- M7 part 2 (multiplayer place v57): the 4 leaderboards (Labs/LabN Board_*) moved by LabOwnerMap onto the raised plaza in a row facing the stair; the spider moved off the plaza to (70,-70)x3.2 by the pen. Capture ScreenCapture_M7c. NEXT: M2 (the 5-floor steel stair tower ~95 high, green slide on its truss, plank bridge, grandstand), then M3-M6 set pieces (Creator Store models, malware pass), M8 trees/boulders/light, M9 streaming/parts, M10 the 5 captures own_6..own_10.
- M2 part 1 (multiplayer place v58): LabOwnerMap.hero: the 5-floor galvanised scaffold stair tower at plan (5,40) x S, 56 x 56, 95 high (9 columns, diamond-plate floors round an open well, zig-zag flights of 19 steps with landings, edge beams, railings with invisible guards, X bracing, a roof deck); the green slide from the roof west edge down to the south-west in 5 bends on truss legs, slippery bed, red button at the top; the plank bridge from floor 2 east down to plan (50,32); the 6-row grey grandstand with wooden seats, back wall with dark panels and a top railing at plan (5,78). The old code tower and Heights hidden. OwnerMap 865 parts. Capture ScreenCapture_M2a. Left: climb test, the old Tower experiment hook (Tried_Tower) on the new tower.
- M3 part 1 (multiplayer place v59): LabOwnerMap.northRow: the rock cave (two big rounded rocks, dark mouth) with a dirt yard ringed by 26 stones and the bear (V3Assets "Bear": Creator Store 9479371160 "Low Poly Bear" by DemonTays, one MeshPart, no scripts, scaled to 9 high) at its mouth; the glass aquarium (concrete base, glass walls, steel frame, water) with the shark tank creature moved into it (LabLayout10 Whale (-30,-95)); the open pool in a concrete rim; the fenced dirt pen with a south gate. Capture ScreenCapture_M3a. NEXT: M4 west (car bays + tank/monster truck/blue car, red barrels, boxing ring, brick crash wall, garage on the rail, rocket pad + gantry, T-rex pen, crocodile pond + speaker wall).
- M4 part 1 (multiplayer place v60): LabOwnerMap.west: car bay slab with lines and kerb (the tank/monster truck/blue car moved to plan (-62/-50/-38, -70): LabLayout10.CARS), 2 groups of red barrels, the brick crash wall (x -76, z -42..8), the garage on the rail (plan -120,-70), the rocket pad + steel gantry with arm (the LabDress rocket moved to plan (-40,30)), the concrete slab, the walled T-rex pen with a gate and the T-rex (V3Assets "TRex": Creator Store 89471479432236 by ItzBaker_love, 34 parts, no scripts, 34 high), the crocodile pond with 3 crocodiles (V3Assets "Crocodile": 125035064545063 by 0XMMSX0, no scripts, 14 long) and the speaker wall. The boxing ring moved to plan (-35,-40) via LabLayout10.MOVES.Lava. Capture ScreenCapture_M4a. NEXT: M5 east (giant fan, sandcastle tower, sandbox, sand circle, archery target, seesaw, GYRO CAGE + red button, raised trampoline, lava strip + trench, turf square, Tesla coil), M6 south (sweeper pad, shredder pit).
- M5 part 1 (multiplayer place v61): LabOwnerMap.east: sandcastle tower (battlements, crates, picket fence), yellow sandbox with wooden rim, round sand circle, archery target on an A-frame, wooden seesaw, the GYRO CAGE (pad, stands, 3 steel rings of 24 segments turning round each other on the server every 0.1 s, red button; visual only so far), the lava strip in a cobblestone trench with kerbs, the turf square, the Tesla coil with blue sparks. The giant fan moved to plan (45,-40) (MapShopService), the trampoline to (45,80) and the stretch machine to (64,62) (LabLayout10). Capture ScreenCapture_M5a. NEXT: M6 south (sweeper pad + beam, shredder pit with railing, lever and button), then M8, M9, M10.
- M6 + M8 part 1 (multiplayer place v62): LabOwnerMap.south: the sweeper pad (yellow ring, post, a beam turning on the server) at plan (0,120); the shredder pit (frame, dark pit, floor 8 down, 2 rollers, railing, lever box, red button) at plan (-52,120). LabOwnerMap.dress: 18 groves of 4-7 round trees and pines, boulder fields at every other grove, a bench at each. Measured: OwnerMap 1672 parts, the whole lab 5747 BaseParts (budget 8000); OwnerMap bounding box 1014 x 971 (the slide end and the T-rex pen reach past the 950 x 820 grass). Captures ScreenCapture_M6a/M6b. Known: the south hills reach into the map edge (move the ring further out); the gyro cage and shredder are visual only. NEXT: M9 (streaming/parts/phone FPS), M10 (the 5 reference captures own_6..own_10, item checklist, fix rounds).
- MAP ROUND 2 part 1 (multiplayer place v63): R2.1 `MECH_ARMS = false` (MechArms.start returns, the Dress MechArmsStand hidden); spawn on the raised plaza front edge facing the tower (Lab.placeOnPlot under LAB_OWNERMAP); MAPS board on the plaza beside the boards (MapBoard); the 3-near ragdolls roam the plaza (LabLayout10.TEST_FLOOR). R2.2 walkways 15 wide, light-grey slabs with the LAYOUT_V3_FLOOR tile texture (15/2 x 12) and kerbs, laid 4 s after the lab stands and cut wherever anything stands (GetPartBoundsInBox per 4-stud cell): 58 runs, nothing on a walkway. Capture ScreenCapture_R2a (from the plaza). Check next: the player stood at y 0 at z -264 after spawn (verify they land ON the plaza), the old spawn kiosk on the spawn circle, top-20 scrolling boards, F1 rejoin test, rope line, R2.3 fill plan.
- MAP ROUND 2 part 2 (multiplayer place v64): spawn checked: a fresh character stands ON the plaza (y 8.2 at z -269; the earlier y 0 was after walking off). `BOARD_TOP20`: LeaderboardService TOP 20 in a ScrollingFrame "List" (5 rows in view, wheel or drag), 40 lists x 20 rows built. Not done: your own row pinned at the bottom (needs a client view per player). Left in R2.1: the F1 rejoin test, the loose rope line; then R2.3 fill plan, M9, M10.
- MAP ROUND 2 part 3 (multiplayer place v65): the "yellow rope line across the grass" was the FirstTwo guide Beam to the next TRY machine (long on the big map): `TRY_GUIDE_LINE = false` hides it; the TRY button and goal line stay. Left: the F1 rejoin test (needs two Play sessions), R2.3 fill plan, M9, M10.
- MAP ROUND 2 part 4, R2.3 fill 1 (multiplayer place v66): LabOwnerMap.fill: car park with 6 parked cars (plan -80,42), small pool with loungers and umbrellas (127,-50), picnic + grill corner (-80,82), playground with slide and swings (90,108), training yard with tyres and hurdles (128,108), a parked 3-car train on the west rail (-129,6), hangar with forklift (128,-108), water tower (-142,-116), control tower (138,122), 3 portable toilets + kiosk (-6/-20,-117), lamp posts every 64 studs along every walkway. Whole lab 6300 BaseParts. Capture ScreenCapture_Fill1 (overview from the south). Left of R2.3: set pieces 1.5-2x, a dressed yard (pad, kerb, lamps, bench, props) round each machine, more groves along the outer edge, flower beds at the plaza, ragdolls walking in twos, birds; then M9, M10.
- MAP ROUND 3 P1+P2 (multiplayer place v67): LabOwnerMap.ground now builds FROM Shared/OwnerMapPlan: grass 980 x 850 at (-22,22), the 22 roads (boulevard 36, cross 26, avenues 16, spurs 14) as textured slabs with kerbs and round junction plazas, the 51 inner paths (12), room courtyards, the fountain (basin, spout, spray), Tower Square, South Cross, the raised spawn plaza (150 x 90, 4 high, railing, a 38-wide stair, side ramps), the station roof, the railway round west/south/east. Every built set piece moved to its plan item (planAt); slide, bridge and grandstand kept inside the Tower Square; the ball groves and grid walkways gone; lamps only along roads 16+ wide, every 32, alternating, none near plazas. Spawn (-30,-300) on the plaza (checked y 7.2), MAPS (25,-320) facing W, boards at z -360, 3-near on the plaza. Studio holds a COMPACT copy of OwnerMapPlan (same numbers) because Script Sync is off and the Assistant HTTP allowlist blocks raw.githubusercontent.com. Lab 6820 BaseParts; 22 road legs, 270 path legs (incl. kerbs counted separately). Capture ScreenCapture_R3top. NEXT P3: re-hook the code machines to plan spots (cannon, wrecking ball, boxing, fan, press, washer, mole, stretch, trampoline, rocket, cars, doghouse, creatures, train, bike loop); P4: tree belts round the rooms with openings + arch signs (Creator Store tree set: 3-4 broadleaf, 2 pines, 2-3 bushes), groves, hedges, flower beds; P5: yard dressing per attraction; P6 lint (nothing on paths/water/spawn, paths end at things, no old paving, no ball trees); then M9, M10.
- MAP ROUND 3 P3 (multiplayer place v68): the code machines on their OwnerMapPlan spots, measured in Play: cannon (-235,335), wrecking ball (-215,-30), boxing ring (-225,-95), fan (150,-85), trampoline (30,90), stretch machine (245,-48), doghouse (30,200), rocket (-185,358), spider (330,-220), shark (-230,-300), washer (335,-33), press (150,-29), mole (280,208), cars in the bays (-394/-370/-346, -95). (LabLayout10 absolute overrides after the x3.2; Playground cannon + wrecking ball; MapShopService fan and its origin-from-cannon; LabDress rocket; GuardDog HOUSE_AT.) Left in P3: the bike (51,21) to BikeRack (-235,95), slingshot facing the target, the cannon's firing direction (plan: west), the old bullseye/stations/pedestals/big button/like post/portals placement, the train route. NEXT P4 tree belts.
- MAP ROUND 3 P4 part 1 (multiplayer place v69): tree belts round the 8 walled rooms: 2 staggered tree rows (5 and 13 in, every 14) + a bush row (9 in, every 12), open at every entrance (GAP/2 + 5), an arch with the room name over each entrance. Trees: Creator Store MeshParts by PopperPoppet in V3Assets/Trees (TreeOak 3184730140, TreeFir 3184730904, TreePoplar 3184725416; one part each, no scripts, untextured: coloured green in code, a brown trunk cylinder on oak/poplar); bushes are squat oaks. 944 trees, 543 bushes. Whole lab now 9039 BaseParts (over the 8000 budget: M9 must cut, e.g. bigger spacing, no trunk parts, streaming). The old ball groves were removed in P2. Capture ScreenCapture_Belts (spawn view: boulevard, fountain, tower, belts on both sides). Left: groves, hedges and flower beds in the open areas, trees along the boulevard; the old spawn kiosk/portal building on the Tower Square (find and hide or move); P5 yards; P6 lint; M9; M10.
- MAP ROUND 3 M9 part 1 (multiplayer place v70): parts 9039 -> 6869 (LabV10, Heights and the mech-arm stand destroyed instead of hidden; trunks only on the front tree row; no kerbs on the inner paths; a sleeper every 10). The brown building on the Tower Square was the weapon range (Dress ShootingRange): moved to the Danger Zone at (150,305) via LabLayout10.MOVES.ShootingRange. Script Sync: the owner turned it on (27 Nov) but a test edit of OwnerMapPlan and LabOwnerMap on disk did NOT reach Studio, so pasting through the MCP goes on (Studio still has the compact OwnerMapPlan).
- MAP ROUND 3 P4b (multiplayer place v71): LabOwnerMap.parks: boulevard trees both sides; hedges, flower beds, trees and benches in the Spawn Gardens, Lawns and Picnic Park; flower beds in front of the spawn plaza; the duck pond with 4 ducks; the gazebo with its flower garden; the dog yard fence; THE BACKDROP: a 140-stud grass rim, a 3-row forest belt outside the railway, the Terrain hills moved out (+260) and 16 far mountains (+650). Lab 7680 BaseParts. Capture ScreenCapture_Parks (spawn view). A console warning "rbxassetid://81504106 not found" at boot is older (not the map).
- MAP ROUND 3 P6 lint part 1 (multiplayer place v72): LabOwnerMap.onPath (plan roads + inner paths, a margin) guards every tree, bush, lamp, flower bed, park bench, yard stone and pen post; the speaker wall moved south of the croc pond (cones toward it), the loungers to the north side of the lounge pool. Lint in Play: small things on paths 2 -> 0 after the bench guard. Things that legitimately touch a path: arch signs overhead, the fountain on the boulevard, the plaza stair and ramps, path ENDS at attractions (cannon, aquarium, creatures). Lab 7640 BaseParts.
- MAP ROUND 3 P5 (multiplayer place v73): LabOwnerMap.yards: at the end of every inner path to an attraction 2 lamps, a name sign on a post (36 names), a bench facing it and a crate/cone/barrel cluster (all guarded by onPath); each courtyard a lamp, a bin and a room-name sign. 41 signs. Lab 7986 BaseParts (at the 8000 budget: any more dressing must come out of something else). NEXT: the DEFINITION OF DONE captures (own_6..own_10 from the ref angles, top view vs masterplan.png, spawn view, a view in each room) and their harsh score; then OVERVIEW items 2-17.
- MAP ROUND 3 P7 (multiplayer place v74): the missing plan items: shop kiosk on the spawn plaza (sign only, no shop prompt yet), 3 launch pads aimed at the brick wall (look only, no launch yet), the bike rack (the bike now stands in it, LabLayout10.CARS.Bike), the landing field boards 50/100/150; the cannon fires WEST over the landing field (CANNON_DIRECTION under LAB_OWNERMAP). Lab 8010 BaseParts. Captures in art/store/lab10: own_top.jpg (top view: matches masterplan.png room by room), own_spawn.jpg (boulevard, fountain, tower, rooms hidden), own_room_cove.jpg (cave + bear, croc pond, aquarium), own_room_hall.jpg (fan, Tesla, stretcher, gyro). Far rooms capture empty because of streaming when the camera is away from the character: capture rooms with the character walked there.
- MAP ROUND 3 P8 (multiplayer place v75): the grandstand on the plan's spot north-east of the tower (rows rise north, seats face the tower), the slide run-out shortened to the plan's south-west spot, and the old-lab leftovers hidden (Bullseye, stations, pedestals, Guide, run stripes, hazard rim, the old Walkway, Zones, like post, spikes): checked in Play, none visible. The BIG RED BUTTON stays (a feature).
- Machine check (Play, v75): the cannon at its plan spot loads a dropped ragdoll, fires it WEST (velocity -61,3,-6) and it lands on the landing field at (-291,333); Tried_Cannon set. 10 creatures, the wrecking ball and the fan exist on their spots. Not yet tried one by one: wrecking ball swing, boxing ring, fan blow, press, washer, stretcher, trampoline, rocket, slingshot, mole, spider, shark.
- DEFINITION OF DONE status (honest, 27 Nov): 1 old lab gone: yes (LabV10/Heights destroyed, frame hidden). 2 size: the ground 980 x 850 + rim; zones on plan spots: yes. 3 R3.1/R3.1b checklist: most there; still missing or weak: grandstand and slide runout on the plan spots (plan png: NE and SW of the tower), the tower set pieces 1.5-2x, shop kiosk prompt, launch pads working, the gyro cage and shredder as real machines, the old bullseye/stations/pedestals/big button/like post placement. 4 every machine works on its spot: not play-tested one by one. 5 the 5 ref-angle captures own_6..own_10 scored 9.5: NOT done (the round-3 plan replaced the ref layout; captures above are plan views). Self score now: about 7/10. Map is NOT done.

## THE RUN ORDER (owner, 26 Nov 2026: "sørg for planen bliver lavet i den rette rækkefølge"). `/klar` follows this list top to bottom.
Why this order:
- the owner's deadline first;
- small quick wins next;
- then the FOUNDATION (physics and the body), which everything later builds on (dog, lasso, wheelchairs, walls, effects);
- then the big lab;
- then the features that use the lab and the physics;
- then session length.

| Step | What | Plan | State |
|---|---|---|---|
| 0 | **Owner:** press Alt+P to publish 0.58.0 (gore off), then send the maturity questionnaire, before Fri 27 Nov 17:34 UTC | `docs/MATURITY.md`, `docs/BODY_V2.md` "final answers" | BUILT, waiting for Alt+P |
| 0.3 | **The owner's fix list of 26 Nov evening (F1-F30):** + every start-place lab solo (nobody else visible), the multiplayer place = one lab with everyone; + the angry dummy shoves 1-3 times, every bone breakable (belly too), the bullet hits the bone on its real path, bones shatter; + no turning 3D icons on the weapon bar (small: do it right before the map); + the washing machine door and in/out through the porthole; + nicer shell casings; + the dog faces the limb it bites and moves like a real dog; + the full-width bar and the dim strip at the bottom on PC, an X-RAY key chip; + no hint strip on phones, fewer ragdolls at the spawn, machine demos once each with real ragdolls; + REVIVE ALL instead of Z, no white blob on shots, CPR faces the patient, hold-to-fire only for automatic weapons; TRY once, hit reactions by spot, no black screen, bullets in bones, bubbles, clean phone UI, the cannon load, talk about what they see, the dog icon, a German Shepherd, the PC nav, the multiplayer place | `docs/FIXES_26NOV.md` | DONE 0.70.0-0.75.0 (all 16; F4 and F10 part 1). State at the end of FIXES_26NOV.md. Studio now saves to the MULTIPLAYER place (v48-v51); the start place was last saved at v1129 |
| 0.5 | **The first 2 minutes + the new TRY:** a TRY button at the machine, a ragdoll comes, grab it (lesson only the first time) and put it in. This replaces the buggy floating TRY! sign (the bug notes below explain why it is removed) | `docs/FIRST_2_MIN.md` | built 0.60.0 (place v1117): `FIRST_TWO`, Client/FirstTwo, Lab.callTo, Session "Try"/"TryStep", +25 BOLTS a machine; `TRY_ME` off. Left: per-machine load spots (the whole machine glows), walk-to-start for no-load machines |
| 1 | Always 3 near you (update: not afraid of weapons; 2 chat, 1 comes all the way, rotating; they come very fast) + a watcher at every machine | `docs/ALWAYS3.md` (read the "Update" at the end) | 3-near built in 0.59.0; the update built in 0.61.0 (place v1118): `FEAR_WEAPONS` false, recruits Pace 2.2, 2 chatters + 1 comer rotating every 15-25 s (Lab assignRoles, Role3). **Left:** the watchers at every machine (stand-ins), new ones spawning out of view |
| 2 | The MULTIPLAYER icon instead of the portal | the section below | built 0.59.0 (`MP_ICON`, `MP_PORTAL` false); left: phone layout of the window |
| 2.5 | **Phones and tablets: much less lag, much smoother** (measure, then fix the top costs, an auto quality governor; the cool details stay) | `docs/PERF_MOBILE.md` | |
| 3 | **PERFECT PHYSICS + THE SMOOTH SKINNED BODY with real fingers** (`docs/BODY_V2.md` 4c): the hard checks, then falls, landings, lying and get-ups | `docs/RAGDOLL_FEEL.md` ("PERFECT physics" first) | part 1 in 0.62.0 (place v1119): a round's turn and push scale with its force, 0.6x-3x (`SHOT_WEIGHT`, ActiveRagdoll shotReaction). Found already: the speed cap (client sim 180 studs/s, ActiveRagdoll) and the server watchdog (over 220: sent home, Lab). To do: hit impulse at the exact point by weapon force, tone per limb, rest-sleep, piles, buoyancy, get-ups, the 5 bench clips |
| 4 | **PERFECT BULLET HOLES** + purple splatter on every hit | `docs/BODY_V2.md` 3 and 2b | checked: 2b exists already (BloodFx.wound: 3-12 purple droplets in the shot direction on every hit, landing; skipped only at the part cap); holes exist (BulletHoles, glued to the limb, sized by weapon).  0.63.0: `HOLE_VARIETY` (owner: "nye skudhuller, ikke det samme hver gang"): every hole its own size, oval by angle, tint, picture, stress ring and edge chip (no rings/chips on phones). Still parked: holes V2 (4 mesh variants, cracks, rim, exit holes, plastic chips) needs new hole art |
| 5 | The body: X-ray 10/10 (bones can break by force), the blood look, injury stages, bandages, faces | `docs/BODY_V2.md` 1, 1b, 2, 4b | part 1 in 0.63.0 (place v1120): X-RAY button + B key (owner: B is fine) (`XRAY_V2`, Client/XRayToggle, DummySkins.setXray: the nearest 16 / phones 6 within 80 studs, whole skeleton). Left: glass shell + blue outline look, mesh skeleton, 1b breaks, 2 blood look, 4b stages/bandages/faces |
| 6 | Impact smoke and dust, grab-swing-SLAM | `docs/IMPACT_FX.md` | part 1 in Studio, 0.64.0 (place v1121): `IMPACT_FX`: Client/ImpactDust (dust + bits by surface and speed, shock ring at 70+, 6 a second, 90 studs, half on phones), hooked in FxController "Land"; SLAM in GrabController (touch button by THROW while holding, right click on PC, "SMASH x2" on the goal line). Left: smoke trail, scuff decals, props react, camera shake/hit-stop on own slams |
| 7 | **The lab:** the owner's map 1:1, 10x bigger, faster running and sprint | `docs/LAB_TARGET.md` ROUND 3 | **GO NOW (owner, 26 Nov late): see "GO NOW: THE MAP" above; was parked for its own long run: a full new map at about 950x820 studs with new set pieces (cave, aquarium, pool, pen, sandcastle, shredder pit, crocodile pond, T-rex pen, garage, railway). It needs several sessions of building and side-by-side captures; done after steps 8-12 unless the owner says go now |
| 8 | Lasso, breakable concrete walls, wooden crates | `docs/DESTRUCTION.md` | part 1 in 0.65.0 (place v1122): `BREAKABLES` wooden crates (Systems/Breakables: 3 stacks a lab, shot holes, 4 rounds or a blast or a flying body break them to planks, back in 20 s). Left: the lasso, breakable concrete walls and brick wall |
| 9 | Burial + revenge | `docs/BODY_V2.md` 4 | built 0.66.0 (place v1123): `BURIAL` (Mourning bury(): shovel, 3 s dig with dirt, body hidden until it wakes, mound + R.I.P. stone 60 s, max 3, 1 burial at a time, not in a newcomer's first 2 min; then one cringe line and a 10 s revenge attack). Left: the funnel steps |
| 10 | The guard dog (tap a limb, it bites) | `docs/GUARD_DOG.md` | built 0.67.0 (place v1124): `GUARD_DOG` (Systems/GuardDog + Client/GuardDogClient): a code-built doghouse at lab (40,22) with Whistle (E); the robot dog follows; tap or click a limb (head picks an arm) and it runs there, bites that part (DummyControl.hit + VitalsService.wound), shakes, GOOD BOY!; dog button sends it home; home after 3 min idle. Tested: whistle + a leg bite. Left: tooth marks, X-ray jaws, a real dog model, limb-specific reactions |
| 10.5 | Human idle behaviour (fingers, stretching, yawning…) + a cyclist on a pedal bicycle round the lab | `docs/LIFE_IDLE.md` | |
| 11 | Wheelchairs | `docs/WHEELCHAIRS.md` | PARKED (`WHEELCHAIRS = false`): no wheelchair model in the place; VehicleService would draw a small car (box, lights). Needs a Creator Store wheelchair (malware pass) and its own run: seating a ragdoll, pushing, let go, crash ejection |
| 12 | Session length, the rest (item 1 is done in 0.57.0) | `docs/STAY_LONGER.md` 2-8 | item 2 in 0.57.0 (TRY reward); item 3 in 0.68.0: `LAB_SURPRISES` on again, about every 2 min (110-130 s), "Surprise in 10 s!" on the goal line (EventService SurpriseAt, LabShowcase); first wow is RocketRain (no extra dummies). Item 6 exists (StuntHud NEW BEST). Item 8 in 0.69.0 (place v1125): the daily gift and streak already exist (ProgressService); a quiet "Come back tomorrow: day N gift!" after 8 min (`COME_BACK_AT`). Left: 4 pacing check, 5 long goal after weapons, 7 A/B shared servers, Roblox experience notifications |

**The TRY! bug (the sign is REMOVED by FIRST_2_MIN; keep these notes only if any marker stays): causes found in `StarterPlayerScripts/.../Client/LabShowcase.luau` `tryMe()`. Fix all of them:**
1. **It flickers every second.** Every second the loop sets `sign.Adornee = nil`, `StudsOffsetWorldSpace = Vector3.zero`, sets `Adornee` again and re-parents the ring and sign, even when nothing changed. For a frame the sign jumps to the ring or the screen origin.
   - **Fix:** create, parent and adorn once. Only move the anchor when the target machine changes.
2. **It flips between machines.** The nearest untried machine is re-picked every second, so walking between two machines swaps the target back and forth.
   - **Fix:** keep the current target until it is tried, or until another machine is at least 40 % closer for 3 s in a row (hysteresis). Also never re-pick while the player moves faster than walking (flying, falling, in a car).
3. **It jumps up and down.** `floorY = hrp.Position.Y - 3` uses the PLAYER's height, so on the tower, when jumping or falling, the ring and sign jump.
   - **Fix:** use the machine's own floor (raycast down from the machine's centre once, when the target is picked).
4. **It shows through everything, from far away.** `AlwaysOnTop = true` with `MaxDistance = 220` shows the sign over walls and the HUD from across the lab.
   - **Fix:** `AlwaysOnTop = false`; `MaxDistance` about 90; hide it while a menu is open, in a car or in first-person aiming; and `ClipsDescendants` so it never sits off-screen as a big shape.
5. **It is too big on phones.** `Size` is 120x54 px fixed.
   - **Fix:** use a scale size that shrinks with distance (`Size = UDim2.fromScale(4, 1.8)`, studs-based), clamped. Max one TRY! at a time.
6. **Check:**
   - walk between 2 untried machines, climb the tower, jump, ride a car: the sign stays on ONE machine, steady, and never flickers;
   - on the phone emulator it is small and clean.

**How to work through it** (owner, 26 Nov 2026: "Sørg for den minder mig om punkt 0 og gør så den ikke stopper og beder mig teste undervejs"):
- **Start:** every /klar run starts with the Danish step 0 reminder, until step 0 is marked done.
- **Never stop to ask the owner to test,** and never wait mid-run. When only the owner can publish, save the place and ask for Alt+P only in the final message.
- **Questions** go into the owner list with a safe default.
- One quick Play after each step, and commit and push.
- **Publish** after steps 3-6 if the tools can do it without the owner; otherwise once at the end. Give ONE Danish "Test selv" list, in the final message only.
- Never ask the owner to test in between. Park questions with a safe default.

## RULE FOR EVERYTHING IN THIS PLAN (owner, 26 Nov 2026): mobile first, simple enough for a 10-year-old on an iPad
- **Phone and iPad first:** every new thing is built and checked on the phone and iPad emulators before PC and console.
- **One tap per action:**
  - big buttons (at least 60 px);
  - icons rather than words; at most 2 words on any button;
  - no reading needed to understand it.
- **Hints:** a first-time hint is one short line plus a pointing hand, shown once.
- **Performance:** within the phone caps (ragdolls, particles, parts); light stand-ins far away.

## Small UI change (owner, 26 Nov 2026): MULTIPLAYER as an icon
> "Det er allerede i spillet i portalen, bare lav det til et ikon i stedet for"

- **What exists:** the Multiplayer window (Play: QUICK JOIN / PLAY WITH FRIENDS; Open games; Private room; Join by code) opens from the multiplayer portal in the world.
- **The icon:** put a **MULTIPLAYER icon button** on the HUD nav (two-people icon, label "Multiplayer" on PC; on phones the icon only, at least 60 px, in the left stack under Shop / More / Lab). It opens the same window.
- **The portal:** hide the multiplayer portal behind a switch (`MP_PORTAL = false`; do not delete it). The SINGLEPLAYER way back stays reachable from the same window ("Back to my own lab").
- **The window on phones:**
  - near full-screen;
  - big buttons;
  - the side tabs as icons with short words;
  - text cut to one short line.
- **Order:** do it in the same run, right after ALWAYS3. It is small.

## FIRST, URGENT: `docs/BODY_V2.md` section 0, gore OFF (owner chose it, 26 Nov)
**State (26 Nov 2026): BUILT and saved as 0.58.0 (place v1114 -> v1115), waiting for the owner to publish (Alt+P).** Switches:
- `SEVERING = false`: no limbs off, no halves, no bursting heads; mech arms cannot tear.
- `GORE = false`:
  - creatures spit gold stars instead of bones or meat, red is purple, and no water turns red;
  - the press has no splat or drips;
  - the X-ray bone stays whole;
  - the words are KO, knocked out, OUT COLD and Energy.
- `STORE_TEXT.md`: "purple cartoon splats; no gore".
- Next: ALWAYS3, then the MULTIPLAYER icon, then LAB_TARGET ROUND 3 and the rest of the run.
**State 0.59.0 (place v1116, not published):**
- ALWAYS3 part 1 done (`ALWAYS_THREE`, Lab `alwaysThree`): far ones run in, near ones walk in and say a line.
- **Left:** the spawn out of view when no ragdoll is free; the "Spectators at every machine" section (`MACHINE_WATCHERS`, stand-ins).
- MULTIPLAYER icon done (`MP_ICON`, a "Multiplayer" square under Lab; `MP_PORTAL = false`). **Left:** the phone layout of its window (near full-screen, icon tabs).
- Next: LAB_TARGET ROUND 3.
- Build it, then **publish at once** (quick gate). The maturity questionnaire is due **Fri 27 Nov 2026 17:34 UTC** and must match the live game.
- Then tell the owner in Danish: "Gore er slået fra og live — send spørgeskemaet nu med svarene i docs/MATURITY.md".
- Only then the rest of the run.
- Right after it (small, big effect): `docs/ALWAYS3.md`, always 3 living ragdolls near the player; replacements run in from afar or walk in and say a line. Plus at least 1 watcher at every machine (section "Spectators").

## CURRENT RUN: `/klar` = LAB_TARGET ROUND 3. Do it now, all of it, without asking.
**Not blocked any more** (owner, 26 Nov 2026): "1:1 10/10 … jeg skal bare skrive /klar".
- Do not search for the old file.
- **The lab is 10x bigger (area) and the player runs faster:** see LAB_TARGET R3.2 "SIZE" and "RUN FASTER".
- Rebuild the owner's own map 1:1 from `art/store/look_target/lab_ref/ref_6` … `ref_10` (and `ref_1` … `ref_5`), as `docs/LAB_TARGET.md` ROUND 3 says.
- Then publish once and give one Danish "Test selv" list.
- In the same run, after the lab: `docs/IMPACT_FX.md` (smoke and dust on every impact, grab and SLAM).
- Then `docs/DESTRUCTION.md`: the LASSO (rope a ragdoll, drag and swing it), concrete walls that break where a body hits, and wooden crates with bullet holes that break into planks.
- Then `docs/BODY_V2.md` sections 1-4b: X-ray 10/10, purple blood look, hit marks instead of holes, burial + revenge, injury stages + real bandages + changing faces.
- Then `docs/GUARD_DOG.md`: whistle the guard dog; tap a ragdoll's limb and it bites exactly that limb. The reaction fits the limb, the damage stays, and X-ray shows the bite.
- Then `docs/WHEELCHAIRS.md`: drivable wheelchairs; put ragdolls in them, push, let go and crash.
- Then `docs/RAGDOLL_FEEL.md`: realistic falls, landings, lying and get-ups like the top ragdoll games.
- Then: `docs/STAY_LONGER.md`.

(Older notes below.)

## CURRENT RUN: LAB TARGET (owner, 26 Nov 2026)

**NOW: `docs/LAB_TARGET.md` ROUND 2.** The references are the owner's OWN old map. Find that version (version history, backups), copy its lab 1:1 into `ServerStorage.OldLabMap`, use it at full size behind `LAB_OLDMAP`, and put every machine where it stood. No rebuilding by eye.

**State (26 Nov 2026, ROUND 2 step 0): BLOCKED on the owner.** The old map is not found:
- not in git (no "Lasso", "Scan" or "Tools" HUD in any commit; git starts 19 Nov 2026);
- not in the local .rbxl files (AutoSaves 20 and 24 Nov and server.rbxl are this game; `Documents\Place1.rbxl`, 31 Oct, 385 KB, is unchecked and is the only candidate);
- Open Cloud asset versions need the `legacy-asset:manage` scope, which is off, and the MCP cannot open a place file.

Asked the owner: which game, version or file is it from? To go on, the owner can do one of these:
- (a) open the old version in Studio (File > Open from Roblox, or Version History > open), so Claude copies the lab from that Studio window;
- (b) open `Documents\Place1.rbxl` if that is it;
- (c) send the game link.

Nothing else in NOW.md can be done without the owner. In WEAKNESSES "Order to fix":
- 3 needs a real phone;
- 4 needs the dislike reasons;
- 5 onwards are new features waiting for direction.

Build `docs/LAB_TARGET.md`: the lab to the owner's reference screenshots (`art/store/look_target/lab_ref/`).
- A realistic plot grid.
- The steel tower and slide in the centre.
- A raised spawn plaza with 4 leaderboards.
- Railway, hills and trees.

It replaces LAB10's cartoon look. Keep attract mode, the "try me" chain and harsh scoring from ROUND 2.

**State (26 Nov 2026):** round 1 of LAB TARGET built and saved (0.56.0, place v1113, `LAB_PARK`). LAB10 R2 part 1 (attract mode, TRY!, zone pads) is in 0.55.0. Not published yet (owner: Alt+P). Next: see LAB_TARGET.md "State": the 50-stud steel scaffold tower, a true plot grid, the 5 reference captures.

The rules are as before:
- one run;
- publish once;
- one Danish "Test selv" list;
- never ask the owner to test in between.

(Older:) ## CURRENT RUN: LAB 10/10 (owner, 26 Nov 2026)

**ROUND 2 NOW** (owner scored round 1 at 3/10): build `docs/LAB10.md` section "ROUND 2". Main things:
- attract mode on every machine;
- the "try me" chain;
- replacing the weak machines;
- 3 new ones;
- the hero tower;
- a denser lab with a floor that has life.

Score harshly.

> "Hele labbet skal tages fra 2/10 til 10/10, ikke vær bange for at ændre ALT"

Build `docs/LAB10.md` in one run: everything, then publish ONCE, then ONE Danish "Test selv" list. Do not ask the owner to test in between. Questions go into the owner list with a safe default.
Then finish what is "Left" from item 1 (More window, bigger hotbar, portrait check) in the same run.

**State (26 Nov 2026):** round 1 built and saved (0.54.0, place v1111): the crash-test lab behind `LAB_V10` (see LAB10.md "State"), plus item 1 leftovers: `PHONE_MORE_FLAT`, `PHONE_BIG_HOTBAR` (portrait was already locked to landscape). Not published yet (owner: Alt+P). Round 2 (signs, hero tower, travel gate, shop row) is listed in LAB10.md "Left".

---

## Earlier run (0.53.0, done 26 Nov; kept for reference)

**URGENT, owner only:** the maturity questionnaire (item 5) must be resubmitted by Fri 27 Nov 2026 17:34 UTC.

Status: **GO** (owner, 26 Nov 2026). Build EVERYTHING in this list in one run before the owner tests.

> "Sørg for at den laver alt før jeg skal teste, så jeg ikke skal ind og teste flere gange i løbet af i dag"

**Targets and order of levers:** `docs/STRATEGY.md`, the 1-week column. Every item is judged against those funnels.

**How this run works (owner order, 26 Nov 2026; it overrides "publish and test after each item"):**
- Build items 0-8 top to bottom in ONE session, without stopping to ask. Item 5 is the owner's (only prepare the answers).
- After each item: one quick Play (no errors), commit and push, mark it done here. **Do not ask the owner to test in between.**
- Anything that needs the owner (new product ids, a picture choice, a yes/no): pick the safe default behind a Config switch, write it in the "Questions for the owner" list at the end, and go on. Never wait.
- **3.18 boxing bets (27 Nov):** betting BOLTS on a ragdoll fight can read as gambling in a kids game. Default: a free "pick the winner" (no stake; a cheer and a streak if right). Say "bets with BOLTS" if you want real stakes. The fight itself (2 ragdolls, bell, referee count) is still to be built; the ring canvas is the hazard launcher today.
- **F89 (27 Nov):** may Claude upload models itself? Add `C:\Users\tristan\Documents\RagdollLab\art\models` to Studio Assistant Settings > MCP Permissions > upload folders. Default: you import `mannequin_v2.fbx` yourself (File > Import 3D).
- **Publish ONCE at the end** through RELEASE.md (quick gate; never restart old servers).
- Then give the owner **ONE combined Danish "Test selv" list** for everything, grouped by device (phone first, then PC, tablet, console), max about 15 lines, plus the "Questions for the owner" list.

0. **WEAPONS list: no BUY, no TRY FREE, only the next weapon shows its KOs** (owner, 26 Nov 2026; do this first, it is small).
   > "Gør så man ikke kan se "Buy" ved hver ting i WEAPONS, men man kun kan se hvor mange KOs man mangler. Så man skal kun kunne se hvor mange KO's man mangler ved det våben man er kommet til, ikke hvor mange KO's det tager at få en sniper fx. og fjern try free ved alle våbene."
   - **File:** `StarterPlayerScripts/.../Client/ToolCatalog.luau` (BUY around line 200-225, TRY FREE around 650-690, the count line at 288, the intro at 427).
   - **Remove BUY** from every weapon card in WEAPONS. Behind a Config switch (`WEAPONS_NO_BUY = true`); the weapon products stay live in the shop, only the cards lose the button.
   - **Remove TRY FREE** from every weapon card (`WEAPONS_NO_TRY = true`). Also stop the "free try is over … or BUY it" toast and any other TRY FREE prompt (TrialService, ProgressService). Do not delete TrialService; just switch it off.
   - **The KO bar shows only on the next weapon to earn** (the first locked one in unlock order): "12 KOs to go" plus its bar. Every later locked weapon shows a lock and "Locked" only, with no number and no bar.
   - **Unlocked weapons:** EQUIP as now.
   - **The weapons stay for sale in SHOP** (owner, 26 Nov). Check that every weapon product is in SHOP (ITEMS, or a WEAPONS tab); add the missing ones, with a picture and the price from Roblox.
   - **Texts:** the line "Locked: earn KOs, BUY, or TRY FREE for 2 min" becomes "Earn KOs to unlock the next weapon". The intro loses "or BUY".
   - **Test selv:** open WEAPONS on PC and on a phone. There are no BUY or TRY FREE buttons, only one card shows "X KOs to go", and the rest say Locked.
   - This overrides item 8's "TRY before buy" and "Get it now" for weapons.

1. **PHONE FIRST: the whole game is built for a phone in landscape** (owner, 26 Nov 2026, after the phone screenshots: "Nu hvor jeg ser det på mobil, kan jeg pludselig godt forstå hvorfor vores spillere ikke spiller så længe"). Most players are on a phone. This is the biggest lever on the 1-5 minute leak, so it comes before everything except item 0.

   **What the phone screenshots show** (iPhone, landscape, 26 Nov):
   - **No clear thing to do.** The top pill reads "Every weapon..." (cut off and meaningless). There is no goal, no KO count and no "shoot that dummy".
   - **Your own FOUNDER and VIP tags sit in the middle of the screen**, right on the crosshair, and your character blocks the dummy you aim at.
   - **Grey dummies on a light grey floor under a white sky.** The targets almost vanish; everything looks washed out. The city map is fog-white.
   - **The left side is cluttered:** Shop, Menu (red !), REVIVE (unclear, shown while alive) and the Roblox buttons. The red ! badges are everywhere: Menu, RANK & EGGS, GIFT.
   - **Menus are a small window on a small screen:**
     - **Shop:** one card visible; FEATURED shows "Everything" even when you OWN it; "CODES" breaks into "CO DES".
     - **Weapons:** 4 tiny cards per row; pictures cut; descriptions cut ("Quick little pops. Your"); COMMON tags bigger than the picture.
     - **More:** a menu inside a menu (MAPS, LAB, GOD MODE, REWARDS, RANK & EGGS, FRIENDS, SETTINGS, FAVORITE…), so key things are 2 taps deep.
   - **The Map board in the world is unreadable** on a phone (tiny text on tiny thumbnails).
   - **The hotbar is small** (an unclear red kit icon, Popper, Sniper, Heal). RELOAD 17/17 is small. The SHOOT button is good.

   **The rule from now on:**
   - On a phone, the screen at any moment shows only the target, SHOOT, the hotbar and ONE goal line. Everything else is at most one tap away.
   - Every new UI is built and checked at phone size first (Studio Device emulator, iPhone landscape + a small Android), then tablet, console, PC.
   - Minimum touch target 44 px (Roblox's own guidance); no text under about 14 px on a phone; never cut text: shorten it.

   **Do, in this order** (each small, each published on its own):
   1. **Clean the centre.**
      - Hide your OWN overhead tags (FOUNDER, VIP, rank) for yourself on every device; others still see them. Smaller, higher tags on others.
      - Over-the-shoulder camera on a phone when holding a gun: the character moves left and down so the crosshair sees the target (`Config.PHONE_SHOULDER_CAM`). The first-person switch on the first shot stays as it is on PC; check what feels best on a phone and keep one.
   2. **Aim help on a phone** (`Config.PHONE_AIM_ASSIST`): a soft pull toward the nearest dummy within a small cone of the crosshair, and "tap a dummy to shoot it". The biggest mobile shooters all do this. Hit marker + a short haptic buzz (HapticService) on hit and on KO.
   3. **Targets you can see.**
      - Dummies must stand out from the floor: darker or warmer floor in the lab, or a slightly darker dummy grey (the owner keeps grey dummies; show 2 options as screenshots before picking).
      - Less fog and brighter, warmer light on the maps on phones; the city map must not be fog-white.
      - A small bobbing arrow over the nearest dummy for new players (first 2 min), off after the first few KOs.
   4. **One goal line instead of "Every weapon..."**: the top pill shows the next goal, short and live: "Next: Bow — 3 KOs" with a bar. When it is reached, a big unlock moment ("BOW UNLOCKED!", sound, buzz, auto-equip). This also carries item 4's minute moments ("Press the red button!", "Try the cannon!").
   5. **A clean left side and fewer badges.**
      - On a phone: Shop and Menu only, bigger (44 px+). REVIVE only shows when you are down.
      - **No notifications on a phone** (owner, 26 Nov: "fjern Free Gift notifikationer osv fra tlf"):
        - the GIFT button with its timer and red ! is gone from the phone HUD; the free gift is claimed from Menu → REWARDS (a quiet dot there only when it is ready);
        - no red ! badges on a phone at all (Menu, RANK & EGGS, …);
        - no pop-up toasts or banners on a phone for gifts, rewards, eggs, codes, "free try", sales, What's New, server events or other players. Only things about YOUR play stay, small and short: a KO, an unlock, low ammo;
        - What's New does not open by itself on a phone;
        - one switch, `Config.PHONE_QUIET = true`; tablets follow phones; PC and console keep today's notices.
   6. **Phone menus.**
      - Every menu opens nearly full-screen on a phone (safe area kept), with big close X.
      - **Weapons:** 2-3 big cards per row, a big picture, name, the lock or EQUIP; no description and no stats on a phone (tap a card for details).
      - **Shop:** FEATURED never shows an owned item (show the best unowned one); 2 big cards per row; tabs that fit (CODES not broken); the cheap starter offer first (item 8).
      - **More:** flatter. The 4 most used (MAPS, LAB, REWARDS, SETTINGS) as big buttons; the rest below. MAPS also gets its own button on the HUD if there is room.
   7. **The Map board:** on a phone, walking up to it (or tapping it) opens the big MAPS menu. The board itself gets fewer, bigger tiles with big names.
   8. **The hotbar:** bigger slots on a phone, a clear icon for the kit (or move it into Menu), the ammo shown on the slot, RELOAD bigger or automatic when empty.
   9. **Phone lag** goes with item 3: measure on a real mid phone, keep 60 fps in the lab and 30+ in events.
   10. **Portrait (upright):** check that the game is usable upright or lock it to landscape on phones; no half-broken middle state.
   - **Measure:** split every funnel step by device (phone / tablet / PC / console) in the custom events, so we see if the phone gap closes. Target: phone 5-min retention equal to PC within 2 weeks.
   - **Test selv** (after each sub-step): on your own phone, in landscape, from a fresh join: can you see what to do, hit a dummy within 10 seconds, and read every menu without zooming?

2. **Ragdolls fall through or half into the ground.**
   - Find the cause: a thin floor for fast bodies, the pad floor, new dummy masses, the time bubble, or spawning half inside the floor.
   - Fix: an invisible thick safety floor under the lab and every map; bodies always created above the floor; any body below the floor put back.
3. **Lag on every platform.**
   - Measure first: server heartbeat, script time, network, phone FPS.
   - Fix the 5 heaviest things: loops, bodies and effects caps, lights, far things, leaks.
   - Lower detail on weak phones without losing the PC look.
4. **Fix the 1-5 minute leak and find why people dislike** (the funnels of 26 Nov, `docs/FUNNELS.md`: half the players at 2 min are gone by 5 min, and 47 % stop between 10 and 25 KOs; targets are in that file).
   - **A new pull every minute in the first 5 minutes:**
     - unlocks close together early: a new weapon at about 3, 6, 10, 15, 20 and 25 KOs (retune `LADDER_V9_KEEP` / the first rungs, and keep the later gaps);
     - each unlock a big, satisfying reveal;
     - the "Next" bar is always visible.
   - **A planned moment at about 1, 2, 3 and 4 minutes** for new players, without pop-up spam:
     - about 1 min: the angry dummy (item 6);
     - about 2 min: a free mini event in your lab (the red button lights up: "Press me!");
     - about 3 min: the first terminal or creature gets pointed out (a calm glow);
     - about 4 min: the Map board gets pointed out ("New place unlocked: Island").
     - These go through Notify / FirstVisit and the V9-0g phone sizes.
   - **Variety past 10 KOs:** the walkers, the GOD mode spawns and the machines are in view. The dummy line-up changes now and then (new dummy types walking in), so there is always something new to hit.
   - **Measure:** add custom funnel steps (AnalyticsService funnel events) so the Creator Hub shows:
     - the minute moments above;
     - the first unlock, the first terminal used, the first map trip;
     - the tutorial steps (item 7);
     - shop: opened → item viewed → prompt → **bought**.
   - **Dislikes:**
     - read Session_v1 (leave times, errors, FPS by device) and the like ratio by version;
     - add an optional "How's the game?" thumbs + reason (no reward);
     - write a short report with the top 3 reasons and the fixes into `docs/FUNNELS.md`.
   - **Test selv:** play 5 minutes as a new player (StudioFresh) and note what happens each minute.
5. **Answer Roblox's mail about the maturity questionnaire** (they rejected the last answers).
   - Needs the owner to paste the mail and the old answers.
   - List what the game really contains: purple blood, guns, the words "Dead" and "bled out".
   - Draft honest answers, and offer the choice: keep the content and the label it gives, or tone it down for a lower age label.
   - **The owner submits.**
6. **The first dummy you hit twice gets angry**, unless the first shot kills it; then it is the next dummy hit twice.
   - Red face and a short tantrum; it runs at you and gives a harmless, funny shove or slap (no damage), then flees.
   - Once per player early on, then rarely.
   - The owner has not answered shove or scold yet: build the harmless shove behind `Config.ANGRY_SHOVE = true` (one switch to turn it into scolding only) and put the question in the owner list.
7. **A tutorial on every device** (PC, phone, tablet, console).
   - 3-4 short show-don't-tell steps: shoot a dummy, grab and throw, use a terminal, find the Map board.
   - The right input glyphs per device; skippable; newcomers only; no pop-ups on top.
   - Measure step completion.
8. **Best sellers, the shop and Robux** (funnel: only 8 % open the shop, and 11 % of them press buy).
   - **Read the sales:** what sells, where it stood, and whether it was tried first. Write the analysis into `docs/FUNNELS.md`.
   - **The shop opens more:**
     - a clear SHOP button;
     - the booths in the lab show a real, cheap, cool item;
     - (not on weapons: item 0 removes BUY there).
   - **More presses buy:**
     - one cheap starter offer first (R$ 25-49, clear big value);
     - a few strong items up front instead of a wall of passes;
     - "Popular" and "Best value" tags from the real sales;
     - TRY before buy on things that can be tried (not weapons, see item 0);
     - pictures and 3D that show what you get.
   - **Move the best sellers forward** in the lab and the shop, and rework or move the weak ones. Change what is shown in the lab.
   - **New items:**
     - **death effects** (fireworks, confetti, a ghost dummy floating up, gold sparkle, cartoon blast);
     - more cosmetics (trails, KO sounds, dummy skins, emotes);
     - fair, with no pay-to-win.
   - Give the owner the product list to create.
   - **Measure:** the shop funnel with a "Bought" step.

## Done in the run of 26 Nov 2026 (release 0.53.0, place saved v1110; Script Sync was OFF: every script went in through the MCP, checked by length)
- **0 done:** `WEAPONS_NO_BUY`, `WEAPONS_NO_TRY` (TrialService refuses), only the next weapon shows "N KOs to go", the rest LOCKED; every weapon sold in SHOP > ITEMS > WEAPONS (its tier product; "NEARLY YOURS" when within 15 KOs).
- **1 mostly done:** own FOUNDER/VIP tags hidden (`HIDE_OWN_TAGS`), phone shoulder cam with a gun (`PHONE_SHOULDER_CAM`), wider touch aim help + hit buzz (`PHONE_AIM_ASSIST`), darker dummies (92,95,102) and warmer hub floor, half the fog on phones (`PHONE_CLEAR_AIR`), bobbing arrow for newcomers (`TARGET_ARROW`), goal pill "Next: X  N KOs" (`GOAL_LINE`), `PHONE_QUIET` (Client/PhoneQuiet: no gift button, no red badges, no pop-ups about gifts/eggs/codes/sales, no event card, no auto What's New, REVIVE only when a dummy is down), `PHONE_MENUS` (3 big weapon cards a row, FEATURED hides owned, CODES on one line, walking to the MAPS board opens MAPS). 1.10: portrait was already locked to landscape (StarterGui + LoadCover). 1.6 `PHONE_MORE_FLAT` (MORE starts with MAPS, LAB, REWARDS, SETTINGS) and 1.8 `PHONE_BIG_HOTBAR` (landscape phone slots 62x56) are in Studio and saved (v1111). **Left:** real-phone FPS.
- **2 done:** GroundGuard rescues a body with nothing under it and lifts a sunk head/chest, taking the body from its player for 0.5 s (`GROUND_RESCUE`).
- **3 partly:** measured (server p95 18 ms; client UI 22.7k objects, WEAPONS alone 8.7k); WEAPONS builds a shelf when shown (`LAZY_SHELVES`, now 16.3k total). **Left:** a real mid phone, lights/beams on phones.
- **4 partly:** the ladder already unlocks at 3,4,5,8,10,13,16,18,21,24 KOs (denser than the target): unchanged. Minute moments at 2/3/4 min in the goal pill with a white outline (`MINUTE_MOMENTS`, Client/MinuteMoments). Funnels NewPhone/NewTablet/NewPC/NewConsole + "Tutorial"; player attribute `Device`. **Left:** read Session_v1 + like ratio, the "How's the game?" prompt, the dislike report.
- **5 prepared:** docs/MATURITY.md (what the game contains + two answer options). Owner submits.
- **6 done:** `ANGRY_FIRST` + `ANGRY_SHOVE` in Mourning.provoke (2nd hit on one dummy, newcomers under 60 KOs, once a visit).
- **7 done:** FirstVisit got "GRAB a dummy and THROW it!" and "Walk to the MAPS board"; each step logs the Tutorial funnel.
- **8 partly:** `SHOP_CHEAP_FIRST` (hero = Starter Crate R$49, cheaper FEATURED picks). **Left:** sales analysis (live data), death effects / cosmetics (need product ids).
- Not published yet: the owner presses Alt+P (no publish action over MCP; Open Cloud cannot upload .rbxl).

## BODY V3 approval (owner gate)
- **BODY V3: waiting for the owner's OK** (built v1296, 27 Nov): renders in `art/models/mannequin/review_v3/` (front, three_quarter, side, back, posed_front, knocked_down, next_to_player: the blue block is a 5.2-stud player). Chunky toy crash-test dummy: chest 2.0 wide, thick limbs, 13 dark joint rings, a chest plate with 4 bolts, yellow-black quarter-circle marks on the plate, knees and upper arms, baked AO; 14.5k tris; no head in the mesh (the dummy keeps its Head with the living faces). The fit pass (R9 + the list in RAGDOLL_10) is PARKED until "BODY V3 APPROVED". Nothing in the game uses v3 until the owner imports it.

## ANSWERS (cloud session for the owner, 27 Nov): use these, do not ask again
1. **X-RAY on I, REVIVE ALL on X:** yes, keep both.
2. **The angry dummy:** keep the harmless shove (1-3, a cooldown). Never in a NEW player's first 3 minutes (FTUE_10 fix 2).
3. **The dummy colour:** the light grey of F89 (about 163,162,165), as in the owner's reference shots; not the dark 92,95,102 and not yellow.
4. **Maturity:** gore OFF for all ages (decided 26 Nov). Purple cartoon only. Do not ask again.
5. **Death effects for sale:** NOT now. Keep them hidden; revisit after the owner's test and release.
6. **Script Sync:** do not wait for it and do not ask again; keep using the MCP with the length check. (The owner may turn it on later; nothing depends on it.)
7. **Places:** Studio is on the START place. Publish BOTH places only at the very end, after the owner has tested (the steps go in the final message).
8. **The German Shepherd:** no purchase. Blender is installed, so A0 builds a RIGGED shepherd in Blender (CREATURES_ANIM: the dog row), with real leg, tail, ear and jaw animation.
9. **The Ford:** the owner wants only the bicycle and the dirt bike free. Keep the code as it is (the pass is used once it is for sale). The owner puts pass 2092632252 on sale in the Creator Hub.
10. **The 5 new vehicles:** build them fully now (models, features, the touch button), each with SOON until the owner sends the pass ids. The suggested prices stand.
11. **The smooth body v2 (F89):** the owner imports `art/models/mannequin/mannequin_v2.fbx` once (Studio, Home or Avatar tab, Import 3D, as a rig, into ReplicatedStorage as SmoothBody, replacing v1). Until then keep v1 hidden if its arms are still up: show the slim grey block body rather than the bodybuilder pose. No Open Cloud key.
12. **3.18 boxing:** use the default: a free "PICK THE WINNER" (no BOLTS stake; a cheer, a streak and a small streak badge if right). No betting with currency in a kids' game. Now build the fight: 2 ragdolls, the bell, punches with the active ragdoll, knockdowns and the referee's count to 10.
13. **Row 14, a ragdoll in a wheelchair:** build the "ride welded" state in ActiveRagdoll (balance, lift and drive off; the pelvis welded to the seat; the client simulation stays with the chair's owner; a sitting pose; it falls out on a hard stop or a hit) and use it for the wheelchairs, the bicycle passenger and the rocket strap.
14. **F68, the water button:** closed. Real water is always on (F78/F87); nothing to find.

## Questions for the owner (filled in during the run)
- X-RAY key: B is already Build mode, so X-RAY is on I now (default). OK, or another key?
- Angry dummy: a harmless shove (now) or scolding only? (`ANGRY_SHOVE`)
- Dummy colour: darker grey (92,95,102, now) or the old (112,114,118)?
- Maturity: keep the gore (13+/17+) or switch it off for all ages? See docs/MATURITY.md.
- Death effects to sell (fireworks, confetti, ghost, gold sparkle, cartoon blast, R$ 49-99 each): create them as passes and send the ids?
- Script Sync is off in Studio: turn it on again, or allow localhost in MCP HTTP allow list (faster, cheaper sessions).
- (26 Nov, F12) Studio now saves to the Multiplayer place. Publish BOTH: File > Publish to Roblox As > the start place (126037745825106) > Overwrite, and the multiplayer place. OK?
- (27 Nov) Script Sync: after turning it on, a change to a file on disk still did not reach Studio. Check the 3 folders show the sync icon and point at DocumentsRagdollLab (ServerScriptServiceServer, ReplicatedStorageReplicatedStorageShared, StarterPlayerScriptsStarterPlayerScriptsClient).
- (26 Nov, F13) REVIVE ALL kept its key X (R and Z are taken). OK?
- (26 Nov, F10) The German Shepherd is one rigid mesh (no free rigged one found), moved by code (trot bob, wiggle, bite shake). For real leg animations: buy or send a rigged German Shepherd (Creator Store id), or keep this?
- (27 Nov, F76) The Ford: its pass 2092632252 is used only if Roblox says it is for sale; otherwise the Ford stays FREE. Put it on sale (or tell me to keep it free). The 5 new vehicles + the bicycle show SOON until you send their pass ids (suggested: go-kart 49, police 99, monster truck 149, bulldozer 149, fire truck 199).
- (27 Nov, S2) The smooth body is built in Blender: art/models/mannequin/mannequin.fbx. Import it ONCE: Studio > File > Import 3D > that file (as a rig), or allow me to upload it as a Model asset on your account (Open Cloud asset:write + an approved folder). Default: waiting; the real hands from parts are on now.

## Phone button map (checked 26 Nov 2026, 0.63.0, iPhone landscape 750x381 in the emulator with DevTouch)
- **Left:** Shop and Menu in row 1, then Multiplayer (`HudMenu.PHONE_KEEP`, `PortalUI` launcher). The move stick is under them.
- **Top centre:** goal pill and gift (no red ! under `PHONE_QUIET`).
- **Top right:** first-person eye, with the body-card arrow just left of it. The arrow moves left of LAB VIEW when that shows.
- **Right column:** X-RAY (60 px, y 62), RELOAD, JUMP.
- **Right bottom:** SHOOT, with TRY right over it (FirstTwo places TRY from SHOOT's real spot).
- **Bottom centre:** the hotbar, 62x56 slots.
- **Studio note:** without DevTouch the emulator reads as a touch laptop and shows the PC sandbox column (1ST/SLOW-MO/REVIVE/RESET), which overlaps JUMP. Real phones never show it.
- Picture: `art/store/phone_hud_0.63.jpg`.
- **F68 water button:** I found no button that turns water on in the start place (0 prompts, click detectors or scripts near water). Which place is it in, and where (a screenshot)? Default: parked until you say.
- **S2 smooth body:** built in Blender (27 Nov), see the question above (one import).
- **M4 smaller map:** Python is installed now; the compact plan is ready (cloud). Built in M4.
- ~~Row 6 new faces~~: done 27 Nov (Pillow installed by the owner; FACES_V2, v1241).

## Done in the run of 27 Nov 2026 (start place v1203-v1228; Script Sync OFF: every script through the MCP, checked by length)
- F86 kneeling moods, F87 aquarium water from parts, D12 bones 12/10 (integrity, weapon classes, drips, stage sounds, X-ray cracks, ribs/skull), F47 tweezers + bullets + plaster, F26 shove series, F28 X-ray tracer, row 5 physics watchdog + no tunnelling, row 6 crying face, row 7 own-slam shake, F88 RAGDOLL BOWLING part 1 (+ chicken to its coop), F78 splash + aquarium buoyancy, F76 free bicycle, P1 personas + spread over the map, row 13 dog bark + pet, T1 bowling-first FTUE + X-RAY pulse + bike hint, row 8 Graphics AUTO/LOW/HIGH, row 15 MP window on phones, row 17 burial funnel, row 14 wheelchairs.
- The cloud's regenerated OwnerMapPlan (F88/T1) was NOT in Studio until v1217: compare cloud-changed .luau files with Studio before relying on them.
- Left (see each row's LEFT in OVERVIEW): S1/F73/F72/S2 leftovers, D12 trickle, F88 animations/swipe/sounds, F76 5 vehicles (pass ids), P1 filming/hiding/CPR, T1 rest of the timeline, row 3 MACHINES_10, A0 creatures (Blender), 1.0 rules 2-11, F81 dispenser, row 14 put-a-ragdoll-in, 0.1568 swap, 11 hurt idles, 0.7 watchers.
- Later in the same run (v1229-v1239): 0.7 watcher pairs, 11 foot tap/pebble/hold-side idles, F88 strike crash + confetti and gutter trombone, D12 trickle, T1 golden ragdoll (~2:00) and the 8/12 min lines, 1.0 rule 3 event crowd, P1 heroes give CPR first, 3.1 cannon targets, 3.2 tower drop score, 3.5 trampoline bounce chain.
- Next /klar: row 3 from 3.3 (gyro: straps, hold-to-spin dial, G-force score), 3.4 fan, 3.6 wrecking ball...; then S1/F73/F72 leftovers, F81 dispenser, 0.1568 swap, F76 vehicles (pass ids), A0 (Blender), S2 (owner FBX import).

## Done in the run of 27 Nov, part 4 (v1267-v1286)
- F89 slim grey body v2 (`SMOOTH_BODY_V2`; waiting for the owner to import art/models/mannequin/mannequin_v2.fbx), S1 gesture layers + foot IK, F73 turn steps (`TURN_STEP`), F72 NavTarget.snap + touch reaction (`NAV_SNAP`), F47 DEATH_HEAL, BUOYANCY_V2, PUDDLE_GLOSS, INJURY_V2, CRATE_BURST, HAND_POSES, BIKE_PEDAL, SWIM_POSE, POLITE_DISTANCE, TIE_SHOE, FILM_PHONE, WHALE_10, TARGET_RUN, SEESAW_10, PLAYER_CPR, EVENT_MIN_FLUNG.
- Parked: 3.18 boxing (question), row 14 ragdoll-in-chair (needs a ride-welded state).
- Left (big): A0 Blender remodel of every animal and machine, T1 rest, row 8 join hitch, M4 object meshes, BOWLING_12 rest, F76 new vehicles (pass ids), the lasso, 3.33 rest, 3.35 weapons pass.

Done in the run of 27 Nov, part 3 (start place v1240-v1264; Script Sync OFF: every script through the MCP, checked by length)
Owner's wishes first: Pillow installed (13.0), the imported Blender body hooked up.
- S2 v1240 `SMOOTH_BODY` (Client/SmoothBody): the Blender body (now ReplicatedStorage.SmoothBody, place file only) on the nearest 12 ragdolls; bones follow the physics parts; fingers posed by state; block skins hidden; X-ray/machines show the old look.
- Row 6 v1241 `FACES_V2`: 7 new faces drawn with Pillow (art/faces/v2/make_faces.py) and uploaded: dead X eyes, pain, angry, worried, sad, relieved, scared.
- Row 3 machines (one switch each): 3.3 GYRO_10, 3.4 FAN_10 (Systems/FanMachine), 3.6 WRECK_10, 3.7 PRESS_10, 3.8 WASHER_10, 3.9 ROCKET_10, 3.10 WALL_10, 3.11 DOG_10, 3.12 SHARK_10, 3.13 SPIDER_10, 3.14 FROG_10, 3.15 PLANT_10, 3.16 CHICKEN_10, 3.17 CAR_10, 3.19 STRETCH_10, 3.20 TESLA_10, 3.21 SHRED_10, 3.22 SWEEP_10, 3.23 LAVA_10, 3.24 MOLE_10, 3.25 SLING_10, 3.27-3.29 ANIMALS_10 (Systems/AnimalCove), 3.30 EVENT_STATS. Every score keeps a per-player NEW BEST attribute (session only, not saved).
- Fixes found on the way: a body-fall THUD was looping as the motor sound of the stretcher (now a PSE motor hum); the washer's door spray was dark red with gore off.
- Left in row 3: 3.18 boxing bets, 3.26 whale spout, 3.31 weapon range, 3.32 rides airtime, 3.33 small fun spots, 3.34 player actions (CPR rhythm, lasso), 3.35 weapons pass.
