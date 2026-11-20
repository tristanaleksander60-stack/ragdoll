# V7: the owner's fixes of 20 Nov 2026 (late evening)

## The owner's words (verbatim)
> Fjern det mærkelige gule lys som lyser ned på bullseye
> Fjern boksene rundt om den røde knap og kanonen på jorden. Lav flotte simple stier på gulvet/jorden af jord osv rundt i ens lab og de andre maps til de forskellige ting man kan lave de steder.
> Gør så fuglene ikke går halvt nede i jordene.
> alle ragdolls skal se bedre ud, både tøj og detaljer og alt

## Item map
| # | Request | Step |
|---|---|---|
| 1 | Remove the strange yellow light shining down on the bullseye | V7-1 |
| 2 | Remove the boxes on the ground round the red button and the cannon | V7-1 |
| 3 | Nice, simple paths (dirt and so on) in the lab and on the other maps, leading to the things to do there | V7-2 |
| 4 | Birds must not walk half sunk into the ground | V7-3 |
| 5 | Every ragdoll must look better: clothes, details, everything | V7-4 |

**Order:**
1. V7 goes first, even though V6-8 (graphics) is under way. Commit and push what is done of V6-8, and note it in V6 State.
2. Then V7-1 to V7-4.
3. Then back to V6-8 in `docs/V6_PLAN.md`.

V7 is small and visible, so it goes before the big graphics pass.

## Rules for every step
These are the same as V6:
- **Captures:** before and after, from fixed named spots, judged against Hyper Realistic Ragdoll. Nothing may look code-built, cheap or "AI".
- **Models:** real Creator Store models in one style, with the malware pass on every insert. Note in State what lives only in the place file, and remind the owner to save.
- **Settings:** Config switches, numbers in Config, and the server decides.
- **Phones:** the low-tier budget holds and LayoutCheck shows 0 problems.
- **Tests and review:** a `T1xx` self-test where it can break again, and one blind reviewer per step (pass bar 8.5).
- **After each step:** commit and push `release`, update State, and send a short Danish report (Lavet / Test selv / Brug for fra dig).

## V7-1 The yellow light and the ground boxes
**Likely sources** (check them in Studio first; the capture decides):
- `Server/Systems/LabZones`, "Today's machine": a yellow **neon cylinder** `TodayLight` (255,205,60, 60 studs tall), standing over the day's machine. Today that is the Bullseye.
- `LabZones.ZONES`: painted floor boxes, made of a `ZoneTint` plus four `ZoneEdge` strips and floor text.
  - EVENT PAD is the red box round the BIG RED BUTTON.
  - LAUNCH ZONE is the orange box round the cannon.
  - TEST ZONE, VEHICLE BAY and HAZARDS are drawn the same way.

**Also check:**
- anything else that throws yellow light on the bullseye (a SpotLight/SurfaceLight in Playground, LabDress or LabGarden, or a Highlight);
- any other box or plinth on the ground round the button (`BigButtonBase`) and the cannon (`CannonPad`) that reads as a box.

**Do:**
- Remove the light column. If "today's machine" is still shown, show it calmly: the small sign only, or nothing.
- Remove the zone boxes: tints, edge strips and floor text, for all zones, since they share one style and the paths in V7-2 take over the wayfinding. Keep the parking lines only if the capture shows they look good.
- Leave the machine parts alone where systems and tests rely on them (CannonPad, Bullseye, BigButton and so on). Make them look right instead: no box outlines.
- Update the tests that look for zones or the TodayLight (search `Tests/` for `Zone`, `TodayLight`, `LAB_ZONES`).

**Done when:**
- captures of the bullseye, the button and the cannon, from above and at eye height, show no yellow light and no boxes;
- the affected tests pass.

## V7-2 Paths to everything (lab and every map)
**Look.** Simple, natural-looking paths of dirt, gravel or worn stone:
- gently curving, with a width that varies a little;
- soft edges: grass overlaps the edge, with no hard rectangle outline;
- no text on the ground.

They lead from the spawn or arrival to each thing you can do there.

**Where:**
- **Lab:** spawn → cannon, bullseye, button, stations, tower, vehicles, creature yard, garden, portals. LabGarden's cobblestone `GardenPath` must match the new style or be replaced by it.
- **Plaza:** arrival → booths, boards, portals.
- **Island, City, Site, Farm, Military:** arrival → each MapActivities spot and the map-shop booths. City uses pavement/cobble where that fits, the farm dirt tracks, the site gravel, the base packed earth.

**How:**
- Where the ground is terrain, paint terrain materials just under the surface (Ground, Mud, Pavement, Cobblestone).
  - Mind the CLAUDE.md notes on terrain heights and on materials that read wrong from above (Pebble, Sand).
- Where the floor is parts, use flush thin parts or pieces with a dirt/gravel MaterialVariant, plus stones along the edge.
- Plan the routes as data (a pure module of points per place), so a test can check that every activity has a path and that no path runs through a machine or a wall.

**Budget:** a part budget per place for phones. Paths are pictures only (no collisions change), so the cars and ragdolls behave exactly as before.

**Done when:**
- a top-down capture and an eye-height capture per place;
- a test that every activity has a path, within the budget;
- the walking and driving tests still pass.

## V7-3 Birds on the ground, not in it
**Likely cause:** `Client/Birds`. A walking bird is placed with its **pivot** at `groundY + 0.05`, so a model whose pivot is in the middle of its body sinks halfway into the ground.

**Do:**
- Measure each bird model's feet offset once, from its bounding box at its `size` scale. Stand the feet on the ground.
- Make the ground ray ignore the birds, dummies, players and invisible/non-collidable parts, so a bird stands on the real floor or terrain.
- Birds that land on roofs, fences and wires sit on top, not inside.
- Flying birds never dip under ground + a margin.

**Done when:**
- a close capture of the pigeons in the lab, plaza and city, and of the perched birds, shows feet on the surface;
- T104 checks that a grounded bird's lowest point is within 0.15 studs of the floor.

## V7-4 Every ragdoll looks better
**Cover every ragdoll type:**
- the lab test dummies (white mannequins under LOOK_V3, `DummyFactory` and `Client/DummySkins`);
- the crowd on each map (`CrowdService`, roles Worker, Farmer, Soldier, Beachgoer, plus city people);
- the visitors (`VisitorService`) and the chasers (`ChaseService`);
- event bodies (GiantDummy, DummyRain);
- the paid skins (crash suit, gold dummies).

**Do:**
- **Mannequins:**
  - a better skin, such as a high-quality crash-test or mannequin mesh with PBR SurfaceAppearance;
  - clean joints and subtle details (seams, joint rings, a calm face shape);
  - no clipping or gaps at the joints while ragdolled.
- **People:** real Roblox clothing and accessories per role and map, so each crowd reads at a glance:
  - Worker: hard hat and hi-vis;
  - Farmer: overalls and straw hat;
  - Soldier: camo and helmet;
  - Beachgoer: swimwear, sunglasses and towel;
  - city: casual and office.

  Also:
  - variety in skin tone, hair, faces and body shape;
  - accessories that stay on (welded right) when ragdolled, so nothing floats.
- **Rules:**
  - no brands or logos, and mild, kid-safe content;
  - the server's physics bodies stay the same (looks are client-side where they are now), so the ragdoll feel, the hits and the tests don't change;
  - the low tier keeps its budget (LOD: simpler skins far away).

**Done when:**
- a line-up capture of every type (standing, ragdolled, dead/green), close up and at play distance, next to the leader;
- the blind reviewer passes it;
- the dummy and crowd tests pass (T36, T40 and the others that touch looks).

## State
- 20 Nov 2026: plan written (cloud). Nothing of V7 started. V6-1..V6-7 done and V6-8 started (see `docs/V6_PLAN.md`); V6-8 waits until V7 is done.
