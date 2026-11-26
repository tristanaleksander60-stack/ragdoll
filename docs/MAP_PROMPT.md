# Prompt for a new Claude chat: build the lab MAP only

**Til ejeren (dansk):**
1. Åbn en **ny** Claude Code-chat på pc'en, med Roblox Studio og Studio MCP tændt.
2. Kopiér alt under stregen og send det.
3. Den bygger kun selve mappet i en **ny, tom place**. Den rører ikke spillet.
4. Når den er færdig, pusher den filen til branchen `labmap`, eller du sender mig `LabMap.rbxmx`.
5. Så kobler jeg alle maskiner, dummies, knapper osv. på mappet.

---

You are building ONE thing: the environment map for the player lab of a Roblox ragdoll game ("Ragdoll Anatomy"). Another session will connect all the gameplay to it afterwards. Talk to me in **Danish, short and plain**.

## Hard rules
- **A new, empty place.** In Roblox Studio make a new Baseplate place and save it as `LabMap_Build.rbxl`. NEVER open or change the live game place (placeId 126037745825106). Never publish anything.
- **Environment only.**
  - Build: floor, walls, buildings, decoration, landscape, and walkable geometry (stairs, ramps, platforms, the tower).
  - Do NOT build: machines, weapons, creatures, cars, dummies, UI.
  - **NO scripts of any kind** in the model (Script, LocalScript, ModuleScript). Delete every script that comes with a Creator Store model, and check every insert for hidden scripts and odd objects (malware pass). The final model must contain zero scripts.
- **One Model named `LabMap`** in Workspace:
  - every part Anchored;
  - `PrimaryPart` = the anchor `Spawn` (below), placed at (0, 0, 0);
  - "Ahead / north" = **-Z**, so the player spawns at the origin looking toward -Z.
- **Budget** (each player gets their own copy of this map, so this matters):
  - at most **2,500 parts** (MeshParts count as parts);
  - prefer a few good meshes over many small parts;
  - no huge unions;
  - CastShadow off on small decoration;
  - CanCollide off on anything you cannot walk on;
  - textures and decals for markings, not thin parts (no z-fighting, no flicker).
- **Size:** the whole compound within **160 x 160 studs** (x -80..80, z -110..50 is a good frame). Dense: no empty floor wider than about 20 studs. Landscape outside the wall can go further (to about 300 studs), but keep it cheap.

## The look: CRASH TEST LAB
A bright, cartoon crash-test facility for kids aged 9-14, playing mostly on phones.
- **Shapes and signs:**
  - chunky, rounded, toy-like shapes; thick and bold; readable on a phone screen;
  - nothing thin or fiddly;
  - signs are big pictograms, never small text.
- **Palette** (stick to it):

  | Colour | RGB | Used for |
  |---|---|---|
  | warm concrete | 230,226,216 | floors (texture it, never plain white) |
  | dark concrete | 150,150,158 | trims, walkways |
  | safety yellow | 255,200,40 | hazard stripes, with black |
  | black | 30,30,34 | hazard stripes, with yellow |
  | signal orange | 255,120,40 | things you use |
  | lab white | 245,245,245 | buildings, with teal glass |
  | teal | 60,190,200 | glass |

  Grass green only outside the wall.
- **The floor has life:**
  - each zone on its own coloured pad;
  - painted arrows, numbers, skid marks and hazard corners;
  - height changes: raised platforms with steps, a sunken crash pit, ramps.
- **Every zone is a set piece:** its own frame (a gantry, a fence or a glass wall), its own floor pad, one big pictogram arch sign, and an accent light. No lone props scattered around.
- **Outside the wall:**
  - a test track running round the compound;
  - hangars, a control tower and a water tower as a skyline;
  - hills and groups of trees;
  - a road with a gate.
  - No flat empty grass, no fog wall.
- **Inspiration level:** the best-looking Roblox hubs (bright, dense, clear landmarks). The current lab scored 3/10 from the owner because it was an empty white slab with scattered props. Aim for 10/10.

## The layout (you may improve it, but keep every zone)
```
          CREATURE WING          DROP TOWER (hero)          SMASH YARD
          spider web, shark      tallest thing, lab         wrecking ball, boxing
          tank, frog, plant      name on top                ring, stretch machine, chicken pen
   LAUNCH RANGE   ---------  TEST FLOOR (centre)  ---------   CRASH TRACK
   cannon, catapult,          round arena, dummies           launch pads, crash wall,
   rocket, mole               on its rim, red button         car bays
          TRAVEL GATE             SPAWN (0,0)                SHOP ROW
          portal + MAPS board      facing -Z                 booths + VIP door
                              (weapon range outside the south gate)
```
- From the spawn, on a phone, you must see the test floor with its dummy stands right ahead (about 15-30 studs), the drop tower behind it, and at least 3 other landmarks.
- Walkways: one loop from the spawn past every zone, with floor arrows. Every path ends at a zone.
- **The drop tower is yours to build, as walkable geometry:**
  - about 50-70 studs high;
  - stairs or a ramp up;
  - a slide down;
  - a top deck;
  - a big frame on top for the lab-name sign.

## Anchors: the contract (the most important part)
Inside `LabMap` make a Folder named **`Anchors`**. For every item below, add one Part with the **exact name**:
- Anchored, Transparency 1, CanCollide false, CanQuery false;
- **Size = the footprint** (X width, Y height, Z depth);
- **Its front (the part's LookVector, -Z) points where the thing should face** (normally toward the spawn or the walkway);
- the bottom of the part sits on the floor where the thing stands.

Leave that footprint **flat, empty floor** (nothing built inside it). The gameplay goes there later. Sizes are approximate: when in doubt, leave a little more room.

| Anchor name | Footprint W x D (studs) | Notes |
|---|---|---|
| `Spawn` | 14 x 14 | PrimaryPart, at 0,0,0, facing -Z |
| `TestFloor` | 40 x 40 | round arena centre; you build the arena itself (raised, hazard rim, painted target) |
| `Dummy_1` … `Dummy_8` | 4 x 4 each | test stands on the arena rim, facing the arena centre |
| `RedButton` | 8 x 8 | the BIG RED BUTTON console, at the arena's far edge, facing the spawn |
| `Portal` | 16 x 6 | travel gate, facing the walkway |
| `MapsBoard` | 18 x 4 | next to / built into the travel gate |
| `Leaderboard_1`, `Leaderboard_2` | 12 x 2 | two big screens (you may build frames round them) |
| `LabNameSign` | 34 x 4 | on top of the drop tower, facing the spawn |
| `TowerPlank` | 6 x 14 | top deck of the tower, sticking out over the airbag |
| `TowerAirbag` | 24 x 24 | landing spot below the plank |
| `Cannon` | 12 x 16 | launch range |
| `Catapult` | 14 x 18 | launch range |
| `Rocket` | 12 x 12 | launch range |
| `Mole` | 14 x 14 | launch range |
| `LandingField` | 30 x 80 | the field the launch range shoots over; distance boards along its side are yours to build |
| `WreckingBall` | 22 x 22 | smash yard (you may build the gantry it hangs from) |
| `BoxingRing` | 26 x 26 | smash yard |
| `StretchMachine` | 14 x 22 | smash yard |
| `ChickenPen` | 18 x 18 | smash yard |
| `Press` | 14 x 14 | smash yard |
| `SpinCycle` | 14 x 14 | smash yard |
| `Vacuum` | 12 x 12 | smash yard |
| `MechArms` | 12 x 12 | any zone |
| `SpiderWeb` | 32 x 10 | creature wing, a backdrop |
| `SharkTank` | 32 x 22 | creature wing (you may build the glass tank, with no water script) |
| `Frog` | 18 x 18 | creature wing |
| `Plant` | 18 x 18 | creature wing |
| `Terminal_1` … `Terminal_4` | 4 x 4 | feeding terminals in front of the creatures |
| `LaunchPad_1` … `LaunchPad_3` | 10 x 10 | crash track |
| `CrashWall` | 32 x 4 | the end of the crash track (you may build the padded wall itself) |
| `CarBay_1` … `CarBay_4` | 12 x 22 | painted bays at the crash track (bay 4 for the tank) |
| `BounceTower` | 18 x 18 | anywhere near the spawn |
| `DummyFactory` | 18 x 18 | dispenser near the test floor |
| `Conveyor` | 6 x 30 | from the factory to the arena (just its path) |
| `Booth_1` … `Booth_4` | 10 x 8 | shop row (you may build the awnings and counters) |
| `VipDoor` | 10 x 4 | end of the shop row |
| `WeaponRange` | 40 x 30 | outside the south gate |
| `Bench_1` … `Bench_4` | 6 x 2 | round the arena, facing it |
| `New_1` … `New_4` | 14 x 50, 30 x 30, 10 x 60, 20 x 20 | room for new machines (bowling lane, pinball pit, rocket sled, spare) |

## Lighting
- Inside `LabMap` add a Configuration named **`LightingSettings`**, with attributes:
  - ClockTime 15.3, Brightness 2.2;
  - Ambient and OutdoorAmbient as Color3;
  - AtmosphereDensity 0.25, AtmosphereHaze 0;
  - Saturation 0.15, Contrast 0.05;
  - plus anything else you set.
- Set the same values in the build place's Lighting so the captures show the real look.
- No custom sky asset that needs scripts; a normal Sky object is fine (put it in the Configuration too).

## Check your work (be a harsh critic)
1. Take 4 screenshots:
   - the spawn view at phone size (Studio Device emulator, iPhone landscape);
   - the spawn view on PC;
   - a high view over the whole lab;
   - top-down.
2. Score each of these 0-10 and be harsh. When in doubt, score lower. Fix anything under 9 and capture again (max 3 rounds).
   - The theme is clear in 1 second.
   - It is dense, with no empty floor.
   - The landmarks are visible from the spawn.
   - It is readable on a phone.
   - Light and colour are good.
   - Nothing floats or clips.
   - It is within the part budget.
   - Every anchor is present and named right.
3. Run a final check script that prints:
   - the number of parts;
   - the number of scripts (it must be 0);
   - every anchor name found, and any missing from the table.

## Deliver
1. Right-click `LabMap` → **Save to File** as **`LabMap.rbxmx`** (XML, not .rbxm).
2. If the game's git repo is on this PC (`tristanaleksander60-stack/ragdoll`):
   - put the file at `art/maps/LabMap.rbxmx`, plus the 4 screenshots in `art/maps/`;
   - commit to a NEW branch **`labmap`** (never to `release`) and push.
   - Otherwise tell me where the file is saved, so I can send it on.
3. Finish with a short Danish summary: the zones, the part count, the anchors, the score.
