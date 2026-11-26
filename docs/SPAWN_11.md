# The SPAWN to 11/10, and room entrances that make you curious (owner, 26 Nov 2026)
> "Lav meget federe bannere til de forskellige ting så man faktisk bliver nysgerrig og tænker wow, det er en godt udviklet server. Det er noget af det første man ser, det der er i spawn, så spawn skal tages fra 2/10 til 11/10."

**The owner's picture:** the Animal Cove sign is a flat dark-green strip with yellow text. Cheap and forgettable. The spawn is the first 5 seconds of every visit; it decides whether people stay.

Behind `Config.SPAWN_11 = true`. Use the same asset style as `DETAILS_10.md` (Creator Store, many favourites, malware pass, instanced meshes). No neon (owner rule): use lit bulbs and marquee lights with a soft glow, light parts only near the player.

## 1. The spawn plaza: a "wow, this is a real game" first look
**The view.** You spawn at the front edge of the raised plaza, facing south. Through a big **WELCOME ARCH** you look down the grand stair and the boulevard to the fountain and the steel tower.
- The arch frames the tower like a postcard.
- The sun lights the scene from behind you.

**The WELCOME ARCH** (the hero of the spawn):
- two stone-and-steel pillars, with a steel truss across the top;
- big 3D letters on top: "RAGDOLL ANATOMY" (thick extruded letters, a white face, a dark edge and a bone icon), with a row of warm marquee bulbs round the letters that chase slowly;
- banner flags on the pillars, waving.

**The 4 LEADERBOARDS** (facing the spawn, OVERVIEW 0.6):
- in a proper frame: a dark granite base, steel posts, a small roof with lights, and the board's name in 3D letters on top ("MOST KOs", "MOST TIME"…);
- **#1 STATUES:** in front of each board, a gold statue of that board's current #1 player's avatar on a plinth with their name. It updates when #1 changes; built from the player's HumanoidDescription, gold material, posed. A famous Roblox hook: players want their own statue.

**The plaza itself:**
- **The floor:** patterned stone paving with a big inlaid compass rose in 2 stone colours, and the game's bone logo in the middle. No plain slab.
- **Water:** 2 small fountains flank the top of the stair (water jets, the sound of water).
- **Planting:** 4 flagpoles with flags; flower beds and planters (`DETAILS_10.md` quality); classic lamp posts at the corners.
- **A WAYFINDING SIGNPOST** at the stair top: a tall post with arrow boards to every room (each arrow with its room's pictogram, colour and distance, e.g. "ANIMAL COVE 210 →").
  - It makes you want to go.
  - On phones it is readable from the spawn.
- **The MAPS board** in a matching frame.
- **Life:** the 3 standing ragdolls (2 chatting, 1 coming to you); birds landing on the arch; butterflies by the flowers.
- **The stair:** wide, with stone balustrades and two big stone ragdoll statues in funny poses at its foot. Nice to pose with.
- **Sound** (no music): birds, the fountains, and the distant hum and booms of machines that tease what is out there.

**A first-join moment** (once ever, skippable by any tap or key; never on rejoin):
1. A 2.5 s camera glide from high above the arch down to behind the player while the title letters' bulbs light up one by one.
2. Then control.
3. Nothing else pops up.

**Performance:**
- the spawn loads first (streaming priority);
- the decoration is instanced meshes;
- lights only on the arch and near the player;
- statues are built once per server.

**The 11/10 bar:**
- capture the spawn view on PC and phone;
- put it beside the spawn screenshots of the top Roblox hubs (the leaders' hubs in `art/store/look_target/`);
- it must look at least as good; harsh score.

## 2. Room ENTRANCES that make you curious (replace every flat banner)
Every room opening (`OwnerMapPlan` entrances) gets a **themed gate**, a small set piece with 3D letters, its pictogram, lights, and something MOVING that teases what is inside. You can see the moving part from the road, so you want to go in.

| Room | Gate |
|---|---|
| **Animal Cove** | A big timber jungle gate with rope bindings and hanging vines; carved animal heads (bear, croc, T-rex) on the posts. 3D wooden letters. The croc head's jaw snaps open and shut slowly. Jungle sounds from inside. |
| **Splash Zone** | A wave-shaped arch in blue tiles; water jets arc over the entrance from both sides; 3D letters with water drips; lifebuoys on the posts. |
| **Crash Yard** | An arch made of two crashed cars stacked on tyre piles, with hazard stripes; a 3D sign made of crumpled metal letters; flashing amber beacons; the occasional crunch sound from inside. |
| **Car Park** | A road-sign gantry (a blue sign "CAR PARK P") with a barrier arm that lifts when you walk through. |
| **Machine Hall** | A steel gantry with big gears turning, pistons pumping and a steam puff now and then; riveted 3D letters; bulb lights. |
| **Fun Fair** | A carnival arch with chasing marquee bulbs, striped canvas, balloons bobbing and colourful 3D letters. |
| **Launch Field** | A gantry with a rocket nose cone on top and a countdown display that ticks down from 10 and "launches" a puff of smoke every 30 s; 3D letters. |
| **Danger Zone** | A heavy hazard gate in yellow and black, with warning lights spinning, cartoon flame jets on top (a burst every 10 s), skull-free warning pictograms (a ragdoll flying) and a "DANGER ZONE" plate. |
| **Picnic Park** | A flower arch (an arbour with climbing roses) and a wooden sign. |
| **Racetrack** | A chequered-flag gantry with the start lights and "RAGDOLL RING". |

- **The letters** are big enough to read from the road on a phone.
- **Inside each gate,** a small board lists the room's attractions with pictograms.
- **Performance:**
  - the moving parts animate only within about 120 studs;
  - effects are pooled;
  - one gate is at most about 120 parts or meshes.

## 3. Check
- **Capture:** the spawn view, then each gate from its road, on PC and phone.
- **Harsh score** on: wow, readable, curious, fits its room, lag-free. Each must be 9.5+, and the spawn 10+ (the "11/10" bar: better than the competition's hub next to it).
