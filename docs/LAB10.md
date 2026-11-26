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
