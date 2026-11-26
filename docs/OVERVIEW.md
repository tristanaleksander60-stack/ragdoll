# OVERVIEW: the whole plan on one page (read this FIRST on every /klar)
Updated 26 Nov 2026 (cloud). The work list is long and spread over many docs. This page is the map of it:
- the ORDER;
- where each part is described;
- what is done;
- what is LEFT.

Keep it short. When you finish or start something, update its line here (and the detail in its own doc).

## How to work (owner orders)
- **`/klar`:**
  - first the step 0 reminder;
  - then work down the ORDER below without stopping or asking the owner to test;
  - questions go into the NOW.md owner list with a safe default;
  - ONE Danish final message: what was built, "Tryk Alt+P" if needed, ONE "Test selv" list (phone first), and the questions.
- **Every item:**
  - phone and iPad first, simple enough for a 10-year-old;
  - gore OFF (purple cartoon, X-ray bones);
  - a Config switch for it;
  - one quick Play, then commit and push.
- **Do not publish** until the map meets its DEFINITION OF DONE (owner: "vent til det er helt færdigt"). Save the place after every step.
- **⚠ TWO PLACES:**
  - Studio currently has the **multiplayer place** (81638873302354) open, so saves go there. The **start place** (126037745825106) was last saved at v1129 (0.72).
  - Before the release, publish the same build to BOTH places: in Studio, File → Publish to Roblox As → each place → Overwrite, or through Open Cloud for both.
  - Tell the owner exactly which place is open.

## THE ORDER

| # | What | Doc | State | LEFT |
|---|---|---|---|---|
| 0 | **Owner:** Alt+P (gore off) and send the maturity questionnaire (deadline Fri 27 Nov 17:34 UTC) | `MATURITY.md`, `BODY_V2.md` "final answers" | waiting for the owner | owner only |
| 0.5 | **BUG: the 3 ragdolls near you spawn LYING DOWN when you join.** Spawn them standing (see the fix below) | `ALWAYS3.md` "Spawn standing" | DONE v76: `SPAWN_UPRIGHT` (LabOwnerMap sets every ragdoll inside the raised plaza on top of it, upright, once the map stands). Checked in Play: the 3 near the spawn stand (up 1.00, Walking/Standing) | the out-of-view spawning (item 10) |
| 0.6 | **Owner (26 Nov):** remove the SHOP kiosk on the plaza completely ("helt cooked"; it is gone from `OwnerMapPlan`; the SHOP button stays). **The LEADERBOARDS face the wrong way:** turn all 4 so their screens (SurfaceGui face) look SOUTH at the spawn and the stair; check from the spawn camera that the text reads the right way round, on PC and phone | `OwnerMapPlan` (regenerated) | DONE v76: kiosk removed (LabOwnerMap extras); the 4 boards turned: measured, their SurfaceGui faces now look +Z (south) to the spawn and the stair | check the text reads right on a phone |
| 0.7 | **Owner asked again (26 Nov): ragdolls at EVERY machine.** Build the watchers NOW: at least 1 standing and watching at every machine and attraction in `OwnerMapPlan` (sometimes 2-3), reacting when it runs, replaced within 10 s when knocked out or used, light stand-ins beyond 60 studs (the phone caps). Check: walk past every machine; none is without a watcher | `ALWAYS3.md` "Spectators at every machine" | not built | all |
| 0.8 | **NEVER ZERO (owner):** if a player has 0 living ragdolls within 35 studs for 1 s, one comes RUNNING at once (the nearest free one, or a new one spawned standing out of view), anywhere on the map | `ALWAYS3.md` "NEVER ZERO" | new | all |
| 0.9 | **They LOOK AT YOU when they talk to you** (eyes, then the head, then the body turns; they track you while talking; chatters look at each other) | `ALWAYS3.md` "LOOK AT YOU" | new | all |
| 1 | **THE MAP**, round 3: the master plan | `MAP_MASTERPLAN.md`, `Shared/OwnerMapPlan.luau`, `tools/masterplan.py`, `NOW.md` GO NOW | P1-P4 done (ground, roads, plazas, paths, lamps, set pieces and machines on plan spots, tree belts + arches, parks, backdrop forest/hills/mountains; 7680 parts) | the DEFINITION OF DONE captures and score (yards done v73, lint 0 small things on paths v72) |
| 1a | **Trees: no more all-green AI look** (real trunks, varied greens, mixed species, a good tree set; the forest backdrop too) | `MAP_MASTERPLAN.md` rule 5b | new | all |
| 1b | **The RACETRACK** in the empty south INSIDE the current map (owner: do NOT make the map bigger; measure the free area and fit the track to it): a big F1 circuit (kerbs, run-off, barriers, gantry with start lights, pits, grandstands), a free go-kart, the **F1 RACER pass** car from the Creator Store (with scripts, security-checked), lap timing, best-lap boards, ghost, marshal ragdolls | `RACETRACK.md` | new | all; the owner creates the F1 RACER game pass and sends the id |
| 1c | **Ragdolls walking the roads in 2s and 3s, stopping to chat** (outer avenues, boulevard, station and track paths) | `LIFE_IDLE.md` section 3 | new | all |
| 1d | **The brick wall breaks ONE BRICK AT A TIME with gravity** (cascade, not all at once; hybrid panels, sleeping bricks, caps: lag-free on every device); concrete walls block by block (2c) and wooden crates plank by plank with toppling stacks (2d) | `DESTRUCTION.md` 2b-2d | new | all |
| 1e | **DETAIL PASS to 10/10, lag-free:** an audit script for primitive props (balls as flowers, etc.), z-fighting flicker, floating and overlapping; replace flower beds, bushes, rocks, benches, signs, fences, food, car-park cars, loungers, playground, seats and rail with real instanced meshes; ground detail; small life | `DETAILS_10.md` | new | all |
| 2 | Solo labs in the start place, one shared lab in multiplayer | `FIXES_26NOV.md` F30 | check | all of F30; tell the owner: start place server size 1 |
| 3 | **MACHINES, ANIMALS, ACTIVITIES to 10/10** (the SATISFY-10 standard, 35 items in priority order) | `MACHINES_10.md` | new | everything, in its order (cannon → tower → gyro → fan → …) |
| 4 | Bones and X-ray: every bone breakable, the real bullet path, shattering, the angry dummy 1-3 shoves | `FIXES_26NOV.md` F26-F29, `BODY_V2.md` 1/1b | check what 0.7x built | F26-F29; X-ray glass shell + blue outline + mesh skeleton |
| 5 | Perfect physics + the smooth skinned body with real fingers | `RAGDOLL_FEEL.md`, `BODY_V2.md` 4c | part 1 (force-scaled push) | the impulse at the hit point; tone per limb; rest-sleep; piles; buoyancy; get-ups; the skinned body; fingers; the 5 bench clips |
| 6 | The body look: blood puddles, injury stages, bandages, 11 faces | `BODY_V2.md` 2, 4b | partly (holes, splatter) | puddle look, stages, bandages, faces |
| 7 | Impact effects | `IMPACT_FX.md` | part 1 (dust, SLAM) | smoke trail, scuff decals, props react, shake/hit-stop on own slams |
| 8 | Phones and tablets: less lag | `PERF_MOBILE.md` | not started | measure, top 5 costs, auto quality |
| 9 | The first 2 minutes | `FIRST_2_MIN.md` | built 0.60 | per-machine load spots; walk-to-start for machines without a load spot |
| 10 | Always 3 near + watchers | `ALWAYS3.md` | 3-near done | spawning out of view (the watchers moved up to 0.7) |
| 11 | Human idle life + the cyclist | `LIFE_IDLE.md` | not started | all |
| 12 | Lasso + breakable concrete and brick walls | `DESTRUCTION.md` | crates done | lasso, walls |
| 13 | Guard dog polish | `GUARD_DOG.md`, F22, `MACHINES_10.md` 3.11 | built (Shepherd, gaits) | tooth marks, X-ray jaws, limb reactions, sounds, pet |
| 14 | Wheelchairs | `WHEELCHAIRS.md` | parked (no model) | get a model; build |
| 15 | Multiplayer window on phones | `NOW.md` MP icon | icon done | the phone layout of the window |
| 16 | Session length, the rest | `STAY_LONGER.md` | gift clock, try reward, surprises, daily line done | pacing check, the long goal after weapons (ranks with prizes), A/B shared servers, experience notifications |
| 17 | Burial funnel steps | `BODY_V2.md` 4 | built | funnel steps |

## Already DONE (do not redo)
- Gore off (0.58).
- 3 near you (0.59, 0.61).
- MP icon (0.59).
- The first 2 minutes + TRY once (0.60, 0.70).
- Surprises every 2 min.
- Daily line.
- Fix list F1-F25 (0.70-0.76; F4 and F10 part 1).
- Crates (0.65).
- Burial + revenge (0.66).
- Guard dog (0.67, Shepherd).
- Map rounds 1-2.
- Map round 3 P1-P3.

## Owner decisions in force
- **The map size stays as it is now, mountains included.** Do not make it bigger.
- **Build EVERYTHING in one run without stopping; the owner tests only at the end** (26 Nov 2026).
- Script Sync: do not wait; use the MCP.
- The dog: find a rigged German Shepherd in the Creator Store yourself.
- Purple blood; gore off; X-ray bone breaks and shatters allowed.
- Spawn on the raised leaderboard plaza.
- The map is the owner's own layout made 10x bigger, now as explorable rooms (round 3 master plan).
- B/I for X-RAY: the key is I.
- REVIVE ALL is X.
- No 3D turning icons on the bar.
- Mech arms removed.
- Publish only when the map is done.
