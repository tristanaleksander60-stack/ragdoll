# V8: the new Ragdoll Havoc (2/10 -> 10/10)

## 1. The owner's words (verbatim)
> Lav flere brugertest, sæt spørgsmål tegn ved ALT fra a-å ned til mindste detalje, så vi får en helt ny udgave af Ragdoll Havoc ... Lig plan for at tage spillet fra 2-10 overall til 10/10 nu overall
>
> Sørg for alt er super satisfying
>
> Brug så lidt credits muligt uden at kvalitet bliver værrere, tværtimod

### Wishes -> steps
| # | Wish | Where in this plan |
|---|---|---|
| 1 | More user tests | §7 (3 rounds of 5 real players + 6 journey self-tests); V8-0.8 (play-as-newcomer mode), V8-0.10, V8-1.8, V8-6.5 |
| 2 | Question everything, a to z, down to the smallest detail | §3 scorecard (16 areas A-P), §5 cut list |
| 3 | A completely new version of Ragdoll Havoc | §4 vision; V8-1 (new first ten minutes), V8-2 (one lab, one look) |
| 4 | From about 2 to 10/10 overall | §6 phases, each with one exit gate; §8 (one gate table, with a playtest fallback when traffic is thin) |
| 5 | Everything must be super satisfying | Rule 1 in §10 (checklist on every step); V8-0.2, V8-1.1, V8-1.2, V8-1.5 |
| 6 | As few credits as possible, quality the same or better | Rule 2 in §10; one blind review per phase, not per step; steps ordered by player value per hour; owner tasks batched into a few sittings |

**Order:**
1. **V8-0 first, in days, and before 1 Dec** (the Christmas lab goes live then). Day 1 reads the place's orientation setting and holds owner Sitting 1. A 0.25.1 with no gameplay change (telemetry, safe boot, store truth) goes out first; the 0.26 bundle follows. V8-0 names a must-ship core.
2. Then V8-1 -> V8-5, each gated on its exit gate (§8), not on the calendar: the numbers when at least 100 new players arrive within 7 days of the publish, otherwise that phase's playtest round.
3. V8-6 (safe, cheap shipping) runs beside the others:
   - 6.2 right after V8-0 (6.4's test helpers and the runner fixes already ride with V8-0.9);
   - 6.1 before the first V8-1 publish;
   - 6.4's TestArena and multiplayer runner just before V8-3, where 2-client tests are first needed;
   - 6.7 before V8-3.
4. One `/klar` runs one phase. A phase starts only when the earlier phase's gate has been read (numbers or playtest round, §8).
5. **Publishing per build** (0.25.1, 0.26, then once per phase) changes the 20 Nov order, under which `/klar` publishes by itself through RELEASE.md once, at the end of a whole plan. The owner approves or refuses this change in Sitting 1 (V8-0.1). If he refuses, 0.25.1 folds into 0.26 and each V8 phase runs as its own plan, so RELEASE.md's end-of-plan publish runs once per phase.

## 2. What the evidence says
The ten findings that matter most. Sources: Session_v1 read in Studio on 20 Nov (365 non-owner visits, 7 days), a Studio playtest on an iPhone 11 portrait and on PC, five simulated players, 16 A-Z audits, and research from the Roblox APIs, the docs, DevForum, the trackers and the LihFolk vault.

1. **Players leave before any hook starts: in the first 20-45 s on 0.17.1, and between 60 s and 3 min on 0.24.**
   - 0.17.1, PC/phone/tablet, n 281: 35 % gone by 20 s, 47 % by 30 s, 71 % by 60 s, 93 % by 3 min.
   - Time played follows takedowns almost one to one: 0 takedowns = gone at 9 s; 21+ = 199 s. After the first shot, players stay a median 24.5 s more.
   - 0.24.0 (n 11, owner out): median about 2 min (126 s), 18 % gone by 60 s, 82 % by 3 min, nobody past 5 min. **0.25.0 has 0 real-player visits**, so the 20 Nov hook times are unmeasured.
   - **Baselines:** from now on the gates (§8) are measured against the 0.24 cohort with the owner left out, until the 0.25.1 cohort replaces it. The 0.17.1 numbers are history: they show how fast players left a build with none of today's first minute.
   - **Correction to the brief:** the "45 visits, mostly 414x814 upright" counted the owner's own phone (13 visits) and a second account on the same phone (5). Real phone players read as upright too, at boot: 105 of 108 phone visits on 0.17.1 (finding 5 says why this may be an artefact).
   - Benchmark: games whose sessions average 0-3 min have a median D1 of 4.31 %; at 13-18 min it is 10.24 % ([GameAnalytics 2025](https://www.gameanalytics.com/reports/2025-roblox-report)).
2. **The first hit is weak and reads like a hospital chart.**
   - Playtest: on PC the Popper took 7 shots (about 15 s) for the first knock-down. On the phone, 4 shots felled nothing. The hit card said "Right leg 98% health · pulse 76".
   - With BLOOD off, gun hits skip the impact effect entirely, and the push is about 9 studs/s (`Client/FxController.luau:1145-1149`, `Shared/HitMath.luau:22-24`).
   - The leaders sell per-body-part reactions ([HRR guide](https://allthings.how/?p=358267)). 91 % of Bloody Ragdoll Physics' (BRP) new players get a first kill (badges API).
3. **The game takes the toy out of the player's hand.**
   - Every unlock at 10 takedowns or fewer auto-equips and becomes the held tool (`Client/ProgressUI.luau:632-647`, `Client/PokeController.luau:1693`).
   - By 10 takedowns the bar is Popper, Grab, Revolver, Heal, Poke, Slap, and the Grenade cannot get on it.
   - On phones, the SHOOT button disappears when a melee tool is picked (`Client/TouchShoot.luau:53-55`).
   - The egg's WOW weapon falls into a 10 s "Pick a slot" and is lost.
   - All five simulated players hit this. HRR gives ten filled slots at spawn.
4. **Too many voices at once, and some of them lie.**
   - At 0-5 s there are four instruction texts and two pointers.
   - About 12 separate clocks crowd 25-110 s. The real HUD reveal is at 48-55 s, not 35 (`Client/FirstVisit.luau:39,206`).
   - False toasts: "3 weapons unlocked!" (the starters), "Daily egg! Come back tomorrow" on a first visit, "Goal done: Open 1 egg" when no egg was opened, and "LAUNCH GIFT ... Open it in RANK & EGGS" (that button is hidden).
   - DevForum: "it was overwhelming seeing those many buttons as soon as you join" ([thread](https://devforum.roblox.com/t/the-age-old-question-what-makes-people-leave-this-after-30-seconds/3969002)).
5. **On an upright phone the player sees a tunnel and no goal.**
   - At 414x814 the view is about 39° wide.
   - The cannon sits 82-97° to the right of the spawn camera. A wooden signpost stands on the spawn point (`Shared/PathPlan.luau:112`).
   - Phones show no next-weapon goal at all (`Client/PokeController.luau:471-475`, `Client/HudPlus.luau:583-585`).
   - About 37 % of the height is left for the game.
   - **The orientation itself is unconfirmed.** The repo never sets `StarterGui.ScreenOrientation` (grep: 0 hits), so the place file decides it, and nobody has checked that value. `SessionClient.luau:72-80` reads ViewportSize once, within 2 s of client start, and never again; DevForum threads report that Roblox mobile can load upright and turn to landscape near the end of loading. So "upright" may be the loading screen, not play. V8-0 checks both before building for it (V8-0.5).
6. **Reach: the game is shut out of every under-16 player, for a reason our docs got wrong.**
   - The age-recommendation API gives "Maturity: Minimal • Ages 16+". Every competitor checked has minimumAge 0.
   - [Kids & Select](https://create.roblox.com/docs/production/publishing/kids-and-select) needs:
     - an ID-verified creator with 2-Step Verification;
     - Plus/Premium for 2 months, or a refundable fee;
     - 100 unique plays from highly engaged, age-checked players within 60 days.
   - Media sharing forces 16+ ([content maturity](https://create.roblox.com/docs/production/promotion/content-maturity)). We have `PromptShareCapture` and global build codes.
   - "Redo the questionnaire" (CLAUDE.md) aims at the wrong control: the label is already Minimal. "Minimal" also understates the content (realistic guns aimed at human crowds), so the honest answer is Mild at best, Moderate if the guns stay real.
7. **The store page promises another game, and nobody finds ours.**
   - Title "[EVENT] RAGDOLL HAVOC" with no event running.
   - The 0.20 description, which says "bring up to 6 friends". That is false: a server holds 6, so 5 friends.
   - AI thumbnails of cartoon dummies and a blue sedan, which do not match the game. No video.
   - 5 up / 3 down votes, 17 favourites from 1,328 visits.
   - Not in the top 80 search results for its own name ([omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=ragdoll%20havoc&pageType=all)).
   - Roblox ranks first-play bounce (<60 s and 61-180 s) among its most important signals ([Discovery](https://create.roblox.com/docs/discovery)).
8. **Built for crowds the game does not have.**
   - Friends who join together get separate walled labs and cannot see each other (`Server/Systems/Lab.luau:757-788`, `Client/PlotPrivacy.luau`).
   - The plaza is the only shared space.
   - One server-wide event queue turns your BIG RED BUTTON into "Busy" because of a stranger's event you cannot see (`Server/Systems/Playground.luau:899-906`).
   - Every genre leader runs 1-player servers. Intentional co-play days are still a ranked signal.
9. **The reasons to stay and to come back are invisible.**
   - The play-gift clock is drawn on a button that is hidden on every device (`Client/GiftClock.luau:47-58`).
   - Settings cannot be opened on PC or tablet.
   - The daily reward is paid in eggs automatically, with no claim moment. The streak resets strictly at UTC midnight.
   - The notification opt-in is spent, but no notification is ever sent.
   - The favourite ask comes after 3-8 min, but only 9 % of players reach 5 min (badges: Five Minutes 84 of Welcome 931).
   - Only 15 of 314 users (about 5 %) came back after more than 6 h.
10. **Every decision so far was tuned on noise, with no telemetry.**
    - 6 builds in about 30 hours (136 commits).
    - Session_v1 cannot say what was on screen when a player left. There is no error telemetry.
    - One boot error stops saving and purchases for a whole server (`Server/Main.server.luau:14-119`). Skipped tests count as PASS.
    - Script Sync writes into the live place. Performance has never been measured on a phone.
    - Vault: "get a few hundred sessions first; one change at a time".

**Context.** Hyper Realistic Ragdoll (HRR) averages 20.35 min per visit and BRP 11.58 min ([Rolimons](https://www.rolimons.com/game/101277003916102)). Both launched in the same weeks as us, so the idea is proven and the wave is now. Our gap is execution, the first minute and the presentation, not the feature list.

## 3. Scorecard now
| Area | Now | Why | 10/10 means |
|---|---|---|---|
| A First impression | 3 | Four instruction layers; hooks land after most players have left; weak first toy; signpost on the spawn | Control in under 8 s; first knock-down in 10 s with a big flop; one line and one pointer; a WOW toy in hand by 30 s |
| B Core feel | 4 | Popper hits barely show; feedback waits for the server; camera drifts; three slow-mo systems | Every input answers in the same frame; readable reactions by body part; real hit-stop; one slow-mo; measured on a phone |
| C Goals and progression | 3 | About 15 overlapping systems; no goal on phones; unlocks that downgrade; timers that fail silently | One mission card, one Next pill, upgrades on a sawtooth curve, one currency, a Stunt Book |
| D Content | 3.5 | About 20 machines share one verb; the cannon is found by about 5 %; no spawning; 16 of 21 events hidden live | 4 hero machines in view with their own verbs and scores, a SPAWN button, 10-12 hero events, use measured |
| E Lab and world art | 3 | Six themes on one plot; Neon; white dummies on light grey; props that do nothing | One identity, one material set, composed for a 39° view, every prop a toy |
| F Maps and travel | 3 | 5 thin maps; instant teleport; hidden on phones; built for crowds | 3 dense maps one tap away; you land at the hero machine; each map has its own light and sound |
| G NPCs | 4 | Strong ragdoll core, but silent; 5 of 6 flee; all alike; creatures far away | Dummy types, voices, one act per personality, creatures that come to you |
| H Social | 2 | Friends walled apart; other players invisible; empty plaza; invites carry nothing | Friends land together; a one-tap invite with launch data; an opt-in fling ring |
| I UI/HUD | 4 | Settings unreachable on PC; hooks drawn on hidden buttons; two HUDs; medical words | One phone-first HUD family; at most 4 things on screen in the first 30 s; every window reachable on every input |
| J Audio | 3.5 | Rewards silent; egg silent; no ambience; flesh squelch | Layered sounds per verb, a reward ladder, zone ambience, a phone mix, haptics, licensed sounds only |
| K Performance | 4 | Never measured on a phone; always-on replay recorder; neighbour labs streamed; 115 sounds preloaded | Live fps/memory telemetry; phone fps p5 ≥ 30 in the busiest scene; memory < 800 MB |
| L Money | 3 | Most of the store at id 0; ULTRA weak; prices 4-10x the market; paid eggs; nothing measured | About 14 honest items at 5-699 R$; no paid random items; live prices; funnel measured |
| M Retention | 2.5 | Clock invisible; eggs paid automatically; strict UTC streak; opt-in wasted | One REWARDS hub, a claim moment, a rolling streak with exclusive prizes, a Daily Stunt, a real notification sender |
| N Store and discovery | 2 | Stale title and text; AI art of another game; 16+ gate; no video | Honest title, text, art and video; all-ages reach; always one event coming up |
| O Code and tests | 3 | No fault isolation; skip counts as PASS; flaky tests; sync into live; no CI | DEV/STAGING places, CI, journey tests, a crash-free gate, zero flaky tests |
| P Safety and policy | 3 | Listed Minimal but honestly Moderate; media sharing forces 16+; paid random items; pleading NPCs | An honest label, banned-word tests, PolicyService, no paid random items, kid-safe reactions |
| **Overall** | **about 3** (owner: 2) | The parts exist; the first minute, the presentation and the reach fail | Median first visit ≥ 10 min, D1 ≥ 13-16 %, open to all ages, rating ≥ 85 % |

## 4. The vision
**Ragdoll Havoc is the kid-safe crash-test lab.**

You spawn in your own lab with a full toy bar and three padded dummies in front of you, and the first tap sends one flying with a cartoon BONK. Every hit reacts by body part: a wobble, a spin, dizzy stars. Every launch earns a CRASH score you try to beat. One goal at a time takes you through the cannon, the bullseye, the wrecking ball and the creatures, and a Stunt Book shows what is still to find. Bring a friend and they land next to you, and you take turns throwing each other into the cannon. Come back tomorrow for the Daily Stunt and your streak prize. No blood, no deaths, no pop-ups in your face: just slapstick that feels great on a phone held upright.

**The loop in one sentence:** knock, launch and fling crash-test dummies (and yourself, and your friends) through crazy machines for the biggest crash score, then beat your best.

**How the plan weighs the three angles:**
- **Retention first decides the order.** V8-0 and V8-1 only touch the first ten minutes, because the data says players leave at 20-45 s, and Roblox says to fix core gameplay first when retention is low ([DevForum](https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575)).
- **Quality and polish are a rule on every step** (§10, Rule 1), not a separate phase, so nothing ships flat.
- **Growth is split.**
  - Now, because it is cheap, owner-only and urgent: the honest store text and product descriptions, 3 honest captures in place of the AI icon and thumbnails, the Kids & Select requirements, and fixing the false claims.
  - Only after Stage A (V8-4): the video, thumbnail tests, growth ads and creators, because a TikTok spike on a 2-minute game hurts ranking for weeks ([RoWatcher](https://rowatcher.com/news/why-your-roblox-game-goes-viral-on-tiktok-and-dies-on-platform)). The small measurement burst at each gate (§8) is not a growth push.
- **Money is last (V8-5).** Spend counts in ranking, but below retention.

## 5. What we cut or hide
Cut means removed from what players see. Code is deleted in V8-6.6 unless a switch must stay.

- **First minute:**
  - the bar hint, the help line and "Now try another tool!" while FirstVisit runs;
  - the touch hand while the greeter pointer shows;
  - the whole first-minute tool lock (STARTERS, UNLOCK_FALLBACK, the first-replay unlock);
  - the false toasts;
  - the Fork/Hub signposts at the spawn;
  - the auto-egg modal for newcomers;
  - the chase before 300 s and 15 KOs;
  - "Welcome back!" for players with under 300 s played.
- **Words and reactions (mild):**
  - "kills" (becomes KO);
  - the pulse / % / DEAD hit card, and the 60 s green corpse (KO stars instead, if the owner agrees in Sitting 1);
  - hands-up pleading lines, scream spreading, the crawling state;
  - purple bullet holes on bodies, and the flesh-squelch sounds;
  - Doctor mode (L), HospitalCharts and the Dead monitor setting (if the owner agrees in Sitting 1);
  - blade blurbs that promise severed limbs.
- **Goals:**
  - stars and the Level badge (merged into one Lab Rank);
  - the Rank & Eggs window and the separate dares (they move into REWARDS);
  - eggs as a reward currency, and "Next egg in 75 takedowns";
  - timers on solo mission cards;
  - Poke, Slap and Shove on the early ladder, and Heal (moves later as "Patch-up");
  - the BUY button that buys the next rung one takedown away.
- **World:**
  - the TODAY'S MACHINE pill, NEW tags, Neon plot lines, the plaza edge boards;
  - the second tower, the dead props (unless they are made to work), and the leaderboards facing the spawn;
  - the 360-part paths (replaced by terrain paint);
  - the landscape beyond the hedges;
  - 6 of the 9 creatures, decided from V8-0.8's `used` data: all 9 stay visible until it names the 3 that players use;
  - the FREE LAB walls for plots 7-10 (PLOT_COUNT follows SERVER_SIZE).
- **Social and maps:**
  - the SINGLEPLAYER portal and MAKE MY OWN (a false profile-join promise);
  - the MULTIPLAYER arch (becomes a plaza gate);
  - the country column in the server list, and the VIP boards;
  - "12 people" on map cards, which counts NPCs;
  - the horde every 600 s;
  - the Game Arena as its own room (it becomes stations);
  - the Squid-Game-style "guard" framing.
- **UI:**
  - HudPlus's hidden WEAPONS button, the Deal card and the sandbox column (dead code);
  - the Robux packs column and "FAN FAVOURITE";
  - CLIPS & LIVE for non-creators;
  - emoji in text, the duplicate ammo count, the duplicate LAB VIEW;
  - two of the three theme token layers.
- **Audio:**
  - the slide whistle everywhere except the banana;
  - the second and third landing layers, and the ricochet whine;
  - the punch sound on a grenade throw;
  - reload recordings used as the minigun spin-up and railgun charge.
- **Money:**
  - ULTRA as the featured headline;
  - BOLTS sold for Robux (Bolt Crate, EntryPack);
  - eggs inside any paid product, and VIP's "eggs come faster";
  - TODAY'S DEAL's daily midnight countdown, and typed "R$" prices;
  - LIKE_CODES;
  - the VIP Lab, Giant Fan and Mega Trampoline passes;
  - paid events inside the free BIG RED BUTTON pool;
  - the map-arrival booths.
- **Store:**
  - the [EVENT] tag and the two past events;
  - the false description lines;
  - the AI icon and thumbnails (3 honest captures replace them in V8-0.1);
  - art/store/v4 (usernames, a stranger's avatar, debug signs) and the 2D doodle set;
  - "0.x" version names;
  - the text-circle pass icons.
- **Policy:**
  - `PromptShareCapture` and global build codes, until PolicyService and the questionnaire allow them;
  - TikTok gift names in the UI;
  - owner trolls on strangers who have not opted in.
- **Code:**
  - WORLD_V2/WorldDress, plus the off branches of ZONE_FLOOR, TODAY_LIGHT, SPIKE_BLOCKS, VIEW_CARD, LOOK_V3, UI_V2, BANNER_V7, ARENA_V2 and UI_CLEAN;
  - `src/` and the stray root files;
  - `validRadio`;
  - T99_NetProbe (moves to `tools/`);
  - owner-only modules loaded for every player.
  - Birds stay off; the switch stays, but BirdModels leaves ReplicatedStorage.

## 6. Phases
Tests from T109 up are all new; "T1xx extended" means a later step adds cases to a test an earlier step created. Modules and docs that do not exist yet are marked (new) where they first appear.

### V8-0 Stop the bleeding (days, before 1 Dec)
**Goal:** a new player's first hits knock a dummy down with a big, funny flop; they keep their toys, hear one voice and can see where the cannon is on every device; and we can finally see why they leave.

**How V8-0 ships:**
- **Day 1:**
  - read `StarterGui.ScreenOrientation` in the place (Studio, read only) and write the value in State (V8-0.5);
  - owner Sitting 1 (V8-0.1), with the session's drafts and captures ready.
- **0.25.1, no gameplay change (first):** V8-0.8 (telemetry and the play-as-newcomer mode), the safe boot from V8-0.9, and the V8-0.1 store text going live the same day. It collects a 0.25 baseline cohort while 0.2-0.7 are built.
- **0.26, the bundle:** V8-0.2 to V8-0.7 and the rest of V8-0.9.
- **V8-0 is one bundle, said outright.** It puts about nine behaviour changes into one build. That breaks this plan's own rule "one change per build" (§9) and the vault rule quoted in finding 10, on purpose: at about 15 new players a day, one change per build would take months. No single change inside 0.26 gets the credit or the blame. 0.26 is judged mainly by playtest round 1, and its numbers against the 0.25.1 cohort (§8).
- **Must ship before 1 Dec (the core):** 0.2, 0.3, 0.4, 0.6, the safe boot and the Christmas path fix from 0.9, and 0.8. If 0.26 cannot make 1 Dec, the Christmas path fix goes out alone as 0.25.2.
- **May slip to 0.27:** 0.5 (built only if upright play is confirmed), and the NPC-reaction and Doctor-removal parts of 0.7. Everything else ships in 0.26.
- **Publishing:** each build goes through RELEASE.md, run by `/klar`, if the owner approves per-build publishing in Sitting 1 (§1, Order 5).

#### V8-0.1 Owner sitting 1: reach, store truth and the first decisions (no code)
- **Prepared by the session before the sitting:**
  - the description text;
  - rewritten product descriptions, drafted from the code;
  - 3 honest Director captures of the current build (HUD off, names hidden).
- **What it covers:**
  - Creator Hub > Publish Settings > Manage Audience: note which Kids & Select requirement is missing.
  - Turn on 2-Step Verification and ID verification. Choose Plus/Premium or the refundable per-game fee.
  - Title: "Ragdoll Havoc 💥".
  - Paste the honest description. Line 1: "Launch, smash and fling ragdoll crash-test dummies in your own physics sandbox lab: a cannon, 60+ weapons, cars and a gorilla rampage." Line 2: "🎄 Christmas Lab opens 1 December." Drop "up to 6 friends", "every week" and the SANDBOX/share lines.
  - **Product descriptions:** paste the rewritten texts for Dummy Rain, Mega Bomb and the other live event products. Each says what really happens and where (your lab), not "the whole server".
  - **Icon and thumbnails:** the 3 captures replace the AI icon and thumbnails (one is cropped as the icon). The video and thumbnail personalisation stay in V8-4.3.
  - Hide the two ended Experience Events. Create "🎄 Christmas Lab opens" for 1 Dec, with a real capture.
  - **Test accounts:** name 1-2 adult test accounts for the play-as-newcomer mode (V8-0.8). Never the owner's own account.
  - **Decisions, asked here before any code** (§9):
    - KO stars instead of the green dead body (he chose green on 10 Nov);
    - removing Doctor mode (L), HospitalCharts and the Dead monitor from the build (his M11 feature);
    - confirm TOY_NAMES.
    - A "no" keeps that piece as it is. V8-0.7 builds only what he approved.
  - **Publishing per build:** the owner approves or refuses publishing per build through RELEASE.md (§1, Order 5). Nobody publishes by hand with Alt+P, except as RELEASE.md's own last resort.
- **Why:**
  - finding 6 and 7; areas N, L and P. The search for "ragdoll havoc" misses us; the description has a false claim;
  - the live Dummy Rain and Mega Bomb texts promise the whole server, while labs are private;
  - mismatched thumbnails cost reach and raise first-minute bounce (high-confidence research), and they break Rule 4 (Truth);
  - the KO-stars, Doctor and TOY_NAMES choices are the owner's alone (§9), so they are asked before V8-0.7 is built.
- **Done when:**
  - the games API shows the new title, text, icon and thumbnails;
  - the virtual-events API lists only the Christmas event;
  - the live product descriptions match the drafts;
  - the Manage Audience status, the three decisions and the publishing answer are written in State.
- **Tests:** read the games, virtual-events and developer-product APIs (the store-truth check in V8-4.4).
- **Switch:** none · **Effort:** S · **Owner:** yes

#### V8-0.2 The first hit lands
- **What it covers:**
  - **Greeter route (audit A, high/high, PLAUSIBLE):** the greeter's route may be computed at the plaza spawn before the player is moved into their lab. Verify it first: T109 asserts that the greeter reaches the player inside their own lab within 5 s of the first frame. If it fails, fix `GreeterService.route` (compute the route after the move into the lab).
  - **First hits:** a newcomer's first 3 body hits with any tool knock the dummy down with a big readable flop. The push on a chest shot is raised so the body staggers back (about 20 studs/s), the head snaps back, the leg buckles.
  - **Impact layer for every gun hit with BLOOD off:**
    - 6-10 pooled white/yellow puff particles;
    - a 60 ms white flash on the struck part;
    - a dry mannequin "thwack" instead of the flesh bank;
    - no body holes.
  - **Feedback from the client, not the server:** a hit tick, a 2D KO "thock", and a small "KO" stamp by the crosshair. The server stays the source of truth for the count.
  - **Fleeing:** no dummy flees in a newcomer's first 60 s. After that, only the one dummy that was hit runs, for about 1.2 s, and at most 2 run at once.
  - **Aim help:** aims at the torso, never the head.
  - **Pad pass (console):**
    - the torso aim help above also for pads (today `PokeController.luau:1257` calls `assisted()` only when `ViewMode.isTouch()`);
    - the pad crosshair at screen centre, not on the player's own head (`GrabController.luau:690`);
    - pad-glyph strings only while a pad is the last input: no "Click", "1-6", "T all weapons" or "B sandbox" (B ragdolls him);
    - the on-screen "Menu" label renamed (for example "MORE", with the D-pad-down glyph), so it no longer sends him to Roblox's ≡ menu and its Leave button.
- **Why:**
  - the playtest (7 shots for the first knock-down; "98% health");
  - `FxController.luau:910-917,1145-1149`; `HitMath.luau:22-24`;
  - `Lab.luau:493-520` (5 of 6 flee from every shot);
  - `Crosshair.luau:337-344` (the X waits for the server);
  - time played follows takedowns one to one (finding 1);
  - audit A: V8-0.2 and T150 both depend on "the first tap on the greeter";
  - the Xbox persona: console leaves fastest (71 % under 1 min on 0.20+), with no aim help, the crosshair on his head and keyboard text on the TV.
- **Done when:**
  - on a play-as-newcomer player (V8-0.8) at 414x814 in Studio, the greeter reaches the player inside their own lab within 5 s of the first frame, and the first tap on it knocks it flat with a visual within 1 frame and the sound within 50 ms;
  - 3 takedowns are possible within 20 s in a scripted run;
  - on a pad at 1080p, RT at the greeter knocks it flat with the crosshair at screen centre, and a string scan finds no keyboard or mouse word while a pad is the last input;
  - before/after captures exist.
- **Tests:** T109_FirstHit (greeter in the player's own lab within 5 s of the first frame; push threshold; impact layer present with BLOOD off; 0 BulletHole parts; flesh bank not played; pad aim help on the torso; pad crosshair at screen centre); T24 updated.
- **Switch:** `V8_FIRST_HIT` · **Effort:** M · **Owner:** no

#### V8-0.3 A full bar that stays yours
- **What it covers:**
  - **Start bar** (`Toys.DEFAULT_LOADOUT`): 5 of 6 slots filled at spawn: Popper, Grab, Bat, Grenade, Launch. Slot 6 is the first unlock at 3 KOs, a WOW toy such as the Rocket.
  - **Ladder:** Poke, Slap and Shove leave the early rungs. Heal moves later (V8-2.5 "Patch-up").
  - **autoEquip rules:**
    - never auto-select a tool while one is in use or fire is held;
    - replace only the weakest slot, and only with a stronger tool;
    - never replace a gun, an explosive or the Bat;
    - an egg or crate prize always lands in the hand: no pick-a-slot step, no 10 s timeout;
    - "It's on your bar" is said only when it is true.
  - **Older profiles:** keep what they own (`LoadoutStore.validate`), with a one-time loadout migration (a profile flag, so it runs once): Poke, Slap and Heal leave the bar; Bat, Grenade and Launch go in. The rest stays in WEAPONS.
  - **Next pill on phones** (here, so it ships whatever the orientation): "Next: Rocket 2/3" from `HudV3.drawNext`, under the top-left row from 0 s. Tapping it opens WEAPONS.
- **Why:**
  - finding 3: all 5 simulated players; `ProgressUI.luau:632-647`; `PokeController.luau:745-797,1693-1719`;
  - the day-2 persona: the bar stays clogged with Poke, Slap and Heal, which autoEquip never gives up, so "It's on your bar" is false;
  - finding 5 and area C: phones show no next goal at all;
  - HRR starts with ten filled slots ([guide](https://allthings.how/?p=358267));
  - DevForum: lower early prices "so players reach the more interesting gameplay sooner".
- **Done when:**
  - a scripted run of unlocks 0..30 shows the bar's power never falls, every gun or explosive lands on the bar, and the held tool never changes while fire is held;
  - a saved bar of Popper, Grab, Poke, Slap, Heal loads once as Popper, Grab, Bat, Grenade, Launch, and the migration never runs again;
  - SHOOT never disappears in 3 minutes of scripted phone play;
  - LayoutCheck shows the Next pill with 0 problems on every phone size.
- **Tests:** T110_HandRules (with the one-time migration); T35 and T56 updated; LayoutCheck.
- **Switch:** `V8_START_BAR`, `V8_HAND_RULES` · **Effort:** S · **Owner:** no

#### V8-0.4 One voice on screen
- **What it covers:**
  - **Guidance while FirstVisit runs:** only the FirstVisit line plus one pointer. The greeter's diamond; the touch hand only if there is no shot within 6 s, and then it says "Press SHOOT".
  - **Experiment card:** waits until FirstVisit ends, then takes the same spot.
  - **Reveal:** one reveal number (QUIET_START). Remove FirstVisit.MIN_QUIET's override.
  - **Notices:** all reward notices go through Notify (`ProgressUI.luau:587-589`). The LaunchGift goes into the first reward. No text names a button the player cannot see.
  - **False toasts:** delete them (the list in finding 4, plus the "UNLOCKED: X! Find it in WEAPONS" / "on your bar" pair, and the hazard tip shown after the hazard is done).
  - **Stuck steps:** a stuck hint at 20 s, an off-screen edge arrow to the target, and an automatic skip at 45 s, not 300.
  - **Spawn:** remove the Fork/Hub signposts and add a 10-stud keep-clear circle to `PathPlan.OBSTACLES`.
  - **Cannon in view (the minimum before V8-2.2):** the spawn is turned so the 3 dummies and the cannon both sit in the spawn camera's view on PC, tablet and a landscape phone. Where the view is too narrow (an upright phone without V8-0.5), the dummies come first and the edge arrow points at the cannon whenever a step names it. The full re-layout stays in V8-2.2.
  - **Pace:** at most one toast per 15 s in the first 3 minutes.
- **Why:** finding 4; finding 5 (the cannon sits 82-97° right of the spawn camera); area A; area D (the cannon is found by about 5 %); area I (the pill overlaps the card at 414 px); `FirstVisit.luau:39,206`; `ExperimentCard.luau:71-83`.
- **Done when:**
  - a recorded 150 s newcomer timeline shows at most 1 objective and 1 pointer at every sample;
  - no two big pop-ups come less than 15 s apart;
  - none of the false strings is ever sent;
  - projecting the 3 dummies and the cannon through the spawn camera puts both on screen at 1920x1080 and on a landscape phone; at 414x814 the dummies are on screen and the edge arrow points at the cannon;
  - LayoutCheck measures FirstVisitGoal and the experiment card: 0 problems on 16 screens.
- **Tests:** T111_FirstTimeline (hooks FeelBus, Notify and HudSlots); T112_SpawnView (the spawn-camera projection); T55 rewritten as an order/gap check; LayoutCheck.
- **Switch:** `V8_ONE_VOICE` · **Effort:** M · **Owner:** no

#### V8-0.5 An upright phone that works (only if upright play is confirmed)
- **First, the check:**
  - The repo never sets `StarterGui.ScreenOrientation` (grep: 0 hits), so the place file decides it, and nobody has checked that value. Day 1 reads it in the place and writes it in State.
  - The "upright" data may be an artefact: `SessionClient.luau:72-80` reads ViewportSize once, within 2 s of client start, and never again.
  - 0.25.1 records `orient10/30/60` (V8-0.8) before anything here is built.
- **The rule:** build this step only if `orient30` and `orient60` show most phones still upright after load (from at least 20 real phone visits, or from most of round 1's phones). If they do not, the V8-1.8 landscape decision comes forward to that moment, and this step is dropped.
- **What it covers (if built):**
  - **Portrait camera profile** in the single FOV writer (FxController): vertical FOV set from the aspect ratio so the horizontal view is at least 55°, and re-applied on rotation.
  - **Spawn camera:** a little further back with a slight downward pitch, so the 3 dummies, the cannon and the bullseye arc are all in frame at 414x814 (V8-0.4 only turns the spawn). The full re-layout comes in V8-2.2.
- **Why:** finding 5; area B (39° tunnel); area A (the orientation finding); 105 of 108 phone visits read upright at boot.
- **Done when:**
  - projecting the dummies, the cannon and the bullseye through the 414x814 spawn camera puts all of them on screen;
  - before/after captures at 414x814;
  - LayoutCheck shows 0 problems, including the 4 portrait phones.
- **Tests:** T112 extended (portrait camera); LayoutCheck.
- **Switch:** `V8_PORTRAIT_CAM` · **Effort:** M · **Owner:** no. May slip to 0.27. If built, the landscape-or-portrait decision still comes in V8-1.8.

#### V8-0.6 A calm first three minutes
- **What it covers:**
  - **Chase:** no NPC chase for a newcomer before 300 s played and 15 KOs (both).
  - **Windows for newcomers:** no window opens by itself before 180 s (egg card, What's New, favourite). The first WOW toy (slot 6) arrives as a 1.5 s non-blocking reveal straight into the hand.
  - **What's New for returners:** a non-modal chip in the top bar from the first frame, not a window. Only its OPEN or GOT IT button marks it seen; a backdrop tap never does.
  - **First-wow UFO:** only when it falls inside the spawn view (lowered for portrait), and it never knocks the player during a FirstVisit step. Otherwise it is skipped.
- **Why:**
  - simulated players: the chase at 100 s is "an ambush"; the egg modal at 60-70 s blocks play;
  - on 0.24 most players leave between 60 s and 3 min (82 % gone by 3 min, n 11), the window where the egg modal and the chase land;
  - V8-0.2 aims for 3 takedowns in 20 s, so "or 15 KOs" would bring the chase back at about 60-90 s;
  - the day-2 persona: What's New opens mid-tap at about 13 s and a backdrop tap marks it seen forever; a flat 180 s rule would move it past the measured 158 s quit, so returners would never see what is new;
  - [DevForum on intrusive prompts](https://devforum.roblox.com/t/let-us-disable-non-essential-in-game-prompts/4699372);
  - `Surprises.luau:126-176`.
- **Done when:**
  - T111 shows, for a newcomer, no modal before 180 s and no chase before 300 s and 15 KOs;
  - a returner sees the What's New chip from the first frame, and it stays until a button is pressed;
  - in playtest round 1, no kid quits during a chase or a modal.
- **Tests:** T111 extended; T123_ChaseGate.
- **Switch:** `V8_CALM_START` · **Effort:** S · **Owner:** no

#### V8-0.7 Mild and honest
- **What it covers:**
  - **Words:**
    - "kills" becomes "KO" everywhere;
    - mild blurbs for Axe, Cleaver, Katana, Chainsaw, SMG and Nuke;
    - the hit card becomes a 1 s "BONK! Head" / "KO!" pop (no %, no pulse, no DEAD);
    - a knocked-out body shows dizzy stars and pops back up instead of turning green (only if approved in Sitting 1);
    - TOY_NAMES kept or changed as the owner answered in Sitting 1.
  - **NPC reactions (may slip to 0.27):** taunts instead of pleading ("Missed me!"), no hands-up surrender at guns, no scream spreading, no crawling state shown.
  - **Removed from the build (only if approved in Sitting 1; may slip to 0.27):** Doctor mode (L), HospitalCharts and the Dead monitor setting.
  - **No paid random items:**
    - VIP's egg perk becomes a fixed perk (dashboard text by the owner);
    - the Robux weapon fallback pays fixed BOLTS;
    - the Starter Pack text has no eggs.
  - **Sold events out of the free pool:** a data change. The events sold as products (Dummy Rain, Mega Bomb and the rest) leave the BIG RED BUTTON's free pool.
  - **Notifications:** `EXPERIENCE_NOTIFY = false` until the sender is live (V8-3.5), so the once-per-30-days opt-in is no longer spent for nothing.
  - **Media sharing:** `PromptShareCapture` and global build codes off; save-to-gallery stays. CLIPS & LIVE's streamer section shows only for the owner or a private-server owner, with no TikTok gift names.
  - **Other text:**
    - What's New loses the bird lines;
    - LIKE_CODES become update codes;
    - the event and product texts in the Shop/Events data match the V8-0.1 descriptions.
- **Why:**
  - areas P, B, L and M;
  - [content maturity](https://create.roblox.com/docs/production/promotion/content-maturity): media sharing is 16+ only, and the questionnaire must cover the most extreme content a player can reach;
  - area L: the free button gives the paid Mega Bomb and Dummy Rain every 75 s;
  - area M: the opt-in is spent, and no notification is ever sent;
  - the owner's rules: never reward likes, no brands;
  - the evidence: `Toys.luau:251-255`, `DummyLines.luau:11-22`, `Shop.luau:24,37`, `CreatorUI.luau:121-132`, `BuildStore.luau:9-12`.
- **Done when:**
  - a banned-word scan over every player-visible string finds nothing (kill, dead, blood, limb, attached, butcher, pulse, organ);
  - no Robux path grants an egg;
  - 500 seeded rolls of the free button never give a sold event;
  - `EXPERIENCE_NOTIFY` is false;
  - a capture of the KO pop;
  - the owner re-answers the questionnaire honestly in V8-0.10.
- **Tests:** T115_MildText (extends T57), T116_NoPaidRandom, T68 updated (sold events out of the free pool).
- **Switch:** `MILD_V8` · **Effort:** M · **Owner:** part (the VIP dashboard text; the Sitting 1 decisions)

#### V8-0.8 See why they leave
- **What it covers:**
  - **New Session_v1 fields:**
    - `owner` (game.CreatorId; left out of reports), `newPlayer`, and `test` (play-as-newcomer visits, below; also left out);
    - `frame0`: the client's first frame. Every `first*At` and `orient` time counts from it, not from PlayerAdded (the server joins 3-5 s earlier);
    - `orient10/30/60`: ViewportSize read again at 10, 30 and 60 s and on every orientation change (today it is read once, within 2 s of client start);
    - `bootOk`, `bootFail`, `errs`, `errSig` (first 3 traceback heads);
    - `fpsP50`, `fpsP5`, `memMb`;
    - `firstKnockAt`, `firstLaunchAt` (the first cannon shot, of the player or a dummy), `firstMissionDoneAt`;
    - `used`: the first-use second for each machine, creature, vehicle, map and event, and for the BIG RED BUTTON;
    - `friendsMax`: the most Roblox friends of the player in the same server at once during the visit;
    - `onScreenAtLeave` (chase / modal / window / objective step);
    - `sfx` and a master-volume bucket.
  - **Play-as-newcomer mode (before playtest round 1):**
    - `Config.TEST_ACCOUNTS` (new): an allowlist of adult test accounts, never the owner's own (the second account seen on the owner's phone goes on it);
    - such an account joins the live game as a newcomer on every visit: a blank profile in memory that is never saved over its real one, `Newcomer` true, passes ignored, and no owner perks (IsOwner off, no admin, no OWNER or VIP tag);
    - its Session_v1 records carry `test = true`;
    - in Studio, `StudioFresh` turns the same mode on for the Studio user (today the owner stays IsOwner, VIP, ULTRA and Returning there, so Studio never shows a real newcomer).
  - **Funnel:** new steps, renamed in OnboardingService: Joined, FirstHit, FirstKO, FirstLaunch, FirstMission, Min3, Min5, Min10.
  - **tools/SessionReport:** per build × device, a "gone by 10/20/30/45/60/90/120/180/300 s" curve from `frame0` with n, D1 per first-visit cohort, the `used` shares, `friendsMax`, and the orientation at 10/30/60 s.
- **Why:**
  - finding 10; the Studio-stats correction (finding 1); finding 5 (orientation read once at boot);
  - areas K, O and J (no fps, error or volume data);
  - area D (content use not measured, high/high) and area H (co-play unmeasured): V8-2.7 reads `used` and the co-play KPI reads `friendsMax`;
  - the test caveat: the Studio test user is never a real newcomer, and the game is 16+ only, so round 1 needs a live newcomer path.
- **Done when:**
  - one Studio record (SessionStudio) has every field;
  - SessionReport prints the curve without the owner's and the test accounts' visits;
  - a listed test account (and the Studio user under StudioFresh) loads as a newcomer with no passes or owner perks, and its saved profile is unchanged afterwards.
- **Tests:** T113_SessionFields, T146_PlayAsNewcomer.
- **Switch:** none · **Effort:** M · **Owner:** part (names the test accounts in Sitting 1). Ships in 0.25.1.

#### V8-0.9 Fix what is broken (small)
- **What it covers:**
  - **Settings:** an opener on PC, tablet and console (a MENU row and a key).
  - **Gift clock:** a visible gift chip on every layout.
  - **Clips:** CLIP IT's callback takes `(result, capture)` (`ReplayController.luau:286-291`).
  - **Boots (ships in 0.25.1):** server and client `safeStart` (pcall each system, a `BootFailed` attribute). Purchases, ProgressService and SessionStats start first.
  - **Christmas (core, live before 1 Dec):** the Christmas spots added to `PathPlan.OBSTACLES` or moved; T106 run with Christmas on.
  - **Tablet thumb zones:** on tablets the HudV3 squares leave the move-thumb zone (bottom left), and MENU no longer covers RAGDOLL. LayoutCheck checks the thumbstick zone on the tablet sizes. The full one-HUD rebuild stays in V8-6.7.
  - **Sounds:**
    - fill the Theme.Sounds slots reward/unlock/purchase/error/hover (a paid purchase is silent today: `LihFolkUITheme.luau:283-290`);
    - egg wobble ticks;
    - the preload key "G17" becomes "Blaster", and the starter banks load first (`FxController.luau:1455`).
  - **Self-test runner:**
    - SKIP is counted on its own;
    - `task.cancel` on timeout;
    - exact test-number match;
    - duplicate numbers renamed (T40, T41, T42, T99);
    - `Tests/Lib` (new: waitFor, withHold), brought forward from V8-6.4.
- **Why:** areas I (Settings; the day-2 tablet: HudV3 squares steal the move thumb and MENU covers RAGDOLL), M, J, E (the Christmas spots sit on the paths from 1 Dec) and O (one boot error kills saving).
- **Done when:**
  - a thrown error in a fake system still lets the later systems start;
  - every `playSound("<name>")` literal maps to a non-empty slot;
  - T106 passes with Christmas on;
  - LayoutCheck shows no HUD square in the thumbstick zone and nothing over RAGDOLL on the tablet sizes;
  - the runner prints `DONE pass= fail= skip=`.
- **Tests:** T114_SafeBoot, T106, T122_SoundSlots; LayoutCheck.
- **Switch:** none · **Effort:** M · **Owner:** no

#### V8-0.10 Ship 0.26 and measure
- **What it covers:**
  - **Builds:** 0.25.1 first (see "How V8-0 ships"), then 0.26. Each goes through RELEASE.md (gate, backup, publish, restart old servers, check), run by `/klar`, if the owner approved per-build publishing in Sitting 1; otherwise 0.26 carries 0.25.1's parts and publishes at the end of V8-0. Use Roblox's "Restart servers for updates" with auto-reconnect instead of a hard shutdown ([DevForum](https://devforum.roblox.com/t/automatically-reconnect-to-experiences-during-updates/2866485)).
  - **Owner:**
    - re-answers the questionnaire honestly (after V8-0.7);
    - does a 15-minute soak on his phone (and a cheap Android if he can get one);
    - runs playtest round 1 (§7) on the test accounts in play-as-newcomer mode.
  - **Owner decision:** the V8-0 gate's ad burst: one small Ads Manager "Plays" campaign for phones, to bring 0.26 to 100 new players within 7 days (ad users do not count for ranking: [Discovery FAQ](https://create.roblox.com/docs/discovery-faq)).
- **Why:** finding 10 (tuned on noise); the vault ("a few hundred sessions first").
- **Done when:**
  - 0.26 is live;
  - the V8-0 gate (§8) is read and written in State: by its numbers if at least 100 new players arrived within 7 days of the publish, otherwise by round 1's criteria.
- **Tests:** the full suite once; LayoutCheck.
- **Switch:** none · **Effort:** S · **Owner:** yes

**V8-0 exit:** the V8-0 column of the gate table in §8. With fewer than 100 new players within 7 days of the 0.26 publish, playtest round 1 decides by its criteria in §8.

### V8-1 The new first ten minutes
**Goal:** a loop that never runs dry: score, goal, upgrade, again. Stage A.

#### V8-1.1 The CRASH score
- **What it covers:**
  - **What scores:** every launch, whether a dummy or yourself: cannon, stations, wrecking ball, a throw, an explosive.
  - **How it scores:** from air time, distance, flips, bounces, machine hits and the bullseye. Named mild tricks ("BOUNCE x3", "MEGA FLIP") and a chain multiplier.
  - **On screen:** a live count-up over the body, then a landing chip with the score, your best, and a big AGAIN button under the right thumb.
  - **Saved:** a best per machine. A daily best board in the lab.
  - **Built from:** `ShareCode.scoreOf` and FeelBus Launch/Land.
  - **Cannon flight (the minimum payoff before V8-2.3):**
    - a longer, higher arc with about 2.5-3 s of air time, instead of today's 1.0 s real-time hop that peaks about 23 studs up; it still lands on the bullseye (`Playground.cannonLanding`);
    - a slow-mo beat at the top of the arc that also slows the player's own avatar (today SlowMotion slows only dummies);
    - a BULLSEYE ding with a short cheer on the landing (brought forward from V8-1.5).
- **Why:**
  - DevForum: players "leave right after the ragdoll fall ... lack of post-fall goals" ([thread](https://devforum.roblox.com/t/ragdoll-game-feedback/3924157));
  - Broken Bones IV (1.54 B visits), Turbo Dismount and Goat Simulator all score the chaos;
  - our score exists only inside the X-ray replay;
  - the TikTok persona came for the cannon and quits at about 125 s: a flat 1.0 s hop with no slow-mo and no payoff sound; Stage A asks ≥ 60 % to fire the cannon, so the payoff cannot wait for V8-2.3.
- **Done when:**
  - a scripted cannon flight scores the same every time and saves a best;
  - a scripted cannon shot of the player stays in the air at least 2.5 s, gets the slow-mo beat and the ding, and lands on the bullseye;
  - count-up and summary captures on phone portrait and PC;
  - in round 2, kids say a score or press AGAIN.
- **Tests:** T117_CrashScore (with the cannon flight time).
- **Switch:** `STUNT_SCORE` · **Effort:** M · **Owner:** no

#### V8-1.2 Hits you can read
- **What it covers:**
  - **Reactions by body part:** leg = wobble/hop; arm = dangle; head = dizzy stars, then KO; chest = double over.
  - **State word:** at most 2 on screen (Dizzy / Wobbly / Knocked out).
  - **Hit-stop:** a real 66-80 ms stop on the struck body, for melee and big hits only. Light hits get sound and a flash, nothing more.
  - **Camera:** the shake and recoil offset is undone each frame, so the view never drifts.
  - **Slow-mo:** one system, and it slows the player's own avatar too, not only dummies. The player's Z key, a SLOW-MO button on phones (today the control is PC-only), plus one rare automatic beat at most once per 15 s (the V8-1.1 cannon beat is one of them), restoring real speed with no 90 cap.
  - **Settings:** a reduced-motion setting.
- **Why:**
  - HRR's per-limb reactions are its product;
  - area B: hit-stop freezes only the camera; the camera drifts (`FeelV2.luau:96-114`); three slow-mo systems (`SlowMotion.luau:39,228-288`);
  - the TikTok persona: SlowMotion never slows the player's own avatar, and a phone has no slow-mo control at all;
  - Kao 2020: no juice and extreme juice both cut play time ([dblp](https://dblp.uni-trier.de/rec/journals/entcom/Kao20.html)).
- **Done when:**
  - each body part shows its motion within 0.1 s of the hit;
  - after 20 recoil kicks, the camera pitch is unchanged within 0.5°;
  - slow-mo slows the player's avatar as much as the dummies, and LayoutCheck places the phone SLOW-MO button with 0 problems;
  - a 60 fps capture of 10 scripted moments on PC and on a phone tier shows input to visual within 1 frame and to sound within 50 ms.
- **Tests:** T118_Reactions, T119_CameraDrift; LayoutCheck.
- **Switch:** `REACTIONS_V8` · **Effort:** M · **Owner:** no

#### V8-1.3 One mission chain
- **What it covers:**
  - FirstVisit and Experiments merge into one card: an icon, at most 24 characters, a bar.
  - **The fixed chain of 8:**
    1. KO the greeter;
    2. swing the Bat;
    3. throw a dummy into the CANNON;
    4. land the BULLSEYE;
    5. throw the GRENADE;
    6. ride the WRECKING BALL;
    7. 10 KOs;
    8. open the Stunt Book.
  - **Rewards:** each step pays an instant, shown reward (a BOLTS chip, or a crate whose prize is shown on the card).
  - **No silent fail:** no timers on solo cards, SKIP after 60 s.
  - **After the chain:** cards scaled to the player's stage, and never a creature or map card before the player has seen that creature or map.
  - **Saved:** the chain position is saved in the profile.
- **Why:**
  - area C: 62 % of first cards ask for things out of reach; cards with timers vanish silently (`ExperimentCard.luau:409-410`);
  - BRP: 40-66 % of new players find each machine ([badges](https://badges.roblox.com/v1/universes/10773926254/badges));
  - endowed progress ([Nunes & Drèze](https://knowledge.wharton.upenn.edu/?p=5630)).
- **Done when:**
  - the chain order holds, its position is saved, solo cards have no timer, and a newcomer never gets a creature card;
  - in round 2, at least 4 of 5 kids finish 3 missions.
- **Tests:** T120_MissionChain; T60 and T63 updated.
- **Switch:** `MISSION_CHAIN` · **Effort:** M · **Owner:** no

#### V8-1.4 Unlocks that feel like presents
- **What it covers:**
  - **Ladder:** a sawtooth (3, 8, 15, 25, 40, 60, 85, 115, 150, 200 ...) of real upgrades only.
  - **Reveal:** every unlock gets a 1.5 s non-blocking reveal (a Ui3D turning model, its name, a chord) and lands in the hand.
  - **One goal:** one `Shared/NextGoal.of` (new) feeds every "Next" surface.
  - **One currency:** a BOLTS counter on every device that counts up. BOLTS buy any locked weapon 5 or more rungs away, and cosmetics.
  - **One rank:** stars removed; Level merged into one Lab Rank whose steps give real rewards.
  - **Eggs** leave the loop. Crates show their prize before opening.
- **Why:**
  - area C: three different "next" definitions; BOLTS have no counter; BOLTS buy the rung one takedown away (`Economy.luau:129-145`);
  - the vault's pacing notes; RDP's visible coin count-up.
- **Done when:**
  - no rung on the ladder is a downgrade;
  - every surface names the same next goal;
  - Session_v1 records `unlocks` and `firstUnlockAt`;
  - captures exist.
- **Tests:** T121_Ladder; T64 updated.
- **Switch:** `LADDER_V3` · **Effort:** M · **Owner:** no

#### V8-1.5 Sounds that reward
- **What it covers:**
  - **UI reward family** (one synth palette, not shared with any world sound): pop, tick, unlock (3 notes), rare (5 notes), purchase coin, error buzz. Crate reveals sound different by rarity.
  - **KOs:** a takedown "thock" with a chime that rises per combo, and a visible "x2 / x3 COMBO" tied to the slow-mo beat.
  - **Cannon:** fuse, boom and whistle (the BULLSEYE ding came in V8-1.1).
  - **Explosive tells:** grenade pin and rising ticks, C4 beeps, a Nuke siren.
  - **Landings:** one owner for the landing sound (FeelV2). The slide whistle only for the banana.
  - **Mix:** a LUFS gain column, a phone EQ, InverseTapered rolloff.
  - **Haptics:** on phones and pads, on the same moments.
  - **Licensing:** ripped sounds are replaced over time by licensed ones.
- **Why:**
  - area J: rewards and egg are silent; cannon and BULLSEYE share one whoosh; the "M9K" and Pixel Gun 3D rips;
  - [haptics](https://devforum.roblox.com/t/full-release-you-can-now-publish-haptic-effects-in-your-experience/3660577).
- **Done when:**
  - every fx id maps to its own bank;
  - a listening pass on a phone is noted in State;
  - captures with sound.
- **Tests:** T122 extended (SoundPlan: every fx id has its own bank); T41 updated.
- **Switch:** `AUDIO_V8` · **Effort:** M · **Owner:** no

#### V8-1.6 The chase, fair and later
- **What it covers:**
  - **Timing:** the first chase after 300 s and 15 KOs (both).
  - **Warning:** a siren and "THEY'RE COMING!", then 2 chasers burst through a gate in view.
  - **Punches:** a visible wind-up and a whoosh. Three hits throw you; no HP bar.
  - **Counting:** each chaser knocked down once is out and sits dizzy, so the counter only counts down.
  - **Ending:** a celebration when cleared.
- **Why:** area G (`ChaseService.luau:30-42,193-205`: invisible punches, a counter that is wrong, an ambush on newcomers); the playtest at 125 s.
- **Done when:** Chase_Cleared ≥ Chase_Time in Metrics after 48 h; capture.
- **Tests:** T123 extended (ChaseFair: wind-up, a counter that only counts down, the celebration); T50 updated.
- **Switch:** `CHASE_V8` · **Effort:** S · **Owner:** no

#### V8-1.7 Phone diet
- **What it covers:**
  - **Replay:** records only bodies in your own lab, at 15 Hz, into a ring buffer, and only around big moments.
  - **Sounds:** banks load lazily.
  - **Ragdolls:** ActiveRagdoll caches attributes and sleeps calm bodies.
  - **Owner tools:** AdminPanel, Director and Spectate are required only for the owner.
  - **Windows:** built on first open.
  - **Assets:** BirdModels out of ReplicatedStorage while birds are off.
  - **Streaming:** a tuned `StreamingTargetRadius`, FX filtered by `Zones.mayEnter`, and a non-persistent plaza crowd.
- **Why:** area K (`ReplayController.luau:121-148,489-501`; `FxController.luau:1437-1482`; neighbour labs streamed in, `PlotPrivacy.luau:1-12`).
- **Done when:**
  - Session_v1 shows phone fps p5 and memory before and after;
  - the Script Profiler's top 5 are fixed;
  - the lab part budget holds.
- **Tests:** T124_PerfBudget.
- **Switch:** per item · **Effort:** M · **Owner:** no

#### V8-1.8 Orientation decision and playtest round 2
- **What it covers:**
  - Round 2 (§7).
  - The owner decides `FORCE_LANDSCAPE` from rounds 1-2 and from Session_v1's `orient10/30/60` and orientation-versus-leave data.
  - If V8-0 already settled it (V8-0.5 dropped because phones turn landscape after load, and the decision was brought forward), this step only runs round 2 and confirms the decision.
- **Why:** the Roblox default is landscape ([ScreenOrientation](https://create.roblox.com/docs/reference/engine/enums/ScreenOrientation)); every leader's phone layout is landscape; our real phone players read as upright at boot.
- **Done when:** the decision is written in State with its numbers.
- **Tests:** LayoutCheck in both modes.
- **Switch:** `FORCE_LANDSCAPE` · **Effort:** S · **Owner:** yes (decision)

**V8-1 exit, Stage A:** the Stage A column of the gate table in §8. With fewer than 100 new players within 7 days of the publish, playtest round 2 decides by its criteria in §8.

### V8-2 One lab, one look
**Goal:** the lab reads as one designed place from the first frame, and everything that looks like a toy is one. (Do only after Stage A, or when round 2 names the lab as the problem.)

#### V8-2.1 Pick the identity
- **What it covers:**
  - The owner picks one sentence. Recommended: "outdoor crash-test park".
  - `docs/STYLE_LAB.md` (new): 6 colours, the material set, where models come from, and a "not this" list.
- **Why:** area E: six themes and three levels of finish on one plot; the leaders each have one identity.
- **Done when:** the file is approved by the owner.
- **Tests:** none.
- **Switch:** none · **Effort:** S · **Owner:** yes

#### V8-2.2 The lab as one stage
- **What it covers:**
  - **Core:** a compact core with 3 dummies at 12-15 studs.
  - **Hero machines:** 4 inside a 60° cone of the spawn camera at 15-45 studs: the cannon firing across the view, the wrecking ball, explosive barrels, and a pin wall or drop tower. This replaces V8-0.4's spawn turn.
  - **Everything else:** in a second ring. One hero vertical (the second tower is cut). The boards move off the spawn view.
  - **Plots:** `PLOT_COUNT` follows `SERVER_SIZE`.
- **Why:**
  - area E: the spawn view on an upright phone shows no machine;
  - area D: the Bullseye badge reaches 4.8 % of players (45/931), against BRP's cannon at 41 %;
  - the vault's world-composition notes.
- **Done when:**
  - every hero machine projects on screen at spawn at 414x814 and at 1920x1080;
  - captures from spawn, the cannon and the back;
  - the walking and driving tests pass.
- **Tests:** T125_LabStage; T112, T36, T39 and T106 updated.
- **Switch:** `LAB_V8` · **Effort:** L · **Owner:** no

#### V8-2.3 Every toy-looking prop is a toy
- **What it covers:**
  - **Props:** barrels explode, chain and respawn; crates break; the fan blows; the rocket becomes a sled or is cut.
  - **Cannon:** aimable (drag or hold for power), with score rings on the bullseye (the flight itself was tuned in V8-1.1).
  - **Drop tower:** a flop score.
  - **Stations:** the 3 become one launch pad with a dial.
  - **Hint:** while you hold a dummy, a ghost shows "drop it here".
  - **Badges:** one per machine (the owner creates them).
- **Why:** area D (about 20 machines share one verb; dead props: `LabDress.luau:1-25`); BRP's barrel chain reaction reaches 55 %.
- **Done when:**
  - each prop works on both dummies and players;
  - the badge ids are pasted.
- **Tests:** T126_PropsWork.
- **Switch:** `PROPS_LIVE` · **Effort:** M · **Owner:** part (badges)

#### V8-2.4 Ground, light and a sound bed
- **What it covers:**
  - **Ground:** terrain grass with flush concrete lanes (terrain paint replaces the 360-part paths), and a play ground dark or green enough that white dummies separate in a greyscale test on a phone at quality 1.
  - **Materials:** no AI-generated MaterialVariants. Neon only on indicators under 1 stud: the cannon pad becomes a steel plate with chevrons.
  - **Light:** tuned on the phone (about 15:00 sun, a warm key light, a little more colour).
  - **Sound:** ambience beds per zone, loops on the machines, and decorative shadows off.
- **Why:** area E (white on light grey is about 1.8:1; noon light is flat); area J (zero ambience).
- **Done when:**
  - the greyscale capture passes;
  - a phone capture before and after;
  - frame time stays in budget.
- **Tests:** T124 (re-run), T127_Ambience.
- **Switch:** `LOOK_V8` · **Effort:** M · **Owner:** no

#### V8-2.5 Dummy types and a SPAWN button
- **What it covers:**
  - **Types:** MINI, HEAVY, BOUNCY and FLOPPY, each with a chest plate.
  - **Spawn:** G, the phone's "+DUMMY" or the pad's D-pad drops the chosen type at the aim point. The server checks it, it is capped by the device tier, and Reset cleans up.
  - **Revive:** R revives the body under the crosshair with a funny bounce-back ("Patch-up", the kid-safe medic verb).
  - **Unlocks:** types are a second unlock track.
- **Why:**
  - area G/D: HRR's "G Spawn / R Revive" and its 8 labelled types;
  - 6 dummies is too few to feed 69 tools.
- **Done when:**
  - spawns respect the device cap;
  - captures of the line-up.
- **Tests:** T128_SpawnDummy.
- **Switch:** `DUMMY_TYPES` · **Effort:** M · **Owner:** no

#### V8-2.6 Dummies with a voice and a personality
- **What it covers:**
  - **Voice:** 4 kid-safe cartoon vocal banks (whoa/wheee, oof, grumble, yelp), at most 2 at once.
  - **Barks:** for Fly, Grabbed, Cannon, Creature, Frozen, Revived and Witness, at most 2 lines on screen.
  - **Personalities:**
    - one Coward, who bolts briefly;
    - the Brave one slaps back: a harmless ragdoll, 8 s cooldown, never in a newcomer's first 60 s;
    - the Clown laughs;
    - Sleepy dozes.
  - **Greeter:** waves, says one line, then joins the row.
  - **Prompts:** dummies are named, and the Talk prompt is hidden while a weapon is out.
- **Why:** area G: the personality layer is dead code under LOOK_V3 (`DummyLife.luau:1187-1191`); there are no vocal banks; the leaders' dummies fight back.
- **Done when:**
  - the brain's choices pass with a seeded random;
  - in round 3, kids mention a dummy reaction.
- **Tests:** T129_Personalities. Its pure brain lets T19 and T32 leave the flaky list.
- **Switch:** `DUMMY_LIFE_V8` · **Effort:** M · **Owner:** no

#### V8-2.7 Creatures that come to you
- **What it covers:**
  - **Which:** the 3 that players use most, by V8-0.8's `used` shares (the owner confirms them in Sitting 3; round 1-2 notes break a tie). All 9 stay visible until `used` has those shares; then the other 6 are hidden. They go in a garden zone beside the dummies.
  - **Players too:** they take players, cartoon-style (swallow and spit).
  - **Sound:** each gets idle and work sounds.
  - **Motion:** runs on the clients from one server start event.
  - **Hint:** a carried dummy glows toward the nearest hungry creature.
- **Why:** area G and E: the creatures are 78-115 studs from the dummies, take dummies only, are silent, and are moved by the server (`LabCreatures.luau:91-131,682-691`); area D: a hidden creature can never be measured, so the cut waits for the data.
- **Done when:**
  - Session_v1 `used` shows the creature share before and after the move;
  - captures.
- **Tests:** T130_CreaturesPlayers; T108 updated.
- **Switch:** `CREATURES_V8` · **Effort:** M · **Owner:** part (confirms the 3)

#### V8-2.8 One sign language
- **What it covers:**
  - one `MachineNames` (new) table used by every sign, card, toast and path;
  - one label component: an icon and at most 2 words, shown within about 30 studs, at most 3 at once;
  - fix the "'S LAB" possessive.
- **Why:** area E: 6 sign systems in 5 fonts, and up to 3 names per machine.
- **Done when:** a capture shows at most 3 labels at once.
- **Tests:** T131_Signs.
- **Switch:** `SIGNS_V8` · **Effort:** S · **Owner:** no

#### V8-2.9 Hero events
- **What it covers:**
  - cut 21 events to 10-12, each with a real model and its own guest victims;
  - merge the duplicates (Zero-G and Moon Gravity, the Fan event and the Fan tool, Sinkhole and the Black Hole tool);
  - a lab-local roulette on the button.
- **Why:** area D: 16 hidden, several built from primitives; most act on only 6 dummies.
- **Done when:** each event has a picture, a model and victims.
- **Tests:** T132_HeroEvents; T107 updated.
- **Switch:** `EVENTS_V8` · **Effort:** L · **Owner:** part (the list)

#### V8-2.10 Maps worth the trip (the cheap part)
- **What it covers:**
  - a MAPS button on phones;
  - before arrival, `RequestStreamAroundAsync`, a loading card and an arrival sting;
  - you arrive 15-20 studs in front of the map's hero machine;
  - travel is refused while seated or grabbing.
  - Keep 3 maps (Island, City, Site); hide Farm and Army Base (owner decision).
- **Why:** area F: an instant pivot into an unstreamed map; arrival 60-270 studs from anything; maps hidden on phones.
- **Done when:**
  - Session_v1 shows the share of trips and seconds per map;
  - captures.
- **Tests:** T133_MapTravel; T26 updated.
- **Switch:** `MAPS_V8` · **Effort:** M · **Owner:** part

### V8-3 Friends and tomorrow
**Goal:** a reason to bring someone, and a reason to come back. Stage B.

#### V8-3.1 Friends land together
- **What it covers:**
  - Roblox friends are mutual lab guests by default (a saved setting, ON).
  - A joiner gets the plot next to their friend, with a gate open between the labs.
  - A "<friend> IS HERE · GO" card; a Prank Party starts, and new members join a running one.
  - **Owner:** reserve 2 server slots for friend joins on the dashboard.
- **Why:** area H: friends are walled apart and take about 6 taps to meet; co-play days are a ranked signal ([Discovery](https://create.roblox.com/docs/discovery)).
- **Done when:** in a 2-client test, two friends are together in one lab within 10 s.
- **Tests:** T134_FriendsTogether (StudioTestService multiplayer, V8-6.4's runner); T67 updated.
- **Switch:** `FRIENDS_TOGETHER` · **Effort:** M · **Owner:** part

#### V8-3.2 An invite at the right moment
- **What it covers:**
  - One invite card per visit, after 3 min, at the first bullseye, a combo or a replay.
  - `PromptGameInvite` with a PromptMessage and LaunchData; the server reads `GetJoinData` (ReferredByPlayerId).
  - A qualified arrival (the friend stays 180 s) gives both players a cosmetic. Opening the prompt gives nothing.
  - Joining a friend in a reserved server works through MemoryStore.
- **Why:** area H: `FriendsUI.luau:219-237` passes no options; nothing reads the join data; MAKE MY OWN's promise is false.
- **Done when:** a scripted arrival with LaunchData is credited once.
- **Tests:** T135_InviteJoinData.
- **Switch:** `INVITES_V8` · **Effort:** M · **Owner:** part (the notification string)

#### V8-3.3 One REWARDS hub
- **What it covers:**
  - Rank & Eggs, Rewards and the Experiments extras merge into one window with three tabs: TODAY, COLLECTION (the Stunt Book and badges), CODES.
  - A gift button with a live red count and a pulse on every layout.
- **Why:** area M/I: three windows overlap; the badges sit on hidden launchers (`RewardsUI.luau:134-136`).
- **Done when:** the count is visible on all 16 LayoutCheck screens.
- **Tests:** T136_RewardsHub; LayoutCheck.
- **Switch:** `REWARDS_HUB` · **Effort:** M · **Owner:** no

#### V8-3.4 A reason for tomorrow
- **What it covers:**
  - **Streak:** a rolling window (claimable 20 h after the last claim, kept for up to 48 h) and one automatic freeze per week.
  - **Welcome back:** a card with a big CLAIM button and a pop.
  - **Prizes:** exclusive streak prizes that are not on the ladder (a golden Popper skin, a trail, a "7-DAY" crown).
  - **Tomorrow:** a "TOMORROW: Day 2 = ..." chip at 75-90 s.
  - **Daily Stunt:** one machine and one target for everyone, by UTC day, with a daily best.
  - **Dares:** EASY, MEDIUM and HARD, sized to a 5-10 minute visit.
  - **Play gifts:** an 8-gift ladder, tap to open, counting active minutes only.
- **Why:**
  - area M: strict UTC streak (`ProgressService.luau:1575-1579`); day-2/day-7 prizes already owned; eggs paid automatically;
  - only about 5 % of users come back.
- **Done when:**
  - the rolling-window and freeze maths pass;
  - Session_v1 records `streak`, `dailyClaimed` and `daysSinceFirst`.
- **Tests:** T137_Streak; T42 and T43 updated.
- **Switch:** `STREAK_V8` · **Effort:** M · **Owner:** no

#### V8-3.5 Asks done right
- **What it covers:**
  - **Favourite:** a small chip (not a window) after the first real wow, at the earliest 90 s, once per visit. Skipped if `GetFavoriteAsync` is true; a decline snoozes it for 7 days. No reward, ever.
  - **Notifications:** `EXPERIENCE_NOTIFY` goes back to true only here, once the server sender is live (V8-0.7 turned it off). The opt-in comes only right after a streak claim, after our own context card.
  - **Owner:** dashboard notification strings and the Open Cloud package. The sender sends at most one a day ("Your Day 4 gift is ready").
- **Why:** area M/N: the ask comes after most players have left; the opt-in prompt shows at most once per 30 days ([docs](https://create.roblox.com/docs/production/promotion/experience-notifications)); favourites per new player: BRP 10.7 %, HRR 0.9 %.
- **Done when:**
  - Session_v1 records `favAsked` and `favOk`;
  - the sender is tested on the owner's account.
- **Tests:** T138_AskRules; T100 updated.
- **Switch:** `ASKS_V8` · **Effort:** M · **Owner:** part

#### V8-3.6 Shared space only where it is real
- **What it covers:**
  - **Events:** a per-lab event slot, so a stranger's event never blocks your button. Paid events run in every lab and name the buyer.
  - **Plaza:**
    - a live presence pill and real player counts on the card;
    - an opt-in FLING RING for player-vs-player hits and grabs;
    - Roblox blocks honoured in both directions.
  - **Portals:** SINGLEPLAYER and MAKE MY OWN cut; the MULTIPLAYER arch becomes an in-server "TO THE PLAZA" gate.
- **Why:** area H/F: `Playground.luau:899-906`; plaza PvP with no consent; `PortalService.luau:131-133`.
- **Done when:** in a 2-client test, two labs run events at the same time.
- **Tests:** T139_LabEventSlot; T44 and T51 updated.
- **Switch:** `SHARED_V8` · **Effort:** M · **Owner:** no

#### V8-3.7 A weekly rhythm
- **What it covers:**
  - weekly boards with a reset and a crown for the top 3;
  - the Saturday show as a Roblox Experience Event;
  - a code with every update (never tied to likes);
  - **Owner:** create the group, send the GROUP_ID; the join gift is a cosmetic.
- **Why:** area M/N: all-time boards only; the game is on a personal account; the leaders run events with RSVPs.
- **Done when:** the week key rolls over in a test; the group is live.
- **Tests:** T140_WeeklyBoards.
- **Switch:** `WEEKLY_V8` · **Effort:** S · **Owner:** part

**V8-3 exit, Stage B:** the Stage B column of the gate table in §8. With fewer than 100 new players within 7 days of the publish, playtest round 3 decides by its criteria in §8.

### V8-4 Be found
**Goal:** the right players see an honest page and can play. Growth ads and creators come only after Stage A (the small measurement burst at each gate, §8, is separate).

#### V8-4.1 All-ages reach
- **What it covers:**
  - Finish the Kids & Select requirements.
  - Answer the questionnaire honestly: Moderate still reaches Select (9-15); Mild is needed for Kids (5-8).
  - Ads Manager "Qualify for Kids and Select" until Manage Audience shows 100/100.
  - Add IARC ratings to the checklist.
- **Why:** finding 6; the [Ads Manager docs](https://create.roblox.com/docs/production/promotion/ads-manager).
- **Done when:** Manage Audience shows all ages.
- **Tests:** none (dashboard).
- **Switch:** none · **Effort:** S · **Owner:** yes

#### V8-4.2 The toy pass for Kids (optional)
- **What it covers:**
  - toy finishes on the guns (bright colours, orange tips) and toy-real sounds (punchy, no room tail);
  - Nuke becomes "Mega Boom", C4 becomes "Sticky Boom";
  - crowds become crash-test robots;
  - Red Light becomes "Robot Freeze".
- **Why:** area P: real guns aimed at humans is a Moderate picture. On 10 Nov the owner wanted real gun sounds.
- **Done when:** the owner decides, and the questionnaire is re-answered.
- **Tests:** T115 extended.
- **Switch:** `TOY_LOOK` · **Effort:** L · **Owner:** yes (decision)

#### V8-4.3 Honest art and a video
- **What it covers:**
  - Director captures with the HUD off and names hidden, replacing the 3 interim captures from V8-0.1.
  - 5 thumbnails on 2-3 ideas (cannon launch, car through a dummy row, gorilla swat, X-ray, friend toss).
  - A one-subject icon from the real dummy face.
  - A 20-30 s gameplay video whose first 2 s are the biggest knock-down (no lyrics, no voice).
  - 14 days of thumbnail personalization with a written hypothesis.
  - Real pass icons.
- **Why:**
  - finding 7;
  - [thumbnails docs](https://create.roblox.com/docs/production/promotion/thumbnails);
  - games with video get up to +39 % playtime from Recommended For You ([DevForum](https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571)).
- **Done when:** uploaded; the result is read after 14 days.
- **Tests:** a privacy checklist in RELEASE.md (no usernames or boards in any capture).
- **Switch:** none · **Effort:** M · **Owner:** part (upload)

#### V8-4.4 Search words and store truth
- **What it covers:**
  - a fixed title, with one dated seasonal slot;
  - hand-entered translations that keep "Ragdoll Havoc";
  - badge descriptions;
  - one public version name ("Update 26");
  - a release gate that compares the What's New lines and the description against the live switches.
- **Why:** area N: auto-translation renames the brand; What's New promised birds that are switched off.
- **Done when:** the gate fails on a planted false line.
- **Tests:** T141_StoreTruth.
- **Switch:** none · **Effort:** S · **Owner:** part

#### V8-4.5 The clip moment
- **What it covers:**
  - The X-ray replay becomes a ready clip of at most 12 s that includes the player's own body. It ends on a card with the score and the game name, inside the 9:16 safe area.
  - One SAVE button. SHARE appears only if `Policy.luau` (new; PolicyService: IsContentSharingAllowed, AllowedExternalLinkReferences, fail-closed) and the questionnaire allow it.
  - Share links carry launchData, so a friend who joins lands at that machine with "Beat 412".
- **Why:**
  - the growth research: the clip is the main growth asset;
  - [CaptureService](https://create.roblox.com/docs/reference/engine/classes/CaptureService);
  - no PolicyService anywhere today.
- **Done when:** the policy stub blocks SHARE; a launchData join lands at the machine.
- **Tests:** T142_ClipShare.
- **Switch:** `CLIP_V8` · **Effort:** M · **Owner:** part (questionnaire)

#### V8-4.6 The traffic plan
- **What it covers:**
  - only after Stage A: a small phone "Plays" campaign of 300-500 sessions per build (the measurement burst at each gate, §8, is separate and smaller);
  - share links per channel;
  - refresh docs/CREATOR_KIT.md;
  - 10-20 small creators, with the disclosure rules;
  - no paid push before Stage B.
- **Why:** [RoWatcher](https://rowatcher.com/news/why-your-roblox-game-goes-viral-on-tiktok-and-dies-on-platform); area N (about 15 new players a day).
- **Done when:** D1 per link is in SessionReport.
- **Tests:** none.
- **Switch:** none · **Effort:** S · **Owner:** yes

### V8-5 A fair shop
**Goal:** a small, honest store that players who stay want to buy from. Stage C.

#### V8-5.1 The lineup
- **What it covers:** about 14 items, priced from the competitors' live APIs:
  - **First Boom:** 5 R$, once per player;
  - **named single weapons:** 9 to 49 R$;
  - **own-lab event charges:** 19 to 35 R$, plus x3 packs;
  - **category passes:** All Melee 69, All Explosives 79, All Guns 99, Lab Controls 69;
  - **VIP 199:** 2x KOs plus a cosmetic;
  - **Endless Events:** 249-299;
  - **Everything:** 599-699;
  - **cosmetics:** 2 trails and 2 pets, with TRY.
  - Created through Open Cloud if the key allows it, otherwise as one table for the dashboard.
- **Why:** area L ([HRR passes](https://apis.roblox.com/game-passes/v1/universes/10773618503/game-passes?passView=Full&pageSize=50); our tiers are 4-10x the market; ULTRA sells almost nothing).
- **Done when:** the ids are pasted; T68 passes.
- **Tests:** T143_ShopLineup.
- **Switch:** `SHOP_V8` · **Effort:** M · **Owner:** yes

#### V8-5.2 The Starter Pack, honest
- **What it covers:**
  - 29-39 R$, fixed contents with no eggs, once per player;
  - a chip after the first wow, on phones too;
  - no fake timer (none, or a personal timer that starts on first view and is never re-armed);
  - a live price.
- **Why:** `HudPlus.luau:666-670` (a countdown to UTC midnight); typed prices.
- **Done when:** it is bought once, then hidden.
- **Tests:** T143 extended.
- **Switch:** `SHOP_V8` · **Effort:** S · **Owner:** part

#### V8-5.3 A phone-first shop window
- **What it covers:**
  - a FOR YOU row first (Starter Pack, the next weapon with TRY/BUY, today's event);
  - tabs: Weapons, Events, Passes, Cosmetics;
  - live pass prices (`RobuxPrice` with the GamePass type);
  - only computed badges;
  - cosmetics in a tab, not in booths.
- **Why:** area L/I: ULTRA sits first on portrait; passes show no price; "FAN FAVOURITE" is made up.
- **Done when:** LayoutCheck shows 0 problems; no typed "R$" digit outside Shop data.
- **Tests:** T143 extended, LayoutCheck.
- **Switch:** `SHOP_V8` · **Effort:** M · **Owner:** no

#### V8-5.4 Honest promises
- **What it covers:**
  - the live product descriptions (V8-0.1) and the sold events' absence from the free pool (V8-0.7) are re-checked against the code;
  - Zero-G becomes lab-local, so its text stays true;
  - at the end of a trial: "Keep the Minigun? R$ N · Not now";
  - a purchased item goes into the hand with a reveal.
- **Why:** area L: the live Dummy Rain text promised the whole server, and Mega Bomb and Dummy Rain were free from the button every 75 s (both fixed early, in V8-0.1 and V8-0.7).
- **Done when:** each pass effect test meets its promised number.
- **Tests:** T144_OfferPromises.
- **Switch:** `SHOP_V8` · **Effort:** S · **Owner:** part (descriptions)

#### V8-5.5 The money funnel, measured
- **What it covers:**
  - Session_v1 `shopOpen`, `offerSeen`, `promptShown`, `promptDone`, `robux`;
  - AnalyticsService funnel and economy events.
- **Why:** area L: nothing measures the shop.
- **Done when:** SessionReport shows conversion per device.
- **Tests:** T145_MoneyFunnel.
- **Switch:** none · **Effort:** S · **Owner:** no

#### V8-5.6 Platform levers
- **What it covers:**
  - a "Roblox Plus" card the player taps (never a pop-up);
  - paid private servers once the party is fun;
  - rewarded video once the game has 2,000 monthly visitors.
- **Why:** area L.
- **Done when:** each is on, or noted as "not yet" in State.
- **Tests:** none.
- **Switch:** none · **Effort:** S · **Owner:** yes

**V8-5 exit, Stage C:** the Stage C column of the gate table in §8. With fewer than 100 new players within 7 days of the publish, the round-4 shop check decides by its criteria in §8.

### V8-6 Safe and cheap to ship (runs beside the phases)
**Goal:** every change is cheap to make, safe to publish, and proven by tests that tell the truth.

#### V8-6.1 DEV and STAGING places
- **What it covers:**
  - the owner makes a DEV experience (its own DataStores) and a STAGING one;
  - Script Sync points only at DEV;
  - the same build file is promoted to live;
  - a written rollback rule (crash-free under 98 %, or the median 20 % under the last build).
- **Why:** area O: syncing into the live place; Studio play writes to the live profiles.
- **Done when:** a build goes DEV -> STAGING -> live once.
- **Tests:** none.
- **Switch:** none · **Effort:** M · **Owner:** yes

#### V8-6.2 Build stamp and sync check
- **What it covers:**
  - a pre-commit `Shared/BuildStamp` (new);
  - `tools/SyncCheck.luau` (new) hashes every script and compares it with the manifest;
  - the server prints the stamp at boot; Session_v1 stores it; the gate refuses any difference.
- **Why:** area O: two runs were hand-mirrored and checked only by file size.
- **Done when:** a planted one-byte edit is caught.
- **Tests:** a gate step.
- **Switch:** none · **Effort:** S · **Owner:** no

#### V8-6.3 CI and pure tests
- **What it covers:** rokit, selene, a StyLua check, luau-lsp strict and lune pure specs on every push.
- **Why:** area O: about 30 pure tests wait for a 10-12 minute Studio run.
- **Done when:** a push runs in under 2 minutes.
- **Tests:** CI.
- **Switch:** none · **Effort:** M · **Owner:** no

#### V8-6.4 Tests that tell the truth (just before V8-3)
- **What it covers:**
  - a TestArena off the map;
  - one TestMode switch that pauses the ambient systems;
  - T27 split into a pure spec and a physics test;
  - a StudioTestService runner with multiplayer (V8-3.1's T134 is the first 2-client test);
  - a JSON result file.
  - `Tests/Lib` and the runner fixes moved forward into V8-0.9.
- **Why:** area O: 6 tests are accepted as flaky (T27 holds the save merge); hard-coded coordinates are stale.
- **Done when:** 3 green full runs in a row; the flaky list is empty.
- **Tests:** the suite.
- **Switch:** none · **Effort:** L · **Owner:** no

#### V8-6.5 Journey tests
- **What it covers:** J1-J6 in §7.
- **Why:** 62 of 83 client modules are never touched by a test; no journey covers a pad, and console leaves fastest.
- **Done when:** J1-J6 run in the gate.
- **Tests:** T150-T155.
- **Switch:** none · **Effort:** L · **Owner:** no

#### V8-6.6 Cut the dead weight
- **What it covers:**
  - delete the code in §5;
  - live tuning numbers and kill switches through ConfigService (so changes need no republish);
  - every switch gets an owner, a date and an expiry;
  - remove the 42 `(Config :: any)` casts.
- **Why:** area O: 42 switches; typos read as nil; about 9k new lines a day with almost nothing deleted.
- **Done when:** CI fails on an unknown or expired key.
- **Tests:** T01 extended.
- **Switch:** none · **Effort:** M · **Owner:** part (the ConfigService decision)

#### V8-6.7 One HUD
- **What it covers:**
  - one phone-first component tree with layout data per platform;
  - one `DeviceProfile` (new);
  - LayoutCheck walks the live PlayerGui;
  - the round-5 stack is deleted.
- **Why:** area I/O: phones run the legacy HUD; every fix is done twice (the tablet thumb-zone fix came early, in V8-0.9).
- **Done when:** LayoutCheck shows 0 problems on 16 screens, measured live.
- **Tests:** LayoutCheck, T150.
- **Switch:** `HUD_V8` · **Effort:** L · **Owner:** no

#### V8-6.8 ProfileStore
- **What it covers:** load, lock, merge, migrate and save are split out of ProgressService, with a DataStore fake.
- **Why:** area O: a 1,982-line module holds the save path.
- **Done when:** the pure specs cover failure injection.
- **Tests:** a new pure spec.
- **Switch:** none · **Effort:** L · **Owner:** no

### Later (only when the numbers ask)
- Per-map signature machines (crane hook, catapult targets, tank, bus); a crash course for the cars.
- NPC WAR mode; pair machines for the party (tandem cannon, seesaw).
- New Christmas verbs (snowball cannon, sledge run). For 1 Dec, ship only the V8-0.9 path fix.
- 69 -> about 35 weapons, with mastery skins (owner decision).
- A "Stream keys" LIVE mode for outside streamers (no brand names; nothing saved or counted).
- Moments Upload API.

## 7. User testing programme

### Real players
- **Who:** 3 rounds of 5 players ([NN/g: test with 5](https://www.nngroup.com/articles/why-you-only-need-to-test-with-5-users/)), plus a short round 4 (a shop check with 5 returning testers) only when the Stage C gate must fall back (§8).
  - **Accounts:** the live game is 16+ only today (finding 6), so a child cannot join on their own account. Children play on an allowlisted adult test account in play-as-newcomer mode (V8-0.8), signed in on their own phone, with a parent's OK and the parent beside them; or in the DEV place with team-test access, if V8-6.1 is done before round 1. Anyone who plays the live game on their own account must be 16+.
  - Mostly 8-13-year-olds, on their own phones held however they like. At least one cheap Android in each round.
  - In each round, also 1 PC player and 1 tablet or console player.
  - Plus 1-2 players aged 16-17 on their own age-checked accounts: the youngest audience the game reaches today (13-15-year-olds are locked out as well).
- **When:** round 1 after V8-0 (0.26); round 2 after V8-1; round 3 after V8-2/V8-3; round 4 only for Stage C's fallback. Fix the top 3 problems before the next round.
- **Protocol:**
  - a fresh newcomer: an allowlisted test account in play-as-newcomer mode (V8-0.8), or the DEV place (V8-6.1); never the owner's own account (it carries IsOwner, VIP and ULTRA);
  - the owner says only: "Prøv det her spil så længe du har lyst, jeg kigger bare med";
  - no help, no hints;
  - 10-15 minutes, or until they stop;
  - the owner watches in silence with a timer sheet.
- **Afterwards, 5 questions** (in Danish): what was funniest, what was confusing, what would you do next, would you play again tomorrow, how would you tell a friend what this game is.
- **What to record** (sheet: `docs/PLAYTEST.md` (new)):
  - seconds to the first tap, first KO, first launch and first mission done;
  - the first "what now?" or look-away;
  - every request for help;
  - the quit or boredom point, and what was on screen;
  - every laugh (time and cause);
  - the words they use for things;
  - device, orientation, and whether it felt laggy.
- **Privacy:** screen recordings only with a parent's consent, kept locally, never uploaded. No names in the sheet.

### Automated journeys (V8-6.5)
Run with StudioTestService, VirtualInput or the MCP input tools, a fresh profile (play-as-newcomer mode), and the device emulator sizes:
- **T150 J1, new player on an upright phone (414x814):**
  - a tap on the greeter gives a KO within 10 s;
  - one objective line at a time;
  - no modal before 180 s;
  - 0 errors and 0 LayoutCheck problems.
- **T151 J2, new PC player:** click-fire, the Grenade on the bar, the first mission done, WEAPONS opens.
- **T152 J3, returning player:** the welcome-back claim, the saved bar, the full HUD at once, What's New as a chip.
- **T153 J4, two friends (2 clients):** together in one lab within 10 s, grab and throw, a toss combo on both screens.
- **T154 J5, 10-minute soak:** instance count and memory stay flat; 0 errors.
- **T155 J6, new console player (pad, 1080p TV):**
  - RT/R2 at the greeter gives a KO within 10 s, with the crosshair at screen centre and the aim help on the torso;
  - no on-screen string names a key or the mouse;
  - the on-screen MENU label opens our menu, never Roblox's;
  - 0 errors.

### Cheap pre-check
Re-run the five simulated players from this audit after each phase, on the new code. It is a filter before the real round, never a replacement for it.

## 8. KPIs and how to read them
Read everything from `tools/SessionReport.luau` (Studio Edit, read-only), per build × device, **without the owner's own visits and without the test accounts' visits**.

**Rule:** a cell with fewer than 100 new players is a direction, not a verdict. Roblox experiments do not work under 1,000 DAU ([Experiments](https://create.roblox.com/docs/production/experiments)), so we judge by cohorts per build and by the playtest rounds.

**Definitions (every row):**
- **New player:** `newPlayer` true (first visit ever), not the owner, not a test account (`test`).
- **Clock:** seconds from the client's first frame (`frame0`, V8-0.8), not from PlayerAdded.
- **Denominator:** as written in each row. The "gone" shares count all new players who reached a first frame.
- **Baselines:** the 0.24 cohort with the owner left out (n 11), until the 0.25.1 cohort replaces it. These are tiny samples: directions only.

**The gate table (the only one; the phase exits in §6 point here):**

| KPI | Session_v1 / source; denominator | Baseline: 0.24, n 11, owner out (0.25.1 cohort replaces it) | V8-0 exit | Stage A (V8-1) | Stage B (V8-3) | Stage C (V8-5) |
|---|---|---|---|---|---|---|
| Median first visit, new players | `played`; new players | 126 s (144 s without the second account on the owner's phone; all visits, `newPlayer` arrives in 0.25.1) | ≥ 3 min | ≥ 6 min | ≥ 10 min | ≥ 12 min mean (leaders 12-20, [Rolimons](https://www.rolimons.com/game/101277003916102)) |
| Gone before 60 s | leave curve; all new players | 18 % | ≤ 20 %, and not above the 0.25.1 cohort | ≤ 15 % | ≤ 10 % | ≤ 10 % |
| Gone at 61-180 s | leave curve; all new players | 64 % (82 % − 18 %) | ≤ 25 % | ≤ 20 % | ≤ 15 % | ≤ 15 % |
| First KO within 15 s of the first frame | `firstKnockAt`; new players still present at 15 s | not recorded (first shot median 6.8 s) | ≥ 80 % | ≥ 90 % | ≥ 90 % | ≥ 90 % |
| Visits with 0 KOs | `takedowns`; new players | 9 % | ≤ 5 % | ≤ 3 % | ≤ 3 % | ≤ 3 % |
| Fired the cannon | `firstLaunchAt`; new players still present at 60 s | not recorded; first read on 0.25.1 (the Bullseye badge, 4.8 % lifetime, counts landings, not shots) | ≥ 40 % | ≥ 60 % | ≥ 60 % | ≥ 60 % |
| D1 | first-visit cohort; share back 24-48 h after the first join | not measured per cohort (all builds: 15 of 314, about 5 %, came back after > 6 h) | read only | ≥ 8 % | ≥ 13 % (p75) | ≥ 16 % (p90) |
| D7 | same cohort; back on day 7 | not measured | — | — | ≥ 2.5 % | ≥ 4 % |
| Favourites per new player | `favOk`, games API; new players | not measured per cohort (lifetime 1.3 %: 17 / 1,328 visits) | — | ≥ 3 % | ≥ 5 % | ≥ 5 % (BRP 10.7 %) |
| Rating | votes API | 5 up / 3 down (lifetime) | — | — | ≥ 80 % | ≥ 85 % |
| Crash-free sessions | `bootOk` and no fatal `errSig`; all sessions | not measured | ≥ 98 % | ≥ 99 % | ≥ 99 % | ≥ 99 % |
| Phone fps p5, busiest scene | `fpsP5`; phone sessions | not measured | recorded | ≥ 30 | ≥ 30 | ≥ 30 |
| Co-play share | `friendsMax > 0`; all sessions | not measured | — | — | ≥ 15 % | ≥ 15 % |
| Payer conversion | `robux > 0`; DAU | not measured | — | — | — | 1.5-3 % of DAU |

**How a gate is read (V8-0, Stage A, Stage B, Stage C):**
1. If at least 100 new players arrive within 7 days of the publish, the numbers in the gate table decide.
2. Otherwise that phase's playtest round decides, by the criteria below. The gate never waits longer than 7 days plus the round.
3. Each gate has a budget for one small ad burst (an Ads Manager "Plays" campaign on phones, owner decision) to reach the 100. Ad users do not count for ranking ([Discovery FAQ](https://create.roblox.com/docs/discovery-faq)); this is measurement, not a growth push.
4. A gate read either way is written in State, and the next phase starts.

| Gate | Playtest round | Passes when |
|---|---|---|
| V8-0 | Round 1 (after 0.26) | 4 of 5 get a KO in their first 15 s; 4 of 5 play past 3 min; nobody quits during a chase or a modal; no boot failure on any tester's device |
| Stage A | Round 2 (after V8-1) | 4 of 5 finish 3 missions; 4 of 5 fire the cannon without help; 3 of 5 play past 6 min; kids name a score or press AGAIN |
| Stage B | Round 3 (after V8-2/V8-3) | 3 of 5 play past 10 min; a pair of friends meets in one lab without help; 3 of 5 play again the next day on their test account |
| Stage C | Round 4, the shop check (after V8-5) | 4 of 5 can say what each item gives and what it costs; nobody meets a prompt they did not ask for; nobody buys by mistake |

**Where the targets come from:**
- the D1/D7 and session ladders: [GameAnalytics 2026](https://www.gameanalytics.com/reports/2026-roblox-report) percentiles (D1 p50 10.3 %, p75 12.9 %, p90 15.9 %);
- the bounce windows: [Roblox Discovery](https://create.roblox.com/docs/discovery);
- the cannon share: BRP's badges (41 % of all its players; ours is measured on new players still present at 60 s).

**After each publish:** compare the first three days of new players with the three days before.

## 9. Risks and owner-only items

### Risks
| Risk | What we do |
|---|---|
| Tiny samples lead to wrong conclusions | Every gate falls back to a playtest round when fewer than 100 new players arrive in 7 days (§8); one ad burst per gate. From V8-1 on, one change per build where the numbers must tell changes apart. V8-0 is one declared bundle, judged mainly by round 1 |
| Gates stall at about 15 new players a day | Numbers decide only with 100 new players within 7 days; otherwise the phase's playtest round decides (§8) |
| The upright-phone reading is a boot artefact | Day 1 reads `StarterGui.ScreenOrientation`; 0.25.1 records `orient10/30/60`; V8-0.5 is built only if upright play is confirmed, otherwise the landscape decision comes forward |
| 1 Dec slips | A named must-ship core (V8-0); the Christmas path fix can go out alone as 0.25.2 |
| The trend wave fades while we rebuild | V8-0 in days; V8-1 before any new world content; L/XL steps only after Stage A |
| Kids & Select needs 100 highly engaged plays in 60 days, and we get about 15 visits a day | The "Qualify for Kids and Select" ad goal (V8-4.1) once the first session holds |
| The mild pass makes it less fun for the 16+ players we have now | Keep the punch (feel, sound, flops); only the gore-adjacent words and reactions go; round 1 includes 16-17-year-olds |
| Growth (clip SHARE) against reach (media sharing forces 16+) | SAVE only now; SHARE only behind PolicyService and a questionnaire answer that allows it |
| Forcing landscape could lose upright players | Decide on round data and Session_v1 orientation (V8-1.8, or earlier from 0.25.1's data); the switch can be undone |
| Script Sync is down, so changes are mirrored by hand | V8-6.2 sync check; V8-6.1 DEV place |
| Publishing kicks players | "Restart servers for updates" with auto-reconnect; at most one restart a day |
| Genre moderation is volatile (the HRR takedown) | Stay mild, label honestly, put "no blood" on the page |
| Credits spent on gold-plating | Rule 2; one blind review per phase; steps only from evidence; reviews advise, the gates decide |

### Owner-only items (batched into sittings)
1. **Sitting 1 (V8-0.1, Day 1, about 1.5 hours):** Manage Audience, 2SV, ID, Plus or the fee; title; description; the product descriptions; the 3 captures as icon and thumbnails; hide the past events; create the Christmas event; name the adult test accounts; the three decisions (KO stars, Doctor removal, TOY_NAMES); approve or refuse publishing per build.
2. **Sitting 2 (V8-0.10):** re-answer the questionnaire; phone soak; playtest round 1 on the test accounts; decide the V8-0 ad burst; update VIP's description. (RELEASE.md publishes 0.25.1 and 0.26 if per-build publishing was approved.)
3. **Sitting 3 (V8-1.8 / V8-2):** the orientation decision (earlier, if 0.25.1's data settles it); the Stage A ad burst; the lab identity; confirm the 3 creatures from `used`; hide Farm and Army; machine badges; playtest round 2.
4. **Sitting 4 (V8-3/V8-4):** reserve friend slots; create the group and send its id; notification strings and the Open Cloud package; free private servers (if wanted); the weekly event; upload thumbnails, video and pass icons; the Stage B ad burst; playtest round 3.
5. **Sitting 5 (V8-5):** products and passes (or an Open Cloud key with the right scopes); the Plus card; private-server price; the Stage C ad burst, or the round-4 shop check.
6. **Sitting 6 (V8-6.1):** the DEV and STAGING experiences (earlier, if children test in DEV for round 1).

**Decisions only the owner can make:**
- **asked in Sitting 1, before any code:**
  - KO stars instead of the green dead body (he chose green on 10 Nov);
  - removing Doctor mode (L), HospitalCharts and the Dead monitor (his M11 feature);
  - confirm TOY_NAMES;
  - publishing per build instead of once at the end of a whole plan (the 20 Nov order);
- real or toy gun look and sound (he chose real sounds on 10 Nov);
- whether to delete the SEVERING and purple-BLOOD paths (or make them build-time only);
- the friends-first server model (keep 6, reserve 2 friend slots);
- 69 -> about 35 weapons;
- hide 2 of the 5 maps;
- the ad burst at each gate.

## 10. Rules for every step
These are the same as V7, except that the blind review runs once per phase (CLAUDE.md):
- **Captures:** before and after, from fixed named spots (phone portrait 414x814, phone landscape, PC 1920x1080, console 1080p), judged against HRR and BRP. Nothing may look code-built, cheap or "AI".
- **Models:** real Creator Store models in one style, with the malware pass on every insert. Note in State what lives only in the place file, and remind the owner to save.
- **Settings:** Config switches, numbers in Config (in LiveConfig once V8-6.6 lands), and the server decides. Every switch has an owner, a date and an expiry; the losing branch is deleted one release after the switch settles.
- **Phones:** the low-tier budget holds and LayoutCheck shows 0 problems.
- **Tests and review:**
  - a `T1xx` self-test where it can break again (every test from T109 up is new; "extended" means a later step adds cases to it);
  - per step: only the Rule 1 checklist and the affected tests;
  - one blind reviewer per phase (pass bar 8.5, at most 3 fix rounds), not per step;
  - reviews advise; the gates in §8 decide when a phase is done.
- **Content:** kid-safe and mild. No brands or trademarks. Never reward likes. No new free-form text. Nothing from TikTok LIVE is saved or counted. BLOOD off, SEVERING off.
- **After each step:** commit and push, update State, and send a short Danish report (Lavet / Test selv / Brug for fra dig).

**New rules:**

1. **Super satisfying. Every step passes this checklist before review:**
   - Every input answers in the same frame: sound within 50 ms, visual within 1 frame (predicted on the client), a pop and a sound within 100 ms.
   - Every hit reads without blood: a puff or flash, a reaction by body part, a kid-safe sound layer.
   - Every reward has motion, a number and a sound from the reward ladder, and lands in the hand. No "find it in a menu".
   - Juice has a budget: light hits get no stop and no shake; heavy hits get a 66-80 ms stop and a shake; peak moments get slow-mo and the replay. Reward animations stay under about 10 % of play time.
   - Nothing takes control away: no auto-select of a weaker tool, and no window over the action.
   - Sound lead-ins are trimmed (30-80 ms of silence makes a hit feel floaty).
   - Felt on a real 30 fps phone held upright, with reduced motion respected.
   - The playtest question: does a kid laugh, or say "again"?
2. **The cheapest path that keeps quality:**
   - Reuse what exists before building anything new: the ActiveRagdoll regions, `ShareCode.scoreOf`, `HudV3.drawNext`, Notify, PathPlan, the Director, ReplayController, FeelBus.
   - Data before code: Toys order, Config numbers, ConfigService.
   - Cut before you add: every step deletes something.
   - Run only the affected tests while working; the full suite once per phase.
   - One blind review per phase, never per step.
   - Steps are ordered by player value per hour of work. No new world content before Stage A.
   - Owner dashboard work is batched into sittings, never one task at a time.
3. **Every step says who sees it, in which second, on which device, and how it is logged.**
4. **Truth:** every store line, What's New line, product description, store picture and toast matches a live switch and what really happens.

## Appendix A: the satisfying pass, interaction by interaction
A separate read-only audit (20 Nov) for the owner's "Sørg for alt er super satisfying". Its numbers are the starting values for Rule 1. Sources: Vlambeer "The art of screenshake" (youtube.com/watch?v=AJdEqssNZ-U), "Juice it or lose it" (GDC 2012, gdcvault.com/play/1016487), Eiserloh "Juicing your cameras" (GDC 2016), Roblox HapticEffect docs (create.roblox.com/docs/reference/engine/classes/HapticEffect; HapticService is deprecated), and the vault notes *Hit-Stop and Screen Shake Tuning by Numbers*, *Input Responsiveness*, *Reward Moments*, *Juice on a Budget* and *Haptics*.

**Already good (keep):**
- Melee hits are predicted on the same frame (`PokeController.luau:1403-1463`).
- Hit sounds scale with power (`FxController.luau:1000`).
- Shake is trauma² noise with a phone cap (`FeelV2.luau:96-114`).
- Voices are pooled.
- Every gun has its own recoil, flash and casing (`FeelTuning.luau:134-158`).
- Blasts are sized and ducked.

**Top 15 by satisfaction per hour:**
1. **Missing sound slots (~0.5 h).** Add `reward`, `levelUp`, `tick` and `crack` to `Theme.Sounds` (`LihFolkUITheme.luau:283-290`).
   - Six reward call sites are silent today: unlock `ProgressUI:648`, daily gift `:576`, goal `:594`, next-goal pop `HudPlus:229`, purchase `ToolCatalog:973`, and the egg wobbles `ProgressUI:235`.
   - Add a test that fails when a slot is missing.
2. **Instant gun hit feedback (~2 h).**
   - Call `Crosshair.hit` from the prediction instead of waiting for HitInfo (`Crosshair.luau:337-344`).
   - The server upgrades the mark to KO.
   - Add a tick (40 ms, vol 0.35) and a head ding (120 ms, pitch 1.35).
   - Show a KO mark for melee too.
3. **Combo pitch ladder (~1 h).** Hit pitch × (1 + 0.04·n), capped at +24 %, reset after 1.2 s. Audio only: no counter on screen.
4. **A cartoon puff on gun hits while blood is off (~1.5 h).** 6 white dust and 2 sparks from the FeelV2 pools. Raise `LIMB_PUSH` from 0.3 to 0.5 so the limb visibly jerks (`FxController.luau:908-937`).
5. **Its own sound per hazard (~2 h).** Lava, wrecking ball, mace, stations, chimney, present and bullseye all send `"CannonPad"` today (`Playground.luau:144,219,287,591,706,771,806,817`). Give each its own fx id, and add the ids to `LAUNCHERS` and to CrowdService's `CANNONS`.
6. **HUD reveal pop (~1 h).** `KitStyle.pop` on each piece (0.6 → 1 over 280 ms), with a 40 ms stagger and a soft tick.
7. **Haptics module (~3 h).** One pre-made HapticEffect per type, at most 8 starts a second, a Settings toggle, and a check on a real phone.
8. **A small KO pop that always shows (~2 h).** A world "KO!" (scale 0.6 → 1.15 → 1 over 120 + 160 ms, held 400 ms, at most 1 per 0.5 s) and a bonk-ding.
9. **Bullseye celebration (~3 h).**
   - The landing check runs on the owner's client; the server still validates.
   - Two gold rings 120 ms apart, 18 stars and a 0.8 s fanfare.
   - 0.6 s of slow-mo (not on the low tier).
   - A "BULLSEYE!" stamp (0.4 → 1.2 → 1).
10. **Egg ceremony by rarity (~3 h).**
    - Wobble ticks at pitch 1.0, 1.12 and 1.26; 3, 4 or 5 wobbles by rarity.
    - A 60 ms white flash at the crack and a card stamp (1.25 → 1 over 180 ms).
    - Confetti for Rare and up: 24 pieces, 12 on a phone.
    - An EQUIP button replaces the auto-close.
11. **The victim stops, not the camera (~3 h).** The simulated body is held at about 5 % of its speed for 50-80 ms (at least 66 ms on phones), then released at 1.15× its speed. A white Highlight flashes over 80 ms.
12. **Level-up ring and chime (~1 h).** The badge stroke goes from 2 to 8 px and fades over 500 ms. Still no banner.
13. **Creature sounds (~3 h).** Chomp, munch loop and "ptoo" spit, driven by `Busy` plus a new `Phase` attribute, with a spit puff of 8 dust and a 100 ms squash before the spit (`LabCreatures.luau:179-213`).
14. **Bolts and stars fly to a counter (~3 h).** 6-10 icons over 450-600 ms with rising ticks, then a count-up.
15. **Cannon wind-up (~3 h).**
    - 250 ms fuse hiss with FOV −4.
    - The existing `cannonShot` boom.
    - A white smoke ring (r10, 0.4 s).
    - FOV +10, decaying over 600 ms.
    - Trauma 0.5.

**Smaller ones:**
- Reload "full" gets a clack and a counter pop (1.25 → 1 over 150 ms) (`AmmoClient:184-189`).
- A window close plays at pitch 0.8.
- The button press jumps straight to the squish (no 50 ms tween).
- Touch gets a UIClick haptic.
- Lava gets a sizzle, a steam puff and a 400 ms orange tint.
- The wrecking ball gets a clang (pitch 0.55) and 10 stars; the mace a clang (pitch 0.9) and 12 sparks.
- The event start gets a "dun-dun" stinger instead of the slide whistle.

**Phones and performance:**
- Pool the muzzle flashes. Each shot makes 2 parts, a PointLight and a PreRender connection today (`FeelV2:427-474`), about 40 parts a second from the minigun.
- Pool the casings.
- Make the FeelV2 emitter pools in `start()`, so the first hit has no hitch (`FeelV2:176-184`).

## State
- 20 Nov 2026: plan written. Nothing of V8 started.
- 20 Nov 2026: plan revised after review: Day 1 orientation check and a no-gameplay 0.25.1 (telemetry, safe boot, store truth) before the 0.26 bundle; a named must-ship core for 1 Dec; one gate table with defined denominators, baselines rebased on 0.24 (owner out) and a playtest fallback per gate; the play-as-newcomer mode for round 1; a pad pass and J6; cannon in view (V8-0.4) and cannon flight (V8-1.1); chase only after 300 s and 15 KOs; owner decisions and per-build publishing asked in Sitting 1; one blind review per phase. Nothing of V8 started.
- **Day 1 (21 Nov):** `StarterGui.ScreenOrientation` = **Sensor** (the phone may turn freely, so upright play is possible). V8-0.5 waits for `orient30/60` from 0.25.1. Sitting 1 (V8-0.1) is parked with the owner: per-build publishing is not yet approved, so V8-0 publishes once at its end (the 20 Nov order).
- **V8-0.8 done (code):**
  - **Visit record:** new fields (`owner`, `test`, `newPlayer`, `frame0`, `orient10/30/60` + `rot`, `errs`/`errSig`, `fpsP50`/`fpsP5`, `memMb`, `vol`, `firstKnockAt`, `firstLaunchAt`, `firstMissionDoneAt`, `used`, `friendsMax`, `screen`) and the V8 funnel `stage` 1-8 (SessionStats, SessionClient, hooks in ExperimentService and EventService).
  - **Play-as-newcomer mode:** `TestAccount` + `Config.TEST_ACCOUNTS` (3037725863; the owner confirms in Sitting 1); StudioFresh does the same in Studio. Blank profile never saved, passes ignored, no owner perks.
    - Other stores are not blanked (daily, playtime and launch gifts may be claimed by a test visit).
  - **tools/SessionReport:** the gone-by curve from the first frame, D1, used, on-screen at leave.
  - **Tests:** T113 passes; T58/T29/T68/T23/T45 pass.
  - **Live baseline (21 Nov, owner and test out):** 368 visits. D1 = **1 %** of 290 first-time players. 0.17.1: 44-50 % gone by 30 s. 0.25.0: 3 visits so far.
- **V8-0.9 done (code + place v614):**
  - **Safe boot:** `Shared/SafeStart` starts all 52 server systems and 51 client systems under pcall. Failures are listed in `BootFailed` / `ClientBootFailed`, and a start slower than 8 s is named in the log. Purchases starts first.
  - **Christmas spots:** moved off the paths and the car park (Chimney 45,66 · Present -40,58 · Sleigh -10,-60) and added to `PathPlan.OBSTACLES`. T106 checks that the two lists match. In Studio with Christmas on, the 7 parts hit no part and no path stone.
  - **Sounds:**
    - every `playSound` name is filled (hover, tick, reward, unlock, purchase and error, all Pro Sound Effects; `Theme.SoundVolume`; playSound takes a pitch);
    - the egg's wobbles tick higher each time;
    - a paid purchase plays "purchase";
    - the preload list said "G17", but the gun's id is "Blaster", so the start gun was never loaded first.
  - **CLIP IT** now reads the callback as (result, capture), so the save prompt can show.
  - **Settings:** a MENU row wherever HudV3 hides the column (PC, tablet, console) and key O.
  - **Gift clock** on HudV3's gift button.
  - **Tablet:** `HudV3Layout` puts Shop/Weapons/Lab in a row at the top left (it shrinks to fit left of the toasts) and Maps/Menu under RAGDOLL. LayoutCheck checks it on 3 tablets: 0 problems.
  - **Runner:** SKIP counted (`DONE pass= fail= skip=`), `task.cancel` on timeout, exact test numbers, T40/T41/T42/T99 duplicates renamed to T70-T73, `Tests/Lib/TestLib` (waitFor, withHold).
  - **Tests:** T114_SafeBoot and T122_SoundSlots pass, as do T106, T113, T58, T23, T53, T54, T90, T70 and T72.
  - **Found on the way:** the lab cannon's breech and knob used an archived mesh (455874143) and drew as nothing (a hole at the back of the barrel). Both are now plain parts in `ServerStorage.V3Assets.Cannon` (place saved, v614).
- **V8-0.2 done (code; switch `Config.V8_FIRST_HIT`):**
  - **Greeter:** T109 confirmed audit A. The greeter's route was worked out at Roblox's spawn, a frame before Lab moves the avatar into its lab, so it stood outside the player's lab. GreeterService.send now waits for the move (at most 3 s, run in its own thread). It is now in the player's lab and walks up.
  - **First hits:** a newcomer's first 3 hits with any tool knock the dummy flat. `ActiveRagdoll.firstHitsLeft` is armed by the client on `Newcomer`. The body is thrown back at ≥ 20 studs/s; a 2 studs/s tap gave 22 studs/s in T109.
  - **With BLOOD off:** a round is a dry thwack, with 6-10 white/yellow puffs and a 60 ms white flash, no hole and no flesh sound.
  - **KO stamp:** the hit tick, the KO stamp and the "thock" come from this screen at once (Crosshair.localHit). The server's mark for the same hit is skipped unless it is a head or a kill.
  - **Cowards:** nobody runs in a newcomer's first 60 s (`CALM_FIRST`). After that, only the coward nearest the bang runs, for 1.2 s, with at most 2 at once per lab.
  - **Aim help:** torso only, and for pads too.
  - **Pad:**
    - the camera goes over the shoulder, so the screen centre is not the head;
    - the help line uses pad buttons (RT / LB-RB / Y), not Click / 1-6;
    - no key chips while a pad is the last input;
    - "Menu" became "More".
  - **Tests:** T109 passes; T23, T24, T32 and T33 pass (T32/T33 now step past the calm minute; T33 accepts the nearest coward); T38 and T45 pass.
  - **Not done:** before/after captures (saved for the round 1 playtest).
- **V8-0.3 done (code; switches `V8_START_BAR`, `V8_HAND_RULES`):**
  - **Start bar:** Popper, Grab, Bat, Grenade, Launch (5 of 6), all open from the start. The Rocket is the first unlock at 3 (`Toys.V8_RUNGS`). Poke 18, Shove 22, Slap 24 and Heal 60 left the early rungs, and Punch stays open in WEAPONS.
  - **Hand rules** (`Shared/HandRules`):
    - a new tool takes the weakest slot that may go, only when it is stronger;
    - a gun, a bang, Grab, the G17 and the Bat never give way to a plain tool; a stronger gun or bang takes the weakest gun or bang (never the G17);
    - a prize (egg, gift day) always lands in the hand, with no pick-a-slot step;
    - a new tool is never picked while fire is held or a tool fired in the last 0.6 s: it waits for a calm moment.
  - **Old bars:** a saved bar moves once (Poke/Slap/Heal out; Bat/Grenade/Launch in while there is room). The flag key `<userId>_v8bar` is written with UpdateAsync, so a Poke put back later stays.
  - **Phones:** they get HudV3's "Next: Rocket" pill from the first second, in the top bar's own strip (tap = WEAPONS, no gift button there).
  - **Tests:**
    - T110 passes: unlocks 0..30 never weaken the bar, every gun and bang lands, keepers stay, a prize lands, the move runs once (memory store only);
    - T35, T56 and T64 updated (T56's 60 s floor was stale since V7's 45 s);
    - T21, T22, T23, T45, T47, T90 and T122 pass;
    - LayoutCheck shows 0 problems.
  - **Not checked:** SHOOT staying up for 3 minutes of scripted phone play (left for the round 1 playtest).
- **V8-0.4 done in part (code; switch `V8_ONE_VOICE`):**
  - **False toasts gone:**
    - "N weapons unlocked!" (the starters);
    - "Daily egg! Come back tomorrow" on a first visit;
    - "Claim your egg in Rank & Eggs" and "Open it in RANK & EGGS" (LaunchGift, PlaytimeGifts): no hidden button is named now;
    - the hazard tip once the cannon or a hazard is done (`HazardDone`, CannonShots);
    - the second, opposite unlock line in the first minute.
  - **Pace:** one toast per 15 s in the first 3 minutes (NotifyRules.EARLY_GAP).
  - **Spawn:**
    - the Hub/Fork signposts are gone;
    - `PathPlan.SPAWN_CLEAR` (10 studs): no machine or sign in it. The flat paving may cross it, a deliberate cut: the trunk stays;
    - the spawn is turned 50° (Lab.SPAWN_FACING). T112 measures the cannon at 42° and the middle dummies at -37..-19 in the follow camera, both on screen at 1920x1080 and 800x360. Capture SpawnView_V8_1.
  - **Greeter:** it also waits for the lab to be claimed (a play test caught it on the plaza).
  - **FirstVisit:** one reveal number (QUIET_START); per step, a "follow the glow" nudge at 20 s and a skip at 45 s.
  - **Tests:** T112 passes; T55, T45, T100, T106, T109 and T23 pass.
  - **Left for V8-1** (one voice in full): the edge arrow, the experiment card waiting for FirstVisit, the touch hand only after 6 s, the reward notices all through Notify, T111 (timeline), LayoutCheck for FirstVisitGoal.
- **V8-0.6 done in part (code; switch `V8_CALM_START`):**
  - **Chase:** a newcomer gets no NPC chase before 300 s in the game and 15 takedowns this visit, both (ChaseService.calmAllows). T123 passes.
  - **Pop-ups:** no window opens by itself for a newcomer before 180 s (Notify.waitBig floor: egg card, auto egg, What's New, favourite).
  - **T43:** passes with StudioFresh off. Owner-only tests (T43, T71, T101) must run without play-as-newcomer mode, which strips owner perks on purpose.
  - **Left for V8-1:**
    - the What's New chip for returners (non-modal, from the first frame);
    - the first WOW toy as a 1.5 s reveal into the hand;
    - the first-wow UFO only inside the spawn view;
    - T111.
- **V8-0.7 done in part (code; switch `MILD_V8`):**
  - **Words and pool:**
    - "kills" became "KOs" on screen (the next-weapon line, the WEAPONS window, the try-over toast);
    - the paid events Mega Bomb and Dummy Rain left the BIG RED BUTTON's free pool.
  - **Notifications and sharing:**
    - `EXPERIENCE_NOTIFY = false`;
    - no share prompt for clips, which is 16+ on Roblox; save-to-gallery stays.
  - **No paid random items:** a Robux weapon with the tier all owned pays 2 × PLAYTIME_BOLTS as fixed BOLTS, not 2 eggs (T35 updated).
  - **Tests:** T21, T29, T63, T68 and T98 pass. T35 passes alone; after T29 it fails "Blaster is not in the hand", an old coupling between the two tests.
  - **Parked for the owner (Sitting 1):** KO stars instead of green, removing Doctor/HospitalCharts, TOY_NAMES, the VIP egg perk text.
  - **Left for V8-1:**
    - the banned-word scan (T115) waits for the Doctor decision, since pulse/organ/blood live in the Doctor UI;
    - mild blurbs, the hit card pop, NPC taunts;
    - global build codes and the streamer section owner-only;
    - LIKE_CODES as update codes.
- **V8-0.10 (21 Nov), 0.26.0 ready to publish:**
  - **Version:** Config.Version 0.26.0 and a What's New entry (4 lines; the bird line is gone).
  - **Full suite: 94 of 100 pass, 1 skip.**
    - T19 and T32 are known flaky and pass alone.
    - T23 and T45 waited for a greeter in the same frame: fixed, they pass.
    - T26 passes on rerun.
    - T103 had two causes, both fixed (T103 and T108 pass):
      - the spider spat into the west hedge and looped (a real bug from V7, not yet live): it now spits towards the lab centre;
      - the test read Playground once.
  - **Blind review:** 6/10, then 8/10 after fix round 1. Fix round 2 closed its two remaining Low points (Grenade and Launch in HandRules.KEEP; a new player who sets a bar during the first read is marked).
    - **Round 1 fixes:**
      - the client Main wrap had cut the Doctor callback;
      - returning players keep Poke/Shove/Slap/Heal earned on their old rungs (LADDER 4);
      - HandRules ranks by Toy.rank;
      - the bar move marks new players;
      - first hits only from the player's own hit;
      - early pace from the visit start;
      - chase KOs from the visit record;
      - a UTF-8-safe error signature;
      - a refused deferred unlock still says WEAPONS.
  - **Gate:**
    - LayoutCheck 0 problems; 0 client errors, ClientBootFailed nil, BootFailed nil;
    - flags off (RunSelfTest false, StudioFresh false, SelfTestOnly removed); no stray parts;
    - place saved, v629; code backup at `RagdollLab-backups/2026-11-21-pre-publish-0.26.0`.
  - **Gate deviations, said outright:**
    - no 2-client test: nothing multiplayer changed in V8-0;
    - no separate 10-minute phone-emulator session: the suite's ~13 minutes of play and the targeted runs showed no errors;
    - no new products, so nothing to test-buy.
  - **Publish:** the MCP cannot publish and the Open Cloud route needs the .rbxl, so the owner presses Alt+P (RELEASE.md, method 3). Then restart the servers through Open Cloud and read Session_v1 after 15-30 min.
- **Admins (owner order, 21 Nov):** the owner gives others the admin menu.
  - **Where:** admin menu → PLAYERS → pick a player → MAKE ADMIN / REMOVE ADMIN (owner only). The line under the buttons lists the admins.
  - **Storage:** `Server/Systems/Admins` keeps the list in DataStore `Admins_v1` (UpdateAsync, at most 20); every server reads it again within 60 s. Studio keeps it in memory.
  - **What admins get:** every tool, never against the owner or another admin (kick, bring, go to, troll, try).
  - **Owner only:** free passes, the Christmas theme, all weapons for everyone, the director, and making admins.
  - **Leaving:** the last admin to leave resets gravity, time, weather and spawned bodies.
  - **Never admin:** a play-as-newcomer visit.
  - **Tests:** T124 passes; T101, T71, T43 and T29 pass.
