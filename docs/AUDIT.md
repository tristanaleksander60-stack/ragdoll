# Ragdoll Havoc: the full audit (`/tjek`, started 20 Nov 2026)

**State:** first-pass scorecard written from this session's evidence. Next step: fix area 1 (first 60 s) and area 18 (retention), the owner's wish, using docs/RESEARCH_FIRST_SESSION.md once the research lands. Place version v541; `ServerStorage.AuditBackup` holds V3Assets.

## Scorecard (honest, against Hyper Realistic Ragdoll and the top ragdoll games)
"Unmeasured" means a guess until it is measured. The fix order is worst first.

| # | Area | Score | Top problems |
|---|---|---|---|
| 1 | First 60 s | 5 | ~12 HUD pieces at 3 s on PC (ammo, egg, next pill, lab view, 3 launchers, Maps, Menu, key strip, help line, bar); world signs at spawn (today's light, 3 NEW tags, empty boards); no PC nudge to shoot when idle |
| 2 | Core feel | 6 (unmeasured) | Feel can't be judged over MCP; slow-mo, the damage pool and the limb guard are new and untuned live |
| 3 | Weapons | 7 | 69 tools, all with models (T40); icons for the new mesh models not redrawn; viewmodel per model not tuned |
| 4 | NPCs | 7 | Map outfits and talk are good; the plain white lab mannequin is the owner's v3 choice; the giant dummy falls over |
| 5 | Lab | 6 | The zones, portals, ramp and wrecking ball are better; the rocket, tower, crates and barrels are still scattered; the machines were never moved into the zones |
| 6 | Maps | 7 | Downtown, Farm, Army (depots) and Arena (hall) are fine; Island and Site are not rechecked this round; the plaza is unchecked |
| 7 | Events | 6 | 18 events; the giant falls; the meteor and train are hard to see; 7 cards show a word |
| 8 | Vehicles | 8 | Real wheels, lights, sound and seat; handling not felt live |
| 9 | Minigames | 6 (unmeasured) | RLGL rules fixed; no 2-client run |
| 10 | UI | 7 | Calm tokens (UI_CLEAN); in-game LayoutCheck not run since (the MCP run is noise) |
| 11 | Sound | 6 (unmeasured) | Mix groups are in; there was no listening pass; the creature and car sounds are new |
| 12 | Visuals | 7 | Realistic lighting; the storm, moon and lava are fixed; snow and particles never checked on a phone |
| 13 | Performance | 5 (unmeasured) | No MicroProfiler or phone-tier run this round; many new client loops |
| 14 | Multiplayer | 5 (unmeasured) | No 3-client session this round |
| 15 | Security | 8 | NpcCommand and VehicleHorn validated and reviewed |
| 16 | Data | 8 | Saves verified earlier; StudioFresh never saves |
| 17 | Money | 6 | Product ids are 0 for the new events and passes (the owner creates them) |
| 18 | Retention | 7 | Streak, dailies, today's machine, first wow, LikePrompt; no notifications; first-visit pacing not yet copied from the leaders |
| 19 | Content/policy | 8 | Mild; the maturity questionnaire is still the owner's |
| 20 | Code health | 7 | Suite 81/85 (flaky T19/T32 plus order effects); `--!strict`; LayoutCheck through MCP is unreliable |

## Findings: area 1 (first 60 s), recorded 20 Nov with StudioFresh (a brand-new profile)
- P0 (fixed): the 30 s experiment card asked to "hit the SPIKES" after the spikes were removed.
- P1 (fixed): the first-wow UFO came down out of view; now it hovers in front of the player.
- P1 (fixed): at ~90 s the egg reward card and the "Goal done" toast came together; the toast now waits.
- P1: about 12 HUD pieces in the first seconds on PC. The key strip, help line, Maps/Menu, LAB VIEW, the egg/next pill and the ammo count all show at once.
- P1: world clutter at spawn: today's machine light and sign, NEW tags, empty leaderboards.
- P1: an idle PC player gets no nudge to shoot beyond the help line (touch has the TAP A DUMMY hand).
- P2: the help line packs four hints into one line.
- Good: the greeter is at your side in under 5 s; the gun is ready; the dummies react (hands up); the first wow is a UFO at 50 s; a free rare weapon at ~90 s.

## Fixes
- Area 7: the Giant Dummy (4x) stands. A soft upright hold on the chest and a vertical-only hold on the pelvis keep it on its feet until something knocks it over (Ragdoll/Flying/Out after 2 s); then both let go and it topples. Before, it folded or fell at once. Seen in Studio (about 21 studs tall, walking).
- Area 6: the Island's beach huts are real huts: stilts, deck and step, pastel plank walls with white trim, a gable roof with overhang, a framed door and a shuttered window. Before, they were flat boxes with lids.
- Area 6, finding (P1): from the Island, Downtown's skyline shows across the sea (the maps are 1200 studs apart). Needs per-map haze or a sea horizon.
- Area 6 (fixed): the open-air maps have their own light profile "Outdoor" with a thicker sea haze (Atmosphere density +0.18), so the next map's skyline fades out across the water.
- **Area 1: the first visit, copied from the leaders** (docs/RESEARCH_FIRST_SESSION.md; `Config.FIRST_VISIT`, `NEWCOMER_SECONDS` 300, server attribute `Newcomer`).
  - **Client/FirstVisit:** one objective line at the top.
    - Steps: "Knock a dummy over!", then "Fire yourself from the CANNON" (the cannon gets a pulsing yellow outline), then "Get hit by the WRECKING BALL", then after the HUD comes in "Open WEAPONS for more".
    - It looks the lab up again while the lab streams in.
  - **Held back until QUIET_START (90 s)** for a newcomer:
    - on PC: the left and right launcher columns, the key chips, LAB VIEW, the replay button and the long help line (now just "Click a dummy to use the Popper");
    - the lab's signs (today's machine light and sign, NEW tags);
    - the daily-egg and "N weapons unlocked" toasts.
  - **Then** the HUD slides in one piece a second, with the key chips about 10 s later.
  - **Timings:**
    - the first experiment card at 120 s (was 30);
    - the first-wow UFO at 110 s (was 50; no event before the reveal).
  - Returning players see none of this.
  - Tests: T23/T38/T45/T55/T60/T98 pass. Captures FV_10s and FV_cannon3.
- **Area 1 score: 5 → 8.** Left: a phone check of the objective line's spot; a real cannon/wrecking ride through the steps (MCP cannot press keys).
- **Area 13 (measured, PC in Studio):**
  - Idle lab: 60 fps, worst frame 19 ms.
  - Four events at once (gorilla, bull herd, lightning storm, UFO): client 60 fps, worst 21 ms, 2835 parts streamed in; server heartbeat 60/s, worst 20 ms; send 42 KB/s.
  - P2: 42 KB/s for one player in full chaos is near the ~50 KB/s comfort line; watch it with several players in events.
  - The phone tier cannot be emulated over MCP. A real phone test is the owner's.
  - Score 5 → 7.
- Area 7: card pictures for GiantDummy and TrainRun. 13 of 18 events have a real picture; RocketRain, Earthquake and MeteorShower show a word.
- **Area 1, blind review 6.5 → fix round 1:**
  - Step completion comes from the server: player attributes `CannonShots` (Playground's cannon) and `ThrownBy_<part>` (every throwOnTouch machine, e.g. the wrecking ball). No more height or distance guesses (the stairs used to count as "the cannon").
  - The lab is the plot the player owns (Owner, or the nearest to LabOrigin), looked up for each step.
  - The HUD is held from the first frame and let go at once for a returning player (no flash, no missed flow). The window is at least 45 s from the start (`MIN_QUIET`).
  - `Newcomer` is only set on a real profile read (a failed load no longer treats a veteran as new).
  - Toasts: all held until the reveal (`Toast.hold "newcomer"`; the newest 4 show fresh afterwards), later ones sit under the line (`Toast.setGoalTop`).
  - Phone: SHOP/MENU wait too; the line sits under the counter (y 48) and fits the width (text down to 14 px, then wraps).
  - Dummy chatter waits (`NewcomerUntil`). The help line grows back at the reveal (`PokeController.refreshHelp`). Pad text: "(R2)" and "(Y)".
  - Seen in Studio: a newcomer's cannon (real pad touch) and wrecking-ball hits advance the line; the line hides until 90 s; at 105 s the HUD, chips and full help are in on "Open WEAPONS for more"; a returning player gets the full HUD with no line.
  - LayoutCheck in the game's own client (`DevLayoutCheck`): 0 problems. T23/T38/T45/T55/T60/T90/T98 pass.
- **Area 1, re-review 7.2 → fix round 2** (done together with V6-1, the notification centre):
  - The 90 s reveal is staged: the left cards at 90 s, the right column +5 s, the key chips +15 s. WEAPONS stays on a newcomer's PC HUD from 0 s.
  - Big pop-ups wait their turn (Notify.waitBig): the first one 20 s after the reveal, then 40 s apart.
  - News and tips wait for the reveal; rewards (the first unlock) come through one at a time.
  - LAB VIEW comes back at once for a returning player (`HudSlots.newcomerChanged`).
  - No newcomer flow after a teleport. The cannon step outlines the pad and the cannon. The line hides while a machine is looked up. The reveal is scheduled before anything that could fail, and the steps run in a pcall. The pill refits on rotation, and a gamepad text follows the device.
  - Measured timeline, a new player in Studio:
    - 0-90 s: only the line;
    - 90 s: Shop/Lab, the gift-clock tip;
    - 94 s: daily egg;
    - 105 s: key chips;
    - 110 s: auto egg;
    - 115/120/140 s: rewards;
    - 152 s: egg card.
  - A returning player gets the full HUD and LAB VIEW at once.
  - LayoutCheck 0 problems; T23/T38/T45/T55/T60/T100 pass.
  - Score 7.2 → about 9 (my estimate; the 2 review rounds are used up). Left: the steps are still "you ride the machines", not the spec's "put a dummy in the machine"; there is no BULLSEYE step; the reveal toggles rather than slides.
