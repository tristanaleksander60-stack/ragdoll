# Fix: square bushes, grey strips through the paths, paths that stop + all purchases live (owner, 21 Nov 2026)

## The owner's words (verbatim)
> Lav nu en plan for claude code til at fikse følgene: Firkanet kedlige buske, og grå ting der går igennem stien, stien stopper også. Samt skriv til mig præsic hvad jeg skal oprette i dev passes og hvor henne og hvad jeg skal sende til dig så vi får alle køb op

The owner sent a screenshot from the lab (0.29.0):
- **Bushes:** they are boxy green blocks with a yellow dot on top, standing on the grass verge.
- **Grey strips:** thin grey strips run through the sandstone path and across the round plaza.
- **Path ends:** a path stops dead in the grass.

**Order.** Run this before the next V8 step. Publish through `docs/RELEASE.md` when it is done.

## F1 Real bushes, not boxes
- **Find them.** They are most likely the verge "bush clumps" and flowers in `PathBuilder.dressLine` (`PATHS_V3` / `LAYOUT_V2`). Also check LabGarden, Landscape and LabDress for any bush built from Part, Ball or Block.
- **Replace every one** with real foliage models:
  - V3Assets `Bush` / `FlowerBed`, or better Creator Store bushes with soft leaf meshes, in one style that matches the garden;
  - run the malware pass on every insert;
  - vary the size by about ±20 % and the yaw at random;
  - sink each one 0.2-0.4 studs so it grows out of the ground.
- **Flowers:** real flower meshes, or none. No coloured ball on a cube.
- **Settings:** no collision, CastShadow off on small ones, and the same budget as now (`DRESS_MAX`).
- **Also replace any other code-built nature** in the lab, plaza and maps: block trees, ball bushes, cube rocks.

## F2 No grey strips through the paths
- **Find every grey part that crosses or touches a path** in the lab and on the plaza. Likely suspects:
  - leftover edge strips of the older path layers (PATHS v1 stones, PATHS_V3 slabs, LAYOUT_V2 slabs over each other);
  - the old concrete lanes / `Lanes`;
  - LabZones remnants;
  - the plaza's floor border (WorldMaps.dress);
  - baseplate seams (BaseplateEast/West);
  - the lab's old floor tiles.

  Use a script: raycast a grid over every path and list every non-path part hit within 0.5 studs of its surface.
- **Fix it.** Remove what is not needed, and lower or cut what must stay, so the paving is the only thing on top. A path with an edge gets a proper border: soil or the raised grass verge, never a grey line.
- **Plaza circle:** no strip across it.

## F3 Paths that go somewhere
- **Every path ends at a thing** (machine, creature, portal, stairs, booth, bench, spawn plaza) or joins another path. Nothing ends in the grass.
  - Extend or join each dead end, or end it in a small round landing at the thing.
- **Joins and corners:** where two paths meet, the paving is one smooth piece (a rounded join), not two slabs overlapping with gaps.
- **Test:** extend T106 (or a new T150_PathEnds). It walks `PathPlan`, checks every end node is within 3 studs of a named target or another path, and checks that no non-path part pokes above the paving.

## F4 Picture check
- **Captures** from the spawn, the plaza circle, the garden walks, the creature yard and 2 map arrivals. Take them on PC and on a phone, before and after.
- **Blind reviewer:** pass bar 8.5. The owner's screenshot angle must look clean.
- **The same check on the plaza and the open-air maps:** grey strips, ends, square bushes.

## F5 Purchases: pictures and ids
**Make the pictures.**
- Make a 512x512 picture for every pass and product that is still 0, in the same style as `art/shop/*.png`, and save them in `art/shop/` (file name = key in lower case).
- The 16 events already have pictures in `art/events/*.jpg`. Make 512x512 square versions of them in `art/shop/event_<id>.png`.
- Make the 3 missing badges in `art/badges/`.

**Check what is for sale.**
- `Shop.STARTER_PACK` (R$29, eggs) looks replaced by the `EntryPack` "Starter Crate" in OFFERS, and V8 removed eggs from Robux.
- If it is no longer used, hide it and remove it from the owner list.
- Also check whether V8-2.9 will cut events. Events that will be cut must not be sold.

**When the owner sends ids**, paste each one into its place:
- `Shop.OFFERS[...].id`;
- `Events.luau` `productId`;
- `Badges.luau` `id`;
- `Shop.GROUP_ID`.

Then:
- run T68, T105 and T65;
- test-buy one pass and one product in Studio;
- publish through RELEASE.md.

Ids are not secrets; they can be pasted in chat.

## State
- 21 Nov 2026: plan written (cloud). Nothing done.
