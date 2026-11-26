# DETAIL PASS: every small thing from 2/10 to 10/10, lag-free (owner, 26 Nov 2026)
> "Blomsterbedene bugger og det er legit bare cirkler, fiks alt der er som det her, detaljer skal gå fra 2/10 til 10/10 lagfri endda."

**The owner's picture:** a flower bed is a flat grey slab with a few coloured BALLS on it (red, orange, purple), a brown wooden edge, and a flicker where surfaces overlap. That is the 2/10 level. Everything like it must go:
- code-built "props" made of balls, cylinders and blocks standing in for flowers, bushes, rocks, trees, food, signs and so on;
- surfaces that flicker (z-fighting);
- things floating or sunk;
- big flat untextured areas.

Behind `Config.DETAILS_10 = true` (false = today).

## 1. Find them all first (an audit script, `tools/DetailAudit.luau`, run in Studio)
It prints, per area (from `OwnerMapPlan` rooms), and writes the counts into this doc's State:
1. **Primitive props:** every Part with Shape Ball or Cylinder, and every small Block, that is decoration (not a machine's working part), grouped by what it pretends to be (look at its name, folder and colour: "Flower", "Bush", "Rock", "Food", "Lamp"…).
2. **Z-fighting:** pairs of parts with coplanar, overlapping faces within 0.02 studs, which is the flicker ("bugger").
3. **Floating or sunk:** decoration whose bottom is more than 0.2 studs above the ground, or more than 30 % sunk into it.
4. **Overlaps:** decoration intersecting another object, a path or water.
5. **Big plain surfaces:** large parts with no texture, decal or material detail (SmoothPlastic grey slabs).

Fix every hit. The audit must end at **0 primitive props, 0 z-fight pairs, 0 floating, 0 overlaps**.

## 2. The 10/10 look per kind of detail
Use ONE consistent stylised-realistic asset style from the Creator Store: sets with many favourites, a malware pass on each, the scripts removed. Every repeated thing shares one mesh and one material, so the engine instances it.
- **Flower beds:**
  - a raised bed with a proper edge (stacked stone or timber sleepers with grain and end caps);
  - dark, slightly lumpy soil (a soil material or texture), not grey;
  - real flower meshes with stems and leaves (tulips, daisies, lavender, roses, marigolds), planted in drifts of one colour (5-12 together), with taller ones at the back and low ones at the edge;
  - a few leafy plants and grass tufts between them;
  - variation in height and turn;
  - shapes: round, long or L-shaped beds that fit their place.
- **Bushes and hedges:** leafy meshes with depth and 2-3 greens (no spheres). Clipped hedges have a slight leaf texture and uneven tops; wild bushes have flowers or berries now and then.
- **Rocks and boulders:** sculpted rock meshes in 3-4 shapes, half sunk into the ground, with grass tufts at their base and moss on top on some.
- **Trees:** `MAP_MASTERPLAN.md` rule 5b.
- **Benches:** wooden slats on cast-iron legs, a little wear.
- **Picnic tables:** proper tables with a cloth on some, plates and a basket.
- **Bins:** with lids and a bin bag.
- **Lamps:** a classic park lamp with a glass head and a soft warm light only at night or dusk (no light parts by day for performance).
- **Signs:** a framed board on posts with the pictogram; slightly weathered.
- **Fences:** posts and rails or pickets as meshes (no long thin parts); gates with hinges.
- **Food, kiosk and grill:** real meshes (sausages, buns, a sign with a menu picture). A sun umbrella at the kiosk.
- **Cars in the car park:** real car meshes, the same quality as the drivable ones (no block cars).
- **Pool loungers and umbrellas:** real meshes in 2 colours.
- **The playground:** a real slide, swings with chains, a roundabout (meshes).
- **The grandstand seats:** real seat rows (meshes), not blocks.
- **Railway:** a rail track mesh (rails and sleepers together), ballast stones as a texture strip.
- **Ground detail:**
  - soft transitions where paths meet grass (a thin worn-grass decal strip);
  - dirt patches under benches;
  - leaves under trees;
  - a few puddles after the "rain" surprise (optional);
  - cracks and drain covers on the plazas.
- **Small life:** birds landing and flying off; butterflies near the flower beds; ducks on the pond. All client-side, near you only.

## 2b. EVERY code-built structure: the MODEL AUDIT (owner, 26 Nov 2026: "Fiks alle AI slop-modeller som denne")
**The owner's picture:**
- the snack kiosk is a plain box with a stretched plank texture;
- a flat red plank floats along its top edge as a "roof";
- three plain blue boxes stand in for portable toilets;
- the only decent part is the framed "SNACKS" sign.

That is "AI slop": a few boxes or cylinders with flat colours or a stretched texture, no shape, no details, no bevels, no purpose you can read.

**The rule:** any object that a player would call "a box pretending to be something" is replaced.

**1. Make the list.** A script lists every MODEL in the lab built by our code (LabOwnerMap, LabV10, WorldDress, etc.) with its part count and part types, and writes it in State. Judge each one as:
- **KEEP:** it already looks like the real thing, e.g. the steel tower or the framed signs.
- **REPLACE:** use a Creator Store model in the game's style (many favourites, one consistent stylised-realistic style, malware pass, scripts removed).
- **REBUILD:** a detailed custom build: real shapes, bevels, trims, parts that do something, textures that fit (not stretched), plus 3-6 small details that tell what it is.

**2. Everything on this list MUST be judged** (from map rounds 2 and 3):

| Area | Models |
|---|---|
| Food and toilets | the snack kiosk, the portable toilets, the grill and the picnic tables |
| Pools and play | the loungers and umbrellas, the playground (slide, swings, roundabout), the training yard (tyres, hurdles, climbing wall) |
| Buildings and towers | the garage, the hangar, the water tower, the control tower, the station platform and the train |
| The car park | the cars (no block cars) |
| Animal Cove and Splash Zone | the cave (2 big rounded rocks today), the aquarium, the pool, the fenced pens, the sandcastle tower |
| Machines and Danger Zone | the shredder pit, the sweeper, the rocket pad and gantry, the concrete slab, the T-rex pen, the crocodile pond, the speaker wall |
| Small props | the crates, barrels, benches, bins and bike racks |
| Every other prop | from any earlier round |

**3. Targets for the worst ones:**
- **The snack kiosk:** a real kiosk or food-truck model with a serving window, a striped awning or pitched roof (attached, not floating), a counter with napkins and ketchup bottles, a menu board with food pictures, a drinks fridge, 2-3 stools, a small queue of ragdolls sometimes, and a sun umbrella table next to it.
- **The portable toilets:** real portaloo models (a moulded plastic shell, a door with a vacancy slider, a roof vent, a step). Our own colours, no real brand. A door that opens when a ragdoll goes in, a "flush" sound and a ragdoll walking out (fun).
- **The cave:** a sculpted rock formation (a cave mesh or terrain rock) with depth, a real dark mouth (F36), roots, moss and boulders, not 2 balls.
- **Buildings** (garage, hangar, towers, station): real building models, or detailed builds with doors, windows, roofs with edges, signs, pipes and lights.

**4. Every replacement:**
- stands on its plan spot with the 3-stud clearance (F44);
- uses shared meshes and materials (instancing);
- fits the part budget;
- matches the one style.

**5. Check:**
- after each area, capture close-ups and medium views on PC and phone;
- harsh score "would a player call this a box?" Every model must be 9+;
- re-run the list: 0 models left marked REPLACE or REBUILD.

## 3. Lag-free rules (all devices)
- **Meshes:** shared meshes and materials (instancing); RenderFidelity Automatic; CollisionFidelity Box or Hull; CanCollide off on small decoration; CanQuery and CanTouch off where not needed.
- **Shadows:** CastShadow only on big things near you.
- **Far away:**
  - flowers, tufts and small props only within about 120 studs (StreamingEnabled plus a client LOD: beyond that a bed is its soil plus a colour decal);
  - birds and butterflies only within 60 studs.
- **No new lights by day.** Lamp lights are on only at dusk or night, and only the nearest 8.
- **Parts:** one area at most about 1,500 decoration parts; the whole lab stays inside the `PERF_MOBILE.md` budget.
- **Measure** the FPS on the phone emulator in the busiest area before and after. It must be the same or better.

## 4. Check
- The audit says 0 of each.
- Close-up captures of a flower bed, a hedge, a rock group, a bench corner, the kiosk and the car park, plus a medium view of each room; PC and phone.
- Harsh score 9.5+ per kind. Nothing may look code-built.

## State
- (none yet)
