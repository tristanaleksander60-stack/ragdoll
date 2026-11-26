# LAB 10/10: the whole lab rebuilt (owner, 26 Nov 2026)

> "Den har nu lavet alt. Tag et skridt tilbage og kig på hele mappet med nye øjne. Hele labbet skal tages fra 2/10 til 10/10, ikke vær bange for at ændre ALT"

The owner's screenshot (PC, 0.53.0, high camera over the lab) is the "before".

**Rules for the run:**
- One run, built behind `Config.LAB_V10 = true`. `false` brings back today's lab (LAYOUT_V3). Hide, do not delete.
- Every machine, creature, terminal, product and remote keeps working. Only where things stand and how they look changes.
- Phone first (most players): every decision is checked at phone size.
- Same process as NOW.md's "one run": build everything, one quick Play per step, publish ONCE at the end, then ONE combined Danish "Test selv" list.

## 1. What is wrong (fresh eyes, honest)

| # | Problem | What the screenshot shows |
|---|---|---|
| 1 | **No theme** | It is called a lab but looks like a park with toys dropped on grass. Nothing says "ragdoll test lab". |
| 2 | **No layout** | Machines stand at random angles and distances. There is no centre, no paths, no zones, and no reason to walk from A to B. |
| 3 | **Clutter** | Benches facing nowhere, barrels, cones, crates, rocks, the hazard-stripe blocks and tiny signs are scattered everywhere. It reads as a junkyard. |
| 4 | **Empty and too big** | Large plain grass gaps; the attractions are small inside a huge field. On a phone, each one is a few pixels. |
| 5 | **Flat, washed-out light** | Green-grey fog over everything, no shadows that read, no colour. It looks like a rainy test place. |
| 6 | **The centre is a plain white disc** | The spawn, where every new player starts, is the most boring spot in the lab. |
| 7 | **Random leftovers** | The red square with a palm tree, the three chunky ring pads (blue, purple, red) with a yellow strip to a grey slab, the light-blue lines along the edge, floating boards, stairs with floating yellow steps beside a slide. |
| 8 | **No skyline or edge** | A thin fence on one side and blue lines; the world just fades into fog. |
| 9 | **No hierarchy** | Everything is the same size and importance. Nothing big, tall and clear says "go here first". |

## 2. The idea: CRASH TEST LAB

The dummies are grey test dummies, so the lab becomes a bright, cartoon **crash-test facility**: a compound with a concrete test floor, hazard stripes, test towers, a launch range, a crash track and a creature wing. It fits the name (Ragdoll Anatomy), the grey dummies and the toy guns, and it is the clearest theme a 9-14 year old gets in one second.

**Look (one style, everywhere):**
- **Palette, max 6 colours:**
  - warm light concrete (230,226,216) for the floors;
  - safety yellow (255,200,40) with black (30,30,34) for hazard trims;
  - signal orange (255,120,40) for the things you use;
  - lab white (245,245,245) with teal glass (60,190,200) for buildings;
  - grass green only outside the wall;
  - purple only for the blood.
- **Chunky, rounded, toy-like shapes** (bevels, big rivets, thick outlines), never thin parts. Readable at phone size.
- **Signs are pictograms** (ICON_SIGNS) on big boards fixed to buildings, never floating.
- **Light:** sunny afternoon.
  - Lighting: ShadowMap, a warm sun at about 40°, Brightness about 2.5, OutdoorAmbient raised.
  - Atmosphere: Density ≤ 0.25, Haze 0 (no fog wall).
  - ColorCorrection: Saturation +0.15, Contrast +0.05. Soft Bloom. A bright sky with clouds.
  - The same on phones (no grey fog).

## 3. The layout (top view)

The spawn is in the south, facing north. Everything sits within about **60 studs** of the test-floor centre: smaller and denser than today, so a phone shows the whole lab from the spawn.

```
                 [ CREATURE WING ]     [ DROP TOWER ]      [ SMASH YARD ]
                  spider · plant        hero landmark       wrecking ball
                  shark tank            lab name on top     boxing ring
                  (feeding terminals)   leaderboard screens compressor · vacuum
                          \                  |                  /
   [ LAUNCH RANGE ]  ----  (  TEST FLOOR: dummies + BIG RED BUTTON  )  ----  [ CRASH TRACK ]
   cannon · slingshot          the centre, 8-15 studs                      ramp · crash wall
   rocket pad → landing        in front of the spawn                       cars + tank in bays
   field with distance marks        |
                          /         |          \
          [ TRAVEL GATE ]      [ SPAWN PAD ]       [ SHOP ROW ]
          one portal arch      facing north        booths with awnings,
          + MAPS board                             3D items, VIP door
```

**The zones:**
- **Spawn pad** (south): a raised start pad. A new player sees the test floor and its dummies straight ahead, the drop tower behind it, and three more landmarks left and right. They are never facing a wall or grass.
- **Test floor** (centre, the heart):
  - a round concrete floor with painted rings, ringed by 6-8 grey dummies on test stands (with crash-test target marks on them);
  - the BIG RED BUTTON on a console at its north edge.
  - Shooting starts within 3 seconds of spawning.
- **Drop tower** (north, the hero landmark, the tallest thing):
  - today's stairs, slide and jump platforms merged into one designed tower (a scaffold with a hazard-striped top);
  - a big "<NAME>'S LAB" sign on top;
  - the leaderboards as screens on its base.
  - It is the thing you see from everywhere.
- **Launch range** (west): the cannon, slingshot and rocket pad in a row on one launch line. They shoot over a long landing field with distance boards (10, 25, 50, 100) to a catch net. No bullseye (owner, 21 Nov).
- **Crash track** (east): a short straight with a ramp and a padded crash wall. The cars and tank park in painted bays at its start, never scattered.
- **Creature wing** (north-west): the spider web, the giant plant and a real shark tank (glass, water), each in its own enclosure with its feeding terminal in front.
- **Smash yard** (north-east): the wrecking ball, the boxing ring, the Compressor and the vacuum, each on its own hazard-trimmed pad.
- **Travel gate** (south-west):
  - one big portal arch with the MAPS board built into it, replacing the three ring pads and the separate portals;
  - on a phone, walking up opens MAPS (as now).
- **Shop row** (south-east):
  - a short row of booths with awnings, showing the real items in 3D (the best sellers first, NOW item 8);
  - the VIP door at its end;
  - close to the spawn, but out of the first view's centre.
- **Paths:**
  - wide painted concrete walkways with yellow edge lines, hub and spoke from the test floor to every zone;
  - drawn with textures and decals, not stacked parts (no flicker, no grey strips);
  - every path ends at a zone.
- **Edge:**
  - a compound wall (concrete and yellow-black hazard trim) with gates;
  - outside it, a skyline of hangars, a test-track tower, a water tower and hills with trees;
  - grass and trees only outside.
  - The blue edge lines go.
- **Benches and props:**
  - only where they belong: a few benches at the test floor facing it, crates stacked at the launch range, cones on the crash track;
  - nothing scattered on grass.
- **Remove (hide behind the switch):**
  - every scattered bench, barrel, cone, crate, rock and hazard block;
  - the red square with the palm tree;
  - the light-blue edge lines;
  - floating boards;
  - the plain white disc;
  - lamps on open grass.
  - If any of these carries a function, that function moves into its zone.

## 4. How to build it (order)

1. **Inventory.**
   - Script-list every part and model in one player's lab (Lab, LabDress, LabZones, LabGarden, Landscape, PathBuilder, LabCreatures, Playground…). For each: what it is, its function (if any), and its zone in the new plan, or "remove".
   - Save the list as `docs/LAB10_INVENTORY.md`.
   - Take the 4 "before" captures (below).
2. **Light and sky** first: fastest, biggest change.
3. **Floor, walls, paths, edge and skyline:** the frame.
4. **Test floor and spawn pad:** the first 10 seconds.
5. **Drop tower** (the hero), then **launch range**, **crash track**, **creature wing**, **smash yard**, **travel gate**, **shop row**.
6. **Clean-up pass:** nothing floating, nothing clipping, nothing scattered; every sign readable on a phone.
7. **Phone pass and performance:**
   - the same or fewer parts than today's lab (each player has their own lab), with meshes and packages over many small parts;
   - StreamingEnabled-safe;
   - 60 fps in the lab on a mid phone in the Studio emulator.
8. **Captures and score:**
   - Take the 4 "after" captures and score them against the bar below.
   - Anything under 9: fix it and capture again, at most 3 rounds.
   - Then publish.

**The 4 fixed captures** (before and after, saved to `art/store/lab10/`):
- the spawn view on a phone (iPhone landscape);
- the spawn view on PC;
- a high view over the whole lab, the owner's angle;
- a top-down view.

**Use Creator Store models** where they beat code-built parts: fences, hangars, scaffolds, shark tank glass, trees, hazard barriers. Malware pass on every insert. One style only.

## 5. The 10/10 bar

Each point scores 0-10 on the captures; all must be 9+.

1. **3-second read:** from the spawn on a phone, you see dummies to shoot, the red button and at least 3 landmarks, and you know what to do.
2. **Theme:** a stranger says "a crash-test lab" from one screenshot.
3. **Layout:** clear zones, every path leads somewhere, nothing more than about 15 seconds' walk from the test floor.
4. **Clean:** zero scattered props, zero floating things, zero grey strips or blue lines, zero clipping.
5. **Light and colour:** bright, warm, contrasty, no fog wall; the palette above only.
6. **Landmarks:** each zone has a unique silhouette visible from the spawn; the drop tower is the hero.
7. **Phone:** every sign and landmark readable at phone size; the shoulder camera never clips into props.
8. **Performance:** part count at or under today's; no FPS drop on phones.
9. **Fun pull:** each zone has one obvious thing to do right at its front (a dummy, a button, a seat, a terminal).
10. **Screenshot-worthy:** the high view would work as a store thumbnail background.

## 6. After publishing
- **Watch the 5-minute and 10-minute funnels** (phone split) for 2 days against 0.53.0.
- **If they drop, flip `LAB_V10 = false`** and publish. That rolls the lab back, never the servers.

## State (26 Nov 2026, release 0.54.0, place saved v1111, NOT published yet: the owner presses Alt+P)
**Built** (one run, Script Sync was off: every script went in through the MCP, checked by length):
- `Config.LAB_V10 = true`. `Shared/LabLayout10` holds every spot; the builders read it (LabCreatures, VehicleService, Playground lava/boxing, LabDress, MapShopService trampoline, BenchService, PathPlan row/button/stretch).
- `Systems/LabV10` (last in Playground.build) adds:
  - the floor in concrete (it was see-through over the grass);
  - a test floor (yellow rim, rings, target) with the dummies on it 26 studs ahead of the spawn, and the BIG RED BUTTON at its north edge;
  - an orange spawn pad with an arrow;
  - walkways with yellow lines;
  - the compound wall with a hazard cap and orange gate posts (S, W, E);
  - two teal hangars, a control tower and a water tower outside;
  - the tower re-coloured white/yellow/black and the crash wall in orange.
- **Hidden:** the garden strips, the old paths, scattered barrels, crates, cones, rocks, lamps, fence and bench props, the white spawn disc, the blue edge lines, and landscape trees inside the wall.
- **Moved:**
  - spider web behind the test floor (0,-86); shark tank, frog and plant north; chicken, stretch machine and boxing ring east (smash yard);
  - slingshot, mole, washer and compressor south-west;
  - cars in bays in front of the crash wall; trampoline behind the spawn; weapon range outside the south gate.
- **Kept where they were:** portal and MAPS board (they face the spawn; moving them without a turn would face them away), the drop tower set, cannon, wrecking ball, crash pads, rocket and mech arms.
- **Light** (`ZoneLighting` SUNNY): sun at 15:20, Brightness 2.2, haze 0, density 0.25, saturation +0.15, contrast +0.05, clouds with the sun disc. `LAB_V10 = false` brings back the overcast look.
- **Parts in one lab:** 4,127 → 2,936.
- **Captures:** `art/store/lab10/`:
  - before: `before_high.jpg`, `before_spawn_phone.jpg`;
  - after: `after_high.jpg`, `after_top.jpg`, `after_spawn_phone.jpg`.
  - A PC spawn shot is still missing; the Studio capture ran in the phone emulator.

**Honest score after round 1 (bar: 9 on each):**
- 3-second read: 7
- theme: 7
- layout: 7
- clean: 8
- light: 8
- landmarks: 6
- phone: 6
- performance: 9
- fun pull: 7
- screenshot: 6

**Left for round 2 (next /klar):**
- zone pictogram signs on boards;
- the drop tower as hero (a hazard crown and the lab-name sign on top);
- one travel-gate arch round the portal + MAPS board (turned to face the spawn);
- launch range distance boards and a catch net;
- a crash-track ramp;
- the shop row with booths;
- the black leaderboard slabs dressed as screens on a frame;
- a PC capture.

## ROUND 2: from 3/10 to 10/10 (owner, 26 Nov 2026)
> "Er du tilfreds med dette resultat? Jeg vurder overall til 3/10, du må gerne udskifte maskiner, tilføje animation som gør folk ikke kan vente med at prøve den næste, og er alt opstillet med det abselut bedste design på alle parametre?"

**Round 1 self-score (7s) was far too kind; the owner says 3/10.** From now on, score like a harsh critic. Put each capture side by side with `art/store/look_target/leader_hub.webp` and the top ragdoll games. When in doubt, score lower. A zone is not done until its capture passes the zone checklist (section R5).

### R1 Why it is 3/10 (the owner's screenshot of round 1)
- **A blank white parking lot.** Most of the screen is empty, bright white floor. Tidy, but sterile; nothing to look at, no depth, no texture, no shadows that read.
- **Attractions are still small and scattered on the slab.** They are not set pieces:
  - a big tree blob in the middle-left;
  - a black cube;
  - a grey box;
  - a brown dirt square with a dashed ring;
  - a trampoline in the middle of a walkway;
  - a slingshot frame standing alone;
  - the three ring pads with the yellow strip, still there;
  - big orange wedges at the corners.
- **Vehicles parked diagonally** across the yard, not in bays.
- **The test floor is a small grey helipad** with tiny dummies. The heart of the lab is the weakest thing in it.
- **The drop tower is the same stairs, slide and floating yellow steps,** recoloured. It is not a hero.
- **Nothing moves.** There is no action to see from the spawn, so there is no pull to walk anywhere.
- **The lab sign is cut off** ("INGSTUDIOS' LAB").
- **Outside is still flat empty grass.**

### R2 The big changes
1. **Denser and smaller.**
   - Shrink the compound by about 40 %, or grow every attraction about 2x; no stretch of empty floor wider than about 20 studs.
   - The phone view from the spawn is full of things happening.
2. **A floor with life.**
   - No plain white:
     - a warm mid-grey concrete texture;
     - each zone on its own coloured pad;
     - painted markings and decals (arrows, numbers, skid marks, hazard corners).
   - **Height changes:**
     - raised platforms with steps;
     - a sunken crash pit;
     - ramps.
3. **Every zone is a set piece:**
   - its own frame (a gantry, a fence or a glass wall);
   - its own floor colour;
   - one big pictogram arch sign;
   - an accent light;
   - its own sound.
   - **No lone props.**
4. **ATTRACT MODE (the main new thing): every machine shows off by itself.**
   - When no player is using it, each machine plays a short demo with a demo dummy every 8-15 s:
     - the cannon fires a dummy into a catch net;
     - the wrecking ball smacks one;
     - the press squashes one (flat-cartoon pop, then it springs back);
     - a car hits the crash wall;
     - the rocket lifts off with a dummy;
     - the spider wraps one;
     - the shark jumps;
     - the bowling pins fly.
   - **The timing is staggered,** so something happens on screen every 2-3 seconds from anywhere in the lab.
   - **It runs on the client,** only within about 120 studs, and stops when a player uses the machine. Within the phone budget (`Config.ATTRACT_MODE`).
   - **"Try me" pull:**
     - the nearest machine you have NOT tried gets a pulsing glow ring and a bobbing "TRY!" hand;
     - after you try it, the next untried machine starts pulsing;
     - the goal pill says "Next: try the CANNON!".
   - **First try of each machine:** a small reward pop (a few BOLTS, "NEW!" sticker).
5. **Replace the weak machines** (each behind a switch; hide the old, do not delete):

   | Today | Becomes |
   |---|---|
   | trampoline (a flat net) | **BOUNCE TOWER**: a giant inflatable that launches you high |
   | slingshot frame | **GIANT CATAPULT** on the launch range |
   | black cube | **HYDRAULIC PRESS** with glass sides and warning lights |
   | grey box | **SPIN CYCLE**: a giant washing machine with a round window, the dummy tumbling inside |
   | three ring pads + yellow strip | removed; their job moves to the travel gate |
   | tree blob, dirt square, dashed ring, orange corner wedges | removed |

   **New** (max 3 this round, cartoon tone, no gore):
   - **DUMMY BOWLING:** a lane with 10 dummies as pins; roll a big ball; STRIKE banner.
   - **PINBALL PIT:** a sunken pit with bumpers and flippers; drop a dummy in and watch it bounce with points.
   - **ROCKET SLED:** rails that end in a padded wall.
6. **The drop tower becomes the hero.**
   - One designed tower, about 2x taller, with a lift that carries you up and a top deck with a PUSH plank.
   - An airbag or splash pool below, with a height/score board.
   - The lab-name sign on top, sized to fit any name (never cut).
7. **Vehicles:** straight in painted bays. The crash track gets a ramp and a crash wall in line with the bays.
8. **Paths:** one loop "tour" from the spawn past every zone in fun order, with floor arrows. The test floor in the middle.
9. **Life everywhere:**
   - a **DUMMY FACTORY**: a dispenser with a conveyor that brings fresh dummies to the test floor (it explains where dummies come from);
   - flashing beacons;
   - a crane moving a dummy;
   - steam puffs;
   - flags;
   - ambient sound per zone.
10. **The test floor is the heart:**
    - a bigger round arena (raised, hazard rim, big painted target);
    - dummies on test stands around it, life-size, not tiny;
    - the BIG RED BUTTON on a big console with a glass cover.
11. **Outside:** the lab sits in a landscape, not on flat grass:
    - a test track running round it;
    - hills and hangars;
    - a road with a gate;
    - trees in groups.
12. **Light:** less glare from the floor, shadows that read, warm sun. The palette from section 2.

### R3 Order
1. Concept first.
   - Draw a top-down plan image from code (coloured zone blocks with names), at `art/store/lab10/plan_r2.png`, and check the density.
   - Then build zone by zone in this order: test floor + factory, drop tower, attract mode + "try me", the replaced machines, the new 3, the frame and outside, light.
2. Commit after each zone.

### R4 Performance
- **Parts:** a lab must stay at or under 3,500 parts; use meshes and packages.
- **Attract-mode demos:** one demo dummy per machine, reused and client-side; max 3 demos animating at once on a phone.

### R5 Zone checklist (each must pass in its capture)
- readable as what it is from the spawn on a phone;
- shows a demo at least every 15 s;
- has a frame, a floor pad, a sign, a light;
- no empty floor > 20 studs;
- nothing floating or clipping;
- one obvious thing to do at its front.

### R6 Done
- The 4 captures, plus a short video (Studio recording, 20 s from the spawn).
- Harsh score: all 9+.
- Then publish once, with ONE Danish "Test selv" list.
