# RAGDOLL HAVOC v4: the owner's fix list (20 Nov 2026)

## For the owner (Danish)
Det her er din liste, delt op i trin, som Claude Code på din pc tager ét ad gangen, når du skriver `/klar`. Hvert trin er først færdigt, når Claude har set det virke i Studio, har vist dig billeder, og testene består. Den laver de ødelagte ting først, så det, der ses mest, og til sidst det, der får folk til at blive og komme tilbage.

## The owner's list (20 Nov 2026, verbatim)
> Rød gul grøn spillet skal fikses. NPC'erne/Ragdollse skal stadig se bedre ud, de skal også kunne dø hvis man skyder dem nok gange eller slår dem nok gange, ikke kun hvis man rammer headshot. Ens lab skal være mere mindre rodet og mere gennemført, så der altid er noget nyt at give sig til uden det ligner en bunke ai skrald. Sørg for alt med lyd er på plads, i forhold til lydstyrke osv også. Lav bedre ikon og thumbnails med højest mulig ctr. Forbedre ydlygere alle maps og alle modeller så det ikke ligner ai slop. Slo-mo skal gøres meget bedre. Bilerne skal gøres meget flottere. First person skal virke når man scroller ind med musen man skal ikke trykke V, selvom det stadig skal være en mulighed. Gør gorilla rampage og bull run meget mere realistike og tilføj mange mange flere ting som dem som gør spillet sjovt og uforudsigeligt. Gør så du kan snak med de forskellige npc'er og så kan du bede dem følge med, eller blive stående, eller angribe end anden npc med de forskellige slags våben du har unlocked. Tilføj billed til maps ikonerne Plaza, Game arena og Lab. Flere steder falder ting halv igennem jorden nogle gange. Gør så npc'erne laver noget interaktivt i forhold til hvor de er, de skal være naturlige, og snakker om noget i forhold til hvor de er og de ser anderledes ud i forhold til hvilket map man er på- lige nu så spawner alle npc'erne rundt på mapsne oveni en kæmpe klump og der er ikke så mange. Sørg for intet UI ligner ai, heler ikke leaderboardsne. Sørg for folk faktisk spiller, og bliver derinde, og liker, og favoriter, og kommer tilbage osv osv, brug eventuelt vaulten, tiktok, reddit og ydligere research for at lave den bedste plan.

## Item map (every request → its step)
| # | Request | Step |
|---|---|---|
| 1 | Fix Red Light Green Light | A1 |
| 2 | Things fall half through the ground | A2 |
| 3 | All sound in place, right volumes | A3 |
| 4 | First person on mouse-wheel zoom (V still works) | A4 |
| 5 | NPCs die from enough shots or punches, not only headshots | A5 |
| 6 | Picture on the Plaza, Game Arena and Lab map cards | A6 |
| 7 | NPCs spawn in one clump, and too few | B1 |
| 8 | NPCs natural and interactive for where they are | B2 |
| 9 | NPCs talk about where they are | B2 |
| 10 | NPCs look different per map | B3 |
| 11 | NPCs/ragdolls look better | B3 |
| 12 | Talk to NPCs: follow, stay, attack another NPC with your unlocked weapons | B4 |
| 13 | Lab less cluttered, finished, always something new, not AI junk | C1 |
| 14 | Cars much nicer | C2 |
| 15 | Gorilla Rampage and Bull Run far more realistic | C3 |
| 16 | Many more fun, unpredictable things like them | C4 |
| 17 | Slow-mo much better | C5 |
| 18 | All maps and all models better, not AI slop | D1 |
| 19 | No UI that looks AI, the leaderboards too | D2 |
| 20 | Better icon and thumbnails with the highest CTR | E2 |
| 21 | People play, stay, like, favourite, come back (research: vault, TikTok, Reddit) | E0, E1, E3 |

## Phase A: broken things and quick wins (do first, in this order)
**A1. Red Light Green Light.**
- Play it in Studio first, with 1 and with 2+ players (Studio's multi-client test). Write down every break: start/end, the timer, how moving is caught (velocity and pose, ragdoll and jump), who is out, the finish line, rewards, the UI lines, and leaving mid-game.
- Then redesign it robustly:
  - a server state machine with one source of truth;
  - a fair grace window after "red" (about 0.3 s, Config);
  - "moving" judged from root speed above a Config threshold, ignoring ragdoll settling;
  - a clear doll, guard or light with sound cues;
  - rejoin and leave handled cleanly;
  - phone-friendly UI.
- **Done when:** 3 full rounds play cleanly solo and with 2 clients (with captures), and a T9x test covers the state machine.

**A2. Nothing falls through the ground.**
- Reproduce it on the lab, the plaza, every open-air map and the arena (dummies, props, models, vehicles, players getting up).
- Find each cause:
  - terrain top versus part floors;
  - CanCollide off on floors;
  - collision groups;
  - spawn height;
  - model pivots not at the lowest part;
  - thin floors with fast bodies (add thick invisible collision floors);
  - network ownership hand-offs.
- Fix them, and add a guard that lifts any body found below the floor back onto it.
- **Done when:** a 5-minute stress run (cannon, cars, events) on each map has nothing sunk, and a test checks the floors and the guard.

**A3. Sound.**
- Audit every sound: guns, hits, bodies, explosions, vehicles, animals, events, UI, ambient, voice lines.
- Build SoundGroups (Master, Weapons, Impacts, World, UI, Ambient), each with a Volume, a light compressor on Master, and ducking of World/Ambient on big blasts.
- Set rolloff distances (near and far) and a per-sound priority and limit, so one source never plays more than N copies.
- Fix missing, too-loud and too-quiet sounds, with phones in mind. Add Settings sliders for Effects, UI and Ambient if they are missing.
- Write a mix table in `Config`.
- **Done when:** a capture-with-sound walkthrough has nothing clipping, everything audible, UI quieter than guns, and a test checks that every SoundManifest id loads.

**A4. First person by mouse wheel.**
- Scrolling all the way in enters first person (gun viewmodel, crosshair); scrolling out leaves it. V still toggles it.
- Do not fight Roblox's zoom: read the camera distance and switch when it falls under a threshold, and give it a little give so it does not flicker.
- Lab view and phones are unchanged.
- **Done when:** it works on PC both ways, V still works, and nothing breaks in lab view or while driving.

**A5. Death from damage.**
- Each body gets health:
  - hits by region (head, torso, limbs) and weapon power add up;
  - enough body shots or punches kill;
  - headshots stay instant.
- Show it kid-safe: knocked out, then "dead" (green, as today), then revive as now.
- Numbers go in Config (for example about 6 Popper body shots, about 10 punches), tuned so it feels good.
- It counts takedowns, experiments and the journal.
- The server decides, and auto weapons stay inside the burst budget.
- **Done when:** a capture shows a body going down from body shots and from punches, and a test checks that the damage adds up and the body revives.

**A6. Map card pictures.** Take real captures of the Lab, the Plaza and the Game Arena, framed like the 5 open-air map cards (`art/maps`, `Places.image`). Upload them (Studio MCP upload_image) and show them on the Maps window. **Done when:** all 8 cards have a picture, with a capture of the window.

## Phase B: NPCs that feel alive
**B1. Spawning: many, spread out, natural.**
- Replace clump spawning with authored spawn points per map: sidewalks, benches, shops, barns, docks and so on, tagged in the place or listed in code. Each spot has a jitter, a minimum spacing and a ground check.
- Raise the counts per map within the phone budget (`DEVICE_CAPS`, streaming). Use NPC LOD: far ones idle cheaply or are culled, near ones are full.
- **Done when:** captures of every map show NPCs spread over the whole map, none stuck together, and the frame time on the low tier stays OK.

**B2. Behaviour and talk by place.**
- Each map has activity spots: sitting on benches, fishing on the jetty, shopping in the city, working on the site, farming, standing guard at the base, swimming or sunbathing on the island, chatting in pairs, filming.
- NPCs walk between spots with PathfindingService and natural idle animations.
- `DummyLines` grows into place-aware line sets (what they say depends on the map and what they are doing) plus reactions: fear when a gun is aimed, cheering at a stunt, pain when hurt, and a comment when a car passes.
- Lines stay short, kid-safe and rate-limited.
- **Done when:** a 2-minute capture per map looks natural, and the lines fit the place.

**B3. Looks.**
- **Lab dummies:** a better mannequin to the leader's level (a clean white mesh with good joints and a readable face). Use a better Creator Store mannequin rig if one exists, and run the malware pass.
- **Map NPCs:** dressed per map with real Roblox clothing and accessories (city: casual or business; site: hi-vis and helmets; farm: overalls and hats; base: fatigues; island: summer). Use a clothes list per map in Config, never one look for all.
- **Done when:** side-by-side captures against the old look and the leader's dummies.

**B4. Talk and command.**
- Walk up to an NPC and press E ("Talk"). A small dialogue panel opens with the options Follow me, Stay here, Attack…, Bye.
- Follow uses pathfinding at a distance of 4-6 studs.
- Attack: you pick a target NPC by pointing at it or from a list of the nearest, and pick one of **your unlocked weapons**. The NPC holds that weapon and uses it on the target with the real hit rules (server-side, the same damage as yours).
- **Limits:**
  - at most 3 followers per player;
  - only NPCs in your lab or on the map you are on;
  - never other players;
  - cooldowns;
  - everything validated on the server (remote through Net with a validator);
  - commands end when you leave the map.
- **Done when:** a capture shows an NPC following, staying, and attacking another NPC with a chosen unlocked weapon, a T9x test checks the limits, and the remote is listed in CLAUDE.md.

## Phase C: the lab and the action
**C1. Lab redesign: clean, finished, always something new.**
- Make a top-down capture of the current lab, then design zones with paths:
  - spawn and hub;
  - the test zone (dummy row);
  - launchers (cannon, stations, throw tower);
  - the vehicle bay;
  - the event pad (BIG RED BUTTON);
  - a machine of the day.
- Remove or merge anything that adds clutter: duplicate signs, stray props, overlapping machines.
- Use one style: real models, matching materials, clean floor markings.
- **"Always something new":**
  - a daily featured machine/activity (rotates by UTC day) with an experiment card;
  - unlockable lab machines bought with Bolts;
  - a small "NEW" marker on what changed since the last visit.
- **Done when:** before/after captures from 4 fixed angles and the top down, nothing overlapping, and the daily rotation shown.

**C2. Cars.**
- Real body models (Sedan, SUV, the monster truck from `V3Assets`) on the code chassis:
  - wheels that spin with speed and front wheels that steer (visual welds updated on the client);
  - a little body roll and suspension feel;
  - headlights and brake lights;
  - an engine sound that follows speed, a horn (H), a crash sound, and tyre dust.
- Driving is tuned in Config. Hitting dummies throws them.
- **Done when:** a driving capture where every part reads as a real car, with the sound on.

**C3. Gorilla and bull, realistic.**
- Rigged, animated models (walk, run, charge, swat, roar) from the Creator Store, or a rigged mesh plus our own AnimationController with authored keyframes.
- Real paths: the gorilla chases the nearest dummy and beats its chest; the bulls stampede in a herd with dust.
- Add sounds (roar, hooves, thuds), camera shake near them, and physics knocks with the real rules.
- **Done when:** a capture of each event that the owner would call realistic.

**C4. Many more unpredictable things.** Build at least 10 new events or surprises in the same EventService pattern (lab-local, kid-safe, within the phone budget), plus random small surprises in the lab every few minutes so no two minutes are the same. Candidates:
- Shark Attack, in a flooded lab or at the island;
- T-Rex Escape;
- a UFO beam that lifts dummies;
- Giant Dummy;
- a Bowling Ball Avalanche;
- Rocket Rain;
- a Magnet Storm that pulls metal props;
- Bouncy Castle;
- Lightning Storm;
- a Sinkhole;
- a Zombie Dummies chase (cartoon);
- a Tornado of Pillows;
- a Lab Earthquake;
- a Giant Fan Blast;
- a Moon Gravity wave;
- a Hot-Air Balloon drop.

Each event needs a sound, a banner and a card picture. **Done when:** each new event has been captured once, and the BIG RED BUTTON and the free-event rotation include them.

**C5. Slow-mo, much better.** Roblox has no global physics time scale, so build it from what works:
- the bodies you own slow down on your client (scaled velocities in a bubble);
- sounds lower their pitch (PlaybackSpeed);
- the camera eases in with a slight FOV punch and a vignette, blur and colour grade;
- trails;
- a heartbeat/whoosh layer;
- a smooth ease in and out.

Big hits get an automatic short slow-mo moment. The X-ray replay gets real slow playback. **Done when:** a capture comparing old and new, the owner can trigger it reliably (Z and the Lab window), and it stays cheap on phones.

## Phase D: everything looks made by people
**D1. All maps and all models.**
- Go over every map (Lab, Plaza, Game Arena, Island, Downtown, Building Site, Old Farm, Army Base) and every model the game shows.
- Replace or remove whatever still reads as code-built or "AI slop".
- Each map gets: real models in one consistent style, terrain with proper materials, paths, lighting accents, set dressing in clusters (not random scatter), and a hero landmark.
- Weapons get model and icon consistency.
- **Done when:** 3 captures per map, judged against the leader, and the owner has signed off.

**D2. UI that does not look AI-made.**
- One hand-crafted style: a calm palette and one display font plus one body font, used with restraint.
- No neon frames, no glowing crowns, no rainbow gradients, no emoji as icons.
- Icons in one consistent set.
- Leaderboards redone as clean wall panels, readable from afar, with avatars and a top-3 accent that is not cheesy.
- Every window, card, toast and HUD piece goes through the same tokens.
- **Done when:** captures of every window and board, and LayoutCheck shows 0 problems.

## Phase E: people play, stay, like, favourite and return
**E0. Research first (short, on the PC, where the web works).**
- **Vault:** grep `INDEX_SLIM.md` / `SYMPTOMS.md` and read the `tldr:start` blocks of the notes on retention, first session, likes/favourites rules, daily rewards and streaks, notifications, update cadence, thumbnails/CTR and sound.
- **Web:** Reddit, TikTok and YouTube on what keeps players in ragdoll sandboxes, and what top games do for icons and thumbnails.
- Write the results into `docs/RESEARCH_V4.md` with sources, and let them adjust E1-E3.

**E1. Retention systems** (all within Roblox rules; never reward likes):
- **First 60 s:** action in under 5 s, then one goal card, then the first wow moment (cannon, car or event) by 60 s.
- **Session length:** goals that chain (experiments, journal, machine unlocks, map discovery), and the next goal always visible.
- **Return:** a daily streak with escalating rewards, the daily featured machine/event, Daily Experiments, and Roblox Experience Notifications if available (for example "your daily chest is ready").
- **Favourite and like:** ask after a wow moment, at most once a session (`LikePrompt` exists, so check the timing), favouriting through `PromptSetFavorite`.
- **Friends:** invite prompts, Prank Party, friend joins.
- **Update rhythm:** a named update with a countdown every 3-7 days.

  **Done when:** each system is seen in Studio, and SessionStats records the funnel steps.

**E2. Icon and thumbnails, highest CTR.**
- Make them from real in-game captures, staged for drama (a dummy mid-air, a car hit, a gorilla). Use a clear focal point, high contrast, and readability at phone size.
- Make 3-5 thumbnails and 2 icon variants, so the owner can A/B test them with Roblox's thumbnail testing.
- Nothing misleading: every image shows something that is really in the game.
- Save them in `art/store/` and tell the owner how to upload them and run the test.

**E2b. Store video.** `docs/TRAILER.md`: `tools/TrailerCam.luau` (client) and `tools/TrailerServer.luau` (server) direct about 30 s of real gameplay while the owner records. Redo it after each big update.

**E3. Release and measure.**
- Bump `Config.Version` and `Shop.WHATS_NEW`, and update `STORE_TEXT.md` with true claims only.
- The owner publishes with "Shut Down All Servers". Remind them about the maturity questionnaire (target: all ages).
- The next day, compare `Session_v1` (`tools/SessionReport.luau`) with the KPI targets: median session above 4 min, above 30 % reaching 5 min, D1 above 20 %, and a like ratio above 85 %. Write the result into the State line and pick the next fixes from the data.

## State
- 20 Nov 2026: plan written (cloud). Nothing of v4 started. Before v4, the v3 leftovers in `docs/V3_PLAN.md` (State, PC TODO) still count, and the PC session decides with the owner's priority (this list comes first).
- 20 Nov 2026 (PC): **A1 done.** Play test (1 player) found the round could not be won: every runner through the red line cost a life, honest green-light walkers too, and at pace 1.1 they crossed in two greens, so the round ended at ~12 s. Now:
  - only a cheater (one that moved on RED) costs a life; an honest finisher is "Safe!";
  - every runner that is out is replaced in its lane after 1.5 s, so the round lasts its minute (no early end while replacements are pending);
  - pace 0.55, sneak 0.12, lives 5.
  - Seen in Studio: the round ran its minute with lights and HUD right. T94_RedLight is new; T27 is updated.
  - Not done: a 2-client test (Studio multi-client).
  - The Studio viewport went white again after visiting the Arena (Studio renderer state; only a Studio restart fixes it), so A1's captures show only the HUD.
- 20 Nov 2026 (PC): **A4 done.** FirstPerson: scrolling all the way in (camera under ENTER_AT 1 stud from the head) enters first person with the viewmodel; the wheel out leaves it; V unchanged; skipped in the lab view, while seated and on touch. Seen in Studio: the zoom-in switched to LockFirstPerson.
- 20 Nov 2026 (PC): **A5 done.** VitalsService keeps a damage pool per body:
  - every hit adds power x Config.DAMAGE_PER_POWER 17 x the region (head 1.5, limbs 0.6) x 0.83 for blows; BODY_HP 100 kills (cause "Wounds");
  - shown as today (dead green, revive after REVIVE_AFTER);
  - patching up and the revive clear it; the attribute Damage carries it; headshots stay instant.
  - T95_DamageDeath: 6 Popper rounds or 10 punches kill; 6 rounds in a foot do not.
  - T33's blow check is 3 Mega Slaps now (5 kill by damage).
- 20 Nov 2026 (PC): **A6 done.** Lab, Plaza and Game Arena captures in art/maps, uploaded (Places.image); other players' labs show the lab picture; all 8 cards seen with pictures in the Maps window. The window's caption no longer says 'rooms full of people'. The Arena capture shows it needs D1 (plain pink box).
