# V5: polish everything (owner, 20 Nov 2026: "Forbedre alt grafisk, ui, modeller, ragdolls, mechanics, dress osv")

Ordered by how much of a player's screen time each one covers. Every step:
- has a Config switch where the old look is kept;
- gets a before/after capture;
- runs only its affected tests;
- is committed on `release`.

## V5-1 Spawn view (everyone sees it first)
- Portals: no neon-filled doors with heavy outlined words. Instead, a steel arch, a dark glass door with a soft inner glow, and a small plate sign. Smaller, and set aside so the lab is visible from spawn.
- Ramp and stairs: real materials (painted steel, diamond plate, hazard edges), not flat yellow.
- Lab floor: tiles or concrete variant with seams, not one grey slab.
- Today's machine sign: placed so it never sits under the top toast.

## V5-2 Dummies and ragdolls
- The classic crash-test look (switch): yellow/white shell, black-and-yellow target marks on the head and chest, dark joint rings.
- A smoother Christmas hat (no stair-step cylinders).
- Ragdoll feel: check the get-up, the flop on landing and the limb guard on a phone budget.

## V5-3 UI windows (UI_CLEAN through the kit)
- Calm window chrome, one display font, no neon edges. Shop, Weapons, Maps, Rewards and Menu go through the same tokens.
- LayoutCheck from inside the game client.

## V5-4 Event and world dressing
- Storm cloud: soft puffs, not balls.
- Card pictures for the 9 events without one.
- Lab clutter: merge or remove stray props.

## V5-5 Maps
- 3 captures per map, fixes to whatever reads as code-built.

## State
- 20 Nov: plan written; V5-1 started.
- **V5-1 done (20 Nov):**
  - With UI_CLEAN the portals are steel frames with a dark glass door, thin light strips and a plate sign, moved to the lab's west side (x -66, z 30/44, facing in), so the view from spawn is open.
  - The ramp is diamond-plate steel with yellow side rails and a painted lip.
  - Station names are small dark tags of a fixed screen size, not huge floating words.
  - T51 passes.
- **V5-2 (part):**
  - The Christmas hat is a real soft Santa hat mesh (ServerStorage.V3Assets.SantaHat = Creator Store 1055416490 "Cool Santa (Hat only)", no scripts, place file only, saved v534), sized to the head. The stacked cylinders stay as the fallback.
  - The scarf tail is thinner and red.
  - T40 passes. The white dummies stay (the owner's v3 choice).
- **V5-3 done (20 Nov):** with UI_CLEAN there is a calm token layer in LihFolkUITheme (`Theme.Clean`):
  - neutral slate canvas;
  - quieter role colours, each at least 4.5:1 under white text (T90 checks it);
  - Builder Sans ExtraBold titles instead of Fredoka, with no outlined lettering;
  - thin 1 px strokes, radii 8-12, a lighter shadow, press 0.96.
  - Every window, card and HUD piece follows it.
  - Bug fixed: the weapon cards read "POWE". The stat names now get 70 units, and LayoutCheck measures with a 15 % margin.
  - Studio-only capture hook: the player attribute `DevOpen` = a window name opens it ("Weapons" opens the catalog).
  - T90 updated (press 0.96 under Clean); T21/T35/T90 pass.
- **V5-4 (part):** the lightning storm's cloud is a volume of dark smoke puffs (a particle emitter in a flat box), not plastic balls. Seen in Studio.
- **V5-4 (more):**
  - **Giant fan:** an open ring of steel segments, a grille, a big rotor, a stand and a foot. It always stands on the east side (z -55); the solid disc used to hide the blades, and on the west it stood in the rocket.
  - **Sinkhole and quake cracks:** now at the real floor height (`Surprises.FLOOR_UP`); before they lay under the floor. The hole is a black void with dust rising.
  - **Moon:** the craters are sunk into the surface.
  - **Meteors:** 7-stud CrackedLava rocks with a light, a smoke trail and bigger fire.
  - **Card pictures:** 4 more (FanBlast, Sinkhole, BalloonDrop, MoonGravity), so 11 of 18 have one.
  - **Still a word on the card:** RocketRain, Earthquake, GiantDummy, MeteorShower and TrainRun. The meteor falls too fast to catch, and the 4x giant falls over.
  - **Seen:** the first-wow UFO came by itself at 50 s.
