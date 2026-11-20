# V6: the owner's list of 20 Nov 2026 (evening)

## The owner's words (verbatim)
> Nofikationer / pop ups. Forbedret admin menu og tilføj en director menu som jeg kan bruge til at optage tiktoks med fra min telefon på min computerskærm. Mange flere sjove forskellige ting, edderkop man kan fodre med Ragdolls og ting som det. Forstør ens lab, gør det smukt æstetisk og hyggeligt og gør så man ikke kan se hinandens lab. Tilføj en masse ting man kan købe rundt på de forskellige maps til robux, gør meget ud af præsentationen og modellen så de betaler for noget der rent faktisk ser perfekt ud og er perfekt på alle parametre. Tilføj forskellige fugle der flyver rundt omkring ens lab og andre maps udenfor. Gør kvaliteten af grafikken 100x bedre i forhold til modeller maps osv.

## Item map
| # | Request | Step |
|---|---|---|
| 1 | Notifications / pop-ups | V6-1 |
| 2 | Better admin menu | V6-2 |
| 3 | Director menu for filming TikToks (phone pointed at the PC screen) | V6-3 |
| 4 | A bigger lab: beautiful, aesthetic, cosy | V6-4 |
| 5 | Nobody can see another player's lab | V6-4 |
| 6 | Many more fun things: a spider you feed ragdolls to, and the like | V6-5 |
| 7 | Birds flying round the lab and the outdoor maps | V6-6 |
| 8 | Lots of things to buy for Robux on the maps, presented and modelled perfectly | V6-7 |
| 9 | Graphics 100x better (models, maps) | V6-8, and as a rule in every step |

Order: finish any half-done V5 step first (see `docs/V5_PLAN.md` State), then V6-1 to V6-8.

## Rules for every step
- **Before/after captures** from fixed angles, judged against Hyper Realistic Ragdoll. Nothing may look code-built, cheap or "AI".
- **Real Creator Store models** in one style, with the **malware pass** on every insert. Put what exists only in the place file into the State line, and remind the owner to save.
- **Settings:** Config switches, numbers in Config, and the server decides. Remotes go through `Net` with validators and rate limits, and are listed in `CLAUDE.md`.
- **Phones:** the budget holds on the low tier, LayoutCheck shows 0 problems, and touch targets are at least 44 px.
- **Content:** mild and kid-safe (no gore: nothing is eaten bloodily; things get swallowed and spat out in a cartoon way).
- **Tests and review:** a `T9x` self-test per new system, and one blind reviewer per step (pass bar 8.5).
- **After each step:** commit and push `release`, update State, and send a short Danish report (Lavet / Test selv / Brug for fra dig).

## V6-1 Notifications and pop-ups
- **Audit.** List every toast, card, banner, prompt and window that can appear by itself: gifts, eggs, experiments, events, like/favourite, tips, chase, deals and so on. Note when each appears and how often, in the first 10 minutes for a new player and for a returning one.
- **One notification centre** (`Client/Notify`):
  - a queue with priorities (critical, reward, info, tip);
  - at most one big pop-up at a time;
  - nothing in the first 60-90 s except the goal;
  - a quiet period after a window closes;
  - a dedupe rule;
  - "don't show again" for tips.
- **One clean look:** a small card from the top, an icon, one line, an auto-hide time set by the text length, swipe or click to dismiss, and a soft sound through SoundMix.
- **Roblox Experience Notifications:** if the API is available, ask for opt-in after a good moment (never on join) for "your daily reward is ready" and "a new update is out". Follow Roblox policy.
- **Done when:**
  - a capture of a 10-minute timeline (new and returning player) with no pop-up spam;
  - LayoutCheck shows 0 problems;
  - a T9x test checks the queue rules.

## V6-2 Better admin menu (owner only)
Rebuild the admin menu as one clean, tabbed window (owner-only, checked on the server). Tabs:
- **Server:** events, all weapons for everyone, gravity, time of day, weather, kick (with a reason), announcements from a fixed list;
- **Players:** spectate, teleport to them, bring them, give a weapon trial;
- **World:** reset a lab, clear props, revive all, spawn N dummies, set crowd counts;
- **Debug:** FPS, memory, part and ragdoll counts, remote rates, the last errors.

Rules:
- Every action is logged in the output.
- Nothing is free-form text in the world.
- Nothing writes to live DataStores beyond what already exists.

**Done when:** a capture of every tab, each action tried once, and a T9x test that a non-owner is refused.

## V6-3 Director menu (owner only) for filming TikToks
The owner films the PC screen with a phone, so everything must read well in **9:16**.
1. **Director mode (toggle F8, owner only):**
   - hides every game UI;
   - shows a 9:16 safe-frame overlay (switchable) and a small director panel that hides itself while recording ("REC" hide key).
2. **Cameras:**
   - free fly (WASD/QE, mouse look, speed wheel);
   - orbit a target;
   - follow a dummy or a player, smooth chase or locked;
   - a drone/top-down view;
   - first person;
   - **camera paths** (set 2-6 points and play a smooth spline with an ease and a duration);
   - FOV and depth-of-field sliders;
   - shake on or off.
3. **Time:** slow-mo (0.1-1x on the own-client visual time, as in C5), freeze frame, step.
4. **Action buttons:**
   - spawn dummies in a row, a ring or a tower;
   - launch the selected dummy;
   - trigger any event or surprise (lab-local);
   - drop props;
   - reset everything in 1 click;
   - "replay the last 10 s" from the X-ray replay with the director camera.
5. **Presets:** save and load 5 shot setups (camera, time, spawn) on the owner profile, with a key for each.
6. **One-tap TikTok shots:**
   - cannon launch;
   - car through a dummy row;
   - feeding the spider;
   - the gorilla;
   - a tower throw;
   - a mega bomb in slow-mo.

   Each one sets the camera, spawns, triggers and plays.

**Done when:** the owner can film all 6 one-tap shots, captures in 9:16 framing, no UI visible, and a T9x test of owner-only access.

## V6-4 A bigger, beautiful and private lab
- **Size:** make the plot larger, about +50 % area (`Lab.PLOT_HALF` / `PLOT_SPACING`, with matching floors, zones, spawns and tests).
- **Landscaped:**
  - grass and flower beds, real trees and hedges along the edges;
  - stone paths between the zones;
  - a small workshop or garage building;
  - benches;
  - warm garden lights and lamp posts at dusk;
  - a fountain or pond;
  - fences with hedges.
- **Cosy and calm:** soft warm lighting, a cosy colour palette, ambient birdsong and wind (SoundMix Ambient).
- **Privacy:** no player can see another player's lab.
  - Tall hedge or hill walls with terrain hills between the plots.
  - PlotPrivacy hides other labs client-side, and streaming/LOD keeps them away.
  - Friends invited in can see.
  - Check with 3 clients that nobody sees another lab from anywhere, including the tower top, the cannon flight and the car.
- **Done when:**
  - before/after captures from 5 spots;
  - the 3-client privacy check;
  - phone frame time OK;
  - lab tests updated.

## V6-5 Many more fun things (lab creatures and machines)
**Headliner: a giant cartoon spider** in a web corner of the lab.
- Drop or throw a dummy into its web: it wraps the dummy in silk with a funny wiggle, munches it (cartoon, no gore) and spits it out wrapped like a burrito, launching it across the lab.
- It has a hunger meter, happy and full animations, sound, and a "FEED THE SPIDER" experiment.
- It is fed through the same rules as other hits.

**At least 8 more, same spirit**, each with a real model and animation, sound, an experiment card and a journal page:
- a carnivorous plant that chomps and spits;
- a frog whose tongue grabs dummies;
- a whale that geysers dummies;
- a giant chicken that lays dummy eggs;
- a catapult turkey;
- a vacuum robot that sucks dummies up and shoots them out;
- a slingshot tree;
- a washing machine that spins dummies;
- a mole that pops up under dummies;
- a ball pit;
- a dummy cannon conveyor.

Some can be unlocked for Bolts and some sold (V6-7).

**Done when:** each one has a capture, its experiment works, and the low-tier performance is checked.

## V6-6 Birds
- **Client-side flocks** (boids): cheap, pooled meshes with wing flaps (animated or AnimationController) and LOD.
  - Pigeons in the city and on the plaza.
  - Seagulls on the island and the beach.
  - Crows and sparrows on the farm.
  - Small birds and a hawk over the lab.
  - Jets or helicopters only on the army base, maybe.
- **Behaviour:**
  - they scatter at gunshots and explosions;
  - they land on roofs, fences and wires;
  - they circle;
  - a few calls through SoundMix Ambient.
- **Budget:** at most N birds per tier in Config.
- **Done when:** a capture on each map, they scatter on a shot, and the phone frame time is OK.

## V6-7 Things to buy on the maps (Robux)
**In-world showcases on every map:** a lit pedestal or a small shop booth, the item turning slowly, a price tag, "TRY" (a short free try where possible), then BUY through Roblox's own prompt.

**Catalogue (examples; pick about 15 strong ones):**
- **Vehicles:** a sports car, a quad bike, a hoverboard, a tank, a jet ski on the island.
- **Lab machines:** the spider deluxe, a mega trampoline, a rocket sled, a giant fan.
- **Pets:** a robot dog, a parrot.
- **Cosmetics:** player trails, crash-test suits, dummy skins for your lab.
- **Event bundles.**

Every item needs:
- a **perfect model** (real, high quality, in one style, with no clipping, sitting correctly on the ground and scaled right);
- a working **function** that is tested in Studio;
- **presentation:** a turntable, lighting, a short preview clip or animation, a clear name and a one-line pitch.

**Money rules:**
- `ProcessReceipt` is idempotent, and passes are checked on join and on purchase.
- Items are delivered exactly once.
- No pay-to-win anger, and prices are fair (follow the leader's ladder).
- Nothing is sold that is not finished.
- Ids are 0 and hidden until the owner creates them. **Write the exact list** of products and passes with name, price, picture and description, so the owner can create them on the dashboard.

**Done when:**
- a capture of every booth and item;
- a test purchase of each in Studio;
- a T9x test for delivery-once;
- the owner list is written.

## V6-8 Graphics 100x better
Go over everything visible:
- the lab;
- the plaza;
- the arena;
- the 5 maps;
- every prop, vehicle, creature, weapon and NPC.

What to do:
- Replace or upgrade everything that still looks basic: PBR materials (MaterialVariants), real models, foliage and grass decoration, terrain detail, decals for dirt and wear, and light accents (lamps, neon only where it fits).
- Lighting per map (Future/Realistic, Atmosphere, a colour grade, sun angle) and a calm sky.
- Effects: dust, sparks, smoke and water that look real but cheap.
- LOD and streaming so phones keep up.

**Done when:**
- 3 captures per map against the leader;
- the owner signs off;
- the low tier is checked;
- no output errors.

## State
- 20 Nov 2026: plan written (cloud). Nothing of V6 started.
- **V5 closed** (20 Nov). Its leftovers are in V6-4 (lab clutter) and V6-8 (map passes, 3 event cards).
- **V6-1 notifications (20 Nov, PC; `Config.NOTIFY`):**
  - **Rules:** `Shared/NotifyRules` (pure, T100), applied by `Client/Notify`.
    - Kinds: critical, reward, info, tip.
    - Gaps since the last unsolicited message: reward 4 s, info 20 s, tip 45 s.
    - The same message is dropped within 120 s. A message expires after its max wait (info 45 s, tip 90 s, reward 120 s).
    - Only rewards and critical get through during a newcomer's first visit (`NewcomerUntil`).
    - 3 s of quiet after any window closes.
    - Big pop-ups (windows and cards that open by themselves): one at a time, 40 s apart, never over a window the player opened, and a newcomer's first one 20 s after the HUD reveal.
  - **Routed through Notify:**
    - small messages: the unsolicited toasts in ProgressUI, ScheduleUI, OnboardingController, GiftClock, ChristmasFx, ExperimentCard and EventShop (free ULTRA over);
    - big pop-ups: the egg card (EggReady), the auto egg, the favourite window (Like) and What's New.
    - Replies to the player's own presses still use Toast directly.
  - **Look:** Toast cards take an optional icon and close on a tap. A tapped tip stays away for the visit. Rewards and critical play a soft click through the UI mix group.
  - **Experience Notifications:** `EXPERIENCE_NOTIFY`, `NOTIFY_OPTIN_AFTER` 480. After a wow moment (LikePrompt's wow) and 8 min of play, the game asks once through Roblox's own opt-in prompt (`ExperienceNotificationService:PromptOptIn`). **Owner, dashboard:** create the notification strings ("Your daily reward is ready", "A new update is out") under Engagement → Notifications. Sending them needs the Open Cloud user-notification API with a key (not set up).
  - The audit's area 1 round 2 goes in here too:
    - a staged reveal (left cards, then the right column +5 s, then the key chips +10 s);
    - WEAPONS stays on a newcomer's PC HUD from 0 s;
    - LAB VIEW comes back at once for a returning player (`HudSlots.newcomerChanged`, `quietUntil`);
    - no newcomer flow after a teleport;
    - the cannon step outlines the pad and the cannon;
    - the line hides while a machine is looked up;
    - the reveal is scheduled before anything that could fail;
    - the pill refits on rotation.
- **V6-1 blind review 7.4 → fix round 1:**
  - Server notices (answers to the player's own presses) go straight to Toast again.
  - Rewards are never deduped or merged.
  - The expiry clock starts at the end of a newcomer's quiet, so join-time news still shows after the reveal.
  - A newcomer's first 90 s hold everything but critical. Direct toasts are held too (`Toast.hold "newcomer"`), and the queue is cleared at the reveal (`Toast.clearQueue`).
  - Only tips can be closed, with a small × (not selectable by a gamepad), so a toast no longer eats a shot. Tips have stable keys.
  - The egg card, Like and What's New never give up: they wait for their turn, then for calm or no window, again and again. A slot freed without a window costs no gap.
  - `playerWindow` is seeded at start. The opt-in slot frees on `OptInPromptClosed`.
  - Timeline (new player): only the line until 90 s; 90.4 s "Welcome back!" (the Studio profile's Returning flag); 94.5 s daily egg; 110 s egg card. T100/T23/T45/T55/T60 pass, no errors.
- **V6-1 re-review 7.8 → fix round 2 (the last; no third review):**
  - No more Toast hold for newcomers. Replies and critical messages show at once, under the objective line (`setGoalTop`). Notify still holds what it owns.
  - Notify treats a held Toast as busy (`Toast.isPaused`), so nothing is queued and lost behind a card.
  - At a newcomer's reveal, only the newest `NOTIFY_REVEAL_KEEP` (2) waiting rewards come out.
  - One egg-card waiter at a time (`offerWaiting` stays set until the card is up).
  - The Like card checks again after its wait (favourited, a window, a replay, building, the first minute).
  - The opt-in waits up to 300 s for the slot.
  - The tip × is 44 px.
  - Capture `toast_tip_x`. T100/T23/T45/T55/T60 pass, no errors.
  - Left (minor): a gamepad cannot close tips (× not selectable); `NotifyRules.pick` is unused.
- **V6-1 done.** Next: V6-2 (admin menu).
- **V6-2 admin menu (20 Nov, `Config.ADMIN_V2`):** one tabbed window, `Client/AdminPanel` ("AdminV2"). The owner's SHOP → ADMIN EVENTS button opens it.
  - **SERVER:**
    - start any event (free, everyone here);
    - all weapons on/off;
    - gravity: normal / low / moon / space;
    - time: auto / morning / day / sunset / night;
    - weather: clear / rain / snow / fog;
    - 5 fixed announcements;
    - the old menu (theme, free passes, trolls).
  - **PLAYERS:** pick a player; go to, bring, spectate; a 2-minute free try of 6 big weapons (`TrialService.grant`); kick with 4 fixed reasons.
  - **WORLD:** reset a lab (picked player's or mine); revive all; spawn 1/5/10 guest dummies as a row, ring or tower (`NoCredit`); clear the spawned ones; crowd +5/-5 where you are (`CrowdService.adjust`, at most 40).
  - **DEBUG:** this screen's fps, memory, parts, ping; the server's fps, memory, parts, ragdolls, players, traffic, version; the last server and client errors.
  - **Server side:** `Server/Systems/AdminTools` behind `AdminService` (owner check, pacing, fixed choices, every action logged with who and whom).
  - **For everyone:** `Client/AdminWorld` draws the time of day (Workspace `AdminClock`) and the rain, snow or fog (`AdminWeather`); a phone gets a third of the drops.
  - T101 (non-owner refused for every tool, fixed choices only, the tools work and are logged) passes; T41/T43 pass.
  - Captures: admin_server, admin_players, admin_world, admin_debug, admin_rain6.
- **V6-2 blind review 7.4 → fix round 1:**
  - GO TO / BRING:
    - refused into a private lab the mover may not enter (it would be thrown straight back out: "use SPECTATE");
    - refused for someone in a vehicle or frozen;
    - `Place` follows the move.
  - Admin bodies are marked `AdminGuest` and vanish after `GUEST_LIFE` 90 s, so they never hold the shared body budget. CLEAR SPAWNED removes only those, never held bodies.
  - When the owner leaves, gravity, time, weather and the spawned bodies go too (`AdminTools.ownerLeft`). The ZeroG event's end keeps the owner's gravity (`AdminGravity`).
  - Events from the menu: at most one waiting, and `force` only when nothing is running (paid events are never stuck behind a queue).
  - Crowd: labs have no crowd, so the owner gets a notice instead of a wrong number. Held people are never removed. An empty room is refused.
  - Debug:
    - not paced;
    - the server's part count walked at most every 15 s, the client's every 10 s.
  - AdminWorld:
    - no admin snow while the Christmas snow falls;
    - no drops with less motion;
    - no rain or snow in the roofed rooms (Y > 500);
    - a third of the drops on any touch screen under 900 px;
    - every emitter property set per kind;
    - fog added on top of each place's own air (re-added after a place change);
    - the time held every frame.
  - Strict casts for the frozen choice tables.
  - Not done: "clear props" (there are no admin props yet) and remote rates in Debug.
- **V6-3 director mode (20 Nov, `Config.DIRECTOR`), `Client/Director`, owner only (player attribute `IsOwner`, set by AdminService; actions checked on the server):**
  - F8 on/off. Every ScreenGui and world billboard is hidden (kept off every frame), plus Roblox's own UI.
  - A 9:16 safe frame. H = REC: the panel and frame lines hide, and the sides go black.
  - Cameras: FREE (WASD/QE, right mouse to look, wheel = speed), ORBIT and FOLLOW (click a body to pick it), DRONE, FIRST, PATH (P adds the view, ENTER plays a Catmull-Rom spline over 6 s, eased).
  - Lens: FOV -/+, DOF (focus on the picked body), SHAKE, 9:16.
  - Time on this screen: 1x, 0.5x, 0.25x, 0.1x, FREEZE (SlowMotion bubbles round the view).
  - Actions: ROW/RING/TOWER, LAUNCH the picked dummy, EVENT > (cycles), RESET ALL, REPLAY 10s (with the director camera).
  - Presets: 1-5 load, Shift+1-5 save (`OwnerSetting` "DirectorPresets", never in Studio).
  - One-tap shots: CANNON (framed along the flight to the bullseye), CAR ROW, SPIDER (waits for V6-5's `SpiderWeb`), GORILLA, TOWER, MEGA BOMB. Each sets the camera and slows the big moment.
  - Server: AdminTools `LaunchDummy`, `Shot`, `DirectorSave`, `DirectorGet`; remote messages `DirectorFocus` / `DirectorPresets` on the Admin remote.
  - T102 passes; T101/T41/T43/T98 pass.
  - Captures: director_on2 (no game UI), director_cannon_rec and director_tower2 (REC 9:16).
- **V6-4 bigger lab (20 Nov, `Config.LAB_V6`):**
  - **Size:** the plots are 250 studs apart (was 170; `Zones.PLOT_SPACING`/`PLOT_HALF`, which Lab reads). That is about +50 % area. The concrete core keeps its size (`Lab.CORE_HALF` 85: markings, floor).
  - **Garden** (`Server/Systems/LabGarden`, called from Playground.build for labs), filling both new side strips:
    - grass and a cobblestone path with two crossings into the lab;
    - flower beds, benches and warm street lamps;
    - round and pine trees;
    - a stone fountain (east) and a shed (west);
    - a 14-stud hedge on the plot's edge (privacy, together with the client's PlotPrivacy).
    - About 627 parts per lab.
  - **New models** in ServerStorage.V3Assets (place file only, saved):
    - GardenFountain 93434732057582
    - FlowerBed 131216077381773
    - GardenShed 132302998596557
    - Hedge 13364734150
  - **Malware pass:** the fountain, flower bed and shed held the known malware scripts "Runtime" and "ScreenBuilder" (12 in all, despite "No scripts" on the store). Removed. The hedge was clean.
  - **Tests:** T31 (now 250 studs), T36, T26, T99, T51, T50, T23, T92, T97 pass.
  - **Captures:** garden_east, garden_west.
  - **Still open in V6-4:** the 3-client privacy check (multi-client is not available over MCP), the dusk lamp look, and ambient birdsong (with V6-6).
- **V6-3 blind review 6.8 → fix round 1:**
  - **Exact restore:** each gui and sign is noted the first time it is seen and put back exactly. A gui the game switched off meanwhile is never forced on (the SlowMotion vignette bug). Checked in Studio: no gui differs after on/off; the camera type and FOV come back.
  - **Slow time:** one lasting bubble that follows the camera's focus (`SlowMotion.director`): no 3 s renewal jolt, never blocked by another bubble, gone at once on 1x/RESET/off. FREEZE is 0.01.
  - **Keys:**
    - ignored while typing in chat (`processed` / focused text box), so "!" no longer saves a preset;
    - the fly keys are read from the keys held each frame (no drift);
    - Space and the arrows are sunk too;
    - the panel's wheel does not change the speed.
  - **Weapons:** PokeController's state is noted and restored only if it was on (build mode and onboarding keep theirs). It is re-switched off if a replay turns it on mid-directing.
  - **Presets:** saved one slot at a time, merged on the server, and only after the stored ones have arrived. `DirectorGet` is not paced.
  - **Shots:**
    - CAR ROW and TOWER only in the owner's own lab;
    - every body shot checks the body budget;
    - GORILLA and MEGA BOMB only when no event is on or waiting;
    - the event shot frames the host's lab (`whereFor`);
    - the facing is guarded.
  - **Camera and screen:**
    - the camera comes back as the normal one if it was Scriptable;
    - the saved FOV and mouse mode come back;
    - the mouse is free while directing;
    - refusals show on the panel ("Notice");
    - new signs are hidden as they appear (also those under PlayerGui).
  - **REPLAY 2s:** renamed to the clip the X-ray replay really keeps.
  - T101/T102 pass. No re-review run (credits).
  - **Left:**
    - a locked follow mode;
    - path ease and duration controls;
    - the Roblox topbar;
    - the SPIDER shot waits for V6-5.
- **V6-5 creatures (20 Nov, `Config.LAB_CREATURES`):** `Server/Systems/LabCreatures` builds a creature yard in front of each lab (z 75-110, grass). The land stays flat out to z 112 (Landscape), and the hedge carries on along the yard.
  - **The 9 creatures:**
    - **SPIDER:** a web; it wraps a dummy in a wiggling silk cocoon, munches and spits it away as a "burrito". Hunger meter (3 meals = full, then a 20 s nap).
    - **GIANT PLANT:** chomps a dummy and spits it high.
    - **FROG:** its tongue pulls in a dummy within reach and spits it.
    - **WHALE:** a pool with a geyser.
    - **CHICKEN:** lays a dummy as a wobbling egg that hatches.
    - **WASHING MACHINE:** spins a dummy and throws it out.
    - **SLINGSHOT TREE:** pulls back and fires a dummy at the lab.
    - **MOLE:** pops up under dummies in its dirt patch.
    - **ROBOT VACUUM:** drives a loop, sucks up a dummy and shoots it out.
  - **Rules:** one body at a time per machine, never a held one. Bodies only through DummyControl (the lab's player simulates them). Kid-safe: nothing eaten for real. An empty lab's yard rests.
  - **Progress:** each creature counts an ExperimentService event for the lab's owner, with 9 new experiment cards (21 in all) and 9 journal pages (25 in all).
  - **Models** in V3Assets (place file only, saved v564): MSpider 9602053434 (meshes only), MPlant 11297917863, MFrog 106808835, MWhale 13676783065, MChicken 4376443752, MWasher 120197306107893, MVacuum 77204638222896, MMole 8096582970.
  - **Malware pass:**
    - The spider held 23 NPC scripts ("killing script", Attack, Damage, Animatronic_AI…) plus an embedded humanoid rig; all removed.
    - The first plant held an Animate script.
    - A second plant tried ("JeffTheKillerMain") was deleted outright.
    - Humanoids and sounds were stripped from all of them.
  - **Tests:** T103 (built, cards and pages, spider eats and spits, whale geyser, held body left alone, events counted) passes; T60/T63/T31 pass.
  - **Captures:** yard_east, spider_feed.
  - **Left:** per-creature sounds (SoundMix), a hunger readout for the owner's HUD, and the ball pit and conveyor (optional in the plan).
- **V6-6 birds (20 Nov, `Config.BIRDS`, `BIRDS_MAX` pc 24 / tablet 14 / phone 8):** `Client/Birds`, client-side only, with pooled real models in ReplicatedStorage.BirdModels (place file only, saved).
  - **Models:** Pigeon (16726492351, skinned walker), Crow (99170264330082), Gull (123244333951153), Hawk (10367972039, skinned with wing bones; its script removed). A part-built "sparrow" was dropped.
  - **Flocks by place:**
    - Lab: pigeons pecking on the ground, crows circling, a hawk gliding high;
    - Plaza and City: pigeons on the ground (crows over the city);
    - Island: gulls;
    - Farm and Site: crows;
    - Army: hawks.
  - **Behaviour:**
    - boids-lite round a point that drifts after the player, banking into turns;
    - the pigeons walk, stop and peck;
    - a shot or a blast nearby (FeelBus Shot / BigHit) scatters them up and away, and the pigeons come back down later;
    - the hawk's wings beat on its bones, gliding most of the time.
  - **Cost:** birds past 320 studs are hidden and not stepped. A quiet birdsong loop (Pro Sound Effects 9119383684, SoundMix Ambient) plays outdoors, never in the roofed rooms.
  - **Bug found and fixed:** without ground under a bird, its floor lifted it 8 studs a frame (they flew off to y 7000).
  - **Tests:** T104 passes (models present and script-free, budgets by tier).
  - **Capture:** birds_lab.
- **V6-4/V6-5 blind review 7.0/6.5 → fix round 1:**
  - **Hiding a body inside a creature:** the server now sets `MachineHidden` and every client hides the body's skins (DummySkins). Before, the server's blocks were already invisible on screens, so the white mannequin showed inside the plant, the egg and the washer.
  - **Throws:** every throw heads back toward the lab's middle (`toLab`). The whale and mole throws land off their own patch, and `MachineCool` stops a thrown body being taken again for 6 s, so there are no endless geyser loops and no throws over the hedge onto the hills.
  - **Server cost:** the vacuum drives only in an owned lab, at 15 Hz (was 60 Hz in all 10 labs). The plant bobs instead of being rescaled every frame.
  - **Cleanup:** a failed swallow removes its cocoon, tongue or egg.
  - **Spider:** it does not digest while napping and wakes hungry.
  - **InMachine respected:** the lab's slot watcher does not walk a body in a creature home, and GrabController cannot pull it out.
  - **Old spacing fixes:** a car in the creature yard is no longer reset (VehicleService front 112); the plaza edge boards follow the plot edge (WorldMaps).
  - **Baseplate:** BaseplateEast/West pieces (place file, saved v567) cover the outer labs at x ±1250.
  - Strict return types in LabGarden.
  - T103 checks the test player's own yard and uses a fresh body for the whale. Passes; T31/T36/T26/T50/T92 pass.
  - Not re-reviewed.
- **V6-7 map shop (20 Nov, `Config.MAP_SHOP`):** `Server/Systems/MapShopService` + `Client/BoothSpin`.
  - **Booths:** a row of showcase booths at the plaza's front (z 130) and by each open-air map's arrival. Each has a marble pedestal with a gold rim light and a spotlight, the item turning slowly on top (client-side), and a sign with the name, a one-line pitch and the price. Two prompts: **TRY 60 s free** (once per item per visit) and **BUY** (Roblox's own purchase prompt). An id of 0 means no booth live; Studio shows TEST and delivers through the real path.
  - **10 items** as Shop.OFFERS entries (`map = true`), delivered by the existing OfferService (`Offer_<key>`, checked on join and after purchase, products once per purchase id). Effects in MapShopService:
    - Rainbow Trail;
    - Fire Trail (flames at the feet);
    - Crash-Test Suit (clothes kept and put back);
    - Gold Dummies (your lab's dummies);
    - Robot Dog (follows you, 15 Hz);
    - Parrot (on your shoulder);
    - Mega Trampoline (your lab's yard; bodies and players bounce);
    - Giant Fan (back of your lab; blows dummies forward);
    - Spider Deluxe (your lab's spider in gold, spits 1.5x farther);
    - Bolt Crate (500 BOLTS).
    All of it is cosmetic or lab fun: no pay-to-win.
  - **Models:** PetRobotDog (Roblox "Innovation Robot Dog" 1374012792; its 2 animation scripts removed) and PetParrot (macaw 3676031164). Place file only, saved v569. Display mannequins are copies of ReplicatedStorage.DummySkin.
  - **Bug:** a sed slip put a stray `&` into Shop.luau/Offers.luau, breaking every module that loads them. Fixed at once.
  - **Tests:** T105 (10 items with grants, 22 booths, try once and never for a product, Studio purchase delivered, the effects on and off) passes; T68/T103 pass.
  - **Captures:** booths_plaza2, booths_plaza3.
  - **OWNER, create on the Creator Dashboard and paste each id into Shop.OFFERS (`id = …`):**

    | Key | Type | Name | Robux | Description | Picture |
    |---|---|---|---|---|---|
    | RainbowTrail | Game pass | Rainbow Trail | 49 | Leave a rainbow wherever you fly. | the booth with the rainbow mannequin |
    | FireTrail | Game pass | Fire Trail | 79 | Run, fly and land in flames (cosmetic). | the fire booth |
    | CrashSuit | Game pass | Crash-Test Suit | 99 | Dress like the real crash dummies: yellow and black. | the suit booth |
    | GoldDummies | Game pass | Gold Dummies | 149 | Every dummy in your lab in shining gold. | the gold mannequin |
    | RobotDog | Game pass | Robot Dog | 129 | A loyal robot dog that follows you everywhere. | the robot dog booth |
    | Parrot | Game pass | Parrot | 99 | A bright macaw that rides on your shoulder. | the parrot booth |
    | MegaTrampoline | Game pass | Mega Trampoline | 149 | A giant trampoline in your lab: bounce dummies sky high. | the trampoline booth |
    | GiantFan | Game pass | Giant Fan | 179 | A giant fan that blows every dummy across your lab. | the fan booth |
    | SpiderDeluxe | Game pass | Spider Deluxe | 199 | Your lab's spider in gold, and it spits farther. | the golden spider |
    | BoltCrate | Developer product | Bolt Crate | 49 | 500 BOLTS for your next weapons. | the crate booth |
- **V6-6/V6-7 blind review 7.8 / 7.4 → fix round 1:**
  - **Gold dummies:** one rule per tick on living bodies only. The dead-green paint is left alone and turns gold again on revive. The true colours are kept per part until put back on a living body.
  - **Pets:** no more server PivotTo loop. The parrot is welded to the shoulder (in the character). The dog is a light physics body pulled by AlignPosition/AlignOrientation, owned by the player's machine.
  - **Nothing sold before it is finished:** `sellable` also needs every model the item uses (place file) and the display mannequin.
  - **BUY:** one per second per player, only within 16 studs of the booth (TRY too), never while the server is closing. Delivery stays OfferService's.
  - **Leaving:** no pet is made for a player who has left.
  - **Crash suit:** clothes that load after the suit are tucked away too, and the arms are black like the mannequin.
  - **Birds:**
    - parts made safe (anchored, no collision, query or touch);
    - landing pigeons glide down instead of popping;
    - ground rays cached about 7 a second per bird;
    - the ray filter is cached;
    - the parent is set only on change.
  - Not done: TRY kept per UTC day (it is per visit), birds perching on roofs and wires, and DeviceTier for the bird budget.
- **V6-8 graphics (part, 20 Nov):**
  - **Event cards:** RocketRain, MeteorShower and Earthquake now have real captured pictures, so all 18 events have one.
  - **Haze:** the open-air haze is down from +0.18 to +0.07 (+0.05 saturation). The maps were washed out; the far skyline still fades.
  - **Map shop:** on the open-air maps the booths stand in a row beside the arrival path (`MAP_SIDE` 42), on terrain only (never a roof).
  - **Birds:** crows fly higher.
  - **Map captures (Studio):** map_island, map_city2, map_farm, map_army, plus the lab (garden_east/west, yard_east) and the plaza (booths_plaza3).
  - **For the owner to judge:** whether the maps now read "100x better". Next per-map upgrades if wanted: MaterialVariants on the open-air terrain and decals for wear.
- **Full regression (20 Nov, end of V6):**
  - Full suite **85/91**. The fails:
    - T15, T19, T25, T32: on the known flaky list;
    - T23: order effect, passes alone;
    - T39: plaza booths stood in front of the leaderboards. Fixed: plaza booths now stand in two side columns facing in; T39 and T105 pass.
  - T66 fails when run alone (it starts before the labs are built) but passes in the full suite.
  - LayoutCheck in the game's own client: **0 problems**.
  - Version **0.24.0** with What's New (T66/T68 checked).
- **State:** V6-1 to V6-8 are built, seen in Studio and pushed.
  - Still open (owner): the product ids for the 10 map items (table above), the notification strings, saving the place (done by me through v570+), and publishing.
  - Still open (later): the 3-client lab privacy check, phone frame-time checks, TRY per UTC day, and birds on roofs and wires.
