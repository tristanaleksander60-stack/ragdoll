# MAP ROUND 3: the master plan (owner, 26 Nov 2026: "Det her map er 1/10, sørg for det bliver 10/10")
> "Stierne connecter ikke med tingene ordentligt. Sørg for alle de stier er meget større og pænere, put flere træer ind og skift dem ud med de grimme træer vi har nu. Meningen er man ikke skal se alt på en gang så man får lyst til at gå ud og udforske. Gør så akvariet ikke står halvt inde i spawn. Fjern lygtepælen fra vandet og fra spawn."

**What went wrong.** The map was built as a straight grid with things dropped into big open plots.
- Walkways stop short of things, run past them, or sit on top of the old paving.
- From anywhere you see everything at once, so there is nothing to discover.
- The trees are balls on sticks.
- A lamp stands in the pool and another on the spawn.
- The aquarium cuts into the spawn plaza.

**The fix:** a real layout designed first, then built exactly. The layout is already done and checked:
- `tools/masterplan.py`: the one source; it lints itself;
- `ReplicatedStorage/.../Shared/OwnerMapPlan.luau`: the generated data the builder reads;
- `art/store/lab10/masterplan.png`: the top view.

Rebuild `Systems/LabOwnerMap` FROM `OwnerMapPlan`. Do not hand-place anything that the plan places.

## The idea: a park of ROOMS you explore
- **The spawn plaza** (raised, north, with the 4 boards, MAPS and a shop kiosk) looks straight down a wide **boulevard** past a fountain to the **Tower Square**. The 95-high tower is the landmark seen from everywhere.
- **8 themed ROOMS:** Animal Cove, Splash Zone, Crash Yard, Car Park, Machine Hall, Fun Fair, Launch Field and Danger Zone.
  - Each is **walled by a thick belt of trees and bushes** (18 studs).
  - You enter only through its **openings**, which have an arch sign with its pictogram.
  - Inside, a small paved **courtyard** leads by paths to the front of every attraction.
- **You never see everything at once:**
  - from the spawn you see the boulevard, the fountain, the tower, and only glimpses of tall things over the trees (the fan, the rocket gantry, the gyro rings);
  - the rest you discover by walking in.
- **Open, framed areas:** the Spawn Gardens, the Lawns and the Picnic Park are framed by low hedges along the roads (flower beds, benches, a few trees). The tall tree belts on their outer sides keep the rooms hidden.
- **The outer loop:** an avenue round the rooms (the cyclist rides it), then the railway (west, south and east) with a train and a station at the south end, the hangar, the water tower, the control tower, and the hills outside.

## The rules the builder MUST follow
1. **Positions:**
   - every room, road, plaza, inner path and item comes from `OwnerMapPlan` (lab-space studs; x east, z south);
   - `face` is the side the thing's front looks to;
   - the item's `size` is its footprint: place the thing inside it, centred, and let it fill it (scale set pieces up or down to fill it nicely).
2. **Roads and paths: big, clean, connected.**
   - **Widths:** the boulevard 36; the cross roads 26; the spurs into rooms 14; the inner paths 12; the avenues 16.
   - **Look:** large light-grey concrete slabs with thin dark joints (a texture, not tile parts), a low kerb on both edges, and a slightly raised surface. Round, paved junction plazas where roads meet.
   - **Every path ENDS AT something:** a plaza, a courtyard, or the front pad of an attraction. Extend the last leg of each inner path until its end meets the attraction's pad, with no gap and no overlap.
   - Where two inner paths run side by side, merge them into one.
   - **Remove ALL old walkways and paving** (the old grid, the brick-pattern paving, the stubs) under `LAB_OWNERMAP`.
3. **Nothing on paths, nothing in water, nothing on the spawn.** No lamp, tree, bench, prop, ragdoll spawn or rope may stand on a road, path, plaza centre, pool, pond, lava, sand or pad. A lint script raycasts every road, path and water surface and lists anything there; the list must be empty.
4. **Lamps:**
   - only along road and path edges, 2 studs outside the kerb, every 32 studs, alternating sides;
   - none within 8 studs of water, pads, plazas' centres or the spawn;
   - one style, a classic park lamp.
5. **Trees: new, good, many.**
   - Replace ALL the ball-on-a-stick trees and stacked-ball bushes with a good low-poly tree set from the Creator Store: 3-4 broadleaf species (oak, birch, maple), 2 pines, and 2-3 bush types. One matching style; malware pass on each.
   - Vary the size (±25 %) and turn them randomly.
   - **The tree belts:** 2-3 staggered rows of trees with bushes underneath, so you cannot see through at eye height. They are broken only at the room openings.
   - Also groves in the open areas, trees along the boulevard, and flower beds and hedges round the plazas.
   - Performance: meshes, CanCollide off for leaves, CastShadow only on the big ones near you.
6. **Fill every room:**
   - each attraction stands on a pad that fits it, with its yard dressing (2 lamps at its path end, 1-2 benches facing it, a cluster of fitting props, its sign, its watchers);
   - each courtyard has a bench, a bin, a lamp and a signpost pointing to the room's attractions;
   - no empty grass bigger than about 40 x 40 inside a room.
7. **The aquarium** is in Animal Cove (plan), far from the spawn. The spawn plaza holds only the plan's spawn items.
8. **Height:**
   - the spawn plaza is raised 4 studs, with a wide stair down to the boulevard;
   - the rooms are gently raised or sunk (±1-2 studs) with small slopes at their openings, so the ground is not dead flat.
9. **Re-hook everything** to the new positions: every machine and its load spot, the creatures, the cars, the bike and cyclist loop (the avenues and roads), the doghouse, TRY and the first machine, the 3-near ragdolls, the watchers, the leaderboards, MAPS, the weapon range and the train.

## Check (part of the DEFINITION OF DONE)
1. Run `python3 tools/masterplan.py` after any plan change. It must say nothing but the two file paths.
2. **In Studio, the lint script must report 0 of each:**
   - things on paths, roads or water;
   - paths that end in the grass;
   - old paving left;
   - ball trees left.
3. **Captures:**
   - a top view next to `masterplan.png`;
   - the spawn view (you see the boulevard, the fountain and the tower; the rooms are hidden);
   - one view inside each room.
4. **Harsh score:** 9.5+ on clean, connected, explore-worthy, full and beautiful.
