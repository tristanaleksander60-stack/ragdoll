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
| 1 | **THE MAP**, round 3: the master plan | `MAP_MASTERPLAN.md`, `Shared/OwnerMapPlan.luau`, `tools/masterplan.py`, `NOW.md` GO NOW | P1-P3 done (ground, roads, plazas, paths, lamps, set pieces and machines on plan spots) | new tree set + belts; room yard dressing and fill; the BACKDROP (forest, terrain hills, mountains, sky); lint 0; the DEFINITION OF DONE captures |
| 2 | Solo labs in the start place, one shared lab in multiplayer | `FIXES_26NOV.md` F30 | check | all of F30; tell the owner: start place server size 1 |
| 3 | **MACHINES, ANIMALS, ACTIVITIES to 10/10** (the SATISFY-10 standard, 35 items in priority order) | `MACHINES_10.md` | new | everything, in its order (cannon → tower → gyro → fan → …) |
| 4 | Bones and X-ray: every bone breakable, the real bullet path, shattering, the angry dummy 1-3 shoves | `FIXES_26NOV.md` F26-F29, `BODY_V2.md` 1/1b | check what 0.7x built | F26-F29; X-ray glass shell + blue outline + mesh skeleton |
| 5 | Perfect physics + the smooth skinned body with real fingers | `RAGDOLL_FEEL.md`, `BODY_V2.md` 4c | part 1 (force-scaled push) | the impulse at the hit point; tone per limb; rest-sleep; piles; buoyancy; get-ups; the skinned body; fingers; the 5 bench clips |
| 6 | The body look: blood puddles, injury stages, bandages, 11 faces | `BODY_V2.md` 2, 4b | partly (holes, splatter) | puddle look, stages, bandages, faces |
| 7 | Impact effects | `IMPACT_FX.md` | part 1 (dust, SLAM) | smoke trail, scuff decals, props react, shake/hit-stop on own slams |
| 8 | Phones and tablets: less lag | `PERF_MOBILE.md` | not started | measure, top 5 costs, auto quality |
| 9 | The first 2 minutes | `FIRST_2_MIN.md` | built 0.60 | per-machine load spots; walk-to-start for machines without a load spot |
| 10 | Always 3 near + watchers | `ALWAYS3.md` | 3-near done | watchers at every machine (light stand-ins far away); spawning out of view |
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
- Purple blood; gore off; X-ray bone breaks and shatters allowed.
- Spawn on the raised leaderboard plaza.
- The map is the owner's own layout made 10x bigger, now as explorable rooms (round 3 master plan).
- B/I for X-RAY: the key is I.
- REVIVE ALL is X.
- No 3D turning icons on the bar.
- Mech arms removed.
- Publish only when the map is done.
