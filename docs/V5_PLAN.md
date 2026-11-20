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
