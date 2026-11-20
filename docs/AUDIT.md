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
