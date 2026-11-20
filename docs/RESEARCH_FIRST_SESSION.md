# First session in the top Roblox ragdoll sandboxes (research, 20 Nov 2026)

Goal: copy how the biggest ragdoll and physics sandbox games run a new player's first session. The owner's brief: "not too much happens for a first-time player, but they stay engaged enough not to leave, on every platform".

## How this was researched, and the limits

- **Player counts, visits, favourites, server size, maturity, game passes and badges** come straight from Roblox's public APIs, read at 01:32 UTC on Friday 20 Nov 2026 (US evening, not the daily peak):
  - search: https://apis.roblox.com/search-api/omni-search?searchQuery=ragdoll (also `physics`, `fling`, `ragdoll playground`);
  - game details: https://games.roblox.com/v1/games?universeIds=10773618503,10773926254,2668101271,10773425091,10774468211,10771155665;
  - votes: https://games.roblox.com/v1/games/votes?universeIds=... (same ids);
  - badges: `https://badges.roblox.com/v1/universes/<universeId>/badges`;
  - passes: `https://apis.roblox.com/game-passes/v1/universes/<universeId>/game-passes`.
- **Badge award counts work as a funnel.** A badge goes to each user once. So "Welcome" counts new players, and the other badges show what share of them reached each moment. This is the strongest first-session evidence here, because it measures real players rather than one YouTuber.
- **Screens and HUD** come from YouTube storyboards. These are the frame strips YouTube makes for its seek bar: one 320x180 frame every 5 or 10 s. I read the frames from the start of each video:
  - the frames are low resolution, so small text is often unreadable;
  - YouTubers' accounts may not be brand new, and some videos are edited;
  - I could not get any transcripts (the caption API returned nothing without a browser token), and the Chrome extension was not reachable.
  - Each time below is the frame time in that video. It is not a measured time from the moment of joining.
- **Fan wikis and guide sites** are used only for controls and unlock numbers. Several are machine-written and some disagree with each other. Those claims are marked *(fan site)*.
- **Not verified at all:** console layouts of any game, the phone layouts of Hyper Realistic Ragdoll and Ragdoll Research, sound and music in the first minute, and the exact second of the first pop-up. No game in the set has a developer DevForum post about its onboarding that I could find.

## 1. Who is on top right now

Data from the Roblox APIs above, 20 Nov 2026 01:32 UTC. Peak figures are from RoWatcher, a third-party tracker.

| Game | Playing now | All-time peak | Visits | Favourites | Likes | Server size | Created | Maturity |
|---|---|---|---|---|---|---|---|---|
| Hyper Realistic Ragdoll (Emo Playworks) | 91,845 | 201k (Nov 2026) [1] | 29.7 M | 123,560 | 90.4 % | **1** | 29 Oct 2026 | Moderate |
| Ragdoll Soccer (sport, not a sandbox) | 53,444 | n/a | 46.6 M | 68,242 | 73.6 % | 8 | 13 Oct 2026 | Minimal |
| BloxNG [CRASH PHYSICS] (cars, no ragdoll focus) | 35,802 | n/a | 16.1 M | 57,894 | 90.4 % | 10 | 13 Oct 2026 | Minimal |
| Bloody Ragdoll Physics (BRP) | 23,965 | 63k (Nov 2026) [2] | 28.9 M | 911,587 | 86.8 % | **1** (+ MULTIPLAYER portal) | 31 Oct 2026 | Mild |
| Fling Things and People (FTAP) | 19,861 | 71k (6 Sep 2026) [V1] | 3.75 B | 2,670,097 | 80.5 % | 25 | 2021 (last update 29 Oct 2025) | Mild |
| Realistic Ragdoll MMA (fighting) | 17,917 | n/a | 14.1 M | 37,415 | 75.6 % | 10 | 5 Nov 2026 | n/a |
| Ragdoll Research (RR) | 11,816 | 44k (Nov 2026) [3] | 29.1 M | 797,202 | 83.3 % | **1** (multiplayer lobbies exist) | 28 Oct 2026 | Moderate |
| Ragdoll Destruction Playground (RDP) | 10,481 | n/a | 8.0 M | 51,268 | 80.8 % | **1** ("multiplayer is planned") | 3 Nov 2026 | Moderate |
| Ragdoll Sandbox (Rise To Top) | 6,306 | n/a | 25.7 M | 795,219 | 84.7 % | **1** | 16 Oct 2026 | Mild |
| Realistic Ragdoll Engine (No Knees!) | 5,402 | n/a | 49.9 M | 784,782 | 86.3 % | **1** | 12 Oct 2026 | Moderate |

[1] https://rowatcher.com/games/10773618503/hyper-realistic-ragdoll
[2] https://rowatcher.com/games/10773926254/bloody-ragdoll-physics
[3] https://rowatcher.com/games/10773425091/ragdoll-research
[V1] Vault note "Teardown - Fling Things and People".

What the numbers say:

- **The genre is a wave of brand-new games.** Every sandbox above except FTAP was created between 12 Oct and 3 Nov 2026. All of them update almost daily ("updated" dates on 19-20 Nov).
- **Solo servers are the norm.** Every ragdoll sandbox in the top set runs 1-player servers. Multiplayer, where it exists, is a separate step: BRP has a green MULTIPLAYER portal in the lab (storyboard of https://www.youtube.com/watch?v=9n2UqulTqBo at about 95 s), RR has "multiplayer lobbies" (its badge "Meet Your Maker"), and RDP says "Multiplayer is planned". So **a new player's first minute is always alone with dummies.** FTAP (25 players) is the only social one, and it is four years old.
- **New players per day** (badges are first-time-only, and the "Welcome" badge is awarded on join):
  - HRR: 1,837,416 Welcome badges in the past day;
  - BRP: 542,150 Welcome badges in the past day;
  - RR: 306,908 First Kill badges in the past day.
- **Favourites per new player differ about ten times:**
  - BRP: 911,587 favourites / 8,534,789 Welcome = **10.7 %**;
  - RR: 797,202 / 10,037,539 First Kill = **about 7.9 %**;
  - HRR: 123,560 / 13,755,283 Welcome = **0.9 %**.

  BRP gives a free weapon for joining its group plus favouriting (*fan site*, https://bloodyragdollphysics-wiki.wiki/). HRR shows no such prompt in any frame I saw. This is the clearest visible effect of an in-game favourite ask.

The top 5 sandboxes used for the tables below: **HRR, BRP, RR, RDP, FTAP** (FTAP as the multiplayer reference).

## 2. Per-game first session

### 2.1 Hyper Realistic Ragdoll (HRR), the leader

| Parameter | What was found | Source |
|---|---|---|
| Spawn, first screen | Outdoor park lab: grass, paths, a tower, a rail track, red barrels, a big fan and a ring, with dummies standing about. In two videos the very first frame shows almost no HUD. In one it is only a shop cart with a "1" badge bottom-left; in the other, none. | storyboards https://www.youtube.com/watch?v=OKrqbbAkgH4 (0 s), https://www.youtube.com/watch?v=DTLl9y7yXzs (0 s) |
| HUD at start | About 10 elements:<br>- left: a small key list (Fall, Distance, Push, Grab), then Shop, Tools, Lab, Lab Log as icon tiles;<br>- top right: "Next: <tool> 22/25" with a green bar, plus Gifts and Events buttons;<br>- bottom: a 7-8 slot hotbar, and key hints "R Revive, G Spawn, V Scan" bottom-left;<br>- a hit line in the bottom middle ("Broken ribs ... 92% blood");<br>- a dummy body card bottom-right. | storyboards OKrqbbAkgH4 (5-40 s), https://www.youtube.com/watch?v=b2gAyouLUh4 (0-40 s); https://allthings.how/?p=356463 ("prints its controls straight onto the HUD") |
| Tutorial or hints | No tutorial. There are one-line hints at top centre per tool ("Click: swing, hold to keep going", "Hold click to draw, let go to shoot", "Click: shove, aim down to launch yourself"). There are also **stickers**, short goals like "New sticker: Knock a dummy flat with the Bat". | storyboards DTLl9y7yXzs (10 s, 70 s), b2gAyouLUh4 (35 s) |
| First 5 s / 60 s | Look around, then hit or grab a dummy (left click). The first 60 s go to hitting dummies and reading the hit line. G spawns more dummies. | allthings.how above; https://www.hyperrealisticragdoll.site/guide/hyper-realistic-ragdoll-multiplayer *(fan site)* |
| First wow | The per-limb reaction: a shot leg limps, a broken leg crawls, the X-ray scan shows breaks. Events (tornado, T-Rex, meteor) and machines come later. | game description (games API); storyboards OKrqbbAkgH4 |
| Default loadout | Fists plus a pistol-class gun; the bar fills as tools unlock. Unlocks by KOs: Bat 5, Hand Cannon 10, Balloon 30 *(fan site)*. The "Next" tracker read 18/20 for a Molotov early on. | hyperrealisticragdoll.site; allthings.how |
| Controls | PC: click grab/hit, wheel for distance, C fall, R revive, G spawn, V scan, 1-7 for slots. Phone and console: not verified. | allthings.how; fan site |
| Camera | Third person over the shoulder; first-person aiming with the gun appears in frames. | storyboards |
| Shop, gifts, favourite | The Shop tile is visible from the start (with a badge). Gifts and Events are visible top-right from the start. No favourite or like prompt was seen. 12 passes, from Demolition Pack 39 to Everything 699; "All Guns" 99. | storyboards; passes API |
| Social | 1-player servers; friends cannot join you. | fan site above; games API maxPlayers 1 |
| Progression intro | "Next: X a/b" bar top right from the first frame, KO-based. | storyboards |

### 2.2 Bloody Ragdoll Physics (BRP), the closest rival (Ragdoll Havoc's HUD is already modelled on it)

| Parameter | What was found | Source |
|---|---|---|
| Spawn, first screen | A sand-floored test lab with dummies a few steps ahead. In view: a cannon, a gantry tower, a wrecking ball on an A-frame, barrels, benches, a cage. | storyboards https://www.youtube.com/watch?v=9n2UqulTqBo (0-10 s), https://www.youtube.com/watch?v=OiE_DfxaXJE |
| HUD at start (PC) | **Minimal, 4 things:**<br>- a red WEAPONS button top-left with a progress bar and a white arrow pointing at it;<br>- one objective line in a dark pill at top centre;<br>- a 3-slot hotbar (Grab, Fists, and one more) with a level badge;<br>- nothing else. | storyboard 9n2UqulTqBo (0-45 s) |
| HUD growth | At about 60 s a left column appears (SHOP, REWARDS, MAPS, SANDBOX, SETTINGS). At about 70-90 s the key chips appear down the right edge. Later the bar has 5-6 slots and an ammo counter ("14 / 15"). A "1 NEW" tag sits on WEAPONS. | storyboard 9n2UqulTqBo sheets 1-2; https://www.youtube.com/watch?v=6SXPY3-vEWE |
| HUD on phone | More is shown at once:<br>- top bar: WEAPONS (red, with bar), SHOP (badge), REWARDS, MAPS, and a **Starter Pack card with a 15-minute countdown** (14:59 -> 14:04);<br>- right side: MORE, RAGDOLL, TAKE BACK, a big red FIRE (it becomes PLACE for the landmine), JUMP, and RELOAD with an ammo count;<br>- left side: the thumbstick;<br>- bottom: a 5-slot labelled hotbar (Grab, Fists, Pistol, Bow, Landmine) and a level badge;<br>- "+15 XP" pops. | storyboard OiE_DfxaXJE (0-40 s) |
| Tutorial or hints | No tutorial screens. One objective line at top centre, an arrow at WEAPONS, and the badge set acting as a hidden checklist of lab machines (below). | storyboards; badges API |
| First 5 s / 60 s | Punch or shoot the nearest dummy. The objective line points to the next thing. The left menus arrive at about 60 s. | storyboards; https://bloodyragdollphysics-wiki.wiki/ ("Kill one dummy to start the weapons-panel bar. Then open rewards and claim the free bat.") *(fan site)* |
| First wow, measured | Badge funnel. All-time share of Welcome earners (past day in brackets):<br>- First kill: **91 %** (89 %);<br>- spike wall throw (Pin Cushion): 66 % (60 %);<br>- pin to wall: 60 % (57 %);<br>- explosive barrel: 55 % (52 %);<br>- freeze mid-air: 46 % (43 %);<br>- wrecking ball: 44 % (27 %);<br>- trampoline: 43 % (35 %);<br>- cannon (Blast Off): 41 % (36 %);<br>- rewind: 35 % (28 %);<br>- tower drop: 22 % (14 %);<br>- balloon: 12 % (8 %). | https://badges.roblox.com/v1/universes/10773926254/badges |
| Default loadout | Grab, Fists, Pistol (fan site: "Fists ... slot 2 and the Pistol ... slot 3"). The phone video shows Bow and Landmine on the bar as well. | fan site; storyboard OiE_DfxaXJE |
| Controls | PC: click to fire/hit, keys shown as chips on the right edge, Alt frees the mouse *(fan site)*. Phone: as listed above. Console: claimed in the description ("Play on PC, phone and console"); layout not verified. | games API description; storyboards |
| Camera | Third person by default. First person with a held gun and a scope view also appear. | storyboard 6SXPY3-vEWE |
| Shop, daily, favourite | The REWARDS window has TODAY'S GIFT, PLAY GIFT and TODAY'S DARE, plus a day strip. The Starter Pack timer shows from the first frame on phones. Free weapons for group + favourite, a login streak, and kill gates *(fan site)*. Passes are on sale: Everything 499, Arsenal 249, VIP 199, Injections 199, Sandbox 99. | storyboard 6SXPY3-vEWE (70 s); passes API |
| Social | 1-player server; a MULTIPLAYER portal in the lab. | games API; storyboard 9n2UqulTqBo |
| Progression intro | The WEAPONS button with a kill bar and an arrow on it from 0 s. Kill gates run from Balloon 60 to Power Thruster 650 *(fan site)*. | storyboards; fan site |

### 2.3 Ragdoll Research (RR)

| Parameter | What was found | Source |
|---|---|---|
| Spawn, first screen | A white sci-fi "TEST HALL" with a teleport ring. A **"Choose a map" window** is open (Boiler, Testing Grounds, Farm, Office Tower, and more), each with a PLAY button. Another video opens in a dark lab with a coloured block dome and dummies. | storyboards https://www.youtube.com/watch?v=ukS5YnIglM4 (0-25 s), https://www.youtube.com/watch?v=q6JiplluejE |
| HUD at start | A level/XP card top-left, a thin column of coloured icon buttons on the left, small key chips on the right, and a small hotbar at bottom centre. A quiet, dark-glass style. | same storyboards |
| Tutorial or hints | Guides describe a first step at "Test Chamber 01" (a mutation panel), then a "NEW JOURNAL PAGE" notice, then the Journal. | https://ragdollresearch.wiki/ *(fan site)* |
| First wow, measured | First Kill badge: 10.0 M (306,908 in the past day). Later badges are rare: 500 kills 1.1 %, "The Door..." 3.1 %. | https://badges.roblox.com/v1/universes/10773425091/badges |
| Default loadout | A pistol in the first frames ("so we can use our pistol"); powers and abilities are sold as passes. | storyboard ukS5YnIglM4 (40 s) |
| Controls | PC: "Click to grab and drop, scroll for distance, right-click or F to throw" *(fan site)*. The description claims mobile, tablet, desktop, console and VR. | ragdollresearch.wiki; games API |
| Progression intro | Journal pages from mutations, weapon variants "for playing the game", accessories and faces for ragdolls. | games API description |
| Social | 1-player servers; separate multiplayer lobbies. | games API; badge "Meet Your Maker" |

### 2.4 Ragdoll Destruction Playground (RDP), the only one with a visible mission chain

The video is titled after the game, but the HUD could not be matched to the game by name. The features fit the game's own description (Reset, slow motion, chainsaw pass).

| Parameter | What was found | Source |
|---|---|---|
| Spawn, first screen | A street lab with weapon racks. Glowing items are free, and "Buy Chainsaw 149" shows on a locked one. | storyboard https://www.youtube.com/watch?v=Pu2CeO92CHM (0-10 s) |
| HUD at start (phone) | - Top left: Roblox, menu, mic and settings.<br>- Top right: a bag (shop) and a coin counter starting at **0**.<br>- Left: a thumbstick.<br>- Right: a big contextual button (Grab -> Swing -> Fire), plus Drop, Throw, Slow and Jump.<br>- Bottom: a numbered 4-slot hotbar.<br>- Top left: a **mission card**. | same |
| Tutorial | A 4-step mission chain on a card with a progress bar and a coin reward:<br>1. "Grab a weapon from the racks" (+200, "The glowing ones are free to take", 0/1);<br>2. "Hit a subject" (+300, 0/4);<br>3. "Unlock an item in the shop" (+200, "Tap the bag at the top to open the shop");<br>4. "Fire your Revolver" (+150).<br>Side lines show "NEW +200 First limb cut off", "+100 First concrete broken" and "+400 First kill with a subject's own gun". | same, frames 10-80 s |
| First 60 s | Grab a free weapon, hit 4 dummies, open the shop (coins go 0 -> 600 -> 1,040 -> 1,840 -> 2,360) and buy the Revolver ("Revolver ready to unlock"). | same |
| Passes | Plasma Pack 300, Slow motion UNLIMITED 199, Chainsaw 99, Jetpack 99. | passes API |

### 2.5 Fling Things and People (FTAP), the social reference

| Parameter | What was found | Source |
|---|---|---|
| Spawn, first screen | A green open map with props and other players. | vault "Teardown - Fling Things and People"; storyboard https://www.youtube.com/watch?v=TpE2j7n7PUM |
| HUD at start | Very small: a coin counter top-right (starts at 0), a short key list bottom-left, and chat. A "Your Toys" window opens on demand. | storyboard TpE2j7n7PUM |
| Tutorial | None. "Click on anything: it lifts on a visible line. Release: it flies. Someone grabs you. You learn the escape mechanic by needing it." | vault teardown |
| First wow | Within a minute you "have flung, been flung, and laughed". | vault teardown |
| Social | 25 players. Grabbing players is the game. The approval of about 80 % is lower than the calmer games, because being grabbed against your will causes friction. | vault teardown; votes API |
| Progression | Coins, toys, houses. Fixed-price passes only (Farther Reach 460, Escape Faster 240, ...). | passes API |

### 2.6 Extra data point: Ragdoll Sandbox (takedown ladder via badges)

- Its badges form a straight "take down N dolls" ladder: 10 dolls 6.89 M, 50 dolls 3.63 M (53 % of the 10-doll earners), 100 dolls 2.24 M (32 %), 1,000 dolls 0.22 M (3 %).
- A "10 kill streak" badge added on 14 Nov already has 787k earners.
- The description advertises free daily rewards and codes, with "Next code at 25k likes!".
- Source: https://badges.roblox.com/v1/universes/10771155665/badges; games API description.

## 3. Common pattern (what all or most of the top games do)

1. **Alone first.** 5 of the 5 new top ragdoll sandboxes start you in a private, single-player lab. Multiplayer is a portal or a lobby you choose later (section 1).
2. **Dummies in front of you at spawn, and the first kill is near-universal.** BRP: 91 % of new players get a kill (badges). Fling's rule: the first grab within 10 s (vault).
3. **No tutorial screen and no text wall.** Teaching is one of these:
   - a one-line objective at top centre (BRP);
   - one-line hints per tool (HRR);
   - a single mission card with a progress count and a reward (RDP);
   - nothing at all (FTAP).
4. **A "next weapon" meter is on screen from the first second,** with tiny first steps:
   - HRR's "Next: X a/b" (Bat at 5 KOs, Hand Cannon at 10, *fan site*);
   - BRP's WEAPONS button with a bar and an arrow;
   - RDP's coins from 0.
5. **Lab machines are the "wow", and badges quietly teach them.** BRP has one badge per machine (spike wall, barrel, wrecking ball, trampoline, cannon, tower drop, rewind). 40-66 % of new players find each. Players find machines by walking into them, not by being told.
6. **Hotbar starts small.** BRP 3 slots on PC (5 on phone), RDP 1 tool + 3 empty numbered slots. HRR shows a full bar, but in guide videos only.
7. **Menus arrive late or sit quietly.** BRP's left column appears at about 60 s and the key chips at about 70-90 s. HRR's Shop/Tools/Lab tiles are small icons. Nobody opens a window over the first screen except RR's map picker.
8. **The money surfaces are present but passive in the first minute:**
   - a Shop button with a badge (HRR, BRP);
   - a Starter Pack chip with a 15-minute countdown on phones (BRP);
   - Gifts/Events buttons (HRR);
   - no purchase prompt was seen in any first-minute frame.
9. **Phones get one big contextual action button on the right** (BRP FIRE/PLACE; RDP Grab/Swing/Fire) with 2-4 small buttons around it (Ragdoll, Reload, Throw, Drop, Slow, Take back), a thumbstick on the left and a labelled hotbar at the bottom.
10. **Daily systems sit behind one REWARDS button:** BRP's Today's Gift, Play Gift, Today's Dare and day strip; HRR's Gifts and Events; Ragdoll Sandbox's daily rewards and like-goal codes.
11. **Updates almost every day,** and the description doubles as a patch note (RDP "NEW UPDATE!", Ragdoll Sandbox "MILITARY UPDATE").

## 4. Spec for Ragdoll Havoc's first session

Base: a new player (no profile) joining their own lab. "Visible" means drawn on screen. Switch names refer to existing Config keys (`QUIET_START` 90, `VIEW_CARD` false, `NEXT_UNLOCKS_AFTER` 180, `Toys.SLOTS` 6, `PHONE_HUD_MAX7`).

### 0-5 s: arrive and see a target

| | PC | Phone (landscape and upright) | Tablet | Console |
|---|---|---|---|---|
| Visible | 3 to 4 things:<br>- WEAPONS button with its kill bar (top-left; BRP place);<br>- start bar of 3 slots: Grab, Punch, G17;<br>- crosshair;<br>- one objective line at top centre: "Shoot a dummy!" | - Thumbstick, SHOOT (big, right thumb), JUMP;<br>- start bar (3 slots, labelled);<br>- WEAPONS button;<br>- the same one objective line;<br>- the "TAP A DUMMY!" hand. | Same as phone, buttons at phone size (they are not to grow with the screen) | - Start bar, WEAPONS with a "Y" glyph, crosshair at screen centre;<br>- objective line "R2 to shoot". |
| Hidden | Left column (Shop, Rewards, Places, Sandbox, Settings), key chips, level badge, NEXT cards, toasts, experiment card, offers, chat bubbles, dead monitor | Same, plus LAB VIEW and RUN (already wait for `QUIET_START`) | Same as phone | Same as PC |
| Happens | - Spawn **facing 2-3 standing dummies 10-15 studs ahead**, in the lab, with the cannon and one machine in view behind them;<br>- the camera behind the shoulder, still. | same | same | same |
| Must NOT happen | - Any window (map picker, daily gift, egg card, like prompt, offer);<br>- any loading text after the spawn;<br>- the plaza as spawn;<br>- a chaser or event in the lab;<br>- music. | same | same | same |

Evidence: section 3, points 1-4, 6-7; the vault rule "control within about 10 s of join; no unskippable cutscene" (vault "First-Time User Experience and Onboarding").

### 5-30 s: first hit, first takedown, first reward

| | PC | Phone | Tablet | Console |
|---|---|---|---|---|
| Visible | Same as above. After the first takedown:<br>- the objective line changes to "Knock down 3 dummies 1/3";<br>- small "+1 TAKEDOWN" pop (already);<br>- the WEAPONS bar fills. | Same; the aim help (`PokeController.ASSIST`) is on. | Same | Same; aim help on (pad = screen centre) |
| Hidden | Everything listed above stays hidden | same | same | same |
| Happens | - The first takedown by about 10-15 s (a dummy falls in 1-3 hits on any limb);<br>- the hit line shows one short body-region line (`MILD_TEXT`);<br>- **first unlock at takedown 3-5** (HRR Bat at 5; BRP free bat after 1 kill): a quiet toast "NEW: Bat, on your bar" and the slot fills itself (auto-equip, already), with no window. | same | same | same |
| Must NOT happen | - A purchase prompt;<br>- a reward that needs a menu to claim;<br>- a second pointer or arrow on screen;<br>- dummies fleeing out of reach before the first hit (greeter never flees, already). | same | same | same |

### 30-90 s: discover the lab machines (the wow)

| | PC | Phone | Tablet | Console |
|---|---|---|---|---|
| Visible | - The objective line moves to one machine at a time, in BRP badge order (most found first):<br>1. "Throw a dummy at the spike wall / station";<br>2. "Blow up a barrel";<br>3. "Put a dummy in the CANNON";<br>4. "Land the BULLSEYE".<br>- The WEAPONS bar keeps filling. | Same; the bar stays at 3-4 slots. GRAB gets its own button next to SHOOT (BRP/RDP pattern: one big action + small helpers). | Same as phone | Same; the X glyph next to "Grab" in the objective |
| Hidden | Left column, key chips, level badge, NEXT cards, egg card, play-gift clock, experiment card, chase, events, plaza portals' text | same; RUN and LAB VIEW still hidden | same | same |
| Happens | - One machine label lights up when the line points at it (glow, no beam arrow across the map);<br>- the cannon/bullseye gives the first big "wow" (slow-mo beat `COMBO_SLOWMO` is fine here);<br>- the second unlock lands at about takedown 10. | same | same | same |
| Must NOT happen | - Chasers (now 150 s, keep it);<br>- world events;<br>- a like/favourite ask;<br>- daily-gift windows;<br>- the auto egg opening a full-screen card;<br>- toasts stacking more than 1 at a time. | same | same | same |

### 90-300 s: open the game up, one piece at a time

| | PC | Phone | Tablet | Console |
|---|---|---|---|---|
| Visible | - At 90 s (`QUIET_START`) the left column slides in one button at a time, 1 s apart (BRP did this at about 60 s): Shop, Rewards, Places, Sandbox, Settings;<br>- at about 100 s the key chips appear on the right;<br>- the level badge appears;<br>- at 180 s the NEXT cards appear (`NEXT_UNLOCKS_AFTER`). | - MENU button + Shop only (`PHONE_KEEP`);<br>- LAB VIEW and RUN appear at 90 s;<br>- no NEXT cards on phones (already);<br>- at most 7 tappable things in the first minute after the reveal (LayoutCheck rule). | Like phone, but Rewards also visible | - MENU entry for everything (`MENU shows every launcher to a pad`);<br>- glyphs on objectives. |
| Happens | - **First egg / free weapon** at about 90-120 s, as a small card that waits for a calm moment (already);<br>- **REWARDS dot** at 90 s: today's gift is claimable (BRP Today's Gift);<br>- **first experiment card** at about 120 s (one goal, one reward);<br>- **chase** at 150 s (keep);<br>- **plaza portal** gets a label "PLAY WITH OTHERS" at 180 s;<br>- the favourite ask only **after a wow** (bullseye, combo 10, chase cleared) and **not before 3 min** (already in LikePrompt). | same | same | same |
| Must NOT happen | - More than one new button or card per 10 s;<br>- the Starter Pack/offer window (a chip is fine after 3 min; BRP shows a timer chip, never a forced window);<br>- a Robux prompt that the player did not tap;<br>- a free-weapon promise tied to liking (owner rule in CLAUDE.md "Never tied to liking"; RESEARCH_V4 section 3 on likes). | same | same | same |

### After 5 min: goals that carry over

| All platforms | |
|---|---|
| Visible | Full HUD: left column, key chips (PC), level badge, NEXT cards (PC), experiment card, Rewards with a day strip. |
| Happens | - Experiment cards back-to-back (session goals; RDP's 4-step chain and HRR's stickers are the same idea);<br>- **takedown badges as a ladder** (Ragdoll Sandbox: 10, 50, 100, 1,000) and **one badge per lab machine** (BRP);<br>- daily: today's gift, play gifts at 2/5/10/15 min, today's dare (BRP REWARDS layout);<br>- the next weapon is always visible with a count;<br>- the Starter Pack chip may appear (top-right, small, timer only if real);<br>- events and the plaza are offered as "something new" at about 5-8 min. |
| Must NOT happen | - Fake countdowns;<br>- more than one pop-up per minute;<br>- rewards for likes;<br>- anything from TikTok LIVE counted (owner rule). |

### Platform rules that apply to every step

- **Phone:**
  - one big action button under the right thumb that changes label (SHOOT -> PLACE/THROW) instead of more buttons (BRP, RDP);
  - helpers 44 px or more (vault "Onboarding Accessibility and Cross-Device Prompts");
  - hotbar labels under icons (BRP);
  - aim help on;
  - objective text one line, 8 words or fewer (vault "Onboarding and FTUE - Tutorials That Keep Players").
- **Tablet:** the phone layout and button sizes, with the reveal schedule of the phone (not PC). No evidence of a separate tablet layout in any top game.
- **PC:**
  - controls printed on screen as key chips, but only after the first minute (BRP at about 70-90 s; HRR shows a short key list at once, so a 4-line key list of only Shoot/Grab/Ragdoll/Weapons is the allowed alternative from 0 s).
- **Console:**
  - R2 fires at the screen centre with aim help;
  - glyphs in every hint;
  - MENU holds all launchers.
  - No top game's console layout was verified; this follows the vault and Ragdoll Havoc's existing PadMap.
- **Sound:** none of the top games was verified to play music. Keep Ragdoll Havoc's no-music rule. Hits, guns and the cannon must be loud and immediate from 0 s.

### KPI targets for the next Session_v1 read

These are based on the measured rival funnel, against Ragdoll Havoc's own launch numbers (median 1.6 min, 71 % left before 3 min; CLAUDE.md, 10 Nov):

| Moment | Target |
|---|---|
| First takedown | 90 %+ of new sessions (BRP 91 %) |
| First machine (station/barrel/spike) | 55 %+ |
| Cannon | 40 %+ |
| Median session | above 4 min (V4 plan target) |
| Favourites | above 5 % of new players (BRP 10.7 %, RR about 8 %, HRR 0.9 %) |

## 5. What commonly makes new players leave

| Cause | Evidence | Counter in the spec |
|---|---|---|
| No action in the first 10-20 s (walk to find targets, loading, intro) | Vault: control within about 10 s, first verb by 30 s, first reward by 40 s ("First-Time User Experience and Onboarding"). Sub-60 s exits count against discovery, and "first-play bounce rate" replaced qPTR in June 2026 (vault "Onboarding and FTUE - Tutorials That Keep Players"; https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575) | Dummies in front at spawn |
| A window over the first screen (daily gift, offer, map picker, egg) | No top-5 game shows a purchase or daily window in the first minute; BRP hides its menus until about 60 s (storyboards). Vault: "no purchase or daily-reward pop-ups during onboarding" | Nothing modal before 90 s |
| A text wall or several pointers at once | Vault: "Two pointers on screen and the player follows neither"; objective text 8 words or fewer | One line, one target |
| Nothing to aim for after the first kills | Vault: players stall "thrown in the game without knowing what to do" until a goal chain is added. Top games show a next-weapon bar from 0 s (HRR, BRP) | WEAPONS bar from 0 s, unlock at takedown 3-5 |
| Phone controls that shoot when walking, or too many buttons | Ragdoll Havoc's own fixes (MoveStick, v0.17.2); top phone layouts use one big action button (BRP, RDP) | One contextual button, 3-slot start bar |
| Being griefed by other players | FTAP's 80 % approval vs 86-90 % for the solo games; vault teardown | Own lab first; plaza only by choice after 3 min |
| A first enemy that fights back at full strength | Vault "Onboarding by Genre": "First combat at full strength -> a weak, owned first enemy" | Chasers only at 150 s, and only in the own lab |
| Asking for likes or favourites too early, or rewarding them | CLAUDE.md (LaunchGift "never tied to liking"); RESEARCH_V4 on likes and favourites | Ask only after a wow and after 3 min, no reward |
| Long loading on phones | Vault "Loading Screen Skip and First-Session Goals": preload only first-screen assets, hard timeout | Not measured here; check join-to-control time on a phone |

## 6. Not verified, and what would close the gaps

- The exact second the first pop-up or offer appears in HRR and BRP for a brand-new account. A test account recording on PC and phone would close this.
- Console layouts of all games.
- HRR's phone layout.
- Whether BRP's minimal first screen (WEAPONS + objective line + 3 slots) is the new-player state or that YouTuber's settings. It shows in one guide video (9n2UqulTqBo); the PC video 6SXPY3-vEWE starts with the full left column, possibly an older account.
- Whether BRP's favourite reward is still live and allowed. It comes from a fan site; RESEARCH_V4 found no official Roblox text on it either way. Ragdoll Havoc keeps no reward for favourites.
- Unlock thresholds: HRR Bat 5 / Hand Cannon 10 / Balloon 30 and BRP Balloon 60 to Power Thruster 650 come from fan sites. A second guide site (https://allthings.how/?p=358267) describes a different "Hyper Realistic Ragdoll" with cash prices, so treat fan numbers with care.
- RDP's identification: the mission-chain video carries the game's name and matching features, but it has 28 views and no description.

## Vault notes used

- First-Time User Experience and Onboarding
- Onboarding and FTUE - Tutorials That Keep Players
- Onboarding by Genre - The First Five Minutes
- Loading Screen Skip and First-Session Goals
- Onboarding Accessibility and Cross-Device Prompts
- Measuring Onboarding - Funnels, Drop-off and A-B Tests
- Skippable Tutorials and Replayable Tips
- Teardown - Fling Things and People
