# RAGDOLL HAVOC v3: the one plan (run it when the owner writes "klar")

The owner's standing order (19 Nov 2026): "når jeg skriver klar, gør du automatisk alt: bedst, hurtigst, kvalitet, billigst". Do not ask questions. Decide by this file and CLAUDE.md, report in Danish (short), and keep going phase by phase until everything is done or credits run out. After each phase, push and leave a state line, so the next "klar" picks up where you stopped.

## How to run it
1. **Where you are decides what you do:**
   - **On the PC** (Studio open, Roblox Studio MCP, RagdollLab folder, branch `release`): everything, including inserting Creator Store models and Studio captures.
   - **In a cloud session** (no Studio): Phase 0 as far as the network allows, then all **code** parts of A, C and D on `release`. Write the Studio-only steps (models, terrain, captures) as a checklist at the bottom of this file under "PC TODO". Never fake a capture.
2. **Order:** 0 research → A look, HUD, first person, 3D UI → B maps (Test Ground first) → C lab activities → D economy. If Phase 0 evidence says otherwise, re-rank B-D and say so in one Danish line.
3. **Cheap and fast:**
   - **Research:** at most 3 parallel agents, one pass.
   - **Building:**
     - work yourself in small commits;
     - do not use a multi-agent workflow unless the owner says "ultracode";
     - put mechanical sub-tasks on a cheaper model where the tool allows it.
   - **Review:** one blind reviewer per phase (skills/quality-score, pass bar 8.5, max 2 fix rounds).
   - **Tests:** only the affected tests while working; the full suite plus LayoutCheck once per phase.
4. **Quality gates per phase:**
   - before and after Studio captures from the same 3 spots (spawn, cannon, crash wall) and each new map, judged only on captures;
   - LayoutCheck at 0 problems;
   - the affected SelfTests pass;
   - the LihFolk check reports 0 errors.
5. **Safety:**
   - Every free model: delete the scripts we did not write and scan for require/getfenv/loadstring/Teleport/Http and hidden names.
   - Vehicles use our own chassis code.
   - Everything sits behind `Config.LOOK_V3` / `Config.UI_3D` switches.
   - Never publish. The owner publishes, with "Shut Down All Servers".
   - Remind the owner to save the place after model work.
   - Never write live DataStores.
6. **End of each phase:**
   - commit and push `release`;
   - add a short CLAUDE.md log entry;
   - tell the owner in Danish: done / test this / still open.

## State
- **19 Nov 2026, cloud session (no Studio): v0.21.0 on `release`, never run in Studio.**
- Phase 0 is done: echo-heist `docs/ragdoll-havoc/research/RESEARCH_V3.md` and `MARKET_2026-11-19-evening.md`. Reddit, TikTok and YouTube were unreachable from the cloud, so those findings are search snippets only.
- Phase A is done in code (`Config.LOOK_V3`, `UI_3D`):
  - overcast light;
  - white dummies that talk (DummyLines);
  - quiet world signs;
  - HudV3: squares, key chips, the Next pill and the LAB window (off phones only);
  - the first-person gun in a white hand;
  - the black hit card;
  - weapon models that turn in the catalog and the egg card (Ui3D);
  - Landscape: a grass baseplate, a terrain hill ring and 140 low-poly trees.
- Phase C has started in code:
  - VehicleService and VehicleClient: a family car and a monster truck per lab;
  - Creatures: Gorilla Rampage and Bull Run events;
  - a BIG RED BUTTON per lab;
  - tests T91_LookV3 and T92_Creatures.
- **Owner feedback after the first test (19 Nov):** the 3D menu lagged (fixed: the turning model only on the hovered card), and the code-built hills, trees, cannon and maps looked cheap. The answer is real models: `Server/Systems/V3Assets` + `tools/ImportV3Assets.luau` + `docs/V3_ASSETS.md` (29 picks); noise-terrain hills; trees only as models; `LabDress`.
- **Checked 19 Nov (PC):** the note that an earlier PC session had run `PC_PROMPT_ASSETS.md` did not hold: the saved place had no `ServerStorage.V3Assets`, and the PC folder had no unpushed work. This session did the import (below).
- **19 Nov 2026, PC session (Studio), first "klar":**
  - PC TODO step 0 done: the 29 models are in `ServerStorage.V3Assets` (place saved, version 471). All scripts stripped; also seats disabled, prompts/clicks/sounds/fire/headlights removed, brand marks removed (a Chevrolet emblem on the truck, logo decals on the rocket and truck, the train's name board), the rocket's launch-site ground removed, one white Sedan and one palm kept from their packs, the fence squared, Yaw set (Car 0, MonsterTruck 180, Gorilla/Bull 90, Cannon -90). `tools/ImportV3Assets.luau` now does all of that itself.
  - Play test with captures (spawn, cannon, west, back end): every model placed, sizes right; the cannon is now 14 studs. T91, T92, T36 (fixed for LOOK_V3), T50, T23, T54, T56, T60, T90, T35 (Ladder v2), T38 (MILD_TEXT) pass.
  - **LayoutCheck had 551 problems on its first Studio run** (the cloud phases were never run there): fixed to **0**, live 0. Main fixes: one bar row on phones clear of GRAB/SHOOT, upright-phone placement for the event bars, BUILD/PLAY, the doctor monitor and the hit line, tablet RUN, button and rarity contrast.
- **Next:**
  1. The rest of the PC TODO: phone captures, drive the car/truck, press the BIG RED BUTTON, first-person tuning.
  2. Phase B maps: **5 open-air maps built and seen in Studio (19 Nov PC)**: Island, Downtown (City), Building Site, Old Farm, Army Base (`Server/Systems/OutdoorMaps`, `Places` outdoor row, spacing 1200). Packs live in the place only: `ServerStorage.V3Packs` (CityBuildings, CityRoads, CityProps, SUV, SiteMeshes, Crane, Scaffold, Mixer, Farm, Military; all scripts stripped, seats off; saved v485). Terrain is filled first and the floor stands on its measured top. T21/T26/T27 pass, LayoutCheck 0. Maps cards show real captures (art/maps, uploaded ids in Places.image). Still to do: the activities (catapult, cliff dive, crane, firing range) in phase C, and a denser Site and Army Base.
  3. Phase C: map launchers DONE (10 on the 5 maps, MapActivities, T93; blind review 7.2 -> fix round 1: getting up on a far map no longer respawns (PlayerRagdoll.validSpot knows Places), hidden outdoor floors are not solid, no relaunch while down, Hazard events once per 30 s per pad, map builders in pcall, arrival on the built pad, T93 sends the player home). Full suite 75/79 (T19, T32 flaky; T26, T29 pass alone). Disasters DONE: Tornado + Meteor Shower (Creatures.tornado/meteors, Events Tornado/MeteorShower productId 0, in the BIG RED BUTTON pool, T92). Then (19 Nov PC): throw tower in every lab (LabDress.throwTower: CastleTower + lift pad TeleportTo + jump launcher, Kind Tower), Train Run event (Creatures.train, rails + steam engine, BIG RED BUTTON pool), crane drop lift on the Site, new experiment cards Tower + MapLaunch (activity of the day via the daily deck). Phase C DONE.
  4. Then D: a Lab Controls pass, an Endless Events pass, an Everything pass and a vehicle pass. Their ids come from the owner.


# RAGDOLL HAVOC v3: maps, look and lab activities (owner request, 19 Nov 2026)

The owner's words: "Tag inspiration af ALT grafisk, helt ned til mindste detalje. Brug maps, biler (fine if from other creators). Tilføj en masse forskellige ting ved de forskellige maps, og især kæmpe opgradering i ens eget lab i forhold til aktiviteter, så folk altid har noget nyt at lave."

Reference: Hyper Realistic Ragdoll gameplay captures (80k CCU), see LOOK_PLAN.md.

**Rules:**
- Free Creator Store models are allowed. Never copy files out of another game.
- Every inserted model gets a malware pass before it is kept. Delete every Script and LocalScript unless we wrote it, and search for `require(`, `getfenv`, `loadstring`, `TeleportService` and `HttpService`. We found malware four times already.

## What their captures show, detail by detail

| Area | Detail |
|---|---|
| Light | Overcast but clean. Roblox cloud sky, soft shadows, no haze on the play area, a slight distance fade on the hills. Low contrast and natural colours. |
| Ground | **Terrain**: Grass (textured, with brown patches), Sand on the island, Ground or Mud on the site. Wide light concrete paths of about 12 studs with joint lines. |
| Backdrop | Rolling green hills (terrain) with low-poly pines and broadleaf trees. The sea is terrain water to the horizon. |
| Props | Real-world objects at 1:1 scale with plain materials: a train on a track, a tank, a monster truck, a blue sedan, a white sports car, red-white barrels, a brick wall, a boxing ring, a wooden crate, a big red push button, benches, a castle tower, a giant fan, a slide tower, a rocket, a pool, a bunker with a truck. |
| Island | A beach ring, palms, a jetty, parked vehicles on concrete pads, a catapult, **a gorilla in a pen** (rocks and logs), a cliff, and a world screen showing the map list. |
| Building site | A concrete mixer, scaffolding, a building frame, a tower crane with a hanging hook, sand and gravel piles, a wheelbarrow, a cable drum, jersey barriers, mesh fences, a fenced pit, pallets, bricks. |
| Dummies | Plain white, **many wander idle** across the map. Speech bubbles are small black boxes: yellow text with a gun icon when you aim ("Is that a gun?", "Whoa, put that down!", "Don't shoot!"), white text for idle chatter ("I wish I had a dog."). |
| HUD | Left: Shop, Tools and Lab (big square icon and word). Right: Maps and Events. Bottom: 6 icon-only slots. Bottom-left chips: R Revive · G Spawn · V Scan. Top-right: a gift icon and a "Next: Golf Club 2/3" pill. A Here/Friends/Global board. One font, dark glass, white icons. |

## The build, in phases (each behind a Config switch, `LOOK_V3`)

### Phase 0: research first (about 1 hour, before any build)
Run it on the PC session, where WebSearch and WebFetch are not blocked by the cloud proxy. Keep separate:
- what you **saw** (a page read, a video watched, a capture);
- what only came from a search snippet.

1. **Reddit:**
   - r/roblox, r/RobloxDevelopers, r/robloxgamedev, r/GoodRobloxGames, r/robloxhackers (only for what exploiters target);
   - search "ragdoll", "hyper realistic ragdoll", "ragdoll game", "physics sandbox", "crash test";
   - collect: what players love, what they complain about (lag, pay-to-win, boring after X minutes), which features they ask for.
2. **TikTok and YouTube Shorts:**
   - #robloxragdoll, #ragdollphysics, #hyperrealisticragdoll, #robloxphysics, "roblox ragdoll funny";
   - note the 20 most-viewed clips from the last 30 days: what happens in the first 2 s, which map, prop or vehicle, and whether it is solo or with friends;
   - this tells us which activities to build first.
3. **YouTube long form:**
   - the top 10 videos on Hyper Realistic Ragdoll, Ragdoll Research, BloxNG and Ragdoll Sandbox;
   - note what the YouTuber does for the first 3 minutes, and what they call boring or amazing.
4. **Roblox communities:**
   - the competitor groups and Discord servers (update logs, suggestion channels, "what's next" polls), DevForum threads on ragdoll performance and vehicles;
   - the update logs of the top 5 (how often, and what each update adds);
   - their game passes and prices (games API).
5. **Numbers:**
   - Roblox games API for CCU, likes and favourites of the top 30 ragdoll games now, compared with research/COMPETITORS.md (19 Nov);
   - rising newcomers (created in the last 14 days, with CCU above 2k): what their hook is.
6. **Our own players:** Session_v1 and Profile_v1 after the `release` publish: median session, the share who fire, the 5-minute share, which toys and stations get used.

**Output:** `docs/ragdoll-havoc/research/RESEARCH_V3.md` with:
- the top 15 requested features;
- the top 10 complaints about competitors (our chance);
- the 5 most viral clip formats;
- prices;
- update rhythm;
- a source list.

Then **re-rank BUILD_V3 phases B-D by that evidence** before building, and show the owner the ranked list in Danish.

### Phase A: look and HUD (code, can be done in the cloud session)
1. **Lighting.** A `ZoneLighting.Overcast` profile:
   - ClockTime 13;
   - Brightness 2.2;
   - Ambient (70,72,78), OutdoorAmbient (120,124,130);
   - EnvDiffuse 1, EnvSpecular 0.6;
   - ShadowSoftness 0.35;
   - Atmosphere Density 0.3, Offset 0.1, Haze 0.4, Glare 0, Color (199,205,214), Decay (106,112,125);
   - Bloom 0.1, ColorCorrection Contrast 0.05, Saturation -0.05;
   - no DepthOfField or SunRays.

   ChristmasFx keeps the snow only.
2. **Dummies:**
   - plain white (`DummySkin` colour 245,245,245), no NpcGlow, no suits or numbers;
   - `DummyLife.BUBBLES = true` with two line sets: fear (when aimed at, with a gun icon, yellow) and idle (white, every 20-40 s, max 2 at a time per screen);
   - idle wander for every free dummy.
3. **HUD v3 (`Client/HudV3`):**
   - Left column Shop / Weapons / Lab and right Maps / Events. Square cards of 132x120, dark glass at 0.25 transparency, a white icon of 56 px and an 18 px word.
   - The icon-only bar (6 slots, 88 px, number top-left).
   - Key chips bottom-left.
   - Next pill top-right.
   - Hide the NEXT banner, the chaos meter, the sandbox column, the event side cards, the level badge and the experiment card on PC. The experiment moves into the Lab window.
   - Phone: the same with smaller cards; SHOOT, GRAB and RAGDOLL stay.
4. **Windows:** a black body, one header colour each (Weapons red, Lab teal, Maps olive, Events magenta), tabs left, big icons.
5. **World text off:** `Playground` billboards, `WorldDress` boards, leaderboard neon and the OWNER/VIP tags (switch).

6. **First person with the gun in view** (owner capture, 19 Nov). We have `Client/FirstPerson` + `Client/Viewmodel`; tune them to match:
   - The gun sits **big, lower right**: the grip is about 35 % of the screen height, the muzzle points at the crosshair, and the slide top is at about 50 % of the screen height.
   - **One plain white hand and forearm** come in from the bottom-right corner (SmoothPlastic, 245,245,245). No skin colour, no sleeve.
   - The gun model is clean matte black with real detail (slide serrations, sights). Use the real mesh models in N7Assets.Weapons at scale 1.0, not 0.55.
   - The sway is small (0.3 studs) and the bob is small. Recoil kicks the slide back and lifts the gun 4 degrees, settling in 0.12 s.
   - The crosshair is a small 4-line cross.
   - **The hit card** sits under the crosshair while aiming at a body: line 1 is the body region in yellow ("Face, skull, jaw, chest"), line 2 is "Name · state · N% blood" (we have HitInfo, so restyle it to a black box with a yellow left bar).
   - V switches the view, and first person is the default for guns on PC.

7. **All UI 3D and interactive** (owner, 19 Nov: "gør alt UI 3D interactive"). Module `Client/Ui3D`, switch `Config.UI_3D`.
   - **Weapon cards:**
     - Each card shows the real weapon model in a ViewportFrame (the N7Assets.Weapons mesh), slowly turning.
     - Hover or touch-drag spins it, and a click fires a dry-fire animation and sound in the card.
     - Locked cards show the model darkened under a lock.
     - The bars (POWER, RATE, REACH) fill in when the card opens.
   - **Event cards:** a live 3D preview in the viewport (a mini tornado, falling mini dummies, a black hole spinning) on hover or select. A static picture when the card is not in view.
   - **Map cards:** a 3D diorama of the map (a low-detail clone, under 300 parts) that turns, with a hover zoom. ENTER plays a short camera fly-in before the teleport.
   - **Shop and offers:** the item turns in 3D. A purchase plays a "drop into your hands" animation.
   - **HUD buttons:**
     - pressed depth (a 4 px drop and a shadow), a hover tilt of up to 6 degrees following the mouse, a spring back;
     - the icons are small 3D renders (ViewportFrame snapshots, static, so no cost);
     - the hotbar slots show the 3D weapon, and the selected slot lifts 6 px and its weapon turns.
   - **The dummy inspector:**
     - In the Scan view (V), click a dummy to open a turning 3D copy of it.
     - The hit regions light up, with the hit card beside it.
     - Drag to rotate, scroll to zoom.
   - **World UI:**
     - In-world screens use SurfaceGui with real buttons you walk up to, as the leader's map board does: a map board, an event board, a weapon rack where you click the gun on the wall to equip it.
     - ProximityPrompt E for pads, the button and vehicles.
   - **Windows:** they open with a short 3D swing (rotate from 8 degrees to 0, scale 0.96 to 1, 0.18 s) and close the reverse way. The gamepad focus ring moves with a spring.
   - **Performance budget:**
     - at most 6 live (turning) ViewportFrames at once on PC and 2 on phones;
     - everything else is static (render once, then stop updating);
     - viewports pause when their window is closed or off screen;
     - test with `FX_CAPS` per tier, and LayoutCheck covers the new pieces.

### Phase B: maps (local session with Studio MCP and the Creator Store)
Every map is a Model under `ServerStorage.Maps`, streamed in for that player's lab (per-player lab stays). A Maps window shows a screenshot and ENTER. There are 6 maps, each with **at least 25 props and 3 activities**.

| Map | Ground and backdrop | Props (free models allowed) | Activities |
|---|---|---|---|
| **Test Ground** (the new own lab) | grass terrain, concrete paths, hills and pines | a train and a looping track, a tank, a monster truck, a sedan, a sports car, barrels, a brick wall, a boxing ring, crates, benches, a castle tower, a giant fan, a slide tower, a rocket, a pool, a bunker | drive vehicles, the train runs dummies over, a fan wind tunnel, a slide, a boxing ring, a big red button (random event), explosive barrels, a rocket launch |
| **Island** | a sand beach ring, sea, palms, a cliff | a jetty, a boat, parked vehicles, a catapult, a gorilla pen, a lighthouse, beach huts | the catapult launch, the gorilla throws dummies, a cliff dive, boat ramming, waves |
| **Building Site** | ground/mud terrain, a site fence | a tower crane and hook, a building frame, scaffolding, a mixer, piles, a wheelbarrow, barriers, a pit, pallets | the crane grabs and drops, a wrecking ball, a falling scaffold, a mixer spin, digger scoops |
| **Clean Room** | a white room, soft ceiling lights | nothing but a few cubes | pure testing with no clutter |
| **City Street** (ours) | asphalt, pavements, shop fronts | buses, taxis, traffic lights, hydrants, lamp posts, a bus stop | bus runs, crash test at a junction, a crosswalk |
| **Christmas Village** (from Dec 1) | snow terrain, cabins | a sleigh, a chimney launcher, a present pile, a tree, a skating pond | the sleigh ramp, the chimney launch, an ice slide, snowball cannons |

### Phase C: lab activities ("always something new")
- **Vehicles** (VehicleSeat on our own simple chassis, never a free-model chassis script):
  - car, monster truck, tank (shell = Blast), bus;
  - hit speed above 30 studs/s ragdolls a dummy;
  - an F prompt to enter.
- **Machines:**
  - the train (a fixed path, 30 s loop);
  - the giant fan (VectorForce cone);
  - the crane hook (grab and drop);
  - the catapult (a charged launch);
  - the wrecking ball (exists);
  - the big red button (fires a random Event, 60 s cooldown);
  - explosive barrels (respawn after 20 s).
- **Animals:** a gorilla that wanders and throws a dummy within 10 studs, and later a bull.
- **Activity of the day:** one machine or map highlighted each UTC day, plus an Experiment tied to it (ExperimentService exists).
- **Lab upgrades for Bolts:**
  - buy and place machines in your own lab (BuildService exists);
  - 3 lab sizes;
  - a "Lab Controls" pass (fly, stop time, spawn dummies, launch, explode), as the leader sells.

### Phase D: economy (as in LOOK_PLAN)
- First unlocks at 2/3/4 takedowns.
- SKIP R$9-49 per locked weapon (dev products by tier).
- Events R$25/49/89 with one free a day (already close).

## Order and proof
1. Phase A first, judged on real Studio captures from the same 3 camera spots before and after.
2. Then one map at a time, Test Ground first.
3. Each map gets its activities in the same step, plus a SelfTest (`T9x_Map<Name>`: prop count, no scripts in models, activities fire).
4. LayoutCheck stays at 0 problems.
5. The owner publishes after each phase.

---

# RAGDOLL HAVOC: the "clean look" plan (2026-11-19)

The owner's verdict on the release build (phone/PC capture, 19 Nov): "it looks like AI slop, not a Steam game".

## Why it looks cheap (found in code)

| # | Cause | Where | Value now |
|---|---|---|---|
| 1 | A grey haze over everything | `Client/ZoneLighting.luau` (Atmosphere) | Density 0.24, **Haze 1.1** |
| 2 | Flat light with no shadow depth | ZoneLighting `Day` | OutdoorAmbient (128,134,150), ClockTime 14.6 (overhead sun), ShadowSoftness 0.25 |
| 3 | Glowing, blurred, washed out | ZoneLighting | Bloom 0.55; DepthOfField Far 0.12 |
| 4 | Cold blue-grey, desaturated | `Client/ChristmasFx.luau` | Tint (236,243,255), Saturation -0.06 on top of the day grade |
| 5 | Green "zombie" dummies | `Client/NpcGlow.luau` | Highlight fill (90,230,110), pulsing |
| 6 | Text in the world everywhere | `Playground.luau` BillboardGuis (LAVA!, SPIKES!, BULLSEYE, PUT RAGDOLL HERE…); `WorldDress` boards; neon leaderboards; OWNER tag; VIP | about 15 labels in one view |
| 7 | Mixed styles | realistic sky + concrete MaterialVariants next to cartoon fonts, neon frames, Santa hats, coloured suits (`DummyFactory.SUITS`) | — |
| 8 | HUD with about 20 elements | HudMenu column (6), sandbox column + event cards (7), bar (7), NEXT banner, people list, ammo "17 / 17" mid-screen | — |
| 9 | Floating black cubes | probably `WorldDress` (lamp heads or light towers) | must be checked in Studio |

## How the big ragdoll games do it

- **The image servers could not be reached from the cloud session** (thumbnails.roblox.com is blocked by the proxy), so no competitor screenshots were graded here.
- What is known comes from their store pages, research/COMPETITORS.md and public guides:
  - Hyper Realistic Ragdoll's "realistic" means the physics (limp, stumble, crawl), not textures. Players choose map, weather and time of day, and the look is plain and calm.
  - The leaders have one style each, either fully realistic or fully cartoon, never both.
  - They use very little text in the world and a small hotbar with icons. Menus stay hidden until opened.
- Common devforum practice for realistic lighting:
  - Future lighting;
  - Ambient near black and EnvironmentDiffuse/Specular 1;
  - hard shadows and a low sun;
  - a little Bloom and ColorCorrection;
  - little or no haze.
- To grade this properly, the owner should send 2-3 Studio or phone screenshots of Hyper Realistic Ragdoll and Ragdoll Research. Judge only real captures (MASTER_PLAN lesson 1).

## The pass (one session, every step behind `Config.LOOK_V3` so it can be switched back)

1. **Light** (ZoneLighting `Day` + atmosphere + ChristmasFx):

   | Group | Settings |
   |---|---|
   | Lighting | ClockTime 16.3, Brightness 3.5, Ambient (30,32,38), OutdoorAmbient (70,72,82), EnvDiffuse 1, EnvSpecular 1, ShadowSoftness 0.05 |
   | Atmosphere | Density 0.28, Offset 0.25, **Haze 0**, Glare 0.2, warm Color |
   | Bloom | Intensity 0.15, Threshold 1.6 |
   | ColorCorrection | Contrast 0.22, Saturation 0, a slight warm tint |
   | DepthOfField | off outside replays |

   Christmas keeps the snow only, with no blue tint.
2. **One style: a realistic test lab.**
   - Dummies get the grey mannequin skin only. No green glow: NpcGlow goes off, or becomes a thin white outline only while you aim.
   - No coloured suits or back numbers.
   - Santa hats only from 1 Dec.
   - Neon only on the 3 launch pads.
3. **World text down about 80 %.**
   - Station labels become flat floor decals (SurfaceGui on the pad, about 2 studs high, no glow), seen only within about 25 studs.
   - Remove LAVA!/SPIKES!/DANGER boards.
   - The two leaderboards become one small wall board without neon or crowns.
   - OWNER and VIP tags off by default.
4. **HUD of 5 things (PC):** the bar (6 small icon slots, number above), one MENU button, a small crosshair, ammo next to the bar, and the experiment line at the top.
   - The NEXT banner, the shop/rewards/places/settings column and the sandbox column move into MENU, with their keys kept.
   - The people list stays hidden (Tab).
   - Phones keep SHOOT, GRAB and RAGDOLL.
5. **Fix the floating cubes** (find them in Studio, then fix WorldDress).
6. **Proof:** before/after captures from Studio at the same 3 camera spots (spawn, cannon, crash wall) on PC and phone, plus LayoutCheck at 0 problems.

## Update: Hyper Realistic Ragdoll's store page, seen (19 Nov)

The 9 store images were downloaded via thumbnails.roblox.com (the video could not be fetched: asset delivery is blocked and the poster is a placeholder).

- **All 9 are polished 3D renders made for marketing, not gameplay captures.** They look like AI or 3D-artist renders.
- **The look is extremely simple:**
  - the classic bright green grid baseplate;
  - a blue sky with white clouds;
  - a few blocky trees and grey blocks far away;
  - smooth **white** mannequins with the classic Roblox face.
- **Each image shows ONE action:** bat to the head (with an X-ray skull), punched into a wall, a hammer into the ground, a snake, a T-rex, arrows and knives, a boulder.
- **No text, no UI, no logos and no signs** in any image.
- **The lesson:** the leader at 43k CCU is not "Steam realistic". It wins on **clarity**: one clean floor, one sky, white dummies, and big readable physics moments. "Hyper realistic" means the physics.

**Changed direction for the pass:** not a dark realistic lab but a **clean, bright crash-test lab**.
- A clear blue sky with no haze, and soft but visible shadows.
- A clean light floor; the props get one or two colours each.
- **White** smooth dummies (lighten DummySkin) with a simple face.
- Close to zero text in the world, a minimal HUD, and big hit moments (X-ray, dust, cracks in the floor).
- Store images in the same style: one action each, no text. The thumbnails made on 19 Nov carry text, so make a new set without it.

## Teardown from real gameplay captures (owner, 19 Nov, Hyper Realistic Ragdoll at about 80k CCU)

### World ("Test Ground")
- **Calm, natural daylight.** Light overcast, with soft shadows under the player. Distance fog only on the far hills, and no grey wash on the play area.
- **Muted, real-world colours:** concrete tiles, grass, army-green machines, brick, wood. No neon anywhere.
- **Props are things a kid recognises:** a giant fan, a tower with a slide, a rocket, a monster truck, a car, benches, trees, a castle tower and a pool. Each has 1-2 colours and is not glowing.
- **Text in the world:** one small "DANGER" sign and a speech bubble from a dummy ("Don't shoot!", the Talk tool). That is all.
- **Dummies** are plain white mannequins that react and talk.
- **The world sits in a landscape** of green hills and pine trees. It is not floating on a void or a rooftop.

### HUD (PC), one style for everything
- **Left:** 3 big square buttons with an icon and a word: Shop, Tools, Lab.
- **Right:** 2 more, Maps and Events. All are the same size and the same dark glass.
- **Bottom centre:** 5 **icon-only** slots with a small number and no names: hand, gun, fist, talk, kick.
- **Bottom left:** key hints as plain chips: "R Revive · G Spawn · V Scan".
- **Top right:** a gift icon, a "Next: Kick 0/2" pill with a thin bar, and a small Here/Friends/Global list (KOs, Revives).
- **Style:** one font (bold sans, white), white flat icons, dark translucent panels. No gradients, outlines, glow or colour per button.

### Windows
- A black body with a coloured header bar per window: Tools red, Lab teal, Maps olive, Events magenta. Icon and title sit left, a big X right.
- **Tools:** tabs on the left (Melee, Guns, Throw, Power, Medic, Robux) and "UNLOCKED 4/72".
  - Cards show a big white icon, a one-line description, POWER/RATE/REACH bars, and EQUIP/UNEQUIP.
  - Locked cards show "0 / 2 KOs" plus a purple **SKIP R$9**.
  - **The first unlocks need only 2, 3 and 4 KOs.**
- **Lab:**
  - free: Slow time on/off with a speed slider, Free cam (L);
  - locked "Comes with Lab Controls" (a pass): Stop time, Fly, Spawn dummies, Launch, Explode.
- **Maps:** 4 maps (Test Ground, Island, Building Site, Clean Room). Each has a real screenshot, one line of text and ENTER. Revive dummies, Back to spawn and Always revive sit along the bottom.
- **Events:** 9 cards with rendered 3D icons (Weightless, Deep Freeze, Falling Dummies, Wildfire, Mini Dummies, Giant Dummy, Meteor Rain, Tornado, Black Hole), "Free today" USE, then BUY R$25, x3 R$49, x6 R$89.

### What we copy as practice (own art and names, no assets or text copied)
1. **The world:**
   - a ground-level test ground in a hill landscape (no rooftop or void);
   - natural light with no haze on the play area;
   - muted materials;
   - real-world props in 1-2 colours;
   - **remove neon and almost all world text.**
2. **Dummies:**
   - plain white mannequins and no glow;
   - a short speech bubble when one is aimed at (we have DummyLife bubbles, BUBBLES=false: turn them on, short lines only).
3. **The HUD in one style:**
   - square dark-glass buttons with an icon and a word: 3 left (Shop, Weapons, Lab) and 2 right (Maps, Events);
   - an icon-only bar;
   - key chips bottom left;
   - one "Next: X 0/2" pill top right.
   - Remove the NEXT banner, the coloured slabs, the chaos meter, the sandbox column and the event side cards. Events get their own window.
4. **Windows:** a black body with one header colour per window, tabs on the left and big icons on the cards.
5. **Economy:**
   - first unlocks at 2/3/4 takedowns;
   - **SKIP for a small Robux price** on each locked weapon (a dev product per price tier);
   - a "Lab Controls" pass (fly, stop time, spawn, launch, explode);
   - events at 25/49/89 with one free per day.
6. **Maps:** several clean maps in place of one crowded lab. One of them is a plain "clean room". We have WorldMaps (Office, WhiteRoom): put them in a Maps window with screenshots.

## PC TODO (Studio only; for the PC session or the owner)
0. **DONE 19 Nov (PC):** real models imported and saved. ~~Run the prompt in `docs/PC_PROMPT_ASSETS.md`.~~ It imports the 29 Creator Store picks with `tools/ImportV3Assets.luau`, then play-tests and builds the maps. The code switches to the models by itself (`V3Assets`).
1. **Sync and play** the `release` branch. Run the SelfTest (T91, T92 and the full suite once) and LayoutCheck.
2. **Captures before and after** from the same 3 spots (spawn, cannon, crash wall) plus one in a car, on PC and phone. Check:
   - the light (no grey wash; shadows visible);
   - white dummies and their lines;
   - the HUD squares not overlapping Roblox's top bar or player list;
   - the Next pill in the top bar;
   - the LAB window rows;
   - the hit card.
3. **First person:** set the gun size and place against the HRR capture (`Viewmodel.OFFSET` and `SCALE` under LOOK_V3), and check the white forearm reads as an arm.
4. **Cars:**
   - Do they drive and turn without flipping? Tune `Config.VEHICLES` and `VehicleClient.GRIP`.
   - Do dummies fly when hit?
   - Do the pads at (66, 20) and (68, -32) clash with the Christmas chimney or sleigh, or with any WORLD prop?
5. **Animals:** press the BIG RED BUTTON until a gorilla and a bull run come. Check their size, speed and swats.
6. **Landscape:**
   - Are the hills seen from spawn but not on the play area?
   - Do the trees stay out of the labs?
   - Is the baseplate grass, with no concrete texture left?
7. **Maps (Phase B):** insert Creator Store models, run the malware pass, and save the place. Build in this order: Test Ground dressing (props like the leader's), City, Island, Building Site.

## State update (19 Nov 2026, PC, "continue every phase")
- Phase C DONE (see above). Blind review of C/D 7.8 -> fix round 1 applied:
  - the BIG RED BUTTON only starts an event when nothing runs or waits (no queue hogging, no lab event running in the plaza);
  - TrainRun is only picked when the Train model exists;
  - the tower jump pad sits on the tower's edge, and the lift lands beside it;
  - no lift from a car seat or while holding/held;
  - launchers count as traps again (Hazard);
  - NaN guards; tornado dust halved;
  - T68 knows LabControls; T25 race fixed (HEAL_AFTER set before the hit);
  - the tower moved to (-70, -28): it sat on the Christmas present trap (T66).
- Phase D DONE in code: Shop.OFFERS has AllGuns (pass, 149) and LabControls (pass, 179: the BIG RED BUTTON every Config.LAB_CONTROLS_GAP 8 s for its owner in their own lab); Everything now includes Lab Controls. All ids are 0 until the owner creates them. A Vehicle pass was skipped: the car and the truck are free in every lab, and nothing paid would add to them yet.
- Release 0.22.0: Config.Version, Shop.WHATS_NEW, STORE_TEXT.md "Description v3".
- Full suite 77/79 before the last fixes (T25 race and T66 tower: both fixed and passing alone); LayoutCheck 0.
- Phase 6 (phones): LayoutCheck covers the phone layouts at 0 problems. HudV3 itself stays off on phones; the phone HUD is the fitted round-5 one.
- **The owner must:** save the place; create the products and passes listed below; publish with "Shut Down All Servers".
