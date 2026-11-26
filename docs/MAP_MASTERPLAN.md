# MAP ROUND 4: SMALLER, like the owner's references; far fewer trees; the references' quality (owner, 26 Nov 2026 late). THIS IS THE MAP JOB NOW.
> "Mappet skal være mindre som du kan se på mine reference screenshots jeg har vedhæftet, desuden er der alt for mange træer buske osv, og det ligner slet ikke samme kvalitet, sørg for det gør det."

**This replaces** the round 3 ideas below: the 10x size (`LabOwnerMap.S = 3.2`, `Config.LAB_SPREAD x 3.2`), the hidden ROOMS, the TREE BELTS and the room gates. The owner also takes back "the map size stays as it is now". Round 3's good parts stay where they fit: the paths rules, the lints, the signs, the yards, the spawn.

**The references** (the owner's own old map; open them and keep them open):
- `art/store/look_target/lab_ref/ref_6.webp` … `ref_10.webp`: the main views (from the tower top, north-west, north-east, east, west, straight down);
- `ref_1` … `ref_5`: extra angles (`ref_1` is the spawn plaza with the 4 leaderboards);
- `docs/LAB_TARGET.md` R3.1 (everything in it) and R3.2 (the 1:1 positions, in studs).

**What the references look like, and the map must look like this:**
- **Compact and open:**
  - every attraction sits close to its neighbours along wide light-grey tile walkways (about 12-14 studs wide, 6-stud tiles, thin joint lines);
  - from the tower top you see nearly the whole lab;
  - nothing is walled off.
- **Lots of clean, bright green flat grass** between things, with no clutter.
- **FEW trees,** in two simple clean kinds:
  - round broadleaf trees (a lumpy round canopy on a brown trunk);
  - slim conifers (stacked cones).

  They stand mostly in loose groups of 2-4 round the OUTER EDGE, plus a few single trees inside next to benches or between attractions. There are NO belts, NO hedges and almost no bushes.
- **Smooth rolling green hills** all round, close behind the edge, soft in the haze (Terrain, as in the shots). There is no dense forest wall.
- **Clean, simple, solid attractions:**
  - grey concrete and steel;
  - glass tanks with blue water;
  - the steel tower with its stairs and slide in the middle;
  - the cars on painted bays;
  - the boxing ring, the cave, the pools, the fan, the lava strip in its trench, the railway along the west edge.
- **Sparse props:** a few benches, red barrels, a bin. Lamps only along the main walkways, not many.
- **Soft daylight** with a little haze.

**The size:**
- **Use R3.2's layout and density, with its distances x 1.0-1.4** (the SMALLEST factor where every attraction fits with about 10-20 studs between neighbours; never more than 1.4). That is about 300-400 studs across inside the railway, instead of about 950 x 820 now.
- **The big set pieces go back to about their reference size:** the tower about 50-55 studs high (5 floors); the slide, fan, gyro cage, cave, tanks, T-rex and rocket to match.
- **The attractions added since the references** (the Machine Hall machines: tesla, gyro, press, washer, stretcher; the launch pads, the wrecking ball, the lounge pool, the spider pen, the garage, the car park, the entrance vehicle row F76) go into the free spots of the reference layout, in the same style, keeping the density.

**Build steps:**
1. **The plan:** rewrite the data in `tools/masterplan.py` to this compact layout:
   - keep its OUTPUT FORMAT (ROADS, INNER, PLAZAS, ITEMS in `Shared/OwnerMapPlan.luau`), so every system that reads it keeps working: watch spots, nav no-go areas, the path walkers' lanes, the vehicle pads, the bike route, events, the spawn;
   - drop the rooms, belts and gates from the data;
   - the walkways connect every attraction's front directly, as in the shots;
   - the lint must report 0; regenerate `OwnerMapPlan.luau` and `masterplan.png`.
2. **The scale:**
   - set `LabOwnerMap.S` (and `LAB_SPREAD`) to the chosen factor;
   - make `Shared/LabLayout10.luau` READ every position from `OwnerMapPlan` ITEMS instead of hard-coding them (`V(245, -48)`, `CARS`, `CREATURES`, `STRETCH`…), so the machines, creatures and vehicles always stand where the map puts them (this also stops bugs like F74 and F75).
3. **Remove:**
   - the tree belts and their 46 invisible belt walls (`Unstick`);
   - the room gates (`themedGate`) and the "IN HERE" boards;
   - the extra groves, boulder fields, hedges, bush rows and most flower beds;
   - the dense forest edge of the backdrop.

   Delete them; do not hide them (no see-through leftovers, F82).
4. **Trees and bushes:**
   - about 50-80 trees in all, in the two kinds above (pick the cleanest matching set in `V3Assets` or the Creator Store: simple, solid colours, low-poly like the shots; a malware pass);
   - mostly in loose edge groups, 6-10 single trees inside;
   - never on or within 4 studs of a walkway, never in front of an attraction, entrance or sign;
   - at most about 15 bushes (beside benches only); at most 6 flower beds.
5. **The backdrop:** smooth rolling Terrain hills close round the edge (as in the shots), the railway at the west edge, light haze.
6. **Everything that reads distances follows the smaller map** (a short code pass):
   - the streaming radius can go down;
   - the event areas (`EVENTS_NEWMAP.md`) and the bands in ALWAYS3 / DRAWN TO YOU stay as written (they still fit);
   - the PATH WALKERS keep their per-device numbers;
   - vehicle speed caps as before.
   - **Walk speed:** keep the owner's chosen numbers (NORMAL 30); put a question in NOW.md: "Gangfart: kortet er mindre nu; skal NORMAL ned fra 30 til ca. 22?" (default: keep 30).
7. **Performance:** far fewer parts (the belts alone were about 1,900 trees and bushes), so phones get faster.
8. **The DoD captures:** from the same 5 angles as `ref_6` … `ref_10` (the tower top and straight down), one capture each, no score. Then the lints: 0 things on walkways, 0 paths ending in grass, 0 old paving, 0 overlapping slabs or see-through parts (F82).

**Check (the owner):**
- from the tower top the lab looks like `ref_6` / `ref_7`: compact, open, clean, with the attractions close together;
- few trees, mostly round the edge; hills behind;
- the spawn plaza with the 4 leaderboards like `ref_1`.

---

# MAP ROUND 3: the master plan (owner, 26 Nov 2026: "Det her map er 1/10, sørg for det bliver 10/10")
> "Stierne connecter ikke med tingene ordentligt. Sørg for alle de stier er meget større og pænere, put flere træer ind og skift dem ud med de grimme træer vi har nu. Meningen er man ikke skal se alt på en gang så man får lyst til at gå ud og udforske. Gør så akvariet ikke står halvt inde i spawn. Fjern lygtepælen fra vandet og fra spawn."

**What went wrong.** The map was built as a straight grid with things dropped into big open plots.
- Walkways stop short of things, run past them, or sit on top of the old paving.
- From anywhere you see everything at once, so there is nothing to discover.
- The trees are balls on sticks.
- A lamp stands in the pool and another on the spawn.
- The aquarium cuts into the spawn plaza.

**The fix:** a real layout designed first, then built exactly. The layout is already done and checked:
- `tools/masterplan.py`: the one source; it lints itself;
- `ReplicatedStorage/.../Shared/OwnerMapPlan.luau`: the generated data the builder reads;
- `art/store/lab10/masterplan.png`: the top view.

Rebuild `Systems/LabOwnerMap` FROM `OwnerMapPlan`. Do not hand-place anything that the plan places.

## The idea: a park of ROOMS you explore
- **The spawn plaza** (raised, north, with the 4 boards, MAPS and a shop kiosk) looks straight down a wide **boulevard** past a fountain to the **Tower Square**. The 95-high tower is the landmark seen from everywhere.
- **8 themed ROOMS:** Animal Cove, Splash Zone, Crash Yard, Car Park, Machine Hall, Fun Fair, Launch Field and Danger Zone.
  - Each is **walled by a thick belt of trees and bushes** (18 studs).
  - You enter only through its **openings**, which have an arch sign with its pictogram.
  - Inside, a small paved **courtyard** leads by paths to the front of every attraction.
- **You never see everything at once:**
  - from the spawn you see the boulevard, the fountain, the tower, and only glimpses of tall things over the trees (the fan, the rocket gantry, the gyro rings);
  - the rest you discover by walking in.
- **Open, framed areas:** the Spawn Gardens, the Lawns and the Picnic Park are framed by low hedges along the roads (flower beds, benches, a few trees). The tall tree belts on their outer sides keep the rooms hidden.
- **The outer loop:** an avenue round the rooms (the cyclist rides it), then the railway (west, south and east) with a train and a station at the south end, the hangar, the water tower, the control tower, and the hills outside.

## The rules the builder MUST follow
1. **Positions:**
   - every room, road, plaza, inner path and item comes from `OwnerMapPlan` (lab-space studs; x east, z south);
   - `face` is the side the thing's front looks to;
   - the item's `size` is its footprint: place the thing inside it, centred, and let it fill it (scale set pieces up or down to fill it nicely).
2. **Roads and paths: big, clean, connected.**
   - **Widths:** the boulevard 36; the cross roads 26; the spurs into rooms 14; the inner paths 12; the avenues 16.
   - **Look:** large light-grey concrete slabs with thin dark joints (a texture, not tile parts), a low kerb on both edges, and a slightly raised surface. Round, paved junction plazas where roads meet.
   - **Every path ENDS AT something:** a plaza, a courtyard, or the front pad of an attraction. Extend the last leg of each inner path until its end meets the attraction's pad, with no gap and no overlap.
   - Where two inner paths run side by side, merge them into one.
   - **Remove ALL old walkways and paving** (the old grid, the brick-pattern paving, the stubs) under `LAB_OWNERMAP`.
3. **Nothing on paths, nothing in water, nothing on the spawn.** No lamp, tree, bench, prop, ragdoll spawn or rope may stand on a road, path, plaza centre, pool, pond, lava, sand or pad. A lint script raycasts every road, path and water surface and lists anything there; the list must be empty.
4. **Lamps:**
   - only along road and path edges, 2 studs outside the kerb, every 32 studs, alternating sides;
   - none within 8 studs of water, pads, plazas' centres or the spawn;
   - one style, a classic park lamp.
5. **Trees: new, good, many.**
   - Replace ALL the ball-on-a-stick trees and stacked-ball bushes with a good low-poly tree set from the Creator Store: 3-4 broadleaf species (oak, birch, maple), 2 pines, and 2-3 bush types. One matching style; malware pass on each.
   - Vary the size (±25 %) and turn them randomly.
   - **The tree belts:** 2-3 staggered rows of trees with bushes underneath, so you cannot see through at eye height. They are broken only at the room openings.
   - Also groves in the open areas, trees along the boulevard, and flower beds and hedges round the plazas.
   - Performance: meshes, CanCollide off for leaves, CastShadow only on the big ones near you.
5b. **The trees must NOT look all-green or AI-made** (owner, 26 Nov 2026: "Fiks træernes udseende, de er HELT grønne og ligner noget AI-lavet"). Today the trees and the backdrop forest are one flat green from top to bottom, with no trunks and no variation, like a green wall.
   - **Real trunks and branches:** brown-grey bark (a texture, not flat green), showing below the crown on every broadleaf tree and between pine skirts.
   - **Foliage with depth and colour variety:**
     - 3-5 different greens per area (dark pine green, olive, fresh spring green, a blue-green), with lighter tops and darker undersides (vertex colour or 2-tone meshes);
     - a few trees with yellow-green, and a rare autumn orange or red for accents;
     - a little gap in the crowns so light shows through.
   - **Shapes:**
     - mixed species and heights;
     - crowns that are not perfect spheres or cones;
     - some leaning, some young and thin, some old and wide;
     - bushes and ferns at their feet;
     - grass tufts and a few stones.
   - **Use a good tree set** (Creator Store, many favourites, one consistent stylised-realistic style, malware pass). Never code-built balls or cones.
   - **The forest backdrop:** the same set at a lower detail, layered rows with real trunks visible at the edge, not a green wall. Darker and bluer as it goes far (atmosphere).
   - **Check:** close-up captures of a tree, a belt and the forest edge, PC and phone. They must read as real trees with trunks and varied colour; harsh score 9.5+.
6. **Fill every room:**
   - each attraction stands on a pad that fits it, with its yard dressing (2 lamps at its path end, 1-2 benches facing it, a cluster of fitting props, its sign, its watchers);
   - each courtyard has a bench, a bin, a lamp and a signpost pointing to the room's attractions;
   - no empty grass bigger than about 40 x 40 inside a room.
7. **The aquarium** is in Animal Cove (plan), far from the spawn. The spawn plaza holds only the plan's spawn items.
8. **Height:**
   - the spawn plaza is raised 4 studs, with a wide stair down to the boulevard;
   - the rooms are gently raised or sunk (±1-2 studs) with small slopes at their openings, so the ground is not dead flat.
9. **Re-hook everything** to the new positions: every machine and its load spot, the creatures, the cars, the bike and cyclist loop (the avenues and roads), the doghouse, TRY and the first machine, the 3-near ragdolls, the watchers, the leaderboards, MAPS, the weapon range and the train.

## Check (part of the DEFINITION OF DONE)
1. Run `python3 tools/masterplan.py` after any plan change. It must say nothing but the two file paths.
2. **In Studio, the lint script must report 0 of each:**
   - things on paths, roads or water;
   - paths that end in the grass;
   - old paving left;
   - ball trees left.
3. **Captures:**
   - a top view next to `masterplan.png`;
   - the spawn view (you see the boulevard, the fountain and the tower; the rooms are hidden);
   - one view inside each room.
4. ~~**Harsh score:**~~ (26 Nov late: no self-score; the owner judges.) Build it clean, connected, explore-worthy, full and beautiful.

## The BACKDROP: hills and mountains that look made by hand (owner, 26 Nov 2026: "Fiks den basic baggrund af bjerge, uden at det ligner AI slop eller noget som er lavet på 2 sekunder")
**Today** (the owner's phone screenshot): a ring of identical smooth green blobs in a grey-green fog behind the plaza. It looks generated and cheap.

**The 10/10 backdrop: 3 layers, designed like a landscape painting.**
1. **NEAR (just outside the railway): a forest edge.**
   - A dense, uneven tree line of mixed pines and broadleaf trees (the same new tree set as the lab), with bushes, a few fallen logs and rocks.
   - It hides where the map ends.
   - Gaps here and there show the hills behind.
2. **MID (about 300-900 studs out): real rolling hills in Roblox SMOOTH TERRAIN** (not part spheres).
   - Sculpt them from a height field: layered noise (several octaves) plus a couple of hand-placed big shapes, so the silhouettes differ. No repeated bumps and no perfect ring.
   - **Materials by slope and height:** grass on gentle slopes, ground/mud on paths, rock on steep faces, a little leafy grass in the valleys.
   - **Details:**
     - tree clusters on the hills (cheap meshes, denser in the valleys);
     - a winding dirt road;
     - a small farm with a red barn and a windmill;
     - fences across a field;
     - a power-line row;
     - a few rock outcrops.

     These give it scale and make it feel lived-in.
   - **A valley gap** lines up with the boulevard's view south, so the tower stands against a deep view.
3. **FAR (the horizon): a mountain range.**
   - Low-poly mountain meshes (Creator Store, malware pass, one style) in 2-3 rows of different heights, with snowy peaks on the tallest.
   - Varied ridges: no two the same, never a uniform ring.

**Atmosphere and sky:**
- Tune the Atmosphere so the far mountains turn soft blue-grey (atmospheric perspective) while the lab and the near forest stay crisp and colourful. That means density low and the haze light, the colour a pale blue, and no flat grey-green fog over everything.
- Use a good skybox with soft clouds matching the sun's direction, and a gentle sun glare.
- On phones the far layer may be a single mesh band (cheap).

**Performance:**
- Terrain only for the mid hills, with a modest resolution.
- The trees on the hills are simple meshes with no collisions and no shadows.
- Mountains are a few big meshes.
- Check the phone FPS and memory.

**Check:** capture the view from the spawn, from the tower top, and from 2 room openings, on PC and on a phone. Nothing may look repeated or blobby. The layers must read clearly (forest, hills, mountains). Harsh score 9.5+.

**Also seen in the same screenshot: the 4 leaderboards show as plain black panels on the phone.** Check that the scrolling top-20 lists render on phones (SurfaceGui pixels per stud, LightInfluence 0, AlwaysOnTop false, MaxDistance).

## PATHS to 9/10+ (owner, 26 Nov 2026: "gulvet der går halvt ind i edderkoppens sted og stopper sådan der med 2 blocks til sidst alle steder … er smal og firkantet men alligevel ikke lige, den er 1/10 og skal minimum være 9/10")
**What is wrong (the owner's screenshot by the spider pen):**
- a walkway runs half into the spider's pen;
- path ends finish with 2 overlapping blocks (a stub plus a darker overlap square: two coplanar parts z-fighting);
- the paths are narrow, and their pieces do not line up (small steps and offsets);
- every branch was its own separate L-path, so pieces ran side by side and overlapped.

**The plan is regenerated** (`tools/masterplan.py`, `Shared/OwnerMapPlan`, `masterplan.png`):
- each room's inner paths are now ONE connected TREE: entrance → courtyard → trunks → branches, and the branches join the existing paths at T-junctions;
- nothing runs side by side;
- the inner paths are 16 wide (were 12), the spurs 18 (were 14);
- the routing keeps an extra 2 studs from every attraction;
- the courtyards sit further in.

**REBUILD all walkways from it with these rules (they are what makes it 9/10):**
1. **One piece per straight leg:** each straight leg between two nodes (corners, junctions, ends) is ONE part, exactly from node edge to node edge. Never two parts on top of each other.
2. **Corners and junctions:** each is ONE square pad (the path's width × width), and the legs stop exactly at its edges. No overlaps, so no z-fighting and no darker squares.
3. **No stubs:** a leg shorter than the path's width is dropped (its pad covers it).
4. **The end of each branch is a LANDING:** a pad 1.5× the path's width wide, 0.75× deep, that touches the attraction's BUILT front exactly.
   - Measure the built model's real bounding box in Studio, not the plan box. Trim or extend the last leg so the landing meets it with no gap and no overlap.
   - If the attraction has a fence (the spider pen, the T-rex pen, the croc pond, the dog yard), the landing meets a GATE opening in the fence at that spot.
5. **Never into an attraction:**
   - no path part may intersect any attraction's built bounding box (with 1 stud clearance);
   - if a built model is bigger than its plan box, write its real size back into `ITEMS` in `tools/masterplan.py`, re-run the script (it re-routes and re-lints), and rebuild from the new `OwnerMapPlan`.
6. **Straight and aligned:** every coordinate snapped to whole studs, every leg axis-aligned, all walkway tops at the same height (no steps between pieces).
7. **One surface look:** the same slab material and texture on every path part, the texture aligned in WORLD space (the same StudsPerTile and offsets from world zero), so the slab joints line up across all pieces and pads.
8. **Kerbs:** a continuous low kerb along both edges, broken only at junctions, landings and gates, with mitred corners (no gaps, no overlaps).
9. **The roads and spurs** meet the room paths and plazas the same way: a junction pad, no overlap.
10. **Lint (must be 0 each):**
    - path parts overlapping each other (XZ overlap over 0.1 stud);
    - path parts inside attraction bounds;
    - branch ends not touching their attraction or a gate;
    - legs shorter than the width;
    - misaligned tops (height difference over 0.05);
    - kerb gaps.
11. **Check:**
    - top-down capture next to `masterplan.png`;
    - close-ups of a corner, a T-junction, a landing at the spider pen and a gate;
    - harsh score 9+ on "clean, wide, straight, connected".
