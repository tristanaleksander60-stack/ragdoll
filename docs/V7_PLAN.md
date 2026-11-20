# V7: the owner's fixes of 20 Nov 2026 (late evening)

## The owner's words (verbatim)
> Fjern det mærkelige gule lys som lyser ned på bullseye
> Fjern boksene rundt om den røde knap og kanonen på jorden. Lav flotte simple stier på gulvet/jorden af jord osv rundt i ens lab og de andre maps til de forskellige ting man kan lave de steder.
> Gør så fuglene ikke går halvt nede i jordene.
> alle ragdolls skal se bedre ud, både tøj og detaljer og alt
>
> (Added the same evening) Også put ind i planen at de nofikationer der kommer som fx rolling studios sent zero g og ens næste mission osv skal gøres meget pænere og vurder alt på ens skærm om det er det rigtige sted på alle platforme tlf console pc osv

## Item map
| # | Request | Step |
|---|---|---|
| 1 | Remove the strange yellow light shining down on the bullseye | V7-1 |
| 2 | Remove the boxes on the ground round the red button and the cannon | V7-1 |
| 3 | Nice, simple paths (dirt and so on) in the lab and on the other maps, leading to the things to do there | V7-2 |
| 4 | Birds must not walk half sunk into the ground | V7-3 |
| 5 | Every ragdoll must look better: clothes, details, everything | V7-4 |
| 6 | The notices that pop up (e.g. "<player> sent ZERO G", your next mission) must look much nicer | V7-5 |
| 7 | Judge everything on the screen: is it in the right place on every platform (phone, console, PC and so on)? | V7-6 |
| 8 | Publish automatically when done, and run the whole plan in one go on "klar" | Release (`docs/RELEASE.md`) |

**Order:**
1. V7 goes first, even though V6-8 (graphics) is under way. Commit and push what is done of V6-8, and note it in V6 State.
2. Then V7-1 to V7-6.
3. Then back to V6-8 in `docs/V6_PLAN.md`.
4. Then the release: `docs/RELEASE.md` (gate → publish by itself → restart old servers → check → Danish report).

One `/klar` runs all of this in one go, without waiting for the owner between steps (owner order 20 Nov 2026).

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

## V7-5 Much nicer notices: event banners and the next mission
**What it covers:** every message that appears on the screen by itself. This includes:
- the event banner when someone starts an event ("<player> sent ZERO G", Gorilla Rampage, Mega Bomb and so on), sent by `EventService.broadcast` and drawn in `Client/EventShop`;
- the experiment / next-mission card (`Client/ExperimentCard`) and its done, late and combo pops;
- toasts and rewards (`Client/Toast`, which `Client/Notify` routes);
- the chase bar, the arena lines, the nuke banner, level-up, "+1 TAKEDOWN", gift and egg notes, What's New, and the Experience Notifications opt-in.

**Look (one hand-made family, like the leader's calm HUD):**
- **Event banner:** a short, premium card that slides in from the top. It has:
  - the event's real picture (`art/events`);
  - the event name in big type;
  - a small line with who sent it (display name, no "@");
  - a thin countdown line instead of a big number;
  - a soft whoosh through SoundMix.

  It shrinks into a small corner chip after 3 s while the event runs.
- **Next mission:** a compact card with an icon, one short goal line and a progress bar that fills smoothly.
  - Done = a quick tick + stars pop, then the next card slides in.
  - It never covers the action in the middle.
- **Everywhere:**
  - one font pair, the UI_V2 tokens, gentle easing (no bouncy spam), a drop shadow, and the same corner radius;
  - an icon on every message, and text no longer than one line where possible;
  - the same look on a phone at the touch floor;
  - no all-caps shouting walls of text;
  - `Notify`'s rules (queue, gaps, newcomer quiet) stay as they are.
- Replace anything that still looks like the old dark-glass or debug style.

**Done when:**
- before/after captures of each kind (PC, phone landscape, phone portrait, console);
- the blind reviewer passes it;
- LayoutCheck shows 0 problems;
- T100 still passes.

## V7-6 Everything on the screen in the right place, on every platform
**Which screens.** Audit every HUD piece, button, card, window and notice on:
- **phone:** small and big; landscape and portrait; with a notch or rounded corners;
- **tablet**;
- **console:** a TV at a 10-foot view with a gamepad, 1080p and 4K;
- **PC:** 1366x768, 1920x1080, 1440p and ultrawide.

**Check each against these rules:**
- **Safe area:** nothing under the notch, the Roblox top bar or the TV edges. Use ScreenInsets (`CoreUISafeInsets` / `DeviceSafeInsets`) and GuiService insets.
- **Thumbs and controls:** on a phone, nothing sits under the thumbs or the move stick, and touch targets are at least 44 px.
- **Console:** text is big enough to read from the sofa, and gamepad focus reaches every button in a sensible order.
- **Layout:**
  - nothing overlaps;
  - the middle of the screen stays free for the action;
  - things that belong together sit together;
  - the first minute shows only what matters (the HudSlots and Notify rules).
- **Platform fit:** the same piece sits in the place players of that platform expect:
  - phone: actions bottom right;
  - PC: key chips;
  - console: glyphs.

**Do:**
- Write the audit as a table in `docs/AUDIT.md` (piece × platform: OK, or the problem).
- Move, resize or hide what is wrong, through the existing layout code (HudSlots, PokeController, HudV3/HudGate, Toast.setMinTop and so on), never with one-off offsets.
- Add the new pieces and the console sizes to LayoutCheck, so this can never slide back.
- Use the device emulator for each size and the gamepad for console.

**Done when:**
- a capture grid (every platform, first minute and mid-game) shows every piece in its right place;
- LayoutCheck covers the console sizes and shows 0 problems;
- the blind reviewer passes it.

## State
- 20 Nov 2026: plan written (cloud). Nothing of V7 started. V6-1..V6-7 done and V6-8 started (see `docs/V6_PLAN.md`); V6-8 waits until V7 is done.
- **V7-1 done (20 Nov):**
  - The yellow light column over today's machine is gone (`Config.TODAY_LIGHT` false). The small TODAY'S MACHINE sign stays.
  - The painted floor boxes are gone (`Config.ZONE_FLOOR` false): the zone tints, edge lines, floor names and parking lines, which included the red box round the BIG RED BUTTON and the orange one round the cannon.
  - The 30x30 hazard box round the spinning mace goes with them.
  - The machines themselves (CannonPad, Bullseye, BigButton, stations, lava rim) are untouched.
  - T99 checks that no boxes or light column are left and waits for the lab to be built; T99/T23/T50 pass.
  - Captures: v7_1_after (above) and v7_1_after2 (eye height).
  - Studio's viewport had gone white (an Assistant plugin version change); Studio was restarted from the saved place (v577).
- **V7-2 done (20 Nov, `Config.PATHS`):** `Shared/PathPlan` (pure: routes, gently bowed curves, widths that vary, budget 400 stones per lab) and `Server/Systems/PathBuilder`.
  - **Lab:** earthen paths of overlapping flat stones, with a few pebbles at the edges. They run from the hub in front of the spawn to the cannon, button, stations, bullseye, lava, mace, tower, portals, wrecking ball, creature yard and both gardens (12 routes, about 330 stones). The garden walks are curving cobbled trails in the same style.
  - **Plaza and open-air maps:** from the arrival to every launcher and every shop booth.
    - On terrain, the grass and sand under the path are repainted (`ReplaceMaterial`; the ground's shape never changes): Ground (warm brown) on the Island, Farm and Army; Mud on the Site; Cobblestone on the plaza and in the City.
    - Where there is no terrain (the City streets, the plaza floor), flat cobbled stones are laid instead (Workspace.MapPaths).
  - Everything is pictures only: no collision, no query, no touch.
  - **Tests:** T106 passes (every route reaches its goal, within budget, non-colliding, painted on every place); T26/T31 pass.
  - **Captures:** v7_2_lab_top, v7_2_lab_eye2, v7_2_farm.
- **V7-3 done (20 Nov):**
  - A walking bird stands on its feet: its pivot is lifted by its own measured feet offset (`Birds.feetOffset`, the bounding box at its size) instead of sitting at ground + 0.05. Before, the pigeons sank to mid-body.
  - The ground ray now skips the birds, every player, the dummies, and any see-through or walk-through part (up to 4 layers down), so a bird stands on the real floor or the terrain.
  - Flying birds keep ground + 8.
  - **Tests:** T104 checks that a grounded bird's lowest point is within 0.15 studs of the floor. Passes.
  - **Capture:** v7_3_pigeon.
  - Not built: perching on roofs, fences and wires (the birds never perch yet, so none sinks into a roof).
- **V7-4 done (part, 20 Nov):** the lab mannequins (and every body made by DummyFactory with `Mannequin`: GiantDummy, DummyRain, the event guests) are crash-test dummies now (`DummySkins.DETAILS`). Client-side and welded, so there is no network or physics change:
  - thin dark rings at the elbows, knees and ankles;
  - a belt at the waist;
  - the yellow and black crash-test target on both sides of the head and on the chest (art/dummy/target.png, asset 91578612138787).

  They stay white (the owner's v3 choice). The rings hide with the body in a lab creature (MachineHidden) and the dead green still reads.
  - **Tests:** T36/T40/T91 pass.
  - **Captures:** v7_4_before, v7_4_after2.
  - **Left:** the map crowds keep their M11 role outfits (real Roblox clothes and hair per role). A new per-role accessory pass (hard hats, straw hats, helmets, sunglasses) and a LOD for the rings are not done.
