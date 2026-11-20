# V8 evidence (20 Nov 2026)

Raw results of the V8 research workflow (7 research sweeps, a Studio playtest with Session_v1 stats, 6 simulated user tests, 16 A-P audits). docs/V8_PLAN.md is built on this. Read-only record.

## Studio playtest and Session_v1 stats

SOURCE: DataStore Session_v1, read-only (ListKeysAsync + GetAsync, nothing written), Studio Edit. The Studio id given in the task was not connected; the open place "[EVENT] RAGDOLL HAVOC" (placeId 126037745825106) is 6897f101-ba4c-4fad-9e21-c1ed2a2ce777, and that is what I used. The store holds 1170 keys in total; 378 are from the last 7 days, and every one was read.

IMPORTANT CORRECTION TO THE BRIEF:
- userId 10346200733 is the OWNER (it is game.CreatorId and the Studio user). It has 13 of the 378 records, including most of the recent phone visits at 414x814 portrait. A second account, 3037725863, has 5 more visits on the same 414x814 phone.
- The "45 visits / 72 h, most on 414x814 upright phones" in the brief therefore counts the owner. Build 0.25.0 has ZERO non-owner visits so far; its only record is the owner's 101 s visit.
- Everything below excludes the owner. Numbers marked "excl alt" also exclude 3037725863.
- Phones are still the biggest real group, and real phone players DO hold the phone upright: 105 of 108 phone visits on 0.17.1 were portrait, and 10 of 10 on 0.20+. Typical sizes are 390x763, 384x833 and 414x814.

TRAFFIC:
- 365 non-owner visits from 314 unique users.
- 40 users came more than once. Only 15 (about 5%) came back after more than 6 hours.
- Visits per UTC day: 14 Nov 277, 15 Nov 44, 16 Nov 4, 17 Nov 7, 18 Nov 1, 19 Nov 5, 20 Nov 27.
- 14 Nov was a single surge on 0.17.1, about 270 joins between 17:00 and 21:00 UTC. Since then traffic is a trickle.
- Boot is not the problem: median 0.9 s from client start to scripts running.

PER BUILD x DEVICE. Columns: n, median seconds played, share <1 min / <3 min / >=5 min, median takedowns (TD), share with 0 TD, share that fired, median first shot, share that opened an egg.
- 0.17.1, ALL: n 336 | 32.6 s | 73% / 94% / 3% | TD 2 | 0 TD 32% | fired 69% | first shot 7.3 s | egg 33%.
  - Eggs: 153 opened; the egg card was shown to 55%; the auto egg opened for 17%.
  - pc: n 127 | 33.8 s | 68% / 94% / 2% | TD 3 | 0 TD 17% | first shot 7.4 s | egg 34%.
  - phone: n 108 | 30.0 s | 78% / 94% / 2% | TD 3 | 0 TD 20% | first shot 7.5 s | egg 29%.
  - tablet: n 43 | 32.8 s | 63% / 86% / 9% | TD 4 | 0 TD 16% | first shot 6.7 s | egg 47%.
  - console: n 55 | 31.7 s | 82% / 100% / 0% | fired 0% | 0 TD 100%. Console could not fire before the gamepad work in 0.18.
  - 3 records with plat "?" left within 1 s.
- 0.20.0: n 1, tablet, 207 s, 21 TD.
- 0.21.0: n 1, tablet, 374 s.
- 0.22.0: n 4 | 83.6 s | 50% / 75% / 25% (one tablet visit >5 min) | TD 5.5 | 0 TD 0%.
- 0.23.0: n 12 (10 excl alt) | 45.4 s (30.6 s excl alt) | 58% / 100% / 0% | TD 2.5 | egg 17%.
  - console: n 6, 30.1 s, fired 83% (pad fire works now).
  - phone: n 3, 69.7 s.
  - tablet: n 3, 71.4 s.
- 0.24.0: n 11 (8 excl alt) | 126 s (144 s excl alt) | 18% / 82% / 0% (>=4 min: 9%) | TD 6 | 0 TD 9% | fired 100% | first shot 6.8 s | egg 45% (63% excl alt; almost all from the auto egg card).
  - phone: n 6, 127 s.
  - pc: n 3, 153 s.
  - console: n 1, 126 s.
  - tablet: n 1, 53 s.
- 0.25.0: n 0 non-owner.
- Pooled 0.20+, by device:
  - phone: n 10, 113 s, <1 min 10%, <3 min 80%, >=5 min 0%, egg 50%.
  - tablet: n 9, 71 s, >=5 min 22%.
  - console: n 7, 31 s, <1 min 71%.
  - pc: n 3, 153 s.
- All builds together: n 365 | 33.4 s | 70% / 93% / 3% | 0 TD 30%.

FUNNEL ('step' is recorded only from 0.20, for new players):
- 19 new non-owner players. 100% reached step 3 (FirstOwnToy). 17 of 19 reached 4 (ReplayEnded). 11 of 19 reached 5 (ThreeToys). 4 of 19 reached 6 (SixToys). 1 of 19 reached 7 (TenToys).
- 10 records have step 0: returning players or not counted.

FIRST SHOT: median 7 s on every build, so the controls are understood. On 0.17.1, 45 PC/phone/tablet players never fired; they left after a median 10.7 s.

WHEN PEOPLE LEAVE:
- 0.17.1 PC/phone/tablet (n 281), cumulative share gone:

| By | Gone |
|---|---|
| 10 s | 14% |
| 20 s | 35% |
| 30 s | 47% |
| 45 s | 61% |
| 60 s | 71% |
| 90 s | 82% |
| 2 min | 88% |
| 3 min | 93% |
| 5 min | 97% |

- After their first shot, players stayed a median of only 24.5 s more.
- Time played follows takedowns almost one to one (median time played):

| Takedowns | Time played |
|---|---|
| 0 | 9 s |
| 1-2 | 20 s |
| 3-5 | 36 s |
| 6-10 | 55 s |
| 11-20 | 83 s |
| 21+ | 199 s |

- Egg openers played a median 97 s against 23.5 s for the rest. This is survivorship: the auto egg comes at 60 s.
- Conclusion for the big sample: most players leave in the first 20-45 s, BEFORE the 20 Nov hooks begin (HUD 35 s, mission 40 s, UFO 45 s, next cards 45 s, surprise 80-110 s, chase 100 s). The cause is the core loop in the first half-minute, not missing later content.
- On the small 0.24.0 sample (n 8-11) the median moved to about 2 min. Most of those players leave between 45 s and 3 min, the window where the HUD reveal, missions, the egg modal and the chase all land. Nobody passed 5 min.
- The 20 Nov changes (0.25.0) have NO real-player data yet.

### Playtest
- **3 s:** [PHONE PORTRAIT, Device Simulator iPhone 11, 413x814 viewport, StudioFresh] First frame. One pill at the top: 'Knock a dummy over!'. Below it, the 'ROLINGSTUDIOS'S LAB' sign with a yellow/black crash-test logo, and 4 white crash-test dummies in a row about 30 studs away. The lower 55% of the screen is empty grey ground and a stone path. Only the thumbstick and jump button show; there is no fire button, no crosshair and no weapon in hand. **Problem:** Half the portrait screen is empty floor. The dummies are small and far away. Nothing on screen says how to hit them (no fire button, no 'tap a dummy' hand).
- **10 s:** [PHONE] The character has spawned, and the camera sits right behind it. A wooden signpost '< LAVA' stands in the MIDDLE of the screen and covers the dummies. A toast covers the centre: 'LAUNCH GIFT! A free weapon egg for everyone who plays now. Open it in RANK & EGGS!'. The bar (WEAPONS, gun 17/17, Grab, Punch) sits ON TOP of the thumbstick and jump button. The right edge has a column of keyboard chips: RAGDOLL, V 1ST, Z SLOW-M (cut off), X REVIVE, DEL RESET. Leaderboards are cut off at both screen edges. **Problem:** The signpost blocks the view at spawn. The toast fires during the 'quiet start' and points to a 'RANK & EGGS' button the phone does not show. The bar covers the touch controls. Caveat: the key column appears because the Studio emulator reports KeyboardEnabled=true; a real phone probably hides it.
- **25 s:** [PHONE] Idle, with no input yet. The scene is the same: signpost in the centre, and a floating 'VIP' tag over the lab sign (the test account owns VIP). The dummies stand still in a line. The only guidance is the top pill. **Problem:** 25 s with no nudge. The data says players with 0 takedowns leave after a median 9 s; this screen gives them nothing to react to.
- **40 s:** [PHONE] A mission card 'Take down 10 dummies 0/10 1:54' appears in the top-left and overlaps the 'Knock a dummy over!' pill, so the pill reads 'K... a dummy over!'. A level badge '1' and a thin bar show on the left. **Problem:** Two goals now compete. The new card covers the old one. A 2-minute timer on a first visit adds pressure, not fun.
- **52 s:** [PHONE] After 4 taps on dummies (4 shots, ammo 13/17, mission 1/10), the screen fills up:
- top: LAB and Shop/Menu (red '!'), with Shop/Menu covering a yellow 'TODAY'S MACHINE: BULLSEYE' banner; the objective changed to '...self from the CANNON' and is hidden under the mission card;
- centre: a 'Daily egg! Come back tomorrow for another.' toast, a 'CANNON' sign, the LAVA signpost still in the middle, and the crosshair with 13/17;
- lower: the hit card 'Belly · Belly  88% health · pulse 64';
- bottom: a big red SHOOT button that covers bar slot 2 (Grab). **Problem:** Overlaps everywhere (mission card over objective, Shop/Menu over the banner, SHOOT over the bar). 'Come back tomorrow' on the first visit is confusing. The hit feedback reads like a medical chart ('88% health, pulse 64'), not a knockout. 4 pistol shots, no dramatic ragdoll.
- **72 s:** [PHONE] Takedowns 3. A modal 'Free egg! You have 2 FREE eggs! A new weapon is inside... OPEN IT!' covers the middle of the screen over a blurred world, with a 'BONE JOURNAL: First egg! +25 BOLTS' toast behind it. The bar has grown to 6 slots (toolbox, gun 12/17, Grab, Punch, Bat, Poke, TNT) and moved up above the thumbstick, with RUN under it. **Problem:** A blocking window mid-action, 70 s into the first visit. 'First egg! +25 BOLTS' appears before any egg was opened. Three currencies or terms (eggs, bolts, journal) arrive in one screen.
- **90 s:** [PHONE] I tapped OPEN IT twice and the modal stayed, with a green 'Replay' button added at the top right. Mission timer 1:08 -> 0:59. **Problem:** Not a game bug: my MCP tap coordinates missed the GUI inset (the third tap with a corrected offset worked). Logged only so the repeated frames make sense.
- **102 s:** [PHONE] The egg opens: a sunburst card 'NEW RARE WEAPON - Rocket - Yours to keep. Going on your bar now!'. The camera has swung to a close-up of a tower and dummies. NPC text 'I used to...' is cut off at the right screen edge. The mission card is gone. **Problem:** The reveal itself is decent. But no slot on the bar clearly shows a Rocket afterwards, and the camera jumped without a reason.
- **125 s:** [PHONE] An NPC CHASE starts: a red bar 'NPC CHASE · HP 56 · 6 LEFT'. Several big white dummies in red jackets crowd the camera and fill the whole screen; the player is being punched. A 'FREE GIFT for playing! +40 BOLTS' toast shows, and 'Fire yourself from the CANNON' is still the objective. **Problem:** For a 2-minute newcomer this is an ambush: the camera is inside the attackers and nothing can be seen or aimed. The toast and objective ignore what is happening.
- **140 s:** [PHONE] I tapped around in panic. The chase is down to '1 LEFT', the level is 2, and a toast reads '+50 BOLTS (daily experiment!)'. Bar slot 4 changed from Bat to 'Slap' and is selected; the gun still shows 12/17, so my taps used whatever auto-equip had put in my hand. The background now shows the rocket on the tower, a MULTIPLAYER portal sign, PLAZA, a '< PORTALS' signpost and a NEW tag cut off at the left edge. **Problem:** Auto-equip swapped the active weapon under the player during combat. The background is the most interesting view so far, but it is only reached by accident.
- **158 s:** [PHONE] A new mission card 'Get launched on any MAP 0/1 3:43' covers the objective pill again. A toast reads 'NEW: SHOVE! It's on your bar. Try it!', but the bar shows toolbox, gun, Grab, a brown icon, Slap, Poke, TNT. The avatar now faces the camera. **Problem:** Contradictory goals: the cannon in the lab vs. 'launched on any MAP'. The toast names Shove, which is not visible on the bar. No arrow or path points to the cannon, although the server is highlighting CannonModel/CannonPad off-screen.
- **180 s:** [PHONE] Idle. The avatar faces the camera, a red-jacket dummy stands behind it, the VIP tag floats, and two goals are on screen (objective + 'Get launched on any MAP 3:21'). The stats are 11 takedowns, 190 bolts, level 2, rank 'Troublemaker'. **Problem:** After 3 minutes the player has collected many numbers (bolts, stars, level, rank, journal) but has not seen a single big physics moment (cannon, wrecking ball, UFO) and has no clear path to one. In the data this is exactly when the 0.24 players leave (45 s-3 min).
- **3 s:** [PC 1683x801, second run, StudioFresh] First frame before the character arrives:
- the camera is at ground level facing a '< LAVA / CANNON >' signpost in the centre;
- flat untextured grey floor, a plain grey stepped wall (the tower) at the left, a monster-truck wheel at the right edge;
- the dummies show only as tiny white heads (still streaming in);
- a lone '17 / 17' sits in the top-left corner, and a floating 'HUNGRY' label hangs in the air. **Problem:** The very first picture looks barren and unfinished: a grey parking lot, orphan HUD text, an unexplained label.
- **10 s:** [PC] The full lab is visible:
- 6 crash-test dummies on a black/yellow test mat, plus a greeter in a yellow vest walking up;
- lava pit with flames, wrecking ball on an A-frame, a plant creature and a monster truck;
- empty boards ('Knock something down to get on the board!', 'Nobody yet: just play!');
- HUD: 'Next: Bat 0/2' top right, the LAUNCH GIFT toast, the objective pill, a 'Weapons' tile bottom-left PLUS a 'WEAPONS' slab on the bar, the Popper/Grab/Punch slots and a help line 'Click a dummy to use the Popper'.
The signpost again sits dead centre in front of the dummies. **Problem:** PC reads far better than the phone, but:
- the signpost blocks the target;
- WEAPONS appears three times (tile, slab, Next pill);
- the leaderboards are empty;
- the styles are mixed: a blocky default avatar, cartoon wood signs, a realistic sky and a flat concrete floor.
- **20 s:** [PC] I clicked 4 shots at two dummies. The hit card says 'Right leg 98% health · pulse 76'. The dummies put their hands up and scatter, but none falls. Dummy speech bubbles overlap each other and the VIP tag ('I bru...', '...the face!', '...g loaded?'). **Problem:** Core feel: 4 pistol hits do almost nothing ('98% health'). The data shows people leave at a median 20 s with 1-2 takedowns. Top games ragdoll a dummy on the first hit.
- **28 s:** [PC] The first knockdown comes after 7 shots (about 15 s of clicking): a small '✓ Nice!' pill and Next: Bat 1/2. The hit card reads 'Right leg · Right leg · Right leg  89% health · pulse 67'. A tip says 'See their pulse and bumps: Doctor mode (L)'. **Problem:** The first takedown is a whisper (a small 'Nice!'), not a celebration. The repeated limb names and the medical 'Doctor mode' wording feel like a hospital sim, not a slapstick toy box.
- **45 s:** [PC] The HUD slides in: Shop/Weapons/Lab tiles on the left, Maps/Menu on the right, LAB VIEW (C). Also on screen:
- the objective 'Fire yourself from the CANNON';
- the mission card 'Take down 10 dummies 0/10 1:44' (it starts at 0 although I already have 1);
- a 'TODAY'S MACHINE: BULLSEYE' sign;
- dummy bubbles 'Is it lunch yet?' / 'Today feels like a cannon day.';
- an empty dark bar sticking out at the top edge;
- ammo 5/17 floating by the crosshair.
No UFO is visible (FIRST_WOW_AT 45). **Problem:** Clutter: three goals and two speech bubbles at once, plus a stray empty banner at the top. The 'first wow' was not seen in either run's captures.
- **62 s:** [PC] The 'Free egg! You have 2 FREE eggs!' modal again, with the screen dimmed. A toast 'Goal done: Open 1 egg! Claim your egg in Rank & Eggs' overlaps the mission card, though no egg was opened. A Grenade has been auto-equipped into slot 4 and selected, with the gun at 1/17. A key-chip row appears (F Ragdoll, X Revive, Z Slow-mo, V View), and the help line now reads 'Click the ground to put down the Grenade · 1-6 switch · T all weapons · B sandbox'. The mission is still 0/10 after about 20 shots. **Problem:** The weapon was swapped to a Grenade without asking; the next click places a grenade instead of shooting. 'Goal done' for something not done. The modal blocks play again. The pistol is too weak to finish '10 takedowns' in the time.

### Biggest problems
- Players leave before any hook starts. In the big sample (0.17.1, n 281 non-console): 35% are gone by 20 s, 47% by 30 s and 71% by 60 s. Time played follows takedowns almost one to one: 0 takedowns gone at 9 s, 1-2 at 20 s, 21+ at 199 s. After their first shot, players stay only about 25 s more. The 35-110 s hooks added on 20 Nov come after most players have already left. The first 20 seconds must deliver big, funny ragdoll hits.
- The core hit is weak and reads like a hospital chart. The starter Popper took 7 shots and about 15 s for the first knockdown on PC, and 4 phone shots felled nothing. Feedback is 'Right leg 98% health · pulse 76', repeated limb names, a small '✓ Nice!' and a 'Doctor mode (L)' tip. Top games (HRR, BRP) ragdoll on the first hit, and 91% of BRP's new players get a kill.
- The main device, the upright phone, gets the worst first screen (105 of 108 phone visits were portrait):
- a '< LAVA' signpost stands dead centre in front of the dummies at spawn, on PC too;
- half the screen is empty floor and the dummies are small and 30 studs away;
- before the first tap there is no fire button or 'tap a dummy' hand;
- for the first ~50 s the bar sits on top of the thumbstick and jump button;
- the SHOOT button then covers bar slot 2 (Grab);
- mission cards cover the objective pill, and Shop/Menu cover the 'Today's machine' banner.
- Too many pop-ups and goals that contradict each other. In 3 minutes on the phone:
- toasts: LAUNCH GIFT ('open it in RANK & EGGS', a button the phone does not show), 'Daily egg! Come back tomorrow' on a first visit, 'BONE JOURNAL: First egg! +25 BOLTS' before any egg was opened, 'FREE GIFT +40 BOLTS', '+50 BOLTS daily experiment', 'NEW: SHOVE! It's on your bar' (not visible on the bar), and 'Goal done: Open 1 egg' (not done);
- the Free egg modal twice and a Rocket reveal card;
- two or three goals at once: the objective 'Fire yourself from the CANNON' plus the timed missions 'Take down 10' and 'Get launched on any MAP';
- too many currencies and terms: bolts, eggs, stars, level, rank and journal;
- nothing points to the cannon (it is highlighted off-screen).
- The game takes control away from the player:
- auto-equip swapped the active weapon mid-fight (Slap on the phone, Grenade on PC, so the next click places a grenade);
- the Rocket won from the egg is not clearly on the bar;
- the NPC chase at ~2 min puts 6 big red-jacket bodies inside a phone camera with HP dropping: an ambush on a newcomer, with nothing to see or aim at;
- the egg modal blocks play at 60-70 s.
- The look is cheap and mixed next to HRR/BRP labs:
- the first frame is a flat grey concrete lot and an untextured grey stepped tower;
- the blocky default avatar, cartoon wooden signposts, a realistic sky and a floating VIP tag do not match;
- an orphan '17/17' sits in the screen corner and a floating 'HUNGRY' label hangs in the air;
- the leaderboards are empty ('Nobody yet: just play!');
- dummy speech bubbles overlap each other;
- WEAPONS appears three times on PC (tile, bar slab, Next pill).
The interesting machines (rocket, portals, wrecking ball, plant creature) are off to the sides and only seen by accident.
- There is almost no traffic, and the brief's data picture is skewed:
- after one 14 Nov surge (277 visits on 0.17.1) the game gets 1-27 non-owner visits a day, and only about 5% of players came back after more than 6 h;
- 0.25.0 has 0 non-owner visits;
- the 'most players on 414x814 upright phones' claim for the last 72 h counts the owner's own phone (13 owner visits plus 5 from a second account on the same 414x814 phone);
- real phones are still the largest group and almost all upright;
- the 0.20+ sample is only 29 visits, so no build after 0.17.1 can yet be called better or worse with confidence.
- Console: on 0.17.1 all 55 console visits fired 0 shots and got 0 takedowns (no pad fire then). From 0.23, 83-86% of console players fire, but console still leaves fastest (median 31 s on 0.20+, 71% under 1 min). The pad first minute needs its own look.
- Test caveats:
- the Studio test user is the owner: IsOwner, VIP and ULTRA are true, and Returning=true even with StudioFresh, so the VIP tag and some extra unlocks differ from a real newcomer;
- the Device Simulator reports KeyboardEnabled=true, so the keyboard chip column (V/Z/X/DEL) on the phone may not show on a real phone;
- this is not a real-device test.

## Simulated user tests

### A 10-year-old on Xbox, playing with a controller on a living-room TV (1080p, sofa distance). First visit, never touches a mouse or keyboard. Plays Roblox gun/ragdoll games and knows the Xbox buttons by their Xbox names (RT, LB/RB, B = back, the Menu button = menu). Console counts as not a phone, so the HudV3 HUD applies (HudGate.luau:15-20). The device tier is "mid": 7 chasers and 2 visitors (Config.luau:113-117).
- **Score:** 3/10. **Likely quits at:** 155 s. **Why:** The most likely exit is at about 155 s, just after the NPC chase ends (it starts at 100 s and lasts 50 s; ChaseService.luau:39, 35). Every big moment is packed into 30-100 s: cannon, UFO, wrecking ball, egg, chase. From 150 s nothing is due: the next surprise is 150-240 s away and the next chase 360-480 s away. The first-visit line has also ended, because its 4 steps finish when WEAPONS opens (FirstVisit.luau:43-48).

By then the pad player has hit four walls:
- **Aiming never felt like his.** The crosshair sits on his own head (GrabController.luau:690). There is no aim assist on a pad (PokeController.luau:1257) and no hit or KO marker (Crosshair.luau:270-291).
- **The egg weapon may be gone.** With a full bar, the slot picker drops it back into WEAPONS after 10 s (ProgressUI.luau:316, PokeController.luau:745-797).
- **His tool keeps changing by itself.** Unlocks at 2-8 takedowns pick Bat, Poke, Crowbar, Revolver, Shove, Slap and Heal one after another. RT now answers 'Tap a dummy to use Slap', or heals the dummy (PokeController.luau:760, 1706, 1325).
- **The on-screen text is for a mouse and keyboard.** He sees 'Click…', '1-6 switch', 'T all weapons', 'B sandbox' (and B ragdolls him), plus five squares he can't press.

The experiment card points at a creature 92+ studs behind the spawn. He presses the controller's ≡ button looking for the 'Menu' he sees on screen, and Roblox's own menu offers Leave.

An earlier exit is likely at about 80-90 s, when the rocket from the free egg goes back into WEAPONS without ever firing.
- **Confusions:** 'Knock a dummy over! (R2)' at the top and 'Press RT to shoot!' at the bottom: two names for the same Xbox trigger (FirstVisit.luau:44 vs OnboardingController.luau:324).; The crosshair sits on the back of his own avatar's head, because the pad camera has no shoulder offset (GrabController.luau:690). There is no aim help (PokeController.luau:1257) and no hit marker (Crosshair.luau:270-291), so he never knows if he hit.; 'Now try another tool!' never says how. LB/RB is never shown; the only pad glyphs used are Fire, Weapons and Ragdoll (OnboardingController.luau:45-58, 245, 324, 534).; The help line on a TV reads 'Click a dummy to use the Popper · 1-6 switch · T all weapons · B sandbox'. On a pad, B ragdolls him (PokeController.luau:353-388, 642; Keybinds.luau:50, 68; PadMap.luau:45).; Big Shop, Weapons, Lab, Maps and Menu squares can't be pressed with a pad (AutoSelectGuiEnabled is off: GamepadControls.luau:171). Lab and Maps have no pad button at all. The game's MENU is on D-pad down and is never shown, while the controller's ≡ opens Roblox's menu with Leave (PadMap.luau:11, 48).; The bar's slot numbers 1-6 match no button on a pad (PokeController.luau:603).; '3 weapons unlocked!' unlocks nothing: they are the same 3 he had from second 0 (Toys.luau:344-352).; Two objectives at once: the first-visit pill and a random Daily Experiment card from 40 s. It may ask for the spider, vacuum or chicken in a yard 92 studs behind the spawn (ExperimentService.luau:268-272; LabCreatures.luau:32).; The weapon in his hand changes by itself (Bat, Poke, Crowbar, Revolver, Shove, Slap, Heal). RT then says 'Tap a dummy to use Slap' or heals the dummy (PokeController.luau:760, 1706, 1325).; The rocket from the egg: 'Pick a slot for Rocket Tube… Tap a slot in your bar first (or the X to cancel)'. X is grab, and after 10 s the rocket goes back to WEAPONS (PokeController.luau:79, 792, 1271).; B is 'back' to an Xbox kid but ragdolls him. The View button cycles into first person and then lab view, with no on-screen way back for a pad (GamepadControls.luau:100-112).; The cannon starts off-screen (48 studs right, slightly behind the spawn facing), with an occluded glow and no arrow (Playground.luau:157; FirstVisit.luau:156).; BOLTS and stars mean nothing to him. The playtime gift pays bolts, not eggs (Config.luau:58-59).
- **Wow moments:** About 32 s: fired from the human cannon in a big arc, maybe a 'BULLSEYE!' (Playground.luau:204-225, 135-147).; About 55 s: the UFO beams the mannequins up, if he is facing it. It is silent and lasts 7 s (EventService.luau:650-664; Surprises.luau:126-151).; About 62 s: the wrecking ball throws him across the lab (Playground.luau:285-293).; About 74 s: a free egg opens by itself with a big weapon: Rocket Tube, Minigun, RPG, C4, TNT or Grenade (ProgressService.luau:1038-1039, 1637-1665). It is only a wow if the bar has a free slot.; About 95 s: a lab surprise such as an earthquake, fan blast or moon gravity (EventService.luau:666-677).; About 100 s: the NPC chase starts, with 7 red dummies charging in. Exciting for a few seconds (ChaseService.luau:131).; If he finds it: the BIG RED BUTTON 14 studs from the spawn sets off a random gorilla, train, tornado or meteor event (Playground.luau:858-880). It is not on the objective line, and its X prompt may clash with grab.
- **Top fixes:**
  - Make aiming with a pad work. (1) Apply the touch aim assist to the gamepad too: PokeController.luau:1257 should check 'ViewMode.isTouch() or GamepadControls.active()'. (2) Give the pad an over-the-shoulder camera, SHOULDER_OFFSET, whenever a gun is picked. GrabController.luau:690 forces CameraOffset to zero for everything except touch Grab. (3) Show the hit and KO marks on the pad's centre crosshair. Crosshair.luau:270-291 hides its root when there is no mouse or touch, so a pad never sees a hit confirm.
  - Never let the game take the weapon out of the player's hand. (1) Unlocks at 10 or below should go onto the bar without being selected. (2) Melee, Heal and Poke should never replace a slot automatically. (3) Nothing should re-select the tool while RT is held or during a chase. (Relevant code: ProgressUI.luau:631-648; PokeController.luau:760, 1706.) (4) The egg's WOW weapon should use autoEquip's swap, not the 10-second slot picker that silently sends it back to WEAPONS (ProgressUI.luau:316 -> PokeController.luau:745-797).
  - Use real pad glyphs everywhere. (1) FirstVisit should use PadMap.glyph('Fire'), which gives RT on Xbox, instead of the hard-coded '(R2)' (FirstVisit.luau:44). (2) Build the pad help line from PadMap: 'RT shoot · LB/RB switch · Y weapons · X grab · B flop'. Today a pad gets the keyboard line, which includes 'B sandbox' (PokeController.luau:353-388, 642). (3) Put glyph badges on the HudV3 squares: Shop = D-pad ↑, Weapons = Y, Menu = D-pad ↓. Give Lab and Maps real bindings. (4) Replace the bar's 1-6 numbers with LB/RB arrows on a pad. (5) Teach LB/RB with the 'Now try another tool!' hint. (6) Reword the touch/mouse hints for a pad: 'Tap a slot…', 'Tap a dummy…', 'Click…'.
  - Fix the reveal clock. FirstVisit.MIN_QUIET 45 always beats Config.QUIET_START 35, so the 20 Nov '35 s reveal' never happens: it is about 48-52 s (FirstVisit.luau:39, 206). The first big pop-up is then reveal + 20 s, about 70 s. Use one number for the reveal and measure it.
  - One objective at a time, with a second act after it. (1) Hide the experiment card while the FirstVisit line is alive (ExperimentCard.luau:71-83). (2) Make the first card scripted, such as 'Blast off the CANNON x3' or 'Press the BIG RED BUTTON'. Do not deal a random daily card first: today it can ask for a creature 92+ studs behind the spawn (EconomyService.luau:176-189, LabCreatures.luau:32). (3) Extend FirstVisit past WEAPONS with steps for the Big Red Button (14 studs from the spawn), the rocket from the egg, beating the chase, and the next weapon.
  - Fill 150-300 s, where this player leaves. (1) A cleared chase pays an egg or a TRY FREE Minigun. (2) A second scripted wow (Big Red Button event, giant dummy) at about 150 s. (3) A visible '3 kills to Rocket' goal. Today the next surprise is 150-240 s away and the next chase 6-8 min away (Config.luau:154, ChaseService.luau:40-41).
  - Make the first chase fair on a pad. A mid-tier device gets 7 chasers at 4 HP per 0.9 s each, with no aim help (Config.luau:113-117, ChaseService.luau:30-35). Start new pad players with 3 chasers, or add a chase-only stomp or shockwave.
  - Remove the '3 weapons unlocked!' toast. Toys.starterCount() is 3, the same 3 weapons the player had from second 0, so it unlocks nothing (OnboardingController.luau:197, 572).
  - Fix the X-button clash. The Drive prompt (VehicleService.luau:176-183) and the Big Red Button prompt (Playground.luau:866-872) leave GamepadKeyCode at its default ButtonX, which is also pad Grab. NpcCommand.luau:367 moved its prompt to L3 for this reason. Not verified in play which one wins.
  - Size text for a TV. Use GuiService:IsTenFootInterface() to scale the FirstVisit pill (20 px), the experiment card (max 18 px), toasts and the '+1 TAKEDOWN' pop (120-160 px wide) by about 1.5x. Then run the V7-6 console glyph and focus checks, which V7_PLAN lists as not done.
  - Check reach and build before measuring. The game is listed 'Minimal, Ages 16+' (RESEARCH_V4.md:15, 132), so a 10-year-old may not even be shown it: redo the maturity questionnaire. Also, V7_PLAN.md says release 0.25.0 was NOT published (the gate failed), so the 20 Nov hook timings may not be live yet. Confirm before reading Session_v1.

### Three friends, about 11-13 years old, all on their first visit (Newcomer = true). They join one 6-slot server through Roblox 'Join' to mess around with each other. FRIEND P is on a Windows PC with mouse and keyboard and joins first. FRIEND M is on a phone held upright (414x814 portrait, the most common device in Session_v1) and joins about 10 s later. FRIEND T is on a tablet in landscape and joins about 15 s later. They talk in Roblox chat. They want to shoot, fling and throw each other, not run a solo checklist. Times are each player's own clock unless noted.
- **Score:** 2/10. **Likely quits at:** 110 s. **Why:** They came to mess with each other, and the game splits them up from the first frame. Lab.claim gives each friend a separate private plot 250 studs apart. PlotPrivacy turns the other labs into solid blocks and hides the avatars in them. Nothing says a friend is in the server. The only ways to meet are MENU > FRIENDS > LAB INVITE > Places, or MAPS > Plaza, and FirstVisit holds both until about 50-60 s (the real reveal is max(35, t+45), not 35). Even then nothing points at them, and plaza PvP is throttled to a no-score knock every 3.5 s. Meanwhile every solo hook fires inside 45-110 s: the UFO (serialised server-wide), the egg (whose WOW weapon falls into a 10-s pick-a-slot step), the surprise and the chase. On the upright phone, auto-equipped melee rungs (Bat, Poke, Crowbar, later Heal and Slap) keep removing the SHOOT button, so at 100 s the chase swarms a player with no gun and a 39-degree view. At about 110 s the phone friend has had no shared moment, has a 'Fire yourself from the CANNON' line stuck on screen, and has nothing new coming for minutes. They leave, and the other two follow because their friend is gone.
- **Confusions:** 'Are we even on the same server?' Friends are split into private labs, other labs are solid blocks, and their avatars are not drawn (Lab.claim, PlotPrivacy).; 'Fire yourself from the CANNON': no cannon is on screen on any device, it sits about 83 degrees to the right, and the line never moves on until it is done or 300 s pass.; Two different goals at once at 4-25 s: 'Fire yourself from the CANNON' at the top and 'Now try another tool!' at the bottom. At 40 s a third: the Experiment card.; 'My SHOOT button disappeared': auto-equipped Bat, Poke or Crowbar becomes the held tool on the phone.; '3 weapons unlocked!' at about 55 s, for the three tools held since second 0.; 'Going on your bar now!' followed by 'Pick a slot for Minigun' and then 'No slot picked: Minigun stays in WEAPONS'.; Two invite buttons: 'LAB INVITE' (into your lab) and 'INVITE FRIENDS' (Roblox's sheet). Plus 'X let you into their lab! Find it in Places' when Places is in MENU on a phone.; 'They're down. Wait till they're back on their feet!' and 'They just got up. Give them a moment!' repeat while shooting friends in the plaza.; An event banner for a friend's BIG RED BUTTON event that nothing in your own world shows, while your own button says 'Busy, try again soon'.; The MULTIPLAYER door in the lab: friends walk in hoping to find each other, and PLAY NOW sends them to another server.; The phone's WEAPONS slab is a 46-px toolbox icon with no word, while the line says 'Open WEAPONS for more'.; Experiment cards naming machines nobody has seen: 'Let the ROBOT VACUUM suck up a dummy' (88 studs behind the spawn), 'FEED THE SPIDER' (90 studs to the side).; The toy word 'Popper' alongside a loud realistic gun recording (a mixed tone, minor).
- **Wow moments:** The greeter walks up and the first shot lands in 3-8 s. The instant takedown credit and the '+1 TAKEDOWN' pop feel good (GreeterService, ProgressService.greeterHit).; The human cannon ragdoll launch, for the player who finds it (Playground.luau:205-219).; A UFO beaming the lab dummies up at about 50-70 s (Surprises.UfoBeam via EventService.surpriseNow).; The free first egg with a WOW weapon (Minigun, RPG, C4, TNT, Rocket or Grenade) at about 75 s (ProgressService.WOW_POOL).; NPC Chase at 100 s for a PC player with a gun: 4-10 red chasers to knock down, with a +3 bonus.; Plaza grab-and-throw of a friend, for the few groups that work out how to meet there.; The BIG RED BUTTON's random free event, if anyone turns around and finds it.
- **Top fixes:**
  - Friends who join together play together from second 0. In Lab.claim/onJoin, if the joiner followed someone (player.FollowUserId) or a Roblox friend is already in the server, add them to that friend's LabGuests both ways, spawn them in that friend's lab, and start a Prank Party card at once with PARTY_THROWS (Lab.luau:757-785 and 1022-1040, FriendsService, PartyService). A solo joiner keeps a private lab.
  - Make friends visible and reachable. PlotPrivacy should never hide a Roblox friend's avatar or name pill, even across labs. Show a critical-kind toast that passes the newcomer quiet: 'SOFIE is here: TAP TO JOIN' with a one-tap teleport. Put FRIENDS on the first-visible HUD on every device, not in MENU (PlotPrivacy.luau:123, FirstVisit.luau:42, HudMenu.luau:28/53/56).
  - Rewrite the first-visit objective for groups: 'Throw your friend into the CANNON' (the TOSS COMBO already exists in ExperimentService.tossCombo). Allow PvP grab/throw in a shared lab for the first 5 min. Score friend knocks and throws (a 'GOT YOU +1' pop and a takedown-equivalent), and shorten PLAZA_GAP (3.5 s) and the grab pair gap (10 s) between friends.
  - Stop the ladder from stealing the weapon in hand. autoEquip should never change `selected` on touch unless the new tool is a gun or explosive. Take Poke, Heal, Slap and Shove out of auto-equip (or off the early ladder). Reserve the auto-replace for filler so Grenade (10) and the egg's WOW weapon always land on the bar without a 10-s 'Pick a slot' (PokeController.luau:745-760 and 1694-1719, ProgressUI.luau:295 and 315-317 and 632-647).
  - Fix FirstVisit pacing. Base MIN_QUIET on spawn time so the HUD really arrives at 35 s (FirstVisit.luau:206). Make the steps any-order with a per-step timeout of about 25 s instead of the 300-s GIVE_UP. Give the off-screen cannon (about 83 degrees right of spawn) a ground arrow or beam. Collapse the 3-4 duplicate 'shoot the dummy' prompts into one (OnboardingController hint, TouchShoot hand, help line).
  - Give each lab its own event slot. Lab surprises, the first-wow UFO, the BIG RED BUTTON and chases must not be blocked by the server-wide miniUntil or EventService.current. Send the event banner only to players who can see the host lab (EventService.luau:100-115 and 625-672, Playground.luau:900-905, EventShop.luau:1446-1459).
  - Fix the false and overlapping UI. Drop '3 weapons unlocked! Tap WEAPONS' (starterCount = the 3 tools held since 0 s) and say 'Click' on PC. Gate ExperimentCard behind NewcomerUntil, or move it off the FirstVisit pill on phones (y 48-88 against the card at 12,68). Add FirstVisitGoal to LayoutCheck. Move HudV3's bottom-left column off the tablet thumbstick zone (HudV3.luau:472-479).
  - Surface the content that exists inside minutes 1-3, ideally as group moments: the BIG RED BUTTON (14 studs behind the spawn), the lab cars, the creature yard (88-98 studs behind or beside), and one open-air map launch. Remove or relabel the lab's MULTIPLAYER door for players already in a server with friends, because its PLAY NOW teleports them away.

### An 8-year-old on a cheap Android phone held upright (414x814 portrait; some cheap phones are 360 px wide). First visit, arrived from the Roblox home page, reads very little English, taps everything, knows the thumbstick and camera drag from other Roblox games. t=0 is when the loading screen goes and the avatar is visible. Server timers start at PlayerAdded, about 3-5 s earlier. This was simulated from the code only (read-only, not played in Studio). Paths are short: Client = StarterPlayerScripts/StarterPlayerScripts/Client, Server = ServerScriptService/Server/Systems, Shared = ReplicatedStorage/ReplicatedStorage/Shared.
- **Score:** 3/10. **Likely quits at:** 90 s. **Why:** By about 90 s the one thing this kid enjoys (shoot a dummy, watch it fall) has been taken away three or four times by the game itself. At 22 s the 25-s fallback auto-equips and selects Bat, Poke and Crowbar, so the gun and the SHOOT button vanish. Every later unlock up to 10 takedowns takes the hand again (Revolver, Shove, Slap, Heal), and the Grenade can't even get onto the bar. The one real wow, the auto egg's Minigun or RPG at about 70 s, hits a full bar and ends in 'Pick a slot for Minigun', then after 10 s 'No slot picked: Minigun stays in WEAPONS'. Every goal is English text pointing at something outside the upright view: the cannon is behind-right, the creatures are 90 studs away, the experiment card is about 11 px and overlaps the pill. On phones there is no visible 'next weapon' goal at all (the next cards are forced off and the big WEAPONS button is hidden). So at about 90 s the screen shows the same 6 dummies, a weak tool in hand, and nothing to look forward to. Anyone who stays meets a second exit at about 100 s: the chase, which arrives while they are often holding Heal or Slap.
- **Confusions:** 'Where did my gun and the SHOOT button go?' At 22 s the fallback auto-selects Bat, Poke or Crowbar.; 'Why do the dummies only flinch now?' Poke is 'A tiny prod. They flinch'. Heal does nothing to a standing dummy.; 'My new Minigun isn't there.' The pick-a-slot chip times out after 10 s with an English toast.; 'Fire yourself from the CANNON': what cannon? It is behind-right, out of the upright view, and there is no arrow.; Two goals at once: the top pill (cannon) and the experiment card (e.g. FEED THE SPIDER, 90 studs away, about 11 px text with a countdown), probably overlapping top-left.; 'Open WEAPONS for more', but no button on a phone says WEAPONS; the bar slab is a toolbox picture only.; The reveal toasts contradict each other: 'Find it in WEAPONS' and 'It's on the bar'. '3 weapons unlocked!' when 3 is what they had from the start. 'Come back tomorrow' 50 s into the first visit.; 'TAKEDOWN', 'BOLTS', 'NPC CHASE', 'EXPERIMENT': words an 8-year-old non-English reader can't read.; SHOP opens straight onto Robux offers; MENU is a list of English words.; On a 360-px Android the selected 6th tool is in the hand but not on the bar.
- **Wow moments:** 0-20 s: the greeter walks up, one tap and it falls. Aim assist (12% of the short side), Popper one-shots to the torso, cowards zigzag away with flailing arms. A strong first 20 seconds.; If the kid finds the cannon: launched about 1 s across the lab onto the bullseye, '🎯 BULLSEYE!'.; About 50 s: the UFO beam lifts dummies (only partly visible on an upright phone).; About 70 s: the egg cracks open to a Minigun, RPG or C4. A real wow, if the weapon reaches the hand.; Tapping RAGDOLL to flop your own avatar.; About 100 s: the NPC chase can be exciting with a gun in hand.
- **Top fixes:**
  - Stop the auto-equip from taking the kid's hand. Never auto-select a new tool while one is in use. Never auto-equip Poke, Slap, Shove or Heal (only guns and explosives). Let a new gun or bang replace the weakest slot without asking: extend GIVE_UP to Poke, Slap, Heal, Shove, Punch, Crowbar, Bat. The egg prize must always land in the hand, with no pick-a-slot step and no 10 s timeout (Client/PokeController.luau:745-794,1693-1719; Client/ProgressUI.luau:314-317,632-640).
  - Re-order the ladder so the first five unlocks are toys a kid wants (Grenade, Rocket, Minigun-lite, Launch, Firecracker within the first 2-8 takedowns). Move Poke, Slap and Heal far up or into a 'Silly' shelf (Shared/Toys.luau:197-199,207,227,249,259).
  - Lay the world out for an upright phone. Put the first objective (cannon plus bullseye) and one creature inside ±15° of the spawn facing, 15-25 studs away. Or pan the camera to the target for 1.5 s and draw a bouncing 3D arrow or footprints on the floor. Drop the 'no arrows' rule for first visits (Server/Playground.luau:157,273; Server/Lab.luau:744-751; Client/FirstVisit.luau:7).
  - Make the first visit wordless and translated: pictograms plus a pointing hand for every step (cannon icon, ball icon, toolbox icon), and LocalizationService/auto-translate for the about 30 first-visit strings. Cut every first-10-min sentence to 3 words or fewer, with an icon (FirstVisit STEPS, OnboardingController hints, ChaseService notices, NotifyRules toasts).
  - Keep one goal on screen. Hold the Experiment card until the FirstVisit line is done (or merge the two). Never deal creature or map cards as a newcomer's first card. Add FirstVisitGoal to LayoutCheck; on 414 px it likely overlaps the card at x 12-170, y 68-114 (Client/ExperimentCard.luau:71-83; Client/HudSlots.luau:167-172; Server/ExperimentService.luau:268-272).
  - Show the progress loop on phones. One big 'NEXT: Grenade ■■■□ 3 more' card above the bar on portrait phones. Today plan() sets up = 0 on touch phones and HudPlus hides WEAPONS there, so phones, the biggest group of players, get no goal at all (Client/PokeController.luau:471-475; Client/HudPlus.luau:582-585).
  - Bring the egg forward and make it automatic. Auto-open the first egg at about 20-30 s, before any reveal gate (today it is ≥65 s behind FirstVisit, NOTIFY_BIG_AFTER_REVEAL and BIG_GAP), with the weapon in the hand and a 'tap to shoot' hand on it (Server/ProgressService.luau:1631-1664; Client/ProgressUI.luau:605-622; Client/Notify.luau:206-224).
  - Fix the reveal timing and the toast burst. QUIET_START 35 is overridden by FirstVisit.MIN_QUIET 45 (Client/FirstVisit.luau:39,206). Remove the contradictory pair 'UNLOCKED: X! Find it in WEAPONS' / 'Your X is on the bar', the wrong '3 weapons unlocked!' (the starters) and 'Daily egg! Come back tomorrow' on visit one. At most one toast per 15 s in the first 3 minutes.
  - Frame the wows for portrait. The UFO at h=40, 25 studs ahead, is above an upright camera's view: drop it to about 15-18 studs, bring it in from straight ahead at 30-40 studs, and add a sound sting. Use the same check for every surprise (Server/Surprises.luau:128,147).
  - Retune the first chase for kids on phones: 2 slow cartoon chasers from the front, a forced gun in the hand, no KO in the first chase, and an icon announcement. It should also not start while the selected tool can't knock anything down (Server/ChaseService.luau:30-40,131-135,203-206).
  - Cheap 360-px Androids: never let the selected tool sit in a slot the bar does not draw. Show 6 slots at 44 px, or keep the selected tool among the drawn ones (Client/PokeController.luau:512-521).
  - The designed first-minute replay and the RAGDOLL tip never fire. onBigEvent needs a 'big' toy, and none of the starters (Popper, Grab, Punch) is big, so every newcomer gets the silent 25 s fallback. Either make the Popper's first knockdown the trigger or delete the dead path (Client/OnboardingController.luau:234-249,551-575).

### Day-2 returning player on an iPad in landscape (touch, not a phone, so HudGate gives it the PC 'HudV3' layout). Played about 6 min yesterday (about 360 s, above NEWCOMER_SECONDS 300, so no FirstVisit flow). Ended yesterday on about 25 takedowns with the early ladder auto-equipped. Came back today to 'see what's new' on 0.25.0. No gamepad, so GamepadControls/PadMap never apply.
- **Score:** 3/10. **Likely quits at:** 158 s. **Why:** The player came back to see what's new and the code gives them almost nothing. The only explanation of the update is the What's New window. It opens mid-tap at about 13 s, the next tap closes it via the backdrop, and that close marks it seen forever. 2 of its 4 bullets are false (birds off, no crash-test marks under LOOK_V3). The Day-2 Rattler gift toast says 'It's on your bar' while autoEquip fails: the bar is clogged with Poke, Slap and Heal, which autoEquip never gives up. NEW tags mark yesterday's things. The first-minute script is identical to yesterday: greeter, 'TAP A DUMMY' hand, UFO at about 45 s, chase at 100 s. On the tablet the HudV3 squares steal the move thumb and MENU covers RAGDOLL. Once the chase ends at about 150-155 s, nothing is scheduled until the free ULTRA at 300 s. The unlock toasts ('Find it in WEAPONS'), near-ladder eggs and bolts that buy the next free rung give no reason to stay.
- **Confusions:** 'DAY 2 GIFT: the RATTLER... It's on your bar.' It is not on the bar (ProgressUI.luau:571-575 ignores autoEquip's false return).; The What's New window flashed and vanished on the next tap. Where do I read it again? (closeOnBackdrop + SeenNew on any close); What's New promised birds and crash-test dummies; neither exists (Config BIRDS=false; LOOK_V3 strips marks).; Trying to walk opened SHOP or WEAPONS or LAB (HudV3 squares in the thumb zone).; Where is the RAGDOLL button? Tapping there opens MENU.; 'UNLOCKED: X! Find it in WEAPONS', again and again, but nothing new ever goes in hand.; 'FEED THE SPIDER a dummy': where is the spider, and how do I carry a dummy that far on a tablet?; 'The clock is on WEAPONS': there is no clock on anything named WEAPONS on this HUD.; What are BOLTS for? (the BUY is hidden in EXPERIMENTS and buys the next free rung); NEW tags sit on the red button, cars and portal I saw yesterday, while the actually-new creatures have no tag.; A 'Pick a slot for X' chip froze my shooting for 10 s after an egg I didn't ask for.
- **Wow moments:** The first shot lands within a couple of seconds: tablet SHOOT plus aim assist work, matching the 3-17 s first-shot data.; The DAY 2 GIFT toast and chime (until the player notices the weapon isn't on the bar).; The NPC CHASE at about 100 s: 7 red chasers rushing in, with a health bar. The one moment of real tension.; The UFO beam at about 45-55 s, if the player happens to be near the lab middle and hasn't seen it before.; The egg opening animation and 'NEW WEAPON' reveal, though its prize is underwhelming.
- **Top fixes:**
  - Build a real 'since you left' moment for returning players. A non-modal card at spawn names today's 1-2 new things. A gold glow trail leads to them, reusing FirstVisit's Highlight. The daily weapon is forced into the player's hand. Self-opening windows get closeOnBackdrop=false, and only GOT IT marks What's New seen. Correct Shop.WHATS_NEW 0.25.0 (drop BIRDS and crash-test marks), and add a test that each bullet's Config switch is on.
  - Fix the bar clog. autoEquip should replace the weakest non-chosen slot by power, not only Shove/Punch/Crowbar/Bat. At least add Poke, Slap and Heal to GIVE_UP, or stop auto-equipping non-gun melee with unlockAt<=10. Make the Daily/Unlock toasts read autoEquip's return value, so 'It's on your bar' is only said when true.
  - Tablets get the touch/phone layout (as RESEARCH_FIRST_SESSION.md:222 says), or HudV3 moves its squares out of the lower-left move zone and keeps RAGDOLL out from under MENU. Add HudV3's squares and the MoveStick zone to LayoutCheck, which today checks the hidden kit launcher instead.
  - Fill the dead zone from 150 s to 300 s and stop repeating the script. Returning players skip the greeter and the 'TAP A DUMMY' hand. The first wow rotates by day, not the same UFO at 45 s. Add a guaranteed beat around 170-200 s (a daily boss or machine-of-the-day event in your lab). Offset the chase for players who saw it yesterday.
  - Make progress feel like progress. Fewer, bigger rungs instead of the squeezed ladder spam (32, 34, 35, 37, 39...). Eggs after the first 2 should give something the ladder won't hand out in the next minute. Bolts should buy something the ladder can't (skins, machines, a weapon 50+ rungs up), and BUY should leave the EXPERIMENTS window.
  - Experiment cards: the first daily card must be doable from spawn in under 30 s (no 100-150 stud touch carries). Creature cards show a glow and arrow on the creature, and start the carry with the dummy auto-grabbed or delivered by a chute.
  - Self-opening windows must respect real action. Count GUI-processed SHOOT/GRAB presses in ProgressUI.lastAction. Never open the egg card or What's New during a fight or a chase.
  - Point NEW tags at the actual update (Config.NEW_IN_LAB = creature habitats, paths), and put the gift clock on something HudV3 actually shows (the top-bar gift).

### A 13-year-old on PC (mouse and keyboard), first visit, a Ragdoll Engine and Fling Things and People veteran. He gets bored fast, wants chaos right away and wants to troll friends. Times are client seconds from the first frame. The server joins about 5 s earlier, so server timers land about 5 s sooner than their Config value. Paths: Client/ = StarterPlayerScripts/StarterPlayerScripts/Client, Server/ = ServerScriptService/Server/Systems, Shared/ = ReplicatedStorage/ReplicatedStorage/Shared.
- **Score:** 3/10. **Likely quits at:** 90 s. **Why:** By 90 s he has used up everything the lab shows from where he spawns: six white mannequins that crumple on one Popper round (gun rounds never fling), a UFO he could only watch, and one RPG/C4-type egg weapon that arrived at 68 s. Nobody else is in his world, because every other lab is hidden on his screen and friends need an INVITE in a menu, so the one thing he came for, trolling friends, has no path. The objective line points at a cannon that sits 83° to his right with no arrow, and it blocks the 'Open WEAPONS' step. A second objective with a timer may name a creature 120 studs away. The UI never says what is coming next. The chase, the hook built for exactly this kid, starts about 5 s after he leaves. A second risk point is 45-55 s: the UFO, the experiment card, the HUD reveal and stale toasts all land in one ten-second window.
- **Confusions:** Two different instructions at once from 7 s to 25 s: top 'Fire yourself from the CANNON' (FirstVisit) and bottom 'Now try another tool!' (OnboardingController.luau:534).; The cannon he is told to use is off screen (pad at 48,6, about 83° right of the camera) with only an occluded highlight on the pad, no arrow.; WEAPONS square and T key silently do nothing for the first 25 s (PokeController.luau:1481-1485, 1855-1858), although HudV3 shows WEAPONS from frame 0.; The bar changes at 25 s (Bat, Crowbar, Revolver, Shove appear) with no explanation; their toasts are held by the newcomer quiet.; A second objective with a countdown (Experiment card, top-middle y=108) appears at about 35 s, before the HUD reveal, and can name a creature he has never seen (spider at -90,-70; others behind the spawn at z about 92).; '3 weapons unlocked! Tap WEAPONS' at about 48 s refers to the 3 starters he has held since 0 s, and says 'Tap' on a PC; 'New tool: Punch!' for a starter.; He is never told how to ragdoll himself until the key chips at about 63 s: the F tip is only queued after a first replay that the starters never trigger, and the RAGDOLL pad is off on PC.; 'Where is everyone?': other players' labs are hidden, friends need an INVITE in a menu, and the plaza is 250 studs away or behind MAPS.; Currency soup in MENU/EXPERIMENTS (BOLTS, stars, journal pages, daily cards), with no meaning in minute 1-2.; Roblox 'E Talk' prompts pop over lab dummies within 9 studs while he punches them.
- **Wow moments:** Under 5 s to the first shot: the greeter walks up and the first hit always counts as a takedown (GreeterService, ProgressService.greeterHit).; Grab-and-throw a mannequin (slot 2 / G): the closest thing to Fling Things in the first minute.; UFO beaming the mannequins up at about 45 s, placed 25 studs in front of the player (Surprises.UfoBeam).; The self-opening egg at about 68 s with a WOW weapon (RPG/C4/Minigun/Grenade/TNT/Rocket) put on the bar.; Not reached in time but strong: the cannon launch plus bullseye, the wrecking-ball throw, the 4-10 red chasers at about 95 s, cars and a monster truck, the BIG RED BUTTON, and TRY FREE on the Nuke in WEAPONS.
- **Top fixes:**
  - Put other players in his world: by default, let everyone in a 6-player server see and reach each other (a shared open lab, or a joined-friend auto-routed into the friend's lab with grab/throw on). PlotPrivacy currently hides every other lab, and players can touch each other only in the plaza. Ragdoll Engine and Fling Things are about other people.
  - Chaos in hand by 20 s, not 68 s: open the first WOW egg (RPG/C4/Grenade/Minigun) at about 20 s, or put one of those on the first-minute bar. Give the starter gun real knockback so a hit throws the body, not only drops it (ActiveRagdoll.gunReaction).
  - One objective system: hold ExperimentCard until FirstVisit's steps are done (it is dealt 40 s after PlayerAdded with no newcomer check). Never deal creature or off-screen daily cards to a newcomer, and no timers on the first cards. Drop OnboardingController's 'Now try another tool!' hint while the FirstVisit line runs.
  - Make the cannon findable: turn the spawn or camera toward the cannon and bullseye, or add an off-screen edge arrow and an AlwaysOnTop highlight. Move the BIG RED BUTTON (14,14, behind him) and the car/truck pads (66,20 / 68,-32) into the first camera view. Let FirstVisit skip a step after about 20 s instead of blocking 'Open WEAPONS' until 300 s.
  - Remove dead and false UI: make the WEAPONS square and T work from 0 s, or hide them until they do. Rewrite '3 weapons unlocked! Tap WEAPONS' to name what was actually earned (Bat/Crowbar/Revolver), with 'Click' on PC. Show the 'F Ragdoll' chip from 0 s on PC, and also schedule the ragdoll tip on the unlockFallback path (today it is only queued after a first replay, which the starters never trigger).
  - Pull the 90-120 s hooks into 50-80 s and space them: chase at about 70 s, right after the egg; a lab surprise the player triggers himself, such as a big red button in view, at about 55 s. Fix the timing that is really shipping: FirstVisit.MIN_QUIET 45 overrides QUIET_START 35, so the reveal is at about 48 s. Don't stack the UFO, the experiment card and the reveal in the same 10 s.
  - Give the first visit a social or trolling goal, not just a bigger number: for example a first mission 'Launch a friend/visitor from the cannon' or a TRY FREE Nuke offered on screen at minute 1. Hide BOLTS, stars and journal from a newcomer until minute 5. The first play gift should be a weapon, not 40 bolts.

### A 12-year-old on an iPhone held upright (about 414x814, the most common device in Session_v1). He has just watched a TikTok of a dummy flying out of a cannon in slow-mo and opens Ragdoll Havoc to do exactly that. It is his first visit (Newcomer=true), he knows Roblox's touch controls and he has about 2 minutes of patience if he doesn't get the shot. Times below are seconds since join; the world is visible about 2-5 s in. Paths are relative to C:\Users\tristan\Documents\RagdollLab: Client = StarterPlayerScripts/StarterPlayerScripts/Client, Server = ServerScriptService/Server/Systems, Shared = ReplicatedStorage/ReplicatedStorage/Shared.
- **Score:** 3/10. **Likely quits at:** 125 s. **Why:** The cannon he came for fails him at about 34 s, and the game runs out of things to do at about 120 s. The flight is a 1.0 s, real-time hop (120 studs/s, about 23 studs at its peak) that never gets slow-mo: SlowMotion only slows Dummies, never the player's own avatar. It never gets a replay either: Replay is held for newcomers, and the recorder only captures Dummies and Props. A phone has no slow-mo control at all (PC-only sandbox column). He tries the cannon 3-4 times and checks MENU for slow-mo. The auto-egg weapon (t≈70) and the NPC chase (t≈100) keep him going briefly. Then at t≈120 the last scheduled hook pays 40 'BOLTS', a currency with no counter on the phone HUD. The next-weapon progress the 20 Nov changes rely on is stripped from every touch phone. The mission card points at a creature 92 studs behind the spawn. Nothing else is due until about t≈230-350. With nothing in view to chase and the TikTok promise not deliverable, he leaves at about 125 s, the measured median.
- **Confusions:** Four simultaneous 'shoot the dummy' cues (top pill, bottom hint, world hand, gold diamond), then a top pill that says 'go to the cannon' while the bottom says 'try another tool'.; 'Fire yourself from the CANNON' appears while the cannon is completely off-screen (82° right of the camera's view) with no arrow or sign; the bullseye it lands on is straight ahead, which makes it worse.; The 'LAUNCH GIFT ... Open it in RANK & EGGS!' toast at about 10 s, when RANK & EGGS is inside a hidden MENU.; At about 25 s the bar rebuilds itself mid-objective: a pulsing WEAPONS slab plus Bat, Crowbar and Shove slots appear with no explanation, because their toasts are held.; Where is the slow-mo from the clip? It doesn't exist on a phone, and the cannon flight is real time and about 1 s.; No replay of his own cannon flight: the replay is held for newcomers, and the recorder never captures the player's avatar.; At 40 s, two missions at once that overlap on screen: FirstVisit's pill and a random daily experiment card, often about a creature 92 studs behind him.; '3 weapons unlocked!' at about 50 s for the 3 tools he has had since spawn.; A tip to 'blast off the CANNON at the BULLSEYE' after he already did it.; '+40 BOLTS' with no BOLTS counter anywhere on the phone HUD (only inside the EXPERIMENTS window).; No 'next weapon' progress at all on an upright phone, so the ladder that is meant to pull him forward is invisible.; The opened WEAPONS catalog is a wall of LOCKED cards and Robux prices: the first screen the game sends him to reads as a store.
- **Wow moments:** The first shot lands within seconds: the greeter walks into view, and the first hit counts as a takedown even on an arm (Server/ProgressService.luau:965-972).; The cannon lands him exactly on the bullseye, with a BULLSEYE toast, a hit burst and a real Roblox badge (Server/Playground.luau:125-149).; The self-opening first egg at about 70 s puts a WOW weapon (RPG, Minigun, C4 and the like) straight onto the bar (Server/ProgressService.luau:1039; Client/ProgressUI.luau:605-622).; The wrecking ball throws him across the lab (95 studs/s sideways, 55 up).; The NPC chase with the new WOW weapon is the one moment of real stakes in the first 2 minutes.; Cowards fleeing in a zigzag when shot reads as alive and funny.
- **Top fixes:**
  - Deliver the clip in the first 15 s. Move the cannon (or the spawn's facing) so it sits inside a portrait camera's ±20° view at spawn; it is 82° off-screen today (Server/Playground.luau:157 vs Server/Lab.luau:750). Make the first cannon shot an automatic slow-mo cinematic: extend Client/SlowMotion.luau stepBodies to the local character for cannon and station launches, and give the flight more hang time (it is 1.0 s now). Then auto-play an Instant Replay that includes the player's own avatar (Client/ReplayController.luau:91-105 records only Dummies and Props), with CLIP IT and SHARE as the payoff.
  - Make the TikTok shot itself a guided step: 'Throw a dummy into the CANNON' (Grab, then the pad, then an automatic slow-mo replay of the dummy). Give the pad a small label again (Server/Playground.luau:496 drops 'PUT RAGDOLL HERE').
  - Use one objective voice. While FirstVisit runs, suppress OnboardingController's hint and diamond and TouchShoot's 'TAP A DUMMY'. Hold ExperimentCard until FirstVisit ends: it overlaps the pill at y 48-114 on portrait (Client/ExperimentCard.luau:71-83 has no newcomer check). Add the FirstVisitGoal pill to LayoutCheck.
  - Route every server Notice through Notify, or hold Notices for newcomers (Client/ProgressUI.luau:587-589). Never send 'Open it in RANK & EGGS' while MENU is hidden (Server/LaunchGift.luau:22). Cancel the lava/cannon tip once those are done, and drop the '3 weapons unlocked!' line for starters the player already holds.
  - Fix the reveal clock. FirstVisit.MIN_QUIET 45 always beats Config.QUIET_START 35 (Client/FirstVisit.luau:39, :206), which pushes the HUD to ≥45 s and the first big pop-up (the WOW egg) to ≥65-70 s. Drop MIN_QUIET to about 20 and open the first WOW egg right after the first cannon landing (≈35 s), not at reveal+20.
  - Give phones visible progression. Bring back a slim portrait 'Next: GRENADE 6/10' pill. It is removed for all touch phones today: Client/PokeController.luau:471-475 (up=0), Client/HudPlus.luau:584 (PHONE_HUD_MAX7), Client/PokeController.luau:1588 (NEXT_ON_BAR=false). Show the BOLTS balance on the HUD or stop paying newcomers in BOLTS (Server/PlaytimeGifts.luau:177).
  - Give touch screens a SLOW-MO button (and/or slow-mo by default on big launches): it is PC-only today (Client/HudPlus.luau:594; Client/HudGate.luau:15-20), and the Slow-Mo Spell needs 1000 takedowns.
  - Fill the 120-300 s hole with a hook every 30-40 s. Offer the second WOW egg (LaunchGift and the daily egg already exist), run the first lab surprise and a BIG RED BUTTON prompt ('Press it!') around 130-160 s, and make the first three mission cards only things visible from the spawn (cannon, bullseye, wrecking ball, button), not the 12/21 off-screen ones (Shared/Experiments.luau:118-127 random daily deck).
  - Make the newcomer's UFO and surprises independent of other players' server-wide events (Server/EventService.luau:651-666 requires current == nil). Place the UFO low enough to be inside a portrait frame (40 studs up, 25 ahead is above the top edge).
  - Turn the cannon into a loop worth repeating: show a landing score (distance, bullseye points), a quick 'AGAIN' return pad by the bullseye, and a personal best, so launches 2-10 are a game rather than the same 1-second hop.

## A-P audits

### A - First impression and the first 3 minutes (spawn, FirstVisit, quiet start, greeter, first shot, first wow, HUD reveal, onboarding hints): 3/10
The mechanics work: new players fire within 3-17 s, so the controls are clear. Everything after that first shot fails. The player gets up to four instruction layers at once. The machine goals point at things that are off screen. The first unlock (Bat at 2 takedowns) is held back for 25-50 s, and one unlock produces up to four messages that contradict each other. The "first replay unlocks the catalog" design can never trigger. About 12 separate clocks on two machines crowd the experiment card, the UFO, the HUD reveal, the egg modal, the surprise and the chase into 40-110 s, which is where the median visit ends (~120 s). The test T55 enforces that crowding. The first weapon is a weak toy pistol and 5 of 6 dummies run from it. The big WOW weapons only come through a late full-screen egg that the data says almost nobody sees. The portrait layout rests on a viewport reading taken in the first ~2 s after the client starts. The greeter may also be sent from the plaza before the player is moved into the lab, and the tests skip the real join path. Measured result: 1 in 11 visits passes 4 min and none pass 5 min on the newest build. Much careful work has gone in, but the result for a new player is a 3.

**10/10 means:** A 10/10 first 3 minutes, on every device:
- **0-3 s (control in under 8 s on a phone):** a small ReplicatedFirst loader closes on "lab streamed + character placed". The player appears inside their own lab, never the plaza. The camera framing is set per orientation (landscape, or forced LandscapeSensor) so that 3 standing dummies are 10-15 studs ahead and the cannon plus one machine are clearly in frame behind them.
- **The first screen has exactly 4 things:** the bar (3 labelled slots, no ammo counter), one action (crosshair on PC/pad, one big SHOOT button on touch), WEAPONS with a "Next: Bat 0/2" bar, and ONE objective line ("Hit the dummy!"). The greeter carries the only pointer. There is no help line, hint, hand, chat window or player list.
- **3-15 s:** the first hit knocks the greeter flat with an exaggerated flop: 0.3 s slow-mo, a camera punch, a loud pop, "+1", and the WEAPONS bar jumps. The lab dummies do not run until the 3rd takedown.
- **~10 s:** at 2 takedowns the Bat lands on the bar at once, already picked, with one compact card ("NEW: Bat"). The next tap is a home-run swing, the first real wow.
- **15-90 s:** one server-driven chain of 3-4 goals, all with dummies: swing the Bat, then grab and throw a dummy into the cannon, then land the bullseye. Each goal has:
  - in-view targets glowing, and off-screen targets shown by an edge arrow plus the V7 path lit from the player's feet;
  - a stuck hint after 20 s and an auto-skip after 45 s;
  - an instant visible reward.
- **~30 s:** after the 3rd takedown a crate drops beside the player. Breaking it in the world gives a WOW weapon (Grenade or Rocket), with no modal, and the next goal is "Throw the GRENADE at them".
- **90 s on:** the HUD reveal is itself a reward ("SHOP unlocked"), one piece every 10-15 s. There is no second goal system, no timers, no bolts, stars or journal, and no chase, UFO or modal before 3 min. One event-driven director owns the whole timeline.
- **At 3 min:** 3+ weapons owned, 2 machines found, 1 big explosion fired, and the next goal always on screen.
- **Measurement:** behavioural Session_v1 steps (FirstHit, FirstUnlockUsed, FirstThrow, FirstMachine, FirstBigWeapon, Min3, Min5, and what was on screen at leave) show the median first visit above 5 min and over 40 % reaching the cannon (BRP 41 %).

- **[critical/high/S] Four instruction layers and two pointers at once in the first 5 s.** A newcomer is told the same thing up to four times in four places:
- the FirstVisit pill at the top: "Knock a dummy over!";
- the pulsing gold-edged hint above the bar: "Click/Tap the dummy to shoot!";
- on PC, the help line under the bar: "Click a dummy to use the Popper";
- on touch, the TouchShoot "TAP A DUMMY!" hand, plus the neon gold diamond pointer over the greeter. That is two pointers on one target.

Right after the first shot the screen gives two different goals at once: the top says "Fire yourself from the CANNON" and the bottom says "Now try another tool!". Touch also mixes two input ideas, "tap the dummy" and a big SHOOT button that fires at the centre crosshair. The vault rule says one pointer at a time, and a hint should add where or how, not repeat the objective. *Evidence:* FirstVisit.luau:44 and 302; OnboardingController.luau:143-175 (showHint, pulse), 323-326 (shootHint), 534 ("Now try another tool!"), 273-308 (GreeterPointer); PokeController.luau:353-366 (helpText first line kept for newcomers); TouchShoot.luau:35, 240, 300; vault 'Tutorial Step Design Patterns - Teach by Doing' TL;DR (one focused step, one pointer; the hint adds where or how) *Fix:* For a newcomer, keep only the FirstVisit line and one world pointer (the diamond over the greeter). Remove these during the first visit:
- the OnboardingController hint;
- the help line;
- "Now try another tool!".

Show the TouchShoot hand only if no shot comes within 6 s, and say "Press SHOOT" (matching the button), not "tap".
- **[critical/high/M] The real timeline is a pile-up of about 12 separate clocks between 25 and 110 s.** The Config comment promises "one hook every 30-40 s". In fact `revealAt = max(QUIET_START 35, time()+MIN_QUIET 45)`, so a newcomer's HUD reveal is about 48-55 s, not 35. Against that, these fire on their own clocks, client time() and server os.clock() mixed:
- unlock fallback at 25 s;
- QUIET_START 35 s, which still drives the phone level badge and RUN, so they appear before SHOP/MENU;
- the experiment card 40 s after PlayerAdded on the server;
- the first-wow UFO at 45 s on a 10 s polling loop, so 45-65 s;
- NEXT cards at 45 s;
- the touch hand and greeter lifetime at 45 s;
- the first egg at 60 s, then a full-screen AutoEgg at reveal + 20 s;
- the lab surprise at 80-110 s;
- the chase at 100 s;
- the +1 TAKEDOWN pop ending at 120 s;
- the play gift at 120 s.

T55 asserts that the experiment, the wow and NEXT land "between the quiet start and 60 s". For a newcomer that is before or during the real reveal, so the test locks the pile-up in. Everything crowds into the 40-110 s window, just before the measured median leave at ~120 s. *Evidence:* FirstVisit.luau:39, 206; Config.luau:19-23, 48, 155-156, 172; ExperimentService.luau:266-272; EventService.luau:646-671; NextUnlocks.luau:288-290; HudPlus.luau:531-534; Sprint.luau:163, 169; ProgressService.luau:1631; ProgressUI.luau:604-617; ChaseService.luau:39; Toys.luau:342; T55_QuietStart.luau:25-37 *Fix:* Replace the timers with one server-authoritative FirstSession director. It keeps a beat queue that moves on behaviour (first hit, first unlock used, first machine, first big weapon), not on seconds. It allows at most one new beat per 15 s, and only when the player is calm (no window open, no ragdoll, no objective just completed). Every client module asks `FirstSession.allowed(beat)` instead of reading QUIET_START. Rewrite T55 to check the effective order and gaps of a simulated newcomer timeline.
- **[critical/high/S] The first unlock is muted for 25-50 s and announced four contradictory ways.** The Bat unlocks at 2 takedowns, which in practice is about 5-15 s. During `PokeController.firstMinute()` (until the 25 s fallback) the auto-equip waits on whenFree. All reward toasts wait for the newcomer reveal (~50 s), and then only the newest 2 survive the trim. The reward sound plays at once with no visual.

One Bat can produce all of these:
- "UNLOCKED: BAT! Find it in WEAPONS." (shown because onBar = false during the first minute);
- "Your BAT is on the bar. Try it!";
- "3 weapons unlocked! Tap WEAPONS";
- "New tool: Bat!" on first use.

The first two contradict each other: in WEAPONS, or on the bar? The project's own research spec says the first unlock should land at 5-30 s, with a quiet toast and auto-equip, and no window. *Evidence:* Toys.luau:207 (Bat unlockAt 2); ProgressUI.luau:624-648 (633 firstMinute, 636-640 whenFree toast, 645-647 UNLOCKED toast, 648 playSound); NotifyRules.luau:77-79; Notify.luau:102-118 (NOTIFY_REVEAL_KEEP trim); OnboardingController.luau:197, 544, 572; RESEARCH_FIRST_SESSION.md:186 *Fix:* Remove the first-minute tool lock. Auto-equip unlocks at once and pick them. Let one compact reward card (picture, "NEW: Bat", 1.5 s) through the newcomer quiet: add a "firstUnlock" kind to NotifyRules that is allowed during newcomerUntil. Delete the other three messages for auto-equipped unlocks, and play the sound together with the card.
- **[high/high/M] Machine objectives point off screen with the wrong guidance tool, and a stuck step never moves on.** The spawn faces -Z with the dummy arc ahead. The two machine goals are not in view:
- the cannon pad is at lab-local (48, 6), about 83 degrees to the right and slightly behind;
- the wrecking ball is at (40, -38), about 46 degrees right.

On the 414x814 portrait phones the data reports, the horizontal FOV is about 39 degrees (+-20), so neither machine is on screen. In landscape they sit at or past the edge.

The only guidance is an Occluded Highlight. The vault keeps Highlights for targets already in view, and says off-screen targets need a feet-to-target Beam or an edge arrow. There is no escalation if the player is stuck. Each step waits up to GIVE_UP 300 s and then the whole chain ends, so a player who never finds the cannon sees "Fire yourself from the CANNON" for up to 5 minutes and never reaches the later steps. *Evidence:* Lab.luau:142-148 (slotPosition arc ahead), 750 (spawn faces -Z); Playground.luau:157 (cannon x,z = 48,6), 273 (wrecking x,z = 40,-38), 739-742 (stations at z +52, behind the spawn); FirstVisit.luau:146-162 (Highlight, DepthMode Occluded), 309, 334-336 (GIVE_UP and break); vault 'Tutorial Step Design Patterns' section 3 (Beam for off-screen, Highlight for in view) *Fix:* When the target is off screen, show a screen-edge arrow and light the V7 path stones from the player's position to the target; the routes are already in PathPlan. Keep the Highlight only once the target is in view. Show a stuck hint after 20 s ("Follow the glowing path") and skip to the next step after 45 s. Also rotate the spawn (or move the cannon) so the cannon is in frame from the start in both orientations.
- **[high/high/M] The objective chain teaches self-launching and ends at a wall of locked cards.** The steps are: knock a dummy over, fire yourself from the CANNON, get hit by the WRECKING BALL, open WEAPONS.

The research's BRP badge funnel shows new players find machines with dummies: spike wall throw 66 %, barrel 55 %, wrecking ball 44 %, cannon 41 %. The research spec asked for "Put a dummy in the CANNON", and AUDIT.md lists this as still open.

On a phone, launching yourself means the player loses control and the camera spins. Grab, slot 2 and the genre's core verb (FTAP: the first grab within 10 s), is never taught. The last step opens a catalog where 66 of 69 cards are LOCKED, and then the line disappears with no next goal. The vault says steps should be verb + target + reward, with the big reward early; no step here has a reward. *Evidence:* FirstVisit.luau:43-48, 338-339 ("Nice!" only); RESEARCH_FIRST_SESSION.md:89, 153, 193; AUDIT.md:94; Toys.luau:290 (Grab on the start bar); vault 'Teardown - Fling Things and People' (first grab within 10 s) *Fix:* Make the chain 4 steps, each with an instant reward:
1. "Hit the dummy!": unlocks the Bat, equipped at once.
2. "Swing the BAT!": gives a takedown streak.
3. "Grab a dummy and throw it in the CANNON": the bullseye gives a slow-mo cam and a WOW crate.
4. "Throw the GRENADE!".

Then hand over to the persistent "Next: X a/b" goal instead of a menu step. Use only server signals for completion: CannonPad Touched by a dummy, Bullseye, and Takedowns.
- **[high/high/S] A second goal system with timers and unknown currencies starts during the first visit.** The Experiment card is dealt 40 s after PlayerAdded. It shows as soon as the 25 s first-minute lock ends: `shown()` checks `firstMinute`, not NewcomerUntil. Today's Daily Experiments are dealt first, so a newcomer can see "Let the MOLE pop a dummy 0/1 2:30" with a countdown and a stars/bolts reward while the top line says "Fire yourself from the CANNON".

Other competing goals arrive in the same window:
- the hazard tip "Jump in the LAVA or blast off the CANNON at the BULLSEYE!" (queued at ~41 s, shown after the reveal);
- the daily-dare toast "Goal done: X! Claim your egg in Rank & Eggs", which names a window hidden in MENU.

On a portrait phone the experiment slot (x 12-170, y 68-114) overlaps the FirstVisit pill (centred, y 48-88, up to the screen width minus 32). LayoutCheck never measures the pill. *Evidence:* ExperimentService.luau:266-272; ExperimentCard.luau:69-80; HudSlots.luau:167-172; FirstVisit.luau:98, 143; Experiments.luau:24-46 (deck, timers, MOLE/VACUUM cards); OnboardingController.luau:100-106; ProgressUI.luau:590-594; LayoutCheck.luau:223 (Experiment measured, pill not) *Fix:* No experiment card, hazard tip or dare toast until the FirstVisit chain is done or skipped. Make the first 3 experiments continue the chain, with no timer and no currency text, and add the pill to LayoutCheck.
- **[high/high/S] PLAUSIBLE: the greeter's route may be computed at the plaza spawn before the player is moved into their lab.** Code order:
- OnboardingService.start (Main.server.luau:61) connects PlayerAdded/CharacterAdded before Lab.build (:64).
- Its `spawned` handler calls `onSpawned` → `GreeterService.send` as soon as the HumanoidRootPart exists, with no yield on the server.
- Lab moves the avatar to the plot only in a `task.defer`.
- The SpawnLocation is hidden but not disabled, and it is the plaza centre.

So the greeter's start and stop points, and its Home, can be worked out from the plaza position, about 250 studs from the lab. T23 and T45 call `onSpawned` by hand after placement, so the real join path is never tested. If this happens live, the greeter walks up in the plaza, and the first 5 s target is missing in the lab. The AUDIT's Studio capture says the greeter came, so check it with a live log before trusting either result. *Evidence:* Main.server.luau:61, 64; OnboardingService.luau:304-313, 458-467; GreeterService.luau:121-148; Lab.luau:982-992 (SpawnLocation kept), 1023-1038 (task.defer placeOnPlot); T23_FirstSeconds.luau:71-74; T45_FirstMinute.luau:42-44 *Fix:* Send the greeter from Lab after placeOnPlot: an `Arrived` signal or player attribute, which GreeterService waits on with a 3 s cap. Or recompute the route when the root first stands inside the owned plot. Add a real-join test (LoadCharacter and wait) that asserts the greeter is within 24 studs of the root and inside the plot. Log the greeter-to-player distance in Session_v1.
- **[high/high/S] The 'most phones are upright' data may be a boot-time artefact, and the orientation is never set.** SessionClient takes one viewport reading within ~2 s of the client starting. SessionStats sets `portrait = h > w` from that. A phone on LandscapeSensor still reports portrait while it rotates out of the Roblox loading screen.

No code sets StarterGui.ScreenOrientation, so the place file decides; it is unknown whether the game is Sensor, Portrait or LandscapeSensor. A whole portrait HUD has been built on this number: PORTRAIT_TOAST_TOP, the thumb row, eventTop, the upright monitor. Every leader phone layout in the research is landscape. Real portrait play gives a ~39 degree horizontal FOV, which makes aiming and finding machines very hard. *Evidence:* SessionClient.luau:71-90; SessionStats.luau:184; grep: no ScreenOrientation anywhere in the synced code; HudSlots.luau:35-43, 282-306; RESEARCH_FIRST_SESSION.md:86, 117 *Fix:* 1. Read StarterGui.ScreenOrientation in Studio.
2. Sample the orientation again at 10 s, 30 s and 60 s, and store the dominant value plus `rotated`.
3. If players really play upright, either set LandscapeSensor (standard for action games, where the leaders are) or build a real portrait camera: wider FOV, further back, aim help on.
4. Re-read Session_v1 after one day before spending more on portrait layouts.
- **[high/high/M] The first verb is the weakest weapon, the dummies run from it, and the WOW weapons are hidden behind a late egg.** The starter Popper is speed 36, lift 0.2, chaos 0.3, wound 1. It takes about 6 body rounds to down a dummy, and with BLOOD off a hit shows only stars and sparks. Every shot within 30 studs makes all lab dummies except the Brave one flee for 2.6 s (zigzag and flail), so targets 2-6 run away from a new phone player.

The genre's first wow is the physical reaction (HRR's per-limb flops). The Bat (speed 70, lift 0.75) waits behind the 25 s lock. The WOW pool (Grenade, Rocket, C4, Minigun, TNT, RPG) only arrives through the auto egg at about reveal + 20 s or later. *Evidence:* Toys.luau:195, 207; Config.luau:186-196 (BODY_HP, DAMAGE_PER_POWER); Lab.luau:66-70, 487-517 (cowards flee every shot); ProgressService.luau:1038-1039; RESEARCH_FIRST_SESSION.md:71 *Fix:* Give a newcomer's first 3 takedowns an exaggerated payoff:
- a knock-down on the first hit, with a large impulse;
- a 0.25 s slow-mo plus a camera punch through FeelV2;
- a loud impact layer.

No flee until the 3rd takedown, or for a newcomer's first 60 s. Move the first WOW weapon to the 3rd-takedown crate (see the egg finding).
- **[high/high/M] The first full-screen pop-up is the auto egg, and it lands too late to be seen.** The server's firstEgg fires at 60 s. The client then waits on whenFree, then QUIET_START, then `Notify.waitBig` (newcomer reveal + NOTIFY_BIG_AFTER_REVEAL 20 s, and BIG_GAP 40 s after any other big pop-up such as the EggReady card). Only then does a darkened full-screen opening play. AUDIT.md measured the auto egg at 110 s and the egg card at 152 s, both after the median leave. Session data says almost nobody opens an egg. The research spec says the auto egg must not open as a full-screen card in 30-90 s. So the strongest first wow is both late and delivered as an interruption. *Evidence:* ProgressService.luau:1631-1666; ProgressUI.luau:604-622 (AutoEgg chain), 183-197 (overlay 0.35 dark); Notify.luau:206-224; NotifyRules.luau:39, 105-112; AUDIT.md:84-91; RESEARCH_FIRST_SESSION.md:196; task FRESH DATA ('almost nobody opens an egg') *Fix:* Deliver the first WOW weapon in the world and at once. After the 3rd takedown (~20-30 s) a crate drops 6 studs in front of the player. One hit opens it with a 2 s burst and no modal. The weapon goes on the bar already picked, and the objective becomes "Throw the GRENADE at them!". Keep the egg window for later eggs only. Log `crateOpened` and `firstBigWeaponFired` in Session_v1.
- **[medium/medium/M] Dead design: the first-replay unlock can never trigger, so the funnel measures a timer.** OnboardingController's first big moment needs `lastOwnBigToy`, which is set only for tools with `big = true`. The first-minute bar allows only Blaster, Grab and Punch, and none of them is big. So every newcomer is released by the 25 s UNLOCK_FALLBACK. That has these effects:
- Funnel step 4 "ReplayEnded" is always a timer, not a behaviour.
- The "Press F to ragdoll yourself!" tip, which is set only on that replay path, never fires for a newcomer. Self-ragdoll, the genre's other core verb, is taught only by the key chips at reveal + 15 s.
- The "3 weapons unlocked!" toast counts `starterCount()` = 3, the same 3 tools the player held from second 0. *Evidence:* OnboardingController.luau:234-254, 538-540, 243-249 (ragdoll tip), 551-576; Toys.luau:195-200, 290, 342-352; FxController.luau:354-358; OnboardingService.luau:30, 295-299 *Fix:* Delete the STARTERS lock, the first replay unlock and the fallback. Replace the funnel with behavioural steps: Joined, Spawned, FirstHit, FirstUnlockUsed, FirstGrab, FirstMachine, FirstBigWeapon, Min3, Min5. Add `onScreenAtLeave` (chase, egg, window, surprise, objective step) to Session_v1 so the next read says WHY people left. Teach ragdoll in context, the first time the player gets knocked down: "F / RAGDOLL to flop any time".
- **[medium/medium/S] The PC first screen is still cluttered, and the 'first minute <= 7 things' check is a hard-coded model.** From 0 s on PC a newcomer sees all of this:
- the HudV3 top row: the gift button and the Next pill (`held.Top` is never set by FirstVisit);
- the 132x120 WEAPONS square, which opens a catalog of locked cards while the bar is still locked;
- the bar with the ammo count, the crosshair, the help line, the hint, the objective pill and the pointer;
- Roblox's player list with Takedowns and Rank (leaderstats), and the default chat window, in a 6-player server.

LayoutCheck.firstMinuteNames counts from a hand-written list. It leaves out the pill, the touch hand, the pointer, the crosshair, the ammo, the stick and jump, and CoreGui. So the "6 things at most" row in AUDIT.md is not a measurement. *Evidence:* HudV3.luau:54-56, 394, 420-430; FirstVisit.luau:166-183 (holds Left/Right/Chips only); PokeController.luau:850-858, 1556; ProgressService.luau:835-846; LayoutCheck.luau:1044-1070; AUDIT.md:121; grep: no TextChatService or ChatWindowConfiguration setup *Fix:* During the newcomer quiet:
- turn off CoreGui PlayerList;
- set ChatWindowConfiguration.Enabled = false (the bubbles can stay);
- hold the gift button (`held.Top`);
- hide the WEAPONS square until the first unlock (its reveal is then the reward).

Make LayoutCheck count what is really visible from the live PlayerGui plus CoreGui flags, and keep the budget at 4 for 0-30 s.
- **[medium/medium/M] The first-wow UFO is code-built, mostly out of frame, and can knock the player mid-objective.** UfoBeam is built from primitives: a Cylinder disc, a Ball glass dome and neon ball lights. It hovers 40 studs above a point 25 studs ahead of the player, about 58 degrees above the eye line. That is out of frame on a portrait phone (vertical FOV 70) and at the top edge in landscape; only the beam reads. It yanks players (knockPlayers), and it fires from a 10 s server poll with no check on the client's objective step, so it can ragdoll a newcomer in the middle of a step. The V7 rules say nothing may look code-built. *Evidence:* Surprises.luau:126-176 (h = 40 at 128, 25 studs ahead at 142-147, knockPlayers at 172-175); EventService.luau:646-663; V7_PLAN.md:35 *Fix:* Tie the first wow to the player's own act: the first cannon or bullseye landing gets a slow-mo follow-cam, and the crate gives the first explosion. If a world event stays, use a real model and frame it with a 1 s camera tilt. Never knock the player during an active FirstVisit step, and gate it through the FirstSession director.
- **[medium/medium/S] The NPC chase hits newcomers at 100 s, right before the median leave.** 4-10 red chasers (4 on a phone) run in and punch the player for 4 HP every 0.9 s each, for up to 50 s. The FIRST_AFTER timer was pulled from 150 s down to 100 s to fit inside the median visit. The vault's genre rule is "first combat at full strength → a weak, owned first enemy". There is no evidence the chase keeps people. Session_v1 cannot tell whether a leave happened during a chase. *Evidence:* ChaseService.luau:30-42; Config.luau:19-22; RESEARCH_FIRST_SESSION.md:197, 254 *Fix:* No chase in a first visit before 5 min of play. Later, offer it as a choice ("They're coming! READY?"), starting with 2 slow chasers. Record `leftDuring = chase` and measure it before moving it earlier again.
- **[low/medium/S] Two definitions of 'new player' give a newcomer 'Welcome back!' in the middle of onboarding.** OnboardingService treats a player as returning once Onboarding_v1 has done = true. That is written at step 4, which the 25 s fallback always reaches. FirstVisit treats anyone under 300 s of total play as a newcomer (ProgressService). A player who left at 30 s on their first visit therefore gets:
- "Welcome back!", which is held as info until after the reveal and so shows about 50 s in;
- no starter lock;
- at the same time, the held HUD and the objective line. *Evidence:* OnboardingService.luau:117-119, 254-256, 478-483; ProgressService.luau:1736; OnboardingController.luau:592-606; NotifyRules.luau:77-82 *Fix:* Use one server source of truth: an attribute `FirstVisitStage` derived from playSeconds plus the furthest chain step. Show "Welcome back" only at 300 s or more played. Resume the chain at the furthest step instead of restarting it.
- **[medium/medium/M] Join to first frame on phones is unmeasured: default loader, lab built synchronously at claim.** There is no ReplicatedFirst loader; the default Roblox loading screen is used. A plot's whole lab (Playground, LabDress, LabZones, LabGarden, PathBuilder with about 360 path parts, LabCreatures and habitats) is built synchronously in PlayerAdded the first time anyone claims that plot. The client then streams it in while the player is already standing in it. The client boot starts about 60 modules in a row. The research lists "check join-to-control time on a phone" as open. SessionStats records `boot` but not when the lab was ready or when control began. *Evidence:* Lab.luau:756-772 (claim builds playground); Playground.luau:934-1036; Main.local.luau:45-125; RESEARCH_FIRST_SESSION.md:256; vault 'Loading Screen Skip and First-Session Goals' TL;DR *Fix:* 1. Pre-build all plots at server start, or build in idle frames before anyone claims them.
2. Add a small ReplicatedFirst loader that closes on "own lab streamed (RequestStreamAroundAsync at LabOrigin) + character placed", with an 8 s hard timeout.
3. Record `labReady` and `controlAt` in Session_v1, and have the owner time one real phone join.
- **[low/low/S] Lab signs are hidden by a one-time scan while the lab is still streaming in; NEW tags mean nothing to a newcomer.** FirstVisit hides ZoneSign billboards and TodayLight with a single GetDescendants pass, run when the server answers. Its own step code says the lab streams in and searches again for 15 s. Signs and NEW tags that stream in after the scan stay visible during the quiet. NEW tags (BigButton, LabCar, LabTruck, PortalMulti) are noise for someone to whom everything is new. *Evidence:* FirstVisit.luau:243-252 vs 284-299; LabZones.luau:102-103; Config.luau:183-185 *Fix:* Hide by tag on the client with a DescendantAdded listener for the whole quiet, or have LabZones skip NEW tags and the TODAY sign for an owner who is a Newcomer.
- **[low/low/S] Ammo and reload on the starter Popper add UI and a dead beat in minute 1.** The Popper has a 17-round magazine and a 1.3 s reload, with a "12 / 17" counter by the crosshair and on the slab. A newcomer hammering the greeter hits a reload pause in the first 10 s. On a phone that is one more counter competing for attention. BRP shows ammo only later in the session. *Evidence:* Ammo.luau:13; CLAUDE.md phase 2 notes (AmmoClient counter by the crosshair and on the slab); RESEARCH_FIRST_SESSION.md:85 *Fix:* Give the starter unlimited ammo, with no counter, in a newcomer's first 3 minutes. Introduce reload with the first unlocked real gun, and explain it with a single contextual hint the first time the magazine runs dry.
- **[low/low/S] Objective text and the done beat are flat.** The steps use shouting capitals ("CANNON", "WRECKING BALL", "WEAPONS"), which goes against V7-5's "no all-caps shouting". The pill uses Builder Sans 20 rather than the UI_V2 display face. Gamepad text appends a bracketed "(R2)" instead of a glyph. The done beat is a bare "✓ Nice!" for 1.4 s, with no reward, sound or progress shown. *Evidence:* FirstVisit.luau:43-48, 103-104, 338-339; V7_PLAN.md:152-160 *Fix:* Each line is an icon plus a verb plus a target in title case, at 8 words or fewer, with a real glyph image. On completion, show a tick, a reward chip ("+ Bat") and a small progress dot row (1 of 4), and play the kit's reward sound.

**Cut or hide:** OnboardingController's bottom hint for newcomers ("Click/Tap the dummy to shoot!", "Now try another tool!"): it repeats the objective line; The PC help line under the bar during the first visit; The TouchShoot "TAP A DUMMY!" hand while the greeter pointer is shown (one pointer only); later it should say SHOOT, not tap; The whole first-minute tool lock: STARTERS, UNLOCK_FALLBACK 25 s, the first-replay unlock and the "3 weapons unlocked!" toast, which announces the 3 tools the player already had; Duplicate unlock toasts: "UNLOCKED: X! Find it in WEAPONS" when X was auto-equipped, and "New tool: X!" on first use; Experiment cards (timer, stars, bolts, daily MOLE/VACUUM cards), daily-dare toasts and the hazard tip until the first-visit chain is done; The "Open WEAPONS for more" step (it ends onboarding on a wall of 66 locked cards); The first-wow UFO made of primitives, and any world event or surprise before 3 min; The NPC chase in a first visit before 5 min; The full-screen auto-egg modal as the first WOW weapon (replace it with an in-world crate); NEW tags and the TODAY'S MACHINE sign for newcomers; The HudV3 gift button, and the PC NextUnlocks cards in the first 3 min (the Next pill already shows the goal); Roblox's player list (Takedowns/Rank) and the chat window during the newcomer quiet; The ammo counter and reload on the starter in the first 3 min; "Welcome back!" for anyone under NEWCOMER_SECONDS; Bolts, stars, the bone journal, the play-gift clock, the level badge and rank toasts in the first 3 minutes (one number only: takedowns towards the next weapon); The OnboardingController view-card code path (VIEW_CARD is false; about 200 lines of dead UI that still adds timers)

### B-core-feel: shooting, hitting, ragdoll physics, knockdowns, hit feedback, slow-mo, hit sound, camera, X-ray replay, takedown counting: 4/10
The technology underneath is good: the client simulates its own lab dummies and predicts hits on them, the active-ragdoll states work (flinch, stumble, ragdoll, out cold, crawl, get up), every gun has its own sound, and there are trauma shake, trails and casings. But a new player mostly uses the Popper on a phone held upright with blood off, and what they actually feel is weak and partly broken:
- **Weak hit:** a body shot makes the dummy drop like a sack (about 9 studs/s), with no particle burst, no shake and no hit-stop. The only impact signs are a "flesh" sound, a dark hole and a tracer.
- **Late feedback:** the hit X and the "+1 TAKEDOWN" both wait for a server round-trip, and the takedown can wait up to 0.8 s more for a retry.
- **Takedowns go quiet:** after 120 s nothing celebrates a takedown, and the combo is not shown at all. FeelBus "Combo" has no listener.
- **Narrow portrait view:** the upright-phone camera sees about 39° across.
- **Camera drift:** recoil and shake are written into Camera.CFrame after Roblox's camera has run and are never undone, so the view should climb with every shot.
- **Three slow-mo systems:** they overlap, and the automatic one can cut the biggest launches.
- **Replay misses the player:** the X-ray replay never records the player, yet it records every dummy at 30 Hz all the time.
- **Never felt live:** Config.luau:118 says Feel v2 was never play-tested, and AUDIT.md rates area 2 "6 (unmeasured)".

Against Hyper Realistic Ragdoll (location-based limp and crawl, slow motion the player controls, KO tracking, over-the-shoulder aim), the moment-to-moment loop is clearly behind. This is not a 6.

**10/10 means:** A 10/10 core feel for Ragdoll Havoc in 2026 (Hyper Realistic Ragdoll / Bloody Ragdoll Physics bar, kid-safe):

1. **Every input answers in the same frame on the shooter's screen.**
   - Shot sound in 50 ms or less.
   - Muzzle flash and tracer.
   - A client-predicted hit X with a dry "tick".
   - The dummy reacts at once (already true for your own lab).
   - The takedown pop comes from the local ragdoll state change, not from the server.
2. **Every hit is readable without blood.** On the struck part:
   - a white/yellow impact puff (6-10 pooled particles) and a 60 ms white flash;
   - a mannequin "thwack/crack" sound, not flesh;
   - a visible stagger-back of about 20 studs/s on a chest shot, the leg buckling on a leg shot, the head snapping back on a head shot;
   - big guns and melee launch with tumbling and speed trails.
3. **Real hit-stop.** The struck body freezes for 66-80 ms and only then takes its impulse, together with the attacker's contact pose. The camera never freezes. The whole thing is budgeted.
4. **The knockdown is a reward event every time.**
   - A short KO sting whose pitch rises with the combo.
   - The counter ticks on the Next pill.
   - From 2 takedowns in a row, a small "x2 / x3 COMBO" stamp by the crosshair.
   - Every 5th takedown gets a slow-mo beat that is visibly tied to "x5 COMBO!".
   - One word everywhere: KO (no kills, takedowns and KO mixed).
5. **The camera fits the device.**
   - Upright phone: pulled back and wider, so at least 55° across.
   - PC with a gun: over the shoulder with the mouse locked while aiming; Alt frees the cursor.
   - Shake and recoil are removed before Roblox's camera runs each frame, so the view never drifts.
6. **One slow-mo system.**
   - Player-controlled (Z / button, like HRR's "slow down time to watch every hit").
   - Plus a rare automatic beat on the biggest launch the player can see.
   - It never takes speed away from a body.
7. **Replay on demand.**
   - One tap on the KO pop replays the last 3 s at 0.3x.
   - It includes the player's own body (the cannon ride).
   - It records only while something big happens, and costs nothing when idle on a phone.
   - Nothing is forced, and no share codes to type.
8. **Targets stay targetable.**
   - At most 2 dummies flee at once, briefly and slower than the player.
   - Two brave ones always stand in front of the player.
   - Aim assist goes to the torso; a head shot stays a skill reward.
9. **Proof on a real portrait phone and on PC.**
   - A 60 fps capture of 10 scripted moments.
   - Measured input-to-visual and input-to-sound latency.
   - A blind A/B feel test against HRR.
   - A Session_v1 rise in shots per minute and in the share who reach 5 min.

- **[critical/high/M] The starter Popper's hit on a body has almost no visible impact (blood off left a feedback hole).** The most-used action in the game (Popper into a dummy, mostly on phones) has nearly nothing at the point of impact:
- With Config.BLOOD 'off', a gun hit returns early from onFx into roundInBody. It never calls impact(), so there are no FeelV2 particles, no trauma and no BigHit.
- roundInBody plays a flesh sound, sticks a dark hole and draws the tracer. BloodFx.wound returns at once because Stylised is on.
- The push is HitMath.gunPush = 6+6*wound = 12 studs/s, times BODY_SHARE.Ragdoll 0.75, so about 9 studs/s: the dummy just folds where it stands.

HRR, RR and RDP are rated Moderate and use blood and limb damage as their feedback. The mild pivot removed that and put nothing in its place. *Evidence:* - Config.luau:34 (BLOOD = "off").
- FxController.luau:1145-1149 (gun -> roundInBody, return), 911-937 (roundInBody), 996-1029 (impact(), never reached by guns).
- BloodFx.luau:380-382 (wound gated by enabled()).
- HitMath.luau:22-24 (gunPush).
- ActiveRagdoll.luau:119 (BODY_SHARE), 1707 (GUN_FELLS 0.9: one Popper round fells).
- RESEARCH_FIRST_SESSION.md:27-37 (leaders' maturity labels). *Fix:* Add a kid-safe 'round' impact layer for every gun hit on a body:
- FeelV2.impact(kind 'Round'): 6-10 white/yellow pooled particles and a 1-frame spark.
- A 60 ms white Highlight flash on the struck part (pooled, one Highlight per screen).
- A dry mannequin 'thwack' sound layered under the shot.
- Small trauma only on big guns.

Raise the reaction so it reads at phone distance:
- gunPush for chest/stomach to about 18-22 studs/s along the shot, plus a small lift, so the body visibly staggers back before it falls;
- head shots snap the head back (a local impulse on the Head);
- leg shots keep the buckle.

Capture before and after on a portrait phone.
- **[critical/high/M] Upright phones (the biggest group) get a 39-degree tunnel view.** Session_v1 shows most players on upright phones (414x814). No client file changes the camera for portrait:
- FxController keeps Roblox's default vertical field of view (70) as baseFov.
- No zoom distance or camera offset changes for portrait.
- At an aspect of 0.51 that is about 39 degrees across. A dummy 4 studs to the side at 10 studs' distance is off screen.

Add fleeing dummies and a 9-stud melee reach, and the core loop becomes hunting for targets through a slot. *Evidence:* - FxController.luau:1275-1277 (baseFov = camera.FieldOfView; only kicks, sprint and zoom are added).
- grep: 'portrait' appears only in HUD modules (HudSlots, Toast, PokeController, LayoutCheck), never in camera code.
- Task data: most visits on 414x814 portrait. *Fix:* Add a portrait camera profile to the single FOV writer (FxController onRender):
- Upright phone:
  - vertical field of view about 85, so the view is at least 55 degrees across;
  - CameraMinZoomDistance about 14 and the default zoom about 16;
  - a slight downward pitch bias, so the floor and the dummies fill the frame.
- Landscape: unchanged.
- Re-apply on rotation.
- Check with the in-game LayoutCheck captures and the portrait median visit in Session_v1.
- **[high/high/S] The hit X and the takedown pop wait for the server; the takedown can be ~1 s late.** Feedback waits for the network even though the client already knows the result:
- Crosshair.hit only runs on the server's HitInfo event. On a phone at 150-250 ms ping the X appears after the body has already dropped.
- '+1 TAKEDOWN' only runs on the server's 'Combo' event.
- ProgressService.onDown can retry after DOWN_RETRY 0.8 s when the client's state report arrives before the hit stamp.

The client simulates its own lab dummies and changes their state on the very frame of the hit, so it could show both at once. There is also no hit-confirm sound at all. Late, silent confirmation is the main reason hits feel 'floaty'; see the vault note 'Feedback Timing - Sound Visual and Haptic Sync'. *Evidence:* - Crosshair.luau:337-344 (hit mark only from Net HitInfo), 186-229.
- ProgressUI.luau:597-604 (pop only from server Combo).
- ProgressService.luau:916, 943-947 (DOWN_RETRY).
- PokeController.luau:1452-1458 (the client already applies the hit to its own simulated dummy). *Fix:* Show both from the client:
- **Hit X:** in PokeController.land, call Crosshair.hit(headZone, false) from the local raycast result. Let the server's HitInfo upgrade it to the kill mark only.
- **Takedown pop:** for bodies with SimulatedBy == me, fire the pop when the local RagdollState goes to Ragdoll/Out after our own hit (the same rules as the server: a 3 s cooldown per body).
- The server stays the source of truth for the count. A missed +1 is harmless.
- **Sound:** add a 30 ms 'tick' hit-confirm sound (UI group) and a deeper 'tock' for a KO.
- **[high/high/S] Takedowns are invisible after 120 s and silent; the combo is never shown, but its slow-mo beat fires.** After the first two minutes a takedown has no feedback of its own:
- The '+1 TAKEDOWN' pop only shows in the first POP_FOR 120 s, and it is silent.
- The combo is hidden on purpose (round-2 owner wish).
- FeelBus fires Combo/Launch/Land, but only SlowMotion (BigHit) and the now-disabled Birds listen. No UI shows a combo.

Yet at combo 5 FeelV2.slowmoBeat drains the colour, pulls the FOV in and plays a whoosh. The player gets a strange screen effect with no reason given.

The leaders make KOs the reward currency: HRR has a 'Next' tracker by KOs, and its '10 kill streak' badge has 787k earners. *Evidence:* - ProgressUI.luau:598-604, 682 (POP_FOR 120).
- FeelV2.luau:548-588 (slowmoBeat), 622-635.
- Config.luau:243 (COMBO_SLOWMO 5).
- FeelBus.luau:4-13 vs grep FeelBus.on: only Birds.luau:493/498 and SlowMotion.luau:352.
- ProgressService.luau:983-999 (combo computed and sent).
- RESEARCH_FIRST_SESSION.md (HRR streak badge). *Fix:* Every takedown gets:
- a 0.3 s KO sting (one sound, pitch up per combo step);
- a tick-up on the Next pill (HudV3);
- a small 'KO' stamp by the crosshair (reuse Crosshair's KO label).

From combo 2, a compact 'x2 COMBO' counter by the crosshair that fades 3 s after the last takedown. At combo 5 the slow-mo beat comes with a visible 'x5 COMBO!' stamp, or the beat is cut.

The pop stays small (the owner's 'quiet HUD'), but it never disappears.
- **[high/medium/S] Camera shake and recoil drift the player camera permanently (offset never undone).** FeelV2.cameraStep returns a rotation (noise shake plus a pitch-up kick), and FxController multiplies it into camera.CFrame at RenderPriority.Camera+1. Nothing removes it before the next frame.

Roblox's ClassicCamera builds each frame from workspace.CurrentCamera.CFrame.LookVector, so every applied offset gets baked into the next frame.
- The recoil kick is always upward and lasts about 3-4 frames. That adds up to roughly 1-1.5 degrees of permanent upward pitch per Popper shot.
- Holding SHOOT on a phone (10 rounds/s, centre crosshair) makes the aim climb about 10 degrees per second.
- The noise shake random-walks the view.

LabCamera is not affected (it keeps its own yaw/pitch). PLAUSIBLE: needs a Studio check (fire 17 rounds and log the camera pitch). *Evidence:* - FeelV2.luau:96-114 (cameraStep, the kick added to pitch).
- FxController.luau:1253-1263 (camera.CFrame = camera.CFrame * offset), 1487 (bound at Camera+1).
- grep: no Camera.Value-1 step that reverts it.
- TouchShoot.luau:79-94 (hold fires at cooldown).
- Roblox PlayerModule BaseCamera:GetCameraLookVector reads CurrentCamera.CFrame. *Fix:* Store the offset applied this frame. Bind a step at RenderPriority.Camera.Value-1 that multiplies camera.CFrame by its inverse before the PlayerModule runs. Alternatively, apply recoil to the aim (GunFeel.aim) and shake through Humanoid.CameraOffset only.

Add a self-test: 20 kicks, then the camera pitch is unchanged within 0.5 degrees.
- **[medium/medium/M] Hit-stop freezes only the camera while the struck body flies on; the medium stop is below the phone floor.** FxController.hitStop holds camera.CFrame for the stop. Problems:
- The struck ragdoll is never held, so the target keeps moving while the view stands still. On a third-person camera that reads as a frame hitch, not as impact.
- It is skipped entirely while walking.
- The melee medium tier is 50 ms (HitFeel TIERS). The vault, and FeelTuning's own stop rule, say 66 ms or more on phones, because 50 ms is 1-2 frames at 30 fps.
- Gun hits never get one, which is right. *Evidence:* - FxController.luau:1370-1416 (takeHitStop / hitStop: camera only), 1489-1501.
- HitFeel.luau:21-26 (TIERS 20->0, 45->0.05).
- FeelTuning.luau stop() (0.03+0.045*s, heavy only).
- Vault '47 Game Feel and Juice/Hit-Stop and Screen Shake Tuning by Numbers' TL;DR. *Fix:* Make it a real hit-stop on the simulating client:
- On a melee or big hit, zero the struck body's part velocities and hold them for the stop (66-80 ms).
- Then apply the impulse (PokeController.land already knows the stop length).
- Keep the attacker's contact pose (AvatarMoves), and drop the camera freeze.
- Raise the medium tier to 0.066 and keep the budget.
- **[medium/medium/M] Three overlapping slow-mo systems; the automatic one can take speed away from the biggest launches.** Slow-mo is spread over:
- SlowMotion bubbles: velocity damping per assembly root, with grade, blur, vignette, pitch, a heartbeat and trails;
- the FeelV2 combo beat (colour and FOV only);
- the replay at 0.3x;
- the Slowmo spell, plus Z / LAB SLOW-MO.

The problems:
- **Launches lose speed:** on the way out, speed is restored only up to RESTORE_MAX 90 studs/s. The auto bubble triggers exactly on BigHit at strength 0.95 or more (speed 85.5 or more), so the biggest launches can come out slower than they went in.
- **Jelly limbs:** each ragdoll part is scaled as its own assembly root, while the joint and balance constraints still solve at full strength. Expect stretched, jelly limbs (PLAUSIBLE; Feel v2 was never play-tested).
- **Two writers:** SlowMotion and FeelV2 both write FeelV2.fovBeat. *Evidence:* - SlowMotion.luau:39 (RESTORE_MAX 90), 44 (AUTO_STRENGTH), 168 (fovBeat write), 228-288 (stepBodies), 352-361 (auto on BigHit).
- FeelV2.luau:548-588 (second fovBeat writer).
- ReplayController.luau:23 (SPEED 0.3).
- Config.luau:118, 150-152.
- HRR's store listing: 'slow down time to watch every hit' (player-controlled). *Fix:* Merge into one SlowMo service with one FOV and grade writer:
- the player's own Z / button, like HRR;
- one automatic beat for a big launch the player can see, at most once every 15 s.

On the way out, restore the body's real velocity (stored entry velocity plus the scaled change since) with no 90 cap. Test it on a real ragdoll in Studio and capture old vs new.
- **[medium/medium/M] X-ray replay never shows the player's own flight and records all the time.** Two problems, plus a cutscene risk:
- **Player missing:** ReplayController records only Workspace.Dummies and Props. The human cannon ('CannonPad' counts as a big moment) can offer a replay in which the player is not there at all. Meanwhile the live world keeps running behind the slowed copies.
- **Constant cost:** it samples every part of every dummy and prop within 120 studs at 30 Hz, calls GetDescendants for each source on every sample and builds a fresh table per frame, keeping 8 s. That is constant work and garbage on phones for a feature that is rarely used.
- **Forced cutscene:** the first replay plays by itself for about 6.7 s ((0.3+1.7)/0.3) when the first big tool lands while the first-toy stage is still on. *Evidence:* - ReplayController.luau:20-25, 91-106 (sources = Dummies + Props), 121-148 (record every Heartbeat at 30 Hz), 308-483.
- FxController.luau:354-358 (CannonPad is big), 1074-1078.
- OnboardingController.luau:184-200, 234-253.
- FirstVisit step 'Fire yourself from the CANNON' (AUDIT.md area 1). *Fix:* - Record into a preallocated ring buffer at 15 Hz, only for bodies on screen, including the local character.
- Start recording only around a big moment (FeelBus BigHit/Launch), not continuously.
- Never force a replay; offer it as one tap on the KO pop.
- Measure the client memory and frame time with it on vs off on a phone tier.
- **[medium/medium/S] The gun audio says 'real firearm and flesh' while the names say 'toy'.** The audio and the names pull in opposite directions:
- TOY_NAMES calls the G17 the 'Popper: Quick little pops'.
- It fires a 'Glock 9mm Shot Close' recording at volume 0.9, heard 400 studs away.
- Every body hit plays 'flesh_impact_bullet' / 'bullet-body-hit' sounds.

On white mannequins with blood off, a realistic flesh squelch is gore told through sound, which fights the kid-safe aim. The tone is also confusing: toy, mannequin and real-gun sounds are all at once. *Evidence:* - Toys.luau:112 (Popper rename), 195.
- SoundManifest.luau:211-216 (flesh bank), 254-257 (Blaster: g17 at 0.9, maxDistance 400).
- FxController.luau:916-917 (flesh on every body round).
- Config.luau:34-38 (mild switches). *Fix:* The owner picks one tone:
- (a) **Toy blaster:** layered punchy 'pop' shots and a rubbery 'thwack' on the body.
- (b) **Real-gun shots kept:** replace the flesh bank with a dry 'mannequin knock' (plastic crack plus a low thump).

The recommendation is (b), close to HRR. Put the result through one listening pass on a phone.
- **[medium/low/S] Dark wound holes stay on bodies even with blood off; red is the default hit-mark colour.** Every gun hit on a body leaves a mark that stays:
- BulletHoles.body always runs from roundInBody. It welds a BLOOD_DARK disc to the limb, up to 8 per body, kept until the body is patched up or gone.
- The crosshair's head mark and kill mark are red.
- Dead bodies are painted green for 10 s.

The vault's gore note says that for a Mild/Minimal target: no wound decals, no persistent marks on characters, and avoid red as the default hit colour. This is a content-label risk and does not help the feel. *Evidence:* - FxController.luau:913-914.
- BulletHoles.luau:2-5, 22 (MAX_PER_BODY 8), 27 (BODY_HOLE = Anatomy.BLOOD_DARK), 194-240.
- Crosshair.luau:48 (MARK_RED), 194.
- VitalsService.luau:623-668 (DEAD_GREEN 10 s).
- Vault '07 Lighting VFX and Audio/Gore Policy and Kid-Friendly Hit Feedback'. *Fix:* When BLOOD is 'off':
- no body holes; use a 0.3 s white scuff flash instead (world holes can stay);
- yellow/white hit and kill marks;
- replace the 10 s green corpse with a dizzy-stars out-cold that ends in a pop-up.
- **[medium/medium/S] Weapon cards promise severed limbs that never happen.** The WEAPONS cards show blurbs that promise cuts:
- Axe 'Chop. It can take a limb off';
- Katana 'One clean cut. Limbs fly';
- Chainsaw 'BRRRRR. Nothing stays attached';
- the Shotgun's text also promises it when TOY_NAMES is off.

But Config.SEVERING is false. A player who grinds to rung 150, 400 or 700 for the promised moment gets an ordinary hit. That is a broken promise at the exact moment of reward, and the text itself is a label risk. The blades also lost their whole identity with severing and got no new signature move. *Evidence:* - Toys.luau:251, 253-255 (blurbs).
- ToolCatalog.luau:717 (blurb shown on the card).
- Config.luau:15 (SEVERING = false). *Fix:* Add mild blurbs when SEVERING is false, the same way TOY_NAMES does it ('Chop! Sends them spinning').

Give each blade a signature physical effect that replaces the cut, all through ActiveRagdoll.hit:
- Katana: a spin launch;
- Axe: a heavy knock to the floor with a bounce;
- Chainsaw: a continuous shove plus sparks.
- **[medium/high/S] Every shot scatters the lab's dummies at nearly the player's speed.** Lab.heard makes every non-Brave, non-greeter lab dummy run for 2.6-3.4 s after any Shot. The trigger repeats every 5 s, the dummies zigzag at FLEE_SPEED 15 studs/s (the player walks at 16), and on phones the view is 39 degrees across.

With the starting Punch's 9-stud melee reach, targets leave the frame or get out of reach right after the first shot. The research itself lists 'dummies fleeing out of reach' as a Must-NOT. *Evidence:* - Lab.luau:66-67 (SCARE_TIME 2.6, SCARE_REST 5), 493-520.
- Ragdoll/Config.luau:28 (FLEE_SPEED 15).
- HitFeel.luau:10 (MELEE_REACH 9).
- RESEARCH_FIRST_SESSION.md:187. *Fix:* Scare only the dummy that was hit or aimed at (within 6 studs of the round), never the whole lab.
- SCARE_TIME 1.2 s at 9 studs/s, in an arc that stays in front of the player.
- At most 2 fleeing at once.
- Keep 2 brave dummies standing within 12 studs in front of the player.
- **[low/medium/S] Phone aim help snaps to the head, so instant kills empty the lab.** The touch aim help can pick the Head, and a gun round to the head kills at once. A dead body then lies green for 10 s and wakes for 3 s more.

A phone tap above a dummy turns into a head shot, which takes that target out of play for about 13 s, against about 3 s for a normal knock-down. In a 6-dummy lab, a run of head shots leaves nothing standing, which kills the chaining loop. The skill reward (head shot) is handed out by the aim help instead. *Evidence:* - PokeController.luau:1205-1241 (ASSIST_PARTS includes Head).
- VitalsService.luau:485-489 (HEADSHOT), 623-668 (REVIVE_AFTER 10, WAKE_SLOW 3). *Fix:* Aim help targets UpperTorso/LowerTorso only. A head shot needs a real tap on the Head.

Optionally shorten the dead time to 5 s in a newcomer's first 5 minutes.
- **[medium/medium/M] PC aiming uses a free cursor with no over-the-shoulder view.** Mouse lock is turned off (Shift is sprint). The player view is Roblox's classic camera with a free cursor: you aim with the pointer and must hold the right mouse button to turn.

HRR plays third person over the shoulder, and BRP uses Alt to free the mouse. With a gun this feels like clicking on a screenshot, not shooting. *Evidence:* - Main.server.luau:7 (EnableMouseLockOption = false).
- Crosshair.luau:271-283 (free mouse crosshair).
- RESEARCH_FIRST_SESSION.md:74, 91 (HRR over the shoulder; BRP 'Alt frees the mouse'). *Fix:* When a gun is picked on PC:
- lock the mouse to the centre, with a shoulder CameraOffset of about (1.8, 0.6, 0) and smooth turning;
- the crosshair sits at the centre;
- Alt frees the cursor for the UI;
- melee and the lab view stay as they are.

This is a custom lock, so Shift stays sprint. Test it with a hold-to-fire gun.
- **[low/medium/S] Your own shot may be heard up to 350 ms late; everything is preloaded at once.** Two sound-timing problems:
- LOAD_WAIT_OWN 0.35 s lets your own shot play up to 350 ms late ('heard a little late beats silence').
- On a phone, POOL is 1 voice per asset, and every bank goes into one big PreloadAsync. The starter guns are queued first, but in the same call as everything else.

The vault: a sound that lands late makes a hit feel floaty, and a sound that arrives after the visual reads as lag. *Evidence:* - FxController.luau:47-51 (PHONE, POOL, LOAD_WAIT, LOAD_WAIT_OWN), 1437-1481 (preload all banks).
- Vault '47 Game Feel and Juice/Feedback Timing - Sound Visual and Haptic Sync'. *Fix:* Preload the start-bar guns, hit, land and the KO sting first, in their own PreloadAsync, and enable firing only once those are in or after 2 s.

Cap the wait for your own shot at 0.1 s; past that, play a tiny fallback click. Load the other banks lazily.
- **[low/low/S] Shove and Slap promise a fall; the physics gives a stumble.** Shove's blurb says 'A good push. Down they go', but its speed is 22, under STUMBLE_MAX 30, so the dummy only stumbles and may recover. Slap at 15 is the same.

These are the rung 6/7 unlocks, the first new verbs a player gets. When the text says 'down they go' and the dummy stays up, the reward lands flat. *Evidence:* - Toys.luau:198-199 (Slap 15, Shove 22).
- ActiveRagdoll.luau:106-107 (FLINCH_MAX 10, STUMBLE_MAX 30), 1814-1820. *Fix:* Give Shove speed 34 with lift 0.2, so it always tips into Ragdoll and slides. Slap gets a visible spin (an angular impulse on the head and chest) instead of a weak push. Re-check that both count as a takedown.
- **[high/high/M] Feel was never measured on a device; there is no feel test at all.** The flags are all on but nobody has felt them live:
- FEEL_V2 and SLOWMO_V2 are on, while Config itself says nothing of Feel v2 was play-tested.
- AUDIT.md rates core feel '6 (unmeasured)' because feel cannot be judged over MCP.
- No test checks input-to-sound or input-to-visual latency.
- No capture compares the feel with the leader.

Every tuning number in FeelTuning, HitFeel and SlowMotion is a guess. *Evidence:* - Config.luau:118, 130, 150.
- docs/AUDIT.md scorecard row 2.
- FeelTuning.luau (all numbers unvalidated). *Fix:* Run a feel protocol once per release:
- A 60 fps capture of 10 scripted moments (Popper chest/leg/head, Punch, Bat, TNT, cannon, combo 5, Z slow-mo, replay) on PC and on a real portrait phone.
- Count frames from input to visual and from input to sound (target: visual within 1 frame, sound within 50 ms).
- A blind A/B with 3-5 players against HRR's opening minute.
- Track Session_v1 shots/min and the share reaching 5 min per build.
- **[low/medium/S] Ammo and reload break the starter loop on phones.** The Popper's magazine runs out fast on a phone:
- It holds 17 rounds and reloads in 1.3 s.
- On a phone, holding SHOOT fires the semi-auto Popper at its 0.1 s cooldown, so 17 rounds are gone in 1.7 s, followed by a 1.3 s dead gap: about 43% of the time is spent reloading under a held finger.
- A '12 / 17' counter sits by the crosshair from the first second.

In a no-stakes sandbox where the first minute decides retention, this is friction and clutter. BRP has a reload button, but its starter is melee. *Evidence:* - Ammo.luau:13 (Blaster mag 17, reload 1.3).
- Toys.luau:195 (cooldown 0.1).
- TouchShoot.luau:79-94 (hold fires semi-autos at cooldown).
- HitService.luau:420-424 (server refuses on Reload). *Fix:* - The Popper gets no magazine (Ammo.SPECS without Blaster), or ammo stays off in a newcomer's first 5 minutes.
- Holding SHOOT on a semi-auto fires at about 4/s, not 10/s.
- Magazines and reloads stay as identity on the big guns (Revolver, DoubleBarrel, Sniper, Railgun).

**Cut or hide:** - The combo slow-mo colour beat (FeelV2.slowmoBeat at COMBO_SLOWMO 5) as long as no combo is shown: either show 'x5 COMBO!' with it or cut it (FeelV2.luau:548-588).; - The Replay button that pops up top-right for 6 s after big hits, every 20 s (OnboardingController.luau:205-229), and the forced first replay (OnboardingController.luau:234-249): replace both with one tap on the KO pop.; - The SHARE CODE pill in the replay overlay, and the 'beat a friend's code' typing loop (ReplayController.luau:408-432, Shared/ShareCode): nobody types 6-letter codes on an upright phone.; - The HitInfo card: 6 s of two lines under the crosshair (HitInfo.luau:52 HOLD 6). Shrink it to one big region word for 1.2 s ('HEAD!', 'LEG!'), and keep the detail only in doctor mode.; - Mixed words for the one reward: 'kills' (HudPlus.luau:207, ToolCatalog.luau:116), 'takedowns' (ProgressUI pop) and 'KO!' (Crosshair). Use KO everywhere; 'kills' also fights the kid-safe label.; - Dark wound holes on bodies and the 10 s green corpse when BLOOD is 'off' (BulletHoles.luau:194-240, VitalsService.luau:623-668).; - The '12 / 17' ammo counter by the crosshair for the starter Popper.; - Whole-lab scatter on every gunshot (Lab.luau:493-520).; - The legacy per-frame random-jitter shake path, which never runs under FEEL_V2 (FxController.luau:1265-1273), and the duplicate 'Land' branch (FxController.luau:1179-1187 vs 1213-1220).; - Three of the four slow-mo entry points (Slowmo spell, auto bubble, combo beat, Z key): keep the Z/button slow-mo plus one rare automatic beat.; - Unheard FeelBus events (Combo, Launch, Land) with no listener now that Birds are off: wire them to the KO/combo UI or remove them.; Research sources used: [HRR beginner's guide](https://progameguides.com/roblox/complete-hyper-realistic-ragdoll-beginners-guide-roblox/), [allthings.how HRR guide](https://allthings.how/?p=356463), [allthings.how](https://allthings.how/?p=358267), [Top 5 ragdoll games](https://progameguides.com/roblox/top-5-ragdoll-physics-games-on-roblox/), plus docs/RESEARCH_FIRST_SESSION.md and the vault notes 'Gore Policy and Kid-Friendly Hit Feedback', 'Hit-Stop and Screen Shake Tuning by Numbers' and 'Feedback Timing - Sound Visual and Haptic Sync'.

### C - Goals and progression (experiments/missions, weapon ladder, eggs, bolts, level/rank, daily goals, calendar, journal, play gifts, trials, unlock pace, minute 5/15/60): 3/10
There is plenty of system: about 15 overlapping goal and reward layers spread over 3 windows. But the player feels almost none of it as "one clear next thing worth doing". On the majority platform (upright phone) no next-weapon goal is visible: the WEAPONS button is hidden and the next-weapon cards are off for touch phones. A newcomer's first mission is a random daily card. In 62 % of cases that card asks them to carry a dummy to a creature, open an egg they don't have, travel to a map, or score 25 takedowns, and it runs next to FirstVisit's own objective line. Mission cards time out without a word. Takedowns 3-8 auto-equip and auto-select downgrades (Poke, Shove, Slap, Heal). By takedown 10 the bar is full of them, so the advertised first big bang (Grenade) is not put on the bar. BOLTS have no counter on screen, and their only use buys weapons a takedown away. The day-2 and day-7 calendar weapons (AK, Minigun) are already owned by the players who come back. Eggs come every 75 takedowns, against a median of about 4 takedowns per visit. Stars, level, rank, takedowns, bolts and eggs all count the same play. Nothing is measured per mission or per unlock. The leaders do this with one tracker (HRR "Next: X a/b", BRP's WEAPONS kill bar) and one mission card (RDP), and do it better. The code quality is fine. The design is fragmented and partly self-defeating.

**10/10 means:** THREE LAYERS, ONE SCREEN SLOT EACH, IDENTICAL ON PHONE-PORTRAIT / PC / CONSOLE:
(1) NOW: one mission card (icon, at most 24 characters of text, a bar that fills smoothly, a BOLTS reward chip). No timer on solo missions, auto-claim with a short pop, no silent failure. The first 8 missions are a fixed chain: knock 1 over, cannon, bullseye, equip your new gun, feed the spider, wrecking ball, 10 takedowns, open the journal. After that the deal is procedural and scaled to the player's stage. The daily missions are the same cards with a DAILY tag.
(2) SESSION: a "Next: Grenade 3/5" tracker from 0 s on every device. A curated ladder of about 32-36 distinct tools on a sawtooth curve (3, 8, 15, 25, 40, 60, 85, 115, 150, 200...). Every rung is a real upgrade and never replaces the held weapon with a weaker one. Every unlock is a 1.5 s non-blocking reveal (turning model + EQUIP chip). An always-visible BOLTS counter that starts at 0 and counts up (RDP). BOLTS buy any locked weapon 5 or more rungs away, priced by rung, and cosmetics (hats, trails, dummy skins), so there is a sink after the ladder.
(3) RETURN: one REWARDS button holding a 7-day streak with a grace day and an exclusive day-7 cosmetic that is not on the ladder, 3 daily missions, the play gift for active minutes only, and a weekly 20-tier free "Lab Season" track. A visual BONE JOURNAL with silhouettes, a hint each and BOLTS per page; it drives discovery of machines and creatures. A live badge ladder (10/50/100/1000 takedowns, one badge per machine and creature).
ONE VOCABULARY: takedowns and BOLTS. No "kills", no stars, no separate level, no severing promises. Every mission and unlock is logged in Session_v1 and tuned live (ConfigService).
PACING TARGETS:
- minute 1: first unlock at takedown 3, mission 1-2 done, the Grenade in hand by about 90 s;
- minute 5: the chain is at mission 5, 4 unlocks, first journal page, about 150 BOLTS, the 5-minute gift;
- minute 15: 8 unlocks, chain done, the first cosmetic or a far weapon bought with BOLTS, the daily missions started, journal 8/30;
- minute 60: 15-18 unlocks, rank title up, weekly track tier 5, a first weapon mastery skin, all lab machines found, and a stated reason to come back tomorrow (the streak card, today's machine).
Targets: median first visit over 5 min; 3 or more missions done by 70 % of newcomers; first-visit BOLTS spend over 40 %.

- **[critical/high/S] Early unlocks auto-equip and auto-select downgrades; the Grenade never reaches the bar.** Every unlock at 10 takedowns or fewer, and every gun or explosive, goes onto the bar and becomes the held tool. With the start bar Popper/Grab/Punch, a simulation gives this:
- Bat (2), Poke (3) and Crowbar (4) fill the 6 slots;
- Revolver (5) replaces Punch;
- Shove (6) replaces Crowbar (speed 46 down to 22);
- Slap (7) replaces Shove;
- Heal (8) replaces Bat, and Heal does nothing in a destruction game.
At takedown 10 the bar is Popper, Grab, Revolver, Heal, Poke, Slap. None of the GIVE_UP names are left, so autoEquip(Grenade) returns false and the toast says 'Find it in WEAPONS'. Launch (12) goes the same way. In minute 1 the player's gun is also swapped for a 'tiny prod' at takedown 3. *Evidence:* Toys.luau:197 (Poke 3), :198 (Slap 7), :199 (Shove 6), :227 (Heal 8), :249 (Crowbar 4), :259 (Grenade 10); ProgressUI.luau:632-647 (auto-equip rule); PokeController.luau:757-762 (selected = id), :1693 GIVE_UP = Shove/Punch/Crowbar/Bat, :1702-1718 *Fix:* - Make the first rungs real upgrades only: Bat 3, Revolver 6, Grenade 10, SMG 15, Launch 20.
- Cut Poke, Slap and Shove from the early ladder.
- Move Heal into doctor mode.
- Only auto-select a new tool when its power is higher than the held one's.
- GIVE_UP = the weakest tool on the bar by Toys power, never a gun or explosive.
- Add a test: after 1-12 takedowns the bar holds the Grenade.
- **[critical/high/M] Phone players (the majority, upright) see no next-weapon goal at all.** Research pattern #4 says every leader shows a next-weapon meter from the first second (HRR 'Next: X a/b', BRP's WEAPONS kill bar). Our phones show none of it:
- the big WEAPONS button with 'NEXT: X / N kills to go!' is hidden on phones because the experiment card takes its box (PHONE_HUD_MAX7);
- the next-weapon cards are forced off for touch phones (up = 0);
- the HudV3 Next pill is off-phone only.
What is left on a phone is a 30 px level badge, which is also hidden during the quiet start. Session_v1 says most players are upright phones at 414x814. Also plausible but not measured: card texts up to about 56 characters (emoji + text + 0/1 + m:ss) in a 158x46 box with a 14 px floor can clip. *Evidence:* HudPlus.luau:583-585 (hidden on a phone and under v3); PokeController.luau:471-475; HudSlots.luau:164-170 (Experiment takes the Weapons box, 158x46); HudGate.luau:15-20 (v3 pill not on a phone); ExperimentCard.luau:67-69, :352-366; Experiments.luau:28; docs/RESEARCH_FIRST_SESSION.md:142-152 (pattern 4) *Fix:* - An upright phone gets a top strip with a 'Next: Grenade 3/5' pill and bar from 0 s; the mission card stacks under it as icon + 24 characters + bar, with no timer text.
- Add both to LayoutCheck for the 4 portrait phones.
- Drop PHONE_HUD_MAX7's swap.
- **[critical/high/M] A newcomer's first mission is a random daily card, competing with FirstVisit's own objective line.** Today's 3 Daily Experiments are set as the deck when the profile loads and dealt before the ordered list. The daily pick is a seeded random 3 of 21 cards. 9 of the 21 are creature tasks that need you to grab and carry a dummy, the hardest phone skill, for 1 star. Egg, MapLaunch, Takedown25 and Bullseye2 are out of reach in the first minutes. So 13 of 21 (62 %) first cards are carry or out-of-reach tasks; 43 % are a creature task. The card arrives at 40 s, while FirstVisit's 4-step line ('Fire yourself from the CANNON', ...) runs until 300 s. That makes two objective surfaces, with overlapping goals, at once. *Evidence:* ExperimentService.luau:73-78 (deck first); EconomyService.luau:183-189 (setDeck on load); Experiments.luau:40-48 (9 creature cards), :119-127 (daily random); Config.luau:48 (EXPERIMENT_FIRST_AT 40); FirstVisit.luau:44-49 (STEPS), :38 GIVE_UP 300 *Fix:* - Merge FirstVisit and Experiments into ONE mission card.
- Newcomers get a fixed 8-step chain (takedown, cannon, bullseye, equip new gun, spider with a 'Grab, drag, drop' hint, wrecking ball, 10 takedowns, open journal).
- Daily cards start only after the chain or after 10 min.
- Never deal Egg or MapLaunch before the first egg or map visit.
- **[high/high/S] Solo mission cards have timers and fail silently.** Every card has a 60-240 s timer, shown as m:ss on the card. When it runs out, the server sends 'Late' and the client just sets current = nil: the card vanishes with no message, and a new one appears 4 s later. A 'Take down 10 in 2:00' or a creature carry under time pressure in a sandbox comedy game teaches the player that they failed and that the game is random. RDP's mission chain (the only leader with missions) has no timer. *Evidence:* Experiments.luau:26-48 (seconds), :107-109; ExperimentService.luau:299-309, :101-103; ExperimentCard.luau:409-410 (Late: silent), :67-69 (timer in text) *Fix:* - No timer on solo cards: they stay until done, with a free SKIP after 60 s.
- Keep timers only for Prank Party and advent cards, with a visible 'Time's up! Next one...' line.
- Log each Late or Skip.
- **[high/high/L] About 15 overlapping goal and reward systems across 3 windows.** A first visit meets all of these:
- FirstVisit line, Experiment cards, Daily Experiments, DailyGoals 'dares';
- the 7-day calendar, the play gift, the BONE JOURNAL;
- rank, level, invisible combos, badges/trophies;
- stars, BOLTS, eggs, the launch gift, the chase bonus, TRY FREE, the group gift.
Rank & Eggs and REWARDS show the same calendar and the same 3 dares. The Experiments window holds the BOLTS, the journal and the codes. The vault rule is 'every currency has one job, one faucet, one sink'. A child cannot form a plan from this. *Evidence:* ProgressUI.luau:111-140 (calendar + goals in Rank & Eggs), RewardsUI.luau:141-191 (calendar, play gift, dares, trophies, group); ExperimentCard.luau:163-275; HudMenu.luau:24-27; vault 48 Economy Design/Currency Architecture (tldr) *Fix:* Collapse to 3 layers:
- NOW: the mission card;
- SESSION: the Next tracker + BOLTS;
- RETURN: one REWARDS window with streak, 3 daily missions, play gift, journal tab and weekly track.
Delete the Rank & Eggs window, stars, the separate dares and the level badge.
- **[medium/medium/S] Five numbers count the same play: takedowns, level/XP, rank, stars and BOLTS.** - Level is XP derived from takedowns and minutes. It is silent and has no reward or unlock. It is hidden on PC/tablet/console (HudV3) and during a phone's quiet start.
- Rank is a second title from the same takedowns.
- Stars are per visit, never saved, and only multiplied by 10 into BOLTS.
- A done card fires two toasts: '+1 star' from the client and '+10 BOLTS' from the server. *Evidence:* Level.luau:8-21; HudPlus.luau:532-536 (level hidden); Progress.luau:17-25 (ranks); ExperimentService.luau:94-96, :258 (stars reset per visit); EconomyService.luau:115, :126; ExperimentCard.luau:408 *Fix:* - Remove stars: the card shows '+20 BOLTS' directly, with one pop.
- Remove Level, or merge Level and Rank into one 'Lab Rank' whose steps give a real reward (a cosmetic or a far weapon).
- Keep takedowns as the ladder meter only.
- **[high/high/M] BOLTS have no on-screen counter, and their only sink buys weapons one takedown away.** - The Bolts attribute is set, but no client code reads it. The balance appears only inside the Experiments window, which opens from the mission card (between cards or while the card is hidden there is no way in) or from the gamepad MENU.
- BuyNext always buys the LOWEST locked rung at 1.5 x rung (minimum 20). At 1 takedown the window offers 'BUY BAT (20)' for a Bat that comes with the next takedown. Robux sales refuse that (BUY_MIN_LEFT 15); bolts do not.
- After the ladder the button says 'ALL WEAPONS YOURS' and BOLTS pile up with no use.
RDP's coins count up visibly from 0 in minute 1, and HRR sells locked guns for cash. *Evidence:* ProgressService.luau:1966-1972 (attribute only); ExperimentCard.luau:223, :289-320, :356-358; HudMenu.luau:27 (padOnly); Economy.luau:129-145; EconomyService.luau:134-154; Toys.luau:305-310 *Fix:* - A BOLTS counter top-right on every device, counting up.
- A BOLTS shop in WEAPONS: any locked weapon at least 5 rungs away, priced by rung; add cosmetic sinks (hats, trails, dummy skins).
- Mission rewards shown as BOLTS.
- **[high/high/S] The calendar's weapon days are duds for exactly the players who return; no grace day.** - Day 2 promises the AK (rung 27). Day 7 promises the Minigun (rung 40 after the squeeze, and in WOW_POOL for the first 2 eggs).
- An engaged day-1 player reaches both in about 10 minutes. Owned means the day silently becomes '+1 egg', so the headline reward of the streak is worthless to returners.
- Missing one day resets the streak to 1, with no grace day (RESEARCH_V4 #7 asked for one). *Evidence:* DailyGoals.luau:28-31; ProgressService.luau:1579 (reset), :1593-1599 (owned = an extra egg), :1039 (WOW_POOL has Minigun); RewardsUI.luau:155-169 (calendar shows AK/Minigun); docs/RESEARCH_V4.md:149 *Fix:* - Streak rewards exclusive to the streak and not on the ladder: day 3 a trail, day 7 a golden skin of the player's favourite gun or a streak-only toy.
- One grace day per week.
- Show 'Tomorrow: X' on the REWARDS chip.
- **[medium/medium/M] Eggs: unreachable from play, low value, and they gate cosmetics.** - An egg comes every 75 takedowns, and a median visit has about 4. Rank & Eggs says 'Next egg in 75 takedowns'.
- An egg gives one of the next 6 rungs (or any locked one 15 % of the time), which the player would earn in minutes anyway. Only the first 2 eggs are a WOW.
- Hats, the only avatar cosmetic, drop only once every weapon is owned.
- Session_v1: almost nobody opens an egg.
- If eggs are ever sold (Starter Pack = 3 eggs), odds must be shown first (2026 paid-random rules). *Evidence:* Progress.luau:13 (EGG_EVERY 75), :34-47 (hats); ProgressUI.luau:97-106; ProgressService.luau:1036-1039, :1187-1232 (hat only when no locked weapon); Shop.luau:53-55 *Fix:* - Replace takedown eggs with mission-chain crates (after missions 3, 8 and 15) holding cosmetics or skins, with odds and a pity counter.
- The first crate is guaranteed big.
- Weapons come from the ladder or BOLTS only.
- Drop 'Next egg in 75'.
- **[medium/medium/S] Daily dares are unreachable or invisible and need a manual claim in a window.** The dares:
- 'Play 10/15/20 minutes' against a median 2-minute visit;
- 'Take down 15/25/40';
- 'Get a combo of 5/8', though combos are never shown on screen (owner removed COMBO; only '+1 TAKEDOWN' for 120 s and a slow-mo beat at 5).
Each dare needs a CLAIM press. The toast points to 'Rank & Eggs', while REWARDS shows the same rows. *Evidence:* DailyGoals.luau:16-23; ProgressUI.luau:590-604; ProgressService.luau:792-828, :1011-1012; RewardsUI.luau:180-191 *Fix:* - Fold the dares into the 3 daily missions of the mission card system, sized to a 5-10 minute visit, auto-claimed with a pop.
- Drop the Minutes and Combo dares (or show a combo counter).
- **[medium/medium/S] The play-gift clock sits on a button that is hidden everywhere, and the tip still sends players there.** - GiftClock draws its 'GIFT 1:42' tag on PokeController.weaponsHud. That is HudPlus's big WEAPONS button, which is hidden on phones (PHONE_HUD_MAX7) and on every non-phone (LOOK_V3).
- The tip still says 'The clock is on WEAPONS.'
- HudV3 has no GiftAt clock, so the timer exists only inside the REWARDS window.
- That window's bar uses a fixed 300 s span, while the gaps are 120/180/300/300 s, so the first bar starts 60 % full. *Evidence:* GiftClock.luau:47-57, :68; HudPlus.luau:337, :583-585; HudGate.luau:15-20; RewardsUI.luau:229-234; PlaytimeGifts.luau:30 *Fix:* - Put the gift countdown as a chip on the REWARDS / top-bar gift button on every device.
- Use the real gap per gift for the bar.
- Fix the tip text.
- **[high/high/M] Unlock pacing is a firehose up front and every unlock is only a toast.** - The first 10 takedowns give 8 unlocks, and 30 tools unlock by takedown 55 (the LADDER_V2 squeeze of rungs above 30 by x0.363).
- The research spec asked for the first unlock at 3-5 and the second at about 10, and the vault warns against constant-rate pacing.
- Each unlock is one toast. Toasts held through the quiet start flush 4 at once at the reveal.
- No reveal moment exists for the ladder, the game's main progression; only eggs have an opening.
- Late ladder gaps grow to 18-54 takedowns with nothing in between. *Evidence:* Toys.luau:197-283 + Config.luau:62-66 (squeeze); ProgressUI.luau:624-648; docs/RESEARCH_FIRST_SESSION.md:186, :195; vault 'Progression and Pacing Design' / 'Rarity Ladders' tldr *Fix:* - A sawtooth ladder: 3, 8, 15, 25, 40, 60, 85, 115, 150, 200, 260, 330...
- Each unlock gets a 1.5 s non-blocking reveal card (turning 3D model via Ui3D, name, EQUIP chip), and the weapon lands in the hand.
- Mini milestones between late rungs (a crate or skin).
- Plot T(n) for the whole ladder.
- **[medium/medium/L] 69 tools with heavy overlap dilute every unlock.** - 8 hand moves: Poke, Slap, Shove, Punch, Kick, Uppercut, Glove, MegaSlap.
- 8 automatic guns: SMG, AK, M4, Tommy, LMG, Minigun, NailGun, Laser.
- 11 explosives: Firecracker, TNT, Grenade, Sticky, C4, Cannon, Shockwave, BigBoom, RPG, Nuke, plus the Rocket.
- On a phone the catalog is 69 cards of 182x346 to scroll.
- A rung that is 'the same gun, slightly faster' is not a goal.
- HRR and BRP run roughly 25-40 tools. *Evidence:* Toys.luau:195-283; ToolCatalog.luau:33, :287 ('x/69 OWNED'); CLAUDE.md 'Gun ladder' (owner asked for many guns) *Fix:* - Cut to about 32-36 tools, each with a distinct verb.
- Fold the near-duplicates into skins earned by weapon mastery, for example 100 takedowns with the AK unlocks 'Drum' as a skin.
- Keep ids so saves stay valid.
- **[medium/low/S] Mixed and not kid-safe progression text: 'kills', and blurbs promising severed limbs.** - The WEAPONS UI says 'N kills to go!', '(43/100) Kills', 'earn kills' and 'Earn the X with kills', while everything else says takedowns, under MILD_TEXT = true.
- With SEVERING = false, the blurbs still promise severing: Axe 'It can take a limb off', Katana 'One clean cut. Limbs fly', Chainsaw 'Nothing stays attached', Cleaver 'A butcher's blade. Quick and nasty'. That is false and works against the all-ages label.
- 'toy egg' versus 'weapon egg'. *Evidence:* HudPlus.luau:207; ToolCatalog.luau:116, :287, :957; Toys.luau:251, :252, :254, :255; Config.luau:15 (SEVERING false), :40 (MILD_TEXT); Experiments.luau:31 *Fix:* - One vocabulary (takedowns, BOLTS, crate).
- Mild blurbs through the TOY_NAMES mechanism (for example Katana 'One clean swing. Up they go').
- A test that greps player text for kill/limb/blood when MILD_TEXT is on.
- **[medium/medium/S] TRY FREE works on every locked weapon, once each per day, with no daily cap.** - A newcomer can try the Nuke or the Golden Popper at minute 1.
- They can chain 66 two-minute trials, more than 2 hours of top weapons a day.
- Trials, the free weekend, OwnerParty, passes, BOLTS and Robux all bypass the ladder, so takedown goals lose their pull. *Evidence:* TrialService.luau:2-3, :23 (SECONDS 120), take(): limit '#rec.ids >= #Toys.list'; ProgressService.luau:1753-1779 (isUnlocked bypasses) *Fix:* - One trial a day, offered only for the current 'Next' goal weapon or a weapon at least 15 rungs away, right after a wow moment.
- At the end of the trial show 'N takedowns to keep it'.
- **[medium/medium/M] Missions neither persist nor scale with the player.** - 'done' resets every visit, and nextFor restarts the fixed list, so a returning player gets 'Take down 3 dummies' and 'Blast off the CANNON' every visit after the daily three.
- Rewards are flat 1-3 stars. A creature carry (hardest input) pays 10 BOLTS, the same as a cannon ride.
- Vault: scale soft rewards to the player's stage, freeze rewards at deal. *Evidence:* ExperimentService.luau:254-259, :72-78; Experiments.luau:97-100, :40-48; vault 'Quests and Objectives' / 'Retention and Return Hooks' tldr *Fix:* - Save a chain index plus a 'seen' set in the profile.
- Deal by stage: targets grow with takedowns, new machines and maps first.
- Rewards scale by difficulty and stage and are frozen at deal.
- **[high/high/S] No telemetry on goals: we cannot see which mission or unlock loses players.** - ExperimentService is a leaf with no Metrics or SessionStats calls.
- Session_v1 records shots, hits, takedowns and the egg fields, but nothing on missions dealt, done, late or skipped, no first-card or first-unlock time, no BOLTS earned or spent, and no window opens for REWARDS or Experiments.
- The 20 Nov timing moves (mission 40 s, next cards 45 s) can only be judged on visit length. *Evidence:* ExperimentService.luau:1-45 (no Metrics require); SessionStats.luau:49-56, :92, :107-111; docs/V7_PLAN.md:343-348 *Fix:* - Add Session_v1 fields: cardsDealt, cardsDone, cardsLate, cardsSkipped, firstCardDoneAt, unlocks, firstUnlockAt, boltsIn, boltsOut, rewardsOpened.
- Add a Metrics funnel per chain step.
- Extend tools/SessionReport to show them.
- **[medium/medium/S] Reward notices bypass the notification centre and stack up in minutes 1-2.** - EconomyService.give, ProgressService.notice and the client's Notice handler all call Toast.show directly, as if they answered a press.
- So these never get Notify's gaps or merging: the journal ('BONE JOURNAL: First takedown! +25 BOLTS'), mission BOLTS, play-gift BOLTS and claim messages.
- Add the 7 unlock toasts, the rank-up at 10, the star toast, the auto-egg card and the daily egg. A player with about 10 takedowns sees 12 or more pops by 2 minutes. *Evidence:* EconomyService.luau:80-93, :104, :126; ProgressService.luau:1560-1562; ProgressUI.luau:587-589, :593-596, :645; PlaytimeGifts.luau:176-178 *Fix:* - Send unsolicited rewards through Notify 'reward' with merging ('+75 BOLTS: 3 journal pages').
- At most 1 reward pop per 8 s in the first 3 minutes.
- Unlock reveals take priority.
- **[low/medium/S] Badge ladder incomplete; no per-machine or per-creature badges.** - Only 5 badges are live. Havoc Maker (100), Nuked It and Havoc Legend (1000) are id 0 and never awarded.
- There is no 10/50 takedown rung and no badge per machine or creature.
- Ragdoll Sandbox's 10/50/100/1000 ladder keeps 32 % of players to 100.
- BRP's per-machine badges teach the lab: 40-66 % find each machine. *Evidence:* Badges.luau:10-19; docs/RESEARCH_FIRST_SESSION.md:133-135, :148-149 (pattern 5) *Fix:* - The owner creates the badges: 10/50 takedowns, one per lab machine (cannon, bullseye, wrecking ball, tower) and one per creature group, and pastes the ids.
- Show them as journal sections.
- **[low/low/S] Idle time is rewarded.** - Play gifts at 2/5/10/15 min of real time, Level XP per minute, the 'Play N minutes' dare and the lab's TIME PLAYED board all count AFK time.
- There is no idle check, against the vault rule 'AFK policy decided'.
- An AFK farm devalues the BOLTS economy and the boards. *Evidence:* PlaytimeGifts.luau:30; Level.luau:9; DailyGoals.luau:18; CLAUDE.md lab boards TIME PLAYED *Fix:* Count only active minutes: an input or a takedown in the last 60 s.
- **[high/high/L] Nothing to chase after the first 1-2 hours (no D7 layer).** - The ladder tops out at 600 takedowns (Golden Popper), ranks stop at 1000, and the 12 hats wait until every weapon is owned.
- There is no mastery, prestige, lab upgrade, collection beyond the 25 journal pages, or weekly track.
- The leaders are new and update almost daily. Without a long layer a returning player has only 'today's machine' and a daily egg holding a weapon they already own. *Evidence:* Config.luau:62-66 (top about 600); Progress.luau:17-25, :34-47; Economy.luau:28-55 (25 pages); docs/RESEARCH_FIRST_SESSION.md:46 *Fix:* - Weapon mastery: 50/200/500 takedowns per weapon give skins.
- Lab upgrades bought with BOLTS: new machines or zones, bigger cannon, golden bullseye.
- A weekly 20-tier free 'Lab Season' track fed by daily missions.
- Hats move to a BOLTS shop.
- **[medium/medium/M] Experiments window is a dumping ground; the journal is one comma-joined line.** One 440x640 window holds:
- SKIP;
- a friend's SHARE CODE box with TRY IT;
- the BOLTS balance and BUY NEXT WEAPON;
- today's 3 experiments;
- the BONE JOURNAL as a single text run ('BONE JOURNAL 3/25: First takedown, Cannonball!, ...');
- a like-code box with REDEEM.
That is two different code boxes in one window. Ragdoll Research shows journal pages, and HRR has stickers. *Evidence:* ExperimentCard.luau:163-275, :278-321 (journal :296-304) *Fix:* - Journal: its own visual book, with a picture page per entry, silhouettes for the unfound ones, a one-line hint, and BOLTS shown per page.
- Codes: one CODES box in REWARDS/Settings.
- Share code: only on the replay card.
- The mission window shows just the current card and SKIP.
- **[low/low/S] Three different definitions of 'next weapon' on one screen.** - The HudV3 pill and HudPlus use goalOf, which skips non-exciting tools.
- The NextUnlocks cards show the next 3 locked tools of any kind.
- The bar's progress (setNext) uses every rung.
At 5 takedowns on PC the pill reads 'Next: Grenade 0/5' while the cards show Shove 6, Slap 7 and Heal 8. *Evidence:* HudPlus.luau:173-192; HudV3.luau:295-319; NextUnlocks.luau:44-56; ProgressUI.luau:547-559 *Fix:* - One shared Shared/NextGoal.of(takedowns, owned), used by every surface.
- Hide the NEXT cards unless they show the same goal.

**Cut or hide:** Stars (ExperimentService Stars attribute and the '+N star' toast): show BOLTS on the card instead; The Level badge and XP line (Shared/Level, HudPlus LEVEL): silent, rewardless and hidden on PC; or merge into one Lab Rank with rewards; The Rank & Eggs window (ProgressUI 'Eggs'): it duplicates the REWARDS calendar and dares; keep the egg opening as an overlay only; DailyGoals 'TODAY'S DARES' as a separate system: fold into 3 daily missions on the mission card; drop the 'Play N minutes' and 'Get a combo of N' dares; Timers on solo Experiment cards (and the m:ss text on the card); FirstVisit's separate objective line once it is merged into the mission chain; Poke, Slap and Shove from the ladder; Heal moved to doctor mode; near-duplicate guns and explosives turned into skins (69 down to about 32-36 tools; owner approval); Takedown eggs (EGG_EVERY 75) and the 'Next egg in 75 takedowns' bar; TRY FREE on every locked weapon: limit it to one a day, on the Next goal or far rungs; Day 2 AK and day 7 Minigun on the calendar: replace them with streak-only cosmetics; The two code boxes (share code + like code) inside the Experiments window: one CODES entry in REWARDS; the share code stays on the replay card; The BONE JOURNAL as a comma-joined text line: replace it with a visual book or hide it until it exists; The BUY NEXT WEAPON button that buys the rung one takedown away; NextUnlocks cards that list Shove, Slap and Heal as goals; The GiftClock tip 'The clock is on WEAPONS' (the clock is not there); Sever-promising weapon blurbs and the word 'kills' in player text

### D - Content variety and depth (weapons, lab machines, creatures, 21 events, surprises, maps, minigames, vehicles): 3.5/10
On paper the game has about as much content as the leaders: 69 tools, 21 events, 9 creatures, about 12 lab machines, 5 open-air maps, an arena, a 30-piece workshop, 2 cars and NPC commands. For real players almost none of it exists.

Our own badge funnel (badges.roblox.com, universe 10774775314, 20 Nov), out of 931 Welcome badges:
- First Takedown: 630 (68%);
- First Egg: 465 (50%);
- Five Minutes: 84 (9%);
- Bullseye: 45 (4.8%).

The bullseye sits exactly where every cannon shot comes down, so at most about 5-10% of players ever fired the cannon. Bloody Ragdoll Physics (BRP) badges show 41% fire its cannon and 66% use its spike wall.

The rest of the area:
- **One verb everywhere.** About 20 machines and pads all do the same thing: touch it and get thrown with a fixed velocity. None needs aim or skill, and none keeps a score.
- **Machines are out of view.** Most stand behind or beside the spawn camera.
- **The creatures miss the dummies.** The 9 creatures work only on dummies, 90-140 studs from the 6 dummies there are.
- **Most events are out of reach.** 16 of the 21 events are not on sale and are hidden in the live shop. Several are code-built primitives or copies of a tool.
- **The maps are thin.** Each has 2-3 launch pads, under the plan's own bar of 3 activities and 25 props.
- **The early ladder makes things worse.** It auto-equips weaker tools (Poke, Shove, Slap, Heal) over the Bat, Crowbar and Punch.
- **Missing leader verbs.** A player-facing dummy/prop spawner, explosive barrels and NPC Wars are missing, or owner-only.
- **Use is not measured.** Nothing records which content gets used.

Breadth earns the 3.5. Reach, verb variety and finish keep it there.

**10/10 means:** 1. **Spawn view.** In the first portrait-phone view, within 15-45 studs, you see:
   - the dummies;
   - 4 hero machines that work on dummies AND on you: an aimable cannon with score rings on the bullseye, a spike/pin wall that holds a body, chain-reacting explosive barrels that respawn, and the wrecking ball.
   - When you hold a dummy, each machine shows a "drop it here" ghost. There is no permanent text.
2. **The first 30 takedowns.** Every unlock brings a new kind of moment: Bat, Grenade, Revolver, Balloon, Rocket, Freeze, Launch, TNT, Minigun, Shrink. None is a weaker punch. Auto-equip never replaces a stronger tool and never selects a hand-only tool over a gun.
3. **A SPAWN button** (G on PC, a radial on phones and pads) spawns dummies, a dummy wall, a crowd row, barrels and crates. It has device-tier caps, and the Lab Controls pass raises them (the HRR and BRP pattern).
4. **10-12 hero events.** Each uses real models, brings its own victims and makes a 10-second clip that works on TikTok. They have:
   - an EVENTS window where each one is FREE TODAY once (the HRR pattern);
   - a visible roulette on the big button;
   - a per-lab event slot, so one player's event never blocks another's.
5. **Each machine has its own verb and a score.** Examples: a drop tower with a height/flop score, a creature that eats you too, a rocket you ride, a fan that blows.
6. **Each map has one signature activity** you can't do in the lab:
   - City: a car through a crowded junction, with a crash score;
   - Site: a crane hook that grabs and drops;
   - Island: an aimed catapult at floating targets;
   - Farm: a bull pen and a tractor;
   - Army: a tank you drive.

   You reach the maps from walk-in arches in the lab, not only from MENU.
7. **NPC WAR is a featured mode.** You arm two teams, press START and watch with slow-mo.
8. **About 45 tools, each with a real mesh and one unique reaction.** The tool names and descriptions are mild and in one consistent voice.
9. **Use is measured.** Every tool, machine, event, place and vehicle is logged per session (Session_v1 + Metrics), with one badge per machine. Each machine has a target of at least 40% of new players, and each event 25%+ of players in the first 5 minutes.

**Cut:** anything that misses its target after 2 weeks.

- **[critical/high/M] Early unlocks auto-equip downgrades and push the Bat, Crowbar and Punch off the bar.** Every unlock with unlockAt <= 10 goes onto the bar AND becomes the selected tool. When the 6 slots are full it replaces the first of {Shove, Punch, Crowbar, Bat} it finds.

Simulated from a new profile (bar: Popper, Grab, Punch; 6 slots):
- Bat (2), Poke (3) and Crowbar (4) fill the bar. Poke is speed 7 against Punch's 32, and is selected with 'NEW: POKE! Try it!'.
- Revolver (5) replaces Punch.
- Shove (6) replaces Crowbar.
- Slap (7) replaces Shove.
- Heal (8) replaces the Bat.
- Grenade (10): nothing on the bar is in the replace list, so the first big bang shows 'Find it in WEAPONS' and never reaches the bar. The SMG, AK and Minigun go the same way.

By 10 takedowns the bar is Popper, Grab, Revolver, Heal, Poke, Slap: weaker than the start. The egg code already learned this ('a free egg that gives a Poke loses the player'). The signature toys also come late: Balloon 39, Shrink 182, Chicken 201, Black Hole 310 and Portal 437 takedowns, against a median of 4 takedowns per session. *Evidence:* - ProgressUI.luau:627-643 (line 632: Guns, Explosives or unlockAt <= 10 auto-equip);
- PokeController.luau:1693 (GIVE_UP = Shove, Punch, Crowbar, Bat), 1694-1719, 757-760 (beginEquip sets selected = id);
- Toys.luau:197-199 (Poke 3, Slap 7, Shove 6), 200 (Punch speed 32), 207 (Bat 2), 227 (Heal 8), 259 (Grenade 10), 222-245 (gadget rungs, squeezed by Config.luau:64-66);
- ProgressService.luau:1195-1196;
- CLAUDE.md launch data: median 4 takedowns. *Fix:* 1. Take Poke, Slap and Shove off the ladder. Make them one free 'Hands' tool that cycles the moves, or late cosmetic rungs. Move Heal to a Medic tab after 40 takedowns.
2. Reorder the first 30 rungs so each one is a new verb: Bat 2, Grenade 3, Revolver 5, Balloon 7, Rocket 9, Freeze 11, SMG 13, Launch 15, TNT 18, Minigun 22, Shrink 26, Black Hole 30.
3. autoEquip:
   - replace the lowest-power slot only when the new tool's power is higher;
   - never replace a gun, an explosive or the Bat;
   - never auto-select a byHand tool while a gun is held.
4. Add a T1xx test that plays unlocks 0..30 and checks the bar's total power never falls and every gun or explosive in the first 30 lands on the bar.
- **[critical/high/L] Lab machines are found by almost nobody, and most stand outside the spawn camera.** The Bullseye badge reached 45 of 931 new players (4.8%). The bullseye is placed exactly on the cannon's fixed trajectory, so this is close to the share who ever fired the cannon. In BRP, 41% fire the cannon, 55% use the barrels and 66% the spike wall.

The spawn faces -Z towards the 6 dummies 22 studs ahead. These machines are behind the player or far to the side:
- the BIG RED BUTTON (14, +14);
- the stations (z +52);
- the mace (-30, +32);
- the portals;
- the creature yard (z +88 to +98);
- the cars (x +66).

On a 414x814 portrait phone, where most players are, the first view shows the dummies, the lava and the bullseye. The early sign after the 20 Nov first-visit cannon step is 4 of 15 Welcome badges in the past day (27%, small sample). *Evidence:* - https://badges.roblox.com/v1/universes/10774775314/badges (Welcome 931, First Takedown 630, First Egg 465, Five Minutes 84, Bullseye 45; past day 15/16/9/2/4);
- https://badges.roblox.com/v1/universes/10773926254/badges (BRP);
- Lab.luau:45-46, 143-148 (6 dummies on an arc in front of the spawn);
- Playground.luau:861 (button), 739-743 (stations), 642 (mace);
- LabCreatures.luau:682-691;
- VehicleService.luau:32-35;
- PathPlan.luau:36-48. *Fix:* 1. Rebuild the lab as a compact ring. The 4 hero machines go within 15-45 studs and inside a 60-degree cone of the spawn camera:
   - the cannon;
   - a new spike/pin wall;
   - explosive barrels;
   - the wrecking ball.
2. Everything else goes in a second ring, and the yard and garden beyond it.
3. Add a test that projects every hero machine through a portrait 414x814 camera at spawn and requires it to be on screen.
4. Add one badge per machine (owner: 5 free a day) as BRP does, to teach and to measure.
- **[high/high/L] About 20 machines share one verb: touch it and get thrown, with no aim, skill or score.** These all call PlayerRagdoll.launch with a fixed or nearly fixed velocity on touch:
- the cannon, the lava, the 3 stations (SKY LAUNCH, FLING PAD, ROCKET WALL), the tower trampoline, the mace, the wrecking ball and the throw-tower launcher;
- the Christmas chimney and present;
- the 10 open-air map pads.

The cannon has a fixed speed (120) and direction, and the bullseye is placed on that exact landing point. So 'Fly from the CANNON onto the BULLSEYE' pays 2 stars for no skill.

BRP's most-found machines are about dummies and have varied verbs: pin to a wall, chain a barrel, freeze in mid-air, rewind, a blender. A sandbox lives on emergent combos, and identical pads give none. *Evidence:* - Playground.luau:54-55 (CANNON_SPEED 120, fixed CANNON_DIRECTION), 598-600 (bullseye at cannonLanding), 239-269 (throwOnTouch), 739-743 / 763-774 (stations), 795-830 (chimney, present, sleigh);
- MapActivities.luau:1-6;
- Experiments.luau:37 (Bullseye, 2 stars);
- BRP badge list (badges API above). *Fix:* Give each machine its own verb and a score:
- **Cannon:** drag or hold to aim with a power meter, score rings 10/25/50/100 on the bullseye, and a daily moving target.
- **Drop tower:** a height and flop score (BRP's 'Drop Test').
- **Pin wall:** a body sticks for 5 s.
- **Barrels:** they chain and respawn in 20 s.
- **Trampoline:** a stacking bounce counter.

Merge the 3 stations into one LAUNCH PAD with a dial (up, fling, wall). Every machine takes dummies AND players.
- **[high/medium/M] The creature yard is dummy-only, 90-140 studs from the dummies, and 9 creatures do the same thing.** All 9 creatures follow one pattern: a dummy enters a trigger box, the creature animates, and the dummy is thrown back with a velocity.

- They act only on bodies in Workspace.Dummies, never on the player. Kids want to be eaten by the plant or blown up by the whale.
- The lab has 6 dummies 22 studs from the spawn, and they walk home when left. Feeding one creature means grabbing a dummy and carrying it 90-140 studs (6-9 s at walk speed; harder on a phone).
- Each of the 9 experiment cards and 9 journal pages pays 1 star.
- The vacuum, mole, washer and slingshot copy the cannon, lava and station verbs. *Evidence:* - LabCreatures.luau:1-17, 682-691 (Spider -90,-70; Plant 90,-70; Whale -95,92; Slingshot 95,98 ...), 110-139 (dummiesIn: Dummies folder only), 371-673 (each creature ends in a thrown velocity);
- Lab.luau:45-46;
- Experiments.luau:43-51;
- Economy.luau:46-54. *Fix:* 1. Let the creatures take players too, kept kid-safe: swallowed whole and spat out.
2. Move the 3 strongest (plant, frog, whale) into the second ring near the dummies.
3. Make them fetch their own food: the frog's tongue reaches 30 studs onto the test mat, the vacuum roams the lab floor, and the hen wanders.
4. Cut or merge the washer, mole and slingshot.
5. Pay 2-3 stars for the first use.
- **[high/high/M] Players cannot spawn dummies or props; only the owner can.** Every leader lets the player make more targets:
- HRR: 'G Spawn';
- BRP: 'spawning objects';
- HRR's Lab Controls pass: spawn dummies, launch, explode.

Here only the owner can spawn dummies (AdminTools Spawn; the Director's row, ring and tower). A player's lab has 6 dummies to feed 69 tools, 21 events, 9 creatures and 2 cars. The sandbox column has only Slow-mo, Revive all and Reset. *Evidence:* - AdminTools.luau:8, 207-228, 533 (Spawn is owner-only);
- Director.luau:297-303;
- SandboxService.luau:3-7, 19;
- Lab.luau:45 (DUMMY_COUNT 6);
- docs/V3_PLAN.md Phase C (the 'Lab Controls' pass with spawn dummies);
- docs/RESEARCH_FIRST_SESSION.md 2.1 (HRR G Spawn). *Fix:* 1. Add a SPAWN action: G on PC, a radial on phones, D-pad on a pad.
2. Choices: dummy, stack of 5, crowd row, dummy wall, explosive barrel, crate.
3. Rules:
   - server-paced;
   - capped by FX_CAPS ragdolls per device tier (14/18/22);
   - cleaned up by Reset.
4. The Lab Controls pass raises the caps and adds 'explode all' and 'freeze time' (a revenue line).
- **[high/high/M] Dead props: the giant fan, the rocket, the barrels and the crates look playable but do nothing.** The lab's most inviting props are scenery only: a 16-stud giant fan, a 26-stud rocket, 5 barrels and 3 crates. Kids walk to the rocket and nothing happens.

Meanwhile:
- a Fan tool exists (unlock 128);
- BRP's explosive barrel is used by 55% of its new players;
- the V3 plan promised explosive barrels (respawning after 20 s), a giant fan with a VectorForce cone and a rocket launch.

None of those three was built. *Evidence:* - LabDress.luau:1-5 ('Scenery only ... play is the same'), 16-25;
- Toys.luau:234 (Fan);
- docs/V3_PLAN.md Phase C, machines list;
- BRP 'Chain Reaction' 4,854,970 of 8,783,358 (badges API). *Fix:* 1. **Barrels:** they explode on any hit, chain and respawn (Blasts).
2. **Giant fan:** it blows in a cone (reuse ToyService.fan).
3. **Rocket:** a ride (prompt, countdown, launch, parachute landing on the bullseye).
4. **Crates:** they break into planks.
5. Anything that stays decor gets no hero placement.
- **[high/high/L] 16 of 21 events are hidden live, only reachable at random, and many repeat each other.** **Hidden.** 16 events have productId 0 and are hidden from the live shop. A live player meets them only at random from the BIG RED BUTTON: a pick from 18, a 75 s gap, and the button stands behind the spawn.

**Repeats.** Many copy each other or a tool:
- ZeroG and MoonGravity;
- FanBlast and the Fan tool;
- BowlingAvalanche and the Bowling tool;
- Sinkhole and the Black Hole tool;
- FlashFreeze and the Freeze tool;
- RocketRain, MeteorShower, LightningStorm and Earthquake are all 'things hit the 6 dummies'.

**Code-built.** The surprises are built from primitives: the UFO is cylinders, the Magnet is 5 blocks, the rockets are blocks. That reads as cheap next to HRR's rendered tornado and T-rex.

**Too few victims.** Most events act on only 6 dummies, so the spectacle is small.

**Free paid events.** The button also gives the paid Mega Bomb and Dummy Rain for free. *Evidence:* - Events.luau:21-46 (productId 0 for 16);
- EventShop.luau:433-434, 540-541 (card hidden unless for sale or Studio);
- Playground.luau:859 (BUTTON_EVENTS includes MegaBomb, DummyRain), 861;
- Config.luau:234 (BIG_BUTTON_GAP 75);
- Surprises.luau:126-140, 238-262, 296-306, 719;
- docs/V3_PLAN.md (HRR Events window: 9 cards, 'Free today USE'). *Fix:* 1. Cut to 10-12 hero events, each with a real model and its own victims (8-12 guest dummies or a crowd):
   - Gorilla, Bull Run, Tornado, Train, UFO, Giant Dummy, Dummy Rain, Balloon Drop, Mega Bomb, Zero-G, Meteor and Magnet.
2. Merge or cut the repeats.
3. Add an EVENTS window that shows every event, each FREE TODAY once (HRR), then the button or Robux.
4. The button shows a roulette of what is coming.
5. Take the paid events out of the free roulette, or make them the daily free one.
- **[medium/medium/M] 'Server events' are invisible to the rest of the server, and one queue blocks every lab.** Events.luau and EventService describe 'one big moment the whole server sees'. In fact Dummy Rain, Mega Bomb, the creatures and the surprises run at labCenter, which is the buyer's own lab, and other players' plots are hidden from each other. Everyone gets a 'X sent MEGA BOMB' banner for a blast they can't see.

The queue is one per server. One player's 25 s Giant Dummy turns every other lab's BIG RED BUTTON into 'Busy, try again soon'. *Evidence:* - Events.luau:2-3;
- EventService.luau:2-3, 85-95 (labCenter = the host's lab), 174-175, 288-289;
- Playground.luau:893-906 (button refuses while anything runs or waits);
- CLAUDE.md owner decision: 'others' plots not visible'. *Fix:* 1. Give each lab its own event slot, so lab events run in parallel within the server body cap.
2. Show the full banner only to players who can see the event. Others get a small chip with a WATCH button (Spectate).
3. Label the truly global events (Zero-G, Bouncy Floor) as 'for the whole server'.
- **[high/medium/XL] The open-air maps are big and nearly empty: 2-3 identical pads each, under the plan's own bar.** The maps are 320-440 studs across, with 12-18 crowd NPCs and these activities:
- City: 2 identical MANHOLE pads;
- Island: catapult and cliff-dive pads;
- Site: pit jump, roof launch and a teleport;
- Farm: hay slingshot and 'BISON TOSS', which is a pad, not a bison;
- Army: mortar and ejector seat; its tanks are static props.

The V3 plan's own bar was at least 25 props and 3 activities per map, with signature machines: crane hook, bus runs, gorilla pen, boat ramming. The cars may not leave the lab floor.

On phones (most players) the maps sit inside MENU > PLACES. Nothing in the world leads to them. *Evidence:* - OutdoorMaps.luau:282-283, 434-439, 632-633, 714-715, 749, 794-795;
- MapActivities.luau:1-6;
- Places.luau:43-48;
- VehicleService.luau:9-10;
- HudMenu.luau:21, 56 (PLACES phone-only in MENU);
- docs/V3_PLAN.md Phase B table. *Fix:* 1. Give each map one signature activity the lab can't offer:
   - City: drive a car or bus through a crowded junction, with a crash score;
   - Site: a crane hook that grabs and drops dummies and players;
   - Island: aim the catapult at floating targets;
   - Farm: a bull pen and a tractor;
   - Army: a tank you drive (its shell = Blast).
2. Otherwise cut to 2-3 maps done properly.
3. Add walk-in map arches with pictures in the lab, next to the portals.
- **[medium/medium/L] Vehicles: 2 code-built cars fenced into the lab with 6 targets.** A box 'Family Car' and a 'Monster Truck' are built from parts and may not leave the lab floor. There is:
- no ramp course or loop;
- no dummy wall or crowd crossing to plough through;
- no crash score;
- no tank or bus, although the V3 plan listed both.

Crash physics is its own top genre (BloxNG at 35.8k CCU), and the code itself calls 'vehicle into the crowd' a top video format. *Evidence:* - VehicleService.luau:1-11, 32-35;
- Config.luau:222-233;
- docs/RESEARCH_FIRST_SESSION.md section 1 (BloxNG 35,802 playing);
- docs/V3_PLAN.md Phase C (car, monster truck, tank, bus). *Fix:* 1. Real Creator Store vehicle models (with the malware pass).
2. A crash course in the second ring: ramp, loop, dummy wall, a spawner for a crowd crossing, and a speedometer with a crash score.
3. A tank on the Army map and a bus in the City.
4. Cars allowed on the open-air maps.
- **[medium/medium/M] NPC Wars exists but is buried behind 'Talk' on one dummy at a time.** NpcCommand lets a player hand an NPC their own weapon and order it to attack, which is close to BRP's advertised 'NPC team battles'.

It is reached only by walking up to a dummy and pressing E 'Talk', with at most 3 followers. Nothing in the HUD, the world or a card points to it. An NPC battle you set up and watch is a strong clip format. *Evidence:* - NpcCommand.luau:1-10, 29 (MAX_FOLLOWERS 3), 364 (prompt 'Talk');
- games API description of Bloody Ragdoll Physics (NPC team battles), https://games.roblox.com/v1/games?universeIds=10773926254. *Fix:* 1. Build an NPC WAR machine (a ring or arena pad in the lab):
   - pick two teams of 5;
   - hand out weapons per team from your owned tools;
   - press START and watch with a slow-mo finish and a winner banner.
2. Make it one experiment card and one badge.
- **[medium/medium/XL] Weapon breadth without identity: 40 'hit' tools that differ only in numbers, and blades with no point under mild mode.** Of the 69 tools:
- 40 are kind 'hit', differing only in speed, lift and cooldown;
- 13 of the 20 guns are plain hitscan (only the shotguns, sniper, railgun, flare gun and golden one have WeaponMechanics);
- the 19 melee tools are mostly speed variants;
- with SEVERING false, the 5 blades (Axe, Cleaver, Katana, Chainsaw, Plasma Blade) lose their only special trait.

Only 21 of 38 held tools have real mesh models. The rest are built by code. *Evidence:* - Toys.luau:195-283 (counts: hit 40, place 19, dummy 9, grab 1; held 38; gun 20);
- WeaponMechanics.luau:3-9, 26-31;
- Config.luau:15 (SEVERING false);
- CLAUDE.md 'Phase 2b' (21 real mesh models; icons not redrawn). *Fix:* 1. Give every kept tool one signature reaction. Examples:
   - Bat: home-run arc with a ball-cam;
   - Pan: a bonk ring with stars;
   - Golf: a flag where it lands;
   - Katana: a slice that sends the body into a dizzy spin, with no gore;
   - Chainsaw: a grinding shake.
2. Merge the look-alike automatic guns (SMG, Tommy, AK, M4, LMG) into 3, and the blades into 2.
3. Aim for about 45 tools, all with real meshes and redrawn icons.
- **[medium/low/S] Weapon card texts promise severing that is switched off, and the names use two voices.** With SEVERING false, the cards still say:
- Axe: 'Chop. It can take a limb off';
- Cleaver: 'A butcher's blade. Quick and nasty';
- Katana: 'One clean cut. Limbs fly';
- Chainsaw: 'BRRRRR. Nothing stays attached'.

That is untrue, and it works against an all-ages maturity questionnaire. The file header is stale ('A new player has five weapons').

TOY_NAMES renames only 11 tools. Toy names (Popper, Buzz Blaster, Rattler) now sit next to Sniper, Minigun, C4, Nuke, Auto Shotgun and Railgun. *Evidence:* - Toys.luau:11, 111-123, 251, 252, 254, 255;
- Config.luau:15, 37;
- docs/RESEARCH_V4.md section 10 (answer the questionnaire for the most extreme reachable content). *Fix:* 1. Add mild description overrides for every blade when SEVERING is false.
2. Pick one naming voice: toy-lab names across the board, or keep the real-ish nicknames for every gun.
3. Fix the header comment.
4. Extend T57_MildContent: no description may contain limb, cut, attached or butcher while SEVERING is false.
- **[high/high/S] Content use is not measured, so 'what nobody finds' can't be answered.** Session_v1 records shots, hits, takedowns, eggs and input. It does not record:
- which tools were fired;
- which machines were touched;
- which events were seen;
- which places, vehicles or creatures were used.

Metrics logs unlocks, purchases and trips, never use. The only content funnel is the 5 live badges. Each content decision in this audit therefore rests on code reading and one badge. *Evidence:* - SessionStats.luau:25-58 (the Record fields);
- Metrics.luau:7-10 and its 22 callers (Unlock, Weapon_*, Place, Game_*, Horde_*, Chase_*: no use events);
- badges API: only 5 badges live (CLAUDE.md 'Badges live'). *Fix:* 1. Add a 'used' set to Session_v1: tool ids fired, machine and creature names triggered, event ids seen, place ids, vehicle driven, and the time of the first machine.
2. Add Metrics 'Use' events with the item as a custom field.
3. Add a SessionReport table: share of sessions that touched each item, by device.
4. Owner: create one badge per hero machine over the coming days (5 free a day).
- **[medium/medium/M] Deep content outside the real session: the horde at 10 min, and the arena, workshop and maps behind MENU.** Only 9% of new players reach 5 minutes, and the median visit is about 120 s. The following land outside that window or behind MENU:
- the plaza horde comes every 600 s;
- the Game Arena (Red light green light, Shoot 'em) and the 5 maps are reached through PLACES;
- the 30-piece Workshop (pistons, motors, cannons, sensors) is in MENU > SANDBOX on phones and has no goal or template;
- REWARDS is in MENU on phones.

For about 90% of players this content does not exist. *Evidence:* - HordeService.luau:29 (HORDE_EVERY 600);
- HudMenu.luau:18-31, 56 (PLACES, SANDBOX, REWARDS phone-only inside MENU);
- Build/Catalog.luau (30 pieces);
- BuildService.luau:1-11;
- badge funnel (Five Minutes 84/931). *Fix:* 1. Move one deep feature into the 2-4 minute window as an invited surprise: a horde in your own lab at 150-180 s, or an arena invite card.
2. Workshop: 3 one-tap blueprints (dummy catapult, launch ramp, domino wall) that you can build and launch within a minute (the Build A Boat lesson).
3. Hide whatever can't be made reachable.
- **[low/low/S] 'Today's machine' is a sign with no reward.** One of 8 machines is named each UTC day, with a sign. It gives no bonus and has no card or score, so it is world text for nothing.

The V3 plan wanted an experiment tied to it. *Evidence:* - LabZones.luau:7-8, 31-46, 185-196;
- Config.luau:178 (TODAY_LIGHT false);
- docs/V3_PLAN.md Phase C ('Activity of the day ... plus an Experiment tied to it'). *Fix:* Either make it pay or cut the sign:
- double stars or bolts on today's machine;
- the day's first Daily Experiment aimed at it, so a return visit has a reason;
- a small HUD chip in place of the world sign.
- **[medium/medium/M] The Christmas lab (from 1 Dec) is three copies of existing pads.** - The CHIMNEY is a launch straight up at 200 (= SKY LAUNCH).
- The PRESENT is a throw on touch (= the lava).
- The SLEIGH RAMP is a wedge with a red box and no function.

All three are code-built primitives. The season starts in 10 days and is the best D7/D30 return hook of the year. *Evidence:* - Playground.luau:795-830 (805 ChimneyPad velocity 0,200,0; 813 PresentTrap; 827 SleighRamp);
- Config.luau:94-99 (CHRISTMAS_FROM_DEC1, CHRISTMAS_LAB, ADVENT). *Fix:* 1. Build the Christmas update around new verbs, with real models:
   - a snowball cannon you aim;
   - a timed sledge run with a leaderboard;
   - a present that pops a guest dummy or an egg;
   - an ice slide into the bullseye.
2. Tie the advent cards to them.
- **[medium/medium/S] Hold-a-dummy affordances were removed, so nobody knows dummies go into the machines.** Under LOOK_V3 the 'PUT RAGDOLL HERE' signs were dropped, and the stations stand behind the spawn. Nothing changes when a player holds a dummy near a pad, the cannon or a creature.

In BRP, putting dummies into machines is the content, and 40-66% find each machine. *Evidence:* - Playground.luau:496 (V3_DROP removes 'PUT RAGDOLL HERE', 'BULLSEYE', 'LAVA!');
- Playground.luau:769 (stations keep only their name);
- GrabController.luau has no machine hint;
- BRP badges (Blast Off 41%, Pin Cushion 66%, Bounce Test 43%). *Fix:* While a dummy is held:
- every machine and creature within 40 studs shows a soft outline and a ghost dummy silhouette on its trigger;
- a dropped body snaps into the trigger.

No permanent text. Add a test that the hint appears only while holding.
- **[low/low/S] Studio shows content that live players never see, so reviews judge the wrong game.** In Studio:
- every productId 0 event shows as a TEST card;
- the map-shop booths are built;
- the shop runs unsold events at once.

Live players see none of this: 16 events hidden, no booths. The paths to the booths are not built live either. Blind reviews and captures (all from Studio) have been scoring content that does not exist in the live game. *Evidence:* - EventShop.luau:434, 541 ('forSale or studio');
- EventService.luau:603-611 (Studio runs unsold events);
- MapShopService.luau:7, 73 (id 0 = no booth live, TEST in Studio);
- PathBuilder.luau:157-172. *Fix:* Add a ServerStorage 'LiveView' flag. When set, Studio play hides id-0 content exactly as live does. Use it for every review and capture.
- **[low/low/S] Two towers side by side, and each tower's real verb is unscored.** On the west side there is the 20-stair fall tower with a plank and trampoline, and about 20 studs away the CastleTower throw tower with a lift pad and a launcher. Both offer 'jump or fly off a height', and neither has a height or flop score.

BRP's 'Drop Test' badge reaches 22% of its new players. *Evidence:* - Playground.luau:85-123 (buildTower at x -52);
- LabDress.luau:37-60 (TOWER at -70, -28 with lift and launcher);
- Experiments.luau:40 (Tower card). *Fix:* Keep one drop tower in the second ring:
- a lift to the top;
- you or a dummy drop off;
- 'FLOP SCORE' from the fall height and the landing spin;
- a personal best on the board.

Cut the other tower.

**Cut or hide:** Poke, Slap and Shove as ladder rungs: fold them into Punch or one free 'Hands' tool. Move Heal off the first 10 takedowns (Toys.luau:197-199, 227).; The 3 launch stations (SKY LAUNCH, FLING PAD, ROCKET WALL): merge into one dial pad (Playground.luau:739-783).; The second tower: keep one drop tower with a score (Playground.luau:85-123 or LabDress.luau:37-60).; Duplicate events: Moon Gravity (= Zero-G), Giant Fan (= Fan tool), Bowling Avalanche (= Bowling), Sinkhole (= Black Hole). Keep only one of Rocket Rain, Lightning Storm and Earthquake. Hide Magnet Storm until it has a real model.; Mega Bomb and Dummy Rain in the BIG RED BUTTON's free pool while they are sold for Robux (Playground.luau:859).; The 'Today's machine' world sign, unless it pays a bonus (LabZones.luau:185-196).; The static BigFan, Rocket, barrels and crates: make them work or move them out of hero spots (LabDress.luau:16-25).; Creature yard: washer, mole and slingshot, which copy existing verbs. Keep the plant, frog, whale, spider and chicken, closer to the dummies.; City's second MANHOLE pad (OutdoorMaps.luau:283), and the 'BISON TOSS' pad name with no bison.; The plaza horde every 600 s, which almost no one sees (HordeService.luau:29): fold it into the in-lab chase or cut it.; The SLEIGH RAMP with no function (Playground.luau:827-830).; The 'CLIPS & LIVE' MENU entry for non-owners: Streamer Mode is owner-only (HudMenu.luau:29; StreamerService.luau:7-9).; Code-built egg hats (cones and buckets, ProgressService.luau:616-645), until real accessories exist.; Dead builders kept in the code: WorldDress (WORLD_V2 false), the removed room builders in WorldMaps, and the old src/ folder. Not seen by players, but they cost review and test time.; Map-shop booths and their paths while the product ids are 0 (they show in Studio only).

### E - Lab and world art (layout, readability, clutter, paths, gardens, creature yard, signage, lighting, materials, ambience): 3/10
The lab does not look like one designed place. Six themes share one plot (crash-test pad, park, castle, launch site, cartoon zoo and, from 1 Dec, a Christmas yard), built at three levels of finish: Roblox PBR packs, old part-built Creator Store builds and raw code primitives. Glowing Neon slabs and lines are the most visible marks of a code-built world, and they appear in the store thumbnail. On an upright phone (the device most players use, about 39° wide view) the spawn view shows no machine: the cannon is 97° to the right, behind the player. A wooden signpost is computed to stand on the spawn point. The white dummies stand on a light-grey floor at about 1.8:1 contrast. The 9 creatures are 70-120 studs away, behind the player, and only react to dummies someone carries there. The red barrels, crates, fan and rocket look usable but do nothing. There are 6 sign systems in 5 fonts. With the birds off, the world makes no sound when nothing is happening. On 1 Dec the Christmas lab will land on two of the paths. A few things work: the real models (cannon, button, cars, trees), the hedges that hide the neighbours, V7-1 removing the boxes and the light column, and the wrecking-ball gantry rework. It is still far from the leaders' clean, compact test grounds (BRP: a sand test lab with the cannon, gantry and wrecking ball in view; HRR: a grass park lab with wide paths and props you can use).

**10/10 means:** The lab has one identity you can say in a sentence, for example "an outdoor crash-test park". It sits on terrain grass with soft painted blends. There are 2-3 wide (8-10 stud) pale-concrete test lanes with joint lines, laid flush so no foot clips into them. The machines are safety-yellow steel. Everything uses one PBR material set (2022 materials plus official Roblox packs, no AI-generated variants), and Neon appears only as thin ready-lights.

The core is compact (about 120x120 studs) and composed for the narrowest screen, a 39° upright phone. From the spawn you see 3 dummies 12-15 studs ahead, the cannon firing across the view so its arc and the bullseye are framed, and one hero vertical (the gantry or a steel drop tower) that is at least 1.5x taller than anything else. Everything else is grouped into 2-3 side zones. Each zone has one hero and one accent colour, reached in 3-5 s on foot, and you see it the moment you turn.

Every prop that looks like a toy is a toy (barrels explode, crates break, the fan blows), and anything else is gone. Creatures sit in one zone next to the dummies and work on players too. At most 3 world labels show at once: one font, an icon plus 1-2 words, and one name per machine everywhere. Light is an afternoon key light shining across the main view with a warm/cool grade tuned on a phone at quality 1-3, and it passes the greyscale test (dummies, paths and machines separate). There is a quiet outdoor sound bed, positional loops on the machines and idle sounds on the creatures. Part and terrain budgets are measured on a low-tier phone. Any frame from the spawn with the HUD hidden would work as a thumbnail or TikTok shot.

- **[critical/high/XL] No single theme: the lab is a crash-test pad, park, castle, launch site, cartoon zoo and Christmas yard at once.** One 250x205-stud plot holds:
- a concrete crash-test floor with crash wall and lab benches;
- a medieval stone castle 'throw tower';
- a rocket on its launch gantry and a giant yellow industrial fan, both pure scenery;
- a cosy park with hedges, fountain, shed, benches, flower beds and 8 street lamps;
- a creature zoo: a whale on beach sand under a palm, a washing machine with a clothes line, a living-room rug with a robot vacuum on grass, a frog pond, a chicken run;
- from 1 Dec, a chimney, a present and a sleigh.

The models come from three levels of finish: Roblox's realistic PBR packs, part-built 'OLD' Creator Store builds (the castle; the rocket is a 'weak pick' in docs/V3_ASSETS.md) and cartoon 'M' creatures, plus raw code primitives. The vault (Environment Art Styles; World Composition) says mixed asset styles read as 'assembled from the toolbox' even when each asset is good. Each leader has one identity:
- BRP: 'a sand-floored test lab';
- HRR: 'an outdoor park lab: grass, paths, a tower, a rail track, red barrels, a big fan and a ring'. *Evidence:* Lab.luau:702-733 (floor, crash wall, benches, barriers); LabDress.luau:15-36 (BigFan, Rocket, barrels, crates, lamps), :42 (CastleTower); LabGarden.luau:97-150; CreatureHabitats.luau:84-205 (rug, clothes line, whale sand + palm); Playground.luau:789-830 (Christmas); docs/V3_ASSETS.md; docs/RESEARCH_FIRST_SESSION.md:67,83; art/maps/Lab.jpg *Fix:* Have the owner pick one identity in one sentence. Recommended: 'outdoor crash-test park', which suits the white crash dummies and matches the leaders.

Write docs/STYLE_LAB.md: a 6-colour palette, the material set, model sources and a 'not this' list.

Then re-skin or remove whatever fails it:
- castle -> a steel scaffold drop tower;
- rocket -> cut it, or make it a working rocket sled;
- creatures -> their own 'Monster Garden' map/portal, or re-skin them as test rigs (washer = spin tester, slingshot = catapult rig);
- garden -> hedges and trees only.

Put every change behind a Config switch, and judge it on captures from spawn, cannon and the back end on a 414x814 portrait phone and on PC.
- **[critical/high/L] Spawn view on the majority device (upright phone) shows no machine.** At 414x814 portrait with Roblox's vertical FOV of 70, the horizontal view is about 39° (±19.5°). The player spawns facing -Z with the camera about 12 studs behind. Angles off the view axis:
- cannon at (48,6): 97° to the right, behind the shoulder;
- wrecking ball (40,-38): ~39°;
- lava (-27.5,-41): ~27°;
- fall tower (-52,-64): ~34°.

The two end dummies of the 70° arc at radius 22 are at ~23° and are cut off too. What remains: 4 dummies, a flat bullseye on the floor, the crash wall, two global leaderboards and the owner board.

FirstVisit step 2, 'Fire yourself from the CANNON', marks the cannon with a Highlight in DepthMode Occluded, which does nothing while the cannon is off-screen. The repo's own spec asks for 2-3 dummies 10-15 studs ahead 'with the cannon and one machine in view behind them'. The vault (Level Design) says: spawn facing the centrepiece. *Evidence:* Lab.luau:46 (RADIUS 22), :144 (70° spread), :749-750 (spawn faces -Z); Playground.luau:157 (cannon 48,6); FirstVisit.luau:45,146-156; docs/RESEARCH_FIRST_SESSION.md:175 *Fix:* Re-lay the core for a 39° view:
- 3 dummies at 12-15 studs;
- the cannon behind-left of them, firing across the view so the arc and bullseye are framed;
- the gantry as the tallest hero just right of centre.

Add a pure SpawnView table in Shared, and a self-test that every first-visit target lies within ±18° and 60 studs of the spawn camera. Add an off-screen edge arrow on the objective line while its target is not on screen.
- **[high/medium/S] A path signpost stands on the spawn point.** PathBuilder puts a signpost at each name in PathPlan.SIGNS, 3.7 studs from the fork on the side no path takes. Recomputing PathPlan.curve and that placement puts the 'Fork' post at lab (1.5, 0.3). Players spawn at origin + (±2, 3.5, ±1).

The post is 6.6 studs tall, with 3.6-stud boards at heights 5.2 and 6.1 that do not collide. So a new player's head starts inside boards reading 'CANNON >' and '< LAVA', in the foreground of the very first frame. The Hub post beside it opens with 'WORKSHOP', pointing at the spawn, but there is no workshop there. *Evidence:* PathPlan.luau:112 (SIGNS includes Fork), :93 (Fork = 'WORKSHOP'); PathBuilder.luau:333-380 (signpost sizes), lab() signpost placement (away * (WALK_WIDTH/2 + 1.6)); Lab.luau:749 *Fix:* Remove 'Fork' and 'Hub' from SIGNS. Add a 10-stud keep-clear circle round the spawn to PathPlan.OBSTACLES, and have T106 assert that no path part, sign or prop is inside it. Drop or rename 'WORKSHOP'.
- **[high/medium/S] From 1 Dec the Christmas lab will sit on two paths.** CHRISTMAS_FROM_DEC1 + CHRISTMAS_LAB build:
- a 7x14x7 brick chimney at (60,40), with its launch pad at (60,34);
- a collidable 6x6x6 present trap at (-56,46) that throws whoever touches it;
- a sleigh ramp at (62,-12).

PathPlan.OBSTACLES does not list these spots, so T106 cannot catch them. Walking the plan's actual stones:
- the EastGap->GardenEast walk goes through the chimney stack (x 54-64, z 38-40) and grazes the ChimneyPad;
- the Portals->YardWest walk, the way to the monsters, runs through the present box (x -56..-54, z 42-49), so walking it launches you;
- the East->Vehicles walk ends against the sleigh ramp.

This goes live in 11 days. *Evidence:* Playground.luau:789 (CHRISTMAS_SPOTS), :795-830 (chimney/present/sleigh, throwOnTouch); PathPlan.luau:47-68 (segments), :118-152 (OBSTACLES without them); ServerScriptService/Server/Tests/T106_Paths.luau:29-42; Config.luau:97-98 *Fix:* Add the three CHRISTMAS_SPOTS footprints to OBSTACLES, or move the spots off the walks (chimney beside the rocket wall at about (66,58), present at about (-40,60)). Run T106 with Workspace 'Christmas' on, and capture the lab in Christmas mode before 1 Dec.
- **[high/medium/M] Neon slabs and lines are the biggest 'code-built' tell, and they are in the store thumbnail.** Neon in the lab:
- CannonPad: an 8x8 Neon orange slab with a white Neon bar arrow. It blooms into a flat yellow square in art/store/v4/thumb4_car.png.
- Stations: three Neon blocks (cyan, purple, red).
- Plot edges: every plot is outlined by four Neon light-blue lines, which now cut through the garden edge and the frog pond.
- Throw tower: the lift and jump pads are Neon.
- Spider web: 48 Neon parts.

Vault (Environment Art Styles): 'Too much glow -> keep glow coverage in budget'. The leaders use painted steel plates. *Evidence:* Playground.luau:158,163 (CannonPad, CannonArrow), :765 (StationPad); Lab.luau:584-597 (Neon edges, markPlot); LabDress.luau:66; LabCreatures.luau:227,236; art/store/v4/thumb4_car.png *Fix:* Replace each pad with a modelled launch plate: recessed dark steel, a yellow-black chevron texture, and a thin emissive ring that pulses only when it is ready. Delete the plot Neon lines (hedges and PlotPrivacy already mark plots). Make the web one alpha-textured mesh. Style rule: Neon only on indicators under 1 stud.
- **[high/high/M] White dummies on a light-grey floor: the core action does not read.** The dummies are 240,240,238. The lab floor is 176,180,188 concrete with the generated LabFloorTiles variant, which looks like cloudy water stains in art/maps/Lab.jpg. That is about 1.8:1 luminance contrast; the same white on the lab's grass green (86,124,64) would be about 4.2:1.

Only the 42x16 black rubber mat under the row gives contrast, and a knocked body leaves it at once. Phones below quality 4 draw no shadows (vault, Stylized Lighting Recipes), so a body lying on the floor loses its outline on the device most players use. The leaders put white dummies on sand (BRP) or grass (HRR). *Evidence:* Config.luau:217 (LOOK_V3_DUMMY); Lab.luau:707-708 (LabFloor 176,180,188 + Finish 'Floor'), :711 (TestZone mat); art/maps/Lab.jpg *Fix:* Make the play ground darker or greener: grass terrain with concrete or dirt lanes, or a mid-dark asphalt test floor (about 85-95 grey). Replace the AI-generated LabFloorTiles with 2022 Concrete/Asphalt or an official PBR variant. Then run the greyscale test (Saturation -1) on a phone at quality 1: dummies, paths and machines must separate.
- **[high/high/M] Props that look interactive do nothing.** Five red oil barrels, three crates, the giant fan and the rocket are pure scenery; no gameplay code refers to them. In BRP, the explosive barrel is the 3rd most-found first-session moment (55% of new players by badge count), and HRR's big fan is a wind machine. A player who shoots a red barrel and gets nothing learns that the world is just a backdrop. *Evidence:* LabDress.luau:15-36 (SPOTS: BigFan, Rocket, Barrel x5, Crate x3; only V3Assets.place); grep finds no gameplay for these roles; docs/RESEARCH_FIRST_SESSION.md:89 *Fix:* Make them toys or cut them:
- barrels explode on a hit and respawn after 10 s (pooled client FX);
- crates break into planks;
- the fan blows bodies in its cone, through DummyControl like the other machines;
- the rocket becomes a sled that carries a dummy away.

Give each a hidden badge and an Experiments card, like BRP's machine badges.
- **[high/medium/M] Paths are a garden walk laid on a crash-test floor, and they clip feet.** The lab has 21 path segments: 4.2-stud cobbled 'warm stone' walks with slate kerbs, on top of the industrial concrete. The gardens have a second cobble system. Paving is raised 0.16 studs and kerbs 0.34 with CanCollide off, so every player and dummy stands 0.16-0.34 studs inside the path.

The tree layout still fans out to 13 goals with 6 signposts and about 360 parts per lab. The blind reviewer stopped at 7.5 after 3 rounds. The leader HRR uses about 12-stud light concrete paths with joint lines on grass. *Evidence:* PathPlan.luau:16-22,47-68; PathBuilder.luau:206-212 (WALK_WIDTH 4.2, KERB_H 0.34, PAVE_H 0.16), flatPart CanCollide false; LabGarden.luau:100-106; docs/V7_PLAN.md State (V7-2 7.5); docs/V3_PLAN.md (HRR table: 'Wide light concrete paths of about 12 studs') *Fix:* Decide the ground first (see the floor contrast finding). On grass terrain, lay 3 wide (8-10 stud) concrete test lanes with joint lines from the spawn to the 3 zones. Lay them flush (at most 0.02 above the ground) as MeshPart ribbons or terrain paint: no floating kerbs, no stone every 2.4 studs, no signposts; sightlines do the wayfinding. Keep PathPlan as data and T106 as the guard.
- **[high/medium/M] Six sign systems, five fonts, three names per machine.** Sign systems in one lab:
- dark Builder Sans tags;
- a yellow 260x40-pixel 'TODAY'S MACHINE' pill in GothamSSm Heavy, the same pixel size from up to 140 studs, with no reward;
- green 'NEW' pills on things that are not new;
- wooden Fredoka One signposts with ASCII '<  LAVA' arrows on rectangular boards;
- steel portal plates;
- the owner board in GothamBlack, which builds 'ROLINGSTUDIOS'S LAB';
- the spider's GothamBold 'HUNGRY' meter;
- two global leaderboards.

One machine, several names:
- MACE / SPIKE MACE / SPINNING MACE;
- BIG BUTTON / BIG RED BUTTON;
- LAUNCH PADS / LAUNCH STATIONS / SKY LAUNCH-FLING PAD-ROCKET WALL;
- the 'TOWER' signpost leads to the stair tower, while the card 'Jump off the THROW TOWER' means the castle 20 studs away, which no path reaches.

LOOK_V3's own rule is 'almost no text in the world'. *Evidence:* Playground.luau:493-524; LabZones.luau:111-137,196 (pill), :199-207 (NEW); Config.luau:183-185 (NEW_SINCE, NEW_IN_LAB); PathBuilder.luau:333-380; Lab.luau:741 ("'S LAB"); LabCreatures.luau:271-300; Experiments.luau:37; PathPlan.luau:92-110 *Fix:* - Add one shared MachineNames table and use it for signs, cards, toasts and paths.
- Use one world-label component: a small plate with a drawn icon and at most 2 words in Builder Sans, shown only within about 30 studs.
- Fix the possessive ("Name' Lab" / 'LAB · Name').
- Cut the pill and the NEW systems (see the cut list).
- **[high/high/M] Back of the lab: five tall things compete in the first view.** Facing -Z from the spawn, the backdrop holds:
- the fall tower (30 tall, blue stripe and yellow/black band);
- the castle throw tower (30) with Neon pads;
- the rocket (26) and the BigFan (16);
- the gantry (about 25);
- the crash wall with two lab benches;
- two 14x18 global leaderboards raised 4 studs, with SpotLights, built 'facing the spawn so they are the first thing seen';
- the 40x8 owner board 16 studs up;
- fence, barrels, crates and 4 street lamps.

Vault (World Composition): one hero per zone, at least 1.5x taller than anything else. AUDIT.md area 1 already lists 'empty leaderboards at spawn' as P1 clutter. Two towers 20 studs apart weaken both. *Evidence:* Playground.luau:87-117; LabDress.luau:16-17,42; Lab.luau:612-620,722-732; LeaderboardService.luau:470-551; docs/AUDIT.md:36 *Fix:* Choose one hero vertical: the gantry, or one steel drop tower with the throw pad on top. Cut the second tower. Move the lab boards to the plaza or behind the spawn, and hide them for newcomers. Move the owner board down to the lab entrance.
- **[high/high/L] The nine creatures are far away, behind the player, and only work on carried dummies.** LabCreatures.LAYOUT places:
- spider and plant at z -70 in the side gardens (x ±90);
- frog and chicken at x ±89-90;
- five in the yard at z 88-98, behind the spawn.

That is 70-120 studs from where the dummies stand (z -20). Every creature only takes bodies from Workspace.Dummies, so a player who walks into the washer, the whale geyser or the slingshot gets nothing. The cards give 120 s to 'FEED THE SPIDER a dummy', which means finding it and carrying a body about 90 studs. Vault (Level Design): avoid long empty walks. *Evidence:* LabCreatures.luau:682-692 (LAYOUT), :110-131 (dummiesIn filters Workspace.Dummies), :32 (YARD_Z 92); Experiments.luau:40-48; Lab.luau:750 (spawn faces -Z) *Fix:* Build one compact 'Monster Garden' zone beside the test row (35 studs or less) with the 4-5 best creatures in a ring and one hero (the spider web). Let them take players too: the washer spin, whale geyser and slingshot are TikTok moments. Or move the zoo to its own map behind a portal so the lab stays a test ground.
- **[medium/medium/M] The ground is a patchwork of hard rectangles.** Ground pieces:
- baseplate grass 104,128,66;
- GardenGrass parts 86,124,64;
- a 250x38 YardGrass part 86,124,64;
- habitat discs of LeafyGrass 58,84,46 and Grass 96,142,70;
- the 158x165 concrete rectangle.

There is also a 2-stud baseplate strip between the lab floor (which ends at z 71) and the yard (which starts at z 73). Every piece is a hard-edged part, so the plot reads as code-laid tiles in different greens. *Evidence:* Landscape.luau:20,57; LabGarden.luau:24,97; LabCreatures.luau:704; CreatureHabitats.luau:86,158; Lab.luau:707 *Fix:* Use one terrain ground per plot: paint Grass, Ground and Concrete/Asphalt regions with terrain blends plus MaterialService grass decoration, and remove all part-grass. Habitats get a terrain material patch, not a disc.
- **[medium/medium/M] Habitats are primitives next to PBR models, and the water is blue glass.** - The spider's dead trees are 1.6x30x1.6 Wood blocks with block branches.
- Cocoons are balls, reeds are 0.18-stud sticks, lily pads are SmoothPlastic discs.
- Mole hills are Ball parts of Ground.
- The whale pool is a 30x1x20 Glass slab, and the frog pond is Glass discs.
- The clothes on the line are flat rectangles.

Next to the Roblox Forest Pack trees, these read as placeholders. *Evidence:* CreatureHabitats.luau:90-100,133,140-147,190-199; LabCreatures.luau:407,448,603-605 *Fix:* Use terrain water for the pond and pool. Take the dead tree, reeds, lily pads and logs from the Forest Pack already in use. Cut the rug, clothes line and cocoons. Run a silhouette test at 30-40 px (vault, Environment Art Styles).
- **[medium/high/S] Noon light, grey grade and heavy air flatten the scene, worst on phones.** LOOK_V3_LIGHT: ClockTime 13, Brightness 2.2, saturation -0.05, contrast 0.05, bloom 0.1, Atmosphere density 0.3, haze 0.4, offset 0.1. Noon gives short overhead shadows and little shape. art/maps/Lab.jpg and Island.jpg show hills fading into grey-blue at about 200 studs.

Vault (Stylized Lighting Recipes): phones below quality 4 have no shadows, so contrast must come from colour shift and ambient tint. Our grade removes colour instead. *Evidence:* Config.luau:197-216; ZoneLighting.luau:204-249; art/maps/Lab.jpg, art/maps/Island.jpg *Fix:* Target values:
- ClockTime about 15-15.5, with the key light across the spawn view;
- ColorShift_Top warm (255,236,210), OutdoorAmbient slightly cool;
- saturation +0.08 to +0.12, contrast 0.08-0.12;
- Atmosphere density about 0.2, haze 0.15 or less, offset about 0.25.

Tune on the phone emulator at quality 1-3 and pass the greyscale test.
- **[medium/medium/S] The lab is silent.** The only ambient loop in the world was the birdsong in Client/Birds, and BIRDS is now false. Playground, LabCreatures, LabGarden and CreatureHabitats create no Sound at all, and CreatureHabitats even deletes the sounds that came with the models. SOUND_MIX keeps an Ambient group at 0.5 with nothing in it. Between events, the wrecking ball, mace, lava, fan, fountain and nine 'alive' creatures make no noise. *Evidence:* Birds.luau:464-468; Config.luau:165,190; CreatureHabitats.luau:69; grep shows no Instance.new('Sound') in Playground/LabCreatures/LabGarden/CreatureHabitats *Fix:* Add one outdoor bed (soft wind and a distant park, no music). Add positional loops on the hero machines (gantry creak, mace whoosh, lava bubble, fountain) and creature idle one-shots from a voice pool, in SoundMix Ambient/World with rolloff of 40 studs or less. Follow the vault's Ambient Soundscapes rules: one player per bed asset, random start offsets.
- **[medium/low/S] Hazard stripes and double rims everywhere.** Each station has a square yellow/black hazardRim and also a round yellow/black pedestal rim: two frames round one Neon block. On top of that:
- the cannon pedestal has a rim and the lava a block rim;
- the tower has yellow stair edges and a yellow/black top band;
- the ramp has yellow rails and the wrecking-ball run is striped.

When everything wears hazard stripes, the stripes stop meaning 'this throws you'. *Evidence:* Playground.luau:768 (hazardRim on stations), :964 (pedestal on stations), :960 (cannon pedestal), :92-101 (stair edges, band), :571 (lava rim) *Fix:* Use one affordance language: chevrons only on launch plates and on the edge of real hazards, one rim per machine, and neutral steel or concrete for everything structural.
- **[medium/medium/S] The free trampoline is a flat blue square while the real model is sold.** The lab trampoline is an 11x0.4x11 blue Fabric slab on a dark 12x1x12 base. A real backyard trampoline was imported, but it is only used for the paid MegaTrampoline map item. SlideTower, BoxingRing, Mountain and BrickWall were imported too and are never placed, which adds weight to the place file. *Evidence:* Playground.luau:114-116; tools/ImportV3Assets.luau:47-57; MapShopService.luau:67,639 *Fix:* Use the real trampoline, with its net removed, for the free one. Delete the unused imports from V3Assets.
- **[medium/low/M] Open-air map paths are straight spokes with 4-stud block edges.** PathBuilder.map paints the terrain stone by stone with Region3:ExpandToGrid(4), along PathPlan.curve lines that bow at most 4 studs. The paths run from the arrival to every launcher and to every shop booth, so each map gets a fan of near-straight spokes with stair-stepped edges, several of them leading to paid booths. Where there is no terrain (city streets, plaza floor), flat cobble discs are laid on the asphalt. The V7 State still lists this as open after 3 rounds. *Evidence:* PathBuilder.luau:109 (ExpandToGrid 4), :140-175 (targets include booths); PathPlan.luau:14 (BOW 0.08, max 4); docs/V7_PLAN.md State *Fix:* Use spline paths resampled by arc length, with terrain carve plus fill below (vault, 'Roads, Rivers and Paths Carved Along Curves in Terrain'). Lead them to activities only, not booths, and lay nothing on the city streets.
- **[low/low/S] Habitat props sit on the walks, and the chicken coop faces the wrong way.** - The frog pond's rim rocks (radius 10 round (-89,-5)) reach x ≈ -98.5 to -100.2, which is on the west garden walk (x -97.7 to -101.9).
- The pond itself (x -99.5 to -78.5) crosses the lab floor edge (-79) and the Neon plot line (-80).
- At yaw 90 the chicken run looks toward -X, so its closed rail and hen house face the lab. The comment says the opposite ('the front stays open toward the lab').

All of these are pictures only, so players walk through the rocks. *Evidence:* LabCreatures.luau:684-686 (Frog -89,-5; Chicken 90,-8 yaw 90); CreatureHabitats.luau:113-127,136-139; LabGarden.luau:91 (pathX); Lab.luau:604 (edge at ±80) *Fix:* Add the habitat and garden footprints to PathPlan.OBSTACLES and check the garden walks in T106. Turn the coop's open side toward the lab.
- **[low/low/S] The mace's sweep has no ground cue since the boxes went.** V7-1 removed the 30x30 box round the mace. Its 13.5-stud sweep at waist height ends 3.5 studs from the end of the Hub->Mace path, and nothing on the ground shows the swing area. *Evidence:* Playground.luau:646-649 (ZONE_FLOOR gate); PathPlan.luau:38 (Mace goal -10,38), :121 (Mace obstacle radius 16.5) *Fix:* Add a subtle worn ring in the ground (terrain or decal, no box, no text) and low chain posts at two points (vault, 'AoE Telegraphs').
- **[low/low/M] All 10 plots fully dressed for a 6-player server; landscape sized for 10; vacuum moved by the server.** - Lab.PLOT_COUNT is 10, with the comment 'the place's server size should be 10', but SERVER_SIZE is 6. Floor, Neon lines, owner board, crash wall, benches, 8 barriers and 8 cones are built for all 10 plots at start, and each gets 2 boards with SpotLights.
- Landscape fills terrain over ±1795 x 930 studs in 8-stud columns up to 110 high, plus 220 trees.
- The vacuum is moved by the server with PivotTo at 15 Hz, which replicates to every player.

None of this has been measured on a phone. *Evidence:* Lab.luau:76,1000-1010; LeaderboardService.luau:526-552; Landscape.luau:23-31,74-115; LabCreatures.luau:642-651; Config.luau SERVER_SIZE 6 *Fix:* Take PLOT_COUNT from SERVER_SIZE, and size the landscape for 6 plots (or use a mountain skybox past 600 studs). Move the vacuum's motion to the client, like CreatureLife. Measure with the MicroProfiler and memory stats on a low-tier phone.

**Cut or hide:** TODAY'S MACHINE yellow pill (LabZones.luau:196): it gives no reward and stays the same pixel size up to 140 studs away; NEW tags on BigButton/LabCar/LabTruck/PortalMulti (Config.NEW_IN_LAB): none of them is new in 0.25.0; Neon light-blue plot edge lines (Lab.luau:584-597): the hedges and PlotPrivacy already mark the plots; All 6 path signposts, the 'WORKSHOP' label included (PathPlan.SIGNS); keep at most one at the lab entrance; The two global leaderboards facing the spawn (LeaderboardService.buildLabBoards): move them to the plaza and hide them for newcomers; One of the two towers: the castle throw tower, or put its jump pad on the fall tower; one hero vertical only; Dead scenery unless it is made interactive: the 5 barrels, 3 crates, BigFan and rocket (LabDress.SPOTS); The lab benches by the crash wall and the 8 barriers + 8 cones down the sides (Lab.luau:723-733); Garden fountain, shed, benches, 8 street lamps and flower beds (keep the hedges and a few trees); Habitat primitives: the rug, clothes line, cocoons, reeds, lily pads and block 'dead trees'; The spider's 'HUNGRY' billboard meter; Square hazard rims under the round pedestals at the stations; The white Neon arrow on the cannon pad (the arc and bullseye already show the direction); Unused V3 imports: SlideTower, BoxingRing, Mountain, BrickWall; The sleigh ramp in the vehicle bay (move it before 1 Dec); The creature yard as it stands: keep the 4-5 best in one zone next to the dummies, or give them their own map

### F - Maps and travel (plaza, Game Arena, the 5 open-air maps, portals, server list, travel flow, usage): 3/10
The pieces exist and are fairly solid. There are five open-air maps built from Creator Store packs: Island, Downtown, Site, Farm and Army Base. The earlier audit rated their looks 7 (docs/AUDIT.md:15). There are also 11 launchers, server-checked travel, a sports-hall arena and a MemoryStore server list. As something that keeps players, the area does almost nothing:
- Each map is scenery plus 2 or 3 launch pads and a crowd. None of your own sandbox comes with you: no dummies to spawn, no machines, no events, no vehicles.
- On phones, which most players use and hold upright, PLACES is buried in MENU.
- The median visit is 120 s, and nothing in the first session points to a map.
- Travel is an instant teleport with no preloading, no loading card and no sound, while the place streams.
- The SINGLEPLAYER portal adds a loading screen to a lab that is already private.
- MAKE MY OWN promises that friends can join from their profile, which reserved servers do not allow.
- MULTIPLAYER contradicts itself and always leads to an empty list at this player count.
- The plaza, the server list, the horde-at-plaza and invites to a friend's lab all need other players, and there are none (about 15 visits a day, server size 6, while the leaders run 1-player servers).
- Nobody measures whether any of it is used. Session_v1 has no fields for trips, portals or maps.
Measured against HRR, BRP and RR, where choosing a map means choosing where your full sandbox is, this area adds clutter and loading screens more than fun.

**10/10 means:** 1. ONE MODEL, SOLO FIRST. As in HRR, BRP and RR, MAPS means choosing where your own sandbox is. Your 6 dummies, G-spawn, REVIVE/RESET, the BIG RED BUTTON, events and your lab car come along. Other players are a bonus, never a requirement.
2. 3-4 DENSE MAPS, NOT 5 THIN ONES. Each map has 5-6 signature machines that exist nowhere else. Examples:
   - Island: catapult, cliff dive, boat ram, wave machine, coconut cannon.
   - City: manhole geyser, a bus crossing the junction, a traffic-light crash test, a rooftop drop.
   - Site: crane hook, cement-mixer spin, pit jump, a wrecking ball on the crane.
   - Farm: hay slingshot, bull pen, windmill fling, silo drop.
   - Army Base: mortar, ejector seat, a drivable tank, a helicopter drop, a firing range with dummies as targets.
   Each map also has a map-only event, one badge per machine (BRP's badge funnel), a journal page and an experiment card. A map ships only when it has its 5 machines.
3. GETTING THERE. A MAPS button on every platform from the reveal on (phone included). A window of 3-4 big 16:9 screenshot cards with the name, 3 activity icons, "N players here", a MAP OF THE DAY tag and ENTER, plus Revive dummies / Back to lab.
   - At about 3-4 min, when the lab's novelty fades, one card says "NEW MAP: Tropical Island - GO" with one tap.
   - ENTER first streams the map in (RequestStreamAroundAsync). A loading card with the map's picture and a tip stays up at most about 2 s. Then a 1 s camera fly-in, an arrival sting, and the map's own ambience.
   - You land 15-20 studs from the hero machine, facing it, with your dummies standing on it and a one-line objective ("Launch a dummy off the CATAPULT").
4. IDENTITY. Each map has its own time of day and weather (warm afternoon island, overcast city with lit lamps, dusty site, golden-hour farm, clear base), its own soundscape (waves and gulls, traffic, machinery, wind and cows), natural borders instead of invisible walls, and crowds capped per device tier.
5. SOCIAL THAT WORKS AT LOW CCU. No SOLO portal and no fake private-server promise. "PLAY WITH FRIENDS" means SocialService:PromptGameInvite plus an in-game friend Join that works. A server list appears only once there are servers to list, with Quick Join as the main button. The plaza is a hub only when there are people to meet.
6. MEASURED. Session_v1 logs trips, distinct maps, seconds per map, launcher uses, portal opens and teleports. Targets: at least 40% of 5-minute sessions try a map, map visitors play 2+ minutes longer, and phone frame time stays in budget on every map.

- **[critical/high/XL] Open-air maps are scenery with 2-3 pads, not sandboxes.** Every map has 2 launch pads (the Site has 3) and a crowd of 12-18 people. None of the lab's play comes along: no own dummies, no spawning, no BIG RED BUTTON, no machines, no events, no vehicles. Playground builds the machines only for labs. The v3 plan's own bar was 'at least 25 props and 3 activities' per map. At the leaders (HRR, RR), choosing a map moves your whole sandbox there. Here a map is a walk-around diorama with 2 trampolines. *Evidence:* OutdoorMaps.luau:282-283 (City: 2 manholes), 434-439 (Site: 3), 632-633 (Island: 2), 714-715 (Farm: 2), 794-795 (Army Base: 2); Playground.luau:950-1014 (machines, BIG RED BUTTON and vehicles only `if lab`); docs/V3_PLAN.md:188 ('at least 25 props and 3 activities'); docs/V3_PLAN.md:344 (HRR Maps window: Revive dummies / Back to spawn) *Fix:* Make a map the place your sandbox is. On arrival, spawn the player's dummy set beside the hero machine (same DummyFactory/ownership path as the lab), and allow G-spawn, REVIVE/RESET, the BIG RED BUTTON and events on maps. Give each kept map 5-6 machines that exist only there (see what_10_looks_like). Reuse Playground machine builders (cannon, wrecking ball, throwOnTouch) with a map skin. Ship a map only when it has its 5.
- **[critical/high/M] The area is built for crowds the game does not have.** The plaza (the only place for hitting and grabbing other players), the shared maps, the server list, the horde at the plaza and invites into a friend's lab all need several players per server. There are about 15 visits a day, server size 6 and most servers hold 1 player. Every genre leader runs 1-player servers, and multiplayer is a separate later step. There are 8 destinations (lab, plaza, arena, 5 maps) plus solo/own servers, so the few players are split even thinner. The vault: 'Consolidate places. A lobby plus three game-mode places triples the emptiness.' *Evidence:* Config.luau:76-80 (SERVER_SIZE 6); Places.luau:37-47 (8 destinations); docs/RESEARCH_FIRST_SESSION.md:47 ('Solo servers are the norm'); Zones.luau:90-93 (grab only in the plaza); vault '27 Marketing and Growth/Rescuing a Weak Launch...' Step 3 *Fix:* Write down one model: solo first. Keep the small server, with Server Fill = Maximum on the dashboard, so the few players at least share one. Cut the SOLO portal. Cut the destinations to Lab + 3 dense maps (+ arena as a lab activity). Show presence where it is real: 'N players here' on map cards and a cross-server takedown ticker. Revisit the plaza and server list once CCU is above about 50.
- **[high/high/M] Phone players cannot find the maps, and nobody measures use.** Most players are on upright phones. There PLACES is only a MENU entry (PHONE_KEEP = Shop only). No first-session step, card or objective points to a map before the median visit ends (~120 s). The only map nudge is the daily experiment 'Get launched on any MAP'. Usage is unknown: Session_v1 stores no trip, map or portal field. Metrics sends Place events to a dashboard whose API refused our queries, and portal teleports are not logged at all. *Evidence:* HudMenu.luau:21 (PLACES phoneOnly in MENU), HudMenu.luau:56 (PHONE_KEEP = { Shop = true }); Experiments.luau:38 (MapLaunch); SessionStats.luau (grep: only `pv`, no trips/places); Metrics.luau:7 (Place_<id> only); CLAUDE.md 'Analytics API refused our query shape (400)'; PortalService.luau:122-143 (no Metrics call) *Fix:* (1) Add to Session_v1: trips, distinct maps, seconds per map, launcher uses, portal opens, teleports out; add a SessionReport column. (2) After the reveal, give phones a MAPS button. (3) At about 3-4 min, or after 4 different lab machines have been used, show a Notify card 'NEW MAP: Tropical Island' with a one-tap GO to that map's hero machine. (4) Judge the area on the numbers after 48 h live.
- **[high/medium/M] Instant teleport into an unloaded map: no preload, no transition, no sound.** WorldMaps.travel pivots the character 1600 studs up and 1400+ studs away in one frame. It never calls Player:RequestStreamAroundAsync, but the place streams (the audit counted parts 'streamed in'). The arrival flash fades in about 0.85 s and has no sound. On a phone the map pops in behind the flash, or the avatar pauses over an empty sky. A sudden colour flash is the whole transition, and the leaders' fly-in or loading card is missing. *Evidence:* WorldMaps.luau:846-848 (PivotTo, no stream request); docs/AUDIT.md:63 ('2835 parts streamed in'); PlaceMenu.luau:309-312 (0.7 s fade + 0.15 s delay); PlaceMenu.luau:260-316 (arrived(): no sound); grep: no RequestStreamAroundAsync anywhere *Fix:* On the server, pcall player:RequestStreamAroundAsync(target.Position, 5) before PivotTo. On the client, show a loading card (map capture, name, one tip) until a raycast finds the floor under the avatar (cap 3 s). Then run a 1 s camera fly-in from above onto the hero machine, a whoosh + arrival sting (SoundMix UI) and start the map's ambience.
- **[high/medium/S] SINGLEPLAYER and MAKE MY OWN are pointless or broken promises.** Labs are already private, so SINGLEPLAYER only adds a 10-20 s teleport and a reload, and the newcomer flow is skipped after a teleport. MAKE MY OWN tells players 'Your friends can join you from your Roblox profile', but reserved servers cannot be joined from a profile or by ServerInstanceId, and FriendsService.join uses ServerInstanceId. So both buttons do the same thing: they strand the player alone. Both call the legacy TeleportService:ReserveServer, which the vault lists as deprecated since Oct 2026. *Evidence:* PortalService.luau:131-133 (Solo and Own both ReserveServer); PortalUI.luau:122 (the profile-join promise); PortalUI.luau:131 ('A server just for you'); FriendsService.luau:379-382 (ServerInstanceId join); Zones.luau:77-83 (labs already private); docs/AUDIT.md:83 ('No newcomer flow after a teleport'); vault 'Joining Friends Parties and Private Servers' line 66 ('Reserved servers cannot be joined by ServerInstanceId'); vault 'Reserved and Private Servers in Practice' line 18 *Fix:* Remove the SINGLEPLAYER door and MAKE MY OWN. Replace them with one 'PLAY WITH FRIENDS' action: SocialService:PromptGameInvite, plus the friend list's Join. The Join shows 'In a private server' instead of a button when the friend's server is reserved. If private rooms come back later, use TeleportOptions.ReservedServerId (a GUID) and a short room code.
- **[high/medium/S] MULTIPLAYER portal is a dead end that contradicts itself.** At this player count the list is always empty. It then says 'No other servers right now. PLAY NOW finds you one!', but PLAY NOW in a public server answers 'You are in the busiest server already!'. When other servers exist, PLAY NOW picks the fullest OTHER server even if it is emptier than yours (no comparison with here). It can move a player from a 4-player server to a 1-player one through a loading screen. The door carries a NEW tag for 7 days, and the V7 paths lead players to it. *Evidence:* PortalUI.luau:87 vs PortalService.luau:179; PortalService.luau:61-69 (fullest: no `e.players > here`); Config.luau:183-185 (NEW_IN_LAB includes PortalMulti); docs/V7_PLAN.md:212 (paths to the portals) *Fix:* Show the door, or an un-greyed card, only when the list holds a server with more players than here; otherwise hide it. PLAY NOW only moves you to a server with more players than yours, else it says 'You're in the liveliest server'. Remove the NEW tag. Quick Join stays the main button and the rows come second (vault 'Server Browsers and Server Lists').
- **[high/high/M] You arrive in empty land, 60-270 studs from anything to do.** Arrival pads sit near the south edge facing north. Distances to the nearest launcher:
- City: the manholes are 190-270 studs away.
- Site: crane drop 213, pit jump 140, roof launch 145.
- Army Base: ejector seat about 157, mortar about 104.
- Farm: hay slingshot 130, bison toss about 60.
At 16 studs/s that is 4-17 s of walking past props before the first fun. The pad is a faint 8x8 square at 45% transparency, and the launchers are small 6-8 stud neon squares in 320-440 stud maps. The leaders put you next to the action. *Evidence:* Places.luau:42-46 (arrive 110-150 south of the middle); OutdoorMaps.luau:73-75 (8x8 pad, transparency 0.45); OutdoorMaps.luau:282-283, 434-439, 714-715, 794-795 (launcher spots); OutdoorMaps.luau:182-195 (6-8 stud pads) *Fix:* Move each arrival to 15-20 studs in front of the map's hero machine, facing it. Put the player's dummies on or next to it, with one objective line ('Launch a dummy off the CATAPULT') and a soft ground glow. Make the hero machines big, readable models, not flat neon squares.
- **[medium/medium/M] Maps have no identity beyond geometry: same light, no sound.** All five maps use the 'Outdoor' profile, which is the Lab profile plus 0.07 haze: the same sun, the same time and the same grade everywhere. No map has ambient audio. The only world loop was the birdsong in Client/Birds, now off. Travel has no sting. The HRR teardown says players there choose map, weather and time of day. *Evidence:* ZoneLighting.luau:69-70 (AIR.Outdoor = Lab +0.07; PROFILES.Outdoor = PROFILES.Lab); Birds.luau:464-468 (the only Looped sound), Config.luau:165 (BIRDS = false); docs/V3_PLAN.md:255 *Fix:* Give each map its own ZoneLighting profile and ambience. Examples: Island warm 16:30 with sea sparkle; City overcast 18:00 with lamps on; Site dusty haze; Farm golden hour; Base clear noon. Add a SoundMix 'Ambient' bed per map from licensed Creator Store audio (waves and gulls, traffic hum, site machinery, wind and cows, distant drills), faded in on arrival and ducked by blasts (SoundMix already ducks Ambient).
- **[medium/medium/M] MAPS window: tiny pictures, blurbs that overpromise, three names for one thing.** Problems with the window:
- Cards are 220x228 with a 64 px cropped picture strip, where the leaders show a real screenshot.
- Each caption ends with a crowd count ('12 people.') that means nothing to a kid.
- Blurbs overpromise: City says 'parked cars and buses' but has only a bus-stop shelter; Army Base's 'helipad' is an empty disc with an H; Farm promises 'grumpy bison' but places 'Bull' models.
- The thing is called 'Maps' on the PC HUD, 'Places' on the window, HUD button and MENU, and 'five big maps' in the caption.
- The default gamepad focus is the Plaza card.
- There is no 'N players here', no map of the day and no activity icons. *Evidence:* PlaceMenu.luau:31 (CARD 220x228), :96 (64 px preview), :113 (Crop), :216 (crowd count), :199/:225 ('Places'), :218-219 (default = card 2, the Plaza); HudV3.luau:511 ('Maps'); HudMenu.luau:21 ('PLACES'); Places.luau:43 vs OutdoorMaps.luau:255 (Bus_Stop only); Places.luau:46 vs OutdoorMaps.luau:765-770; Places.luau:45 vs OutdoorMaps.luau:704 *Fix:* Call it MAPS everywhere (window, HUD, MENU, keybind label). Use cards with a 16:9 capture at full card width, the name, 3 activity icons, 'N players here' (from the Place attribute) and a MAP OF THE DAY tag, with ENTER. Default focus on the recommended map. Rewrite blurbs to match exactly what is there, or add the missing bus and helicopter.
- **[medium/low/S] Travel from a car seat or mid-grab is not refused.** WorldMaps.refusal checks health, ragdoll state and pacing, but not humanoid.SeatPart or PlayerGrab holding/held. The map lift pads guard exactly this case ('the car or the other body would come too'). Pressing GO while driving the lab car, or while holding a player in the plaza, pivots the character with whatever is welded to it. *Evidence:* WorldMaps.luau:794-824 (refusal has no seat/grab check); MapActivities.luau:36-39 (the lift pad's check: SeatPart, holdingOf, heldByOf); VehicleService.luau:384 (seats are real VehicleSeats) *Fix:* Add the same guard to WorldMaps.refusal. When seated, get out first (humanoid.Sit = false, then travel) or refuse with 'Get out of the car first'. When holding or held, call PlayerGrab release before the trip. Add a test case to T26.
- **[medium/low/S] Plaza: a PvP square with no players, and loud signs reaching into labs 1 and 2.** The plaza is the only place where players may hit and throw each other, but most servers have 1 player. Its 'PLAZA / EVERYONE'S WELCOME' + 'You can hit other players here. Nobody gets hurt.' boards:
- stand every 256 studs along both plot edges for the whole baseplate length;
- carry text on both faces;
- sit in a Persistent model with a yellow edge line.
So they show from the first two labs on every server, against LOOK_V3's 'no shouting signs'. The plaza also repeats the lab's tower, cannon, ramp and wrecking ball. Players in labs 3+ cannot walk there through the private labs in between. *Evidence:* WorldMaps.luau:959-991 (boards, EDGE_BOARD_EVERY 256, both faces via sign() 88-110, Persistent at 979); Playground.luau:947-950, 982 (the plaza gets tower, cannon, ramp, wrecking ball); Lab.luau:535-550 (keepOut); Config.luau:141-147 (LOOK_V3 intent) *Fix:* Delete the edge boards and the long yellow line, and keep one small sign at the plaza arrival. Under the solo-first model, take the plaza out of MAPS until CCU supports it (it stays as the walk-to square for labs 1 and 2). If it stays, make it a real hub: the leaderboards, the daily map board and the horde, and no duplicate lab machines.
- **[medium/low/S] Calls to travel cannot be acted on in time (horde, invites).** The horde warning gives 10 s and says 'Open Places to go'. On a phone that means MENU, then PLACES, scroll to the Plaza, then GO, which cannot be done in 10 s. The invite toast 'Find it in Places' has no button either. A call to action with no one-tap action is noise. *Evidence:* FriendsUI.luau:402 (HORDE toast), FriendsUI.luau:386 (invite toast); HordeService.luau:30 (WARNING 10) *Fix:* Send these through Notify with an action button ('GO' = PlaceMenu.go('Plaza') / go(Places.labId(plot))). Lengthen the horde warning to 20 s. Skip the server-wide horde call for players who are alone on the server.
- **[medium/medium/M] Map crowds are not capped per device and no map was measured on a phone.** An open-air map brings in 12-18 server-run R15 bodies with real Roblox clothes and hair the moment a player comes near. DEVICE_CAPS and FX_CAPS limit only visitors, chasers and effects, not crowds. The only performance measurement is the idle lab and a 4-event lab on a PC; no map has a phone-tier number. *Evidence:* Places.luau:42-46 (crowd 12/18/12/12/14); CrowdService.luau:1456-1461 (makeZone with place.crowd); Config.luau:113-117 (DEVICE_CAPS: visitors/chasers only), Config.luau:136-140 (FX_CAPS ragdolls 14 on low); docs/AUDIT.md:61-66 *Fix:* Size each map crowd by the lowest device tier present on that map, or hide far bodies client-side (LOD: under the phone cap, only the nearest N fully drawn). Run the MicroProfiler on each map in the phone emulator. Budget each map at the lab's frame time.
- **[low/low/S] Game Arena: a sealed room with a Squid-Game-like game and a host-only score.** The arena floats as a closed hall reached only through the MAPS window. Red Light Green Light uses runners in coloured tracksuits named '001'... with you as the guard. That reads as the Netflix show, against the owner's no-brands rule. The other game, 'Shoot 'em', is described in the code as 'people stroll across... knock them down'. Only one host scores at a time, so a second player in the arena just watches. *Evidence:* MinigameService.luau:150-176 (tracksuits, PersonName %03d, Role 'Runner'); MinigameService.luau:9-15 (Shoot 'em text; host-only scoring); Places.luau:40 (Arena slot 7, a sealed room); WorldMaps.luau:540-606 *Fix:* Rename it 'Freeze!' with plain crash-test dummies and no numbers. Turn 'Shoot 'em' into 'Target Practice' with dummies on rails. Let every player in the arena score their own line. Better still, put both games into the lab or a map as stations instead of a separate destination.
- **[low/low/S] Daily goal 'Visit N places' counts the wrong thing.** The goal text says 'Visit %d places'. But only trips to slot>0 places (the arena and the outdoor maps) count. The plaza and a friend's lab never count, while going to the same map twice counts twice. A kid who visits the Plaza and a friend's lab is told nothing happened, and map ping-pong is rewarded. *Evidence:* DailyGoals.luau:20; Main.server.luau:88-93 (onTrip counts `place.slot > 0`, every trip) *Fix:* Count distinct maps per UTC day and word it 'Try %d different maps'. Pair it with the map-of-the-day card.
- **[low/low/S] Server list shows the first player's country and uses the vault's 'avoid' timings.** The 'region' column is the country code of the first player who joined that server, shown to every other server's players. It is not where the server is, and it shares a child's country for no gain. The heartbeat is 15 s and the expiry 50 s (the vault: 30/90). A comment still says players x/10. *Evidence:* PortalService.luau:344-351 (GetCountryRegionForPlayerAsync of the first player); PortalUI.luau:93 (region column), PortalUI.luau:4 ('players x/10'); PortalService.luau:31-32 (BEAT 15, EXPIRE 50); vault 'Server Browsers and Server Lists' TL;DR *Fix:* Drop the region column (or show a ping band if a server list returns later). Fix the comment. Use a 30 s heartbeat and a 90 s TTL.
- **[low/low/S] Invisible walls in open grass and sea.** Island and Farm end in invisible walls at the map's size, but the terrain runs another 120-400 studs past them. A player walks into an invisible barrier in open grass or shallow sea, which feels cheap. Site and Army Base at least have a fence. *Evidence:* OutdoorMaps.luau:62-72 (WallN/S/E/W, Transparency 1); OutdoorMaps.luau:485-486 (Island sea s+800); OutdoorMaps.luau:658 (Farm ground +240) *Fix:* Use natural borders: a buoy line plus deep water that gently pushes back on the Island, a hedge or fence with hills behind it on the Farm, all inside the walls, so the wall is never touched in the open.
- **[low/low/S] Dead code and stale paths for removed rooms and unused plots.** Leftovers from earlier versions:
- Seven indoor-room builders (Cafe, Office, FoodCourt, Market, Hangar, WhiteRoom, Metro) plus their looks and extras are still in WorldMaps but never built.
- PlaceMenu has a Hangar colour branch, and the headers of Places and WorldMaps still describe indoor rooms.
- The 'ALL LABS TAKEN' and 'A lab came free' paths can never run: there are 10 plots for a 6-player server, and Lab.luau still says the server size 'should be 10'.
This slows every future change and confuses audits. *Evidence:* WorldMaps.luau:194-536 (BUILDERS for removed rooms), 618-760 (LOOKS/EXTRAS); PlaceMenu.luau:301 (Hangar), PlaceMenu.luau:61-64 and 344-347; Places.luau:2-8; WorldMaps.luau:1-8; Lab.luau:76 vs Config.luau:80 *Fix:* Delete the unused builders, looks and extras and the Hangar branch. Rewrite the module headers to what is built. Set PLOT_COUNT from Config.SERVER_SIZE and drop the unreachable lab-taken UI (keep one fallback log line).

**Cut or hide:** SINGLEPLAYER portal door and window (PortalService.luau:329, PortalUI.luau:129-136). Labs are already private, so it only adds a loading screen and loses the newcomer flow.; MAKE MY OWN (PortalUI.luau:121-125, PortalService.luau:189-190). It is the same as solo and promises a profile join that reserved servers do not allow.; MULTIPLAYER portal and server list while there are no other servers with more players than here (PortalService.luau:330), plus its NEW tag (Config.luau:185) and the V7 path to it.; Region column in the server list (PortalUI.luau:93).; Plaza edge boards 'PLAZA / EVERYONE'S WELCOME / You can hit other players here' every 256 studs on both sides, and the full-length yellow edge line (WorldMaps.luau:959-991). Keep at most one small sign at the plaza arrival.; The Plaza as a MAPS destination under a solo-first model (it can stay as the walk-to square for labs 1 and 2). Also the plaza's copies of the lab tower, cannon, ramp and wrecking ball (Playground.luau:947-950).; Crowd count text '12 people.' on map cards (PlaceMenu.luau:216).; Blurb promises that are not built: 'buses' (City), 'helipad' (Army Base, an empty disc), 'bison' (Farm uses bulls).; Consolidate 5 thin maps into 3 dense ones: keep Island, City and Building Site (most distinct). Merge the Farm's bull pen and hay slingshot and the Army Base's mortar/ejector ideas into those three or into the lab. Re-add a map only when it has 5 signature machines.; Game Arena as a separate floating room. Move Freeze/Target Practice into the lab or a map as stations, and drop the numbered-tracksuit runner look.; The 'Visit %d places' daily goal in its current form (DailyGoals.luau:20).; Dead code: the 7 removed-room builders and their looks/extras in WorldMaps, the Hangar branch in PlaceMenu, the unreachable 'ALL LABS TAKEN' / 'lab came free' UI, and the 4 plots never used at server size 6.

### G-npcs: dummies, mannequins, crowds, behaviours (flee/talk/follow), greeter, chasers, visitors, creatures: 4/10
The core under the skin is strong. ActiveRagdoll gives flinch, stumble, noodle limbs, limping, crawling, out cold and getting up, which matches what the leader is praised for (HRR: a leg shot limps, a broken leg crawls, a head hit faints). DummyLife also gives faces, blinking, looking at bangs and dizzy stars. Most of that never reaches the player who matters: a phone player holding the phone upright, in a visit of about 120 s.

What that player sees:
- Six identical white mannequins stand in a fixed 70-degree arc 22 studs away. Their faces come out at roughly 5-10 px on a phone.
- After the first shot, 5 of the 6 run off at almost the player's own speed.
- The greeter walks up silent.
- Nothing has a voice.
- The personality layer (HI!, HEY, HA!, Zzz, the panic '!', chat dots) is dead code under LOOK_V3.
- A "Talk / Dummy" prompt sits over every target.
- The nine lab creatures are 80-115 studs away, out of view. They only take dummies the player has to carry over, and they make no sound.
- The chase arrives at 100 s with invisible punches draining an HP bar, slow chasers and a "LEFT" counter that does not count.

The crowds on the maps are sparse (12-18 people on 320-440 stud maps) and simulated on the server. They are dressed as realistic people, and the hit line says "DEAD / no pulse", which fights the all-ages goal.

Against HRR's labelled dummy types, bystanders who beg and talk about their injuries, G to spawn and R to revive, and dummies that fight back, this area is about a 4. The audit's 7 was generous.

**10/10 means:** **At spawn (frame 1):** three dummies stand 12-14 studs ahead, clearly different and labelled on a chest plate: STANDARD, HEAVY and BOUNCY. Behind them is one at the cannon queue and one on the tower top. The orange greeter walks in from the side, waves, and says one short line ("Hi! I'm padded - hit me!"). Every hit gets a reaction within 100 ms, through:
- the body (the physics we already have);
- a kid-safe cartoon voice (whoa, oof, wheee), with up to 2 voices at a time;
- at most two short barks on screen, which escalate with what happened: flying, grabbed, cannoned, frozen, lost a bolt, revived, saw a friend fly.

**Personalities read inside 10 s, each through one signature act:**
- the single coward bolts in a zigzag;
- the brave one marches up and slaps you, a harmless ragdoll (the leader's dummies fight back);
- the clown laughs and dances after a hit;
- the sleepy one dozes (Zzz) until it is woken by a bang.

**Lab life:**
- Visitors walk in through a gate and show each machine and creature in view during the first minute.
- Three creatures live within 40 studs of spawn. They also grab players: the frog's tongue gets YOU, the whale geysers YOU.
- Every creature has its own sounds and smooth client-side motion. A carried dummy shows an arrow to the nearest hungry creature.

**Player verbs:** G (a phone +DUMMY button) drops a dummy of a chosen type at the aim point, within the device's ragdoll cap. R revives the one under the crosshair. Unlocking new dummy types is a second progression track beside weapons.

**The chase:**
- It comes after 5 minutes or 15 takedowns, never earlier, and is telegraphed by a siren and chasers bursting through a gate in view.
- Two chasers come first. Their punches show a wind-up pose and a whoosh, and three hits throw you.
- Each chaser knocked down once is out and sits dizzy. The counter is honest and it ends in a celebration.

**Map crowds:**
- They stand in clusters of 4-6 at the arrival pad and the activities.
- When panicked, some run, some cower and beg, some hide behind props and some call for help on a toy phone.
- They have injury and recovery barks by body region and a cartoon look that matches the mannequins.
- The hit line says KO, never DEAD or pulse.

**Measured live:**
- more than 90% of newcomers knock down 3 dummies in 60 s;
- more than 80% see a bark in minute one;
- more than 40% use a creature in the first visit;
- the chase is cleared more often than it times out;
- the NPC tests (T19, T25, T32) are deterministic and no longer flaky.

- **[high/high/S] The personality presentation is dead code under LOOK_V3.** DummyLife draws the old bubbles only when LOOK_V3 is off; with LOOK_V3 on, only the black line box is drawn. That kills every personality signal:
- the greeter's HI!;
- the Grumpy person's HEY;
- the Clown's HA!;
- the Sleepy person's Zzz;
- the Chicken Spell's BAWK;
- the red panic '!';
- the dots of two people chatting.
CrowdService still runs Coward, Brave, Grumpy, Clown and Sleepy traits, but they only change timings no player can see. In the lab, the 'Chatty' pair walk out and face each other with nothing shown. *Evidence:* DummyLife.luau:1187-1191 (LOOK_V3 calls only updateLine, never updateBubble); DummyLife.luau:870-1006 (all the bubble kinds); DummyLife.luau:63 BUBBLES=false; CrowdService.luau:24-28 and 119-126 (traits); Lab.luau:412-440 (chat pair, the 'Chatting' attribute) *Fix:* Fold the bubble kinds into the LOOK_V3 line box as one-word barks with their own colour:
- HI! green;
- HEY! orange;
- HA! yellow;
- Zzz blue;
- '!' red.
Tie each one to its trigger (greet, angry, laugh, doze, panic) and keep one shared cap of 2 per screen. Give the chat pair alternating short lines from DummyLines.PLACE. Then delete updateBubble.
- **[high/high/S] 5 of 6 lab dummies run from every shot, almost as fast as the player.** Lab.heard sends every dummy but the Brave one running (Friendly and both Chatty included) from any shot within 30 studs.
- The row is 22 studs from spawn, so the very first shot at the greeter scatters the row away from the player.
- ActiveRagdoll also runs from a fired gun within 9 studs. A dummy hurt in the last 8 s runs from anyone within 15 studs.
- FLEE_SPEED is 15 studs/s; the player walks at 16.
- After running, a coward stays wary of its home for 20 s while a gun points there.
The start bar is G17, Grab and Punch. Punch and Grab need you to get close, so after the first hit the targets keep running out of reach. On a phone held upright, with a thumbstick, this is chasing chickens. The personality design has collapsed into 'everyone flees'. *Evidence:* Lab.luau:54 (PERSONALITY), Lab.luau:66-70 (SCARE_SHOT 30), Lab.luau:509-510 ('every one but the brave runs'); ActiveRagdoll.luau:901-907 and 1034-1038 (Personality ~= 'Brave'); Ragdoll/Config.luau GetAbout FLEE_SPEED 15, FLEE_RADIUS 15, FLEE_MEMORY 8; ActiveRagdoll.luau:179 GUN_WARY 20; RESEARCH_FIRST_SESSION.md:187 ('Must NOT happen: dummies fleeing out of reach') *Fix:* Make exactly one Coward per lab. It runs in the comic zigzag at 10 studs/s for 2 s.

Everyone else reacts where they stand:
- hands up, cower, duck;
- the scared face;
- a fear bark.

Drop the 'hurt + approached' flee except for the Coward. Set GUN_WARY to 5 s. Nobody flees in a newcomer's first 60 s (read NewcomerUntil).
- **[high/high/M] The spawn row is too far, too static and too uniform.** There are six dummies on an arc of radius 22 studs, 70 degrees wide (about 5.4 studs apart), all facing spawn. They never wander. Nothing stands at a machine.
- Our own research asks for 2-3 dummies 10-15 studs ahead.
- The leader has many wandering dummies, and dummies placed at each station (Pin Wall, Gravity Chamber, Vehicle Impact Zone).
- V3_PLAN planned 'idle wander for every free dummy'. It was never built: there is no wander in the lab code.
The lab core is 170x170 studs, with up to 7 bodies on a phone, all within 25 studs of spawn. *Evidence:* Lab.luau:45-46 (DUMMY_COUNT 6, RADIUS 22), Lab.luau:141-148 (slotPosition arc); RESEARCH_FIRST_SESSION.md:175 ('facing 2-3 standing dummies 10-15 studs ahead'); V3_PLAN.md:85 and 140 (wander planned); grep 'wander' finds no lab-dummy code; allthings.how/?p=358267 (HRR dummies at the Pin Wall, Gravity Chamber and Vehicle Impact Zone) *Fix:* Put 3 slots at 12-14 studs in a loose cluster in clear view. Move the other 3 into 'machine slots':
- one waiting in the cannon queue;
- one on the tower top;
- one by the bullseye.
Give each a 6-10 stud idle-wander leash (pick a spot, walk, stand 3-8 s) by moving Home, the way CrowdService already does. Lab.rewind still resets them.
- **[high/high/M] There are no dummy types or variety; every dummy is the same rig.** DummyFactory builds one fixed body: SCALE width 0.7, depth 0.75, head 0.95, bodyType 0.7, then HEAD 0.86, with the same physics tuning for every body. The only differences are colour on the greeter, visitors and chasers. The leader's main attraction is a test range of eight labelled types:
- STANDARD, HEAVY, LIGHTWEIGHT, STIFF;
- FLOPPY, GRIPPY, BOUNCY, STEADY.
Each reacts differently to the same shot. Ours only shows size variety in the paid GiantDummy event. *Evidence:* DummyFactory.luau:35-55 (one SCALE), DummyFactory.luau:262-340 (spawn: no type parameter); allthings.how/?p=358267 (HRR's 8 labelled types); Events GiantDummy and DummyRain only *Fix:* Add a 'type' parameter to DummyFactory.spawn:
- MINI (0.6 scale);
- HEAVY (wide, mass x3, slow get-up);
- BOUNCY (high elasticity via CustomPhysicalProperties, a boing on landing);
- FLOPPY (Tone strength low);
- STIFF.
Each shows a stencilled chest plate (one SurfaceGui, client-side, like the DETAILS rings). Put one of each in the lab. Unlock new types and hats as rewards: a second progression track that costs no weapon balance.
- **[high/high/M] The dummies have no voice.** SoundManifest has hit, land, whoosh, gun and blast banks, but no vocal bank of any kind for bodies, and DummyLife plays no sound. Slapstick is half audio, and the leader's bystanders 'describe their wounds aloud'. A silent mannequin that flies 80 studs reads as a physics demo, not a joke, and makes weak TikTok clips. The project already uses licensed Pro Sound Effects vocals for the gorilla and bull, so kid-safe cartoon vocals are available. *Evidence:* SoundManifest.luau (bank list lines 29-218: no voice, yelp, grunt or oof bank; a grep for voice/scream/oof/groan matches nothing for bodies); CreatureAnim.luau:26-27 (Pro Sound Effects vocals already in use); allthings.how/?p=358267 (injury speech) *Fix:* Add 4 vocal banks, each with 3-5 cartoon (non-gory) variants:
- launched: 'whoa', 'wheee';
- hard landing: 'oof';
- getting up: a grumble;
- aimed at or grabbed: a yelp.
Vary the pitch by each dummy's Seed (0.85-1.25) and play at most 2 voices at once, through SoundMix in its own 'voice' group with a phone volume ceiling. Trigger them from the same state changes DummyLife already reads.
- **[medium/medium/S] The faces carry the emotion but are too small to read on the main device.** Mood is shown by a 256 px face sticker on the front of a head shrunk to 0.86 x 0.95 of the usual size. The row is 22 studs away and the camera sits behind the shoulder, so the face is about 34 studs from the camera.
- Phone held upright (414x814, vertical FOV 70): about 17 px per stud, so the face is roughly 10 px. This is an estimate.
- Phone held sideways (about 390 px tall): about 5 px.
The owner's rule (10 Nov) was 'faces and bodies show what they feel'. The faces cannot do that at phone distance. *Evidence:* DummyFactory.luau:34 (HEAD 0.86), DummyFactory.luau:96-125 (face SurfaceGui, CanvasSize 256); Lab.luau:46 (RADIUS 22); task data: most players are on phones held upright at 414x814 *Fix:* Close the distance first (see the spawn-row finding). Then:
- give lab mannequins a head scale of 1.0-1.1, a cartoon proportion that reads as funnier;
- on big moments (launch, KO, hands up), pop the face to 1.3x for 0.4 s;
- add pixel-constant BillboardGui icons for the states that matter (sweat drop when aimed at, spiral eyes when KO, stars) that stay readable at 40 studs.
- **[medium/high/S] Too few lines, and the biggest moments say nothing.** The lines are:
- FEAR: 10, only when the hands go up (a gun within 14 studs);
- OUCH: 8, only after getting up, with a 45% chance;
- IDLE: 12, plus 6-8 per map.
Nothing is said while flying, while grabbed, in the cannon, in a creature, frozen, with a broken bolt, when revived, or when seeing another dummy fly. The leader's bystanders beg ('Why are you aiming at me?!'), describe their injuries and give recovery lines ('What was that for...?'). The vault rule for barks is 3-8 words, 3-5 variants per trigger, and react to state.
Two lines refer to things that are not there:
- 'Who left the tank there?' (the lab has no tank);
- 'hot cocoa' on the plaza in November. *Evidence:* DummyLines.luau:12-45 (lists), 42 (tank), 56 (cocoa), 120-125 (HOLD 2.6, OUCH_CHANCE 0.45); DummyLife.luau:1079-1113 (only Fear, Ouch and Idle triggers); the vault's 'Writing Dialogue for Roblox Players' section 7 (barks); allthings.how/?p=358267 *Fix:* Add these trigger lists to DummyLines, 5 variants each, kid-safe:
- Fly ('WHEEEE!', 'I can see my house!');
- Grabbed ('Put me DOWN!');
- Cannon ('Not the cannon again!');
- Creature ('This frog has no manners!');
- Frozen ('B-b-brr!');
- Bolt ('My bolt! Where's my bolt?');
- Revived ('I'm back, baby!');
- Witness ('Did you SEE that?!');
- Weapon-aware ('Is that a NUKE?!').
Use priority Fly > Grabbed > Fear > Ouch > Idle, with the shared on-screen cap. Tie lab idle lines to the props that exist (LabZones), and gate season lines by Christmas.active.
- **[medium/low/S] Fear lines have no cap and are wide on a phone.** IDLE_MAX (2) only limits idle lines. Every dummy whose hands go up shows its own yellow box, 300x34 px, 18 px text. A player 10 studs in front of the row points the gun at all six at once (a 40-degree aim cone, 14-stud reach, dummies about 5 studs apart), so up to six overlapping boxes appear. On a 414 px phone held upright, one box already takes 72% of the width. The leader shows one small box with a gun icon. *Evidence:* DummyLife.luau:1033 (Size 300x34), 1062 (TextSize 18), 1079-1084 (Fear shows with no cap), 1105 (cap on Idle only); GunThreat.luau SCARE_REACH 14, AIM_CONE 40 degrees; V3_PLAN.md:85 (the leader's box has a gun icon) *Fix:* Show one Fear line per screen, from the nearest aimed dummy. The others get a small yellow '!' icon. Add the gun icon at the left of the fear box. Cap the box at 60% of the screen width on a phone held upright, and keep at most 2 lines of any kind on screen.
- **[medium/high/S] The greeter, the first five seconds, walks up silent and then poofs away.** GreeterService spawns an orange-shirted dummy that walks to 8 studs in front of the player. It never gets GreetUntil, so it does not wave, and under LOOK_V3 there is no HI! anyway. Idle lines are held for newcomers. Twelve seconds after its first hit it vanishes in a white puff, after 45 s at most. The player's first friend disappears without a reason. *Evidence:* GreeterService.luau:131-150 (orange shirt, Home in front, no GreetUntil), 160-176 (STAY_AFTER_HIT 12, GREETER_LIFETIME 45, goAway poof); DummyLife.luau:1103-1106 (no lines while NewcomerUntil); Lab.luau:456-457 (only the Friendly lab dummy gets the wave) *Fix:* Set GreetUntil when the greeter arrives, so it waves with the existing pose. Show one line ('Hi! I'm padded - hit me!'), allowed during the quiet start: the objective line still carries the instruction. Give the first hit a big reaction (voice plus 'WOW! Again!'). Then the greeter walks off to join the row as a seventh dummy instead of poofing.
- **[high/high/M] The lab creatures are out of view and out of reach, and only take dummies.** Nine creatures sit at x +-90, z -70 to +98. The dummies stand around z -22, x +-12, so each creature is 78-115 studs from the dummies and behind or beside the camera at spawn.
- Triggers only look in Workspace.Dummies. A player walking up to the frog, whale or spider gets nothing.
- Visitors never go to them: their SPOTS are the cannon, station, trampoline and lava.
- The vacuum loops through an empty yard.
- The experiment cards give 120 s to carry a dummy there, and nothing points the way.
In a 2-minute visit, a newcomer most likely never sees one work. *Evidence:* LabCreatures.luau:32 (YARD_Z 92), 681-691 (LAYOUT), 110-131 (dummiesIn: Dummies only), 637-660 (vacuum loop); VisitorService.luau:24 (SPOTS); Experiments.luau:40-48 (120-150 s cards); Lab.luau:141-148 (row position) *Fix:* 1. Let creatures take players too, cartoon-style through PlayerRagdoll.knock: the frog's tongue pulls YOU and spits you, the whale geysers you, the spider wraps you. This is the 'ride the machine' verb FirstVisit already teaches.
2. Add the creature triggers to the visitors' SPOTS, so visitors show each creature working.
3. Move the 3 best creatures into the 40-stud ring around spawn and hide the rest (see the cut list).
4. While the player carries a dummy, show a soft arrow or glow toward the nearest creature that wants one.
- **[medium/medium/M] The lab creatures are silent, and their motion is driven by the server.** LabCreatures and CreatureLife play no sound at all. A chomping plant, croaking frog or clucking hen with no audio feels dead, and the gorilla and bull do have roars and snorts.

The swallow-and-spit motion runs on the server: PivotTo on anchored models every Heartbeat, and the vacuum loops at 15 Hz in every owned lab. Anchored CFrame changes reach clients without interpolation, so the motion is likely to look steppy on phones, and it costs replication per lab. *Evidence:* A grep for Sound in LabCreatures.luau and CreatureLife.luau matches nothing; LabCreatures.luau:88-99 (play() on Heartbeat), 637-652 (vacuum PivotTo at 1/15 s); CreatureAnim.luau:26-27 (gorilla and bull sounds) *Fix:* Give each creature 2-3 sounds: an idle sound (ribbit, cluck, hum) and a work sound (chomp, slurp, splash, spin), routed through SoundMix. Move the swallow and spit animation to the clients: the server sends a single 'Work' event with the start time and the body, the clients tween the model (as CreatureLife already does at idle), and the server only holds and pushes the body.
- **[high/medium/M] The chase has invisible punches, slow chasers, a broken counter and arrives too early.** Damage is applied whenever a chaser is within 4.5 studs. There is no punch pose or sound; only the HUD bar shakes. The Role 'Charging' is set but never read.
- Chasers walk at 7 x 1.35, about 9.5 studs/s, against the player's 16.
- MAX_HP is 100 at 4 per hit, so it takes 25 invisible hits to go down.
- ChaseLeft is recounted only on a new knock-down and never goes back up when a chaser stands. 'Cleared' needs every chaser down at the same moment, so most chases likely end in 'They gave up the chase!' (check the Chase_* metrics).
- The text is 'NPC CHASE · HP 96 · 3 LEFT' with an emoji, which is developer jargon.
- Chasers spawn on a ring of 34 studs, some behind the player, with no telegraph.
- It starts at 100 s for newcomers, inside a median 120 s visit, against our own research rule of 'a weak first enemy'. *Evidence:* ChaseService.luau:30-42 (CHASE_MIN 4, MAX_HP 100, HIT_DAMAGE 4, FIRST_AFTER 100), 132 (the notice), 134-146 (ring spawn, Pace 1.35, Role Charging), 150-163 and 193-195 (the counter), 196-205 (invisible damage); a grep for 'Charging' finds it set only; ChaseHud.luau:88; RESEARCH_FIRST_SESSION.md:254 *Fix:* **Counting:** each chaser knocked down once is out. It sits dizzy and then poofs, so the counter only goes down.

**Start:** first chase after 300 s or 15 takedowns, with 2 chasers.

**Telegraph:** a siren and 'THEY'RE COMING!', then the chasers burst through a gate in view over 3 s.

**Punches:** a visible wind-up pose (a DummyLife arm pose keyed on a 'Swing' attribute) and a whoosh. Drop the HP bar: three hits throw you.

**Speed:** Pace 1.8, about 12.6 studs/s, so it is a chase.

**Ending:** a celebration pop when cleared. Then measure Chase_Cleared against Chase_Time.
- **[medium/low/S] The colour language collides.** Colours mean too many things at once:
- greeter: orange (255,140,40);
- visitors: orange (255,170,40), blue, or green (120,220,110);
- dead: whole-body green (96,196,84);
- chasers: red torso and arms.
A green-shirted visitor reads as half dead, and an orange visitor reads as the greeter. Nothing tells a player that red means 'coming for you' until it hits. *Evidence:* GreeterService.luau:21; VisitorService.luau:25; VitalsService.luau:626 (DEAD_GREEN); ChaseService.luau:142-146 *Fix:* Use one rule:
- white = test dummy;
- orange = only the greeter;
- red with an angry face = after you;
- a yellow cap or hat = visitor (never green);
- green = never on a living body.
Check it in a line-up capture.
- **[medium/medium/S] A 'Talk / Dummy' prompt sits on every target from second one.** Every lab dummy and crowd person gets a ProximityPrompt ('Talk', key E, 9 studs, hold time 0) whenever you walk up to punch it. Lab dummies have no PersonName, so the prompt reads 'Dummy' and the ATTACK WHO? list reads DUMMY, DUMMY, DUMMY. The prompts are hidden only in the lab view and in Build, not during a newcomer's quiet start. On touch screens the prompt is a tappable button over the target, so a tap meant as a shot can open a menu. The leader puts Talk on a hotbar slot instead of on floating prompts. *Evidence:* NpcCommand.luau:353-371 (prompt settings), 365 and 401 (the 'Dummy' fallback); a grep for PersonName shows it set only for crowd, chaser, horde and minigame bodies; NpcTalk.luau:175-182 (visibility); V3_PLAN.md:330-331 (HRR has a 'talk' icon slot) *Fix:* Name the lab dummies (Bolt, Patch, Dent, Crash, Rivet, Bumper). Set HoldDuration to 0.35 and RequiresLineOfSight to true. Hide the prompts until NewcomerUntil and while a gun or melee tool is out. The best version is a TALK tool slot, like the leader's, so no prompts float during play. Move 'Attack...' behind 10 minutes of play.
- **[medium/medium/L] Map crowds are sparse, simulated on the server, and dressed as realistic people with medical 'death' text.** There are 12-18 people on 320-440 stud maps (Island 12 on 360, City 18 on 440), so the maps read as empty. The server simulates the crowd, so a shot or punch on a person waits a network round trip, unlike the lab dummies the client owns. The people have realistic skin tones, real names (Priya, Omar, Fatima), real clothes and roles (Soldier, Guard). Even with MILD_TEXT, the hit line says 'no pulse' and 'DEAD'. Shooting realistic civilians with near-real guns works against the owner's plan to redo the maturity questionnaire for all ages. Their panic is one behaviour (run). The leader's bystanders run, beg, call for help on phones, talk about injuries, and talk again after a Med Kit. *Evidence:* Places.luau:42-46 (crowd counts and sizes); CrowdService.luau:17-19 ('The server simulates the crowd'), 89-106 (skin, names), 1137 (spawn with no owner); HitInfo.luau:89-105; CLAUDE.md v3 maturity note; allthings.how/?p=358267 *Fix:* Group crowds in clusters of 4-6 at each map's arrival pad and activities instead of spreading them. Add panic variety:
- cower and beg (a Fear line);
- hide behind the nearest prop;
- 'call for help' with a toy phone pose.
Add injury and recovery barks by body region. Change the HitInfo wording to 'KO!' and 'Knocked out', with no pulse or DEAD. The owner should decide on cartoon-izing the crowd (mannequin skin plus role hats), which would also match the lab look.
- **[high/high/M] No way to spawn or revive a dummy where you aim.** There is no spawn-a-dummy action anywhere in the code. SandboxService has only SlowMo, Revive-all and Reset, and the sandbox column is PC only (in MENU on phones). The leader's HUD prints 'G Spawn, R Revive, V Scan', and G-spawn is its core sandbox verb. Players cannot set up their own scenes (a dummy on the tower, one in the cannon, ten in a pile), which is where clips and long sessions come from. *Evidence:* A grep for SpawnDummy or spawnDummy finds nothing; SandboxService.luau:20 (GAP actions); allthings.how/?p=356463 ('Press G to spawn a target'; R revive); RESEARCH_FIRST_SESSION.md:68-70 *Fix:* G, a phone '+DUMMY' button and a pad D-pad entry drop the chosen dummy type at the aim point, raycast to the ground. Give it a short cooldown. Extra dummies are capped by DEVICE_CAPS: on a phone 14 ragdolls minus the 12 used leaves about 2, more on PC. The oldest extra one poofs. R revives the body under the crosshair. Validate on the server (own lab, distance, rate).
- **[high/high/M] Personalities exist only as names: nobody fights back, laughs or dozes in the lab.** The six lab personalities are Brave, Coward, Friendly, Chatty, Chatty and Coward, and they look identical. Behaviour separates them only by who greets and who chats; everyone except Brave flees. Brave shows a Grumpy face when a gun is near, which is unreadable at distance. The leader's dummies 'aren't passive': they stumble, fight back and get up on their own. Fighting back (harmless and funny) is the strongest 'alive' signal a ragdoll game can give. *Evidence:* Lab.luau:54, 456-484 (social), 509-510 (flee); DummyLife.luau:845-846 (Brave grumpy face); allthings.how/?p=356463 ('Dummies also aren't passive... fight back') *Fix:* Give each personality one signature act, visible inside 10 s:
- Brave marches up after being hit and gives a slap that ragdolls the player (no damage, 8 s cooldown, never on a newcomer's first 60 s);
- Clown laughs (HA!) and dances after any knock;
- Sleepy dozes (Zzz) until a bang wakes it with a jump;
- Coward bolts.
Use a hat or accessory per personality (from V3Assets or Creator Store, no brands) so they read at distance.
- **[medium/medium/S] Visitors pop in and out with no staging for a newcomer.** Visitors spawn every 4 s from the very first second the player is in their lab: they appear standing near or behind the spawn, with no entrance. They pick a random machine. They are Destroyed with no puff when the player leaves the lab. They are 'Brave', so they ignore guns. Their real value (showing what each machine does, without text) goes to waste because it is random and often out of view. *Evidence:* VisitorService.luau:100-128 (spawn at center plus random, Brave, shirt), 66-72 (Destroy on clear), 153-170 (fill every 4 s, no newcomer gate), 55-64 (random pick) *Fix:* For a newcomer, the first visitor walks in through the lab gate at about 20 s and goes straight to the cannon, in front of the camera: a demo for the FirstVisit cannon step. Later visitors queue at the machine named by the current objective or experiment card. Add a puff on leave. Visitors react to guns like everyone else (hands up), because Brave reads as broken.
- **[low/low/M] The NPC brain carries three of the six known-flaky tests.** T19 (DummiesGetAbout), T25 (Crowd) and T32 (NpcLife) are on the flaky list. T32 once failed on a real live bug: a coward stuck at the rim of the lava. Flaky NPC tests hide real NPC regressions in exactly the area being rebuilt. *Evidence:* CLAUDE.md, Tests: 'Known flaky: T15, T19, T24, T25, T27, T32'; V7_PLAN.md:288 and 341 (the T32 lava bug) *Fix:* Split the brain decisions (flee choice, home steering, avoidDummies, clearRun) into pure functions with seeded Random and test them off-line (lune), as was done for PadMap and NotifyRules. Keep one short live smoke test per behaviour with longer, fixed timeouts. Then take T19, T25 and T32 off the flaky list.
- **[medium/low/S] Dead means lime green, 'DEAD', 'no pulse' and bodies that lie 60 s.** A killed body turns solid green with shut eyes and the hit line says DEAD or 'no pulse'. Lab dummies come round after 10 s. Crowd and event bodies lie out the full DEAD_HOLD of 60 s, up to 16 of them (MAX_CORPSES). For an all-ages, kid-safe pivot, lingering green bodies and pulse-and-death wording are the wrong signal. They are also unclear: is it dead, a zombie, or a visitor in a green shirt? *Evidence:* VitalsService.luau:65 (DEAD_HOLD 60), 623-626 (REVIVE_AFTER 10, DEAD_GREEN), 690 (MAX_CORPSES 16); DummyLife.luau:810-813 (the dead face); HitInfo.luau:101-105 *Fix:* Replace 'dead' with a cartoon KO:
- spiral eyes, stars and a small halo or ghost puff;
- the body greys out slightly;
- it gets up after 5 s with a 'revived' bark.
Crowd and event bodies poof after 15 s. The wording is 'KO!' only. This is the owner's call: he chose green on 10 Nov.

**Cut or hide:** Client/NpcGlow.luau: dead under LOOK_V3 (it returns at line 32). Delete the module and its start call.; DummyFactory giveMarks, MARK_FACES, SUITS and suit(): dead under LOOK_V3 with WORLD_V2 false (DummyFactory.luau:126-260 and 292-297). DummySkins.DETAILS replaced them. Delete.; DummyLife updateBubble and BUBBLES: fold its kinds into the line box (see finding 1), then delete the old renderer (DummyLife.luau:870-1006).; NpcCommand 'Attack...' (pick a target and one of your weapons): a deep menu few find, during combat. Hide it until 10+ minutes of play, or cut it. Keep Follow and Stay, ideally as a TALK tool slot instead of a prompt on every body.; Talk prompts for newcomers: hide them on every body until NewcomerUntil, and while a weapon is out.; HordeService (every 600 s): never reached in a 2-minute visit. It overlaps the chase and costs up to 18 bodies. Merge it into the reworked chase as the 'big wave' variant, or cut it.; 6 of the 9 lab creatures (keep the 3 best near spawn, e.g. the frog, giant plant and whale). Washer, vacuum, mole, chicken, slingshot and spider sit 80-115 studs out of view and add build cost and server motion. Hide them until creature use is measured.; The chase for newcomers before 300 s or 15 takedowns (FIRST_AFTER 100 now).; Crowd role data for removed rooms: SHIRTS and the Chef, Cashier and Traveler roles are no longer used by any place in Places.list.; Medical vitals wording on NPCs in the main hit line ('pulse 118', 'no pulse', 'DEAD'); keep it only inside the optional dead monitor if anywhere.; Idle lines about things that are not there ('Who left the tank there?') and season lines out of season ('hot cocoa' in November).

### H-social: social and multiplayer (shared plaza, private labs, invites, Prank Party, grabbing and throwing players, server size 6, friends, chat moments, why friends bring friends): 2/10
The code has many social pieces: friend checks, lab guests, Prank Party cards, toss combos, plaza grab and throw, friend nukes and pranks, a friend boost, a server list, the horde. What a player actually gets is a single-player game inside a 6-player server.
- You see nobody: other labs are solid blocks, and avatars in them are hidden.
- Two friends who join together spawn in separate walled labs. Getting together takes about 6 taps through MENU, FRIENDS and Places.
- The invite is buried in MENU. It carries no launch data, so an invited friend lands nowhere special.
- 'MAKE MY OWN' promises profile joins that reserved servers do not support.
- The plaza is the only shared space and gives no reason to go there. It has fewer machines than your lab, a horde every 10 minutes when the median visit is 2, and an NPC count shown as '12 people'.
- In the plaza, strangers can knock or grab you every 3.5 s, with no opt-in and no respect for Roblox blocks.
- A stranger's invisible event makes your BIG RED BUTTON say 'Busy'.
- Prank Party is effectively reachable only by Roblox friends who also press LAB INVITE.
- No social metric exists in Session_v1, and no 2-client test has ever been run.
On 'why would a friend bring a friend', the honest answer today is: no visible reason.

**10/10 means:** **Friends first, low density by design:**
- **One tap to play together.** A friend who joins (invite, profile Join or follow) spawns next to you. Roblox friends are mutual lab guests by default (a saved setting, ON). The labs are neighbours with an open gate. Within 10 s a 'MIA IS HERE' card shows one GO button, and a PRANK PARTY starts.
- **The party has machines only a pair can use.** A tandem cannon (one loads, one fires), a seesaw launcher and a friend-toss target. A 'PARTY x2: +50% TAKEDOWNS' pill sits on the HUD, and party badges teach it.
- **Invites appear at the moments that want company.** After the first bullseye, a combo or an X-ray replay, after 3 minutes, at most once a visit. They use Roblox's prompt with a short PromptMessage, a dashboard notification string and LaunchData. Arrival is read from GetJoinData (ReferredByPlayerId and LaunchData). A qualified arrival (the friend stays 3 minutes) gives both players a cosmetic. Nothing is given for opening the prompt.
- **Friends can always get in.** 2 server slots are reserved for friend joins. 'Own server' links are stored in MemoryStore, so a friend can follow in.

**Strangers, without risk:**
- A live presence pill: '2 PLAYERS IN THE PLAZA: GO'. A lab gate to the plaza with no teleport.
- The plaza is a meetup with a show every 3-4 minutes (horde or launch-off, 30 s warning, one-tap GO) and a plaza-only two-player toy.
- A marked opt-in FLING RING for player-vs-player grabs and hits. The rest of the plaza is safe. Roblox blocks are honoured in both directions.
- Small overhead tags: level and rarest weapon.
- Kid-safe system chat lines for rare moments. A fixed-phrase reaction wheel (no free text), because many kids cannot use chat.
- Paid events hit every lab and name the buyer. Lab events never queue behind a stranger's.
- Arena rounds that everyone in the arena joins, with per-player scores.

**Measured and tested:**
- Session_v1 records friendsHere, joinedVia, plazaSec, grabs, partySec, inviteOpened and arrivals. The report splits sessions with a friend from solo ones.
- 2- and 3-client Studio tests and a live 2-device test before each release.

**Targets:**
- 15% or more of sessions co-play.
- Median session with a friend over 10 minutes.
- An invite prompted in 20% or more of sessions longer than 5 minutes.

- **[critical/high/M] Friends who come to play together are walled apart.** A friend who joins the same server gets the first free plot (often on the other side of the plaza). Their lab and yours are solid blocks to each other, and each avatar is hidden on the other's screen. Being together takes about 6 taps: MENU > FRIENDS > LAB INVITE for the host, then the toast, MENU > PLACES and the card's GO for the guest. The guest list is one-way and is lost on leave. Nothing makes friends mutual guests automatically. This is the single most important social moment, and it is broken. *Evidence:* Lab.luau:757-788 (claim(): first free plot, no friend adjacency); FriendsService.luau:393-408 (LabInvite, opt-in per friend per visit); Zones.luau:77-83 (mayEnter: owner or guest only); PlotPrivacy.luau:123-152 (other avatars hidden) and 211-221 (solid block over each lab you may not enter); grep setLabGuest: only FriendsService.luau:401 and 492; FriendsUI.luau:385-386 toast 'Find it in Places'. *Fix:* 1. Roblox friends in the same server become mutual guests on join. Add a Settings row 'Friends can come into my lab', default ON and saved in the profile.
2. claim() picks the free plot next to a friend's lab (index ±2 on the same side, or 1/2 across the plaza) and opens a gate in the shared fence.
3. When a friend arrives, show both players a Notify card ('MIA IS HERE') with a one-tap GO that travels to the friend's lab.
4. The Prank Party starts right after.
5. Keep LAB INVITE only for taking access back.
- **[high/high/M] Invites carry no launch data and nothing reads join data.** PromptGameInvite is called with no ExperienceInviteOptions: no PromptMessage, no InviteMessageId and no LaunchData. The capture share passes the constant 'clip'. No code reads GetJoinData().ReferredByPlayerId or LaunchData, so an invited friend arrives as a random player in their own walled lab. The inviter gets no credit, and no arrival is counted. *Evidence:* FriendsUI.luau:219-237 (PromptGameInvite(player) with no options); CreatorUI.luau:132 (PromptShareCapture(capture, "clip", ...)); ProgressService.luau:1734 is the only GetJoinData use (SourcePlaceId); vault 'Friend Invites Referrals and Experience Invites': ReferredByPlayerId fills for all invite types, LaunchData up to 200 chars, poll for a few seconds after join. *Fix:* 1. Prompt with options: PromptMessage 'Throw me in the cannon!' (short); InviteMessageId set to a dashboard notification string that contains {experienceName}; LaunchData set to JSON {from=userId}. Share captures with the same LaunchData.
2. The server polls GetJoinData() for 5 s after join. If the inviter is here: make them mutual guests, place the friend beside the inviter, and pop '<Name> brought you!'. If the inviter is not here: offer FriendsService.join.
3. Reward only a qualified arrival (the friend stays 180 s): a cosmetic for both, such as a 'Buddy' cannon trail. Never reward the prompt itself.
- **[high/high/S] The invite is buried in MENU and never offered at a good moment.** INVITE FRIENDS sits only inside the FRIENDS window, which is an entry in MENU on every device. Nothing in the first session says that a friend makes the game better. RESEARCH_V4 item 6 asked for an invite at moments with company (after a combo or bullseye); it was never built. The friend list of 'IN OTHER SERVERS' is likewise only visible after opening the window. *Evidence:* HudMenu.luau:28 (FRIENDS = a MENU entry); FriendsUI.luau:218-237 (the only invite); docs/RESEARCH_V4.md:148 (recommended invite at combo/bullseye, reward only qualified arrival); repo grep for 'PromptGameInvite' finds FriendsUI only. *Fix:* 1. Send one contextual invite card through Notify (kind 'tip'), once a visit, after 3 minutes. Trigger it on the first BULLSEYE, a TOSS/takedown combo of 10 or more, or the end of an X-ray replay. Text: 'Throw a friend in the cannon! INVITE'. Hide it when CanSendGameInviteAsync is false.
2. Put a dot on MENU and FRIENDS when a friend is online in another server.
3. Add a 'bring back your squad' row using GetFriendsWhoPlayedAsync with InviteUser.
- **[high/high/S] Server Fill 'Maximum' locks friends out of full servers.** The owner was told to set Server Fill = Maximum, and servers hold only 6. Once a server is 6/6, a friend pressing Join on the inviter's profile cannot get in. That loses exactly the co-play session Roblox discovery rewards ('intentional co-play days'). Private labs also mean a full server has no visible benefit to strangers anyway. *Evidence:* CLAUDE.md round 5 'Owner: set Server Fill = Maximum on the dashboard'; Config.luau:76-80 (SERVER_SIZE 6, set by hand on the dashboard); vault 'Social Design and Multiplayer Play' section 1 (co-play days are a Discovery signal). *Fix:* In Creator Dashboard > Places > Server fill, choose 'Customize how many server slots to reserve' and reserve 2 slots for friend joins. Re-check after a week with the new social fields in Session_v1 (see the measurement finding).
- **[high/medium/M] 'MAKE MY OWN' promises a profile join that reserved servers do not allow.** The FRIENDS ONLY section says: 'A server just for you. Your friends can join you from your Roblox profile.' The server is created with TeleportService:ReserveServer, and friends cannot follow into reserved servers from the website or app. The in-game JOIN uses TeleportAsync with ServerInstanceId, which also cannot enter a reserved server. A player who makes their own server to play with a friend ends up alone. Related: anyone who arrives by teleport (PLAY NOW, JOIN, SOLO) never gets the newcomer flow, even a brand-new player. *Evidence:* PortalUI.luau:122-123 (the promise and MAKE MY OWN); PortalService.luau:131-133 (ReserveServer + ReservedServerAccessCode); FriendsService.luau:370-384 (join by ServerInstanceId only); ProgressService.luau:1732-1736 (Newcomer off when SourcePlaceId is set); DevForum threads 'Clicking Join on a friend in a ReservedServer throws error' and 'Redirecting players who attempt to join friends in ReservedServers'. *Fix:* 1. Write {ownerUserId -> accessCode, expires} to MemoryStore when an Own server starts.
2. In FriendsService.join, when GetPlayerPlaceInstanceAsync points at a reserved server, look the friend up and teleport with ReservedServerAccessCode, after checking the friendship.
3. In public servers, also honour Player.FollowUserId on arrival.
4. Until then, change the text to 'Invite friends from inside' and wire the INVITE button into that window.
5. Keep the newcomer flow when profile.playSeconds is under NEWCOMER_SECONDS, whatever the join source.
- **[high/medium/L] A 6-player server where you never see another player.** Every other lab is a solid, invisible block as long as the ground, and anyone standing in it is drawn transparent. Plots alternate east and west: the 3rd to 6th players' labs sit behind plot 1 or 2. Their owners cannot walk to the plaza because the neighbour's block is in the way; they can only travel there through Places. In practice the 'shared plaza between the labs' is reachable on foot by 2 of 6 players. For strangers, the server size is invisible apart from names in the player list. *Evidence:* PlotPrivacy.luau:201-221 ('as long as the ground: nobody walks round it'), 123-152 (avatars hidden), 300-306 (a wall for every plot you may not enter); Lab.luau:131-136 (odd plots east, even west, further out each step); Lab.luau:535-550 (keepOut); vault 'Social Design and Multiplayer Play' section 3 (servers must not feel empty; design for low density). *Fix:* 1. Lay a public front street ('Lab Row') along the front of every plot, joined to the plaza. It is walkable and visible to all; avatars on it are drawn.
2. Each lab stays private behind a gate, keeping the owner's 'others' plots not visible' rule. The gate shows the owner's name, level and a live sign such as 'NOW: ZERO-G!'.
3. Cheaper first step: keep the blocks, but add a walkway strip along z = front that is never blocked, so every lab reaches the plaza on foot.
- **[high/medium/M] The plaza gives no reason to go and counts NPCs as 'people'.** The plaza card reads 'The square between the labs. The horde comes here. 12 people.', but the 12 are NPCs. The real player count is never shown. The plaza has fewer machines than your own lab: no lava, bullseye, stations or big button. The only co-op draw, the horde, comes every 600 s, while the median visit is about 120 s. Its warning is 10 s, too short to open Places and travel. The spec's 'PLAY WITH OTHERS at 180 s' nudge and the 'plaza at 5-8 min' offer were never built. *Evidence:* Places.luau:39 (blurb, crowd = 12); PlaceMenu.luau:216 (caption '%s %d people.'); Playground.luau:950-970 (lava, bullseye, stations and big button only when lab); HordeService.luau:28-29 (HORDE_EVERY 600, WARNING 10); FriendsUI.luau:402 ('Open Places to go'); docs/RESEARCH_FIRST_SESSION.md:203 and 211 (the spec, not implemented: repo grep 'PLAY WITH OTHERS' finds only an old plan). *Fix:* 1. The plaza card shows live players ('2 PLAYERS HERE'). When at least one other player is in the plaza, a HUD presence pill offers a one-tap GO.
2. Give the plaza one exclusive shared toy, such as a giant trebuchet or slingshot that needs two people (one loads, one pulls), with a 'LAUNCH-OFF' distance board for this server.
3. Run a plaza show every 3-4 minutes (horde or launch-off) with a 30 s warning and a GO button.
4. Add the first plaza nudge at about 5 minutes.
- **[high/medium/M] Plaza PvP: no consent, no block respect, and the shop booths sit inside it.** Anyone in the plaza can knock any other player once every 3.5 s from up to 60 studs with a gun, and grab and throw them (with an 8 s gap). You cannot opt out except by leaving. No code reads Roblox block lists, so a blocked stranger can keep grabbing and knocking you. The map-shop booths stand in the same zone. 'Friends can prank me' covers only nukes and pranks. For a kid-safe game this is both a ratings risk (FTAP's approval of about 80% against 86-90% for the solo games) and a griefing hole. *Evidence:* HitService.luau:304-327 (PLAYER_REACH 60, plazaHit), 385-399 (any 'hit' toy on a player in the plaza); PlayerRagdoll.luau:285 (PLAZA_GAP 3.5); PlayerGrab.luau:37-45 and 95-125 (no block check); repo grep GetBlockedUserIds/PlayerBlocked/PromptBlockPlayer: none; WorldMaps.luau:959-960; docs/V6_PLAN.md:398 (booths at the plaza front); docs/RESEARCH_FIRST_SESSION.md:130 and 253. *Fix:* 1. Make player-vs-player hits and grabs work only inside a painted 'FLING RING' in the plaza: opt-in by stepping in, with a floor ring and one sign. The arrival, booths and boards stay safe.
2. Honour blocks in both directions. The client reads GetCore('GetBlockedUserIds') plus the PlayerBlocked/PlayerUnblocked events and tells the server. PlayerGrab.refusal, HitService.plazaHit and FriendsService.refusal refuse in both directions.
3. Keep Roblox's report flow reachable.
- **[high/high/M] A stranger's invisible event makes your BIG RED BUTTON 'Busy'.** The free lab button starts an event only when no event runs or waits anywhere on the server. With 6 private labs, another player's paid event or button press (in a lab you cannot even see) turns your button into 'Busy, try again soon', with no reason given. Their event banner still reaches your screen. Multiplayer here only takes away from the solo player. *Evidence:* Playground.luau:899-906 (EventService.current() == nil and queued() == 0 and not miniRunning()); EventService.luau:1-3 ('one at a time'), 113 (state FireAllClients). *Fix:* 1. Give each occupied lab its own event slot for free and lab events. Each client simulates only its own lab, so the cost per device does not change. Use the existing body caps per lab.
2. Keep the single server queue only for paid server-wide events.
3. Draw banners only for events in places this screen shows, plus server-wide paid ones.
- **[medium/medium/M] Paid 'server events' happen only in the buyer's lab.** A bought Dummy Rain, Mega Bomb and so on runs at the buyer's lab focus, but every player gets the banner. Nobody else can see that lab, so the strongest status moment on Roblox (an 'admin abuse'-style event where everyone sees who sent it) is lost, along with its sales pull. Only Zero-G-style physics changes are felt by others. *Evidence:* EventService.luau:48-49 (hostId: 'it happens in their lab'), 85-94 (labCenter: the host's lab focus, else the plaza); Events.luau:22-26 ('across the lab'); EventService.luau:113 (banner state to all). *Fix:* 1. Paid events run in every occupied lab at once, each simulated on its owner's client.
2. Banner: 'MIA SENT DUMMY RAIN TO EVERYONE!' with the buyer's headshot.
3. A fixed 'THANKS!' reaction lets others pop a heart over the buyer.
4. Free and big-button events stay in their own lab.
- **[high/high/L] Prank Party is almost unreachable and has nothing only a pair can do.** A party needs 2 or more players standing in one lab. Entry is friends-only and manual (LAB INVITE), so for nearly every session it never fires. When it does, the cards are the solo goals with 'TOGETHER:' in front (15 takedowns, 5 cannon shots, 6 traps). Only PartyToss uses the second player. Members are fixed at the start, so a third friend waits up to 200 s. No machine needs two people, and there is no party HUD or badge. *Evidence:* PartyService.luau:19-20 (CHECK_EVERY 5, GAP 20), 57-68 (needs n >= 2 in Lab.ownerAt); Experiments.luau:55-61; ExperimentService.luau:177-186 (members = table.clone at the start); Zones.luau:77-83 (friend-only entry). *Fix:* 1. With mutual guests on by default (see the first finding), start the party the moment a friend arrives.
2. Add members who walk in to the running card.
3. Build 2 pair machines into labs that have company: a tandem cannon (one loads, one fires) and a seesaw launcher (one jumps, the other flies).
4. Show a party pill on the HUD ('PARTY x2 · friend boost on').
5. Add 2 free social badges ('Toss a friend into the cannon', 'Clear a party card').
- **[medium/medium/S] The friend boost and friend nukes and pranks are invisible.** The friend boost (every 2nd takedown counts double) is shown only as a caption inside the FRIENDS window. NUKE and PRANK are buttons in a list inside MENU > FRIENDS, so nobody discovers the funniest thing two friends can do to each other. The vault's reference keeps the friend boost on the HUD. *Evidence:* FriendsUI.luau:139-143 (boost text), 88-135 (NUKE/PRANK rows); ProgressService.luau:1000-1005 (boost logic); HudMenu.luau:28; vault 'Social Design and Multiplayer Play' section 4 (friend boost shown as a HUD pill). *Fix:* 1. HUD pill 'FRIEND BOOST' while a friend is in the server.
2. Add a client-only ProximityPrompt on a friend's character ('PRANK MIA'), shown to friends only and keeping the server cooldowns.
3. In the first visit with a friend present, one tip: 'Press PRANK near Mia'.
- **[medium/medium/S] SINGLEPLAYER/MULTIPLAYER portals mislead and leak players.** Two portal arches sit behind every lab spawn. MULTIPLAYER teleports you to another server, where you still see nobody. SINGLEPLAYER teleports you to a reserved server, which is no different from your private lab. Both cost a load screen. The research behind them came from solo-server games (BRP's portal makes sense there); here the default is already multiplayer with private labs. *Evidence:* Playground.luau:961-962; PortalService.luau:1-11, 121-143, 329-334; PortalUI.luau:57, 131-132 ('GO SOLO'); docs/RESEARCH_FIRST_SESSION.md:47. *Fix:* 1. Cut SINGLEPLAYER.
2. Replace the MULTIPLAYER arch with a 'TO THE PLAZA' gate: in-server travel through WorldMaps, no teleport. Its sign shows the live count ('2 PLAYERS').
3. Move the server list into FRIENDS as 'JOIN FRIENDS / OTHER SERVERS'.
- **[medium/medium/M] Arena games are host-only; everyone else just watches.** Red Light Green Light and Shoot 'Em score only the host's knock-downs, one game at a time, so a second player in the arena is a spectator, or is blocked until the host is done. The phase-0 store text claimed 'Play the arena games with everyone'. *Evidence:* MinigameService.luau:12-15 ('Only the host's knock-downs score ... everyone in the arena sees the game bar'); STORE_TEXT.md:101. *Fix:* 1. When anyone starts a game, show a 10 s 'JOIN ROUND' to everyone in the arena or plaza.
2. Score every player's own knock-downs and show a round-winner banner with a THIS SERVER best board.
3. Solo still works when nobody joins.
- **[medium/medium/M] No 'display' rung: nothing shows who others are or what they did.** There are no player tags over heads (only the owner tag) and no server-wide moments in chat. The plaza boards are global top 5 (out of reach for anyone new), and two of the four are VIP-only boards that are near empty. With private labs, the plaza is the only place to show off, and it shows nothing. HRR has a Here/Friends/Global board. *Evidence:* LeaderboardService.luau:2-4, 36-41 (MOST TAKEDOWNS, MOST TIME, VIP TAKEDOWNS, VIP TIME); AdminService.luau:367-371 (OwnerTag only); repo grep DisplaySystemMessage: none; docs/V3_PLAN.md:86 (leader's Here/Friends/Global board); vault 'Social Design and Multiplayer Play' section 3 (titles above heads, rare moments visible to the whole server). *Fix:* 1. A small overhead tag (level plus the rarest owned weapon's icon), drawn within 60 studs, at most 12 at once.
2. Kid-safe system lines through TextChannel:DisplaySystemMessage with fixed strings ('Mia unlocked the GOLDEN POPPER!', 'Leo hit 3 BULLSEYES in a row!').
3. Replace the two VIP boards with THIS SERVER and FRIENDS boards.
- **[medium/medium/M] No kid-safe way to communicate.** There are no emotes, no reaction wheel and no 'come here' ping. Roblox's 2026 age-check rules for chat (my knowledge, not verified this session) leave many young players unable to chat at all. The owner's rule bans new free-form text, so fixed reactions are the only voice two kids in the plaza have. *Evidence:* Repo grep for emote, reaction or quick chat in Client/: none; CLAUDE.md owner rule 'No new free-form text in the world'; vault 'Emotes and Social Animation' and 'Block and Mute Respecting Platform Rules'. *Fix:* 1. A 6-slot reaction wheel (pad: D-pad hold; phone: one small button in MENU or a long-press): laugh, thumbs up, scared, 'AGAIN!', 'WATCH THIS!', 'COME HERE!'.
2. Show the chosen reaction as a bubble over the head with a 1 s emote. The server rate-limits it to 1 per 2 s and honours blocks.
- **[high/high/M] Social play is unmeasured and has never been tested with 2 clients.** Session_v1 records nothing social: no friends present, no join source, no time in the plaza, no grabs, party time, invites or arrivals. Metrics has nothing social either. No 2- or 3-client session was ever run: AUDIT gives Multiplayer '5 (unmeasured)', and V7 skipped the 2-client test. The grab tests use a single player holding itself. Every social claim is therefore a guess, and the owner's '15 joined, 2 stayed' cannot be split into solo against with-friends. *Evidence:* SessionStats.luau:25-55 (Record fields: none social); grep friend/party/plaza in SessionStats and Metrics: no matches; docs/AUDIT.md:23; docs/V7_PLAN.md:273, 339; PlayerGrab.luau:220-227 (holdForTest: 'the suite has one player, who holds itself'). *Fix:* 1. Add Session_v1 fields: othersAtJoin, friendsMax, joinedVia (invite, follow, referral, teleport, plain), plazaSec, grabsGiven, grabsTaken, playerKnocks, partySec, inviteOpened, inviteArrival.
2. Make SessionReport split the table by 'with friend vs solo'.
3. Before each release, run Studio Test > Clients and Servers with 2-3 players by hand, covering invite, guest, party, toss, plaza grab and hit, nuke, block, and leave mid-hold.
4. Run one live test on 2 devices (phone + PC).
- **[low/low/S] 10 plots for a 6-player server: 4 permanent 'FREE LAB' walls.** Lab and Zones still lay out 10 plots, and the comment says 'the place's server size should be 10'. Server size is 6, so plots 7-10 are never owned. Every client still builds a fenced block for each, with 'FREE LAB / Closed until someone owns it' signs every 96 studs. That is extra clutter, a longer strip to stream (250-stud spacing), and landscape built for 10. *Evidence:* Lab.luau:76 (PLOT_COUNT 10 + stale comment); Zones.luau:20; Config.luau:80 (SERVER_SIZE 6); PlotPrivacy.luau:225 (FREE LAB text), 300-306 (a wall for every non-allowed plot), 183 (SIGN_EVERY 96); Main.server.luau Landscape.build(..., Lab.PLOT_COUNT). *Fix:* Set PLOT_COUNT from Config.SERVER_SIZE (6). At the least, draw unowned plots as plain landscape with no fence or sign. Re-run T36/T39/T106 for layout.
- **[low/low/S] Copy promises things the rules forbid.** Several texts promise things the rules do not allow.
- Fence signs say 'PRIVATE: ask for an invite', but strangers can never be invited (friends only).
- The kick-back toast says 'That's X's lab. Ask them to let you in!'.
- Places says 'other players' labs', but you only see labs you were invited to.
- The PortalUI header comment still says 'players x/10'.
- Roblox now calls friends 'Connections' (my knowledge of the 2025 rename; verify), so 'Only your Roblox friends' may read oddly to kids. *Evidence:* PlotPrivacy.luau:225, 378; PlaceMenu.luau:200; PortalUI.luau:4; FriendsService.luau:180, 368, 397. *Fix:* 1. Fence sign: 'MIA'S LAB · friends only'.
2. Toast: 'Labs are private. Friends can let you in'.
3. Places caption: 'Your lab, the plaza, your friends' labs, the arena and five maps'.
4. Check the current Roblox wording for friends and use it everywhere.
- **[low/low/S] Trespass and friend-prank flings dump players in the plaza.** Anyone whose body ends up in a lab they may not enter is teleported to the plaza arrival and told to 'ask'. A friend's nuke launches you at 110 studs/s in a random flat direction, so a nuke near your lab's edge can land you next door. That sends you to the plaza, far from your lab and its first-visit steps. *Evidence:* Lab.luau:535-550 (keepOut: PivotTo worldOrigin + (0, 3.5, 40)); FriendsService.luau:292-295 (random flat direction, 110 studs/s). *Fix:* 1. Put a trespasser back at their own lab's spawn (or the edge they crossed), with no scolding toast when they arrived by a launch.
2. Aim friend-prank launches up and inwards, towards the victim's plot centre.
- **[low/low/S] Friend code uses a deprecated API, and unsolicited social toasts skip Notify.** FriendsService uses Player:IsFriendsWith, which is deprecated in favour of IsFriendsWithAsync. FriendsUI shows unsolicited toasts ('X pranked you', 'X let you into their lab', 'HORDE of N...') with Toast.show directly. V6-1 routes unsolicited messages through Notify. The horde toast goes to every player, even someone on a far map. *Evidence:* FriendsService.luau:84, 365 (IsFriendsWith); FriendsUI.luau:378-386, 401-409 (Toast.show for Hit/LabInvited/Horde*); CLAUDE.md V6-1 ('Unsolicited toasts ... go through it'). *Fix:* 1. Switch to IsFriendsWithAsync in a pcall.
2. Route the Hit, LabInvited and Horde messages through Notify.say (kinds info and critical), and send the horde warning only to players on the ground grid.

**Cut or hide:** The SINGLEPLAYER portal and the 'GO SOLO' window (PortalService.luau:329/333, PortalUI.luau:129-132). It teleports you out to the same experience you already have.; The MULTIPLAYER portal arch in every lab. Replace it with an in-server 'TO THE PLAZA' gate and move the server list into FRIENDS.; The 'MAKE MY OWN' button and its 'friends can join from your profile' text until reserved-server friend joins work (PortalUI.luau:121-123).; The VIP TAKEDOWNS and VIP TIME PLAYED plaza boards (LeaderboardService.luau:39-40). They are near empty; put THIS SERVER and FRIENDS boards in their place.; The plaza edge boards repeated every 256 studs on both edges and both faces (WorldMaps.luau:973-988). They are also visible from labs 1 and 2. Keep one arrival board.; The fenced 'FREE LAB / Closed until someone owns it' blocks and signs for plots 7-10 (PlotPrivacy.luau:225; Lab.luau:76).; The 'PRIVATE: ask for an invite' signs every 96 studs on every fence (PlotPrivacy.luau:183, 225). Use one gate sign per lab.; The '12 people' NPC count on the Plaza card (PlaceMenu.luau:216). Show real players or nothing.; The country code in the server list (PortalService.luau:346-350): it can reveal a single child's country and adds nothing.; Event banners for events in labs this screen cannot see, except paid server-wide ones.; The 10-minute horde in its current form: nobody sees it at a median visit of 2 minutes, and its 10 s warning is too short. Fold it into a 3-4 minute plaza show.; The 'Hit other players in the PLAZA only...' caption under SETTINGS in the Friends window (FriendsUI.luau:245-251). It belongs at the plaza's fling ring.

### I-ui: UI/HUD and menus on phone portrait, phone landscape, tablet, PC and console (HudSlots, HudV3, HudGate, HudPlus, HudMenu, KitStyle, LihFolkUITheme, EventShop, ToolCatalog, RewardsUI, ExperimentCard, FirstVisit, Onboarding, HitInfo, LayoutCheck): 4/10
The layout engineering is careful: there is a slot table, safe insets, 44 px tap floors and a self-check on 16 screens. The player-facing result is still weak, and partly broken.

- **PC and tablet:** Settings cannot be opened at all.
- **Retention hooks no device shows:** the play-gift clock and every "something to claim" badge are drawn on HUD pieces that are hidden everywhere.
- **Phones (most players, held upright):** they get the old round-5 HUD with no next-weapon goal, and only about 37% of the screen is left for the game.
- **A newcomer's first seconds:** three instruction texts and two pointers.
- **Look:** two different HUDs (phone vs everything else) on three stacked theme layers, plus emoji and leftover colours.
- **The self-check:** LayoutCheck's "0 problems" never looks at HudV3 (the HUD on PC/tablet/console) or at the first-visit line, yet it does measure pieces that never show.
- **Wording:** "kills", "DEAD", "no pulse" and "Bone journal" leak into an all-ages game.

**Research limits:** the web-search budget for this session was used up, so the comparison with the leaders rests on the repo's research (docs/RESEARCH_FIRST_SESSION.md: storyboards of Bloody Ragdoll Physics, Hyper Realistic Ragdoll, Ragdoll Research and Fling Things; docs/V3_PLAN.md teardown) and the LihFolk vault UI notes. Nothing new from TikTok or Reddit this pass.

**10/10 means:** **One HUD family, one look, every device.**
- One component set and one token layer. The HudV3 dark-glass family is also used on phones, at phone sizes.
- One font pair, one drawn icon set, no emoji in text.
- One "is a phone" rule (touch plus short side), shared by every module.

**Phone (the main platform, designed first)**
- Landscape-first, by a measured choice (StarterGui.ScreenOrientation tested against SessionStats).
- Upright phones still get a real portrait layout, with at least 55% of the screen free.
- **Thumb row:** the stick on the left. On the right, one big contextual action (SHOOT / THROW / PLACE) with 2-3 helpers around it, RAGDOLL among them, and the jump button.
- **Bar:** a labelled 3-5 slot bar at the bottom.
- **Top-left:** one row with SHOP, REWARDS (with a live badge and the gift clock), MAPS and MENU.
- **Top bar:** a "Next: Revolver 3/5" pill with a bar, and a bolts counter.

**First 30 s (every device)**
- At most 4 things: the stick, the action button, the bar, and one objective line with one pointer.
- Then one new piece every 10 s or so.
- One goal line at a time: the first-visit steps first, then the experiment card in the same spot.
- On a hit: a 1-second "KO! +1" pop by the crosshair, not a medical readout.

**PC and console**
- The same family. Key chips only after the first minute, and the key list in one place.
- Console: nothing under 20 px at 1080p, a gold focus ring on every HUD square, glyphs in every prompt.
- Every window is reachable on every input: Settings, Rewards, Eggs, Bolts/Codes, Maps, Friends.

**Words**
- One word per thing, kid-safe: takedowns/KO, knocked out, Crash Journal, Maps, Build.
- No fake urgency, no made-up "fan favourite".

**Settings**
- A graphics preset (Auto/Low/High), HUD size, left-handed swap, and a hide-HUD toggle.

**Proof**
- LayoutCheck walks the live PlayerGui tree (all ScreenGuis) in each scenario: first minute, mid-game, building, chase, windows.
- Before/after captures on a real small Android, an iPhone, an iPad, a 1080p TV and PC.
- SessionStats shows the reveal, egg/reward claim rates and the share of visits over 5 minutes rising per device.

- **[critical/medium/S] Settings cannot be opened on PC or tablet.** The SETTINGS button only lives in two places:
- the kit's left launcher column, which HudV3 hides whenever it is on (every non-phone screen);
- MENU, where it is marked phoneOnly, so it shows only on phones or with a gamepad.

HudV3's own squares are Shop, Weapons, Lab, Maps and Menu, plus a gift button. None of them opens Settings, and there is no Settings key. So PC and touch-tablet players cannot change sound, camera shake, motion or UI size. *Evidence:* - HudMenu.luau:30 (Settings phoneOnly) and :158-163 (Visible = isPhone() or pad).
- HudPlus.luau:621 (the launcher sits in the kit column).
- HudV3.luau:403-406 (column.Visible = false while active) and HudV3.luau:485-516 (no Settings square).
- HudGate.luau:15-20 (active on every non-phone screen).
- Keybinds.luau:35-99 (no Settings binding).
- grep: no other Controller.open("Settings"). *Fix:* Make Settings reachable on every input:
- drop phoneOnly for the Settings entry in MENU, or show it whenever HudGate.active() is true;
- put a Settings row at the top of the MENU window;
- add a K-style key binding.

Add a test: for each device context, every registered window has at least one visible opener.
- **[high/high/S] The play-gift clock and every claim badge are invisible on all devices.** **The gift clock.** GiftClock draws its "GIFT 1:42" tag on PokeController.weaponsHud, which is HudPlus's big red WEAPONS button. That button is hidden on phones (PHONE_HUD_MAX7) and on every other screen (LOOK_V3). So the clock shows nowhere. Yet at the reveal a tip tells the player "The clock is on WEAPONS."

**The badges.** RewardsUI's claimable count and HudMenu's "!" badge go onto the kit's launcher column, which HudV3 hides. HudV3's own gift button and Menu square draw no badge at all.

The daily gift, dares and play gifts, the main return hooks, never signal that they are ready. *Evidence:* - GiftClock.luau:47-51 (it draws only on weaponsHud) and GiftClock.luau:68 ("The clock is on WEAPONS.").
- HudPlus.luau:337 (weaponsHud = the big button) and HudPlus.luau:583-585 (hidden on phones and under LOOK_V3).
- RewardsUI.luau:134-135 (hud.setCount on the kit launcher).
- HudMenu.luau:96-98 (setBadge on the kit MENU launcher).
- HudV3.luau:222-235 (gift ImageButton with no badge) and HudV3.luau:403-406 (kit column hidden). *Fix:* Make one Rewards entry the single home of the gift clock and the count badge on every device:
- HudV3: the top-bar gift (a count bubble plus a "1:42" pill) and a badge on the Menu square;
- phones: a REWARDS square in the top-left row.

Point GiftClock at it, and change the tip to "The clock is on REWARDS." Delete the weaponsHud path.
- **[high/high/S] Phones (most players) have no next-weapon goal on screen.** The leaders' core hook is a "next weapon" meter from second 1 (Bloody Ragdoll Physics' red WEAPONS button with a bar; the HRR pill "Next: X 22/25"). On phones every version of it is off:
- the big WEAPONS button is hidden (PHONE_HUD_MAX7, its place given to the experiment card);
- the NEXT cards are forced to 0 on phone touch;
- the HudV3 "Next" pill exists only off phones.

A phone player sees the level badge only after the quiet start, and nothing about what they are unlocking. *Evidence:* - HudPlus.luau:583-585.
- Config.luau:50 (PHONE_HUD_MAX7 = true).
- PokeController.luau:471-475 (up = 0 on phone touch).
- HudGate.luau:19 (the V3 pill is off on phones).
- RESEARCH_FIRST_SESSION.md:84, 86 and 149-151 ("A next weapon meter is on screen from the first second"). *Fix:* Reuse HudV3's Next pill (HudV3.drawNext) on phones as a 44 px-high pill under the top-left row: weapon picture, "Revolver 3/5" and a thin bar. Tapping it opens WEAPONS. Show it from 0 s for newcomers; it replaces the level badge. Give the experiment card its own row under it, or let it alternate with the pill.
- **[high/high/M] Three onboarding systems give a newcomer 3 texts and 2 pointers at once.** At 0-5 s on a phone the newcomer gets all of this for one action:
- FirstVisit's objective pill at the top: "Knock a dummy over!";
- OnboardingController's hint over the bar: "Tap the dummy to shoot!";
- a spinning neon cube over the greeter's head;
- TouchShoot's "TAP A DUMMY! 👇" hand over the nearest dummy;
- a SHOOT button and a centre crosshair that say "press here", contradicting "tap the dummy".

From 40 s three goal lines run together: the FirstVisit step ("Fire yourself from the CANNON"), the experiment card (EXPERIMENT_FIRST_AT 40, which does not check FirstVisit), and "Now try another tool!".

The repo's own research rule is one line and one target: two pointers and the player follows neither. *Evidence:* - FirstVisit.luau:44 and :98 (pill at y 48 on phones).
- OnboardingController.luau:323-326 (shootHint), :280-307 (neon cube pointer) and :386 ("Now try another tool!").
- TouchShoot.luau:35 and :235-240 (hand for 45 s).
- ExperimentCard.luau:72-82 (shown() never checks the FirstVisit line).
- Config.luau:48 (EXPERIMENT_FIRST_AT 40).
- RESEARCH_FIRST_SESSION.md:250. *Fix:* Make FirstVisit the only guidance owner. Cut the bar hint and the neon cube while it runs, and keep a single pointer: the hand on touch, a highlight on PC.
- The device text comes from one function: "Press SHOOT", "Click" or "R2".
- The experiment card waits until FirstVisit ends, then takes the same top-centre spot, so only one goal line is ever on screen.
- Add LayoutCheck rule: at most one objective text and one pointer per scenario.
- **[high/high/M] Upright phones: the game gets only about 37% of the screen; RAGDOLL is out of thumb reach.** Most visits are 414x814 portrait. On a 414x804 safe area the HUD takes the top ~200 px and the bottom ~310 px:
- the bar sits 180 px up (48 high);
- the LOOK_V3 hit card is 64 px above it, plus a 12 px gap;
- the thumb row (SHOOT/GRAB, RUN, THROW/ZOOM, jump) is under the bar;
- toasts start at y 200;
- SHOP/MENU start at y 130 on the left;
- LAB VIEW, Replay and RAGDOLL stack in the top-right corner, which a thumb cannot reach on a tall phone.

About 300 px of height is left for a third-person physics game.

No code sets StarterGui.ScreenOrientation, so the place file allows portrait. Every leader's phone layout in the research is landscape: stick left, FIRE/RAGDOLL/JUMP right. *Evidence:* - PokeController.luau:463 (PORTRAIT_BOTTOM 180) and :523 (48 px slabs).
- HitInfo.luau:49-51 (64 px card) and :30.
- HudSlots.luau:42 (toasts at 200) and :57-59 (RAGDOLL top-right at y 130).
- HudMenu.luau:61 (PHONE_COLUMN_TOP 130).
- grep: no ScreenOrientation anywhere in the code.
- RESEARCH_FIRST_SESSION.md:86 and :161. *Fix:* 1. Run an A/B by place version: set StarterGui.ScreenOrientation = LandscapeSensor and compare SessionStats (median visit, share over 5 minutes) against the portrait build.
2. If portrait stays, give it its own layout:
   - bar directly over the stick and action row (about 90 px up);
   - RAGDOLL in the action cluster;
   - hit card removed (see the hit-line finding);
   - toasts as a 1-line strip under the top row;
   - top-right reserved for Roblox.
   - Target at least 55% of the height free.
- **[high/medium/M] LayoutCheck's '0 problems' skips the real HUD and the newcomer line, and measures pieces that never show.** **What it misses.** LayoutCheck never references HudV3, which is the whole HUD on PC, tablet and console. It also misses FirstVisit's objective line. Its live check finds controls by the HudSlot attribute, which HudV3 pieces do not carry. Its first-minute count is a hand-written list of names, not the live screen.

**What it measures that never renders:** the WEAPONS, Deal and Packs slots, which are hidden on every device.

**Overlaps computed from the code (not seen in captures):**
- 1024x768 iPad: HudV3 scales to 0.72, so the Menu square covers about x W-104..W-9, y 108-194. The touch RAGDOLL slot (86x52 at 0.846) covers x W-87..W-14, y 130-174. They overlap.
- 414 portrait phone: the FirstVisit pill (y 48-88, centred, up to 382 px wide) overlaps the experiment card (12,68, 158x46) once the card comes at 40 s. *Evidence:* - grep: no 'HudV3', 'HudGate' or 'FirstVisit' in LayoutCheck.luau.
- LayoutCheck.luau:1045-1071 (firstMinuteNames is a fixed list).
- HudSlots.luau:312-317 (the HudSlot attribute is set only by apply).
- HudV3.luau:436-437 (scale clamp 0.72-1.1) and :497-503 (right column at y 150).
- HudSlots.luau:57-59 and :249-260.
- AUDIT.md:107 (claims 0 problems on all 16 screens). *Fix:* Rewrite the live check to walk every visible GuiObject of every ScreenGui in PlayerGui in each scenario: newcomer 0 s / 40 s / 120 s, mid-game, building, chase, each window open.
- Check it against the jump button and thumbstick rects.
- Drop the rule-copy lists.
- Add tablet portrait, 1024x768 iPad and notched phones to SCREENS.
- Store a capture grid per release.
- **[high/medium/L] Two HUDs on three stacked theme layers, plus emoji and stray colours: it reads as patched together.** Phones get the round-5 HUD: kit launchers, slabs, red/green roles. Every other screen gets HudV3, with its own glass colour and alpha, its own BuilderSansBold sizes and hand-made corners. Windows use the kit with three token layers applied in order: dark glass, then UI_V2 navy/orange Fredoka, then UI_CLEAN slate Builder Sans.

Stray styles on top of that:
- HudPlus's RED (214,40,48) with a white gradient;
- the experiment card's legacy stroked text and pink edge;
- FirstVisit's gold-stroked pill;
- the black hit card;
- emoji glyphs in text (🧪 🎁 ⭐ 🔩 📖 🎉 🥚) next to the hand-drawn icon set.

The owner's verdict on the release build: 'it looks like AI slop'. *Evidence:* - LihFolkUITheme.luau:50-145 (dark glass), :322-414 (V2) and :435-509 (Clean).
- HudV3.luau:34-35 and :126-127.
- HudPlus.luau:50 and :252-255.
- ExperimentCard.luau:68 and :362-372.
- FirstVisit.luau:100-114.
- RewardsUI.luau:167 and :226-231.
- V3_PLAN.md:235 and :247 ('Mixed styles'). *Fix:* Collapse to one token set (UI_CLEAN values baked into the base, with the V2 and dark-glass blocks deleted) and one HUD component family, HudV3's card, pill and chip, used on phones at phone size.
- Swap every emoji for a DrawnIcons icon.
- Add a lint test: no Color3.fromRGB in Client HUD modules except tokens, and no emoji codepoints in player text.
- **[medium/medium/S] Violent or medical words leak into an all-ages UI.** MILD_TEXT only swaps 'blood' for 'health'. Everything else stays:
- the WEAPONS button: 'N kills to go!';
- catalog: '(43/100) Kills', 'Locked: earn kills', 'Earn the X with kills';
- the hit card: 'no pulse · DEAD' and 'OUT COLD', with pulse numbers;
- Settings: 'Dead monitor — Show a dead body's monitor';
- the Experiments window: 'BONE JOURNAL';
- keybind 'Doctor mode (hospital monitor)'.

Elsewhere the game says 'takedowns'. The owner still has to redo the maturity questionnaire for all ages, and the UI wording should match a mild label. *Evidence:* - HudPlus.luau:207.
- ToolCatalog.luau:116, :287 and :957.
- HitInfo.luau:90 and :101-108.
- Settings.luau:191-192.
- ExperimentCard.luau:304.
- Keybinds.luau:39.
- CLAUDE.md v3 ('listed Minimal, Ages 16+'). *Fix:* One word list in Shared (Words.luau) with kid-safe terms, and a test that greps the Client strings for kill/dead/death/bone/blood/pulse outside doctor mode:
- takedowns / KO;
- knocked out;
- Crash Journal;
- 'Crash monitor' or remove it.
- **[medium/medium/S] A medical readout sits over the action after every hit.** Every hit shows two lines (pulse, health %, state) in a 64 px black card centred just above the bar, held for 6 s after the last hit. On a phone it is 280 px wide. While shooting it is almost always there, covering the part of the screen where the ragdoll lands.

The leaders show short pops instead (+XP, KO). Ragdoll Havoc's own docs already note 'Nothing else pops up on a hit'. *Evidence:* - HitInfo.luau:2-11 (format), :35 (MAX_W_PHONE 280), :49-51 (HEIGHT 64 under LOOK_V3) and :52 (HOLD 6).
- HitInfo.LONGEST_STATUS at HitInfo.luau:59. *Fix:* Default to a 0.8-1.2 s pop by the crosshair ('KO!', '+1', a headshot star) through FeelBus. Keep the two-line readout only in doctor mode (opt-in).
- **[medium/high/S] Rewards, Maps, Eggs and Settings are buried in MENU on phones.** The phone's left edge keeps only SHOP and MENU. MENU holds 8 entries:
- PLACES, SANDBOX, REWARDS, RANK & EGGS;
- FRIENDS, CLIPS & LIVE (the TikTok-LIVE streamer tools);
- SETTINGS, FAVORITE.

Eggs are a MENU entry on every device ('almost nobody opens an egg'). The 5 open-air maps and the daily gift sit two taps deep. BRP's phone top bar shows WEAPONS, SHOP, REWARDS and MAPS directly. *Evidence:* - HudMenu.luau:21-33 (entries), :56 (PHONE_KEEP = Shop only) and :26 (RANK & EGGS).
- RESEARCH_FIRST_SESSION.md:86 (BRP phone top bar) and :162 (daily systems behind one REWARDS button). *Fix:* Phone top-left row: SHOP, REWARDS (badge plus gift clock), MAPS, then MENU.
- Fold eggs into REWARDS ('Free egg' as a claim row) and WEAPONS.
- Show CLIPS & LIVE only when the Streamer or creator attribute is set.
- MENU keeps Friends, Build, Settings and Favorite.
- **[medium/medium/M] The soft currency (BOLTS) is invisible and its window is hard to find.** Bolts, BUY NEXT WEAPON and REDEEM CODE live only in the Experiments window. That window opens by tapping the experiment card, and the card is hidden whenever no experiment is running. The MENU entry for it is pad-only.

No HUD piece shows the bolts count, while the leaders put a coin counter top-right (RDP, Fling Things). Meanwhile toasts promise '40 FREE BOLTS'. *Evidence:* - ExperimentCard.luau:356-358 (card opens window), :72-82 (card hidden without current), :227 (BUY NEXT WEAPON), :255 (REDEEM CODE) and :284-290.
- HudMenu.luau:27 (padOnly).
- GiftClock.luau:67-68.
- RESEARCH_FIRST_SESSION.md:117 and :127. *Fix:* Add a bolts counter chip (count-up on gain) beside the Next pill on every device. Tapping it opens a Bolts tab in Rewards with BUY NEXT WEAPON. Move codes to Rewards or Settings. Let the experiment card open only the mission detail.
- **[medium/low/S] One feature, many names (Sandbox/Build/Lab, Maps/Places, View).** - **Build mode** is called 'SANDBOX' in MENU, 'B sandbox' in the help line, and 'Build mode' inside a window titled 'Lab', which the HudV3 square 'Lab' opens.
- **'Lab'** also means your plot, the LAB VIEW camera and the Lab Controls pass.
- **Maps:** the 'Maps' square opens a window titled 'Places', and MENU says PLACES.
- **Views:** the key chip 'V View' is first person, while the LAB VIEW button uses C.
- **Progress:** takedowns, kills, KOs, stars, level/XP, rank and trophies all appear as separate measures. *Evidence:* - HudMenu.luau:21 and :24.
- PokeController.luau:383-386.
- HudV3.luau:192, :369, :494 and :511.
- PlaceMenu.luau:199 (title 'Places').
- LabCamera.luau:481.
- Keybinds.luau:36 and :40. *Fix:* Words.luau as the single dictionary:
- BUILD;
- MAPS everywhere (window title included);
- 'First person' chip text;
- LAB VIEW renamed 'TOP VIEW';
- one progress word (takedowns) plus level.

Add T-test: every window title equals its launcher word.
- **[medium/low/S] TV text too small; HUD squares have no gamepad focus look.** HudV3 scales only by height/1080. On a 1080p TV:
- the Next pill draws at 15 px;
- the experiment card and the next cards at 14 px.

The vault's ten-foot rule is nothing under about 20 px at 1080p. Kit windows get the console 1.35 base scale, but the HUD does not. HudV3 squares animate only on mouse enter/down, and have no selection ring. *Evidence:* - HudV3.luau:254 and :268 (TextSize 15), :436-437 (scale = h/1080) and :77-88 (mouse-only depth).
- LihFolkUIController.luau:152-153 (console 1.35, windows only).
- Vault 'Gamepad and Console UX.md':188. *Fix:* Multiply the HudV3 and HudSlots scale by 1.3 on deviceKind 'console'. Set the HUD text floor to 20 px on TV. Use Theme.Focus as the SelectionImageObject on the HUD squares, the same as hover. Add a LayoutCheck TV text-floor rule.
- **[medium/medium/S] Tablets get the mouse HUD with squares in the thumbstick zone.** HudGate turns HudV3 on for any non-phone screen, touch tablets included. Its Shop, Weapons and Lab squares are anchored bottom-left, where Roblox's dynamic thumbstick starts (MoveStick's fallback zone is the lower-left 40% x 55%). A thumb meant for moving opens the shop.

HudV3 itself says it was designed off-phone with phones' touch buttons measured separately. The repo's research says tablets should use the phone layout. *Evidence:* - HudGate.luau:15-20.
- HudV3.luau:10-11 and :472-477 (left column bottom-left).
- CLAUDE.md mobile fixes v0.17.2 (MoveStick lower-left 40%x55%).
- RESEARCH_FIRST_SESSION.md:222. *Fix:* Use the phone layout family for touch tablets (bigger cards and the same placement), or move HudV3's left column to the top-left on touch. Add the iPad to the live check with the thumbstick rect.
- **[medium/low/S] Four different 'is it a phone' tests.** - HudSlots: viewport short side ≤ 500, with no touch check, so a short PC window gets the phone HUD.
- PokeController and HitInfo: the same, on the gui size.
- The kit Controller: safe-area short side < 520 and TouchEnabled.
- FirstVisit: < 600 and touch.

A touch device with a 501-519 px short side gets the kit's phone column (Shop only) and HudV3 at the same time. The vault's phone case study asks for exactly one definition. *Evidence:* - HudSlots.luau:333-336.
- LihFolkUIController.luau:62 and :144-145.
- FirstVisit.luau:82-86.
- PokeController.luau:467.
- HitInfo.luau:39.
- HudMenu.luau:64-68.
- Vault 'Case Study - Phone UI Overhaul' ('One phone definition'). *Fix:* Add Shared/DeviceProfile (touch plus safe-area short side < 520, plus a console flag) and have every module ask it. Add a unit test listing the 20 LayoutCheck screens with their expected family.
- **[medium/medium/S] The experiment card is crammed into a 158x46 box with emoji and a ticking timer.** The phone card packs an emoji, the mission text, the count and a live mm:ss countdown into 158x46 px with TextScaled at a 14 px floor. Longer missions clip. The text re-flows every second, and every mission feels timed. On PC it sits top-centre, 94 px under the FirstVisit line, so two objective boxes are stacked. *Evidence:* - ExperimentCard.luau:68 (lineOf) and :352-367.
- HudSlots.luau:167-172.
- FirstVisit.luau:98 (PC y 14). *Fix:* Card = icon + 3-5 word goal + progress bar ('Blast off the cannon 0/1'). The timer shows only on timed or party cards, as a thin ring. It uses the same component and spot as the FirstVisit line, which hands over to it.
- **[medium/low/S] Dead UI and fake urgency still in the code.** **Never visible under the current Config, but still measured by LayoutCheck:**
- HudPlus's big WEAPONS button, TODAY'S DEAL and the sandbox column (each hidden by PHONE_HUD_MAX7 or LOOK_V3);
- EventShop's Robux packs (enabled only if not HudGate.active() and not a phone, which never happens).

**Fake urgency and unbacked claims:**
- TODAY'S DEAL counts down to UTC midnight and resets every day, the fake-urgency pattern the research forbids;
- the first event card always wears a hard-coded 'FAN FAVOURITE' pill with no data behind it. *Evidence:* - HudPlus.luau:583-595, :343-346 and :669 ('Ends in').
- EventShop.luau:342 and :518-525.
- RESEARCH_V4.md:86 and :176 (no fake countdowns or untrue claims). *Fix:* Delete the big WEAPONS button, Deal, the sandbox column and Packs, along with their slots and checks. Remove the 'FAN FAVOURITE' pill, or drive it from real purchase counts. Any future deal timer must be honest: a real fixed end or a per-player first offer.
- **[low/medium/S] Small landscape phones silently hide equipped slots.** On a landscape phone the bar shows only the slots that fit between the stick and GRAB/SHOOT, at least 3. On an iPhone SE (667x317) that is 4 of the 6 slots. A weapon equipped into slot 5 or 6 vanishes from the bar with no hint. The catalog still says EQUIPPED. *Evidence:* - PokeController.luau:489-497 and :584-586.
- GAP 8 and EDGE 10 (PokeController.luau:74-75).
- PHONE_THUMB_RIGHT 196.
- LayoutCheck.luau:45 (iPhone SE 667x317). *Fix:* Cap equip on that screen to the shown count: the catalog asks to replace a visible slot. Or add a '+2' chip at the bar's end that cycles the hidden slots.
- **[low/medium/M] Settings lack graphics, HUD and handedness options.** Settings has sound, camera shake, motion, UI size and the dead monitor. Phones are the main platform, but there is:
- no graphics preset (Auto/Low/High), even though DeviceTier caps exist in code;
- no hide-HUD option;
- no left-handed swap or button layout;
- no aim-assist toggle. *Evidence:* - Settings.luau:164-213.
- Config.luau:113-117 and :136-140 (device caps exist).
- Vault 'Graphics and Performance Toggles for Low-End Devices', 'UI Scale HUD Hide and Compact Mode' and 'Mobile Button Layout Editor'. *Fix:* Add rows:
- Graphics (Auto/Low/High), driving FX_CAPS and the lighting;
- HUD (Full/Compact/Hidden, with critical buttons exempt);
- Handed (Right/Left), mirroring HudSlots x for touch;
- Aim help.

Move the Dead monitor row behind 'Doctor mode'.
- **[low/medium/M] The weapons window on phones shows about 4 of 69 weapons at a time and holds an unrelated doctor switch.** Cards are 182x346 design units and the phone picture shrinks to 40 px. On a portrait phone that leaves 2 columns and about 2 rows in view. Each locked card stacks a kills bar, a Robux BUY and TRY FREE. There are 4 shelves (MELEE, GUNS, BOMBS, SPECIALS).

The doctor-mode / hospital monitor switch sits under the shelf, unrelated to weapons. The header line reads 'x/69 OWNED · Locked: earn kills, BUY, or TRY FREE for 2 min'. *Evidence:* - ToolCatalog.luau:33 (CARD 182x346), :40 (WINDOW 820x780), :46 (ICON_PHONE 40), :287 and :473-490 (hospital button). *Fix:* Phone grid of 3 columns with 90 px pictures and the name, details on tap.
- Filter chips: Mine / Next / All, with 'Next' first so the next 3 unlocks show at the top.
- One price button per card.
- Move doctor mode to Settings.
- **[low/low/S] Text measured with the wrong font; HUD captions can drop to about 9 px.** PokeController.wordWidth measures slab words with Enum.Font.FredokaOne, but under UI_CLEAN the display face is Builder Sans ExtraBold, so icon-only and wrap decisions use the wrong widths. The kit's HUD caption floor is lowered to 11 design units, and with the 0.85 HUD scale that draws about 9-10 px, under both the game's own 14 px floor and the vault's 12 px. The key chip is fixed at 12 px. *Evidence:* - PokeController.luau:143-148.
- LihFolkUITheme.luau:481.
- HudMenu.luau:59-60 (HUD_CAPTION_MIN 11, HUD_SCALE 0.85).
- HudPlus.luau:115 (KeyChip TextSize 12).
- Vault 'Responsive UI' ('12 px text'). *Fix:* Measure with GetTextBoundsAsync and Theme.Fonts.display. Raise HUD_CAPTION_MIN to 14 / 0.85 (about 17) or shorten the words. Key chips at 14 px or more.
- **[low/low/S] The same information shows in two or three places.** - **Ammo:** by the crosshair and on the slab.
- **Key teaching on PC, three times:**
  - the HudV3 chips 'F Ragdoll  X Revive  Z Slow-mo  V View';
  - the help line '1-6 switch · T all weapons · B sandbox';
  - key chips on the launchers.
- **LAB VIEW:** a top-right button even under HudV3 (LabCamera ignores HudGate), and also a row in the Lab window.
- **First person:** a chip and a Lab row. *Evidence:* - CLAUDE.md Phase 2 (AmmoClient '12 / 17' by the crosshair and on the slab).
- HudV3.luau:192 and :356-380.
- PokeController.luau:369-387.
- HudPlus.luau:600-605.
- LabCamera.luau:477-549 (no HudGate check). *Fix:* One place for each piece of information:
- ammo by the crosshair only;
- on PC, one key strip after the first minute, with the help line reduced to what the picked weapon does;
- LAB VIEW as a button OR a Lab row, not both.

**Cut or hide:** HudPlus big red WEAPONS button, TODAY'S DEAL card (with its daily midnight countdown) and the sandbox column: never visible under the current Config, so delete the code and their LayoutCheck slots; EventShop Robux 'packs' HUD column: never enabled (EventShop.luau:342); delete; Hard-coded 'FAN FAVOURITE' pill on the first event card (EventShop.luau:518-525); The two-line medical hit card (pulse, health %, DEAD/OUT COLD) outside opt-in doctor mode: replace with a 1 s KO pop; Doctor-mode/hospital switch under the WEAPONS shelf (ToolCatalog.luau:473-490) and the 'Dead monitor' row in Settings: move both into one opt-in 'Doctor mode' row; OnboardingController's bar hint 'Tap the dummy to shoot!' and the spinning neon cube over the greeter while FirstVisit runs: keep one pointer and one line; CLIPS & LIVE (TikTok streamer tools) in every player's MENU: show it only to creators (Streamer attribute); STREAMER F1-F8 gift keys and Wish keys in the KEYS list for normal players; The ticking mm:ss timer on every experiment card (keep it for timed or party cards only); Emoji in player text (🧪 🎁 ⭐ 🔩 📖 🎉 🥚 👇): use drawn icons; Duplicate ammo count on the bar slab; PC key chips for Revive and Slow-mo in the first visit: show them after the first minute only, merged with the help line into one strip; LAB VIEW as both a top-right button and a Lab window row on PC: keep one; The separate 'RANK & EGGS' window: fold eggs into REWARDS/WEAPONS and rank into the level pill; The level badge plus XP line on phones once a Next-weapon pill exists (two progress meters for one goal); Two of the three theme token layers (the dark-glass base and the UI_V2 navy/Fredoka block): bake the UI_CLEAN values into one set

### J - Audio (hit sounds, guns, ambience, music, UI sounds, mix: SoundMix, SoundManifest, FxController): 3.5/10
Paths are relative to C:\Users\tristan\Documents\RagdollLab. The plumbing is decent. There is a mix bus (StarterPlayerScripts/.../Client/SoundMix.luau), a pooled voice system with variants, burst thinning, priority and stealing (Client/FxController.luau:34-288), one real recording per gun (Shared/SoundManifest.luau:166-310), and reload sounds. What the player actually hears is poor. Most moments that should feel rewarding are silent or play the wrong sound: the 'reward' UI slot does not exist, the egg wobbles are silent and the egg crack is a light-switch click, and the human cannon and BULLSEYE get the same whoosh plus slide whistle. There is zero ambience: the only ambient sound was the birds, now off. Ranged hit confirms are positional at the target and fade with distance, and there is no kill or headshot sound. Hazards, events and explosives share a handful of generic cartoon sounds (the grenade throw plays a punch; the C4 promises beeps that do not exist; the Nuke sounds like C4). The minigun spin-up and railgun charge are cut-down reload recordings. Real-firearm and flesh-squelch recordings clash with toy names, BLOOD off and the all-ages goal. Several gun sounds are third-party rips. There has never been a listening pass, a phone-speaker mix or any telemetry (docs/AUDIT.md:20 says '6 (unmeasured) ... no listening pass'). Against Slap Battles, Rivals, Fling Things and People, Pet Simulator 99 or Steal a Brainrot this sounds unfinished. It is not broken, but it is thin, repetitive and silent where it matters.

**10/10 means:** 1. **Every core verb has its own layered sound, and own actions are always heard.** Each verb is built from transient, body and a sweetener. Own shots, own hits and confirms play 2D or listener-close with under one frame of delay. That includes a crisp hit 'tick', a takedown 'thock' with a rising two-note chime, and a headshot 'ding'.
2. **Ragdolls have a voice.** Collision thuds depend on impulse and surface: plastic mannequin knock, metal clang, wood knock, soft grass. On top of that come rate-limited, kid-safe cartoon reactions (non-verbal 'whoa!', 'oof', 'wheee!' on a launch).
3. **Every attraction has a signature you can recognise with your eyes closed.**
   - Human cannon: fuse hiss, BOOM, flight whistle, then a BULLSEYE DING with a crowd cheer.
   - Lava: a bubbling loop that draws you in, plus a sizzle and a yelp.
   - Spikes: a thunk-boing.
   - Mace and wrecking ball: creak and whoosh loops.
4. **Explosives build tension.** Pin pull, fuse ticks that rise, C4 beeps that speed up, the RPG launch roar. The Nuke gets a siren, a falling whistle, a sub-bass boom, a short mild ear-ring and a long rumble, with the whole mix ducked.
5. **Rewards climb a ladder of sounds from one UI family.** Pop, tick, whoosh up and down, error buzz, coin, a three-note unlock, a five-note rare with shimmer, and a legendary fanfare. Egg shakes rise in pitch, then a crack, then a stinger by rarity. Nothing is shared with world sounds.
6. **Each zone has an ambience bed, crossfaded with hysteresis.** Lab hum, wind and distant birds; sea on Island; traffic in City; animals on Farm; distant drills on Army Base. Each event has its own stinger and loop (UFO hum, tornado wind, quake rumble). There is still no background music (owner rule), only short stingers.
7. **The mix is measured, not guessed.** Each asset is levelled by LUFS (a gain column in the manifest), each category has a ceiling, InverseTapered rolloff, a limiter, and a phone-speaker EQ profile (most players are on upright phones).
8. **Players control and feel it.** Separate Guns / Effects / UI / Ambience sliders, and HapticEffect pulses tied to the same events on phones and pads.
9. **Every sound is safe to ship.** Every id is owned or Roblox-licensed (no rips) and is checked live. Session_v1 records the SFX setting, the master-volume bucket and failed loads, so the team knows how many players are muted.

- **[critical/high/S] Every 'reward' sound is silent (unlocks, Robux purchases, day gifts, goals).** `C.playSound("reward")` is the sound for the game's biggest positive moments: a weapon unlocked, a weapon bought with Robux, the 7-day calendar gift and a goal done. Theme.Sounds has no `reward` slot, so playSound returns without a sound. All the player gets is Notify's soft chime, which is the light-switch click at volume 0.3 and pitch 1.25, then the UI group at 0.45. A paid purchase confirms with silence. *Evidence:* ProgressUI.luau:576, :594, :648; HudPlus.luau:229; ToolCatalog.luau:973 (Bought); LihFolkUITheme.luau:283-290 (slots: click/hover/open/close/success/error only); LihFolkUIComponents.luau:158-162 (empty slot returns); Notify.luau:50-57, :81-83 *Fix:* Add the slots reward, unlock, rare, legendary, purchase and error, with licensed stingers (Pro Sound Effects library), at 0.7-0.9 in the UI group. Route each call by importance: unlock = 3-note rising, purchase = coin plus sparkle, rare = 5-note. Add a test that every `playSound("<name>")` literal in the client resolves to a non-empty Theme.Sounds slot.
- **[critical/high/S] Egg opening is almost silent: the wobbles have no sound and the crack is a switch click.** The egg is the core collect loop, and players are already ignoring it. Its three wobbles call the `hover` slot, which is empty, so they are silent. The crack and Sunburst play the toggle-switch click. There is no reveal sound by rarity, so a legendary sounds exactly like a common. *Evidence:* ProgressUI.luau:228-237 (playSound("hover") per wobble), :239-240 (Sunburst + playSound("click")); LihFolkUITheme.luau:285 (hover = "") *Fix:* Wobble ticks that climb in pitch (1.0, 1.15, 1.3) and volume, a crack/pop on the burst, then a stinger by rarity, synced to the card's pop-in: common pop; rare chime; epic chime plus whoosh; legendary fanfare plus a low boom that ducks everything else. Keep it under 2.5 s and skippable.
- **[high/high/M] Ranged hits give no audible confirm; no takedown, KO or headshot sound.** A gun hit on a dummy plays the flesh sound at the dummy's position. Sounds start fading at 10 studs with Roblox's default Inverse rolloff, so a hit at 40 studs plays at about 25% (and lower in LAB VIEW, where the camera sits 28-95 studs back). Takedowns, the 'KO!' stamp and headshots are visual only. The research asked for own shots and confirms in 2D; that was never done. Rivals and Arsenal make the hit tick and the kill chime the core of the loop. *Evidence:* FxController.luau:112 (RollOffMinDistance 10), :916-917 (flesh at target), :285 (reach); no RollOffMode set anywhere; Crosshair.luau:133 (KO! visual only); docs/RESEARCH_V4.md:126-127 and table #11 ('own shots 2D') *Fix:* Play these 2D (SoundService:PlayLocalSound, or a voice parented to the camera), each with a pitch ladder:
- a short hit 'tick' on the confirmed hit echo;
- a takedown 'thock' with a rising chime on the server's takedown;
- a headshot 'ding';
- the player's own muzzle sound.
Keep others' shots 3D with InverseTapered rolloff.
- **[high/high/S] Human cannon and BULLSEYE (the lab's star wow) have no payoff sound.** The cannon launch sends 'CannonPad'. In the client that is the 'Big' style: a whoosh plus a slide whistle. There is no cannon boom, even though a cannonShot bank exists. Landing on the BULLSEYE sends the same 'CannonPad', so the reward sounds exactly like the launch. The 'BULLSEYE!' notice is a silent toast. This moment also triggers the like/favourite ask. *Evidence:* ServerScriptService/Server/Systems/Playground.luau:219 (launch), :144-145 (bullseye + notice); FxController.luau:942-947 (Big = whoosh + whistle); SoundManifest.luau:83-86 (cannonShot used only by Cannon toy/RPG) *Fix:* Give them separate fx ids (CannonLaunch, Bullseye).
- Launch: a 0.3 s fuse hiss, the cannonShot boom with a duck, then a flight whistle that follows the body.
- Bullseye: a target DING, a short crowd cheer, a coin chime in 2D, and a light haptic.
- **[high/high/M] Zero ambience: lab, plaza and the 5 open-air maps are silent between hits.** The mix has an 'Ambient' group described as 'the place's hum', but the only thing ever routed to it was Birds, which the owner switched off. No zone has a bed: no lab hum, no sea on Island, no traffic in City, no animals on Farm, no drills on Army Base. Silence makes the world feel empty and cheap, and it makes every hit stand out as a lone sample. *Evidence:* SoundMix.luau:10; Birds.luau:468 (only user of Ambient); Config.luau:165 (BIRDS = false); grep: no other Looped world beds in Client/ *Fix:* Write a Client/AmbientZones module that defines beds per Places id as data. It plays one voice per bed asset, crossfades equal-power with dwell hysteresis, polls at 4-10 Hz, starts each bed at a random offset, and plays in the Ambient group at about 0.35, ducked by blasts (vault: Ambient Soundscapes). Use licensed Pro Sound Effects beds. Keep them low and calm, not music.
- **[high/medium/M] Explosives sound wrong or generic (grenade = punch, no C4 beeps, Nuke = C4).** - The grenade throw sends 'Grenade', which no branch handles, so it falls into impact() and plays the punch 'hit' bank plus sparks. There is no pin pull and no tick during the 3-second countdown label.
- The C4 blurb promises 'Beep. Beep. BOOM', but no beep sound exists anywhere in the game.
- The RPG launch is a musket 'cannonShot'.
- The Nuke, the top of the ladder at 1450 takedowns and the best TikTok moment, plays the same boomBig plus debris as C4 and RPG three times. Burst thinning (BURST_MAX 3) trims it, and the falling bomb has no whistle or siren. *Evidence:* ToyService.luau:505-515 (count label, FxService.hit 'Grenade'); FxController.luau:996-1000, :941-988 (no Grenade branch); Toys.luau:260 (C4 blurb); ToyService.luau:646 (RPG CannonFire), :661-689 (Nuke: 3x BigBoom + Shockwave); FxController.luau:39, :823-853 (bombFall silent) *Fix:* Give each explosive its own sound plan:
- Grenade: pin pull, throw whoosh, 3 ticks that rise in pitch.
- C4: beeps that speed up.
- RPG: launch roar plus a rocket loop on the projectile.
- Nuke: siren (2 s), falling whistle synced to bombFall, one sub-bass boom with a long rumble, a 1.5 s ear-ring through a low-pass on Effects (mild), and every group ducked.
Give the Nuke its own id so it skips burst thinning.
- **[medium/medium/S] Minigun spin-up and railgun charge are chopped reload recordings.** - The minigun 'whine' is FxController.reload('Minigun', 0.45), which plays 'M9K M134 minigun reload' cut short.
- The railgun's 'rising hum' is reload('Railgun'), which plays the 'AR Reload' magazine sound.
- There is no spin-down at all.
- The minigun fires as re-triggered 0.27 s one-shots instead of a loop, so it stutters. *Evidence:* GunFeel.luau:8-9 (promised whine/hum), :98, :120, :253-256 (spin-down: no sound); SoundManifest.luau:204, :208, :276-279, :307-308 *Fix:* Add spinUp, spinLoop and spinDown banks for the minigun, plus a fire loop with a light per-round transient. Add a railgun charge whine whose PlaybackSpeed rises with the ring's fill, then the shot. Keep reload banks for reloads only.
- **[medium/medium/S] Realistic gunshots and a flesh squelch clash with toy names, BLOOD off and the all-ages goal.** TOY_NAMES renames the guns to toys (Popper and so on), BLOOD is off, and the dummies are plastic mannequins. Yet every round into a body plays 'flesh_impact_bullet' squelches, and guns are close-mic real 9mm, magnum and rifle recordings at volume 0.9-1.0. That reads as realistic violence, which is exactly what the maturity questionnaire for all ages has to avoid. It is also tiring at 10 shots a second. *Evidence:* SoundManifest.luau:166-170, :211-216 (flesh), :254-310 (volumes); FxController.luau:916-917; Config.luau:34 (BLOOD off), :37 (TOY_NAMES); docs/RESEARCH_V4.md:131-137 *Fix:* When BLOOD='off', swap the flesh bank for a plastic mannequin 'thwack/knock' plus a small pop. Owner decision: a 'toy-real' gun layer that keeps the punchy transient, adds a bright toy sweetener and cuts the room tail by half, behind a Config switch.
- **[medium/low/M] Gun sounds include third-party rips (Pixel Gun 3D, M9K Garry's Mod pack).** These are copyright and takedown risks:
- 'Generic Laser Shot 3 (PG3D Impulse Sniper Rifle)' is from a commercial game.
- 13 'M9K ...' uploads by one group are re-uploads of a Garry's Mod pack whose sounds come from commercial titles.
- 'HM Magnum/Shotgun' has an unclear origin.
A takedown drops the gun to its fallback, a pitched small 'boom', with nobody noticing. *Evidence:* SoundManifest.luau:175-178, :190-209 (M9K), :202 (PG3D); fallbacks :256-310; vault note 'Music Licensing and Audio Upload Rules for 2026' (third-party ids: re-upload with rights or replace) *Fix:* Replace them with the Roblox-licensed Pro Sound Effects firearm/sci-fi library, or with owned or commissioned recordings uploaded by the game owner. Add a source/licence check to T41, and a live load check that reports failures (see the telemetry finding).
- **[medium/medium/S] The starter gun's sound is never preloaded first ("G17" key bug); all 115 assets load at boot.** FxController preloads `{ "G17", "Deagle", "Shotgun", "Revolver" }` first. The G17's GUNS key is 'Blaster', so `SoundManifest.GUNS["G17"]` is nil, and neither the starter gun nor the flesh bank gets first place. Then all 115 assets (230 Sounds on PC) go into one PreloadAsync, competing with the phone's first-minute download, including long blast tails that are used much later. An own shot that has not loaded within 0.35 s is dropped silently. Phones were 'nearly silent' once before. *Evidence:* FxController.luau:1455-1481, :48-50, :41-45; SoundManifest.luau:254 (Blaster); Toys.luau:290 (DEFAULT_LOADOUT Blaster) *Fix:* Use 'Blaster'. Preload a starter set first (g17, flesh or its mild swap, hit, land, whoosh, reloadPistol, UI slots). Load the rest after 20 s or when a weapon is unlocked or equipped. Count Failure statuses and send them to SessionStats.
- **[medium/medium/M] No listening pass, no loudness levelling, no phone-speaker mix.** SOUND_MIX values are guesses. Community uploads differ a lot in loudness, and there is no gain column. The Effects bus has only a soft compressor (threshold -14, ratio 3): no limiter, no EQ. Most players are on upright phones whose speakers lose the low body of gun and blast samples. Rolloff is the Roblox default (Inverse, hard cut at max distance) everywhere, though the research asked for InverseTapered. The reward chime ends up about 6x quieter than a gunshot (0.135 vs 0.855 effective). *Evidence:* Config.luau:190 (SOUND_MIX); SoundMix.luau:52-60; FxController.luau:283-285; Notify.luau:56; docs/AUDIT.md:20 ('no listening pass'); docs/RESEARCH_V4.md:126 *Fix:* Measure the LUFS of every asset and add `gain` to SoundManifest entries. Set category ceilings (Weapons -14, Impacts -16, UI -18, Ambient -26 LUFS). Use RollOffMode InverseTapered. Add a limiter (compressor ratio 20 at -3 dB). On a PHONE tier, add an EqualizerSoundEffect profile on Effects (low shelf -6 dB, mid +3 dB). Do one recorded listening pass per device tier.
- **[medium/medium/S] Every melee tool sounds like the same punch; Slap has no slap.** Punch, Slap, Kick, Shove, Poke, Uppercut, Glove and MegaSlap all play 'Punch Kit Beefy Hit 1-8', pitch-scaled by power (small hits go chipmunk at 1.21). Slap Battles' whole identity is its slap sound. Pan and Hammer share one clang sample (one variant). *Evidence:* FxController.luau:1000 (hit for all), :665-675 (WEAPON_HITS covers only Bat/Golf/Axe/Cleaver/Katana/PlasmaBlade/Chainsaw/Crowbar/Crossbow), :948-951; SoundManifest.luau:29-38, :146-148 *Fix:* Add banks of at least 4 variants each: slap (crisp hand slap), kick (boot thud), glove (padded 'boof'), shove (soft push), hammer (squeaky toy plus thunk), and 3 more clangs. Keep the pitch swing to 1.0-1.12 so small hits never sound chipmunky.
- **[medium/medium/M] Hazards and events reuse a handful of cartoon sounds (slide whistle everywhere).** - Lava, the wrecking ball and the mace send 'CannonPad' (whoosh plus slide whistle).
- The spike blocks send 'Trampoline' (a 'Magic Transformation' boing plus a whistle).
- Every server event starts with the same slide whistle plus boing. V7 notes it is still the old sound.
- The slide whistle plays on CannonPad, SpringPad, Trampoline, BananaPeel, Uppercut and Event.
- Hazards have no loops, so nothing draws players to them by sound. *Evidence:* Playground.luau:591 (lava), :634 (spikes), :706, :287; FxController.luau:1088-1092, :1132-1143, :942-947, :1202-1205; docs/V7_PLAN.md:269, :318 *Fix:* - Give each hazard its own id (Lava = sizzle plus yelp, Spikes = thunk, Mace/Ball = metal clang plus whoosh).
- Give each hazard a looped positional bed (rolloff 40) as a lure.
- Add a per-event stinger and loop table in Shared/Events data (siren for Mega Bomb, hum for UFO, wind for Tornado, rumble for Earthquake).
- Keep the slide whistle for the banana peel only.
- **[medium/high/M] Dummies and lab creatures have no voice.** The dummies are the stars, and they react with hands up and fleeing, but make no sound at all (bubbles are off too). The 9 lab creatures (spider, plant, frog, whale, chicken, washer, mole, vacuum) animate in CreatureLife but are mute. The gorilla's roar is a 'Giant Crab Monster' sample pitched down with PlaybackSpeed, which sounds slow and blurry (vault). Its one-shots are new Sounds made per play with no preload, so the first roar can come late. Top hits use character audio as the hook (Steal a Brainrot's voices). *Evidence:* CreatureLife.luau (no Sound use); CreatureAnim.luau:25-29, :49-70; DummyLife bubbles off (CLAUDE.md M11) *Fix:* Add a licensed bank of 8-12 non-verbal cartoon reactions (whoa, oof, wheee, grumble). Play one on launch, a hard landing or a takedown, at a 30% chance, at most once per 1.5 s per lab, with a pitch per dummy, in a new 'Voices' group. Give each creature its own sounds (ribbit, cluck, whirr, spin, slurp) and preload them.
- **[low/medium/S] Landings play two or three layered thuds (hollow, doubled sound).** With FEEL_V2 on, one Land event plays a 'land' sample in FxController. FeelV2.flop then plays a second 'land' variant at another pitch, and at higher speeds adds a 'hit' or 'slam' layer. Two different takes of the same thud at once cause phasing, the vault's 'hollow, doubled sound'. *Evidence:* FxController.luau:1179-1187, :1213-1220; FeelV2.luau:236-251; FeelTuning.luau:92-101; Config.luau:130 (FEEL_V2 = true) *Fix:* Give one module the landing sound: when FeelV2.ON, FxController skips its 'land' play and FeelV2.flop owns the layers, tuned so each speed tier plays one main sample plus at most one different-spectrum layer.
- **[medium/medium/S] UI sounds reuse gameplay sounds; there is no coherent UI palette.** Window open and close play 'Synth Air Whoosh Cheesy Karate Style Swishes 3', which is also the 7th whoosh variant for punches. The 'success' sound when equipping is 'Magic Transformation 6', which is also in the boing bank (trampolines, balloons, gifts, events). The Notify chime is the switch click pitched up. There is no error sound and no hover sound. *Evidence:* LihFolkUITheme.luau:284-290; SoundManifest.luau:53, :131-136; Notify.luau:55-57; PokeController.luau:736, :764, :1710 *Fix:* Use one family of UI sounds from the same synth palette, not shared with any world bank: soft pop (open), soft pop down (close), tick (press), error buzz, equip 'clack', and the reward ladder from finding 1.
- **[medium/low/S] No telemetry on whether anyone can hear the game.** Session_v1 records device, input and the funnel, but not the in-game SFX setting, Roblox's master volume (many phone players play muted) or failed sound loads. T41 only checks manifest fields, never that the ids load live. Audio work is prioritised blind. *Evidence:* ServerScriptService/Server/Tests/T41_SoundManifest.luau:21-36; Settings.luau:29-37 (sfx value, not reported); SessionStats/SessionClient (no sound fields); FxController.luau:1470-1480 (failures removed silently) *Fix:* Record in Session_v1: the sfx setting, a master-volume bucket from UserSettings():GetService('UserGameSettings').MasterVolume (0, under 0.3, under 0.7, otherwise), and the count of failed sound loads with the first 3 ids. Show them in tools/SessionReport per device.
- **[medium/medium/S] No haptics on phones or pads, which are most of the players.** There is no HapticService or HapticEffect use anywhere. HapticEffect is fully released (2025) and works on most iPhones, Pixels and Galaxies plus gamepads. On muted phones, a pulse would be the only physical feedback. *Evidence:* grep HapticService/HapticEffect: no matches in StarterPlayerScripts or ReplicatedStorage; https://devforum.roblox.com/t/full-release-you-can-now-publish-haptic-effects-in-your-experience/3660577 *Fix:* Add a Client/Haptics module tied to the same moments: a light pulse on the own shot (thinned to 10/s), hit confirm, takedown, a near blast, the cannon launch and the egg crack. Add a Settings 'Vibration' toggle.
- **[low/low/S] Settings and routing gaps: one global volume, the horn ignores OFF, slow-mo pitches the UI.** Sound settings are a single NORMAL/QUIET/OFF for everything, so players cannot turn guns down and keep rewards. The vehicle horn is a server-made Sound with no SoundGroup, so it plays even with sound OFF. The slow-mo PitchShift sits on the Effects parent group, so UI clicks and the monitor pitch down too. *Evidence:* Settings.luau:32, :164; ServerScriptService/Server/Systems/VehicleService.luau:297-301; SlowMotion.luau:98-103, :156-158 *Fix:* Add sliders for Guns, Effects, UI and Ambience (group volumes times the Config mix). Play the horn on the client in the World group from the VehicleHorn remote. Move the PitchShift onto World, Impacts and Weapons only, plus a low-pass swell for slow-mo.
- **[medium/medium/S] Kill and level-up are silent by owner request; question that.** The owner asked for a quiet HUD on 10 Nov, so the '+1 TAKEDOWN' pop and the level-up are silent. A subtle 2D kill confirm and a short level-up stinger (not music) are standard in every top Roblox hit and cost nothing visually. Silence here removes the progression beat the data says is missing (median visit about 120 s, almost nobody past 5 min). *Evidence:* CLAUDE.md v0.17.0 ('+1 TAKEDOWN small, silent', 'silent level-up'); ProgressUI.luau:599 *Fix:* Propose a subtle takedown 'thock' (0.15 s, UI -20 LUFS) and a 1 s level-up stinger to the owner. If they agree, add them; otherwise keep silence behind a Config switch.

**Cut or hide:** Slide whistle on CannonPad, SpringPad, Trampoline, Uppercut and Event (keep it only for the banana peel): it reads as cheap when everything uses it (FxController.luau:942-947, :1088-1143, :1202-1205); The 'Magic Transformation' boing as the UI success, gift, balloon, spike and event sound: one boing for 6 meanings; The second and third landing layer (FxController Land plus FeelV2.flop): keep one owner; The flesh_impact_bullet squelch while BLOOD = 'off' (swap it for a mannequin knock); Random 'Ricochet Reverberant' whines on 25% of ground hits (FxController.luau:884, :903-905): clutter in rapid fire; Dead-monitor beep and alarm (HospitalCharts): keep it off by default and out of the audio budget; Dead playSound("hover") and playSound("reward") calls: fill the slots or remove the calls; The server-side horn Sound (VehicleService.luau:297-301): move it to the client; Preloading all 115 assets at boot: load rare banks (nuke, railgun, minigun, debris, boomBig) lazily; Reload recordings used as the minigun spin-up and railgun charge; The punch sound and sparks on a grenade throw

### K - Performance on low-end phones (part counts, client loops, physics bodies, particles, streaming, memory, network): 4/10
There is real performance engineering in the code: DummyLife has distance LOD, FX_CAPS/DEVICE_CAPS tiers exist, sounds and particles are pooled, BillboardGuis have MaxDistance, dummies use Atomic/PersistentPerPlayer streaming, and code-built decoration is anchored and shadowless. It still scores 4 because:

1. **Never measured where players are.** It has never been measured on a phone. Session_v1 says most players are on portrait phones (414x814). The only measurement is one PC run in Studio with one player and no other labs (docs/AUDIT.md:60-66: 60 fps, 2,835 parts). That run came before V6/V7 added about 627 garden parts and 360 path parts per lab, 9 creature models with 8 habitats, cars, booths and the landscape. The audit itself says "the phone tier cannot be emulated over MCP" (AUDIT.md:65).
2. **No live numbers.** There is no fps or memory telemetry, so nobody can tell whether the phones that leave at about 120 s leave because of lag.
3. **Structural costs scale with players.** Other players' labs are streamed in and replicated, then only reparented out of sight on the client (PlotPrivacy). A phone simulates and uploads about 12 active ragdolls with no physics sleep. An always-on 30 Hz replay recorder walks GetDescendants of every nearby body. Big creatures are CFrame-animated on the server every Heartbeat. 115 sound assets are preloaded at join. There are about 55 per-frame client connections. There is no Low/High graphics setting, and the device tier is guessed from the platform, not measured.

Top Roblox hits in 2026 (Grow a Garden, Steal a Brainrot, 99 Nights) and the light ragdoll leaders (Ragdoll Engine) win on phones with small instance counts, a tuned streaming radius and capped or sleeping physics bodies. This game has grown in the other direction without a budget gate.

**10/10 means:** **Measured on real low-end devices, every release, with a hard gate:**
- The owner's phone and a 3 GB Android (Helio G85 / Snapdragon 680 class) hold a locked 60 fps in an idle lab. In the busiest scripted moment (6 players, a chase, a cannon launch, an event) they hold at least 30 fps p5, with no frame over 50 ms.
- Client memory stays under 800 MB on the phone (under 600 MB is the ideal).
- Join to first control: 8 s or less on 4G.
- In the spawn view: under 2,500 streamed parts, under 1,000 draw calls, under 400k triangles, at most 8 lit lights.
- Network: down under 30 KB/s and up under 8 KB/s per phone in chaos.

**Live telemetry:** Session_v1 stores fps p50/p5, worst second, memory MB, ping, quality level, join time and device tier for every visit. SessionReport shows them per build x device. RELEASE.md refuses a build whose phone p5 fps or memory regresses more than 10%.

**Adaptive quality:** a Settings row "PERFORMANCE: AUTO / LOW / HIGH". AUTO picks the tier from measured frame time with hysteresis (slow to rise, quick to fall), not from the platform. LOW turns off decorative particles, lamps, creature idles, skin details, the replay recorder and shadows on props, and lowers the ragdoll count.

**Interest management:**
- A neighbour's lab is never on your device. Plots are far enough apart, or the streaming radius is tuned so it falls outside, and nothing relies on client reparenting.
- FX, aim and physics only go to players who can see that lab.

**One client scheduler:** a per-frame bucket only for the camera, aim, crosshair and the viewmodel. HUD polling runs at 10 Hz / 2 Hz or is event-driven. No per-frame allocations, so there are no GC hitches.

**Physics LOD:** standing or calm bodies go kinematic and asleep. Lying bodies freeze after 4 s. The phone tier simulates at most about 8 bodies. Event creatures animate client-side from one server start message.

**A lean world:**
- Each lab is at most about 2,000 parts / 150 unique meshes, with paths painted into terrain or merged into a few MeshParts.
- Nothing decorative lies outside the player's sightline.
- No legacy Fire objects.
- ReplicatedStorage holds only what the first minute needs (start-bar guns, UI). Weapon models and sound banks arrive when a weapon is unlocked or an event starts.

- **[critical/high/M] Performance has never been measured on a phone; the one PC measurement predates most of today's world.** The only performance numbers come from one PC run in Studio with a single player and no other labs: 60 fps, worst frame 21 ms, 2,835 parts streamed, 42 KB/s. That run was before V6-4 (garden, about 627 parts per lab), V6-5 (9 creature models and their yard), V7-2 (360 path parts per lab), the creature habitats, the CreatureLife animator, booths and the landscape trees. The real audience (Session_v1, 72 h) is mostly upright phones at 414x814, then PC, tablet and console. AUDIT.md still lists 'phone frame-time checks' as open, and V6 has several 'done when the phone frame time is OK' items that were never closed. Performance is effectively unknown for most players. *Evidence:* docs/AUDIT.md:22 (Performance 5, unmeasured), :60-66 (PC-only run; 'The phone tier cannot be emulated over MCP. A real phone test is the owner's.'); docs/V6_PLAN.md:114, :138, :153, :460 ('Still open: ... phone frame-time checks'); docs/V6_PLAN.md:307 (627 parts per lab); docs/V7_PLAN.md:350 (360 path parts per lab); T37_Performance.luau:1-31 measures only the server's heartbeat (and fails at about 24 Hz on the dev PC, CLAUDE.md M10) *Fix:* Write docs/PERF_TEST.md: 5 fixed scenes (spawn at 10 s, a chase at 100 s, a cannon launch plus a bullseye, an event (gorilla or bulls) with 3 players, the WEAPONS window open). Run them on the owner's phone and on a cheap 3 GB Android. Read the in-game Dev Console (F9 / the on-device MicroProfiler) and record fps, frame time, memory by tag and network. Repeat every release and record the numbers in RELEASE.md as a gate. Until then, treat every new world feature as blocked on a phone number.
- **[critical/high/S] No fps/memory/ping telemetry in Session_v1: lag cannot be ruled in or out as the reason phones leave at 120 s.** SessionClient sends touch/keys/pad, the screen size, the boot time and the first shot. It sends no frame rate, memory, ping, graphics quality level or join-to-control time. The only fps/memory readout is the owner's admin DEBUG tab. With 1 of 11 visits past 4 min, the team cannot tell 'bored' from 'lagging or crashing'. The leading games track join time and fps per device (vault: Case Study - Fast Join and Deferred Loading). *Evidence:* StarterPlayerScripts/.../Client/SessionClient.luau:1-4, :38-60 (fields sent); GetTotalMemoryUsageMb appears only in ServerScriptService/.../AdminTools.luau:491 and Client/AdminPanel.luau:317; docs/RESEARCH_FIRST_SESSION.md:256 ('Long loading on phones: not measured here') *Fix:* In SessionClient, sample 1/dt every frame into a 5 s bucket and keep the median and p5 fps, the worst second and the frame-time spikes over 100 ms. Also read Stats:GetTotalMemoryUsageMb() every 15 s, the ping, UserSettings().GameSettings.SavedQualityLevel, and the time from start to first input and to first shot. Send at 60 s, 180 s and on leave (BindToClose / PlayerRemoving relay). Add columns to tools/SessionReport per build x device: fps p5, memory p90, left within 30 s of a frame-time spike. Optionally mirror it as AnalyticsService custom events.
- **[critical/high/M] Other players' labs are streamed and replicated to every phone, then hidden by client reparenting; their FX are sent and dropped, and their dummies are still animated.** Plots are 250 studs apart. No code sets the streaming radius, so the default (about 1024) puts all 6 labs (up to ±750) on every device. PlotPrivacy moves them out of Workspace into a client folder and never destroys them, so their memory stays and their property and physics updates keep arriving. FxService sends hits within 350 studs (more than a plot), so a neighbour's minigun (26 rounds/s) reaches you, and FxController throws it away after the network cost. DummyLife clears a dummy from `lives` only when its Parent becomes nil. A hidden dummy's Parent is the hidden folder, so it stays in the table and keeps being stepped at 15 Hz whenever it is geometrically on screen. Reparenting streamed instances on the client also fights the streaming system, which cannot stream them out properly. Per extra player this could add roughly 2,000 parts plus 6-11 ragdolls of about 15 assemblies each to a phone's memory and download (estimated, not measured). *Evidence:* Client/PlotPrivacy.luau:1-12 ('Things are moved into a folder outside the Workspace, never destroyed'), :58-66 (hide), :263-269 (0.5 s sweep), :123-147 (GetDescendants of hidden avatars every 0.5 s); Shared/Zones.luau:17 (PLOT_SPACING 250); Server/Systems/FxService.luau:36 (FX_REACH 350), :76-91; Client/FxController.luau:1041-1047 (drops hidden-lab FX after receiving them); Client/DummyLife.luau:1269-1307, :1324-1327 (ChildRemoved clears only pendingModels); vault 'Interest Management and Per-Player Replication' (no per-player exclusion API: radius or distance is the tool) *Fix:* 1. Set Workspace.StreamingTargetRadius to about 320, StreamingMinRadius to 96 and StreamOutBehavior to Opportunistic.
2. Spread the plots so a neighbour is always past the radius: PLOT_SPACING of about 900, or labs in a ring around the plaza. Teleport between labs and the plaza through the existing Travel flow.
3. Once the distance guarantees it, stop reparenting streamed instances in PlotPrivacy and keep only the fence and sign plus the server's Lab.keepOut.
4. Filter FxService.broadcast with Zones.mayEnter(player, plotAt(position)) and lower FX_REACH to about 160.
5. In DummyLife, drop `lives[model]` on Dummies.ChildRemoved.
6. Re-measure memory with 6 players.
- **[high/medium/S] Instant Replay records all the time: 30 Hz GetDescendants of every nearby body and prop, a new table each sample, and a full Clone of every dummy kept in memory.** ReplayController.record runs on Heartbeat at 30 Hz for every player, whether or not a replay will ever play. For every dummy and prop within 120 studs (the lab's 6-11 bodies, props, and the plaza crowd when near), partsOf() calls GetDescendants. A dummy is about 220 instances plus about 23 client skin parts and welds. Each sample builds a fresh {[BasePart]=CFrame} table and keeps 8 s of them (about 240 frames). That comes to roughly 90k instance visits and over 10k CFrame allocations a second, and about 100k CFrames held (my estimate). It also Clones every source the first time it is seen and keeps the clone for as long as the original exists, which doubles the memory of every dummy, skins included. On phones this means steady GC churn and hitches, for a feature most players never open. *Evidence:* Client/ReplayController.luau:16-19 (RECORD_HZ 30, KEEP_SECONDS 8, RANGE 120), :95-120 (sources(), partsOf() with GetDescendants), :121-148 (record(): Clone of each src, a new cfs table per sample), :489-501 (always-on Heartbeat); called only from OnboardingController.luau:183-186 and the Replay button (HudSlots.luau:54) *Fix:* 1. Cache each model's limb list once, on ChildAdded or when the dummy is dressed. Record only the 15 limbs of bodies in your own lab (Owner == me) plus props, at 15 Hz.
2. Write into a preallocated ring buffer of 120 slots holding arrays of CFrames (no new tables per sample).
3. Clone templates only when play() starts.
4. On the LOW tier, record only while the newcomer replay is due or the player has pressed Replay in the last 60 s.
5. Check the cost with the Script Profiler before and after.
- **[high/high/M] A phone simulates and uploads about 12 active ragdolls with no physics LOD or sleep; ActiveRagdoll does raycasts and attribute reads for every body every physics step.** Each lab's bodies are network-owned by that lab's player for life. A phone carries 6 lab dummies, 1 visitor, 4 chasers from 100 s, and its own avatar. Each dummy has 15 AnimationConstraint muscles plus ball sockets, about 15 assemblies. FX_CAPS.low.ragdolls is 14. ActiveRagdoll.update runs on PostSimulation for every rig with no distance or calm sleep. Every step it calls governSpeed, which raycasts through isAirborne on recently hit bodies. guardLimbs walks all parts' velocities and reads the 'Severed' attribute. vitalDown does a GetAttribute string lookup. A Standing body thinks every step, with more GetAttribute calls. A ragdolling or lying body raycasts isAirborne every step. The phone also uploads physics for all of these assemblies over mobile data. The DevForum consensus on ragdoll lag is to cap bodies, sleep or freeze them once settled, and avoid running ragdoll physics on every body all the time. *Evidence:* ReplicatedStorage/.../Shared/Config.luau:113-117 (DEVICE_CAPS low: visitors 1, chasers 4), :136-140 (FX_CAPS low ragdolls 14); Shared/DeviceTier.luau:1-5; Shared/Ragdoll/ActiveRagdoll.luau:266-269 (isAirborne raycast), :322-347 (governSpeed), :375-401 (guardLimbs), :1276-1361 (update over all rigs), :1369 (PostSimulation); Client/DummySim.luau:19-27 (15 AnimationConstraints); Server/Systems/ChaseService.luau:30-39, :118-121; DevForum 'Reduce lag when having alot of ragdolls' (https://devforum.roblox.com/t/reduce-lag-when-having-alot-of-ragdolls/1876872) *Fix:* 1. Cache the attributes that change rarely (IsDummy, Personality, Greeter, Severed, Vital, Home) through GetAttributeChangedSignal into the rig table.
2. Run think, vitalDown and the sink check at 10 Hz, staggered across rigs.
3. Cache isAirborne for 3 steps.
4. Sleep: after 3 s calm with no player within 30 studs, set the joints kinematic, skip guardLimbs and governSpeed, and wake on any hit or attribute change.
5. Freeze a lying, calm body after 4 s (weld or anchor its limbs) until it is touched.
6. LOW tier: 4 lab dummies, 0 visitors and 3 chasers during the first 5 minutes.
7. Measure the physics time ('Physics' / 'worldStep' in the MicroProfiler) on the phone before and after.
- **[high/medium/M] The lab has no whole-world part or mesh budget: garden, paths, creature yard, habitats, landscape and terrain kept growing past the only measurement.** There are only sub-budgets. T36 LAB_BUDGET 80 counts only Workspace.Labs markings. T106 caps the path stones at 400. Nothing bounds Playground.LabN with its Garden, CreatureYard and habitats, which is what a player actually sees.
- Each lab: about 627 garden parts (Creator Store hedges, trees, flower beds, benches, lamps, fountain, shed), plus 360 path parts with raised kerbs, plus 9 Creator Store creature models with 8 code-built habitats, plus 2 cars, plus the playground machines.
- Around all labs: 220 Creator Store trees, bushes and rocks.
- Terrain hills over about 3,600 x 930 studs, about 45k FillBlock columns, most of them behind 14-stud hedges that nobody walks to.
- V3Assets.place and LabGarden.place never set CastShadow, RenderFidelity or CollisionFidelity on imported models, so leafy Creator Store trees and hedges cast shadows and keep their import settings. *Evidence:* docs/V6_PLAN.md:300-307; docs/V7_PLAN.md:211-217, :350; Server/Systems/LabGarden.luau:47-75 (place: no CastShadow or fidelity change), :96-150; Server/Systems/Landscape.luau:18-26 (SIDE 420, DEPTH 360, PEAK 110, TREES 220), :76-104 (FillBlock loop), :132-143; Server/Tests/T36_Models.luau:36-39 (LAB_BUDGET 80 = markings only); Server/Systems/V3Assets.luau (no CastShadow/RenderFidelity handling); vault 'Art Budgets' (one fully dressed zone 3k-10k instances; draw calls before triangles) *Fix:* 1. Add a T-test that counts BaseParts, unique MeshIds, lights and emitters under Playground.LabN + Labs.LabN for one lab. Assert at most 2,000 parts, 150 unique meshes and 8 lights, and print the top 10 folders.
2. Paint the paths into terrain (Ground/Pavement/Cobblestone material via FillBlock on a thin slab) or bake them into 2-4 MeshParts per lab.
3. Set CastShadow = false on every imported decorative model and RenderFidelity = Automatic.
4. Landscape: SIDE 150, DEPTH 160, 60 trees, only in front of and behind the labs where the camera looks.
5. Run an art-audit print in Studio (vault script) and record the numbers in AUDIT.md.
- **[high/medium/M] No graphics or performance setting, and the device tier is guessed from the platform: every PC (including Chromebooks and old laptops) gets 'high', every phone gets 'low'.** DeviceTier.of maps phone to low, tablet/console/unknown to mid and everything else to high. A 2 GB Android and an iPhone 15 Pro get the same budget. A school Chromebook or an integrated-GPU laptop (the second-biggest audience) gets the high tier: 10 chasers, 3 visitors, 22 ragdolls, 14 lit lamps and 6 live 3D viewports. Settings has only sound, blood, shake, motion, UI size and the dead monitor, with no LOW mode. The vault and the leading games use Auto/Low/High presets, with an Auto mode driven by measured frame time and hysteresis. *Evidence:* Shared/DeviceTier.luau:14-21; Shared/FeelTuning.luau:25-33 (platOf from touch/keyboard only); Shared/Config.luau:113-117, :136-140, :240; Client/Settings.luau:28-37 (no performance row); vault '58 Player QoL/Graphics and Performance Toggles for Low-End Devices', '47 Game Feel/Juice on a Budget - Mobile and Low-End' *Fix:* 1. Add Settings 'PERFORMANCE: AUTO / LOW / HIGH'. AUTO measures frame time over 10 s windows: drop a tier after 2 windows under 40 fps, rise after 6 windows over 57 fps. Use the SavedQualityLevel as a ceiling.
2. Send the tier to the server (remote, validated to one of 3 values) so ChaseService and VisitorService use the measured tier, not the platform.
3. LOW: no decorative emitters or lamps, CreatureLife and BoothSpin off, DummySkins.DETAILS off, the replay recorder paused, CastShadow off on props, half the particle counts.
4. Remember the choice per player.
- **[high/medium/M] Event creatures and machines are animated on the server with PivotTo/CFrame every Heartbeat, so every frame of motion is replicated.** The gorilla, the bull herd, the tornado parts, the lab creatures' 'swallow' motions and several surprises move anchored multi-part models with PivotTo or .CFrame on the server's Heartbeat. There are 93 such writes across Creatures, Surprises, LabCreatures, ToyService and MapActivities. Each frame's CFrame for each part becomes a replicated property change to every client in range (and with the default radius, players in hidden labs too). The result is a heavy downstream on phones and visible jitter, because anchored parts do not get physics interpolation. The only network measurement, four events at once, was already 42 KB/s against the 50 KB/s budget, with one player. *Evidence:* Server/Systems/Creatures.luau:177-185 (place -> PivotTo), :214-240 (Heartbeat), :444-458 (tornado parts' CFrame every Heartbeat); Server/Systems/LabCreatures.luau:91-101 (play() PivotTo per Heartbeat), :340-357; grep: 93 PivotTo/.CFrame= writes in Creatures/Surprises/LabCreatures/ToyService/MapActivities; docs/AUDIT.md:63-64 (42 KB/s, 'watch it with several players'); T37_Performance.luau:31 (NET_BUDGET 50) *Fix:* Use the CreatureLife pattern for every moving set piece. The server sends one reliable message per event ({kind, seed, path points, t0 = GetServerTimeNow()}). Each client animates locally in a 30 Hz bucket and only within 160 studs. The server keeps its gameplay checks (who gets hit) at 10 Hz against the same deterministic path. Measure KB/s with 3 clients during the gorilla and the bulls.
- **[medium/medium/S] 115 sound assets are created and preloaded at join on every device, in one PreloadAsync call.** FxController.start makes a Sound for every id in every bank: one per id on phones, two elsewhere. It preloads all of them in one PreloadAsync: every gun recording with its long tail, every reload, blast, creature and UI bank. A newcomer owns 3 weapons and hears maybe 10 of these sounds in the first minute. On 4G this competes with streaming in the lab during the 0-35 s window the first-minute design depends on, and it holds the decoded audio in memory all visit. *Evidence:* Client/FxController.luau:1437-1482 (loadList over every BANK, one PreloadAsync), :48 (POOL 1 on phones); ReplicatedStorage/.../Shared/SoundManifest.luau (115 unique numeric asset ids); vault 'Case Study - Fast Join and Deferred Loading' (preload only first-screen assets) *Fix:* At join, preload only the start bar (Popper/G17, Punch, Grab), the hit and land banks and the UI clicks (about 15 ids). Load a gun's bank when it unlocks, is equipped, is tried free, or is within 2 kills of unlocking. Load event banks when the event banner fires (the event has a 2-3 s lead-in). Unload banks the player hasn't touched for 5 min. Log join-to-first-shot per device to confirm the gain.
- **[medium/medium/M] Join builds everything for everyone: owner-only GUIs, the full 69-card catalog, all windows, about 60 modules started synchronously.** Main.local starts about 60 client modules in a row before the player can act.
- Director.start builds the whole director GUI for every player; the only gate is Config.DIRECTOR, and the owner check comes later.
- ToolCatalog.start builds all 69 cards at join (about 32 GUI objects each, roughly 2,200 objects, with UIStrokes and TextScaled). The pictures are lazy, the cards are not.
- EventShop, RewardsUI, FriendsUI, CreatorUI, PortalUI and others build their windows up front as well.
- 44 ScreenGuis are created across modules.
On a phone this is a first-frame hitch and extra memory before the 35 s HUD reveal even matters. *Evidence:* Client/Main.local.luau:45-125 (start order); Client/Director.luau:767-772 (buildGui for everyone), :92 (IsOwner check used later); Client/ToolCatalog.luau:413-875 (card builder), :927-930 (build() in start); grep: 44 Instance.new("ScreenGui") in Client + LihFolkUI *Fix:* 1. Build each window on its first open (the Controller.register pattern already exists). Build catalog cards per shelf when the shelf is shown, and virtualize the list (vault 'Virtualized Lists').
2. Start Director and AdminPanel only when player:GetAttribute('IsOwner') becomes true.
3. Defer non-first-minute modules (Rewards, Friends, Creator, Portal, Minigame HUD, BoothSpin, CreatureLife) with task.defer after the first input.
4. Record join time (time() at Main start and at first input) in Session_v1.
- **[medium/medium/S] ReplicatedStorage ships content nobody uses yet: BirdModels while birds are off, and all 69 weapon models to a newcomer who owns 3.** Everything under ReplicatedStorage downloads to every client at join; streaming does not apply there.
- Birds were switched off by the owner, but ReplicatedStorage.BirdModels (4 skinned Creator Store birds: Pigeon, Crow, Gull, Hawk) is still replicated.
- N7Assets.Weapons holds all 69 weapon models (21 real mesh models among them), although a new player's bar holds 3 and the catalog draws pictures lazily.
- The DummySkin template and LihFolkUI are needed; the rest is join weight. *Evidence:* Shared/Config.luau:165 (BIRDS = false); Client/Birds.luau:152 (reads ReplicatedStorage.BirdModels); docs/V6_PLAN.md:368; Shared/N7Models.luau:5-8 (Weapons in ReplicatedStorage for every client); CLAUDE.md Phase 2b (21 real mesh models in N7Assets.Weapons); vault 'Case Study - Fast Join and Deferred Loading' ('Avoid: putting every model the client might ever need in ReplicatedStorage') *Fix:* 1. Move BirdModels to ServerStorage while BIRDS is false, and adjust T104 to look there.
2. Move N7Assets.Weapons to ServerStorage. Keep a small ReplicatedStorage set: the start bar and the next 3 unlocks.
3. Have the server parent a weapon's model into a per-player folder (PlayerGui or a Camera-child replicator) when it is unlocked, tried or bought, or when the catalog is opened (models first, then pictures).
4. The owner must save the place after the move.
- **[medium/low/M] About 55 per-frame client connections, most always connected and polling state, several allocating every frame.** Outside the necessary camera/aim/crosshair work, many HUD modules poll every frame:
- HudPlus.followBar does FindFirstChild on the PlayerGui and reads AbsolutePosition every frame.
- HudV3 writes root.Size every RenderStepped.
- ChaosMeter, ExperimentCard, EventShop (2 connections), MinigameHud and CreatorUI run on Heartbeat.
- AmmoClient builds the '12 / 17' string every frame.
- TouchShoot runs FindFirstChild('Zoom') every frame.
- AdminWorld does a GetAttribute('AdminClock') every frame for everyone.
- HospitalCharts has 2 RenderStepped connections, one doing GetLastInputType().Name and string.find every frame.
- Ui3D walks every tracked picture's ancestor chain every frame.
- Sprint, FirstPerson, GunFeel, BoothSpin and VehicleFeel (2) run every frame too.
Each one is small, but the total was never profiled on a phone. Per-frame strings and tables cause periodic GC hitches, which matter more than the averages. *Evidence:* grep RenderStepped/Heartbeat/BindToRenderStep in Client: about 55 hits, e.g. Client/HudPlus.luau:522-560, :651-672; Client/HudV3.luau:468-471, :554-562; Client/ChaosMeter.luau:209-214; Client/AmmoClient.luau:174-182, :225; Client/TouchShoot.luau:281-292; Client/AdminWorld.luau:136-150; Client/HospitalCharts.luau:1244-1281; Client/Ui3D.luau:79-97; Client/EventShop.luau:1426, :1467; vault 'Frame Budget' (spikes beat averages) *Fix:* 1. Add a Client/Scheduler with three buckets: every frame (camera, aim, crosshair, viewmodel, grab), 10 Hz (HUD followers, ammo text, touch zoom visibility, chaos meter) and 2 Hz (clocks, banners, the experiment card).
2. Replace polling with signals: GetAttributeChangedSignal, the AbsolutePosition/Size changed signals of the bar, and ViewportSize.
3. Write text only when the value changes.
4. Run the Script Profiler on the phone for 60 s of normal play and fix the top 5.
- **[medium/low/S] Aim is replicated as a reliable character attribute at up to 20 Hz per player, to everyone.** Each client sends its pitch and yaw about 10 times a second on an unreliable remote. The server then writes character:SetAttribute('Aim', Vector2) on every change of at least 0.02 rad, at up to 20 Hz. Attributes replicate reliably and in order to every client that has the character: with 6 players that is up to about 600 reliable updates a second of server send, including to players in hidden labs. This adds latency to the reliable stream that also carries hits and UI events. *Evidence:* Server/Systems/AimService.luau:1-5 (design), :10 (MAX_RATE 20), :11 (STEP 0.02), :45 (SetAttribute('Aim', now)); Client/AvatarMoves.luau:1018 (consumer on PreSimulation) *Fix:* Relay aim over an UnreliableRemoteEvent from the server to players within about 120 studs who may see that lab (Zones.mayEnter), at 10 Hz with client-side smoothing. Keep the attribute only for 'aiming or not' (rare changes). Re-measure Stats.DataSendKbps with 3 clients.
- **[medium/low/M] Client mannequin skins add about 23 welded parts per dummy on every screen.** DummySkins welds 14 MeshPart skins over the R15 block limbs on every client and hides the blocks. V7-4 DETAILS adds 6 cylinder joint rings and 3 target plates with decals per dummy, all with WeldConstraints to unanchored limbs. On the simulating phone these massless parts join the physics assemblies. The ReplayController clones and walks them too. Crowd people are exempt, but every lab dummy, visitor and chaser carries them: for 11 bodies that is about 250 extra parts and welds, created again on every respawn (every 10 s revive cycle, every chaser respawn after 1 s). *Evidence:* Client/DummySkins.luau:17-18 (OVERLAP, DETAILS), :52-88 (skin clone + WeldConstraint per limb), :93-166 (rings and marks); Server/Systems/ChaseService.luau:36 (RESPAWN 1) *Fix:* Make the mannequin the dummy itself: build the server R15 from MeshPart limbs of the DummySkin meshes (one part per limb, a standard MeshPart R15), so there are no duplicate parts. Bake the joint rings and targets into the skin texture (one texture shared by all dummies so it instances). Until then, set DETAILS off on the LOW tier and pool skin sets across respawns.
- **[medium/low/S] Decorative effects that never sleep: legacy Fire on every lava pool, garden lamps lit in daylight, booth emitters, and shadow-casting imported models.** - **Lava:** every lab's lava pool has 3 legacy Fire objects (size 6, heat 12) and a PointLight, always on.
- **Garden lamps:** 8 StreetLamp models per lab keep their Lights on at ClockTime 13 (range capped at 24, but on), and nothing culls them. WorldLights only manages WorldV2 lamps, and WORLD_V2 is off.
- **Booths:** showpieces run ParticleEmitters at Rate 30 nonstop (not live while ids are 0, but they would be).
- **Whale:** the spout emitter is fine (Rate 0).
- **Shadows:** imported hedges, trees and benches keep CastShadow = true.
There is no distance or quality sleep for any of it (vault 'Rendering Performance §8'). *Evidence:* Server/Systems/Playground.luau:563-588 (3 Fire + PointLight per lab); Server/Systems/LabGarden.luau:63-71 (lights kept, only range and brightness capped), :131-133 (4 lamps x 2 sides); Client/WorldLights.luau:12 (tag WorldLight only; WorldDress.luau:31); Shared/Config.luau:129 (WORLD_V2 false); Server/Systems/MapShopService.luau:171-178 (Rate 30), :208-216 *Fix:* 1. Replace the legacy Fire with one ParticleEmitter flipbook per pool, enabled only within 80 studs of the camera and halved on LOW.
2. Tag every decorative Light with WorldLight so WorldLights lights only the nearest FX_CAPS[tier].lights.
3. Switch the garden lamps off between 7:00 and 18:00 ClockTime.
4. Set CastShadow = false on all imported decorative models in LabGarden.place and V3Assets.place.
5. Gate the booth emitters by distance.
- **[medium/medium/S] The lighting is tuned for a PC 'Steam look' and was never A/B-tested on a phone.** The place uses LightingStyle Realistic with PrioritizeLightingQuality on (CLAUDE.md, Steam look pass). On top of that come GlobalShadows, Bloom (size 20), ColorCorrection and Atmosphere every session. SunRays and DepthOfField are correctly turned off under LOOK_V3. Whether PrioritizeLightingQuality costs low-end phones frame time or draw distance was not checked. I could not confirm its exact behaviour from public docs, so treat that part as unverified. The look was judged only in PC captures. *Evidence:* CLAUDE.md 'Steam look pass (10 Nov): Lighting.LightingStyle = Realistic + PrioritizeLightingQuality'; Client/ZoneLighting.luau:203-246 (finishV3: GlobalShadows, bloom, CC, Atmosphere), :208-210 (SunRays/DoF off); docs/AUDIT.md:12 ('snow and particles never checked on a phone') *Fix:* Run the PERF_TEST scenes on the phone with PrioritizeLightingQuality on and then off, and with Bloom off on LOW. Keep whichever setting loses less than 2 fps p5. Under the LOW tier, turn Bloom and the ColorCorrection contrast off client-side. Note the result in AUDIT.md so it is not undone in a later visual pass.
- **[low/low/S] The plaza crowd (12 people) is always populated and simulated on the server, and streamed to every lab.** CrowdService keeps the plaza zone persistent. Its 12 people (classic clothes plus InsertService hair) exist and run ActiveRagdoll on the server's PostSimulation even when no player is near; brains pause, bodies do not. The plaza sits 250 studs from the nearest labs, so with the default streaming radius every phone also holds them and DummyLife draws them at its mid LOD whenever they are on screen. The open-air maps' crowds are correctly brought in only on approach. *Evidence:* Server/Systems/CrowdService.luau:17-23 ('the plaza's always stays'), :44 (SIZE 12), :1466-1490 (zones; persistent never emptied); Shared/Places.luau:39 (Plaza crowd 12); Client/DummyLife.luau:68-69 (LOD_NEAR 70, LOD_FAR 170) *Fix:* Make the plaza zone non-persistent like the maps (populate when a player comes within 150 studs, empty 30 s after the last leaves), or anchor and sleep each person after 5 s with nobody within ACTIVE_RANGE. Once the radius fix lands, labs will not stream the plaza anyway.
- **[low/low/M] Client set-piece animation uses Model:PivotTo on multi-part anchored Creator Store models at 30-60 Hz.** CreatureLife moves each of up to 9 creature models with PivotTo at 30 Hz within 160 studs, which covers almost the whole 250-stud lab, so all of them are usually live. BoothSpin does it every RenderStepped. PivotTo on an anchored model with dozens of parts rewrites every part's CFrame and invalidates its render and spatial data each step. The part counts of the MSpider/MWhale/MChicken imports were never audited. *Evidence:* Client/CreatureLife.luau:16 (LIFE_RANGE 160, STEP 1/30), :108-140 (PivotTo per creature per step); Client/BoothSpin.luau:31-45; Server/Systems/LabCreatures.luau:63-88 (Creator Store models cloned and scaled, parts left as imported); vault 'Tween and CFrame Animation of Objects' (bulkmoveto, pivots) *Fix:* 1. Weld each creature's parts to one unanchored-massless root on the client, or rig them with Bones / AnimationController and play a looping idle animation (the GPU does the work).
2. Otherwise, collect the parts once and use workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged).
3. Lower LIFE_RANGE to 70 and the rate to 15 Hz beyond 40 studs.
4. Cap each creature import at 30 parts / 5k triangles (art audit).

**Cut or hide:** The always-on Instant Replay recorder (ReplayController Heartbeat at 30 Hz, a clone of every dummy): record only your own lab's bodies, and only around the newcomer replay or when Replay was pressed in the last minute; pause it on LOW; Other labs on your device at all: PlotPrivacy's client reparenting of streamed labs. Rely on plot distance plus the streaming radius instead, and stop sending neighbours' FX (FX_REACH 350 > PLOT_SPACING 250); Landscape beyond the hedges: 220 Creator Store trees, bushes and rocks, and about 3,600 x 930 studs of terrain hills (Landscape.SIDE 420 / DEPTH 360) that nobody walks to. Keep a thin, flat band in front and behind; Paths built as 360 parts per lab with raised kerbs and signposts (PathBuilder): paint them into terrain or merge them into a few meshes; The 3 legacy Fire objects + PointLight on every lab's lava pool (Playground.buildLava); Garden StreetLamp lights in daylight (8 per lab, LabGarden); DummySkins.DETAILS (joint rings + target plates, about 9 extra parts per dummy) on the LOW tier; Director and AdminPanel GUIs built for every non-owner client (Director.start builds them for everyone); ReplicatedStorage.BirdModels while Config.BIRDS = false (join download for nothing); All 69 weapon models in ReplicatedStorage at join: ship the start bar plus the next 3, and the rest on unlock or catalog open; Preloading all 115 sound assets at join: load banks on unlock or when an event starts; Visitors on phones during the first 5 minutes (DEVICE_CAPS.low.visitors 1 -> 0) and 4 chasers -> 3: fewer bodies a phone must simulate exactly when retention is decided; The persistent server-simulated plaza crowd when no one is on the plaza; CreatureLife idle animation beyond about 70 studs, and BoothSpin while booth product ids are 0; Server-side per-frame PivotTo of event creatures (gorilla, bulls, tornado): replace with client-side animation from one start message

### L - Monetization (game passes, developer products, offers, prices, sold vs hidden, 2026 Roblox compliance, leader comparison): 3/10
The purchase code is very good. Purchases.luau has one ProcessReceipt, orders saved before PurchaseGranted, claims, release and BindToClose. OfferService and MapShopService deliver once per purchase id. Prices are mostly read live, and near-earned weapons are never sold (Toys.luau:307). What is for sale is the problem. I checked the public Roblox APIs on 20 Nov 2026. Live today: 2 passes, ULTRA 249 and VIP 149, and 9 developer products: 4 generic "Weapon (25/49/99/199)" tiers and 5 of the oldest events at 20-35 R$. That's all. Still at id 0 and hidden: all 19 Shop.OFFERS, the Starter Pack, the group gift and 16 of 21 events. The most expensive live pass (ULTRA) sells a perk you can barely feel. VIP's main perk is faster eggs, and almost nobody opens eggs. Two paid events (Mega Bomb, Dummy Rain) come free from the BIG RED BUTTON every 75 s. The live Dummy Rain description promises "the whole server ... Everyone sees", but labs are private. Single weapons cost up to 199 R$, against 9-49 at the leaders, and buying all 69 costs 5,606 R$. There is no bundle and no impulse buy under 20 R$. Nothing measures the shop funnel. With about 1,328 lifetime visits and 5 upvotes, real revenue is close to zero. A good back end cannot lift the area above a 3. Research limit: the web-search budget ran out after one search. Leader lineups therefore come from the live games.roblox.com, game-passes and developer-products APIs, the vault and docs/RESEARCH_FIRST_SESSION.md. I found no Reddit or TikTok threads.

**10/10 means:** A 10/10 store is small, honest, phone-first, priced like the 2026 leaders, and every number on it is measured.

(1) The live lineup is about 14 items, each one created and tested:
- Impulse:
  - "First Boom" 5 R$: one event charge, once per player. HRR sells exactly this.
  - Single weapons as named products at 9/19/29/39/49 R$. Roblox's prompt then shows "Minigun" with its picture, not "Weapon (25)".
- Events: own-lab charges of the best events (Gorilla, Tornado, Train, Meteor, UFO, Mega Bomb) at 19-35 R$, plus x3 bundles at about 1.6x the single price. The free BIG RED BUTTON draws from a pool that does not include what is sold.
- Passes: All Melee 69, All Explosives 79, All Guns 99, and Lab Controls 69 (fly, stop time, spawn 10 dummies, no-wait button in your own lab, never blocked by the server queue). Also VIP 199 (2x takedowns forever, a gold name, a cosmetic crown), Endless Events 249-299 (unlimited own-lab events, 10 s apart) and Everything 599-699.
- Cosmetics: 2 trails at 49-79 and 2 pets at 99-129, all with TRY.

(2) One Starter Pack at 29-39 R$:
- Fixed contents with no eggs (for example Minigun + Grenade + Rattler + 300 BOLTS), once per player.
- It hides once bought.
- It shows as a small chip after the first wow (about 3 min), on phones too.
- Its timer is personal (15 min from first view, saved on the server, never re-armed), or there is no timer.

(3) Every price comes from GetProductInfoAsync, passes included (regional and Plus prices). No typed-in "R$29", no invented "FAN FAVOURITE". Value labels are computed, and the ladder rises in value per Robux.

(4) Store layout and moments:
- On a 414x814 portrait phone the shop opens on a FOR YOU row: the Starter Pack, the next weapon (BUY/TRY), today's best event.
- Then tabs: Weapons, Events, Passes, Cosmetics, each item turning in 3D (Ui3D) with TRY.
- The game never starts a prompt by itself. Offers appear only at calm moments the player chooses: the end of a free try, the next-weapon card, after a wow.

(5) Every description is literally true: "in your lab" where it is the lab. No paid random items at all; if any ever exist, PolicyService fails closed and the odds are shown.

(6) Platform levers are on:
- the game is group-owned, with a group-join gift;
- a player-tapped "Get Roblox Plus: 10% off here" card (250 R$ per month for 3 months per sign-up);
- paid private servers once the Prank Party is fun;
- rewarded video once there are 2,000+ monthly visitors.

(7) Measured:
- Session_v1 records per visit: shopOpen, offerSeen, promptShown, promptCancelled, bought, robux, and the device and orientation;
- AnalyticsService economy events for BOLTS and funnel steps for shop, prompt and purchase.

Targets: 1.5-3% payer conversion of DAU, first purchase inside the first 3 sessions, and zero misleading-description complaints. "Spend days" feeds Recommended For You.

- **[critical/medium/M] Most of the store is dormant (id 0); the live lineup is 2 passes and 9 products.** Live on 20 Nov 2026: ULTRA 249, VIP 149, Weapon 25/49/99/199 (generic) and 5 events (Bouncy Floor 20, Dummy Rain 25, Flash Freeze 25, Zero-G 25, Mega Bomb 35).

Still at id 0 and hidden live:
- all 19 Shop.OFFERS: All Guns, All Melee, Everything, the Starter Crate, 9 map cosmetics and more;
- the Starter Pack;
- the group gift;
- 16 of 21 events.

Every leader sells bundle passes as its backbone:
- HRR: 17 passes, 39-699, All Guns 99, Everything 699;
- BRP: Sandbox 99, VIP 199, Arsenal 249, Everything 499;
- RR: 15 passes plus a Starter Pack 29 product.

Ours has no bundle, no starter offer and no item under 20 R$. The plans keep listing 'owner must create', and it never happens. *Evidence:* ReplicatedStorage/ReplicatedStorage/Shared/Shop.luau:50,53,160-183 (every id = 0); Shared/Events.luau:22-26 live, 29-46 productId 0; apis.roblox.com/game-passes/v1/universes/10774775314 (2 passes) and developer-products/v2/universes/10774775314 (9 products); leaders from the same APIs (HRR 10773618503, BRP 10773926254, RR 10773425091) *Fix:* Cut the 19 planned offers down to the 8-10 in the 10/10 lineup. Create them in one batch through Open Cloud: the rbx-open-cloud-usage skill, with the owner's key and approval, scopes developer-product:write / game-pass:write, and icons from art/. Paste the ids, run T68/T105/T59 and publish. If Open Cloud cannot create them, give the owner one exact 10-row table (name, price, description, picture) to make in a single sitting.
- **[high/medium/M] Paid events are sold while the free BIG RED BUTTON gives the same ones every 75 s.** Mega Bomb (35 R$) and Dummy Rain (25 R$) are in the free BIG RED BUTTON pool, which fires every 75 s.

On top of that the game gives away a free UFO at 45 s and free lab surprises every 150-240 s.

The 16 newer, more visual events (Gorilla, Bull Run, Tornado, Meteor, Train, UFO, Lightning ...) cannot be bought at all; they are free-only.

So the shop sells the oldest, weakest events, and two of them are free one walk away. The leaders sell each event as a 15-39 R$ charge, with x3 bundles. HRR also has a 5 R$ 'First Boom', one charge of any event, once per player: the classic first purchase. *Evidence:* ServerScriptService/Server/Systems/Playground.luau:859 (BUTTON_EVENTS includes MegaBomb, DummyRain) and :901-911; Shared/Config.luau:154-156 (surprises, FIRST_WOW_AT 45) and :234 (BIG_BUTTON_GAP 75); Shared/Events.luau:29-46 (productId 0); HRR developer products: 'First Boom' 5, 'Bee Swarm x3' 39, 'Gorilla Rampage' 35 *Fix:* 1. Sell personal own-lab charges of the 6 best events at 19-35 R$, plus x3 bundles.
2. Add a 5 R$ 'First Boom' (any event, once per player, a profile flag).
3. Take whatever is sold out of the free BIG RED BUTTON pool. The button instead gives a daily-rotating 'event of the day' taste of one paid event.
- **[high/low/S] Live event descriptions and the shop line promise server-wide visibility that private labs break.** Dummy Rain and Mega Bomb run in the buyer's own lab. Every other player's screen hides that lab. Yet the live Dummy Rain description says 'onto the whole server! Everyone sees your name on the banner', and the shop says 'Everyone in the server sees your event'.

Others only get a banner ('X sent MEGA BOMB') with nothing happening on their own screen.

The opposite problem: Zero-G changes Workspace.Gravity, and Flash Freeze freezes every dummy in every lab. A buyer therefore changes other players' private labs without asking.

Roblox's rules forbid misleading item descriptions. *Evidence:* EventService.luau:85-94 (labCenter = buyer's lab) and :174-175, 288-296; EventService.luau:298-305 (Workspace.Gravity) and :339-346; StarterPlayerScripts/.../Client/PlotPrivacy.luau:1-10; Client/EventShop.luau:83; live product descriptions via the developer-products API *Fix:* Make every bought event lab-local, including Zero-G (a gravity zone over the lab) and Flash Freeze (the lab's dummies only). Rewrite the dashboard descriptions and EventShop.luau:83 to say 'in your lab'. Show other players a small 'X is having a Mega Bomb in their lab' line instead of a full banner. If a server-wide event is wanted, sell it as a clearly named 'SERVER PARTY' variant.
- **[high/low/M] ULTRA (249 R$, the most expensive live item and the shop's featured card) sells a perk you can barely feel.** ULTRA's whole effect is that tool cooldowns become min(cooldown, 0.08). The starter Popper goes from 0.1 s to 0.08 s, and the automatic guns are already at 0.045-0.12. Magazines and reloads are untouched.

The free taste meant to sell it starts only after 300 s of play. The median visit is about 120 s, so almost nobody ever feels it.

It is still the first, featured card in the shop. No leader sells a cooldown pass. They sell core-loop multipliers (BRP VIP = 2x kills, 199) and bundles. *Evidence:* Shared/Shop.luau:11-18, 34-36; Server/Systems/HitService.luau:125-126; Shared/Toys.luau:195, 261, 272-281 (cooldowns); MoneyService.luau:383-389 (task.delay FREE_ULTRA_AFTER); Client/EventShop.luau:237 (featured = index 1); Session_v1 median ~120 s *Fix:* 1. Stop selling ULTRA as the headline. Take it off sale or move it to the bottom of the shop, and keep it working for current owners (the owner is the only known one).
2. Put its no-wait effect into Lab Controls and Everything.
3. The featured card becomes the Starter Pack, or All Guns for players who already bought the Starter Pack.
4. Move the free taste to a 60 s 'POWER MINUTE' after the first wow, if it is kept at all.
- **[high/medium/S] VIP sells eggs nobody opens and builds pay-only leaderboards.** VIP's perks:
- 'An egg every 50 takedowns (not 75)'. Session_v1 shows almost nobody opens an egg.
- A tag over the head.
- 'VIP on the boards'. The plaza and the labs build separate VIP TAKEDOWNS and VIP TIME PLAYED boards, which show 'No VIPs here yet!'.

The vault's Ethical Design note calls this pattern 'Spending status' (boards split by payment, social pressure on children). It is also an empty board taking space in the world. *Evidence:* Shared/Shop.luau:19-26, 37; Shared/Progress.luau:13; Server/Systems/LeaderboardService.luau:39-40, 309, 572-578; MoneyService.luau:94-120, 319-321; vault 10 Game Design and Genres/Ethical Design and Player Trust.md §3 *Fix:* 1. Remake VIP at 149-199 R$: 2x takedowns forever (faster weapon unlocks, the core loop, as at BRP), a gold name and a cosmetic crown.
2. Delete the two VIP boards.
3. Keep the egg rate for owners as a hidden bonus.
4. Change the dashboard description to match.
- **[high/medium/M] Single-weapon prices are 4-10x the market, and Roblox's prompt never names the weapon.** The tiers are 25 / 49 / 99 / 199 R$. 15 weapons sit at 199 and 13 at 99, so buying all 69 one at a time costs 5,606 R$.

The leaders charge:
- HRR: Bat 9, Fire Axe 15, Crossbow 35;
- BRP: SMG 19, Katana 39, Sniper 39;
- bundles: All Guns 99 (HRR), Arsenal 249 (BRP).

Our 4 products are called 'Weapon (25)' ... 'Weapon (199)', all with one generic description. Roblox's purchase window, the last thing a child sees before paying, shows no weapon name or picture.

The moment the planned All Guns pass (149) goes live, it undercuts anyone who paid 199 for a single gun. *Evidence:* Shared/Toys.luau:298-304 (PRICE_TIERS), 312-320; tier counts computed from Toys.luau unlockAt + Config LADDER_V2_SCALE 0.363 (22x25, 16x49, 13x99, 15x199 = 5,606 R$); live product names from developer-products API; Server/Systems/WeaponShop.luau:106-116 *Fix:* 1. Re-tier single weapons to 9 / 19 / 29 / 39 / 49 R$, with 49 as the top.
2. Best: one named product per weapon ('Minigun: unlocks the Minigun forever', with its drawn icon), created in a batch through Open Cloud.
3. At least: rename the tiers to 'Unlock a weapon' and pass the chosen weapon's name into the toast.
4. Launch All Guns at 99 with the new single prices, so the bundle is always the better deal.
- **[high/medium/S] Nothing measures the money funnel.** The owner's live data source (Session_v1) has no shop, prompt or purchase fields. Metrics only logs:
- Weapon_Prompt / Weapon_Bought;
- Pass_<key>;
- Weapon_Trial.

There is nothing for event prompts, offers, shop opens or cancelled prompts. There is no PromptProductPurchaseFinished listener, no AnalyticsService:LogEconomyEvent for BOLTS (0 hits in the repo) and no LogFunnelStepEvent. Nobody can tell whether a single player has ever opened the shop on a phone. *Evidence:* Server/Systems/Metrics.luau:12-44; WeaponShop.luau:109; MoneyService.luau:353; TrialService.luau:121; repo grep: 0 hits for LogEconomyEvent, LogFunnelStepEvent, PromptProductPurchaseFinished *Fix:* 1. Add these fields to Session_v1: shopOpen, shopTab, offerSeen (key), promptShown (key), promptDone (true/false), robux (from receipt.CurrencySpent), and the device and orientation.
2. Log AnalyticsService funnel steps Shop -> Prompt -> Bought, and economy events for BOLTS sources and sinks.
3. Extend tools/SessionReport to show conversion by device.
- **[high/medium/M] The Starter Pack is built with a fake daily timer, a typed price, no once-per-player limit and paid random eggs.** The TODAY'S DEAL card counts 'Ends in hh:mm:ss' down to UTC midnight for a product that is identical every day. The vault calls this a resetting fake timer.

Its price 'R$29' is typed in, which is wrong for regional and Plus prices.

RewardsService delivers it any number of times; nothing makes it once per player.

It is hidden on phones, where most players are. BRP puts its Starter Pack chip on phones.

It gives 3 weapon eggs. Those are paid random items, which need odds shown under the 2026 rules, and the repo has 0 PolicyService calls. This contradicts the Shop.luau comment 'No paid random items here'. The weapon fallback in ProgressService.deliverWeapon also hands out eggs.

On top of that, a second, overlapping 'Starter Crate' (EntryPack: 49 R$ for 300 BOLTS and the Rattler) exists. *Evidence:* Client/HudPlus.luau:343-346, 363, 591 (not phone), 666-670; Shared/Shop.luau:53-55, 158-161; Server/Systems/RewardsService.luau:144-167; ProgressService.luau:1156-1161; repo grep PolicyService = 0; vault 38 Live Ops Deep Dive/Limited-Time Offers - Design and Ethics.md *Fix:* 1. Keep one Starter Pack and delete EntryPack.
2. Fixed contents with no eggs, for example Minigun + Grenade + Rattler + 300 BOLTS, at 29-39 R$.
3. Once per player: a profile flag checked at prompt time, and the card hides once bought.
4. Read the price from GetProductInfoAsync.
5. Show it on every device as a small chip after the first wow (about 3 min).
6. Either no timer, or a personal 15-minute timer that starts on first view, is stored on the server and is never re-armed.
- **[medium/low/S] Pass prices are never shown, and the map booths print typed-in prices.** RobuxPrice only asks Roblox about developer products (Enum.InfoType.Product).

So the ULTRA and VIP cards, and every pass in OFFERS, just say 'BUY' with no number. A player only learns the price inside Roblox's prompt, which converts worse and reads as hiding the price.

The map-shop booth signs print the price typed into Shop.OFFERS. Regional pricing has been on by default for every pass since 30 Mar 2026, so that number will be wrong for many players. The vault notes that Docs flag this as charging a different price than the UI shows. *Evidence:* Client/RobuxPrice.luau:59; Client/EventShop.luau:103-105, 147-152, 216-220; Server/Systems/MapShopService.luau:253; Client/HudPlus.luau:363; vault 49 Roblox Platform Features/Discovery and Monetization Changes 2025-2026.md §6 *Fix:* 1. Make it RobuxPrice.get(id, infoType) and use Enum.InfoType.GamePass for passes.
2. Show 'R$ N' on every card and check IsForSale.
3. Booth signs: drop the price from the server BillboardGui, and let each client draw its own price from GetProductInfoAsync.
4. Add a T59-style test that fails on any typed 'R$' digit outside Shop data.
- **[medium/medium/M] Planned passes promise things the code cannot deliver.** - Lab Controls (179 R$), 'BIG RED BUTTON every 8 s': the button refuses whenever any event runs or waits anywhere on the server. Events last 5-25 s plus a 3 s gap, so the real gap is often 13-28 s, or zero presses while other players' events run.
- Events Pass (249 R$), 'Every server event, free, all season': it is one event per 120 s, slower than the free button's 75 s. 'All season' is wrong for a permanent pass.
- VIP Lab (199 R$), 'More dummies roaming your lab': +2 visitors, cut by the server's shared body budget, so it can add 0.
- Giant Fan (179) and Mega Trampoline (149) booth passes duplicate the free 'Giant Fan' event and the earnable Fan (300) and Trampoline (135) tools. *Evidence:* Shared/Shop.luau:165-168, 179-180; Server/Systems/Playground.luau:901, 910; Shared/Config.luau:90, 234-235; Server/Systems/EventService.luau:586-604; Shared/Events.luau:43 (FanBlast free); Shared/Toys.luau:231, 234; Server/Systems/VisitorService.luau:92-99 *Fix:* 1. Lab Controls 69 R$, as at HRR: fly, stop time, spawn 10 dummies, slow-mo, and a lab-local button that never waits on the server queue.
2. Endless Events 249-299 R$: unlimited own-lab events, 10 s apart, lab-local.
3. Drop VIP Lab, Giant Fan and Mega Trampoline.
4. Every 'gives' line reworded so it is literally true. Add a self-test that runs each pass effect and checks the promised number.
- **[medium/low/M] Map shop booths stand where few players go, add world clutter, and What's New advertises things that aren't live.** The 10 cosmetic and lab items get booths at the plaza front and at each open-air map's arrival (22 booths in T105). In a roughly 120 s visit most players never leave their lab.

Each booth adds a priced BillboardGui to the world, against the V3 'world text off' rule.

With every id at 0, sellable() is false live, so there are no booths. Yet What's New 0.24.0 promises 'NEW SHOP BOOTHS: pets, trails ... (try them free)'. 0.25.0 advertises 'BIRDS that really fly', and birds are now switched off. *Evidence:* Server/Systems/MapShopService.luau:72-75, 199-277, 280-332, 340-358; Shared/Shop.luau:64, 74, 173-182; Shared/Config.luau:166 (MAP_SHOP) *Fix:* 1. Move cosmetics into a Cosmetics tab in the shop window: Ui3D turntable, TRY 60 s, live price.
2. Keep at most one lit showcase kiosk in the lab near the spawn, showing one featured item.
3. Remove the map-arrival booths.
4. Fix Shop.WHATS_NEW now: drop the birds line and the booths line, and add a test that each What's New line maps to a switch that is on and an id that is live.
- **[medium/medium/L] The shop sells the wrong things first on portrait phones, and its labels are invented.** With OFFERS hidden, the shop's first screen on a 414x814 portrait phone is the featured ULTRA card, then VIP. The events sit below the fold, and weapons are not in the shop at all (they are in WEAPONS).

The HUD event packs show on PC only.

The first event card gets a hard-coded 'FAN FAVOURITE' pill. With about 1,300 visits that is made-up social proof. The vault says labels must be computed from real data. *Evidence:* Client/EventShop.luau:158-176, 226-268, 326-328, 472-511, 518-526; Shared/Config.luau:46 (phone HUD); Session_v1 (most visits are 414x814 portrait) *Fix:* 1. Rebuild the shop window phone-first. A FOR YOU row comes first: Starter Pack (if not bought), the next locked weapon with TRY/BUY, today's best event.
2. Then tabs: Weapons / Events / Passes / Cosmetics, one column on portrait screens, 44 px+ buttons.
3. Only computed badges: 'BEST VALUE' from a value-per-Robux table checked at boot, 'NEW' from the version.
4. Delete FAN FAVOURITE.
5. Add the shop's FOR YOU row to the LayoutCheck screens.
- **[medium/low/S] 2026 platform money levers are unused.** - Roblox Plus: no PromptRobloxSubscriptionPurchase anywhere. Roblox pays 250 R$ a month for 3 months per Plus sign-up made through the game, which may be more than the game's whole revenue today.
- Group: the game is owned by a user (creator tristancqq), not a group. Every leader is group-owned. The group-join egg is dormant (GROUP_ID 0). Joining a group may be rewarded; likes may not.
- Private servers: off (createVipServersAllowed false). Plus pays up to 100 R$ per subscriber per paid private server with 60+ minutes.
- Rewarded video: needs 2,000+ monthly visitors; the game has 1,328 lifetime visits, so it is not eligible yet. *Evidence:* repo grep: 0 hits for PromptRobloxSubscriptionPurchase; Shared/Shop.luau:50; Server/Systems/RewardsService.luau:35-41; games.roblox.com/v1/games?universeIds=10774775314 (createVipServersAllowed false, visits 1328, creator User); vault 49 Roblox Platform Features/Discovery and Monetization Changes 2025-2026.md §5, 11 Monetization/Ads and Rewarded Video.md *Fix:* 1. Add a player-tapped 'Roblox Plus: 10% off everything here' card at the end of the Passes tab. Never a pop-up, and never grant on the Finished signal.
2. The owner creates the group, moves the game into it, and sends the GROUP_ID so the group egg goes live.
3. Once the Prank Party is fun, turn on paid private servers at a low monthly price.
4. Revisit rewarded video at 2,000 monthly visitors.
- **[medium/medium/S] The purchase and free-try moments have no payoff and no next step.** A bought weapon gets only a toast 'The X is yours. EQUIP it!'. It is not put on the bar automatically and there is no reveal.

The end of a 2-minute TRY FREE, when the player wants the weapon most, is also just a toast ('Earn the X with kills, or BUY it in WEAPONS!'). It sends the player into a menu instead of offering a calm BUY right there.

The kill-based copy ('earn kills', 'take people down') also goes against MILD_TEXT. *Evidence:* Client/ToolCatalog.luau:287, 426, 956-957, 972-979; Server/Systems/TrialService.luau:121 *Fix:* 1. On a purchase, put the weapon on the bar automatically (PokeController.autoEquip), with a 1.5 s 'drops into your hands' reveal and a sound.
2. When a try ends, show a small card 'Keep the Minigun? R$ N · Not now' (player-tapped, closes itself after 8 s), with the 'N takedowns to go' bar beside it.
3. Reword to mild text: 'takedowns', not 'kills'.
- **[low/low/S] BUY cards sell violence the game no longer has.** These blurbs show on BUY cards:
- Axe: 'It can take a limb off';
- Cleaver: 'A butcher's blade. Quick and nasty';
- Katana: 'One clean cut. Limbs fly';
- Chainsaw: 'Nothing stays attached'.

SEVERING is off and the game is meant to be kid-safe, so this misdescribes the product and is the wrong tone for the maturity label. Only the Shotgun got a mild TOY_NAMES rewrite. *Evidence:* Shared/Toys.luau:122 (only Shotgun rewritten), 251-255; Shared/Config.luau:15 (SEVERING = false), 37 (TOY_NAMES) *Fix:* Add mild blurbs to TOY_NAMES for every sever weapon, for example Katana 'One clean swing. Sends them spinning' and Chainsaw 'BRRRR. Shoves everything aside'. Extend T57_MildContent to fail on 'limb', 'butcher' and 'attached' in any visible blurb.
- **[low/low/S] Two side currencies are sold with value that does not add up, plus like-milestone codes.** Bolt Crate is 49 R$ for 500 BOLTS. BOLTS buy the cheapest locked weapon at 1.5 per takedown rung. So 49 R$ buys several cheap weapons, while a single weapon product costs 25 R$, and the Starter Crate is 49 R$ for 300 BOLTS plus the Rattler. The ladders contradict each other.

Selling a currency with confusing value is a pattern the vault flags.

LIKE_CODES hand out codes when the like count reaches a milestone. They are dormant, but a reward tied to likes risks Roblox's ban on incentivising ratings. I could not verify the exact current wording (search budget ran out). *Evidence:* Shared/Shop.luau:161, 182; Shared/Offers.luau:29, 48; Shared/Config.luau:60-61, 67-73; Server/Systems/EconomyService.luau:134-154; vault 11 Monetization/Pricing and Store Design.md §3 *Fix:* 1. Never sell BOLTS for Robux; they stay a free play reward (delete the Bolt Crate and EntryPack).
2. Replace LIKE_CODES with update codes ('code for the 0.26 update'), which have nothing to do with likes.
3. Keep 2x BOLTS only inside Everything, if at all.

**Cut or hide:** ULTRA as a headline or featured pass. Take it off sale and keep its effect for current owners; the no-wait goes into Lab Controls and Everything.; Both VIP leaderboards (VIP TAKEDOWNS, VIP TIME PLAYED) in the plaza and the labs (LeaderboardService.luau:39-40); The TODAY'S DEAL card's countdown to UTC midnight (HudPlus.luau:666-670) and the typed 'R$29' price; EntryPack 'Starter Crate' (a duplicate of the Starter Pack) and the Bolt Crate. Selling BOLTS for Robux goes entirely.; Eggs in any paid product: the Starter Pack's 3 eggs and the 'two eggs' fallback in ProgressService.deliverWeapon; Planned passes VIP Lab (+2 dummies), the 120 s Events Pass version, Giant Fan and Mega Trampoline: weak or duplicate value; Most of the 10 map-arrival booths and their priced world billboards. Cosmetics move into a shop tab plus at most one lab kiosk.; The hard-coded 'FAN FAVOURITE' pill on the first event card (EventShop.luau:518-526); Mega Bomb and Dummy Rain in the free BIG RED BUTTON pool while they are sold (Playground.luau:859); The What's New lines for BIRDS (off) and NEW SHOP BOOTHS (not live) (Shop.luau:64, 74); The generic 'Weapon (25/49/99/199)' product names: rename them or replace them with named per-weapon products; LIKE_CODES like-milestone codes (Config.luau:67-73); 'THE ADMIN SHOW' countdown line inside the shop window (EventShop.luau:484-493): clutter between the passes and the events; Violent sever blurbs on BUY cards (Toys.luau:251-255)

### M - Retention: daily streak, playtime gifts, notifications opt-in, favourite prompt, What's New, reasons to come back tomorrow, live-ops cadence (DailyGoals, PlaytimeGifts, RewardsUI, LikePrompt, Notify, GiftClock, LaunchGift, ScheduleService/UI, MoneyService What's New, RewardsService, EconomyService codes): 2.5/10
The game has many retention systems, and the backend is careful: mark-then-pay claims, UpdateAsync, retries, a pure NotifyRules module that is tested. Players see almost none of it.

1. The playtime-gift clock is drawn on a button that is hidden on every device.
2. Every hook lands after the median exit (~120 s, 0 players past 5 min on the newest build): play gift 1 at 120 s, favourite ask at 180-480 s, notification opt-in at 480 s, free ULTRA at 300 s, dares that need 15-40 takedowns or 10-20 minutes.
3. The daily reward is paid automatically, with no claim moment, in eggs that almost nobody opens.
4. The streak resets strictly at UTC midnight, which breaks it for American evening players. The two named calendar prizes usually turn into an egg.
5. REWARDS is two taps deep on phones (the main platform) and has no count badge on PC.
6. The same daily content sits in three overlapping windows.
7. The opt-in prompt is used up, but no notification is ever sent.
8. There is no community, no live code, and three of the eight badges do not exist.
9. What's New advertises birds that were just switched off.
10. None of these surfaces is measured, so the owner cannot tell whether any of them works.

What exists is plumbing, not retention. Players today have no felt reason to come back tomorrow.

**10/10 means:** **One hub, always visible.** A single REWARDS gift button sits on every layout, phone portrait included, with a live red count and a pulse when something is ready. Nothing daily lives anywhere else.

**First session (newcomer):**
- 60 s: the first play gift. A visible chip counts down ("🎁 0:42"), turns into a READY pulse, and a tap opens a box.
- 75-90 s: a "TOMORROW" chip names the day-2 prize, which is exclusive and cannot be earned otherwise (for example a golden Popper skin), with a real countdown.
- 90-120 s: a small favourite chip appears after the first real wow (first cannon shot or bullseye, or 10 takedowns). It is skipped if GetFavoriteAsync says the game is already favourited. A decline is remembered for 7 days.
- The first dare can be finished inside the first two minutes.

**Returning player.** One welcome-back card about 8 s in:
- the "DAY 3 🔥" strip with a big CLAIM button and the prize popping on screen;
- "NEW since you left" with one picture and a TRY IT button that walks or teleports the player to the new thing;
- today's dare.

**Streak rules:**
- a rolling window: claimable 20 h after the last claim, kept for up to 48 h;
- one free streak freeze a week;
- a "streak ends in 3 h" line when it is at risk;
- day 7 is the best reward in the calendar.

**Playtime gifts:** 6-8 gifts in a day, escalating, each shown with its prize icon and claimed with a tap.

**Weekly live ops:**
- The Saturday show is published as a Roblox Experience Event every week, so Notify Me reaches under-13s, and a HUD chip counts down to it.
- A weekly leaderboard resets every Monday, with a crown for this week's top 3.
- The free-weekend weapon goes onto the bar to try.
- An update announcement goes out every 3+ days.
- A new code with every update, and a visible CODES entry.

**Notifications:**
- The opt-in is asked only right after a streak claim, with our own one-line context card first.
- The server really sends at most one notification a day through the Open Cloud UserNotification package: "Your Day 4 gift is ready" and "The show starts now".
- The Turn Off rate is watched.

**Community:** a live group with an exclusive join gift and an in-game join prompt.

**Measurement:**
- SessionStats records new or returning, days since the first visit, streak day, claim, favourite and opt-in results, and What's New seen.
- Targets per build: D1 above 20 %, D7 above 6 %, favourites above 5 % of new players (BRP is at 10.7 %).

- **[critical/high/S] The playtime-gift clock is invisible on every device, and the tip points players at it.** GiftClock draws its 'GIFT m:ss' tag on PokeController.weaponsHud. HudPlus starts after PokeController and sets that to HudPlus's big WEAPONS button. That button is hidden on phones (PHONE_HUD_MAX7) and wherever HudV3 is active, which is every non-phone screen. HudV3's own WEAPONS square and its top-bar gift button never read GiftAt. The result: no player on any device sees the clock. The 35-40 s tip still says 'The clock is on WEAPONS'. This is the main 'stay a bit longer' hook, and it does not render. *Evidence:* - GiftClock.luau:47-58 (draws on PokeController.weaponsHud) and :68 (tip 'The clock is on WEAPONS').
- HudPlus.luau:337 (weaponsHud = the big WEAPONS button) and :582-585 (hidden when phone and PHONE_HUD_MAX7, and when v3).
- HudGate.luau:15-20 (v3 = every non-phone screen).
- HudV3.luau:222-235 (gift button with no GiftAt and no tag).
- Main.local.luau:79 vs :111 (start order). *Fix:* - Add a dedicated GiftChip that is not tied to any launcher: the top bar beside the gift on PC, tablet and console; under the top cluster on a phone in portrait and landscape.
- It shows '🎁 0:42', then a pulsing READY, and a tap claims.
- Point the tip at it.
- Add the chip to LayoutCheck on all 16 screens, and a test that the tag is visible (AbsoluteSize > 0) on each layout.
- **[critical/high/M] Every retention hook lands after the median player has left.** Live data: the median visit is ~120 s, 1 in 11 passes 4 min, and none passed 5 min on the newest build. The first-minute hooks were moved earlier on 20 Nov, but the retention layer was not:
- first play gift at 120 s;
- favourite ask only after a wow once 3 min are played, otherwise at 8 min;
- notification opt-in at 8 min or later;
- free ULTRA '5-minute gift' at 300 s;
- FiveMinutes badge at 300 s;
- daily dares that need 15-40 takedowns or 10-20 minutes (median ~4 takedowns).
So more than 90 % of players never see a single reason to return. *Evidence:* - PlaytimeGifts.luau:31 (AT = 120, 300, 600, 900).
- LikePrompt.luau:90-92 (SHOW_AFTER 8 min, MIN_PLAYED 3 min).
- Config.luau:175 (NOTIFY_OPTIN_AFTER 480).
- Shop.luau:35 (FREE_ULTRA_AFTER 300).
- Badges.luau:28.
- DailyGoals.luau:17-22.
- Session_v1 numbers in the task brief. *Fix:* Re-time the retention beats inside the real session:
- play gift 1 at 60 s;
- a 'TOMORROW: Day 2 = <exclusive prize>' chip at 75-90 s;
- the favourite chip after the first real wow from about 90 s;
- the first dare finishable within 2 min;
- the free ULTRA trial folded into play gift 3 (about 4 min).
Guard the timings in a T55-style test. Re-measure with Session_v1 after 48 h.
- **[critical/high/M] The daily reward is auto-paid at 4 s, with no claim moment, in eggs nobody opens.** ProgressService.daily runs 4 s after the profile loads and adds eggs silently. The only feedback is a toast, which for newcomers waits until the reveal. The calendar never shows by itself and there is no CLAIM tap.

The rewards themselves are eggs:
- streak: 1 1 2 1 1 2 3 eggs;
- each dare: 1 egg;
- all three dares: a bonus egg.
The owner's data says almost nobody opens an egg, so the daily payout is effectively invisible. The top games make the claim itself the dopamine moment: a tap, a pop, the prize shown. *Evidence:* - ProgressService.luau:1719-1723 (task.delay 4, daily), :1570-1611 (eggs added), :812-823 (dares pay eggs).
- DailyGoals.luau:26-28.
- ProgressUI.luau:565-586 (toast only).
- Task brief: 'almost nobody opens an egg'. *Fix:* - For returning players, show one welcome-back card about 8 s in: the 7-day strip, today's tile, and a big CLAIM button.
- The claim plays a short reveal of a direct prize: bolts, a 24 h weapon trial, or an exclusive skin or hat on days 3, 5 and 7. Never an egg.
- Newcomers get their day-1 claim at the reveal, as one card.
- Keep the server's mark-save-pay order, but pay on the ClaimDaily remote (no arguments, rate limited) instead of the timer.
- **[high/high/M] A strict UTC-midnight streak breaks for American evening players, with no grace day and no warning.** The streak continues only if lastDay == day-1 on the UTC calendar. UTC midnight falls at 19:00 EST and 16:00 PST, in the middle of US after-school play.

Example: Monday 18:00 EST (23:00 UTC Monday, day N), then Tuesday 20:00 EST (01:00 UTC Wednesday, day N+2). The streak resets to day 1 even though the player played on two evenings in a row.

A missed day silently restarts the calendar. There is no grace day, no freeze, no 'streak ends in X h' line and no 'next gift in 7h 12m' countdown anywhere. The vault flags strict streaks as the shape most likely to anger children. *Evidence:* - ProgressService.luau:1575-1579 (streak = if lastDay == day-1 then +1 else 1).
- DailyGoals.luau:40-42 (UTC day).
- RewardsUI.luau:76-87 (no countdown).
- Vault 'Retention and Return Hooks' §3 (grace, the 20 h / 48 h rolling window). *Fix:* Switch to a per-player rolling window:
- claimable 20 h after the last claim;
- the streak is kept up to 48 h after it;
- one automatic freeze per 7 days ('Streak saved! 🧊').
Also:
- store lastClaimAt as os.time() in the profile and migrate lastDay;
- show 'Next gift in 7h 12m' and 'Streak ends in 3h' in REWARDS and on the welcome card;
- write the missed-day rule into a test (T42).
- **[high/high/M] The calendar's two named prizes (day 2 AK, day 7 Minigun) usually turn into one more egg.** Day 2 gives the AK and day 7 the Minigun only if the player has not unlocked them by takedowns. The AK unlocks at 27 takedowns and the Minigun at about 40 under LADDER_V2. Anyone who keeps a 7-day streak has passed both, so the 'best' days pay one more egg, which is the reward nobody opens. Day 7 must be the strongest pull of the week, and here it is a dud. *Evidence:* - DailyGoals.luau:31 (STREAK_WEAPONS).
- ProgressService.luau:1593-1599 (owned, or takedowns >= unlockAt, gives an extra egg).
- Toys.luau:261 (Minigun unlockAt 58, squeezed) and :273 (AK unlockAt 27).
- Toys.luau:127-130 (squeeze). *Fix:* Make streak prizes exclusive, never sold and never unlocked any other way:
- day 2: a golden skin for the starter gun;
- day 4: a 24 h trial of a top-ladder weapon;
- day 5: a trail;
- day 7: a '7-DAY' crown hat, plus an exclusive weapon skin per cycle.
Show each prize as a picture on the strip. Roll a new set of exclusives every 4 weeks (a 28-day ladder with a weekly highlight).
- **[high/high/S] REWARDS is two taps deep on phones and has no count on PC, so the 'ready thing' never reaches the eye.** Phones, where most players are (portrait 414x814), keep only SHOP beside MENU. REWARDS is inside MENU, and MENU's '!' follows only eggs and dares (ProgressUI). On PC, tablet and console, HudV3's gift button has no badge or number. RewardsUI calls setCount on the kit launcher, which HudV3 hides. The 'at least one ready thing on every join' rule from the vault and the research is therefore unseen on every platform. *Evidence:* - HudMenu.luau:25 (Rewards phoneOnly in MENU) and :56 (PHONE_KEEP = Shop only).
- HudV3.luau:222-235 (gift with no count).
- RewardsUI.luau:134-136 (count on the hidden launcher).
- ProgressUI.luau:170.
- RESEARCH_FIRST_SESSION.md:162 (BRP: one REWARDS button, visible). *Fix:* - Put one gift button with a red number (RewardsUI.claimable) and a pulse on every layout, including the phone portrait top bar beside SHOP.
- Count real claimables only: streak claim, play gift ready, dare done, group gift. Not unopened eggs.
- Add it to LayoutCheck.
- **[high/high/L] Three overlapping daily windows and about nine progress tracks.** The same daily content is in three windows:
- Rank & Eggs: rank, egg card, 7-day calendar, 3 dares, bonus-egg claim, hats;
- Rewards: calendar, play gift, the same 3 dares (no bonus claim), trophies, group;
- Experiments: bolts, daily experiments, Bone Journal, like codes, and a second SHARE CODE box.
The rewards are spread over eggs, bolts, stars, takedowns, level XP, rank, journal pages, trophies and hats. A child cannot tell what 'today' means or where to claim it. The bonus egg can only be claimed in Rank & Eggs. *Evidence:* - ProgressUI.luau:424-503 (Rank & Eggs: calendar, goals, bonus).
- RewardsUI.luau:139-211.
- ExperimentCard.luau:164-309 (bolts, daily, journal, codes, share code).
- HudMenu.luau:18-33 (all in MENU). *Fix:* Merge into one REWARDS hub with 3 tabs:
- TODAY: streak strip, 3 dares, play-gift ladder, daily experiments;
- COLLECTION: journal and badges as one book;
- CODES.
Rank & Eggs keeps rank and hats only. Pay every daily reward in one soft currency (bolts) plus exclusive cosmetics.
- **[high/high/L] The notification opt-in is spent, but no notification is ever sent.** Notify.goodMoment fires Roblox's PromptOptIn after any wow (a combo, a bullseye, a cleared chase) once 480 s are played. It shows no context line of our own. A wow is not a delayed-payoff action. Roblox shows this modal at most once per 30 days per user, so a wasted ask costs a month.

Worse: the repo has no server sender at all (no Open Cloud package, no createUserNotification), so a player who opts in receives nothing personal. Only update announcements, typed by the owner on the dashboard, could reach them. *Evidence:* - Notify.luau:258-301 (prompt after wow, no context card).
- Config.luau:174-175.
- A grep of ServerScriptService finds no createUserNotification or OpenCloud.
- Vault 'Experience Notifications and Return Prompts' §3 (30-day rule, context line first, ask after a delayed payoff). *Fix:* Owner:
- create 2-3 strings on the dashboard: 'Your Day {day} gift is ready in {experienceName}', 'THE SHOW starts now: free events for everyone', 'Today's dare: {dare}';
- insert the Creator Store OpenCloud package into ServerScriptService.
Code:
- a sender that queues 'streak ready' sends in a MemoryStore sorted map keyed by due time, drained by any running server, at most 1 per user per day;
- 'show starts' sends at the event;
- ask the opt-in only right after a streak claim, after our own card: 'Want a ping when Day 4 is ready? [YES] [Not now]';
- skip it entirely until the sender is live.
Track the Turn Off rate on the dashboard.
- **[high/high/S] The favourite ask never reaches most players, is a big modal, and repeats for players who already favourited.** The ask fires only after a wow once 3 min are played, otherwise at 8 min. With a 2-minute median, almost no one sees it.

When it does show:
- it is a 460x380 window, which interrupts;
- 'favorited' lives only for the session and GetFavoriteAsync is never checked, so a player who favourited earlier is asked again every visit;
- the copy promises 'hear about new weapons, places and events first', which favouriting does not guarantee;
- SHOW_AFTER is set twice (6 min, then 8 min).
The research shows the lever: BRP gets 10.7 % favourites per new player with an in-game ask, HRR 0.9 % without. Our rate is unknown because it is not measured. *Evidence:* - LikePrompt.luau:24 and :90 (SHOW_AFTER twice), :91 (MIN_PLAYED 180), :25 (460x380 window), :32 and :83-85 (session-only favorited), :51 (copy).
- RESEARCH_FIRST_SESSION.md:52-57.
- RESEARCH_V4.md:56 (reference project asks 25 s after the tutorial). *Fix:* - Replace the window with a small chip: '⭐ Favorite Ragdoll Havoc to find it again'. A tap runs PromptSetFavorite.
- Show it after the first real wow (first cannon shot or bullseye, or 10 takedowns), not before 75 s, once per visit.
- Skip it when AvatarEditorService:GetFavoriteAsync says the game is already favourited.
- Save a 7-day snooze in the profile on a decline.
- Use honest copy: it shows up in your Favorites on the home page.
- Log ask and result into SessionStats.
- No reward, per Roblox rules.
- **[high/medium/S] No community (group): the group gift is hidden and there is no return channel.** Shop.GROUP_ID is 0, so the group gift section is hidden. A community gives:
- shouts that reach members without the 13+ notification limit;
- a place to post codes and updates;
- a reward Roblox allows for joining.
The leading rival BRP pairs a group join with a free weapon. We have none of this. *Evidence:* - Shop.luau:48-50 (GROUP_ID 0).
- RewardsUI.luau:112-133.
- RewardsService.luau:35-41 and :117-142.
- RESEARCH_FIRST_SESSION.md:57 and :93. *Fix:* Owner: create the Ragdoll Havoc community and send the id.
Code:
- the group gift is an exclusive weapon skin (not an egg);
- the CLAIM button opens the in-game join prompt (GroupService:PromptJoinAsync; check the current docs);
- check membership again on window open, as it does now;
- post every new code and update in the community.
- **[high/medium/S] No retention surface is measured.** The Session_v1 record has no new-or-returning flag, days since the first visit, streak day, daily claim, rewards window opened, play gifts received, favourite asked and accepted, opt-in asked, or What's New seen. Metrics sends only Goal_<kind>, Goals_All and Daily_Weapon. The owner cannot tell whether any piece of this area works, or compare builds. *Evidence:* - SessionStats.luau:25-55 (Record fields).
- ProgressService.luau:824 and :1602 (the only retention Metrics).
- Metrics.luau:7-10 (the list of names). *Fix:* - Add to the SessionStats record: ret (profile playSeconds > 0 before join), daysSinceFirst, streak, dailyClaimed, rewardsOpened, playGifts, favAsked/favOk, optInAsked, newsSeen.
- Have tools/SessionReport print, per build: the returning share, favourite rate per new player, and streak-day distribution.
- Read the dashboard's Retention D1/D7 per cohort weekly against the targets D1 > 20 %, D7 > 6 %, favourites > 5 %.
- **[medium/medium/S] What's New claims birds that are switched off, and it is a text-only pop-up window.** The 0.25.0 entry, shown to every returning player, says 'BIRDS that really fly'. Config.BIRDS was set to false today by the owner. The 0.24.0 entry advertises birds too.

The window itself:
- opens about 12 s after join as a modal (it waits for the big-pop-up slot, but it is still a window over play);
- is bullet text only, with no pictures and no way to go and try the new thing;
- shows only the newest entry, so a player who skipped versions misses the rest.
The vault says notes must never block play and must be specific and honest. *Evidence:* - Shop.luau:64 ('BIRDS that really fly') and :73 (0.24 birds).
- Config.luau:165 (BIRDS = false).
- MoneyService.luau:46 and :391-399 (12 s, newest version only).
- EventShop.luau:1038-1065 (text window, GOT IT) and :1398-1415.
- Vault 'Patch Notes and Player Communication' (TL;DR). *Fix:* - Now: remove the birds line from 0.25.0 and from the What's New of the next publish.
- Then: show a small 'NEW' ribbon chip; a tap opens the notes, with one picture per line and a TRY IT button that walks or teleports to the thing.
- Merge every entry newer than the player's seen version.
- Add a check that What's New names nothing behind a switch that is off.
- **[medium/medium/S] Daily dares are sized for 15-40 minute sessions and push systems that fail.** The pool asks for:
- 15/25/40 takedowns (median ~4 a visit);
- 10/15/20 minutes played, which repeats the play-gift clock;
- 1-2 eggs opened, the loop that is failing;
- 2-3 places visited;
- a combo of 5/8;
- 1-2 arena rounds.
With three random picks a day, a typical player finishes none, so dares give no 'almost there' pull. There is no refresh countdown. *Evidence:* DailyGoals.luau:16-28 (POOL, COUNT 3, EGGS_PER_GOAL, BONUS_EGGS) and :49-66 (random picks). *Fix:* Use three dares with fixed difficulty slots:
- EASY: finishable in one 2-minute session (5 takedowns, or 1 cannon shot);
- MEDIUM: a machine (bullseye, wrecking ball, a creature);
- HARD: about 10-15 min (50 takedowns, or 3 daily experiments).
Drop 'open eggs' and 'play minutes'. Show 'New dares in 7h 12m'. Pay in bolts or exclusive cosmetics.
- **[medium/medium/M] Playtime gifts: four flat, auto-paid bolt drops with no box, no escalation and no claim.** Four gifts a day at 2, 5, 10 and 15 min, each a flat 40 bolts, added silently with a toast. Nothing escalates, no prize is shown, and there is nothing to tap. The REWARDS bar always spans 300 s, so gift 1 (due at 120 s) starts the bar at 60 % full, which reads as broken. The simulator standard is 8-12 gifts with the first at about 1 min, escalating prizes, and a tap to open each. *Evidence:* - PlaytimeGifts.luau:31 (AT) and :176-178 (auto EconomyService.give).
- Config.luau:58 (PLAYTIME_BOLTS 40).
- RewardsUI.luau:214-236 (span = 300). *Fix:* - 8 gifts at 1, 2, 4, 6, 8, 10, 13 and 16 min, escalating: 20, 25, 30, 40, 50, 60 bolts, then a 30-min weapon trial, then an exclusive skin.
- Each shows its prize icon; READY waits for a tap that opens a box with a pop.
- Bar span = the gap between the previous gift and the next.
- Keep the per-day DataStore claim logic as it is.
- **[medium/medium/S] Reward notices skip the notification centre and break the first-visit quiet.** Every server 'Notice' goes straight to Toast.show, not through Notify. So these all skip the newcomer's quiet start and the priority and gap rules:
- LaunchGift fires about 6 s after load for everyone, newcomers included: 'LAUNCH GIFT! ... Open it in RANK & EGGS!';
- the play-gift '+40 BOLTS';
- journal pages;
- 'Goal done: an egg!'.
'RANK & EGGS' is a window name a newcomer cannot see; it is inside MENU. The returning player gets a generic 'Welcome back!' toast as well. *Evidence:* - ProgressUI.luau:587-589 (Notice -> Toast.show).
- ProgressService.luau:1525-1535 (giveEgg fires Notice).
- LaunchGift.luau:22 and :94-97 (6 s).
- PlaytimeGifts.luau:34-35.
- OnboardingController.luau:605. *Fix:* - Add a server 'Reward' message kind that the client routes through Notify.say('reward').
- Fold the launch gift into the day-1 claim.
- Replace window jargon with the button the player can see ('Tap 🎁').
- Replace the generic 'Welcome back!' with the welcome-back card.
- **[medium/high/S] No named reason to come back tomorrow.** The only day-1 message is 'Daily egg! Come back tomorrow for another.' It names no prize and gives no time. Rank & Eggs says 'Tomorrow: 1 egg' deep in MENU. Today's machine (LabZones) rotates daily but pays nothing, its light column is off, and tomorrow's machine is never teased. The vault's D1 rule (a great first session plus an unfinished goal, or a timer that resolves tomorrow) is not met. *Evidence:* - ProgressUI.luau:584-586 and :141-150.
- LabZones.luau:7-8 and :30-46.
- Config.luau:178 (TODAY_LIGHT false).
- Vault 'Retention and Return Hooks' §1 (hooks per window). *Fix:* - At 75-90 s, and again when the player opens MENU or Settings (a proxy for leaving), show a chip: 'TOMORROW: Day 2 = Golden Popper ⏳ 14h'.
- Today's machine pays x2 bolts and carries one dare; REWARDS shows 'Tomorrow's machine: WRECKING BALL'.
- The welcome-back card on day 2 delivers exactly what was promised.
- **[medium/high/M] The weekly live-ops calendar is invisible outside the game.** The Saturday 18:00 UTC Admin Show (3 free events) and the free-weekend weapon are announced only to players already in a server, by toasts at 10, 5 and 1 min, and by a line inside SHOP. Neither is a Roblox Experience Event, so there is no Notify Me, which reaches under-13s, and nothing on the game page. UPDATE_TITLE and UPDATE_DAYS exist only in docs; no code or checklist uses them. There is no weekly limited item or weekly challenge. The leaders update almost daily and run appointment events (Grow a Garden-style admin events). *Evidence:* - Schedule.luau:12-16 (SHOW Saturday 18:00, 3 events).
- ScheduleUI.luau:35-43 (SHOP line), :47-54 (weekend toast), :84-103 (countdown toasts).
- Config.luau:100-103 (unused anywhere but docs/CREATOR_KIT.md:34-38).
- RESEARCH_FIRST_SESSION.md:46 and :163. *Fix:* Owner, weekly:
- publish 'THE HAVOC SHOW' as a Roblox Experience Event every Saturday;
- post an update announcement every 3+ days (60 characters).
Code:
- a HUD chip 'SHOW in 2d 4h';
- the free-weekend weapon goes on the bar as a trial;
- a weekly featured exclusive (one Shop.OFFERS map item as a free 7-day trial for streak 3+ players);
- RELEASE.md gets a step to bump UPDATE_TITLE on update days.
- **[medium/medium/M] Leaderboards are all-time only, with no weekly reset.** The lab boards (TAKEDOWNS, TIME PLAYED) read one OrderedDataStore per board for all time. A new or casual player can never place, so the boards give no reason to come back this week. Weekly resets are a standard D7 driver. *Evidence:* LeaderboardService.luau:6 and :90 (one OrderedDataStore per board), :561 (GetOrderedDataStore(board.store), no week key). *Fix:* - Add weekly boards keyed by ISO week (store name + '_W' .. week) beside the all-time ones.
- 'Resets in 3d 2h' on the board.
- This week's top 3 get a crown hat for the next week.
- Show the player's own weekly rank in REWARDS.
- **[medium/medium/S] Codes are empty and hidden next to a second, unrelated code box.** All three like-milestone codes have an empty code and live = false, so there has never been a code to type. The code box sits deep inside the EXPERIMENTS window, under a different 'friend's SHARE CODE' box, which confuses children. Ragdoll Sandbox advertises 'Next code at 25k likes!'. Codes are the cheapest weekly return hook there is. *Evidence:* - Config.luau:67-73 (LIKE_CODES all code '' and live false).
- ExperimentCard.luau:177-213 (share code box) and :236-263 (like code box).
- EconomyService.luau:63-66.
- RESEARCH_FIRST_SESSION.md:137. *Fix:* - Add a CODES tab in REWARDS with one box only; share codes move to the replay.
- Owner: go live now with a launch code that is not tied to likes, then a new code with each update, posted in the description and the community.
- Show 'Next code at N likes' (allowed: everyone can use it).
- **[low/medium/S] Free ULTRA '5-minute gift' lands where nobody is, and ends with a sales line.** The free ULTRA minutes start only after 300 s of play, which no newest-build player reached. When they end, the toast reads 'Your free ULTRA is over. Get it to keep the speed!'. A gift that ends in a pitch feels like bait to a child. *Evidence:* - Shop.luau:34-35.
- MoneyService.luau:383-389.
- EventShop.luau:1389-1395. *Fix:* - Make the ULTRA trial gift 3 of the play-gift ladder (about 4 min).
- End it with 'ULTRA trial over: thanks for playing!' plus a small, optional shop link.
- **[low/low/S] Trophies count badges that do not exist, so they can never be completed.** TROPHIES shows have / #Badges.LIST = x/8, but three of the eight badges (Havoc Maker, Nuked It, Havoc Legend) have id 0 and can never be awarded. BRP teaches every lab machine with one badge each (40-66 % of new players earn them), and we have no machine badges. *Evidence:* - RewardsService.luau:85-100 (total = #Badges.LIST).
- Badges.luau:16-18 (three ids 0).
- RESEARCH_FIRST_SESSION.md:89 (BRP badge funnel). *Fix:* - Owner: create the 3 badges and send the ids. Until then, count only live ids.
- Add one badge per lab machine and creature (cannon, wrecking ball, lava, mace, trampoline, spider and so on), shown in the merged COLLECTION book.
- **[low/low/S] The favourite trigger matches toast text by string.** LikePrompt finds a wow by searching notice text for 'BULLSEYE' or 'CHASE CLEARED'. A text change (MILD_TEXT, a toy rename, a translation, an emoji) silently stops the trigger. No test catches it. *Evidence:* LikePrompt.luau:133-140. *Fix:* - Have the server fire a typed 'Wow' Progress event (kind = Bullseye, ChaseCleared, Combo10, FirstCannon) that LikePrompt and Notify listen for.
- Add a test that each wow source fires it.
- **[low/low/S] The two calendars disagree about today.** Rank & Eggs works out today's tile from streak alone and ignores dailyToday. Rewards does take it into account. Before the daily lands, or while egg slots are full, the two windows light different days. *Evidence:* ProgressUI.luau:111-121 vs RewardsUI.luau:79-87. *Fix:* Use one shared calendar view helper. This disappears with the REWARDS merge.

**Cut or hide:** The calendar, dares and bonus-egg section in Rank & Eggs: move it into one REWARDS hub. Rank & Eggs keeps rank and hats only.; Eggs as the currency for daily, dare, streak, group and launch rewards: pay in bolts and exclusive cosmetics instead.; The free-standing Free ULTRA '5-minute gift' and the LaunchGift toast: fold both into the play-gift ladder or the day-1 claim.; The generic 'Welcome back!' toast (OnboardingController.luau:605): replace it with one welcome-back card.; The Experience Notifications opt-in prompt (Notify.goodMoment) until the server really sends notifications: today it spends the once-per-30-days prompt for nothing.; The 'Open N eggs', 'Play N minutes' and 'Visit N places' dares.; The birds lines in What's New 0.25.0 and 0.24.0 (birds are off).; The modal What's New window on join: replace it with a NEW ribbon chip that opens on tap.; The friend SHARE CODE box in the EXPERIMENTS window beside the like-code box (keep share codes in the replay).; The TROPHIES count while 3 of 8 badges do not exist (or create them).; The TODAY'S MACHINE sign while it pays nothing.; The day-2 and day-7 calendar weapons that most streakers already own (they turn into an egg): replace them with exclusives.; The play-gift bar's fixed 300 s span.; The duplicate LikePrompt.SHOW_AFTER = 6*60 (dead value).

### N - Store page and discovery (title, description, icon, thumbnails, video, maturity/age gate, genre, events, group, update cadence, first impression on the Roblox home page): 2/10
I read the live page from Roblox's public APIs on 20 Nov 2026, so this is what players see now, not what the repo says.

**What players see**
- **Title:** "[EVENT] RAGDOLL HAVOC". It is in all caps, and the [EVENT] tag is left over from events that ended on 10 and 14 Nov.
- **Description:** still the 0.20.0 text (STORE_TEXT.md:67-89), five versions behind. It contains a false claim ("bring up to 6 friends").
- **Art:** the icon and all 3 thumbnails are AI renders that are not in the repo. They show a look the game does not have.
- **Missing:** no video.
- **Age rating:** "Maturity: Minimal • Ages 16+", so every under-16 player is cut off.
- **Numbers on the tile:**
  - 1,328 visits; 0 playing when checked.
  - Rating 5 up / 3 down (63%), against 83-90% for the leaders.
  - 17 favourites.
  - About 15 new players a day: the Welcome badge was given 15 times in the last day, and the Five Minutes badge 2 times.
- **Ownership:** owned by a personal account. No group, private servers off, no event coming up. The ULTRA pass icon breaks into "ULTR / A".

**The competition**
- Three ragdoll sandboxes started within the same week, 28-31 Oct: Hyper Realistic Ragdoll (88k playing), Bloody Ragdoll Physics (19k) and Ragdoll Research (12k).
- All three are owned by a group and have an 83-90% rating. Two of them have a video.
- Their first lines say "ragdoll physics sandbox". Ours never says "physics".

**Our own process**
- The repo's store art (art/store/v4) cannot be used: it shows usernames and other players' names, a "FREE LAB closed" sign, a chat bubble and a HUD chip.
- The release steps never touch the live page, so it drifts.

**Why 2 and not 1:** the genre (Physics Sim) is right, the 3 custom thumbnails make the game eligible for Home, and the AI icon is a readable single subject.

Note: the web-search budget ran out during this run. Competitor data comes from Roblox's public APIs, read on 20 Nov 2026. Reddit and TikTok could not be read (as already noted in RESEARCH_V4.md:10).

**10/10 means:** **At a glance, on a phone held upright:**
- **Title:** "Ragdoll Havoc 💥", with one changing slot. It reads "[🎄] Ragdoll Havoc 💥" from 1 Dec and "[UPD] Ragdoll Havoc 💥" for three days after a real update. Every change is logged with its date in STORE_TEXT.md.
- **Icon:** one big crash-test-dummy face in shock, mid-launch, with a warm blast behind it.
  - It is drawn from the real in-game dummy and face.
  - It can be read at 50 px and passes the greyscale test.
  - Two versions are swapped week by week.
- **Thumbnails:** 5 images in one template, all made with the game's own Director camera at top graphics settings.
  - One action each: a cannon launch with the scared face, the car hitting a row of dummies, the gorilla swat, the X-ray bones replay, and tossing a friend.
  - No text, or one short word. Nothing important in the bottom 15%.
  - Thumbnail personalization (Roblox's built-in A/B test) runs them for 14 days, with the art frozen during the test.
- **Video:** a 20-30 s gameplay video whose first 2 seconds are the most violent knock-down.

**Description**
- The first 150 characters name the action, the subject, "ragdoll physics sandbox", the lab fantasy and friends.
- Line 2 is "NEW: …".
- Every claim is checked against Config by the release gate. Nothing promises a cadence the game does not keep.
- The brand stays "Ragdoll Havoc" in every hand-written translation.

**Reach**
- The label is Minimal or Mild, answered honestly for every content switch that can be reached.
- The game is eligible for Roblox Select (9-15), and for Kids if the weapons allow it.
- It is owned by a "Ragdoll Havoc" group with a perk for joining (allowed), announcements and several admins.
- Private servers are free, so creators can use Streamer Mode and friends can have their own server.
- There is always an honest Experience Event coming up, starting with "Christmas Lab opens", 1 Dec.
- The Store tab shows polished pass art.

**Measured weekly**
- Play-through rate that counts only real plays.
- Under 15% of players leave within 60 s.
- Rating above 85%; favourites above 3% of visits.
- New players per day keep growing.
- Once the first session holds, a small Sponsored Ads test feeds the A/B tests enough traffic.

- **[critical/high/S] The game is shut out of every under-16 player ("Minimal • Ages 16+"), and the docs misdiagnose why.** The label is already Minimal, the lowest. So "redo the questionnaire for all ages" (the step our docs keep repeating) cannot be what is blocking reach.

Roblox's content-maturity page says Minimal and Mild games are eligible for Roblox Kids (5-8) and Select (9-15) only after the creator meets extra publishing requirements and Roblox reviewers check the game. Until then the game falls to the standard 16+ audience.

What the vault lists for Kids and Select:
- ID verification;
- two-step verification;
- Roblox Plus or Premium held at least 2 months, or a one-time refundable fee per game;
- a real-time evaluation of the game.

These features alone also force 16+:
- free-form user creation;
- media sharing;
- social hangouts.

We have candidates for each:
- SANDBOX share codes copy another player's build into your workshop (BuildStore.luau:9-12);
- CreatorUI calls CaptureService:PromptShareCapture (CreatorUI.luau:121-132);
- the shared plaza.

For a toy ragdoll game, the 9-15 group is most of the audience. *Evidence:* - POST apis.roblox.com/experience-guidelines-api/experience-guidelines/get-age-recommendation, universe 10774775314, returns displayNameWithHeaderShort "Maturity: Minimal • Ages 16+" and a single descriptor, Violence (Occasional/Mild).
- create.roblox.com/docs/production/promotion/content-maturity says creators "must also meet additional publishing requirements aside from their content maturity rating". It lists free-form creation, social hangouts and media sharing as 16+ only.
- Vault "Policy and Age Rules 2026", lines 40-60.
- Our docs give the wrong fix: CLAUDE.md:136 ("Redo the maturity questionnaire for all ages"), RESEARCH_V4.md:15 and :143, RELEASE.md:73. *Fix:* **Owner, today:**
1. Open Creator Hub → Ragdoll Havoc → Audience and find the Kids and Select eligibility page. It names the requirement that is missing.
2. Turn on 2-step verification and ID verification.
3. Get Premium or Plus, or pay the refundable fee for this game.
4. Re-check the questionnaire's feature questions (user creation, media sharing, hangout).

**If a feature forces 16+:** switch it off live behind a Config switch. For example, turn off the SANDBOX share codes and the CLIP share prompt (saving clips stays). Then submit for review.

**Fix the docs:** CLAUDE.md:136, RESEARCH_V4.md and RELEASE.md:73 should say "meet the Kids and Select publishing requirements", not "redo the questionnaire".
- **[critical/high/M] The live icon and thumbnails are AI renders of a game players will not get.** The 3 live thumbnails and the icon are glossy, Pixar-style AI images. None of them is in the repo.

What they show:
- big-eyed cartoon dummies with crash-test marks;
- a row of 20+ dummies run over by a blue sedan;
- a cartoon gorilla swatting dummies among crates and barrels;
- a cartoon cannon firing at a bullseye.

What the game actually has:
- white mannequins with flat drawn faces;
- a realistic rigged gorilla;
- a white sedan;
- flat daylight.

Why it matters:
- Roblox's media rules forbid "graphics enhanced beyond what players will see".
- Our own rules say "Store images and claims must be true" and "Nothing may look … AI".
- The leader (Hyper Realistic Ragdoll) also uses AI renders. But its renders match its in-game look (white mannequin, the classic Roblox face, green grid), so the click delivers what was promised. Ours promise a different art style.
- The live data fits a mismatch between promise and game: median visit about 120 s, 9% reach 5 min, rating 63%.
- RESEARCH_V4.md:26 quotes a third-party rule of thumb: if more than 15% leave within 60 s, suspect a thumbnail mismatch. *Evidence:* - games.roblox.com/v2/games/10774775314/media shows 3 images (130041076140252, 85105512597254, 78757019607626).
- thumbnails.roblox.com icon is version TN3. Downloaded and viewed. None of these files is in art/store.
- In-game look: art/store/v4/thumb4_car.png (white sedan), thumb1_gorilla.png (realistic gorilla), art/faces/scared.png.
- Our rules: MASTER_PROMPT.md:64, V7_PLAN.md:35.
- Vault "Thumbnails Icons and Store Page" §1 (moderation rules).
- Badge counts: Five Minutes 84 of Welcome 931.
- Votes: 5 up, 3 down. *Fix:* **Make a faithful set:** use the game's own Director camera (Client/Director, F8: free camera, lens, time controls) at top graphics.
- One action per image: a dummy mid-launch from the cannon with the scared face, the car hitting a row of real dummies, the real gorilla swat, the X-ray bones replay, a friend toss.
- Light colour grade only. No text.

**Run a fair test:**
- Keep the current AI icon as the control. It is the strongest piece we have.
- Run personalization for 14 days with the faithful set against the AI set.
- Judge on qualified play-through, average playtime and the share who leave within 60 s, not on clicks.

**If an illustrated style wins:** redraw it over the real captures (real dummy, real models, real faces), so the click delivers what was shown.
- **[high/medium/S] The title is a stale "[EVENT] RAGDOLL HAVOC" in all caps.** - **Stale tag:** the [EVENT] tag refers to two Experience Events that ended on 10 Nov and 14 Nov. No event is running or scheduled.
- **All caps:** the top games don't use all-caps hype; they keep a calm, fixed brand with one changing slot.
- **Unused options:** neither STORE_TEXT.md's title options nor Config.UPDATE_TITLE was ever applied.
- **Brand lost in translation:** Roblox's automatic translation turns the title into "[EVENTO] Caos de muñecos de trapo" (Spanish), "[EVENTO] Caos de Bonecos de Pano" (Portuguese) and "[EVENT] Kekacauan Ragdoll" (Indonesian).
- **Why it matters:** the title is the strongest signal on the home tile and in search. *Evidence:* - games.roblox.com/v1/games?universeIds=10774775314 returns name "[EVENT] RAGDOLL HAVOC".
- The virtual-events API shows the 2 events ended 2026-11-10 and 2026-11-14.
- The translated titles come from the same API with Accept-Language es-es, pt-br and id-id.
- STORE_TEXT.md:7-11; Config.luau:102.
- Vault "Cross-Game Patterns - Thumbnails Icons and Titles", Pattern 1 and line 54 (no all caps). *Fix:* - **Now:** set the title to "Ragdoll Havoc 💥".
- **From 1 December:** "[🎄] Ragdoll Havoc 💥" (CHRISTMAS_FROM_DEC1, Config.luau:97).
- **Update weeks:** "[UPD] Ragdoll Havoc 💥" for at most 3 days after a real update.
- **Log:** keep a dated title log in STORE_TEXT.md.
- **Translations:** enter titles by hand that keep "Ragdoll Havoc" (see the localisation finding).
- **Optional test:** after the art test, try one descriptor, e.g. "Ragdoll Havoc 💥 Physics Lab". Never more than one.
- **[high/medium/S] The description is the 0.20.0 text: stale, with a false claim, an unverified claim and none of the words players search.** **The live text** is Description v2 word for word, while the game is at 0.25.0. The recommended v4 text (STORE_TEXT.md:13-40) was never pasted.

**What is wrong:**
- **False:** "Prank Party: bring up to 6 friends". PARTY_MAX is 6 players and the server size is 6, so the most you can bring is 5 friends.
- **Unverified:** Prank Party and the toss combos are sold, but no 2-client test has ever run (V7_PLAN state; AUDIT.md area 14 is 5, unmeasured).
- **Missing the biggest current draws:** the 5 open-air maps, cars, the gorilla and bull herd, the creature yard.
- **A promise we don't keep:** "New toys and experiments every week!"
- **A risky line:** "Build your own contraptions in SANDBOX" could be read as free-form creation (16+).
- **Missing words:** "physics" appears nowhere on the page, "sandbox" only as a mode name, and the first line has no hook about friends.

**How the leaders open:**
- Hyper Realistic Ragdoll: "Hyper realistic ragdoll physics sandbox where every punch, shot and blast makes dummies stumble…"
- Bloody Ragdoll Physics: "Every dummy is a real physics body."

The #ragdollphysics tag on TikTok has about 38M views.

The store says "toys" while the game's button says WEAPONS. *Evidence:* - Live description from games.roblox.com/v1/games, matched to STORE_TEXT.md:67-89.
- Config.luau:79 PARTY_MAX = 6; Config.luau:80 SERVER_SIZE = 6.
- Competitor descriptions from the same API, universes 10773618503 and 10773926254.
- RESEARCH_V4.md:43 (the #ragdollphysics tag).
- Vault "Experience Description and Search Keywords": the first two lines should say the verb, subject, fantasy, social hook and the current update. *Fix:* Rewrite and paste today.

**Opening:**
- Line 1 (about 140 characters): "Launch, smash and fling ragdoll crash-test dummies in your own physics sandbox lab: a cannon, 60+ weapons, cars and a gorilla rampage."
- Line 2: "NEW: monsters in your lab's yard. 🎄 Christmas Lab opens 1 December."

**Then:** short sections (5 MAPS, YOUR LAB, EVERY DAY, devices). Keep the line "Cartoon effects only, no blood".

**Every claim must be checked against Config and the gate:**
- "up to 5 friends", not 6;
- Prank Party only once a 2-client test has passed;
- no weekly promise;
- no SANDBOX line.

**Keep one current text:** move the older versions to an archive heading in STORE_TEXT.md.
- **[high/medium/S] The tile shows a 63% rating and 17 favourites, and the favourite ask comes after most players have left.** **The numbers:**
- 5 up and 3 down make a 63% rating on every tile. The leaders sit at 83-90%.
- 17 favourites from 1,328 visits is 1.3%. Bloody Ragdoll Physics has 3.2%, Ragdoll Research 2.7%.

**The timing problem:**
- LikePrompt asks only after 3 minutes of play following a big moment, or at 8 minutes otherwise.
- Only 9% of players ever reach 5 minutes (84 Five Minutes badges for 931 Welcome badges).
- So more than 90% of visitors, including the happy ones, are never asked.

With only 8 votes, every vote moves the rating by several points. *Evidence:* - games.roblox.com/v1/games/votes: us 5/3; Hyper Realistic Ragdoll 33402/3511; Bloody Ragdoll Physics 32460/4965; Ragdoll Research 20412/4110.
- favoritedCount 17.
- LikePrompt.luau:90-91 (SHOW_AFTER 8×60, MIN_PLAYED 3×60) and :129-137.
- Badge stats from badges.roblox.com/v1/universes/10774775314/badges.
- RESEARCH_V4.md:57: a reference project asks new players 25 s after the tutorial. *Fix:* - **Ask earlier:** lower MIN_PLAYED to about 60 s, and ask right after the first big moment (first cannon flight, first UFO at about 45 s, a bullseye) for players with at least 1 takedown.
- **Keep the limits:** at most once per visit, never in the first 35 s, and never with a reward.
- **Keep the like reminder in words only.**
- **Measure:** add a SessionStats field for whether the player was asked and whether they favourited, so the change can be measured.
- The rating itself only improves with the first-session fixes. This change just makes sure happy players are asked while they are still in the game.
- **[high/medium/S] The questionnaire answer "Violence: Occasional/Mild" understates the game, and the switches it can reach are not covered.** - **Violence is the core of the game:** the whole loop is shooting, hitting and blowing up human-shaped dummies, again and again.
- **The weapons look and sound real:** about 21 real mesh firearms (AK, M4, Sniper, RPG, Minigun, Nuke). Several keep real names in the store and the game. Gunshots are recordings chosen to "sound like real guns".
- **Kills are explicit:** headshots kill at once, and dead dummies turn green and lie for 60 s.
- **The honest answer is "repeated, mild":** that gives the Mild label, which is still eligible for Kids and Select. "Occasional" invites a re-rating or a failed Kids/Select review.
- **The rule:** the questionnaire must cover the most extreme content the game can reach, including switches. Config.SEVERING and Config.BLOOD = "purple" are one edit away.
- **Kids (5-8) is unrealistic** with real-looking guns and a Nuke. Aim for Select (9-15). *Evidence:* - The experience-guidelines API returns the descriptor violence: frequency "occasional", intensity "mild".
- Config.luau:15 (SEVERING) and :34 (BLOOD).
- Toys.luau:111-122: TOY_NAMES renames only 11 guns; Sniper, Minigun, Nuke, Grenade and C4 keep their real names.
- CLAUDE.md, 10 Nov: real gun recordings; Phase 2b: 21 real mesh models.
- Vault "Gore Policy and Kid-Friendly Hit Feedback": answer for the most extreme reachable content. *Fix:* **Owner:**
- Re-answer violence as repeated, mild (cartoon, no blood).
- Keep the label at Mild and aim for Select.

**Code:**
- Make SEVERING and BLOOD purple build-time only. The release gate fails if either is on, and the questionnaire then matches the live build.

**For a later Kids attempt:**
- toy colours or skins on the firearms;
- Nuke renamed, e.g. "Mega Boom".
- **[high/high/M] Discovery is starving: about 15 new players a day, "0 playing" on the tile, and no traffic plan.** **Where we stand:**
- 1,328 visits in 15 days.
- The Welcome badge was earned 15 times in the last 24 h, and 2 players reached 5 minutes.
- "playing" was 0 when checked. Next to rivals showing 88k, 19k and 12k, the tile reads as dead.

**Why the A/B tool can't help yet:** thumbnail personalization needs volume (RESEARCH_V4.md:111: under 1,000 daily users, results may mean little), so even good art won't learn.

**What we lack:**
- no Sponsored Ads test;
- no Creator Hub share link used in posts (they carry attribution for Creator Rewards);
- the creator kit (docs/CREATOR_KIT.md) was never published and is outdated.

**Timing:** the ragdoll wave is now. All three leaders launched 28-31 Oct. *Evidence:* - Badge statistics: Welcome pastDayAwardedCount 15, Five Minutes 2.
- Games API: visits 1328, playing 0, created 2026-11-05.
- Competitors' created dates from the games API: 2026-10-28, -29, -31.
- RESEARCH_V4.md:107-122 (personalization needs volume).
- Vault "Sponsored Ads and Campaign Math"; "Discovery and the Algorithm" §5-6. *Fix:* **Order matters:**
1. Fix the first session first (median visit above 4 min).
2. Then run a small Sponsored Ads test, e.g. 3-5k Robux over 5 days, with 2 creatives (the winning faithful thumbnail and a short video). Use it to measure play-through, early bounce and play time on real traffic.
3. In the same week, create Creator Hub share links for every TikTok post and creator.
4. Refresh CREATOR_KIT.md to the current build and send it to 10-20 small ragdoll TikTok creators. No paid post without the disclosure rules (vault "Marketing to Kids and Teens").
- **[medium/medium/S] No store video, while two of the three leaders have one.** - Our page has 3 images and no video.
- Hyper Realistic Ragdoll has 9 images and a video; Ragdoll Research has 4 and a video.
- A 30-second directed gameplay script already exists (docs/TRAILER.md, tools/TrailerCam.luau, tools/TrailerServer.luau), and so do the Director's 6 one-tap TikTok shots. Nothing has been uploaded.
- Video uploads are free, 3 a month (rejected ones count too), and they don't show on consoles. *Evidence:* - games.roblox.com/v2/games/{id}/media: ours 3 Image; 10773618503 has 9 Image + 1 GamePreviewVideo; 10773425091 has 4 Image + 1 GamePreviewVideo.
- docs/TRAILER.md:1-31.
- Vault "Thumbnails Icons and Store Page" §1: video specs and rules. *Fix:* - Record a 20-30 s cut with the Director: cannon launch, car through a dummy row, gorilla swat, X-ray replay, a tornado, one open-air map.
- Put the most violent knock-down in the first 2 s.
- No voice, no lyrics, no claims.
- Upload it as the first media item.
- Redo it after each big update. That uses 1 of the 3 monthly uploads.
- **[medium/medium/S] Thumbnail testing can't produce an answer: 3 look-alike images, a cadence that resets tests, nothing written down.** **The images:** only 3 thumbnails are live, all in the same AI style. Roblox staff advice is 2-5 active, clearly different from each other, kept for at least 7 days and not changed on update days.

**The cadence:** we published 136 commits over 19-20 Nov. RELEASE.md publishes at the end of every /klar run, so no test window stays undisturbed.

**The records:** nobody has written down a hypothesis, a metric or a stop rule. The v4 README (art/store/v4/README.md:17-20) wrongly suggests an icon A/B test; Roblox has no built-in icon test. *Evidence:* - Media API: 3 images.
- git log --since 2026-11-05: 64 commits on 19 Nov and 72 on 20 Nov.
- RELEASE.md:10-13 (publishes after every plan).
- RESEARCH_V4.md:112 (no built-in icon test) and :114-121 (staff tips).
- art/store/v4/README.md:19. *Fix:* **Run one proper test:** 5 thumbnails in 2-3 clearly different ideas (launch, crowd crash, creature/event, friend toss, X-ray), for 14 days.

**Write it down first,** in STORE_TEXT.md: the hypothesis, the metric (qualified play-through plus average playtime) and the stop rule.

**Protect the window:** no art changes during it, and no publishes on its first and last day.

**The icon:** Roblox can't A/B test it, so test it by swapping weekly.

**Fix the README's icon-test step.**
- **[medium/low/S] The repo's store art can't be used: player names, a stranger's avatar, debug text and a HUD chip.** **art/store/v4, the "real captures":**
- They show "ROLINGSTUDIOS'S LAB" and leaderboards with other players' usernames (e.g. "potcito 296"). That is a privacy problem on a kids' platform.
- icon_gorilla.png centres a real player's avatar.
- thumb2 and thumb3 show a "FREE LAB / Closed until someone owns it" sign.
- thumb1 shows the chat bubble "Has anyone seen the fountain work?".
- thumb5 has the HUD chip "Slow-mo V View" in the bottom-left, where the player-count overlay sits, and a black pillar across its centre.
- thumb2 and thumb3 use the same camera angle.
- Several show Santa hats although Christmas starts 1 Dec.
- Both icons are scenes, not one subject. The vault says a scene can't be read at 64 px.

**art/store/icon.png and the three thumb_*.png:** yellow 2D doodle dummies with title text. The game's dummies are white 3D mannequins. *Evidence:* - Viewed: art/store/v4/thumb1_gorilla.png, thumb2_ufo.png, thumb3_storm.png, thumb5_bulls.png, icon_gorilla.png, icon_ufo.png.
- Viewed: art/store/icon.png, thumb_fling.png, thumb_lava.png, thumb_tnt.png.
- Vault "Game Icon Design - Readable at Small Sizes" (TL;DR). *Fix:* - Mark both sets obsolete: art/store/v4/README.md "do not upload", or move them to art/store/_old.
- Every new capture: Director mode with the HUD off and Streamer Mode names hidden.
- Blur or remove every username, leaderboard and sign.
- Christmas items only after 1 Dec.
- Add a store-art checklist to RELEASE.md.
- **[medium/medium/M] The game is on a personal account: no group, no community, no group perk.** - **Ours:** the creator is the user account "tristancqq", with no verified badge.
- **The leaders:** all three new ones are group-owned (Emo Playworks, blablablablabla123123, Ragdoll Shenanigans). Ragdoll Engine gives a free Push, Potion and Speed Coil for joining its group.
- **The code is ready but idle:** Shop.GROUP_ID = 0, so the group gift card in RewardsUI stays hidden.
- **What a group gives:**
  - a community page;
  - announcements that reach members, a free way to bring players back;
  - a join perk (allowed, unlike rewarding likes);
  - several admins. *Evidence:* - Games API creator: type User, hasVerifiedBadge false.
- Competitor creators: type Group, from the same API.
- RESEARCH_V4.md:38.
- Shop.luau:47-50 (GROUP_ID = 0).
- Vault "Community Building" TL;DR. *Fix:* 1. Create the group "Ragdoll Havoc" and set Shop.GROUP_ID.
2. Turn on the existing group gift: one weapon egg. Ask only after the first session, at most once per visit.
3. Post an announcement with every real update.
4. If Creator Hub offers transferring the experience to the group, check first that passes, products, badges and DataStores stay with the universe. Then transfer.
- **[medium/medium/S] The Experience Events are stale and misleading, and the real Christmas event isn't scheduled.** **Two past events are still listed as active:**
- **"UPDATE 1.5" (ended 10 Nov):** promises "many more weapons … improving multiplayer" and has a typo ("aswell"). Its picture is a white mannequin with the classic Roblox face and arrows, on a green grid: Hyper Realistic Ragdoll's look, not ours.
- **"Santa's Homecoming!" (ended 14 Nov):** subtitle "Admin abuse??", text "You do not want to miss this…", and a candy-cane world with Santa avatars that the game doesn't have.

**Version names clash:** "UPDATE 1.5" here, "Version 0.25.0" in the game's What's New.

**The missed chance:** the Christmas Lab really opens on 1 Dec, 10 days from now. That is the right event: people who RSVP get a notification, and it gets its own section on the store page. *Evidence:* - apis.roblox.com/virtual-events/v1/universes/10774775314/virtual-events: two events, both eventStatus "active", end 2026-11-10 and 2026-11-14.
- Event pictures 101996158939372 and 125175992765875, downloaded and viewed.
- Config.luau:97 (CHRISTMAS_FROM_DEC1).
- EventShop.luau:1044 ("Version " .. entry.version). *Fix:* - Hide or delete both past events.
- Create "🎄 Christmas Lab opens" for 1 Dec (chimney launcher, present trap, sleigh ramp, advent experiments), with a picture from a real Christmas-lab capture.
- After that, one event per real named update.
- Use one public version name, e.g. "Update 26", in events, What's New and the title slot. Drop "0.x".
- **[medium/medium/M] Updates come at no fixed time, and every publish shuts down all servers without moving players.** **Publishing:** every /klar run ends with a publish and then "Shut Down All Servers" (restartServers). On 19-20 Nov that happened several times a day.

**What players lose:** there is no soft shutdown. BindToClose only saves; nobody is teleported to a fresh server. A player in the middle of a visit is kicked, which shortens visits and spoils the stats Roblox ranks on.

**What we promise vs. what we do:**
- The description promises "New toys and experiments every week!".
- Config.UPDATE_DAYS says Thursday and Saturday.
- The [UPD] title slot has never been used.
- In practice nothing follows a rhythm.

**Benchmarks:**
- Bloody Ragdoll Physics updates almost daily.
- Fling lived a year without updates on social play.
- Players need a rhythm they can see. *Evidence:* - RELEASE.md:55-57 (restart old servers = Shut Down All Servers).
- grep: no teleport migration in any BindToClose (only saves).
- Config.luau:102-103.
- Git: 136 commits on 19-20 Nov.
- RESEARCH_V4.md:86-90 (cadence). *Fix:* - **Public rhythm:** one named content update a week (Saturday) with the [UPD] slot for 3 days.
- **Fixes:** silent hotfixes are allowed, but go out with a soft shutdown. On BindToClose, reserve a server and TeleportAsync everyone into it with their lab state, then back to a fresh public server.
- **Pacing:** never restart more than once a day.
- **Text:** drop the "every week" promise until it has held for 4 weeks.
- **[medium/low/S] The live store page is kept outside the repo and the release gate, so it drifts.** **What is out of sync:**
- The live title and art are not in the repo.
- STORE_TEXT.md recommends v4, but v2 is live.
- art/store/v4 was never uploaded.

**The gate doesn't help:** it only says "Update STORE_TEXT.md if something big came in", then hands the owner a reminder at the end. Nothing checks that the live page matches the build. *Evidence:* - RELEASE.md:35 and :73-74.
- STORE_TEXT.md:13 (v4 "recommended") against the live text = v2.
- Live media ids are not referenced anywhere in the repo.
- docs/V4_PLAN.md:361-362. *Fix:* **Make the live page part of the release gate:**
- Add a "LIVE" section to STORE_TEXT.md, refreshed by reading games.roblox.com, the media endpoint and the age-recommendation endpoint.
- The gate fails if the live title or description contradicts Config: birds, party size, Christmas dates, removed features.
- If Open Cloud's Place update lets us write displayName and description (check the scope), sync the text automatically. Otherwise send the owner a ready-to-paste block.
- Keep the live art files in art/store/live, with their upload dates.
- **[low/low/S] Automatic translation renames the brand.** Spanish, Portuguese and Indonesian players see "Caos de muñecos de trapo", "Caos de Bonecos de Pano" and "Kekacauan Ragdoll".

Why it matters:
- A child who hears "Ragdoll Havoc" in a TikTok and searches it in their own language sees a different name.
- Search attribution and Creator Rewards depend on people finding the exact brand.
- The descriptions are machine-translated too. *Evidence:* - games.roblox.com/v1/games?universeIds=10774775314 with Accept-Language es-es, pt-br and id-id returns the names above; sourceName is null.
- Vault "Experience Description and Search Keywords": localise for search, and use the exact title in posts off Roblox. *Fix:* 1. In Creator Hub → Localization, enter titles by hand that keep "Ragdoll Havoc 💥" in the top locales. Check Audience → locale first; Spanish, Portuguese and Indonesian are likely.
2. Add a short translated first line with the local words for "ragdoll physics sandbox".
3. Do this after the English text is final.
- **[low/low/S] The Store tab looks unfinished: the ULTRA icon reads "ULTR / A".** - The two game passes on the page's Store tab use plain circle icons with text.
- ULTRA's text wraps into "ULTR" over "A".
- These icons are the first look at what we sell. They read like placeholders. *Evidence:* - thumbnails.roblox.com/v1/game-passes?gamePassIds=2075722841,2075632736, downloaded and viewed.
- apis.roblox.com/game-passes/v1/universes/10774775314/game-passes: ULTRA 249 R$, VIP 149 R$. *Fix:* Draw two proper 512 px pass icons in the store-art style:
- VIP: a gold VIP tag over a dummy's head.
- ULTRA: a lightning bolt over a barrage of weapons.
- No wrapped text; readable at 150 px.

The owner uploads them on the dashboard.
- **[low/low/S] What's New and the creator kit make claims that are no longer true.** - **What's New 0.25.0** still says "BIRDS that really fly", and 0.24.0 says "BIRDS over your lab and every map". Birds were switched off on 20 Nov.
- **CREATOR_KIT.md** says it is for build 0.19.0. It sends creators to:
  - spikes, which were removed;
  - "Golden Popper (600 takedowns)";
  - the arena games Red Light Green Light and Shoot 'Em.
- A creator who films from this kit, or a player who reads What's New, finds things that aren't there. The vault calls false claims a moderation and trust risk. *Evidence:* - Shop.luau:64 and :73 against Config.luau:165 (BIRDS = false).
- docs/CREATOR_KIT.md:3, :28, :29, :32.
- AUDIT.md:32 (spikes removed). *Fix:* - Remove the bird lines from What's New 0.25.0 (and 0.24.0's history).
- Rewrite CREATOR_KIT.md for the current build: Director shots, X-ray replay, cannon, gorilla, open-air maps.
- Add a release-gate check that searches the What's New lines for the names of switches that are off.
- **[low/low/S] Private servers are off, so Streamer Mode only works for the owner.** - The live universe has createVipServersAllowed = false.
- StreamerService lets Streamer Mode run only in a private server that the player owns. That is exactly what TikTok creators need for the CREATOR_KIT formats.
- With private servers off, no outside creator can use it, and friends can't keep a server of their own.
- The leaders don't offer private servers either, because their servers hold 1 player. For our lab-plus-friends design, free private servers would set us apart. *Evidence:* - games.roblox.com/v1/games: createVipServersAllowed false.
- StreamerService.luau:58-77 (needs PrivateServerId and PrivateServerOwnerId).
- docs/CREATOR_KIT.md:5-15. *Fix:* Turn on private servers for free (0 Robux) in Creator Hub → Monetization → Private Servers. Mention "free private servers" in the description and the creator kit only after it is on.
- **[low/low/S] The badge list on the page says nothing.** - The five live badges' descriptions just repeat their names, e.g. "First Takedown" reads "First Takedown".
- Badges and their win rates appear on the store page and are a small discovery surface.
- Three planned badges have id 0 (Takedowns100, Nuke, Takedowns1000). *Evidence:* - badges.roblox.com/v1/universes/10774775314/badges: names, descriptions, and Welcome 931 / First Takedown 630 / First Egg 465 / Five Minutes 84 / Bullseye 45.
- CLAUDE.md, "Badges live". *Fix:* - Write one fun, true line per badge, e.g. "Bullseye: land a dummy dead centre from the cannon".
- Create the 3 missing badges, plus a Christmas Lab badge for 1 Dec.
- Use the same art style as the new icon.

**Cut or hide:** The [EVENT] tag and the all-caps title. Use "Ragdoll Havoc 💥" with one dated slot instead.; The two past Experience Events: "UPDATE 1.5" (ended 10 Nov; another game's look) and "Santa's Homecoming!" (subtitle "Admin abuse??").; These description lines: "bring up to 6 friends" (false, the most is 5), "New toys and experiments every week!" (a promise we don't keep), "Build your own contraptions in SANDBOX" and "Share the code" (could be read as free-form creation, 16+), and the Prank Party combo claims until a 2-client test has passed.; The five old description versions in STORE_TEXT.md. Keep one current text plus a dated archive, so the wrong one can't be pasted again.; All of art/store/v4 (usernames, a stranger's avatar, a FREE LAB sign, a chat bubble, a HUD chip, Santa hats in November) and the yellow 2D doodle set in art/store (icon.png, thumb_*.png). Mark them obsolete; never upload them.; The AI thumbnails that show things the game doesn't have (a row of 20+ dummies, the blue sedan, the cartoon gorilla), once the faithful set wins the test. Keep the AI icon only as the control.; The bird lines in What's New 0.25.0 and 0.24.0 (birds are off).; The outdated parts of CREATOR_KIT.md: build 0.19.0, spikes, Golden Popper 600, the arena games.; The "0.x" version numbers in public text ("Version 0.25.0" reads as a beta). Use one name, e.g. "Update 26".; The placeholder text-circle pass icons (ULTRA reads "ULTR / A").; The live SEVERING and BLOOD purple switches. Make them build-time only, so the questionnaire matches what can be reached live.; The "redo the maturity questionnaire for all ages" advice in CLAUDE.md:136, RESEARCH_V4.md and RELEASE.md:73. The label is already Minimal; the real block is the Kids and Select requirements.

### O - Code health and tests (flaky tests, Config switch sprawl, dead features, Script Sync, release gate, user-journey tests, shipping speed and safety): 3/10
Some things are better than in most small Roblox games: `--!strict` in every file, 94 self-tests, a 16-screen LayoutCheck, validated remotes and a per-visit Session_v1 record. The pipeline around them is weak, though. Shipping is neither safe nor fast:
- **Boot:** neither boot is fault-isolated. One error stops saving and purchases for a whole server, or the HUD and shooting on a phone.
- **No signal from live:** there is no error telemetry.
- **Test runner:** it only runs inside a manual 10-12 min Studio Play. A timed-out test keeps running, a skipped test prints PASS, and six known-flaky tests are accepted, including the progress/save test. None of the tests drives a real player journey. 62 of 83 client modules (FirstVisit, TouchShoot, MoveStick) are never touched by a test, although most players are on portrait phones.
- **Sync:** Script Sync writes straight into the live place. It dropped out for two whole /klar runs, and the code was then copied into Studio by hand, checked only by file size.
- **Assets:** imported models live only in the unversioned place file.
- **Release gate:** it has items that cannot be met. It never passed, and the build went out through Alt+P anyway.
- **Config:** 42 compile-time switches, 42 `(Config :: any)` casts that hide typos, and dead features still kept and loaded.
- **Two HUDs:** phones, the biggest platform, still run the legacy one.
- **Growth:** about 92k lines, growing about 9k a day with almost nothing deleted.
- **Process:** no CI, no lint config, and `main` has 1 commit while `release` has 135.

The earlier self-score of 7 (AUDIT.md:29) was generous.

**10/10 means:** 1) **One reproducible source of truth.**
- Code and every imported model (.rbxm exported from N7Assets, V3Assets, V3Packs, DummySkin, MaterialVariants, sky) are in git.
- A Rojo project, or Script Sync aimed only at a DEV place, builds the place file from a commit.
- Studio never syncs into the live place.
- Every build carries a stamp (git sha plus a manifest hash). The server prints it at boot, Session_v1 stores it, and the gate refuses to go on if Studio's script hashes differ from the repo.

2) **Three places with the same artifact.**
- DEV is synced, with its own DataStores.
- STAGING is published by the pipeline and played on the owner's phone and with 2-3 clients.
- LIVE gets the promoted build.
- Updates go out with Restart Servers for Updates (auto-reconnect) or a soft shutdown, never a hard kick.
- An automatic rollback trigger fires on a Session_v1 or crash-free regression.

3) **CI on every push**, in under 2 minutes:
- selene, StyLua check, and luau-lsp strict analyze with Roblox definitions;
- pure specs in lune, covering the Shared economy, odds, ladder, NotifyRules, PadMap, PathPlan and Config invariants;
- engine specs through Open Cloud Luau Execution against the staging place version, returning a JSON summary.

4) **Studio suite** through a StudioTestService plugin runner:
- solo runs, plus ExecuteMultiplayerTestAsync(2-3);
- each test in its own sealed arena, built and destroyed per test, with the ambient systems paused through one TestMode module;
- an injected clock and RNG, no fixed sleeps, and task.cancel on timeout;
- PASS/FAIL/SKIP kept apart; SKIP fails the gate;
- zero known-flaky tests (quarantined tests count as failures);
- the full run in under 5 minutes.

5) **Five journey tests** with VirtualInput or the MCP input tools, on real screen sizes:
- a new portrait phone player gets a takedown within 10 s, the HUD by 35 s, a mission and a wow on time, 0 errors and 0 overlaps;
- a new PC player opens WEAPONS and equips a weapon;
- a returning player gets the full HUD and the saved bar;
- a 2-client party grabs, throws and gets a combo on both screens;
- a 10-minute soak shows no memory or instance growth and 0 errors.

6) **Fault-isolated boots.**
- Server and client start every system in a pcall and report a boot health list.
- The client sends BootOk plus error counts and signatures, rate-limited.
- Session_v1 and AnalyticsService show crash-free sessions per build.
- The gate requires at least 99% crash-free sessions on staging.

7) **Config.**
- At most about 15 code constants.
- Live tuning, A/B values and kill switches live in ConfigService, with code defaults and targeting: new vs returning, platform.
- The first-minute timings are A/B-tested without a republish.
- Every flag has an owner, an added date and an expiry. CI fails on unknown or expired flags.
- The losing branch is deleted once a flag has stayed at its final value for a release.

8) **Code.**
- One HUD with per-platform layouts.
- No v2/v3 fallbacks, and modules of 600 lines at most.
- ProfileStore is split from the features and fully tested with a DataStore fake.
- Test hooks come through injected dependencies, not *ForTest globals.
- `main` is what is live: tagged, with short feature branches, one feature plus its test per merge.

- **[critical/high/S] Server boot has no fault isolation: one error kills saving and purchases for the whole server.** Main.server.luau starts about 60 systems in one straight run. Only Landscape is wrapped in a pcall. ProgressService.start (the profile, takedowns and saving) runs only after ~40 other starts, and Purchases.start (the one ProcessReceipt) after ~50. If any earlier start() throws on a live server (CrowdService, WorldMaps, MapActivities, PathBuilder, MapShopService and so on), every system after it never starts: no profile load or save, no ProcessReceipt, and no ChaseService, VisitorService or BadgeAwards. Players then lose progress, and paid purchases go undelivered. New systems are added every day (V6/V7), so the chance of an uncaught error grows. *Evidence:* ServerScriptService/Server/Main.server.luau:14-119 (pcall only at :77-84 for Landscape); ProgressService.start at :95, Purchases.start at :104, after MapShopService :85 and PathBuilder :86 *Fix:* - Replace the run with a table of {name, start} pairs started by `safeStart(name, fn)` (pcall plus Log plus append to Workspace attribute BootFailed).
- Move Purchases, ProgressService, LoadoutStore and SessionStats to the front (data and money first).
- Add a T-test that injects a throwing fake system and checks that the later systems still started.
- Gate: BootFailed must be empty.
- **[critical/high/S] Client boot has no fault isolation and no boot-complete signal: phones can be left unable to shoot.** Main.local.luau makes about 45 `.start()` calls in a row without a pcall. Only 12 are task.spawn'ed. If FxController.start (:61) or any module before PokeController.start (:79) throws on one device class (a portrait phone, a gamepad, a low-memory device), there is no fire path, no HUD and no onboarding. The player can only leave, and nothing records it: Session_v1's `boot` is written before most modules start (SessionClient starts first, :45). With a 120 s median visit and portrait phones as the main audience, nobody can currently tell how many leavers had a broken client. The Birds module is still required and started (:58), although BIRDS = false. *Evidence:* StarterPlayerScripts/StarterPlayerScripts/Client/Main.local.luau:45-125 (pcall only in the Studio DevLayoutCheck hook :141); Birds start at :58; grep for 'Booted|BootDone|ClientReady' finds 0 hits *Fix:* - Add a `safeStart` wrapper for every client module.
- At the end of boot, fire Session 'Boot' {ok=true, failed={...}, ms=...}.
- Add Record fields `bootOk` and `bootFail` to SessionStats.
- tools/SessionReport: report the share of visits without bootOk per platform and build.
- Stop requiring modules whose switch is off.
- **[high/high/S] No live error telemetry: the team has no signal from live play.** The Session_v1 record holds input, screen size, shots and takedowns, but no client or server error counts, no boot completion, and no fps or memory. The only error capture is AdminTools keeping the last 6 error strings in memory for the owner's DEBUG tab. Every question about why players leave at about 2 minutes is answered by guessing at timings (QUIET_START 90 -> 35, and so on), not from errors. The top Roblox games watch the crash-free rate per build. *Evidence:* ServerScriptService/Server/Systems/SessionStats.luau:26-58 (Record type); ServerScriptService/Server/Systems/AdminTools.luau:510-516 (6 errors, memory only); ServerScriptService/Server/Systems/Metrics.luau:1-40 (no error events) *Fix:* - Client: ScriptContext.Error -> a rate-limited remote (max 5 per session) -> the server adds `errs` (count) and `errSig` (the first 3 traceback heads, 80 chars each) to Session_v1.
- Add an AnalyticsService custom event 'ClientError' with a module field.
- Server: the same through LogService.MessageOut.
- Read the Creator Hub Error Report every release.
- Release check: crash-free sessions per pv, with rollback if it falls under 98%.
- **[high/high/M] The release gate is advisory, partly impossible, and was bypassed; publishing hard-restarts players.** RELEASE.md demands:
- a 2-client play session and a phone-emulator session, which the session says it cannot start from the MCP;
- a pass on every blind review, which are scored by the same model (V7-4 4.0 -> 6.5, still under 8.5).

The gate failed in run 1 and in run 2 (T32, 2-client, emulator, reviews). Run 3 saved v602 and 'needs Alt+P'. 0.25.0 is now live, so the gate did not stop the publish. Step 4 restarts all servers through Open Cloud restartServers, which kicks every player mid-session, in a game whose problem is that players leave. There is no staging place, no canary and no rollback threshold. *Evidence:* docs/RELEASE.md:15-35 (gate), :49 (publish into the live place), :55-57 (restartServers); docs/V7_PLAN.md:254 (review scores), :271 and :320 (gate failed), :357 (v602, needs Alt+P); DevForum: https://devforum.roblox.com/t/automatically-reconnect-to-experiences-during-updates/2866485 and https://devforum.roblox.com/t/improvements-to-updating-experiences/2600703 *Fix:* Rewrite the gate as one script (tools/Gate.luau plus a plugin runner) that returns PASS/FAIL JSON from:
- (a) static checks;
- (b) the suite through StudioTestService, including ExecuteMultiplayerTestAsync(2) (this removes the 'impossible' 2-client item);
- (c) the journey tests;
- (d) LayoutCheck;
- (e) Studio flags off and BuildStamp equal to HEAD.

Then:
- Publish to a STAGING place first, with a 5-minute owner phone smoke test and Session_v1 from staging.
- Promote the same file to live.
- Use 'Restart Servers for Updates' (auto-reconnect) or a soft shutdown, not a hard restart.
- Write the rollback threshold down: crash-free under 98%, or a median visit 20% under the last build.

Self-scored reviews advise and never gate.
- **[high/medium/M] Studio syncs into the LIVE place; there is no dev or staging place, and Studio play uses live DataStores.** The working Studio place is the live placeId 126037745825106. Saves go into the live place's history, and the publish pushes the same file. Outside self-tests, Studio play probes and then uses the real Profile_v1 (and Loadout, Onboarding, Builds) stores. Every manual playtest by the owner or an agent changes the owner's live profile ('Testene giver din egen Studio-profil lidt BOLTS'). The vault rule is to point sync at a DEV place, never the live one. *Evidence:* CLAUDE.md line 3 (Studio place = live placeId); ServerScriptService/Server/Systems/ProgressService.luau:1850-1860; LoadoutStore.luau:182-192; OnboardingService.luau:500-512; TEST-ALT.md section 2.4; vault '01 Studio and Workflow/External Tooling - Rojo Wally Selene StyLua.md' TL;DR ('Avoid: Syncing into the live place') *Fix:* - Create a 'Ragdoll Havoc DEV' experience (own universe, so own DataStores) and a 'STAGING' experience.
- Point Script Sync (or Rojo servePlaceIds) only at DEV.
- Live changes only through promoting a built place file.
- Studio Play in DEV may use real stores freely.
- **[high/medium/M] Script Sync fragility: two whole runs were mirrored into Studio by hand, checked by file size only, with no build stamp.** After a Studio auto-update, Script Sync did not resume (auto-resume fails when the Studio version or the disk changed after close). For /klar runs 2 and 3, every change was copied into Studio by MCP find/replace, then 'checked in size' or 'byte for byte' by hand. A same-length edit or a missed file goes unseen. Script Sync's source of truth is Studio, with files mirrored, so when sync reconnects after hand edits, either side can overwrite the other. Nothing in the code says which commit is running: Version '0.25.0' is bumped by hand, and grep finds no commit or build hash. *Evidence:* docs/V7_PLAN.md:283-284 ('Script Sync was still down... put into Studio by hand... match the repo in size'), :340 ('Script Sync is still down. Every change was mirrored into Studio by hand'); ServerScriptService/Server/Main.server.luau:44 (only Config.Version is logged); DevForum Script Sync beta thread: https://devforum.roblox.com/t/studio-script-sync-now-in-beta/4065468 and https://devforum.roblox.com/t/early-preview-studio-script-sync/3257548 *Fix:* - A git pre-commit hook writes Shared/BuildStamp.luau {sha, files, manifest} plus build/manifest.txt (sha1 per synced file).
- tools/SyncCheck.luau (MCP execute in Edit mode) hashes every ModuleScript and Script Source and diffs it against the manifest, printing the missing, extra and different files.
- The server prints BuildStamp at boot, and Session_v1 stores it.
- The gate refuses on any diff.
- Medium term: move to Rojo, so `rojo build` makes the published file from git and sync drift cannot happen.
- **[high/low/M] Imported models and materials live only in the unversioned place file.** - .gitignore excludes *.rbxl.
- These exist only in the place: N7Assets (21 gun meshes), V3Assets (29+ store models, creature rigs, garden, pets), V3Packs, DummySkin, BirdModels, MaterialService.AssistantMaterials, the realistic sky, LabCannon and the BaseplateEast/West pieces.
- Backups are loose .rbxl copies in Documents\RagdollLab-backups.
- A clean checkout cannot produce the game, cloud sessions cannot test the world, and a bad model edit can only be undone by restoring the whole place.
- Malware was found 4+ times in store inserts. Without versioned assets there is no diff to show what changed. *Evidence:* .gitignore (*.rbxl, *.rbxlx); CLAUDE.md 'place file only' notes (N7Assets, V3Assets saved v471, V3Packs v485, DummySkin, MaterialVariants, OldSky_Backup); docs/RELEASE.md:40-43 (backup = a copy of the place) *Fix:* - Export each asset folder as .rbxm into art/models/ (MCP or Studio 'Save to File').
- Map them in a Rojo project, or re-import them with a tools/LoadAssets.luau.
- Keep an asset manifest (name -> asset id, part and triangle count, script count = 0) checked by T36.
- The release backup becomes a git tag plus the rbxm set.
- **[high/low/S] Self-test runner defects: leaked threads after timeout, wrong prefix matching, duplicate numbers, untraceable names, console-only results.** (a) runWithTimeout returns on timeout, but the test's thread keeps running and changing the world while the next test starts. This explains order effects such as T16, which fails in the suite and passes alone.
(b) SelfTestOnly uses a plain prefix: 'T10' also runs T100-T108, and 'T40' runs two tests.
(c) Four numbers are used twice: T40, T41, T42 and T99.
(d) The runner prints t.name, which for about 40 older tests is a kebab label ('dummies-walk-limp-crawl-faint-flee') without the T-number that the flaky list and the gate use.
(e) Results exist only as console prints, which the gate scrapes through the MCP. *Evidence:* ServerScriptService/Server/SelfTest.server.luau:27-48 (timeout without cancel), :74-83 (prefix match), :105 and :108 (print t.name); Tests folder: T40_Christmas and T40_GripAlignment, T41_SoundManifest and T41_TrollMenu, T42_Retention and T42_Sprint, T99_LabZones and T99_NetProbe; docs/V7_PLAN.md:287 (T16 fails in the suite but passes alone) *Fix:* - Keep the thread from task.spawn and call task.cancel on timeout, then reset the shared world (Lab.rewind, release the holds).
- Match by `^T%d+_` and the exact number.
- Renumber the duplicates.
- Print '<file> <name>'.
- Write a JSON summary to ServerStorage attribute SelfTestResult and return it through StudioTestService:EndTest, so the gate reads data, not the console.
- **[high/medium/S] A skipped test counts as PASS: about 20 tests turn green without running.** About 20 tests return 'skipped (no player)' or append 'skipped', and the runner counts the result as passed. If the player joins late, a Run-mode session is used, or the 15 s player wait times out, the first-minute and money tests are reported green without running: T23 FirstSeconds, T45 FirstMinute, T47 TryFree, T43 Gifts, T44 Grab, and T101-T108 (admin, director, creatures, map shop). *Evidence:* ServerScriptService/Server/SelfTest.server.luau:103-105; T23_FirstSeconds.luau:211, T45_FirstMinute.luau:157, T47_TryFree.luau:64, T43_GiftsSpectate.luau:82, T101_AdminTools.luau:47, T105_MapShop.luau:38, T108_CreaturesWork.luau:40, T46_RewardsSandbox.luau:47 and :125 *Fix:* - Tests return {status='skip', why=...}.
- The runner prints SKIP and counts it apart (DONE pass= fail= skip=).
- The gate fails if any gate-listed test is SKIP.
- The runner waits for the player and its character before starting the player tests.
- **[high/medium/L] Flaky tests come from a shared live world and stale hard-coded coordinates; the save/progress test is on the accepted-flaky list.** Six tests are accepted as flaky (T15, T19, T24, T25, T27, T32), and the gate allows them to fail. T27 bundles the save-critical profile clean/merge checks, which are deterministic, with a physics knock-down at LabOrigin+(30,0,-60), where plaza booths and paths now stand. When the physics flakes, the merge coverage is ignored too.

T24 and T21 use 'open baseplate' coordinates written before LAB_V6 and Landscape: x=1000 and x=-950 are now on lab plot centrelines (plots every 250 studs out to ±1250), next to a hill band (DEPTH 360, PEAK 110), and no test checks that the spot is clear.

T32 tests personalities while visitors, creatures, the crowd and surprises are live.

The tests hold 304 fixed task.wait sleeps, and 30 tests each define their own waitFor. *Evidence:* CLAUDE.md:23 and docs/MASTER_PROMPT.md:43 (flaky list); docs/RELEASE.md:17; ServerScriptService/Server/Tests/T27_Progress.luau:42-70 (pure merge at :43-56, physics at :61-70); T24_CombatFeel.luau:19 ORIGIN (1000,0,640); T21_Catalog.luau:18 ORIGIN (-950,0,480); Lab.luau:131-136; ReplicatedStorage/ReplicatedStorage/Shared/Zones.luau:17; Landscape.luau:23-26; T32_NpcLife.luau:55-140 *Fix:* - Add a shared Tests/Lib module (waitFor, withPlayer, arena, withHold) and a TestArena far off the map (for example y=4000, its own baseplate), built and destroyed per test.
- Pause every ambient system (visitors, chasers, surprises, creatures, crowd AI, the UFO) through one TestMode switch.
- Split T27 into a pure spec (profile clean/merge/addOnto, run in lune) and a physics test.
- Replace the sleeps with condition waits.
- Quarantined tests count as FAIL for the gate.
- Target: 0 known-flaky, and 3 green runs in a row before the list may be emptied.
- **[medium/medium/S] Test hooks and ad-hoc test-mode checks leak into production code, without teardown.** 36 of 71 server systems carry *ForTest hooks. Holds are set without try/finally: in T32, CrowdService.holdForTest(true) runs at :59, and if the assert at :76 fails, holdForTest(false) at :98 never runs, so the crowd stays frozen for every later test. 14 systems read ServerStorage RunSelfTest themselves. Some do not check IsStudio: if a place is published with the attribute left on, EventService's surprise loop silently switches off the lab surprises and the 45 s UFO 'first wow' on live servers. The gate has to catch it by hand. *Evidence:* grep 'ForTest' finds 36 system files (e.g. ProgressService has 12 hooks); ServerScriptService/Server/Tests/T32_NpcLife.luau:59, :76, :98; ServerScriptService/Server/Systems/EventService.luau:646 (no IsStudio check) and :651-656 (the UFO in the same loop); versus HitService.luau:461 and ChaseService.luau:228 (with IsStudio) *Fix:* - One Shared/TestMode.active() (IsStudio AND attribute), used everywhere.
- A static test that fails if any system reads 'RunSelfTest' directly.
- Inject the clock and RNG instead of the clockForTest globals.
- `Tests/Lib.withHold(set, reset, fn)` always resets, through pcall.
- **[medium/high/M] Change-detector tests pin tuning numbers instead of checking what a newcomer actually experiences.** T55_QuietStart asserts number ranges (QUIET_START 20-45, FIRST_WOW_AT ≤ 60, Chase ≤ 110). Its header still says the quiet start is 'at least 90 s'. It is rewritten every time the design changes a number (90 -> 35), so it never catches a real regression, such as two pop-ups landing in the same second or the mission never showing on a portrait phone. T01_Config only checks that Version exists and the table is frozen. *Evidence:* ServerScriptService/Server/Tests/T55_QuietStart.luau:2 and :6 (header '90 s'), :28-37 (range asserts); T01_Config.luau:8-9; docs/AUDIT.md:52-91 (the timeline was measured by hand) *Fix:* Replace these with a timeline journey test:
- A fresh profile (StudioFresh) on a portrait 414x814 client runs 150 s, with a recorder hooked on FeelBus, Notify and HudSlots.
- It asserts the events and their order: objective at 0 s, first takedown possible by 10 s, HUD reveal, mission, wow, next cards.
- No two big pop-ups less than 15 s apart, and none over the thumb zone.
- The numbers themselves move to ConfigService, so a change does not touch the test.
- **[high/high/L] The client is almost untested and no test plays a real user journey, although the tools now exist.** 62 of 83 client modules are never referenced by any test. They include FirstVisit (the newcomer flow), TouchShoot (phone firing), MoveStick (walk vs shoot), ExperimentCard, HudV3, LabCamera and ToolCatalog. The server tests call HitService and the other systems directly, past the client, and LayoutCheck checks rectangles only. The docs say the MCP 'cannot press keys' and that 2-client runs cannot be started, which is no longer true:
- StudioTestService (Dec 2025) runs Play and multiplayer sessions with up to 8 clients from a plugin and returns a result;
- VirtualInput (UserInputService:CreateVirtualInput) clicks real buttons;
- the Studio MCP now has user_mouse_input, user_keyboard_input and character_navigation.

Most players are on portrait phones and leave at about 120 s, and that path has no automated coverage. *Evidence:* Module scan: client modules never named in Tests include AdminPanel, AmmoClient, ChaseHud, Crosshair, ExperimentCard, FirstVisit, HudV3, LabCamera, MoveStick, Notify, PokeController's fire path via TouchShoot, ToolCatalog, Viewmodel (62 of 83); docs/AUDIT.md:60 ('MCP cannot press keys'); docs/V7_PLAN.md:320 (2-client not startable); vault '12 Performance Testing and Debugging/UI Automation with VirtualInput and StudioTestService.md' section 1 *Fix:* Build a plugin runner on StudioTestService and five journey tests that run in the gate:
- J1: new portrait phone (414x814): tap dummy -> takedown within 10 s, HUD at 35 s, mission at 40 s, 0 errors, 0 LayoutCheck problems.
- J2: new PC player: click-fire, open WEAPONS, equip, fire the new weapon.
- J3: returning player: full HUD at once, saved bar.
- J4: 2-client Prank Party: grab, throw, combo on both screens.
- J5: 10-minute soak: instances and memory flat, 0 errors.

Client test code runs inside the client (avoids the separate module copies execute_luau gets).
- **[high/high/M] Config switch sprawl: 42 compile-time switches, 42 any-casts that hide typos, dead keys, and a contradicting SERVER_SIZE.** Config.luau mixes 42 booleans, about 100 tuning numbers and the change history in comments. Every A/B change (QUIET_START, FIRST_WOW_AT, NEXT_UNLOCKS_*) needs a republish and a server restart, so the first minute cannot be A/B-tested live.

42 `(Config :: any).X` casts in 13 files remove strict checking: a misspelt switch silently reads nil, so the feature is off.

UPDATE_TITLE and UPDATE_DAYS are never read. SERVER_SIZE = 6 is only 'documentation', while Lab.PLOT_COUNT = 10 ('server size should be 10') lays out and dresses 10 plots with 60 dummy slots at every boot. Two modules share the name 'Config' (Shared/Config and Shared/Ragdoll/Config). *Evidence:* ReplicatedStorage/ReplicatedStorage/Shared/Config.luau:4-244 (42 '= true|false' keys), :80 SERVER_SIZE, :102-103 UPDATE_TITLE/UPDATE_DAYS (0 references); casts e.g. EventService.luau:656, Playground.luau:298 and :1007, EventShop.luau:902 (42 in 13 files); ServerScriptService/Server/Systems/Lab.luau:76 and :1000-1012; vault '04 Data and Persistence/Global State and Live Config.md' (ConfigService section) *Fix:* Split Config into three layers:
- (1) Constants: physics and layout, in code.
- (2) LiveConfig: a wrapper over ConfigService with typed defaults and targeting (new vs returning, platform), so QUIET_START, FIRST_WOW_AT and the experiment/next-card timings can be A/B-tested without a republish, and kill switches work in about a minute.
- (3) Flags, each with an owner, an added date and an expiry.

Also:
- Remove the `:: any` casts.
- Derive PLOT_COUNT from SERVER_SIZE.
- Delete the unused keys.
- T01 fails on unread or expired keys.
- **[medium/low/M] Dead and superseded code is kept, loaded and tested behind switches that will never flip.** Off for good, or barred by the all-ages target:
- WORLD_V2: WorldDress (644 lines) and T81;
- BIRDS: Client/Birds, T104 and ReplicatedStorage.BirdModels, still started at boot;
- ZONE_FLOOR, TODAY_LIGHT, SPIKE_BLOCKS and VIEW_CARD;
- SEVERING and BLOOD 'purple': BloodFx (644 lines) and the VitalsService blood paths, which the kid-safe all-ages target rules out.

The false-branches of LOOK_V3, UI_V2 ('round 5 dark-glass look, unchanged'), BANNER_V7, ARENA_V2 and UI_CLEAN are still maintained, with 16+ if-branches such as DummyFactory.luau:29 and :292 and ZoneLighting.luau:55, :77 and :252. ProgressService still exposes validRadio for a radio removed on 10 Nov.

V6 and V7 added about 9k lines in a few hours with almost no deletions, so every fix has to be checked against code nobody runs. *Evidence:* Config.luau:15, :26, :129, :165, :177-178, :181; StarterPlayerScripts/StarterPlayerScripts/Client/Main.local.luau:58; git log --numstat for 9438ab3 (+950/-1), f3746e7 (+856/-2), 7716f36 (+986/-1), 233f9bc (+1282/-61); ProgressService public function 'validRadio' *Fix:* - Tag `pre-cleanup-0.25`, then delete WorldDress, Birds, the BloodFx/severing paths and the off branches of ZONE_FLOOR, TODAY_LIGHT, SPIKE_BLOCKS, VIEW_CARD, LOOK_V3, UI_V2, BANNER_V7 and ARENA_V2, with their tests and Config keys.
- Team rule: a switch that has held its final value for one release has its losing branch deleted in the next.
- Measure the deletion in lines.
- **[high/high/L] Two HUD stacks, and the biggest platform (portrait phones) runs the legacy one.** HudGate turns HudV3 (the 'big ragdoll games' HUD') on only when not on a phone. Phones, most of the players (414x814 portrait), keep the round 5 HUD: HudPlus, HudSlots, PokeController, NextUnlocks, ChaosMeter and HudMenu, about 4k lines with 'step aside' rules between the layers. Every UI fix has to be done and LayoutChecked twice. The phone path is also the one with the most special cases (portrait, PHONE_HUD_MAX7, QUIET_START phone holds) and the least test coverage. *Evidence:* StarterPlayerScripts/StarterPlayerScripts/Client/HudGate.luau:14-20 ('a phone keeps the round 5 HUD'); HudPlus.luau:40 and ChaosMeter.luau:21 (step-aside checks); EventShop.luau:342; CLAUDE.md v3 PC session (551 LayoutCheck problems, mostly phones) *Fix:* Rebuild one HUD component tree, phone-portrait first, with per-platform layout data in HudSlots. Move the phone onto it, then delete the round 5 stack. J1 and LayoutCheck guard it.
- **[medium/medium/L] God modules and weak typing around the save path.** ProgressService (1982 lines, 59 public functions) holds the profile load, merge, save and BindToClose path. The same file also holds goals, gifts, settings, hats, eggs, combos, prank prefs, free ULTRA days, the seen version and the economy, so every UI-driven tweak edits the module that can lose saves. Other files over 1,400 lines: PokeController 1874, CrowdService 1544, FxController 1504, ToyService 1497. The code also has 332 `:: any` casts and 31 in-function requires (cycle dodges). Each feature has its own DataStore (18 *_v1 stores) and its own retry and BindToClose code (10 handlers). *Evidence:* ServerScriptService/Server/Systems/ProgressService.luau (1982 lines; BindToClose :1902; start :1850); line counts from wc; grep ':: any' = 332; BindToClose in 10 files (EventService:730, LeaderboardService:594, LoadoutStore:212, OnboardingService:528, PlaytimeGifts:252, PortalService:366, ProgressService:1902, Purchases:521, SessionStats:263) *Fix:* - Extract ProfileStore: load, session-lock, merge, migrate, save and one BindToClose, plus a DataStore fake with failure injection and 100% pure specs.
- Features read and write through ProfileStore.
- Fold the small per-feature stores into profile fields where they are per-player.
- CI warns at more than 600 lines per module and more than 0 new `:: any` casts per change.
- **[medium/low/M] No CI, no lint or format config, and pure tests run only inside a 10-12 minute Studio Play.** There is no .github workflow, selene.toml, stylua.toml, .luaurc or rokit.toml. luau-lsp and selene were run once, by hand, in a cloud session. About 30 of 94 tests are pure and could run in lune in seconds on every push: T01, T53-T57, T61, T62, T64, T65, T80, T90, T95, T100, T107 and others. Instead they wait for a full Studio session: 92 tests with a combined timeout budget of 4407 s, run about once per phase. Errors the type checker would catch (the 42 Config casts, and nil keys) reach Studio, or live. *Evidence:* `ls -a` repo root (no .github, selene.toml, stylua.toml, .luaurc); CLAUDE.md release 0.20 note ('luau-lsp 1.53.1 analyze... No stylua/selene config in the repo'); pure test list (files without Players/Workspace); timeouts summed = 4407 s *Fix:* - Commit rokit.toml (rojo, selene, stylua, luau-lsp, lune), selene.toml (std=roblox) and .luaurc (strict).
- GitHub Actions on push: selene, then stylua --check, then luau-lsp analyze --definitions=roblox, then `lune run tests/pure`.
- Later: Open Cloud Luau Execution of the engine specs against the staging place version (one task per run, polled, JSON result).
- Protect `main`.
- **[medium/low/S] Branching and repo hygiene make bisecting and onboarding hard.** `main` has 1 commit. `release` is 135 commits ahead (about 31 hours of work) and never merged, so `main` is not what is live. Commits often carry several features (V6-7 map shop +950 lines minutes after V6-6), so a regression cannot be bisected to a feature.

Cloud sessions wrote whole phases 'never run in Studio' straight onto `release` (UI v2, World/Feel v2, v3), and the first Studio LayoutCheck then found 551 problems.

Stale and conflicting files:
- src/ (8 files);
- ReplicatedStorage/Shared/Config.luau ('Ragdoll Lab', 0.0.1), one folder away from the real sync root;
- StarterPlayerScripts/Client/Main.client.luau, a .client.luau that README itself warns runs twice there;
- README still says 'Ragdoll Lab';
- PLAN-2026-11-10-*.md, PROMPT-runde5.md and TEST-FASE0..3.md at the root.

MASTER_PROMPT names V4_PLAN.md 7 times while V7 is current. A merged comment fragment at Main.local.luau:110 shows copy-paste rot. *Evidence:* git rev-list --count main..release = 135, release..main = 0; git log 9438ab3 / 506371f timestamps; CLAUDE.md UI v2 / World/Feel v2 / v3 ('never run in Studio') and v3 PC session ('551 problems'); repo files src/, ReplicatedStorage/Shared/Config.luau, StarterPlayerScripts/Client/Main.client.luau, README.md:1; docs/MASTER_PROMPT.md (7 V4_PLAN references); StarterPlayerScripts/StarterPlayerScripts/Client/Main.local.luau:110 *Fix:* - Make `main` equal live: tag v0.25.0 and fast-forward `main`.
- Short feature branches: one feature plus its test per merge, and cloud work never merges before the PC gate on that branch.
- Delete src/, the stray Config, Log and Main.client files and the old root plans (move them to docs/archive).
- Update the README.
- Make MASTER_PROMPT read the current plan from one pointer file (docs/CURRENT_PLAN).

**Cut or hide:** Delete WORLD_V2 completely: Server/Systems/WorldDress.luau (644 lines), T81_WorldDress, and Config keys WORLD_V2, WORLD_V2_LAB_PARTS and WORLD_V2_LAB_LIGHTS (owner already judged it clutter).; Delete the birds: Client/Birds.luau, T104_Birds, ReplicatedStorage.BirdModels, Config BIRDS and BIRDS_MAX, and the start call at Client/Main.local.luau:58 (it still loads although BIRDS = false).; Delete the severing and purple-blood paths (BloodFx.luau 644 lines, the VitalsService blood code, SEVERING, BLOOD 'purple'). They are not allowed under the all-ages, kid-safe target, so they are dead weight and policy risk.; Delete the switches that are off for good, with their branches: ZONE_FLOOR, TODAY_LIGHT, SPIKE_BLOCKS and VIEW_CARD.; Delete the fallback looks nobody will return to: LOOK_V3=false (the 0.20 look), UI_V2=false (round 5 dark glass), BANNER_V7=false, ARENA_V2=false and UI_CLEAN=false branches (16+ if-branches across DummyFactory, ZoneLighting, Playground, EventShop, HitInfo, Viewmodel and NpcGlow).; Delete one of the two HUD stacks once the phone-first HUD is unified (HudGate's phone exception plus the round 5 HudPlus layering).; Delete repo leftovers: src/, ReplicatedStorage/Shared (stale Config 'Ragdoll Lab' 0.0.1 and Log), StarterPlayerScripts/Client/Main.client.luau. Move PLAN-2026-11-10-*.md, PROMPT-runde5.md and TEST-FASE0..3.md to docs/archive. Rewrite README.md.; Remove unread Config keys UPDATE_TITLE, UPDATE_DAYS and Phase, and turn SERVER_SIZE into the real source for Lab.PLOT_COUNT (now 10 plots built and dressed while servers hold 6).; Remove ProgressService.validRadio and the leftover Radio prefs handling (the radio was removed on 10 Nov).; Move T99_NetProbe (a measuring tool that 'passes' by skipping) out of Tests into tools/.; Remove the number-pinning asserts in T55_QuietStart (and its stale '90 s' header) once the timeline journey test replaces them.; Do not load owner-only client modules (AdminPanel, AdminWorld, Director, Spectate) for every player at boot: require them only when the player attribute IsOwner is set (less boot work and smaller attack surface on phones).; Schedule removal: LaunchGift (ends 10 Dec 2026) and its DataStore read on every join.; Measure, then cut or hide behind MENU if under 5% of sessions use them: workshop build mode (BuildService, BuildStore, BuildController, CreatorUI and Shared/Build, about 4.2k lines), the doctor monitor (HospitalCharts, 1.3k lines, default off), the weekly ADMIN SHOW / ScheduleService and the Horde every 10 minutes. Add a Session_v1 'used' flag for each first.

### P-safety-policy: kid-safe text, mild violence, free-form text, TikTok LIVE, admin tools, maturity questionnaire / all-ages reach: 3/10
Some foundations are solid. BLOOD is off, SEVERING is off, and there is no free-form text: the code boxes only accept a fixed alphabet. The admin tools are checked on the server and only take fixed choices. Streamer Mode only works in a private server, and its gifts never count (NoCredit). The favourite prompt gives no reward. Friend pranks have an opt-out. The real game behind the Config switches is a different story. On the first frame a realistic G17 is in your hand, and it fires real gunshot recordings. The targets are people who put their hands up and plead ("Not the face!", "Put it down, please!"). The crowd's panic spreads person to person with screams, and bodies limp or crawl on broken legs. Hits make a bullet-into-flesh sound and leave purple bullet holes on the body even with BLOOD off. The hit line reads "no pulse / DEAD", dead bodies turn green and lie for 60 s, and any player can press L for an organ-by-organ wound monitor. The weapon catalog promises limbs flying (Axe, Katana, Chainsaw, Cleaver), and T57 does not catch it. Against Roblox's 2026 questionnaire, every answer points the same way: humans as targets, a realistic world, a realistic style, realistic reactions. That honestly rates Moderate. The game is listed "Minimal", which is a moderation discrepancy waiting to happen. It is also "Ages 16+", which looks like the Kids/Select trial gate plus built-in media sharing (clip share, global build codes); nothing documents or handles either. There is no PolicyService anywhere, and TikTok appears in a menu every child sees. The game also has paid random items: VIP's faster eggs, and the fallback that pays 2 eggs for a Robux weapon. The owner's questionnaire guide (TEST-ALT.md:114-121) says there are none, and also that "nobody gets hurt". The last audit gave this area 8/10; the evidence does not support that.

**10/10 means:** One written content charter, enforced by code and tests:
- **Label.** An honest Mild label, eligible for Roblox Kids (5-8) and Select (9-15). The owner is age-checked and ID-verified, has 2-Step Verification, and pays Plus/Premium or the refundable fee. Manage Audience shows all ages. IARC ratings are assigned before 26 Jan 2027.
- **Targets and reactions.** Every target is clearly a robot or crash-test dummy, never human civilians. Reactions are unrealistic: stars, BOING, dizzy, pop back up. There is no death, pulse, organ or bone-break language, no corpses, no hands-up pleading, no crawling.
- **Weapons.** They read as toys: bright colours, foam, goo or paint, cartoon pop sounds. The first item is a toy popper.
- **Player-facing text.** Every string passes a banned-word scan in a test (kill, dead, blood, limb, butcher, nuke, TikTok...).
- **No media sharing** that forces 16+. If a share feature exists, PolicyService IsContentSharingAllowed gates it.
- **PolicyService on the server, fail-closed:** ArePaidRandomItemsRestricted, IsContentSharingAllowed and AllowedExternalLinkReferences.
- **No paid random items at all.** Fixed rewards only, so "No" is a true answer.
- **Streamer tools** are visible only to the owner or a private-server owner, with no third-party brand names.
- **Admin pranks** reach only players who opted in, there is a notice when the owner spectates, and an audit log is kept for 30 days.
- **Plaza:** a grab opt-out, and players who blocked each other are never paired.
- **Data:** an RTBF erase script that covers every DataStore.
- **Store page, thumbnails and What's New** match the build exactly.
- **Owner's Danish answer sheet:** a question-by-question answer sheet in TEST-ALT, each answer backed by code evidence, re-checked by the release gate on every publish.

This is how Fling Things and People (Mild, 25-player servers) and Bloody Ragdoll Physics (Mild after it toned down its blood) stay in front of young audiences. The Moderate leaders (Hyper Realistic Ragdoll, Ragdoll Research) chose realism and answered it honestly.

- **[critical/high/S] Listed 'Minimal' but the content honestly rates Moderate: a moderation discrepancy.** The 2026 violence questionnaire asks who is targeted, where, in what style, how characters react and how violence is shown. This build answers: humans (a crowd with real Roblox clothes and hair, Soldier/Worker/Farmer roles); a realistic world (Downtown, Army Base, Farm, Building Site); a realistic style (realistic lighting, real gun meshes and real gunshot recordings); realistic reactions (limping, crawling on broken legs, pulse, 'DEAD', green bodies lying 60 s); shown often and close up (first-person mode). That is Moderate, not the 'Minimal' that CLAUDE.md records. Roblox moderation reviews answers. A discrepancy brings a label replacement, possible moderation of the game, and slower Kids/Select selection. *Evidence:* CLAUDE.md:136 and docs/RESEARCH_V4.md:15 ('Minimal, Ages 16+'); CrowdService.luau:8-13, 26, 163-218; ActiveRagdoll.luau:14-16; VitalsService.luau:65, 528, 626-641; SoundManifest.luau:166-216; Roblox content-ratings page (violence questions: targets, world, art style, reaction, how shown) *Fix:* Pick a target this week. (A) Mild: do findings 3-9, then re-answer. (B) If the owner wants real guns: re-answer Moderate honestly now. That keeps Select (9-15) and 16+, and drops only Kids (5-8). Never leave 'Minimal' on this build.
- **[critical/high/S] The game is likely stuck in the 16+ trial: Kids/Select requirements are not met or documented.** Under Roblox's Kids & Select rules, a game stays available only to age-checked 16+ users until two things are true. First, the creator is age-checked, ID-verified (18+), has 2-Step Verification, and pays either Roblox Plus/Premium (at least 2 months old) or a refundable per-game fee. Second, the game reaches 100 unique plays from 'highly engaged' age-checked 16+ players within 60 days. 'Ages 16+' on the listing matches this gate. No doc tells the owner any of it; the release checklist only says 'questionnaire, target all ages'. Most Roblox players are under 16, and the fresh data says most players are on upright phones (a young-audience profile). So this gate may be cutting the reachable audience more than anything else in the game. *Evidence:* create.roblox.com/docs/production/publishing/kids-and-select (read 20 Nov 2026); docs/RELEASE.md:73; TEST-ALT.md:114-121 (no mention of Kids/Select, 2SV, ID, Plus or the fee); vault 'Policy and Age Rules 2026' section 2 *Fix:* Owner checklist (Danish), in this order:
1. Creator Hub > Ragdoll Havoc > Publish Settings > Manage Audience: read the status.
2. Turn on 2-Step Verification and ID-verify the creator account.
3. Pay Plus/Premium or the refundable per-game fee.
4. Publish for all ages.
5. Track progress toward the 100 engaged plays.
Also add IARC to the checklist: Kids/Select games without IARC ratings by 26 Jan 2027 may leave the Australian catalog. Put all of this in RELEASE.md as a gate.
- **[high/high/M] Built-in media sharing forces 16+, and IsContentSharingAllowed is never checked.** Roblox: 'Games that allow media sharing are only available to players that are at least 16 years old.' Media includes video, images, text and 3D models shared from gameplay through tools built into the game. Three features count, or likely count. CreatorUI's RECORD A CLIP / SCREENSHOT open PromptShareCapture ('share it with an invite'). ReplayController's CLIP IT records a video. BuildStore publishes every build under a global 6-character code that anyone can load (a shared 3D creation). None of these is gated by PolicyService IsContentSharingAllowed, which is the questionnaire's second media-sharing question. *Evidence:* CreatorUI.luau:121-132 (PromptSaveCapturesToGallery + PromptShareCapture), 166-188; ReplayController.luau:289-291; BuildStore.luau:9-12, 247-283 (Shares_v1, global code); grep: no PolicyService in the repo *Fix:* To keep all ages:
- Drop PromptShareCapture and keep save-to-gallery only, or call it only when IsContentSharingAllowed is true. Ask the owner to confirm in the questionnaire whether platform captures count.
- Replace global build codes with 'send my build to a friend in this server' (a FriendsService friendship check, no stored public code). Expire the Shares_v1 codes.
- Answer the media-sharing question 'No' only after this ships.
- **[high/medium/M] PolicyService is not used anywhere: no paid-random, content-sharing or external-link gating.** The 2026 compliance rules expect three server-side checks: ArePaidRandomItemsRestricted (hide or block paid random items), IsContentSharingAllowed (captures and shares), and AllowedExternalLinkReferences (references to off-platform brands such as TikTok). The game has paid random exposure (finding 5), sharing (finding 3) and TikTok references (finding 12), and checks none of them. *Evidence:* grep 'PolicyService|IsContentSharingAllowed|ArePaidRandomItemsRestricted|AllowedExternalLinkReferences' over ServerScriptService/ReplicatedStorage/StarterPlayerScripts: 0 hits *Fix:* Add Server/Systems/Policy.luau. It reads GetPolicyInfoForPlayerAsync with 3 retries and fails closed. It sets the player attributes PolicyRandomRestricted, PolicyShareOK and PolicyLinks, which the UI reads. Gate OfferService/MoneyService/RewardsService, the CreatorUI share and Streamer sections, and the build share on them. Add test T-Policy with a stub.
- **[high/low/S] Paid random items exist, but the owner's guide says 'no'.** Three Robux paths lead to random weapon eggs, with no odds shown:
- The VIP pass (149 R$) sells 'Eggs come faster': an egg every 50 takedowns instead of 75. That is an enhanced drop rate on a random item.
- A Robux weapon purchase pays '2 eggs' when no locked weapon is left at that price.
- STARTER_PACK sells '3 weapon eggs + the Revolver'. Its id is 0, but it is one paste away from going live.
TEST-ALT tells the owner to answer 'Hasardspil / betalte tilfældige ting: nej'. *Evidence:* Shop.luau:24, 37 (VIP perk), 52-55 (STARTER_PACK_TEXT); MoneyService.luau:8, 318-320 (eggEvery); ProgressService.luau:1156-1160 + WeaponShop.luau:71-72 (fallback eggs); TEST-ALT.md:119 *Fix:* Make every Robux reward fixed:
- VIP perk becomes '+25% BOLTS' or a cosmetic, with no egg rate.
- The weapon fallback pays a fixed BOLTS amount at the Robux value.
- The Starter Pack becomes '300 BOLTS + Revolver + Rattler'.
Add an assert in T68 that no Offers/Shop entry mentions eggs. Fix the line in TEST-ALT.
- **[high/low/S] Purple bullet holes and 'flesh' impact sounds on bodies even with BLOOD = off.** Every gun round that hits a dummy calls BulletHoles.body unconditionally. It welds a dark-purple wound disc (Anatomy.BLOOD_DARK) onto the limb, up to 8 per body, kept until the body is patched up. It also plays the 'flesh' bank ('bullet-body-hit1', 'flesh_impact_bullet1-3'). These are persistent wound marks and realistic injury audio. Both contradict HitFxConfig 'Stylised' and the store line 'Cartoon effects only: stars and sparks, no blood'. T57 only checks blood particles. *Evidence:* FxController.luau:910-917; BulletHoles.luau:2-5, 27, 195-250; Anatomy.luau:461; SoundManifest.luau:210-216; STORE_TEXT.md v4 last line; T57_MildContent.luau:23-27 *Fix:* In FxController.roundInBody: when BloodFx.enabled() is false, skip BulletHoles.body and play the cartoon 'hit'/'bonk' bank instead of 'flesh'. Delete the flesh bank from the Mild build. Extend T57: a round into a dummy with BLOOD off leaves 0 BulletHole parts.
- **[high/medium/M] Death and injury simulation on every hit (no pulse, DEAD, corpses, bones cracking).** Even with MILD_TEXT on, the server's hit line is '<region> · N% blood · no pulse / pulse N'. HitInfo shows 'N% health · no pulse · DEAD' in red. A headshot kills at once. Dead bodies turn green and lie still for DEAD_HOLD 60 s. X-ray replay draws neon bones with 'CRACK!' / 'MEGA CRACK!', and the progression book is the 'BONE JOURNAL'. These are realistic reactions in the questionnaire's terms ('characters reacting to pain, realistic wounds'), not 'poof into smoke'. *Evidence:* VitalsService.luau:65, 484-509, 528, 626-641; HitInfo.luau:59, 86-106; ReplayController.luau:46-81; ShareCode.luau:70; Shop.luau:115 (BONE JOURNAL) *Fix:* Mild vocabulary:
- The hit line becomes 'BONK! Head' + 'DIZZY ★★★' or 'KO!' + 'back in 10 s'.
- No pulse, no %, no DEAD tag.
- The KO look is cartoon stars over the head instead of the green corpse colour; the body pops back up after REVIVE_AFTER.
- X-ray becomes 'CRASH CAM' with sensor dots, not bones; words become 'BOOM!'/'MEGA FLIGHT!'.
- BONE JOURNAL becomes 'CRASH LOG'.
The sim can stay internal. Only what the player sees changes.
- **[high/low/S] Every player can open Doctor mode and the Dead monitor (organ wounds, flatline).** Any player can press L (Doctor mode) or turn on Settings 'Dead monitor', which reads 'Show a dead body's monitor when you point at it'. This shows an ECG that fibrillates and then goes flat with an alarm, a body map with red 'still bleeding' wounds, and an injury list naming organs ('Heart bruise 3s', aorta, liver). The questionnaire must be answered for the most extreme content reachable, and this is the most extreme part of the game. *Evidence:* Keybinds.luau:39; HospitalCharts.luau:6-25, 136-155, 260; Settings.luau:189-200; Config.luau:38-40 (MILD_TEXT explicitly keeps doctor mode) *Fix:* Cut it from the shipped build (a Config switch that removes the keybind, the setting row and the module start). If the owner wants a toy version, make a 'DIZZY METER': stars 0-3 and a 'back up in' timer, with no organs, ECG, flatline or bleeding.
- **[critical/medium/L] Humans who surrender, plead, scream and crawl when you aim a gun at them.** Pointing a raised gun makes every non-Brave dummy put its hands up with a scared face. It then says FEAR lines such as 'Not the face!', 'Put it down, please!', 'Can we talk about this?', 'Is that thing loaded?'. Crowd panic spreads person to person by screams, and cowards 'scream furthest'. With both legs broken a body 'drags itself along on its arms'. This all happens to clothed human NPCs on a plaza or in a city: an execution / mass-panic picture. Parents and moderators flag exactly this, and it is the opposite of 'kid-safe'. The previous audit even lists 'hands up' as a first-minute positive. *Evidence:* DummyLines.luau:4, 11-22; DummyLife.luau:605, 679-700, 870-884; GunThreat.luau:1-12, 22-23; CrowdService.luau:8-13, 26, 103, 125-131, 963-968; ActiveRagdoll.luau:14-16; docs/AUDIT.md first-minute note 'the dummies react (hands up)' *Fix:* Keep the comedy, drop the menace:
- No hands-up surrender at guns. Dummies taunt and dodge ('Missed me!', 'Bring it!', 'I'm rubber!'), as FTAP and Bloody Ragdoll Physics do.
- Remove scream propagation; use a comic 'WAAH' boing on launch only.
- Remove the crawling and limping states.
- Make plaza and map NPCs crash-test robots: suits, visors, no real clothes or hair.
Re-test the first-minute fun on a phone afterwards.
- **[high/medium/L] Realistic firearms are the core verb: a real handgun at second 0, real gunshot recordings, 9 of 20 guns still real names.** The G17 is in the hand from the first second. Each gun plays a real recording on purpose: 'Glock 9mm Shot Close', M9K Ak47/Hk416/M249/TEC-9/M14/M134 uploads. CLAUDE.md records the owner's wish that guns 'must sound like real guns, not airsoft'. They are realistic mesh models with reload and first person. TOY_NAMES renames only 11 ids. Revolver, Sniper, Minigun, Shotgun, Double Barrel, Auto Shotgun, Flare Gun, Laser Rifle and Railgun keep real names, and so do C4, Grenade and Nuke. Blurbs include 'Spray and pray' and 'One shot from across the lab'. The store page calls them 'blasters'. This is the single biggest driver toward Moderate. *Evidence:* Toys.luau:111-123 (TOY_NAMES list), 193-195, 259-283; SoundManifest.luau:166-208; Config.luau:35-37; CLAUDE.md 10 Nov 'must sound like real guns' *Fix:* For the Mild route:
- Starter = 'Popper', a foam-dart blaster with a cartoon pop and an orange tip.
- Every gun gets a toy finish (bright colours, orange muzzle), paint/goo/foam projectiles and a cartoon sound set: a punchy 'thwump' with no room tail.
- Rename the rest: Sniper becomes Long Popper, Minigun becomes Whirl Blaster, C4 becomes Sticky Boom, Nuke becomes Mega Boom.
This contradicts the owner's 10 Nov choice ('must sound like real guns'), so the owner must decide.
- **[high/low/S] Weapon cards promise dismemberment while SEVERING is off, and T57 does not catch it.** Current blurbs:
- Axe: 'Chop. It can take a limb off'
- Cleaver: 'A butcher's blade. Quick and nasty'
- Katana: 'One clean cut. Limbs fly'
- Chainsaw: 'BRRRRR. Nothing stays attached'
- Heal: 'Mends broken limbs'
- Nuke: 'The end of the lab. Run.'
- SMG: 'Spray and pray'
Roblox names dismemberment as a Restricted-level example, so the text alone is a red flag. It is also false advertising, because severing is off. T57 only rejects the words 'blood', 'limbs off' and 'tears', so 'a limb off' and 'Limbs fly' pass. *Evidence:* Toys.luau:227, 251, 252, 254, 255, 265, 272; T57_MildContent.luau:47-50 *Fix:* Rewrite the blurbs:
- Axe: 'Thwack! Spins them round'
- Cleaver: cut, or reskin as a Rubber Chicken
- Katana: 'Swish. Sends them sailing'
- Chainsaw: reskin as a 'Leaf Blower'
- Heal: 'Patches them up'
Give T57 a banned-word list (limb, attached, butcher, kill, dead, blood, gore, spray and pray, nuke, corpse) and run it over the Toys blurbs, DummyLines, Experiments, Shop.WHATS_NEW[1], AdminTools.ANNOUNCE and Notify texts.
- **[high/low/S] TikTok and Streamer Mode in a menu every child sees.** MENU 'CLIPS & LIVE' opens the Creator window for everyone. It reads 'Make clips for TikTok, or go live with Streamer Mode' and has a section 'STREAMER MODE (TIKTOK LIVE)'. It lists TikTok's own gift names, including 'TikTok' itself and high-value gifts like 'Universe' and 'Lion'. It tells the player to 'make one [private server] on the game's page'. That breaks the owner's no-brands rule. It is an off-platform reference that AllowedExternalLinkReferences never checks. It nudges minors toward TikTok LIVE gifting, which is 18+ on TikTok. The EventService 'TikTok' source and its 'A gift from' banner are dead code. *Evidence:* HudMenu.luau:29; CreatorUI.luau:9-12, 40, 88-93, 479, 504-505; EventService.luau:45; EventShop.luau:849, 989-991 *Fix:* Show the Streamer section only when the server says mayStream (the owner, or the owner of the private server they are in) AND the policy allows external links. Rename it 'Stream keys' with gift slots 'Gift 1-8'; no third-party names anywhere. Keep RECORD A CLIP and SCREENSHOT as local save only. Delete the 'TikTok' Source and banner branches.
- **[medium/low/S] Like-goal codes: 'At N likes: a new code here!' ties a reward to likes.** The EXPERIMENTS window shows 'At 100 likes: a new code here!' and 'CODE X (N likes!)', which pay 100/200/400 BOLTS. This breaks the owner's own rule ('never reward likes'). DevForum opinion is split on whether like goals break the rules. For a Kids/Select safety review it reads as a ratings incentive. *Evidence:* ExperimentCard.luau:300-310; Config.luau:69-73 (LIKE_CODES); vault 'Policy and Age Rules 2026'; DevForum threads 4495969 and 2926286 *Fix:* Re-key the codes to updates and events ('UPDATE26', 'XMAS'), announced in What's New. Never show like counts next to a code. Keep LikePrompt as is: a favourite ask with no reward.
- **[medium/low/S] 'Kills' in the progression UI.** The rest of the game says 'takedowns', but the WEAPONS catalog shows '(43/100) Kills', 'Locked: earn kills, BUY, or TRY FREE', 'Earn the X with kills'. The big WEAPONS button says 'N kills to go!'. The weapons window and the always-on HUD button are the two most-read strings in the game. *Evidence:* ToolCatalog.luau:4, 114-116, 287, 752, 957; HudPlus.luau:207 *Fix:* Use 'KOs' (or 'takedowns') everywhere: '(43/100) KOs', '3 KOs to go!'. Add 'kill' to the T57 banned-word scan.
- **[medium/medium/M] Owner troll menu acts on strangers with no consent, cap or notice.** The owner can RAGDOLL, FLING, FREEZE, TINY, GIANT, SPIN, SKY LAUNCH, DUMMY RAIN, NPC CHASE or PRESENT any player in the server. The only limit is a 4 s cooldown per action per target, so ten different actions can chain on one child. There is no opt-out, unlike friend pranks, which honour 'Friends can prank me'. SPECTATE silently shows the owner a private lab. BRING teleports a stranger to the owner. The Director (made for filming TikToks) does not hide other players' name tags. The logs go only to server output, so after a parent's report there is no record. *Evidence:* AdminService.luau:48-60, 94-260, 307-347, 427-461, 463-525; AdminTools.luau:145-176; FriendsService.luau:4-10 + FriendsUI.luau:253 (friend opt-out exists); Spectate.luau:3, 153; Director.luau (no name hiding) *Fix:* - Troll actions only on players with Settings 'Owner pranks: on', or inside the owner's own lab or party.
- Cap trolls at 3 per target per minute.
- Show a small 'The owner is watching' pill to a spectated player.
- Director 'privacy' toggle, on by default, that hides other players' DisplayName and VIP tags.
- Keep an AdminLog_v1 DataStore of kicks and trolls for 30 days.
- **[medium/medium/M] In the plaza any stranger can grab, throw and shoot anyone, with no opt-out and no blocks respected.** Zones.mayGrab returns true for any two players in the plaza. A stranger can grab the same victim again every 8-10 s indefinitely (VICTIM_GAP 8, PAIR_GAP 10). Plaza hits and blasts reach every player. Nothing checks blocked users. Kids/Select selection runs a live 'safety review' of moderation reports, so griefing reports from the plaza can stall it. *Evidence:* Zones.luau:90-93; PlayerGrab.luau:19-45; FriendsService.luau:12-14 ('Players reach each other ... in the plaza ... no PvP switch') *Fix:* - Add a Settings toggle 'Others can grab me in the plaza' (on by default, offered after the first grab).
- Never pair players where either has blocked the other: the client sends GetBlockedUserIds, the server intersects it.
- Show the victim a one-tap 'NO GRABS' chip for 5 minutes after being thrown.
- **[medium/medium/S] Store art, store text and What's New don't match the build (gun in car, 'drive into the crowd', birds).** - Thumbnail v4 'thumb4_car' shows the avatar holding a black pistol at a car window: a drive-by look, on a page that says 'Cartoon effects only'.
- Store description v3 (and the 0.21 What's New) says 'Drive the car or the monster truck into the crowd', which evokes a vehicle-ramming attack.
- The live 0.25.0 What's New, which every player sees once, promises 'BIRDS that really fly', yet Config.BIRDS = false.
- 0.24 calls the lab 'your own private place', wording that invites the questionnaire's 'private spaces' classification. *Evidence:* art/store/v4/thumb4_car.png; STORE_TEXT.md:54; Shop.luau:62-66 (0.25 entry), 71, 102; Config.luau:165 *Fix:* - Replace thumb4 with a weapon-free capture: the car knocking robot dummies, or the cannon arc.
- Delete the v3 description and the 'into the crowd' lines.
- Edit the 0.25.0 entry to drop the birds line (T66 still passes).
- Say 'your own lab' instead of 'private place'.
- Rule for every store asset: no guns in store art.
- **[medium/low/M] Arena minigames are 'shoot the people' (Squid Game guard premise).** RED LIGHT, GREEN LIGHT makes the player 'the guard' who must 'knock down the ones that move on red'. That is the Squid Game premise, a 16+ show's elimination game and an IP-adjacent reference. SHOOT 'EM is a gallery of 'people stroll across the arena; knock them down'. Both put realistic guns against human figures in a scored loop. *Evidence:* MinigameService.luau:3-10, 36-40; Shop history 0.11.0 'Red Light, Green Light and Shoot 'em' *Fix:* - Rename and reskin: 'ROBOT FREEZE' (robots tip over with a BOING when caught moving) and 'POP-UP DUMMIES' (cardboard crash-dummy targets on rails, foam popper).
- Remove the guard role wording.
- **[high/high/S] The owner's questionnaire answer guide is wrong and incomplete.** TEST-ALT asks the owner to answer:
- violence 'mild ... nobody gets hurt', but bodies die, show 'DEAD', break bones and crawl;
- paid random items 'no', but see finding 5.
It never covers:
- media sharing (clips, build codes);
- the six violence sub-questions (who / where / art style / reaction / how shown / how known);
- fear (the dark mossy spider corner, creatures that swallow bodies);
- AI interaction (No);
- gambling (No);
- Kids/Select creator requirements and IARC.
One wrong answer here costs more than any feature. *Evidence:* TEST-ALT.md:114-121; STORE_TEXT.md:130-133; docs/RELEASE.md:73 *Fix:* Rewrite it as a Danish answer sheet in TEST-ALT: one row per questionnaire question, with the answer, the code evidence (file:line) and the Config switch that would change it. Make the release gate in RELEASE.md block publishing when any row is marked 'changed since last answer'.
- **[low/low/S] Nuke and C4 as named real-world weapons, with a mushroom cloud and a 'nuke your friends' button.** The Nuke drops a bomb and grows a glowing mushroom cloud ('the end of the lab'). It has its own badge and a FRIENDS button that drops a nuke on a friend. C4 and Grenade keep their real names. Mass-destruction iconography is not a label-breaker on its own, but it piles onto the realistic-weapon picture and reads badly to parents. *Evidence:* ToyService.luau:661-697; Toys.luau:259-260, 265; FriendsService.luau:4-10, 40; BadgeAwards (Nuke) *Fix:* - Rename Nuke to 'MEGA BOOM' with a confetti and smoke cloud, no mushroom stem.
- Rename C4 to 'Sticky Boom' and Grenade to 'Pop Grenade'.
- The FRIENDS button becomes 'MEGA BOOM'.
- Keep the spectacle and the badge (renamed).
- **[medium/low/M] No right-to-be-forgotten (RTBF) tool across ~15 user-keyed DataStores.** Roblox forwards RTBF requests, and creators must erase the user's data. Data is spread across about 15 stores:
- Profile_v1;
- Session_v1, with many keys per user (userId_jointime);
- Builds_v1;
- Shares_v1 (records 'by' userId);
- Trials_v1, PlaytimeGifts_v1, LaunchGift_v1, GroupGift_v1, Orders_v1;
- the Loadout, Onboarding and Christmas stores;
- the ordered leaderboards.
There is no script to find and delete them. *Evidence:* SessionStats.luau:24; BuildStore.luau:4-12, 354; ProgressService.luau:63, 1853-1859; LeaderboardService.luau:37-40, 561; tools/ (no erase script); vault 'Player Privacy and Data Deletion' *Fix:* Add tools/EraseUser.luau. It runs in Studio with API access and takes a userId. It calls RemoveAsync on every store key, uses ListKeysAsync with prefix '<id>_' for Session_v1, removes Shares_v1 entries 'by' that user, and removes leaderboard entries. Add a RELEASE.md section 'RTBF: done within 30 days'.
- **[low/low/S] Replay share codes can spell words (vowels in the alphabet).** The X-ray SHARE CODE alphabet includes the vowels A, E, U and Y, so generated codes can spell rude words. Build codes deliberately use 'consonants and digits only, so they never spell words'. The two systems disagree. *Evidence:* ShareCode.luau:9; BuildStore.luau:9-11 *Fix:* Switch the replay code alphabet to consonants plus digits. Bump a version letter so old codes fail cleanly, and update T61.

**Cut or hide:** Doctor mode (L key), HospitalCharts and the Settings 'Dead monitor' row: cut from the shipped build; The 'no pulse / DEAD' hit line, the green dead-body colour and the 60 s corpse hold: replace with KO stars and a pop back up; Hands-up surrender and the FEAR plea lines when a gun points; crowd scream propagation; the crawling and limping states; Purple bullet holes on bodies and the 'flesh' impact sound bank; BloodFx, purple blood and the SEVERING code paths: remove them from the shipped build so the questionnaire's 'most extreme reachable content' is truly mild; Streamer Mode / TikTok section in CLIPS & LIVE for everyone except the owner and private-server owners; the 'TikTok' event source and its 'A gift from' banner (dead code); PromptShareCapture and the global build share codes (media sharing forces 16+); keep local save-to-gallery; The 'At N likes: a new code here!' line and the like-milestone code framing; VIP 'eggs come faster', the 2-egg fallback on Robux weapon purchases, and the egg Starter Pack text; Blade weapons used on people (Cleaver 'butcher's blade', Chainsaw, Katana/Axe dismemberment blurbs): reskin or cut; The Nuke mushroom cloud and the friend 'NUKE' button name; C4 as a name; The 'guard' framing of Red Light Green Light and the SHOOT 'EM people gallery; The owner troll menu on non-opted-in strangers; thumb4_car.png (gun in car), the v3 store line 'drive into the crowd', and the 0.25 What's New birds line; 'Kills' wording in WEAPONS and on the HUD button

## Research

### Competitor teardown: the top Roblox ragdoll and physics sandboxes (data read 20 Nov 2026) and what they share that Ragdoll Havoc lacks
- **(high)** Ragdoll Havoc is the only game in its genre that only age-checked players aged 16+ can play. Every competitor checked is open to all ages. This publishing tier, not the questionnaire, is the single biggest lever. The game's content label is already the mildest possible (Minimal). *Evidence:* Roblox age-recommendation API, 20 Nov 2026 (POST experience-guidelines-api/get-age-recommendation):
- Ragdoll Havoc (universe 10774775314) = 'Maturity: Minimal • Ages 16+', minimumAge 16.
- Every competitor has minimumAge 0: Hyper Realistic Ragdoll (HRR) Moderate, Ragdoll Research Moderate, Ragdoll Destruction Playground Moderate, Bloody Ragdoll Physics (BRP) Mild, Dummy Lab Mild, Animal Ragdoll Mild, Ragdoll Sandbox Mild, Ragdoll Wars Mild, Ragdoll Experiment Mild, Fling Things and People Mild, BloxNG Minimal.

Creator docs 'Roblox Kids and Select' (updated 2026-11-20):
- The 16+ tier 'releases only to age-checked Roblox users ages 16+'.
- Kids (5-8) and Select (9-15) need: an ID-verified owner, 2-Step Verification, and an evaluation (100 unique plays by 'highly engaged' age-checked users within 60 days).
- Kids also needs a refundable per-game fee, or Plus/Premium held for 2 months. A third-party guide puts the fee at 1,000 Robux.
- An optional expedited review costs 50,000 Robux.

Roblox newsroom, 5 Feb 2026: only 45% of daily users had age-checked. Of those, 35% are under 13, 38% are 13-17 and 27% are 18+.

Ragdoll Havoc was created on 5 Nov 2026, after the global rollout on 16 Jun 2026, so 16+ is its default. *For us:* Make this step 0 of the 10/10 plan, before any rebuild. It is an owner task on the Creator Dashboard:
1. Pass ID verification and turn on 2-Step Verification.
2. Get Plus/Premium or pay the per-game fee.
3. Publish to all ages; the label stays Minimal.
4. Reach 100 highly engaged plays: drive age-checked 16+ traffic with ads or friends, or pay for expedited review.

Rough estimate: today only about 15-20% of Roblox daily users (45% age-checked × the 16+ share) can see the game, and they are the least ragdoll-hungry group. The 2/10 numbers cannot be read as a verdict on the gameplay until this is fixed.

Update CLAUDE.md: the earlier 'redo the questionnaire' advice aims at the wrong control.
- **(medium)** Mid-November 2026 brought a moderation wave against blood-heavy ragdoll games. Kid-safe content is a durable advantage, not a handicap. *Evidence:* - HRR was reported removed around 15 Nov with 150k+ players online (X post by Valra; fan wiki says 'under review'). The games API shows it back: 85.8k playing, updated 19 Nov.
- Ragdoll Physics 🩸 (Rolimons): 72,476 peak 1 week ago, 2,318 now.
- BRP's own description: 'Blood effects have been reduced to comply with Roblox's content moderation guidelines'. Its 'Smoothie' badge (a blender machine) had 0 awards in the past day while every other badge earned thousands, so that machine looks removed.
- BRP hit its all-time peak of 62,907 about 4 days ago, while HRR was down, and is now 18.6k.
- 'untitled ragdoll game' has fallen out of the top 100 (livecounts).
- A YouTube video claims 4 ragdoll games were banned. *For us:* - Keep BLOOD off and SEVERING off for good, and say 'no blood, cartoon stars' on the store page (already there).
- Never chase 'hyper realistic' gore.
- When a leader goes down, its players spill into similar games. Recommendations only pick up games with good per-user numbers, so first-session quality decides who catches that wave.
- **(medium)** Leaders hold an average visit of roughly 12-18 minutes. Ragdoll Havoc's median is about 2 minutes, a 6-9x gap. *Evidence:* Little's law (average session = average players online ÷ visit rate), visit counters read twice about 7.9 min apart on 20 Nov (10:35 and 10:43 UTC):
- HRR ≈ 18 min
- Ragdoll Wars ≈ 18.5
- Ragdoll Destruction Playground ≈ 15
- Ragdoll Research ≈ 14.5
- BloxNG ≈ 13
- Animal Ragdoll ≈ 13
- Ragdoll Sandbox ≈ 12.6
- BRP ≈ 12.4
- Fling Things and People ≈ 12
- Dummy Lab ≈ 7

A 9-hour window (01:32 to 10:35 UTC, against the 20 Nov research snapshot) gives the same order: HRR 19-25 min, BRP 11-18, Fling 9-14.

Ragdoll Havoc on 0.24.0: median about 120 s, 1 of 11 visits past 4 min (Session_v1). *For us:* Set the plan's target as a mean session of 12+ min and median of 5+ min, measured in Session_v1. Moving HUD timing by seconds will not close a 6-9x gap. The levers are the loops below: progression, escalation, sandbox control and medic play.
- **(high)** Single-player first is the genre standard. Multiplayer is an opt-in step taken later. *Evidence:* Games API maxPlayers = 1 for HRR, BRP, Ragdoll Research, Ragdoll Destruction Playground, Ragdoll Sandbox, Ragdoll Wars, Animal Ragdoll, Gladiator Arena and Ragdoll Universe 🩸.

Multiplayer comes later, as a separate step:
- HRR's Update 1 (from 10 Nov) was headlined 'Multiplayer', with quick-join and a server list through a sub-place.
- BRP has a MULTIPLAYER portal.
- Ragdoll Destruction Playground says 'multiplayer planned'.

Shared-server games score lower on the estimate: Dummy Lab (6 players) about 7 min per visit, Fling (25 players) about 12, against 12-18 for the solo games.

Roblox's 'Recommended for You' does count 'intentional co-play days' (joins, invites, private servers) as a ranking signal (vault, 'Discovery and the Algorithm'). *For us:* Make the root place solo: SERVER_SIZE 1, own lab, no shared plaza on first join.
- Move the plaza and Prank Party behind a 'PLAY WITH FRIENDS' portal into a multiplayer place. PortalService already teleports to reserved servers.
- Keep friend invites, join-a-friend and party throws, so co-play days still count.

This also cuts phone load and griefing for first-time players.
- **(high)** Monetization in the leaders is a wide ladder of cheap impulse unlocks, consumable event charges and 'All X' passes up to an Everything pass. Ranking rewards spend days, so many small purchases beat one big one. *Evidence:* HRR developer products (API, 50+ items):
- Permanent per-tool unlocks: Bat 9, Bow 19, Defibrillator 29, Assault Rifle 59, Chainsaw 149, Energy Blade 299.
- 'All Tools 30 Min' rental: 39.
- Event charges at 15-39 each, in x3/x6 bundles (Black Hole 35 / 69 / 119).

HRR passes: All Throwables 69, All Medic 69, Lab Controls 69, All Melee 79, All Guns 99, All Powers 129, Double KO 129, VIP 199, Endless Events 299, Everything 699, and vehicles 249/399/549 kept outside Everything.

BRP:
- Per-weapon skips 19-39.
- Starter Pack 29, first session only.
- Events 20-35 (NUKE, DUMMY RAIN, BLACKHOLE, FIRE STORM, ZERO-G, FLASH FREEZE).
- Passes: Sandbox 99, VIP 199, Injections 199, Arsenal 249, Everything 499.

Others:
- Dummy Lab: 25 passes at 45-259.
- Animal Ragdoll: playable animals 99-599, skins 199-499, Starter 49, Ultimate 1999.
- Fling: only utility passes (reach 460, escape 240).

Vault: ranking uses spend days per user. *For us:* - Keep Weapon25/49/99/199 and the event products; they already mirror BRP's event list.
- Add a per-weapon skip at 9-39 Robux on each locked card.
- Add a 30-minute 'all weapons' rental at about 39.
- Add x3/x6 event bundles and an Endless Events pass (about 299).
- Add category passes (All Guns, All Explosives, All Doctor) at 69-129, and an Everything pass at 499-699.
- Show the Starter Pack (29-49) only in the first session.
- Fill in the many ids that are still 0 (Shop.OFFERS, STARTER_PACK, GROUP_ID); today most of the store is hidden live.
- **(high)** Leaders use badges as a hidden checklist of lab machines, plus takedown and streak ladders. The public badge counts show 40-60% of new players find each machine. *Evidence:* BRP badges, past day: Welcome 746,050, then:
- First Specimen 89%
- Pin Cushion (spike wall) 60%
- Pinned 57%
- Chain Reaction (barrels) 52%
- Hold Still 44%
- Blast Off (cannon) 36%
- Bounce Test 35%
- Swing Test 28%
- Run It Back (rewind) 27%
- Drop Test 15%
- Up Up and Away 8%

Ragdoll Sandbox: 10 dolls 6.92M, 50 dolls 3.66M, 100 dolls 2.26M, 1,000 dolls 223k. A '10 Streak' badge added on 14 Nov already earns 192k a day.

Ragdoll Research: First Kill 10.1M; 'The Door...' mystery 318k; a time-limited Halloween 2026 badge 2.33M.

Ragdoll Havoc has 5 live badges. *For us:* - Add one badge per machine (cannon, bullseye, spike wall, wrecking ball, trampoline, lava, stations, each creature, chimney).
- Add a takedown ladder (10/50/100/1,000) and a streak ladder (10/100).
- Add a mystery badge (a hidden room or entity) and a time-limited Christmas badge.

Badges are free funnel instruments and quiet goals. Order the experiment cards by the BRP discovery rates.
- **(medium)** Leaders' icons and thumbnails show a Roblox-native white dummy with a readable, meme-able face in one clear action. Ragdoll Havoc's art looks like a generic AI mobile ad and does not match the game. *Evidence:* Store images downloaded from the thumbnails API and viewed, 20 Nov:
- HRR icon and thumbnail: a white Roblox mannequin with the classic Roblox face, its head turned to an X-ray skull by a bat hit, on a green baseplate grid.
- Ragdoll Research: a Roblox head with the classic face under a hydraulic press.
- Dummy Lab: a Roblox head with a laughing face in front of a tornado, plus a logo.
- BRP: an in-engine white dummy blown out of an explosion.
- Animal Ragdoll's icon is currently an update countdown, '12 HOURS'.

Ragdoll Havoc: the icon is a cartoon crash-test dummy with non-Roblox proportions fired from a cannon. The thumbnail is a realistic blue sedan ploughing through about 20 cartoon crash-test dummies. Neither looks like Roblox or like the in-game dummies.

Vault: play-through rate is the most important ranking signal, and a broken promise raises first-play bounce. *For us:* Redo the icon and 3 thumbnails:
- the in-game white Roblox dummy, big readable face, one moment (cannon launch, X-ray crack, friend toss);
- matching the in-engine look;
- no realistic car.

A/B test them with Roblox's thumbnail experiments. Swap the icon to an update countdown the day before each drop.
- **(medium)** Ragdoll Havoc cannot be found in Roblox search, even by its own name, and the word 'Havoc' is taken by an older game. *Evidence:* Omni-search API (logged out), 20 Nov:
- 'ragdoll havoc': the top 80 results do not include universe 10774775314. Result 1 is 'Ragdoll Physics Havoc' (2020, 115,640 upvotes).
- '[EVENT] RAGDOLL HAVOC': not in the top 15.
- 'ragdoll': not in the top 40.

Ragdoll Havoc stats: 1,328 visits, 17 favourites, 5 up / 3 down votes, 0 playing.

Competitors put the genre noun first and add a twist or emoji ('Dummy Lab 🩸', 'Animal Ragdoll', 'Ragdoll Wars!'). *For us:* - Do not expect search traffic. Plan for recommendations, sponsored ads and short-video links.
- Drop the '[EVENT]' tag unless a real Roblox Event is running.
- Consider a distinct title with the genre noun and a clear twist (for example a 'Crash Test Lab' or 'Toss Your Friends' angle), owner's choice.
- Write the description in plain words for semantic search.
- **(medium)** Updates land almost every day and are announced through Roblox's own surfaces: Experience Events with RSVPs, an update-name first line in the description, and countdown icons. *Evidence:* Every competitor showed an 'updated' stamp of 19-20 Nov.
- HRR ran Update 1 as a Roblox Experience Event (from 10 Nov); allthings.how reported about 38,000 RSVPs.
- Animal Ragdoll's icon reads '12 HOURS'.
- Ragdoll Sandbox: 'MILITARY UPDATE' (36 vehicles, 13 weapons) with codes MILITARY/TANKS/JETS and 'next code at 25k likes'.
- Ragdoll Destruction Playground: 'NEW UPDATE'.
- Car Crushers 2 numbers its updates (Update 91).
- Ragdoll Experiment: 'SHUTDOWN = UPDATE'. *For us:* For every drop:
- create a Roblox Experience Event (RSVP notifications reach players who left);
- swap the icon to a countdown 24 h before;
- make the description's first line the update name.

Ship small, named, visible drops twice a week (UPDATE_DAYS) plus one big numbered update every 2-3 weeks. LIKE_CODES already matches the like-goal code pattern.
- **(medium)** This is a short trend window: brand-new ragdoll games are exploding now, while older destruction sandboxes fade. *Evidence:* - GGRecon (pulled 2 Nov): 12 of 127 new games since 1 Sep have 'ragdoll' in the title.
- Games API: HRR, BRP, Ragdoll Research, Ragdoll Destruction Playground, Ragdoll Sandbox, Dummy Lab and Animal Ragdoll were all created 16 Oct to 8 Nov 2026.
- HRR went from 0 to a 201k peak in about 2.5 weeks (RoWatcher).
- Animal Ragdoll (created 8 Nov): 282,151 new players in the past day (badges API).
- Car Crushers 2 (1.38B visits, 7.19M favourites): peak 13k on 13 Jun 2026, now about 940, -41% in 30 days (RoWatcher).
- Ragdoll Engine (212M visits): about 1k now.
- Fling survives a year without updates on social play alone (vault). *For us:* Speed beats breadth. Ship the 'new version' in weeks:
- all-ages audience;
- new store art;
- a solo first session;
- the progression and escalation loops below.

One strong twist should headline it, rather than 60+ features of equal weight.
- **(medium)** The crash-test-lab concept is proven to draw players: Dummy Lab is nearly the same game. Its short sessions show that depth decides retention, not the concept. *Evidence:* Dummy Lab (created 7 Nov):
- crash-test dummies, X-ray results, cannon, rocket sled, drop tower, wind tunnel, freezer, centrifuge, 70+ weapons;
- rank-ups unlock weapons, maps and rooms; up to 6 players;
- 4.68M visits, about 6.6k playing (peak 10k, RoWatcher), 77% likes;
- 25 passes at 45-259 Robux;
- estimated about 7 min per visit, the lowest of the set. *For us:* The concept is not the problem, but it is not unique either. Differentiate on:
- kid-safe comedy, open to all ages, which Dummy Lab (Mild, heavy unrealistic blood) cannot claim as cleanly;
- 'throw your friend' party play;
- daily experiments.

Invest in the long-session loops that Dummy Lab's short sessions suggest it lacks.
- **(medium)** The newer hits climb on an escalation or fantasy layer on top of the hitting: wanted levels, bosses, hordes, mutations and mysteries. *Evidence:* - Animal Ragdoll: play as 36 animals, each with a super move, growing bigger; destruction rebuilds; 'Animal Control' stars rise with chaos, and at 5 stars a truck with guards arrives. It runs about 13 min per visit.
- Ragdoll Sandbox: wanted stars and kill streaks, military vehicles.
- Ragdoll Gladiator Arena: rare bosses (Zeus, Hades), god powers.
- Ragdoll Universe 🩸: a Zombie Night horde mode.
- Ragdoll Research: mutations feed a journal; 'The Door...' entity.
- HRR: animals, zombies from a graveyard, dummies that answer speech and follow commands. *For us:* Tie the existing chase NPCs to the player's own chaos. A 'LAB ALARM' meter fills with takedowns and machine use; at 5 stars, Lab Security or a boss dummy arrives; beating it pays bolts and stars.

That gives each session an arc (calm, chaos, boss, reward), a strong clip moment, and costs little to build on ChaseService and ExperimentService.
- **(medium)** HRR sells a kid-friendly 'doctor' counter-loop (hurt, X-ray, heal, revive) as a whole product line. *Evidence:* - HRR description: 'view broken bones with X-ray, then heal or revive dummies'.
- Medic developer products: Bandage 9, Antidote 25, Defibrillator 29, Burn Gel 29, Blood Bag 35, Adrenaline 49; an All Medic pass at 69.
- Animal Ragdoll has a 'doctor mode for repairing dummies'.
- BRP has 14 syringes and an Injections pass at 199. *For us:* Promote Doctor mode (HospitalCharts, Heal, X-ray replay) to a first-class loop:
- doctor tools on the weapon ladder;
- 'patients healed' takedown-style goals and badges;
- an All Doctor pass.

It fits the all-ages pitch and gives calm players a reason to stay.
- **(medium)** 'Director mode' sandbox control is a paid, long-session feature in every leader. *Evidence:* - HRR 'Lab Controls' pass at 69: fly, time stop, spawn many dummies; G spawns dummies (guides call it the most important key).
- BRP Sandbox pass at 99: spawn anything, change the rules, slow time, rewind, set up NPC Wars teams.
- Ragdoll Destruction Playground: 'Slow motion UNLIMITED' at 199, map reset.
- [PHYSICS] Ragdoll Playground: G slow-mo, Space pause, 1.16M favourites. *For us:* After the first minutes, put a big SPAWN/LAB menu in front: place dummies in any number, place machines and props, slow-mo, rewind, team fights.
- Sell an advanced 'Lab Controls' tier (fly, unlimited spawns, time stop), but keep a free core.
- SandboxService and the build mode already exist; they need to be visible and fun on phones.
- **(medium)** Joining the group is the standard free reward, and favourites per new player differ about 10x depending on whether the game asks. Some rivals reward likes and favourites, which Ragdoll Havoc must not copy. *Evidence:* Group or favourite rewards:
- BRP: free weapons for group + favourite (fan wiki).
- Ragdoll Test Physics: free tentacles for group + favourite, daily coins x1.5 for group members.
- Car Crushers 2: extra cars for group + favourite.
- Ragdoll Engine: free Push/Potion/Speed Coil for the group.
- Troll Ragdoll Tower: 'like and favorite for in-game rewards'.

Favourites per new player (badges API, 20 Nov research): BRP 10.7%, HRR 0.9%. HRR still leads, so favourites are not the driver.

Ragdoll Havoc: 17 favourites from 1,328 visits; GROUP_ID is 0. *For us:* - Create the Roblox group now and switch on the existing group gift (Shop.GROUP_ID).
- Keep favourite and like asks reward-free (owner rule), shown only after a wow.
- Use group membership for update announcements.
- **(low)** Competitors' phone layouts are built around one big contextual action button in landscape. Ragdoll Havoc's players hold phones upright, a case no competitor was seen to design for. *Evidence:* Storyboards in docs/RESEARCH_FIRST_SESSION.md:
- BRP phone: big red FIRE (becomes PLACE), RAGDOLL, TAKE BACK, RELOAD with ammo count, a labelled 5-slot hotbar, a Starter Pack chip with a 15-minute timer.
- Ragdoll Destruction Playground: one button that turns Grab -> Swing -> Fire, plus Drop/Throw/Slow/Jump.

All observed phone frames were landscape. Ragdoll Havoc's Session_v1 shows most players on upright phones (414x814), and CLAUDE.md says the game is 'not forced to landscape'. *For us:* A/B test forcing landscape on phones (ScreenOrientation LandscapeSensor) against today's portrait HUD, measured by Session_v1 bounce under 60 s and 61-180 s.

In both orientations, use one big contextual button (SHOOT -> THROW -> PLACE) with at most 3 helpers.
- **(medium)** Synthesis: on paper Ragdoll Havoc matches the leaders feature for feature. What they share and it lacks is reach, a clear promise, a solo first session, visible goals and live-ops plumbing. *Evidence:* Shared by the top set (HRR, BRP, Ragdoll Research, Ragdoll Destruction Playground, Ragdoll Sandbox, Animal Ragdoll, Dummy Lab), and Ragdoll Havoc's status:
1. Open to all ages (minimumAge 0). Havoc: 16+.
2. Roblox-native dummy art with a readable face. Havoc: cartoon/AI-look store art.
3. Solo server by default. Havoc: 6 players.
4. Next-weapon ladder from the first seconds. Havoc: present.
5. Public machine and ladder badges. Havoc: 5 badges.
6. 9-39 Robux impulse unlocks plus event charges and an Everything pass. Havoc: many product ids are 0.
7. A group reward. Havoc: GROUP_ID 0.
8. Near-daily updates announced through Events, icons and description. Havoc: no Roblox Events.
9. An escalation or fantasy layer (wanted stars, bosses, hordes, mutations). Havoc: chase not tied to the player's chaos.
10. Visible sandbox/director control. Havoc: hidden behind menus.

Features Havoc already has, like the leaders: weapons, events, creatures, vehicles, X-ray replay, cannon and machines, daily rewards, experiments. *For us:* The 2-to-10 plan should order work by reach and promise first:
1. Publish to all ages.
2. New icon and thumbnails.
3. Solo root place with a friends portal.
4. Then session-length loops: alarm/boss escalation, machine badges, doctor loop, spawn/director menu.
5. Then the monetization ladder and live ops.

Adding more toys or machines is not the gap.

**Sources:**
- Roblox age-recommendation API (experience-guidelines-api/get-age-recommendation), read for Ragdoll Havoc and 12 competitors (https://apis.roblox.com/experience-guidelines-api/experience-guidelines/get-age-recommendation), 2026-11-20
- Roblox Creator Docs: Roblox Kids and Select (https://create.roblox.com/docs/production/publishing/kids-and-select.md), 2026-11-20 (page last updated)
- Roblox Creator Docs: Content maturity and compliance (https://create.roblox.com/docs/en-us/production/promotion/content-maturity.md), accessed 2026-11-20
- BloxBot: Roblox publishing requirements 2026 (https://bloxbot.ai/guide/roblox-new-publishing-requirements-2026), 2026 (accessed 2026-11-20)
- Roblox Newsroom: Moving beyond self-reported age (https://about.roblox.com/newsroom/2026/02/moving-beyond-self-reported-age), 2026-02-05
- Roblox games API (playing, visits, favourites, maxPlayers, created/updated, descriptions) (https://games.roblox.com/v1/games?universeIds=10773618503,10773926254,2668101271,10773425091,10774468211,10771155665,2007050448,10774775314,10775166914,10775306701,10771544071,10770604649,274816972), 2026-11-20 10:35 and 10:43 UTC
- Roblox omni-search API (ragdoll, ragdoll havoc, [EVENT] RAGDOLL HAVOC, dummies, car crushers 2, ragdoll simulator) (https://apis.roblox.com/search-api/omni-search?searchQuery=ragdoll%20havoc&sessionId=abc&pageType=all), 2026-11-20
- Roblox game-pass API (HRR, BRP, Fling, Ragdoll Research, Dummy Lab, Animal Ragdoll, Car Crushers 2, Ragdoll Engine) (https://apis.roblox.com/game-passes/v1/universes/10773618503/game-passes?passView=Full&pageSize=50), 2026-11-20
- Roblox developer-products API (HRR, BRP) (https://apis.roblox.com/developer-products/v2/universes/10773618503/developerproducts?limit=50), 2026-11-20
- Roblox badges API (BRP, Ragdoll Research, Ragdoll Sandbox, HRR, Animal Ragdoll, Dummy Lab) (https://badges.roblox.com/v1/universes/10773926254/badges?limit=100&sortOrder=Asc), 2026-11-20
- Roblox thumbnails API (icons and thumbnails, downloaded and viewed) (https://thumbnails.roblox.com/v1/games/icons?universeIds=10773618503,10773926254,10773425091,10774468211,10775166914,10775306701,2668101271,10774775314&size=256x256&format=Png), 2026-11-20
- Rolimons: Ragdoll Physics 🩸 and Bloody Ragdoll Physics (https://www.rolimons.com/game/121868512253414), accessed 2026-11-20
- RoWatcher pages: HRR, BRP, Ragdoll Engine, Car Crushers 2, Dummy Lab (https://rowatcher.com/games/274816972/titan-attack-car-crushers-2-physics-sim/dying), accessed 2026-11-20
- Hyper Realistic Ragdoll Wiki: Roblox Banned (fan site) (https://hyper-realistic-ragdoll.wiki/updates-and-availability/hyper-realistic-ragdoll-roblox-banned), 2026-11-15
- X post by Valra on the HRR deletion (https://x.com/ValraSwag/status/2122045577827381299), about 2026-11-15 (search snippet only)
- YouTube: Roblox BANNED 4 HUGE Ragdoll Games? (https://www.youtube.com/watch?v=MXvWIf3mkhM), Nov 2026 (title and search snippet only)
- allthings.how: Hyper Realistic Ragdoll Update 1 schedule (https://allthings.how/hyper-realistic-ragdoll-events-schedule/), about 2026-11-13
- Hyper Realistic Ragdoll multiplayer guide (fan site) (https://hyperrealisticragdollroblox.wiki/guides/multiplayer/), 2026-11-15
- GGRecon: The 10 fastest-growing new Roblox games (November 2026) (https://www.ggrecon.com/articles/fastest-growing-new-roblox-games-november-2026/), 2026-11-02 data pull
- LiveCounts: Most played Roblox games (November 2026) (https://livecounts.nl/roblox-charts/), 2026-11 (10:25 UTC snapshot)
- Bloody Ragdoll Physics Wiki (fan site) (https://bloodyragdollphysics-wiki.wiki/), 2026-11-13
- Hyper Realistic Ragdoll Wiki (fan site) (http://hyperrealisticragdoll.wiki/), 2026-11-14
- LihFolk vault: Teardown - Fling Things and People (C:\Users\tristan\LihFolk-Vault-V2\LihFolk Vault V2\59 Viral and Trend Game Teardowns\Teardown - Fling Things and People.md), 2026-10-29
- LihFolk vault: Discovery and the Algorithm (C:\Users\tristan\LihFolk-Vault-V2\LihFolk Vault V2\11 Monetization Publishing and Live Ops\Discovery and the Algorithm.md), as of 2026-10
- Repo: docs/RESEARCH_FIRST_SESSION.md (earlier storyboard teardown) (C:\Users\tristan\Documents\RagdollLab\docs\RESEARCH_FIRST_SESSION.md), 2026-11-20
- NamuWiki: Fling Things and People (https://en.namu.wiki/w/Fling%20Things%20and%20People), 2025-12-16

**Gaps:** - **Web search budget:** the session-wide search cap (200) ran out partway through. After that, only direct fetches of Roblox APIs, trackers and docs were possible. No further Reddit, TikTok or YouTube searching could be done.
- **Reddit:** none of the searches returned a Reddit thread, so there is no Reddit sentiment here.
- **TikTok:** only search snippets, with no reliable dates or view counts. The most-engaged ragdoll clip found had about 44k likes and no date.
- **YouTube:** watch pages returned no descriptions.
- **DevForum:** pages rendered empty (JavaScript), so the Kids/Select AMA and the algorithm post could not be read directly; the official create.roblox.com docs were used instead.
- **Session lengths are estimates.** They come from Little's law (average players online ÷ visit rate) over an approximately 7.9-minute window and a 9-hour window.
  - Visit counters may update in batches.
  - Teleports or sub-places can inflate visits.
  - These are means, not medians.
- **The claim 'BRP grew from about 2.5k to about 21k CCU after a maturity label change' could not be verified anywhere.**
  - BRP is labelled Mild and open to all ages today.
  - The verified mechanism is different: Ragdoll Havoc itself is gated at minimumAge 16 (Ages 16+).
  - Which owner requirement is unmet (ID check, 2SV, Plus/fee or the engagement threshold) must be checked on the Creator Dashboard.
- **Kids/Select numbers disagree between sources:**
  - fee 1,000 Robux (secondary) versus no amount stated (docs);
  - engagement threshold 100 (docs) versus 250 (GitHub docs mirror) or 500 (DevForum AMA/secondary);
  - expedited review 50k (docs) versus 100k (secondary).
- **Mid-November takedowns:** the reasons are unconfirmed and there is no official Roblox statement. That HRR is back is verified only through the games API (85k playing, updated 19 Nov).
- **Not verified:**
  - whether HRR's quick-join multiplayer is live;
  - HRR's phone layout;
  - whether any competitor forces landscape;
  - console layouts.
- **Product lists:** HRR's developer products were read only for the first 50 (more pages exist). Products for the other games were not read.
- **Revenue figures:** no reliable revenue estimates were found for any game.
- **Ragdoll Universe:** the classic version (580765040) was not re-checked. The 🩸 version (10773111433: 540 playing, Zombie Night, 60+ weapons) was.
- **Search results** were read while logged out; logged-in and age-checked accounts may see different results.
- **'Car Crushers 2'** shows in search as 'Car Crushers 2 ⌛ Physics Simulation', while RoWatcher lists it as '[TITAN ATTACK💥] Car Crushers 2'. Both refer to the same universe, 274816972.

### Game design for short-session physics sandboxes and kids' Roblox games (FTUE, time to fun, session clocks, goal ladders, collection, juice, social, daily return, portrait mobile, and what Grow a Garden / Steal a Brainrot / Dress to Impress / Brookhaven / Natural Disaster Survival / Broken Bones do), turned into build changes for Ragdoll Havoc
- **(high)** Players do not leave because they fail to learn the controls. They leave because nothing new happens in minutes 2 to 5. The 'second-minute cliff' is the main problem, and Roblox ranks exactly that window. *Evidence:* Own data (docs/V7_PLAN.md, Session_v1, 72 h, 45 visits): first shot after 3-17 s, but the median visit is about 120 s, 1 of 11 visits got past 4 min and none past 5 min on the newest build. The owner counted 2 of 15 who stayed 5 min. Roblox Discovery docs: 'first play bounce rate' is a 'Most important' signal, reported in two windows, under 60 s and 61-180 s. A 120 s median sits inside the second window. GameAnalytics 2025 Roblox Benchmark (data Jan 2023 to Jul 2025): the platform-wide average session is P25 2.36 min and P50 6.62 min, so Ragdoll Havoc is in the bottom quartile. Games whose average session is 0-3 min have a median D1 of 4.31% and D7 of 0.41%. At 13-18 min the median D1 is 10.24%; at 19-24 min it is 11.46% D1 and 1.61% D7. This is a correlation across games, not a measured effect. *For us:* Stop tuning the first 30 s; it works. Write a minute-by-minute escalation script for 1:00-6:00 with something new every 45-60 s: a new machine lights up, the first run on yourself, a new toy, a record, a friend prompt. Make the 61-180 s bounce share (from Creator Analytics) and the median first session the headline KPIs. A 10/10 target is a median first session of 13 min or more, which in the benchmark is where D1 roughly doubles.
- **(high)** Every long-session hit has a clock: a repeating unit of 30 s to 6 min that ends in a payoff and a one-tap 'again'. A free sandbox has no clock, so a visit has no natural 'one more'. *Evidence:* Natural Disaster Survival: a random map plus a random disaster each round, the whole game learnt in one round, and a new round within a couple of minutes (vault 'Teardown - Natural Disaster Survival'; 4.53 B visits, 90.8% approval). Dress to Impress: theme, then a timer (about 5-6 min), runway, vote, podium, and a payout for every player (vault 'Case Study - Dress to Impress'; Wikipedia). Grow a Garden: a shared shop restock every ~5 min and weather events on top of a reliable grow loop (vault 'Case Study - Grow a Garden'). Steal a Brainrot: a conveyor of units plus a ~60 s base-lock timer (vault). Broken Bones IV: run off the cliff, then a Round Summary (distance, top speed, injuries, cash), then Play Again / Change Map (allthings.how guide, 1 Sep 2026). It has 1.54 B visits, 4.5 M favourites, 30-player servers and was updated Aug 2026 (Roblox games API, 20 Nov 2026). *For us:* Add a 30-90 s 'Stunt Run' unit: aim, launch (cannon, sky launch, fling pad, ramp, or a weapon on a dummy), then a slow-mo beat and score count-up. A summary card follows (score, personal best, the next rung, one star goal) with a big AGAIN button under the right thumb. On top, add a lab/plaza heartbeat: a visible countdown to the next shared event every 3-5 min (the 18 events already exist), so there is always 'just wait for the next one'.
- **(high)** Scoring the chaos is the proven way to turn a ragdoll toy into a goal ladder, on Roblox and outside it. It works in a kid-safe form when the points come from stunts, not injuries. *Evidence:* Broken Bones IV (Roblox, Bloxy award, 1.54 B visits): every break pays cash, and cash buys upgrades and abilities. Turbo Dismount: 'damage awards points', with an instant rewind, replays from several camera angles in slow motion, and sharing (Wikipedia; GameGrin preview). Goat Simulator: points for flips and actions in the style of Tony Hawk's Pro Skater, with chained tricks building a multiplier and combo quests at 1,000 / 4,000 / 10,000 (Wikipedia; GamesBeat guide). Ragdoll Havoc already computes a score ('CRACK! +N', Shared/ShareCode.scoreOf) but only inside the X-ray replay. *For us:* Make one big number the core currency: a CRASH score from air time, distance, flips, bounces, machine hits and bullseye, with named tricks and a chain multiplier. Show it live over every launch, keep a personal best per machine and a daily best board in the lab, and feed bolts and weapon unlocks from score as well as takedowns. The words stay mild ('BOUNCE x3', 'MEGA FLIP', 'SPLAT-FREE LANDING'), never organ or injury names, so it fits BLOOD off and MILD_TEXT.
- **(medium)** Hits are one verb plus one twist that a 15-second clip explains. Feature breadth without one loop dilutes the game. *Evidence:* Vault 'Viral Game Anatomy - Hooks, Loops and Timing': each 2025-26 megahit is a known loop plus one sentence of difference, the core verb can be understood from a 15-second clip, and Roblox deprioritises games that closely resemble existing ones. Bloody Ragdoll Physics has almost Ragdoll Havoc's exact feature list (docs/RESEARCH_V4.md §3). Hyper Realistic Ragdoll leads the genre (85,765 playing, Roblox games API, 20 Nov 2026) with per-limb reactions and, per a guide, 'no real progression'. Ragdoll Havoc has 69 tools, 18 events, 9 lab creatures, cars, 5 open maps, minigames, an arena and a map shop, but has 1,328 lifetime visits and 17 favourites (Roblox games API, 20 Nov 2026). *For us:* For the 'completely new version', write the loop sentence first. For example: 'Launch ragdolls and yourself through crazy machines for the biggest crash score, then beat your friends' best.' Then route each system into that sentence: weapons become launch and score modifiers, machines become multipliers, maps become stunt courses, events become score storms. Hide or cut whatever does not feed it during the first session. The store title, icon and thumbnail must show that one verb.
- **(medium)** Do not fight the leaders on gore realism. The kid-safe, cartoon-slapstick lane is both required by the owner's rules and safer and wider for reach. *Evidence:* A 'Hyper Realistic Ragdoll' copy (place 101277003916102) was reported unavailable around 15 Nov 2026. The community cites 'extremely violent' depiction (fan wiki hyper-realistic-ragdoll.wiki; Roblox has not confirmed). Bloody Ragdoll Physics reduced its blood to comply with moderation (RESEARCH_V4). Under-9 accounts can open only Minimal or Mild experiences by default (DevForum safety update; ESRB). 34% of age-checked users are under 13 and 37% are 13-17 (Roblox Q3 2026 shareholder letter). The long-lived physics hits are mild and comedic: Fling Things and People (3.76 B visits, Mild), Natural Disaster Survival (4.5 B), Broken Bones IV (1.54 B). The vault note 'Gore Policy and Kid-Friendly Hit Feedback' recommends stars, shards and cartoon 'pow' bursts instead of red. *For us:* Position the new version as a cartoon crash-test comedy. Hit feedback is stars, dizzy spirals, 'POW' cards, squash and stretch, and goofy sounds; no injury vocabulary on screen. Keep the maturity questionnaire at Mild for the maximum reachable content, and remove the dormant BLOOD/SEVERING paths from the live build so the label is defensible. This is the moat against the gore-leaning rivals.
- **(medium)** Slapstick needs a victim with character. The genre leader's draw includes dummies that behave like people, and physics-comedy designers make the ragdoll sympathetic on purpose. *Evidence:* Hyper Realistic Ragdoll's dummies 'move around, panic if threatened, communicate, and even help one another' (search summary of the progameguides guide). Turbo Dismount's developers aimed to make Mr. Dismount 'a more sympathetic character' (Wikipedia). Coffee Stain on Goat Simulator: it worked 'because everything you could do was funny' (Epic Store remaster piece, 2024). Ragdoll Havoc's v3 look chose plain white mannequins with no marks or glow, and speech bubbles are off (CLAUDE.md, LOOK_V3; DummyLife BUBBLES=false). *For us:* Give dummies a cartoon face that reacts (scared before a launch, dizzy after, relieved on a soft landing, cheering when another dummy flies), short kid-safe voice barks on launch and land ('Not the cannon AGAIN!'), and a recurring named star dummy with a test-number suit. Reactions are the punchline that makes clips funny. They cost little network, since they can be client-side like DummySkins.
- **(high)** Most players hold the phone upright, so the game must be playable one-handed in portrait. Otherwise the owner should decide on purpose to force landscape; drifting between the two loses players. *Evidence:* Session_v1: most visits are phones held upright (414x814), then PC, tablet, console (docs/V7_PLAN.md). Hoober (UXmatters, Feb 2013): 49% of people use the phone one-handed; only about a third of the screen is effortless (the bottom, on the side away from the thumb); the centre is the most accurate target. Voodoo's hyper-casual test: 'Can they play it with one hand, while standing on a crowded moving vehicle, for the first time?' (GameAnalytics blog). An analyst estimates about 11.5 B of 14 B monthly Roblox hours in Q3 2025 were on mobile (Windows Central; an estimate, not a filing). No code in the repo sets StarterGui.ScreenOrientation (grep). *For us:* Build a portrait-first one-thumb mode:
- tap a dummy or machine = act, with the existing aim assist; drag = camera;
- every primary control in the bottom third inside the right thumb's arc, the AGAIN and LAUNCH buttons biggest;
- nothing you need in the top-left (notch, unreachable);
- a portrait camera pulled back and up so a machine plus its target fit in the frame, because a vertical 3D view shows a narrow slice.
If playtests show portrait players still quit faster, set ScreenOrientation to landscape explicitly rather than leaving it to the place default.
- **(high)** More juice is not better: both no juice and extreme juice reduce play time. Game feel needs a budget, with the biggest effects kept for the rarest moments. *Evidence:* Kao 2020 (Entertainment Computing 34:100359, N=3,018, four versions of one action RPG): the None and Extreme conditions both gave significantly lower play time, player experience, intrinsic motivation and performance than Medium and High. Vault, 'Hit-Stop and Screen Shake Tuning by Numbers': light hits get no stop and no shake, and important stops need 66 ms or more to show reliably at 30 fps. Vault 'Reward Moments': reward animation time should stay under about 10% of play, and world dimming is kept for top tiers. Vault 'Feedback Timing': sound files with 30-80 ms lead-ins make hits feel floaty. Ragdoll Havoc stacks FEEL_V2 layers: trauma shake, hit-stop, combo slow-mo, FOV, trails, particles, casings and recoil. *For us:* Do a juice-budget pass on a real 30 fps phone in portrait:
- light hits: sound and a small flash only;
- heavy hits and launches: add the stop and shake;
- peak (bullseye, new record, a 10x chain): add slow-mo and the replay.
Never slow-mo routine hits. Measure each sound's onset and trim its lead-in. Count the seconds of slow-mo and replay per 10 minutes of play and keep them under about 10%.
- **(high)** Goal ladders work best when each goal starts partly filled and the next rung is always close. People speed up as they near a goal. *Evidence:* Nunes & Drèze 2006 (Journal of Consumer Research 32(4)): a car-wash card needing 8 stamps was completed by 19% of customers; a 10-stamp card with 2 stamps already given was completed by 34%, for the same effort. Kivetz, Urminsky & Zheng 2006 (Journal of Marketing Research 43): coffee-card members bought faster as the reward neared, and a 12-stamp card with 2 bonus stamps was finished faster than a plain 10-stamp card. Roblox Onboarding docs: keep early XP thresholds low, and surface short-, mid- and long-term goals 'in highly visible places'. Bloody Ragdoll Physics: 91% of new players get the first kill, and 40-66% find each machine badge (docs/RESEARCH_FIRST_SESSION.md). *For us:* Every new goal (next weapon, stunt-book page, daily challenge, level) opens visibly pre-filled, with a stated reason ('+2 for your first shots'). The first rungs come at 1, 3 and 5. Three goals are always on screen and never more: one near (under 60 s away), one for this session, one for this week. No 'come back later' locks in the first session.
- **(medium)** The best collection in a ragdoll sandbox is one that also teaches: a book of named stunts and machines, with blanks you can see. *Evidence:* Bloody Ragdoll Physics uses one badge per lab machine (spike wall 66%, barrel 55%, wrecking ball 44%, cannon 41% of new players); players find the machines by walking into them (RESEARCH_FIRST_SESSION). Hyper Realistic Ragdoll has 'stickers' (short goals such as knocking a dummy flat with the Bat), and Ragdoll Research has journal pages. Ragdoll Sandbox's takedown-badge ladder runs 10 / 50 / 100 / 1,000 (6.89 M / 3.63 M / 2.24 M / 0.22 M earners). In the non-ragdoll hits, collection is the long loop: Grow a Garden's mutations, Steal a Brainrot's index, Dress to Impress's items (vault case studies). *For us:* Fold the 15-page BONE JOURNAL and the experiment cards into one STUNT BOOK of about 30 named stunts, each tied to a machine, weapon or map. Unknown entries show as silhouettes with a one-line hint ('Something happens at the bullseye...'). Each stunt has 1-3 stars from score thresholds, and the first 2 are pre-filled. Award a free Roblox badge per machine stunt, as BRP does. The book is the menu that tells a kid what to try next.
- **(medium)** Coming back on later days now matters more for ranking than one long visit, and under-13s cannot be reached by notifications, so the return hook has to live inside the game. *Evidence:* Roblox newsroom (15 Jun 2026): Recommended For You moved from a 7-day to a 28-day view, with signals for day 1, days 2-7 and days 8-28. Roblox Discovery docs: 'Play days per user' is a 'Most important' signal, and playtime per user is capped at 60 min per user, per game, per day. Experience Notifications reach only opted-in users aged 13+, one per day per experience, with no false time pressure (Roblox docs). 34% of age-checked users are under 13 (Q3 2026 letter). Grow a Garden's icon says 'GROW OFFLINE', which turns logging off into an investment (vault). Vault 'Retention and Return Hooks': give one 'ready' thing on every join and end a session on an unfinished, time-bound goal. Duolingo's Streak Wager raised return visits; a +14% D7 or D14 lift is reported only second-hand. *For us:* Build three return hooks:
- Something that builds while away: a new lab machine or crate assembling over about 8-20 h, shown with a countdown before the player is likely to leave (around 5 min and at a session-end card), ready on the next join.
- A Daily Stunt: the same machine and target for everyone by UTC day, with a daily best board and a reward for beating yesterday's own score.
- A streak with a grace day.
Notifications are an extra for 13+ only, after a wow. Never punish absence with decay.
- **(medium)** Playing with friends is a ranking signal and a proven retention driver, but forced player-on-player physics costs approval. The winning shape is a private space that friends are invited into, with co-op stunts. *Evidence:* Roblox Discovery docs: 'Intentional co-play days per user' is an 'Important' signal: unique days users come back to play with friends through joins, invites or private servers. Roblox's DevForum announcement says its testing found users who play with friends are more likely to be retained long-term (search summary; the page itself could not be fetched). A Roblox spokesperson credited Grow a Garden's success partly to 'friends driving play' (GEEIQ). Fling Things and People (25-player servers) kept 33,314 players a year after its last update, but at 80.5% approval against 86-90% for the solo ragdoll games, because being grabbed against your will causes friction (vault teardown; votes API). Every top new ragdoll sandbox runs 1-player servers (RESEARCH_FIRST_SESSION). *For us:* Keep 'my own lab', and make 'bring a friend into my lab' the social headline:
- an invite that lands the friend beside you (PromptGameInvite with launch data; the Party API can teleport party members together);
- 2-player stunts: one fires the cannon while the other rides, catch the flyer, and the TOSS COMBO that already exists;
- a friends-only best board per machine.
Throws stay opt-in between friends, and the plaza stays non-damaging. Reward only a friend's real arrival, never the act of sending the invite.
- **(medium)** Shareable crash clips are now a discovery channel inside Roblox, and Ragdoll Havoc already has the API wired but hides it. *Evidence:* Roblox newsroom (5 Sep 2025): Moments is a feed of player clips up to 30 s with a 'Join' button. Over 240 M videos were captured in experiences from 24 Jul to 24 Aug 2025, and creators can 'customize capture prompts... to highlight specific in-game events'. Moments was rated Moderate and limited to 13+ at launch. The CaptureService reference has StartVideoCaptureAsync and PromptShareCapture(captureContent, launchData, ...). Turbo Dismount's core includes replaying and sharing crashes. Steal a Brainrot's theft moments spread on TikTok (vault). TikTok ragdoll clips are short fails and chaos (RESEARCH_V4). The repo already calls StartVideoCaptureAsync and PromptShareCapture (Client/ReplayController.luau, CreatorUI.luau), but behind 'CLIP IT'. *For us:* At a personal record, a bullseye or a 5x chain, offer a one-tap 'SHARE THIS CRASH' over the slow-mo replay, never in the first 90 s and at most once per few minutes. Pass launch data with the stunt id and score, so a viewer who taps Join lands at that machine with 'Beat 12,400!'. The stunt and the score card are the clip's hook, so frame the replay camera for 9:16.
- **(medium)** The thumbnail and the first screen must promise the same thing. Roblox now penalises attention that does not turn into play. *Evidence:* Roblox newsroom (15 Jun 2026): games that 'win attention with exciting thumbnails but don't deliver long-term value' were displacing valued games, which motivated the change. Discovery docs: play-through rate and first-play bounce are both 'Most important', and a custom thumbnail is required for Home recommendations. Thumbnail Personalization tests up to 5 thumbnails and allocates impressions hourly by qualified play-through (Roblox docs and DevForum). A third-party claim (RoWatcher) reads a sub-60 s exit rate above 15% as a thumbnail/game mismatch. *For us:* Make 3-5 honest thumbnails of the exact first-minute action: a cartoon dummy flying out of the lab cannon toward the bullseye with a big score. Make sure that machine is in view and usable within 10 s of spawning. Run Thumbnail Personalization once the new version is live, and read the under-60 s bounce per thumbnail.
- **(low)** Weekly appointment events drive the biggest spikes in the top hits, but they need a base of players. For Ragdoll Havoc today they come after retention, not before. *Evidence:* Grow a Garden runs a Saturday 'admin abuse' about an hour before the weekly update (about 30 min, with special weather, rare restocks and exclusive items) and a second weekly 'Watering Wednesday' slot since April 2026. The sources are GameSpot and fan schedule sites, and their times disagree. Steal a Brainrot's scheduled admin events and the Aug 2025 'admin war' with Grow a Garden pushed both games to records (vault case studies). Ragdoll Havoc currently shows 0 playing and 1,328 lifetime visits (Roblox games API, 20 Nov 2026). *For us:* Park appointment events until there are a few hundred players a day. Then run one weekly fixed-time 'HAVOC HOUR' using the existing AdminPanel/AdminTools: server-wide score storms, a free event for everyone, and a limited cosmetic for attending. Announce it with an update announcement and a real countdown in game, never a fake one.
- **(high)** With about 15 visits a day, A/B tests and session stats cannot tell good from bad. The owner's 'more user tests' should be small moderated playtests repeated in rounds. *Evidence:* Roblox Experiments docs: 'Games with fewer than 1,000 daily active users might struggle to get useful data from experiments.' Experiments run 14-60 days, with up to two variants and one control. Ragdoll Havoc had 45 visits in 72 h (Session_v1). Nielsen (NN/g, 'Why you only need to test with 5 users', 2000): run several small studies of about 5 users rather than one big one, and fix between rounds. He also says groups that behave differently, such as children and adults, need separate tests. NN/g's children research recommends designing for age bands (3-5, 6-8, 9-12) and notes that kids barely tell promotions from content. *For us:* Run 3 rounds of 5 players, mostly 8-13-year-olds on phones held upright, plus 1-2 on PC. Each session is 10-15 min, unguided and silently observed (screen plus face if a parent agrees). Log:
- seconds to the first takedown, the first launch and the first stunt score;
- the first 'what now?' or look-away;
- the quit or boredom point;
- what they say is funny.
Fix the top 3 problems between rounds. Use Session_v1 only for direction, and A/B tests only after DAU passes about 1,000.
- **(medium)** Kids love seeing their own avatar fly. The longest-lived ragdoll games on Roblox make the player the ragdoll, not only the dummies. *Evidence:* Broken Bones IV: the core is jumping off a cliff yourself and being paid per break, with level badges at 50 and 100 (allthings.how, Sep 2026; 1.54 B visits). 'Fall Off A Building' has 42.6 M visits as a jump-off-skyscrapers ragdoll sandbox (Rolimons via search). In Fling Things and People, players are the props. Brookhaven gives a new player a house or vehicle within 30 s with no tutorial gate (vault 'Case Study - Brookhaven RP'). Ragdoll Havoc's first session centres on hitting dummies; the player's own RAGDOLL button and stations are secondary. *For us:* Within the first 2 minutes, send the player into the cannon or sky launch themselves, in their own Roblox avatar, scored like any stunt and with a replay. Put the player's name on the lab ('<NAME>'S CRASH LAB' from the Roblox display name, not free text), so ownership is felt in the first 30 s.
- **(medium)** Pop-up and offer discipline matters more for kids, who barely tell offers from content. Fake urgency is also against Roblox's rules for notifications. *Evidence:* NN/g children research, via secondary summaries: children can barely distinguish advertising and promotions from real content. Roblox Experience Notifications docs forbid deceptive tactics such as false time pressure and bait-and-switch rewards. The vault pop-up gate (Core Loops and Session Design): no automatic pop-up in the first 180 s of onboarding, none within 8 s of another, and never over another panel. BRP shows a 15-minute starter-pack countdown on phones from the first frame (RESEARCH_FIRST_SESSION). Ragdoll Havoc's own audit found the egg card and a 'Goal done' toast colliding at about 90 s (docs/AUDIT.md). *For us:* Do not copy BRP's countdown. Keep all offers inside the SHOP and clearly marked with the Robux sign, and never in the play space or the summary card during the first session. Route every automatic card through the existing Notify gate with a hard rule of one at a time, none before the first Stunt Run summary, and none over a replay.

**Sources:**
- Roblox Creator Docs - Discovery (Home recommendation signals) (https://create.roblox.com/docs/discovery), read 2026-11-20
- Roblox Newsroom - Optimizing Discovery: How Great Games Reach Millions of Players on Roblox (https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox), 2026-06-15
- Roblox Creator Docs - Onboarding (https://create.roblox.com/docs/production/game-design/onboarding), read 2026-11-20
- Roblox Creator Docs - Experiments (https://create.roblox.com/docs/production/experiments), read 2026-11-20
- Roblox Creator Docs - Experience notifications (https://create.roblox.com/docs/production/promotion/experience-notifications), read 2026-11-20
- Roblox Newsroom - Roblox Moments: user-generated discovery (https://about.roblox.com/newsroom/2025/09/roblox-moments-user-generated-discovery), 2025-09-05
- Roblox Engine API - CaptureService (https://create.roblox.com/docs/reference/engine/classes/CaptureService), read 2026-11-20
- Roblox DevForum - Boost Your Discovery with the Improved Recommended For You Algorithm (intentional co-play) (https://devforum.roblox.com/t/boost-your-discovery-with-the-improved-recommended-for-you-algorithm-and-analytics-for-creators/3587441), about 2025 (not dated in the summary)
- Roblox Q3 2026 earnings shareholder letter (SEC 8-K exhibit) (https://www.sec.gov/Archives/edgar/data/0001315098/000162828026068235/ex991-q32026earningsshar.htm), 2026 Q3 (week ended 30 Sep 2026)
- Roblox DevForum - Introducing Updates to Our Safety Protections and Parental Controls (https://devforum.roblox.com/t/introducing-updates-to-our-safety-protections-and-parental-controls/3264200), 2024-11 (via search summary)
- GameAnalytics - The 2025 Roblox Benchmark Report (https://www.gameanalytics.com/reports/2025-roblox-report), last updated 2026-08-24 (data Jan 2023-Jul 2025)
- Kao, D. - The effects of juiciness in an action RPG (Entertainment Computing 34:100359) (https://dblp.uni-trier.de/rec/journals/entcom/Kao20.html), 2020
- Nunes & Drèze - The Endowed Progress Effect (Journal of Consumer Research 32(4)); Wharton summary (https://knowledge.wharton.upenn.edu/?p=5630), 2006
- Kivetz, Urminsky & Zheng - The Goal-Gradient Hypothesis Resurrected (Journal of Marketing Research 43) (https://business.columbia.edu/faculty/research/goal-gradient-hypothesis-resurrected-purchase-acceleration-illusionary-goal), 2006-02
- Hoober - How Do Users Really Hold Mobile Devices? (UXmatters) (https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php), 2013-02
- GameAnalytics blog - Voodoo's guide to mobile game design: keep things simple (https://www.gameanalytics.com/blog/voodoo-guide-mobile-game-design-keep-things-simple), undated (2018-2019 era)
- Turbo Dismount (Wikipedia) (https://en.wikipedia.org/wiki/Turbo_Dismount), read 2026-11-20
- Goat Simulator (Wikipedia; GamesBeat quest guide; Epic Store 'Cleaning up the chaos in Goat Simulator Remastered') (https://en.wikipedia.org/wiki/Goat_Simulator), 2014 / 2024
- Roblox games API - Broken Bones IV (universe 911750776) (https://games.roblox.com/v1/games?universeIds=911750776), 2026-11-20
- allthings.how - Broken Bones IV on Roblox: how to play and earn cash (https://allthings.how/broken-bones-iv-on-roblox-how-to-play-and-earn-cash/), 2026-09-01
- Roblox games API - genre snapshot (HRR, BRP, Ragdoll Research, FTAP, Ragdoll Havoc) (https://games.roblox.com/v1/games?universeIds=10773618503,10773926254,10773425091,2668101271,10774775314), 2026-11-20
- hyper-realistic-ragdoll.wiki - Hyper Realistic Ragdoll Roblox banned (fan wiki) (https://hyper-realistic-ragdoll.wiki/updates-and-availability/hyper-realistic-ragdoll-roblox-banned), 2026-11-15
- progameguides - Complete Hyper Realistic Ragdoll beginner's guide (search snippet; page returned 403 earlier) (https://progameguides.com/roblox/complete-hyper-realistic-ragdoll-beginners-guide-roblox/), 2026-11 (approx.)
- GEEIQ - Grow a Garden hits 35.9B visits: what brands can learn (https://geeiq.com/resources/blog/grow-a-garden), 2025
- PocketGamer.biz - Steal a Brainrot becomes first game to surpass 25m concurrent players (https://www.pocketgamer.biz/robloxs-steal-a-brainrot-becomes-first-game-to-surpass-25m-concurrent-players/), 2025-10-07
- Grey Journal - How much does Grow a Garden make (https://greyjournal.net/hustle/how-much-does-grow-a-garden-make/), 2026-10-31
- GameSpot - Next Grow A Garden update and events; mygagcalculator Saturday admin abuse guide (https://www.gamespot.com/articles/next-grow-a-garden-update-and-events/1100-6534922/), 2025-2026
- LihFolk vault notes: Case Study - Grow a Garden / Steal a Brainrot / Dress to Impress / Brookhaven RP; Teardown - Natural Disaster Survival / Fling Things and People; Viral Game Anatomy; Core Loops and Session Design; Retention and Return Hooks; Hit-Stop and Screen Shake Tuning by Numbers; Reward Moments and Celebrations; Feedback Timing; Gore Policy and Kid-Friendly Hit Feedback (C:\Users\tristan\LihFolk-Vault-V2\LihFolk Vault V2\), notes dated Oct 2026
- RoWatcher - Roblox onboarding in 90 seconds or your game is already dead (https://rowatcher.com/news/roblox-onboarding-in-90-seconds-or-your-game-is-already-dead), undated (2026)
- Nielsen Norman Group - Why You Only Need to Test with 5 Users (https://www.nngroup.com/articles/why-you-only-need-to-test-with-5-users/), 2000
- Nielsen Norman Group - children's UX (kids cognition; physical development) (https://www.nngroup.com/articles/kids-cognition/), read 2026-11-20 (via search summaries)
- Windows Central - Roblox engagement vs Steam, PlayStation and Fortnite (analyst estimate) (https://www.windowscentral.com/gaming/oof-roblox-has-as-much-player-engagement-as-steam-playstation-and-fortnite-combined-and-now-its-even-nipping-at-netflixs-heels), 2025
- Ragdoll Havoc internal data: docs/V7_PLAN.md (Session_v1 stats), docs/RESEARCH_FIRST_SESSION.md, docs/RESEARCH_V4.md, docs/AUDIT.md (C:\Users\tristan\Documents\RagdollLab\docs\), 2026-11-20

**Gaps:** - **Reddit:** the web-search tool refuses reddit.com outright (400, "domain not accessible"), so there are no direct Reddit player opinions. DevForum threads were the substitute, but they render as JavaScript and came back empty through WebFetch (normal URL and /raw/). DevForum claims, including the intentional co-play announcement and the 15 Jun 2026 RFY post details, come from search-result summaries only.
- **TikTok:** the discover pages returned only the page title, so there are no captions, view counts or dates. TikTok claims rely on search snippets and the earlier RESEARCH_V4 notes.
- **Session lengths of the hits:** there is no official figure for any hit. Grow a Garden's "18 min" is unsourced (Grey Journal). Steal a Brainrot's "a third of GaG" is a ratio only. Hyper Realistic Ragdoll and BRP session lengths are unknown.
- **The GameAnalytics benchmark:**
  - its session-length/retention table is a correlation across games in its own SDK dataset;
  - the dataset is PC-heavy (mobile-only 7-10%, console about 2%), so its device split is not Roblox's.
- **Mobile share of Roblox hours:** found only as analyst or third-party estimates (72-82%); Roblox filings give no split.
- **Natural Disaster Survival:** real round and intermission timings were not found.
- **Dress to Impress round length:** sources disagree (5 vs 6 min).
- **Hicks et al. 2019 (CHI PLAY):** findings on juicy visuals were not retrieved; only Kao 2020 was used.
- **Duolingo streak lift figures:** second-hand, and they disagree (D7 vs D14).
- **Hoober's thumb-zone details:** come partly from secondary articles.
- **The Hyper Realistic Ragdoll removal:** the ban of place 101277003916102 and its cause come from a fan wiki and YouTube titles, not Roblox. The main HRR universe is live (85,765 playing on 20 Nov).
- **Moments and share links:**
  - whether clip sharing works for under-13s (Moments launched 13+);
  - whether launch data from PromptShareCapture or share links can drop a viewer into a specific lab/machine.
  Neither was verified.
- **Not tested on Ragdoll Havoc's audience:** whether portrait-first or forced landscape keeps young phone players longer. Moderated playtests should decide.
- **No first-hand play:** none of the hit games was played; their first-session descriptions come from vault notes, guides and press. Fan-site numbers (Broken Bones payouts, GaG timings) are marked as such.
- **Precondition for live events:** appointment events and Experiments need far more traffic than the current ~15 visits a day.

### Roblox discovery and recommendation in 2025-2026: ranking signals, retention benchmarks and targets, age/maturity reach (Kids & Select), Experience Notifications, ads/events, thumbnails/icons/video, title/description, update cadence, and the first-session metrics that predict growth. All of it applied to Ragdoll Havoc (live 0.25.0, ~15 visits/day, median visit ~120 s, "Minimal, Ages 16+").
- **(high)** The game's biggest reach problem is the 'Ages 16+' audience gate, not the maturity label. A game with a full Minimal or Mild rating still reaches only age-checked users 16+ until the creator meets the all-ages publishing requirements and the game passes evaluation. Users who are not age-checked count as Roblox Select (self-declared 9+). So today the game is closed to Kids (5-8), Select (9-15) and every user who has not done an age check. Redoing the questionnaire alone, as V3/V4 assumed, does not fix this. *Evidence:* Roblox Kids & Select docs: Kids = Minimal/Mild, Select = up to Moderate. Select covers 'self-declared age 9 or older (until age-checked)'. The all-ages steps are: account in good standing, ID or facial age check, 2-Step Verification, the full Content Ratings Questionnaire, either Roblox Plus/Premium held for 2 consecutive months or a one-time refundable fee, and evaluation. In evaluation the game is first trialled with age-checked 16+ users and must reach 100 unique plays by highly engaged, age-checked users within 60 days. Roblox lowered that threshold from 250 to 100 starting 19 Nov 2026 (DevForum 'A Simpler Path to Publish', 12 Oct 2026). A highly engaged user needs account tenure, playtime in the game and a purchase anywhere on Roblox in the last 60 days. The progress page is Creator Hub > Publish Settings > Manage Audience. The AMA (16 Apr 2026, update 11 May) gives the per-game fee as 1,000 Robux, refundable. Games that miss the requirements 'stay available to 16+'. Over 50% of global DAU and 65% of US DAU had done an age check in April 2026. Of the checked users in Jan 2026, 35% were under 13, 38% were 13-17 and 27% were 18+ (Roblox Q4-2025 letter via ppc.land). Expedited review costs a refundable 50,000 R$. The top ragdoll sandboxes are rated Moderate (HRR, ~92k CCU) or Mild (BRP), so the label tier itself is not what limits reach. *For us:* Make this owner task P0, ahead of any new feature. (1) Open Manage Audience and see which step is missing: ID check, 2FA, Plus held 2 months or the 1,000 R$ refundable fee, and the full questionnaire answered for every live switch (BLOOD off, SEVERING off). (2) Collect 100 highly engaged 16+ plays within 60 days. At ~15 visits a day that will not happen on its own. Run a small Ads Manager campaign with the 'Qualify for Kids and Select' goal (see the ads insight), or pay the 50,000 R$ refundable expedited review if the owner has the Robux. Rough estimate, not measured: age-checked 16+ users are only about a fifth to a quarter of DAU, so every RFY test the game gets today runs on the smallest and least ragdoll-hungry slice of Roblox.
- **(high)** Since 15 June 2026, Recommended For You ranks mainly on four signals: play-through rate (PTR), first-play bounce rate (leaving within 60 s, and within 61-180 s), play days per user (day 1, days 2-7, days 8-28) and playtime per user (capped at 60 min per user per day). Four signals rank as 'important': intentional co-play days, qualified play sessions, spend days and Robux spent. QPTR was removed. On 20 Aug 2026 Roblox added more weight on long-term retention and 'sustainable monetization'. Only players who arrived through RFY are counted. *Evidence:* Roblox Discovery docs (create.roblox.com/docs/discovery) give the priority table and the bounce windows (<60 s and 61-180 s). DevForum 'RFY Algorithm Improvements That Better Value Long-Term Retention' (15 Jun 2026) covers the 7-to-28-day move and the QPTR removal. Roblox newsroom (15 Jun 2026): the old proxies 'could disproportionately favor games that win attention with exciting thumbnails'. DevForum 'Boost Your Discovery by Building Games People Want to Play' (6 Aug, live 20 Aug 2026): 'If retention is low, focus first on making the core gameplay experience more fun, clear, and rewarding.' The 60-minute cap comes from the DevForum post of 31 Mar 2025. The Discovery FAQ: signals are per-user averages, so 'smaller games with highly engaged users are not disadvantaged'; early signals 'kick in immediately'; the algorithm retests daily with a very low play minimum. *For us:* The median visit of ~120 s falls inside the 61-180 s bounce window, so most new players count as a negative signal. Design goal #1 for the new version is to keep a new phone player past 180 s, and the 60-180 s stretch needs its own hook. The 20 Nov schedule (mission 40 s, UFO 45 s, next weapon 45 s, surprise 80-110 s, chase 100 s) is the right shape. Measure it per window: add <60 s / 61-180 s / >180 s buckets to tools/SessionReport. Goal #2 is reasons to come back on days 2-7 and 8-28, which now outweigh one long first session. A long single session beyond 60 min per day earns nothing extra. Monetization comes third: Roblox itself says to fix core fun first when retention is low.
- **(medium)** Roblox publishes no absolute targets, and its Creator Hub benchmark scorecards only appear at 100+ DAU. Third-party percentiles from games with 1M+ MAU give a usable ladder. Session length predicts retention strongly: games whose sessions average 0-3 min have a median D1 of only 4.3%. *Evidence:* GameAnalytics 2026 Roblox report and benchmarks hub (538 titles with 1M+ MAU, Aug 2025 to Jul 2026). D1: p25 8.4%, p50 10.3%, p75 12.9%, p90 15.9%, p95 18.0%. D7: 1.0/1.5/2.5/3.9/5.3%. D30: 0.3/0.5/0.9/2.0/3.0%. Average session per game: p25 7.3, p50 9.8, p75 12.0, p90 14.7 min. Payer share 3.8%. GameAnalytics 2025 report by session band: 0-3 min band median D1 4.31%, D7 0.41%; 4-6 min 6.20%/0.88%; 7-12 min 7.91%/0.90%; 13-18 min 10.24%/1.20%; 19-24 min 11.46%/1.61%. Deconstructor of Fun (Apr 2026) quotes a Roblox partner: a hit is '90th percentile across all those metrics'. CreatorXP (Oct 2026): scorecards need 100+ DAU. One developer's own bounce goal is under 10% in both windows, measured at 20%/23% (GitHub issue). Another developer called 20% bounce 'too high' (video transcript, Jun 2026). *For us:* Targets below are estimates built from those percentiles. Stage A (next 2-4 weeks): median first session at least 6 min, at most 15% bounce under 60 s, at most 20% bounce at 61-180 s, D1 at least 8%. Stage B (being recommended): median session at least 10 min, D1 at least 13% (p75), D7 at least 2.5%, D30 at least 1%. Stage C (hit): D1 at least 16%, D7 at least 4%, around p90 everywhere. The game sits at ~2 min in the 0-3 min band, where median D1 is ~4%; that alone explains 'only 2 of 15 stayed'. Below 100 DAU the owner sees no benchmarks, so Session_v1 must compute D1/D7 (returning userIds) and the bounce buckets itself.
- **(medium)** Experience Notifications are the only owned push channel for day 2-7 returns. As built now, the game gets almost nothing from them: the opt-in waits for 8 minutes of play, which nobody reaches, and no notification is ever sent because the Open Cloud sender is not set up. *Evidence:* Roblox docs (Experience notifications): open to 13+ users only, so every current 16+ player is eligible. The game needs 100+ visits. Each user gets at most 1 notification per day per experience. PromptOptIn shows at most once per 30 days, its text is fixed, and it should come 'in contexts where a future notification is clearly useful'. Strings are 99 characters at most, and analytics appear after 100 impressions. No published lift figures exist (DevForum threads 2024-2025 only discuss limits). Repo: Config.EXPERIENCE_NOTIFY = true, NOTIFY_OPTIN_AFTER = 480 s. V6_PLAN says sending 'needs the Open Cloud user-notification API with a key (not set up)'. Session_v1: no visit past 5 min on the newest build. *For us:* Move the opt-in to a moment that promises tomorrow, around 2-4 min. Examples: when the first Daily Experiment is done ('a new one tomorrow') or when the next weapon is 1-2 kills away and a gift timer is running. Wire the Open Cloud sender from a server (daily experiment reset, streak at risk, 'your gift is ready'), one per day at most. Track opt-in rate and CTR in the dashboard. This feeds the day 2-7 play-days signal directly. It is cheap but not a cure; its value depends on first sessions getting longer first.
- **(medium)** Intentional co-play (joins, invites, private servers, and since 11 Dec 2025 reserved-server sessions) is a ranked signal. All the top ragdoll sandboxes run 1-player servers, so co-play is an open lane in this genre. *Evidence:* DevForum 'Boost Your Discovery...' (31 Mar 2025; update 11 Dec 2025): co-play is 'Frequency of users intentionally playing with friends'. It counts play 'through join, invite, or private server rather than through a matchmaking', and 'Play sessions in reserved servers are now counted as intentional co-play.' The Discovery docs list it as 'Important'. A separate DevForum thread reports that Play-button joins later teleported to a friend's reserved server were counted as unintentional (2025, no staff answer). In repo research (RESEARCH_FIRST_SESSION.md, 20 Nov 2026), HRR, BRP, RR, RDP and Ragdoll Sandbox all use server size 1. A Plus change (24 Sep 2026) limits free private servers to one per game unless the creator makes them free for everyone. *For us:* Keep server size 6 and the shared plaza. Make 'bring a friend into my lab' a first-session moment: SocialService invite at the first wow, a free private server (owner turns off 'Requires Robux'), and PortalService reserved labs for friend groups and Prank Party. Do not lengthen the first join with a teleport for solo players. A loading screen before the first shot costs more in <60 s bounce than co-play gains. Whether a solo reserved server counts as co-play is unverified, so do not design around it.
- **(high)** Store assets are now hard gates and measurable levers. A custom thumbnail has been required for any Home recommendation since 19 Oct 2026. Gameplay video autoplays on RFY (since 29 Jul 2026) and feeds Moments. Thumbnail personalization raises play-through, and thumbnails that do not match the game cost reach. *Evidence:* DevForum 'Homepage recommendation eligibility now requires a custom thumbnail' (19 Oct 2026). DevForum 'How we are improving Home this year' (9 Mar to 29 Jul 2026): gameplay video in Standout gave '+47%' quality plays; on RFY, games with video saw 'up to +39%' more playtime from RFY. The video 'does not change how recommendations are ranked'. Rules: real current footage; no voice-over, narration, or music with lyrics; minimal editing. Thumbnail docs: 2-5 active thumbnails for personalization, an average +8.5% (some +50%) in qualified play-through, nothing essential at the bottom edge, 16:9 at 1920x1080, 3 video uploads per month. Icon docs: at least 512x512, check it at 150x150. Discovery docs: 'mismatched metadata and content' and 'non-unique games that closely resemble existing games' get lower exposure. RDC (11 Sep 2026): EDP videos appear in Moments. *For us:* Use the existing Director mode (F8, 9:16 frame, REC) to record 2-3 honest 15-30 s clips of moments a new player meets in the first 2 minutes: cannon to bullseye, UFO beam, gorilla, a car into the crowd. Upload them as EDP videos with no lyric music. Keep 3-5 personalized thumbnails, each built on one first-minute moment, and swap the set only with major updates. The icon needs one big dummy face or pose that reads at 50-150 px. Never show content the first session does not deliver: the bounce penalty undoes any extra clicks. The look must also stand apart from HRR/BRP/RR so the game does not read as 'non-unique'.
- **(medium)** Title and description rules reward stability and accuracy. One or two emojis are fine. Frequent renames reduce findability. Giveaway-led metadata is demoted. Search is semantic across languages. *Evidence:* Roblox publishing docs: 'one or two well-placed emojis isn't harmful'; renaming too often 'reduces the chances that players can find it'; repeating words can cause demotion. Discovery docs: lower exposure for 'Giveaway-led titles' and mismatched metadata; 'Don't rely on promotional monetary rewards'; search 'uses semantic search across all officially supported languages', so natural-language queries work. Discovery FAQ: inaccurate tags cause bounces. Vault note 'Cross-Game Patterns - Thumbnails Icons and Titles' says to keep a fixed brand with one changing slot. STORE_TEXT.md currently lists rotating titles: '[🎄] Ragdoll Havoc 💥', '[UPD] Ragdoll Havoc 💥', and others. *For us:* Choose one permanent title (for example 'Ragdoll Havoc 💥') and allow at most one seasonal slot, changed rarely, such as the 🎄 from 1 Dec to early January. Drop the '[UPD]' rotation. Open the description with the plain words people search for, 'ragdoll physics sandbox: launch crash-test dummies…', and promise nothing missing from the first session. Never use 'free egg' or 'free weapon' in the title or thumbnails. Add a Danish translation through localization so semantic search finds it in DA too.
- **(medium)** Discovery is now age-aware. Roblox says younger players engage best with shorter-form games they discover, enjoy and move on from, while older players prefer deeper games they return to. It is also testing ranking by how many new players a game brings to Roblox, and shared links are becoming direct play paths (Chrome play by the end of 2026). *Evidence:* Roblox newsroom 'RDC 2026: The World Needs More Play' (11 Sep 2026), quoting 'Our discovery ranking system is increasingly age-aware', the short-form/deep split, 'looking beyond the first week to the first 28 days', and the test of 'how many new players a game brings to the platform'. Roblox IR release (11 Sep 2026): 'A shared link, anywhere on the web, becomes a direct path from discovery to play'. Creator Rewards docs: Audience Expansion pays for new or reactivated users who arrive by Share Link and play 10+ min the same day, and the game must average 100+ DAU. *For us:* A ragdoll sandbox is short-form by nature, which suits the young cohort the game cannot reach yet (see the first insight). Opening the age gate is what lets the short-form strength count. For the 16+ audience it can reach today, it must show depth and reasons to return: the ladder, daily experiments, the journal. Plan TikTok/YouTube clips that carry the game's Roblox Share Link, so off-platform viewers land straight in play. This would count for the 'new players brought' test, and later for Creator Rewards once DAU passes 100. Never tie rewards to likes or follows, and save nothing from TikTok LIVE.
- **(medium)** Paid ads can't buy RFY rank, but they are the fastest legal way to (a) reach the Kids & Select highly-engaged threshold and (b) get enough sessions to measure a new build. *Evidence:* Discovery FAQ: users acquired through ads are excluded from RFY ranking signals, and 'Ads do not penalize or downrank your game'. Ads Manager docs: there is a 'Qualify for Kids and Select' goal aimed at age-checked highly engaged players (expect a higher cost per play). Targeting covers age, location, device and genre. The minimum ad credit purchase is 1 credit. If nothing improves after 3-5 days, the docs say to fix onboarding first. Non-unique games may get no delivery. Roblox Q4 2025 letter (via ppc.land, 7 Feb 2026): Ads Manager cost per play fell more than 40% against Q1 2025. Forum figures from the 2023-24 launch era put cost per play around 1.7-2.85 R$ (old, anecdotal). Session_v1 has only 45 visits in 72 h, too few to judge any change. *For us:* Once the new first session is built, run (1) a small 'Qualify for Kids and Select' campaign until Manage Audience shows 100/100, and (2) a short phone-targeted 'Plays' campaign to collect about 300-500 sessions per build for SessionReport. Judge a build only on those cohorts. Do not run ads to 'grow': they do not feed RFY, and a game with 120 s sessions wastes the money.
- **(high)** Monetization is now part of ranking, through spend days and Robux spent per user. Roblox's guidance is still to fix retention first, then add value-for-money purchases for players who stay. *Evidence:* DevForum 'Boost Your Discovery by Building Games People Want to Play' (6/20 Aug 2026): 'Games that are strong in both retention and monetization are best positioned to earn more impressions'; games strong in one area still get impressions. DevForum (26 Nov 2024): Roblox does not route only payers to monetized games. GameAnalytics 2026: 3.8% of tracked players paid anything; median ARPPU per game $0.70. Repo/CLAUDE.md: Shop.OFFERS and several product ids are still 0, and 'almost nobody opens an egg'. *For us:* Ordering for the new version: first session and return first. Then one or two clear low-price offers that a player who has stayed sees after real play, such as the starter pack and a weapon tier at 25-49 R$, each with an id. Avoid aggressive early pop-ups: they push up <60 s bounce, which outranks spend. Track 'spend days per user' as the monetization KPI, not revenue.
- **(medium)** Roblox offers no 'recently updated' boost. Updates matter only through the signals they move. Distribution is re-tested daily, and a bad stretch carries no lasting penalty. Experience Events and Update announcements are the official places to say what is new. *Evidence:* Discovery FAQ: 'updates to your game or changes to gameplay' influence signals, with no rule about frequency. The RFY Q&A video: 'There is no cost or penalty for you to start with a game that didn't perform as well'. Staff posts (Nov 2024, Nov 2025): 'Keep building and updating'. Experience events docs: events appear on the detail page with Notify Me, plus the Charts sort 'Trending Events in Experiences' (needs 1,000 RSVPs); update announcements are 60 characters, at most one every 3 days, and should be specific. Discovery FAQ: traffic peaks on Saturdays and shifts with holiday seasons. Staff FAQ (Nov 2024): 'Frequent crashes ... hurts' discovery. Repo research: rival sandboxes update almost daily. *For us:* Ship on a steady weekly rhythm before the weekend (Thursday/Friday) so the Saturday peak meets the new build. Each update should target one measured weak spot rather than add features. Create an Experience Event for the 1 Dec Christmas Lab (Notify Me) and write specific 60-character update announcements. Treat crashes on low-end phones as a discovery bug: a zero-crash target on 414x814 phones.
- **(medium)** The genre is a crowded wave of near-identical new ragdoll sandboxes, so the 'non-unique' demotion and the Standout Games route both turn on having one visible, novel twist. *Evidence:* Discovery docs: lower exposure for 'non-unique games that closely resemble existing games'. Ads docs: non-unique games may get no ad delivery. Standout Games docs: curated for 'unique, in-depth gameplay mechanics, distinctive visual styles'; copies and reskins are 'a hard sell'; console and mobile optimization, R15 and experience events are recommended; nomination needs gameplay video. Repo research (20 Nov 2026): HRR, BRP, RR, RDP, Ragdoll Sandbox and Realistic Ragdoll Engine were all created between 12 Oct and 3 Nov 2026. *For us:* The new version needs one signature idea a player sees in the first 30 s and the thumbnail shows. Candidates already in the code: an X-ray crash-test replay with a score and share code, daily lab experiments that are the same for everyone, and throwing friends into traps (Prank Party). Make it the core loop, not a menu item. Once it exists and D1 is near p50 or better, nominate the game for Standout with a clip from the Director mode. Gamepad, portrait phone and R15 support already match the 'recommended' list.

**Sources:**
- Discovery (Roblox Creator Docs) (https://create.roblox.com/docs/discovery), 2026 (current)
- Discovery FAQ (Roblox Creator Docs) (https://create.roblox.com/docs/discovery-faq), 2026 (current)
- Recommended For You Algorithm Improvements That Better Value Long-Term Retention (DevForum) (https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575), 2026-06-15
- Optimizing Discovery: How Great Games Reach Millions of Players on Roblox (Roblox Newsroom) (https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox), 2026-06-15
- Boost Your Discovery by Building Games People Want to Play (DevForum) (https://devforum.roblox.com/t/boost-your-discovery-by-building-games-people-want-to-play/4779042), 2026-08-06 (live 2026-08-20)
- Boost Your Discovery with the Improved RFY Algorithm and Analytics for Creators (DevForum) (https://devforum.roblox.com/t/boost-your-discovery-with-the-improved-recommended-for-you-algorithm-and-analytics-for-creators/3587441), 2025-03-31 (update 2025-12-11)
- How we are improving Home this year (DevForum) (https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571), 2026-03-09 to 2026-07-29
- Testing Improvements to the 'Recommended For You' Algorithms (DevForum) (https://devforum.roblox.com/t/testing-improvements-to-the-%E2%80%9Crecommended-for-you%E2%80%9D-algorithms/3275201), 2024-11-26
- [Tests] Continuing to improve the 'Recommended For You' algorithm (DevForum) (https://devforum.roblox.com/t/tests-continuing-to-improve-the-%E2%80%98recommended-for-you%E2%80%99-algorithm/4067565), 2025-11-13
- Recommended for you algorithm Q&A (Roblox video docs) (https://create.roblox.com/docs/videos/recommended-for-you-algorithm-q-a), 2026
- Roblox Kids and Select (Creator Docs) (https://create.roblox.com/docs/production/publishing/kids-and-select), 2026 (current)
- Content maturity and compliance (Creator Docs) (https://create.roblox.com/docs/en-us/production/promotion/content-maturity.md), last updated 2026-11-10
- New Publishing Requirements + Evaluation Process for Games (DevForum) (https://devforum.roblox.com/t/new-publishing-requirements-evaluation-process-for-games/4573166), 2026-04-13
- [AMA] Publishing Requirements + Roblox Kids & Select (DevForum) (https://devforum.roblox.com/t/ama-publishing-requirements-roblox-kids-select/4580953), 2026-04-16 (update 2026-05-11)
- A Simpler Path to Publish, Plus Invite Early Testers (DevForum) (https://devforum.roblox.com/t/a-simpler-path-to-publish-plus-invite-early-testers/4930524), 2026-10-12
- Experience notifications (Creator Docs) (https://create.roblox.com/docs/production/promotion/experience-notifications), 2026 (current)
- Introducing Experience Notifications (DevForum) (https://devforum.roblox.com/t/introducing-experience-notifications/2826474), 2024-02-06 (updates to 2024-06)
- Experience events (Creator Docs) (https://create.roblox.com/docs/production/promotion/experience-events), 2026 (current)
- Ads Manager (Creator Docs) (https://create.roblox.com/docs/production/promotion/ads-manager), 2026 (current)
- Roblox's ad platform hits 90% completion rates as age checks unlock adult audience data (PPC Land) (https://ppc.land/robloxs-ad-platform-hits-90-completion-rates-as-age-checks-unlock-adult-audience-data/), 2026-02-07
- Experience Thumbnails (Creator Docs) (https://create.roblox.com/docs/production/promotion/thumbnails), 2026 (current)
- Game icons (Creator Docs) (https://create.roblox.com/docs/production/promotion/game-icons), 2026 (current)
- Homepage recommendation eligibility now requires a custom thumbnail (DevForum) (https://devforum.roblox.com/t/homepage-recommendation-eligibility-now-requires-a-custom-thumbnail/4945086), 2026-10-19
- [Live now] Personalize your thumbnails to attract more users (DevForum) (https://devforum.roblox.com/t/live-now-personalize-your-thumbnails-to-attract-more-users/3257233), 2025-02-13
- Create and publish games and places (Creator Docs) (https://create.roblox.com/docs/production/publishing/publish-experiences-and-places), 2026 (current)
- Acquisition analytics (Creator Docs) (https://create.roblox.com/docs/production/analytics/acquisition), 2026 (current)
- Improved Discovery Measurement in Creator Analytics (DevForum) (https://devforum.roblox.com/t/improved-discovery-measurement-in-creator-analytics/4930122), 2026-10-12
- RDC 2026: The World Needs More Play (Roblox Newsroom) (https://about.roblox.com/newsroom/2026/09/rdc-2026-the-world-needs-more-play), 2026-09-11
- Roblox Unveils New Ways to Play, Build, and Grow at RDC (Roblox IR) (https://ir.roblox.com/news/news-details/2026/Roblox-Unveils-New-Ways-to-Play-Build-and-Grow-at-the-Roblox-Developers-Conference-RDC/default.aspx), 2026-09-11
- Roblox unveils new play, creation and monetisation tools at RDC 2026 (PocketGamer.biz) (https://www.pocketgamer.biz/roblox-unveils-new-play-creation-and-monetisation-tools-at-rdc-2026/), 2026-09-14
- Roblox Fuels High-Fidelity Games for Over 18 Players (Roblox Newsroom) (https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42), 2026-04-30
- Standout Games (Creator Docs) (https://create.roblox.com/docs/creator-programs/standout-games), 2026 (current)
- Creator Rewards (Creator Docs) (https://create.roblox.com/docs/creator-rewards), 2026 (current)
- 2026 Roblox Benchmark Report / Benchmarks Hub (GameAnalytics) (https://www.gameanalytics.com/reports/2026-roblox-report), 2026-09-01
- The 2025 Roblox Benchmark Report (GameAnalytics) (https://www.gameanalytics.com/reports/2025-roblox-report), 2025 data (page updated 2026-08-24)
- What makes a new Roblox game take off? (Dubit) (https://dubit.io/library/what-makes-a-new-roblox-game-take-off), 2026-09-16
- How to Build a Real Business on Roblox in 2026 (Deconstructor of Fun) (https://www.deconstructoroffun.com/blog/how-to-build-a-real-business-on-roblox-in-2026), 2026-04-06
- Why Your Roblox Game Has No Players (CreatorXP) (https://creatorxp.gg/guides/why-your-roblox-game-has-no-players), 2026-10-26
- BIG UPDATE! New Roblox Algorithm Changes June 2026 (transcript summary, SozAI) (https://sozai.app/transcript/roblox-algorithm-changes-june-2026/), 2026-06
- Bounce under 10% goal (GitHub issue, Cat-Cafe) (https://github.com/derekburnz/Cat-Cafe/issues/5285), 2026
- Roblox Age Verification 2026 (Tech Insider) (https://tech-insider.org/roblox-age-verification-2026/), 2026 (inconsistent dating)
- Home Recommendation Impressions and CCU dropped 70-80% following RFY Algorithm Test (DevForum) (https://devforum.roblox.com/t/home-recommendation-impressions-and-ccu-dropped-70-80-following-rfy-algorithm-test-april-10-2026/4576807), 2026-04-14
- Roblox's Algorithm Gives New Games Two Boosts — Then Nothing (RoWatcher) (https://rowatcher.com/news/roblox-s-algorithm-gives-new-games-two-boosts-then-nothing), undated
- LihFolk vault notes: Discovery and Monetization Changes 2025-2026; Policy and Age Rules 2026; Cross-Game Patterns - Thumbnails Icons and Titles (C:\Users\tristan\LihFolk-Vault-V2\LihFolk Vault V2\49 Roblox Platform Features\), 2026-10/11

**Gaps:** Not reached or not verified:
(1) Reddit. Searches returned no r/robloxgamedev threads, only DevForum posts.
(2) TikTok. Covered only through secondary trend reports, with no direct TikTok data.
(3) The web search budget for this session ran out near the end. I could not check whether Experience Events also surface on Home or a 'Live Events' sort, or whether small games can apply to platform events such as The Hunt.
(4) Roblox publishes no absolute targets for PTR, bounce, D1 or D7. The stage targets above are my estimates from the GameAnalytics percentiles, which come from 1M+ MAU games (survivor bias), plus developer anecdotes.
(5) The share of DAU the game can reach at '16+ only' is an estimate. Roblox gives age-checked shares (over 50% global in April 2026; a secondary source says 64% by 30 Sep) and an age split of checked users (Jan 2026), but no 16+ share.
(6) The game's own Manage Audience status was not checked. I did not open its dashboard or query its universe, so which all-ages step is missing (ID check, 2FA, Plus or 1,000 R$ fee, full questionnaire, or the evaluation threshold) is still open for the owner.
(7) Sources give different highly engaged thresholds: 100 in current docs, 250 earlier, 500 in the April AMA. The 12 Oct 2026 staff post says 250 drops to 100 from 19 Nov 2026, which I treat as current.
(8) No published lift figures exist for Experience Notifications. No 2026 Ads Manager cost per play is published; the forum figures are from 2023-24.
(9) Whether a solo player in a reserved server counts as intentional co-play is unverified. The December 2025 note says reserved-server sessions count, but gives no detail.
(10) The CLAUDE.md claim that Bloody Ragdoll Physics went from 2.5k to 21k CCU after a label change could not be found. A third-party wiki lists BRP as Mild today. Treat the claim as unverified.
(11) Experience Notifications are 13+ only, and the docs say nothing about under-13 reach. If the game later reaches Kids & Select, notifications will not reach those players.

### Ragdoll Havoc's own history (research, plans, audits, decisions, 5-20 Nov 2026) set against the live store page and current Roblox platform rules. What was implemented, what was not, what was wrong, what players never saw, and the biggest strategic mistakes.
- **(high)** The biggest unaddressed limit is reach, not polish. Since June 2026 a brand-new Roblox game is shown only to age-checked users aged 16+ until it passes the Kids and Select evaluation. That evaluation needs: an ID-verified creator with 2-step verification; 2 months of Plus/Premium or a refundable publishing fee; and a benchmark of 100 (docs) / 250 / 500 (other sources) unique plays from 'highly engaged' age-checked players within 60 days. A highly engaged player needs account tenure, playtime in your game and a purchase somewhere on Roblox in the last 60 days. The repo's 'biggest owner lever' is to redo the maturity questionnaire (CLAUDE.md v3; RESEARCH_V4 rank 1). That is almost certainly a misdiagnosis: the label is already Minimal, and a game that is 'Minimal, Ages 16+' matches exactly the trial-phase lock that many DevForum threads describe. No repo doc mentions Kids and Select, Audience Reach, highly engaged players or ID verification. The LihFolk vault does: 'Publishing an Experience' says 'A brand-new game is 16+ only until enough highly engaged, age-checked players play it.' *Evidence:* - Games API, 20 Nov 2026: '[EVENT] RAGDOLL HAVOC' has 1,328 lifetime visits, 17 favourites, 0 playing, votes 5 up / 3 down, maxPlayers 6, created 5 Nov 2026.
- Same API: Hyper Realistic Ragdoll (HRR) 85,345 playing, 31.7 M visits.
- Roblox creator-docs kids-and-select.md: 'The game is first made available only to age-checked users 16 and older'; '100 unique plays by highly engaged age-checked users within a 60-day window'; ID verification and 2FA required; expedited review 50,000 Robux.
- DevForum, 2026: 'Content Maturity is Minimal but still only locked on 16+', where staff call it 'intended behavior'.
- The Kids and Select launch thread gives the expedited review as 100k Robux.
- Grep of the repo for 'Kids and Select', 'Audience Reach' and 'highly engaged': 0 hits. *For us:* Step 0 of any new plan, before code:
- the owner opens Creator Hub > Audience Reach and reads the game's status and threshold;
- turns on ID verification and 2FA;
- pays the refundable fee or keeps Plus.

Treat the first ~100-250 highly engaged 16+ plays as the launch milestone. That means making the game good for the 16+ age-checked audience it has now, while keeping it Mild for later. Spend the 50k-100k expedited review only once the first session holds. Stop telling the owner that the questionnaire is the lever.
- **(high)** The store promises a different game from the one players get. The live icon and all 3 live thumbnails are AI-made, Pixar-style cartoon renders:
- expressive cartoon crash-test dummies with big eyes;
- a cartoon gorilla;
- a blue car ploughing through a line of 15 dummies.

None of the repo's honest in-game captures (art/store/v4, 'all are real in-game captures') was uploaded. Inside the game, players get white block mannequins with the classic smiley in a realistic-lit lab. The repo's own research warned against exactly this:
- RESEARCH_V4 §8: 'no renders that look better than the game';
- the vault [Click-Through Rate]: a misleading thumbnail 'raises CTR and then loses players in the first minute'.

Roblox now ranks on first-play bounce in two windows, under 60 s and 61-180 s. A median visit of about 120 s sits in the middle of the second window. *Evidence:* - Downloaded the live thumbnails (thumbnails API, ids 130041076140252, 85105512597254, 78757019607626; none appear anywhere in the repo) and the icon.
- Compared them with art/store/v4/thumb1_gorilla.png, a real capture: a flat white plaza, text billboards, plain avatars.
- Rival icons both show the real white mannequin with Roblox's 'man face' plus the core hook: HRR an X-ray skull hit by a bat; Bloody Ragdoll Physics (BRP) an in-engine explosion.
- Dubit (16 Sep 2026), citing the 15 Jun 2026 DevForum post: first play bounce rate (<60 s and 61-180 s) is among the four 'Most Important' Recommended For You (RFY) signals.
- Roblox newsroom (Jun 2026) warns against games that win 'attention with thumbnails' but have weak long-term value. *For us:* Pick one of two moves and make the promise and the game match:
- (a) Replace the icon and thumbnails with in-engine shots of real moments (cannon launch, car hit, gorilla swat) and run Roblox's thumbnail personalisation for 7-14 days.
- (b) Bring the game to the promise cheaply: big expressive faces on the dummies (shocked while flying, dizzy after a hit), crash-test marks, a bright sky and grass. This is mostly decals and face swaps.

The game cannot measure its first session honestly while the store page sets the wrong expectation.
- **(high)** The live store text is stale or false:
- The title is '[EVENT] RAGDOLL HAVOC', but no event is running. STORE_TEXT.md never proposed '[EVENT]', and the vault calls '[UPDATE] with no update' title spam that players learn to ignore.
- The live description is the 0.20 'v2' text (Prank Party, SANDBOX, X-ray replay, Christmas Lab). The recommended v4 text was never pasted.
- The in-game What's New for 0.25.0 promises 'BIRDS that really fly: wings beating as they take off', but Config.BIRDS = false went out in the same publish. *Evidence:* - Games API name and description, read 20 Nov 2026.
- STORE_TEXT.md: 'Description v4 ... recommended'.
- Shop.luau WHATS_NEW[1] line 64.
- Config.luau line 165 (BIRDS = false).
- Commit e6570f8 at 11:27, just before the 10:30 UTC update.
- Vault 'Rescuing a Weak Launch': 'Repeated title spam ([UPDATE] with no update). Players learn to ignore it.' *For us:* - Give the release gate (docs/RELEASE.md) a 'store truth' check: title tag, description and What's New against the live switches.
- Use an honest one-line title, and a description that leads with what the first 60 s deliver.
- **(high)** Every decision since 10 Nov was tuned on noise.

The sample sizes:
- Session_v1 had 45 visits in 72 h and only 11 on build 0.24.
- The visit records do not exclude the owner's own live test joins.
- They do not mark newcomer versus returning.

The pace:
- 6 builds went public in about 30 hours (0.20 to 0.25).
- Each changed dozens of things at once.
- So no build ever got a measurable cohort.

The repo's own vault says not to work this way: 'Avoid: Tuning on tiny samples. Get a few hundred sessions first'; 'Avoid: Shipping new content in week 1 while the onboarding leak is still open'; 'Changing everything at once. You will not know what worked'. *Evidence:* - V7_PLAN State: '45 visits ... 1 of 11 visits past 4 min'.
- SessionStats.luau: no owner/creator exclusion and no newcomer field; Studio is excluded only by the SessionStudio flag.
- git log: 136 commits from 19 Nov 09:13 to 20 Nov 11:27, and Config.Version 0.18.0 to 0.25.0 over the same span.
- Vault 'Rescuing a Weak Launch' and 'Launch Strategy - The First Two Weeks', TL;DR blocks. *For us:* - Freeze feature work.
- Ship one first-session change per build, with a funnel step for each.
- Leave out owner, collaborator and test accounts.
- Split new from returning visits.
- Collect a few hundred first sessions before judging. A small, fixed Sponsored campaign is a valid way to measure the funnel; ad users do not count for RFY ranking but 'can accelerate' consideration.
- Read medians only with n and the share still in at 60 s and 180 s.
- **(high)** The telemetry cannot answer 'why do they leave at 2 minutes'.

The AnalyticsService onboarding funnel still logs the 10 Nov game's steps:
- Joined, Spawned, FirstOwnToy, ReplayEnded, ThreeToys, SixToys, TenToys.

Session_v1 stores only:
- shots, hits, takedowns and egg flags;
- a lab flag;
- input and portrait;
- that funnel step.

The ~40 features built since are not logged when seen or used:
- the cannon and wrecking-ball steps, the UFO wow, the HUD reveal, experiments, surprises;
- cars, creatures, maps, events, the BIG RED BUTTON. *Evidence:* - OnboardingService.luau STEP_NAMES, lines 9-10 and 29.
- SessionStats.luau Record fields, lines 40-57.
- Metrics.* call sites: ProgressService 9; MoneyService/Metrics 2 each; one each in WorldMaps, WeaponShop, TrialService, StreamerService, ScheduleService, MinigameService, HordeService, ChristmasService, ChaseService.
- No calls in the v3-V7 systems: VehicleService, LabCreatures, OutdoorMaps, Surprises, Creatures, FirstVisit. *For us:* Before any redesign, log time-stamped server events for each visit:
- control;
- first shot and first takedown;
- each first-visit step;
- the first wow seen;
- the first window opened;
- the HUD reveal;
- the first machine and first vehicle;
- orientation measured at 10 s;
- the last 3 actions before leaving.

Rebuild the Roblox onboarding funnel around the new first minute. The new 10/10 plan must be judged on these numbers, not on blind-review scores.
- **(high)** On 0.24, most hooks were timed after most players had left:
- HUD reveal at 90 s, first wow at 110 s, first mission at 120 s;
- NEXT cards at 180 s and 25 takedowns;
- chase at 150 s, the first lab surprise at 150-240 s;
- favourite ask at 3 min or later, notification opt-in at 8 min or later;
- free ULTRA after 5 min, play gifts at 2/5/10/15 min.

The 90 s 'quiet start' was an over-reading of the research. BRP brings in its left column at about 60 s and shows WEAPONS, a bar and an objective at 0 s. Ragdoll Havoc held back almost everything, including the wow.

The audit scored area 1 '7.2 → about 9 (my estimate)' while the real median stayed near 2 minutes. On 20 Nov everything was moved inside 2 minutes; that build is unmeasured. *Evidence:* - Config.luau comments, lines 16-30 and 153-158: QUIET_START was 90, now 35; FIRST_WOW_AT was 110, now 45; EXPERIMENT_FIRST_AT was 120, now 40; NEXT_UNLOCKS_AFTER was 180, now 45.
- Shop.FREE_ULTRA_AFTER 300; NOTIFY_OPTIN_AFTER 480.
- AUDIT.md area 1 lines 46-94.
- RESEARCH_FIRST_SESSION §2.2 (BRP HUD at 0-45 s). *For us:* Design the first 60 s as the product. In order:
1. a dummy in front of you;
2. a first takedown within 10-15 s;
3. one big physics laugh, cannon or car, inside 45 s;
4. one visible next goal at all times.

Anything scheduled after 3 minutes is invisible to almost every player until the 180 s survival rate rises. Never self-score a first-session area: score it on the 60 s and 180 s survival shares.
- **(medium)** Much of what was built was probably never seen by a player.

'Probably' because nothing is logged:
- **Owner-only by design:** Admin V2 and Director mode, a whole V6 step each.
- **Multiplayer stack at 0 CCU in 6-player servers with private labs:**
  - Prank Party, party throws and toss combos;
  - plaza grab/throw;
  - the PortalService server list;
  - arena minigames.
- **Monetisation hidden because ids are 0:**
  - 20 zero ids in Shop.luau and 16 in Events.luau;
  - STARTER_PACK, GROUP_ID, 3 badges;
  - map-shop booths ('id 0 = no booth live'), LabControls and AllGuns.
- **Experience Notifications:** the opt-in comes after 8 min plus a wow; the dashboard strings were never created and there is no sender.
- **Behind MENU on phones (the majority):** 5 open-air maps, Sandbox/BUILD, Rewards and Places (PHONE_KEEP = Shop only).
- **NPC Talk:** works only where crowds exist (the maps, not labs).
- **Off or not yet live:** the Christmas lab and advent (from 1 Dec); the dead monitor (off by default); birds (built, polished three times, then removed). *Evidence:* - Config.luau lines 161-175.
- HudMenu.luau line 56: PHONE_KEEP = { Shop = true }.
- grep counts of zero ids: Shop.luau 20, Events.luau 16, Badges.luau 3.
- Shop.luau lines 50-53.
- V6_PLAN State line 219: notification strings and Open Cloud sender not set up.
- CLAUDE.md: 'labs have no crowd'.
- Games API: playing 0.
- Commits 197470f and e6570f8. *For us:* - Park the multiplayer and owner-tool tracks until there is traffic.
- Either create the product ids or delete the surfaces.
- Pick the 2-3 strongest existing moments, likely the cannon, a car hit and the gorilla, and put them into the first 60 s on a phone instead of in menus.
- Every new feature must state who sees it, in which second, on which device, and how that will be logged.
- **(high)** The roadmap was driven by the owner's visual punch lists and by internal quality gates, not by player data:
- V4 to V7 each turned one evening list (paths, a yellow light, birds, monster homes, admin, director, map shop) into a full '/klar' plan.
- The only data-driven change, moving the hooks earlier, came on the third /klar run of 20 Nov.
- The gates check that a step was 'seen in Studio', that LayoutCheck shows 0 and that a blind review passes. They never check a player metric.
- V7 shipped with reviews of 5.5, 4.0, 6.0 and 5.0, still under the 8.5 bar after 3 rounds.
- The cloud phases were written without being run: LayoutCheck found 551 problems on its first Studio run.
- The codebase is now about 93k Luau lines, 71 server systems, 83 client modules, 94 tests and 42 feature switches, for a game with 17 favourites. *Evidence:* - V4_PLAN, V5_PLAN, V6_PLAN and V7_PLAN item maps and State lines.
- V7_PLAN lines 253-319.
- V3_PLAN line 57 (551 to 0).
- wc of the .luau files; ls of the Systems, Client and Tests folders; Config switch count (42).
- Vault 'Roadmaps Milestones and Scope Control': 'Milestones defined by date -> Exit criteria anyone can check'. *For us:* The '10/10 version' needs a roadmap sorted by funnel stage: reach, then click, then the first 60 s, then the first 5 min, then D1/D7. Each milestone's exit criterion is a player number, for example: 60 s survival at or above 85 %, 180 s survival at or above 50 %, favourites at or above 5 %. Add a WIP limit, so that the owner's look requests queue behind the funnel work instead of each starting a new plan.
- **(medium)** A 'clarity' lesson was learned and then reversed. V3_PLAN's teardown of HRR's store page concluded that the leader 'wins on clarity: one clean floor, one sky, white dummies, and big readable physics moments', with 'close to zero text in the world'. Then the lab got denser:
- a garden and hedges (V6-4);
- a creature yard of 9 creatures with habitats (V6-5);
- 360-part gravel paths;
- cars, a throw tower, stations, portals and leaderboards;
- today's-machine signs.

At the same time the HUD and windows were redesigned 4 times: UI_V2, then LOOK_V3/HudV3, then UI_CLEAN, then BANNER_V7. *Evidence:* - V3_PLAN lines 296-315 ('The lesson').
- V6_PLAN State for V6-4 and V6-5.
- V7_PLAN V7-2 (paths: 360 parts per lab).
- Config UI_V2, LOOK_V3, UI_CLEAN and BANNER_V7 all true and stacked.
- AUDIT.md area 5: 'the machines were never moved into the zones'. *For us:* For the new version:
- one readable stage seen from spawn: dummies plus the 3 strongest machines;
- everything else one step away;
- one UI language, chosen once.

Cut rather than add.
- **(high)** Which research recommendations were implemented, and which were not.

**Implemented:**
- mild defaults (BLOOD off, no severing);
- a greeter dummy within 5 s;
- the first-visit objective line;
- WEAPONS with a Next bar;
- early unlocks (Bat 2, Crowbar 4);
- touch aim assist;
- a REWARDS window with streak and dare;
- daily experiments;
- the favourite ask after a wow, with no reward;
- the notification opt-in call;
- sound groups;
- the portrait HUD;
- What's New and an update-rhythm config.

**Not implemented (or only half):**
- honest thumbnails and thumbnail personalisation: the AI renders went live instead;
- an icon A/B swap;
- one badge per lab machine as BRP's hidden checklist, which reaches 40-66 % of BRP's new players: only 5 badges are live;
- the takedown badge ladder: ids 0;
- the group reward: GROUP_ID 0;
- the starter-pack chip: id 0;
- 'put a dummy IN the machine' and BULLSEYE objective steps: the audit left them open;
- a 3-slot start bar: SLOTS = 6;
- one big contextual phone button: the phone has SHOOT, GRAB, RUN, THROW, ZOOM and RAGDOLL;
- join time measured on a real phone: never;
- notification strings and update announcements every 3 days;
- a few hundred sessions before tuning;
- the KPI read after each release: SessionReport was run once. *Evidence:* - RESEARCH_FIRST_SESSION §3-4.
- RESEARCH_V4 §11 (12 ranked actions).
- AUDIT.md line 94 ('the steps are still "you ride the machines"... no BULLSEYE step').
- Toys.luau line 294 (SLOTS = 6).
- CLAUDE.md badges list.
- Shop.luau GROUP_ID and STARTER_PACK.
- Thumbnails/media API. *For us:* The cheapest proven rival mechanics are still missing:
- per-machine discovery badges;
- a takedown badge ladder;
- a group-join reward (allowed; likes and favourites are not);
- honest store art with an A/B test.

They cost owner dashboard time and little code. Do them before any new world content.
- **(low)** The 'most phone players hold the phone upright' finding, which drove the whole portrait HUD of Phase 0 and V3, may be a measurement artefact:
- SessionClient reads ViewportSize once, as soon as it is over 100 px (within about 2 s of client start), and never again.
- DevForum threads report that Roblox mobile starts loading in portrait and flips to landscape near the end of loading, and that ViewportSize changes between join and character load.
- The repo never sets ScreenOrientation, so the place file decides it (unchecked).

If portrait is real, most phone players see a third-person shooter through a window about 414 px wide. No top ragdoll game was verified to support portrait. *Evidence:* - SessionClient.luau lines 66-87: one Hello with w/h after the first viewport over 100.
- SessionStats.luau line 184: portrait = h > w, once.
- LayoutCheck.luau line 59: '95 % of phone visits hold the phone upright'.
- DevForum threads: 'Mobile players start the game in portrait mode', 'Camera.ViewportSize.Y changes on mobile devices between join and character loading', 'Edge case causes game to load in portrait mode even though StarterGui.ScreenOrientation is set to Landscape' (search snippets; page bodies did not load). *For us:* - Re-measure orientation at 10 s and on every change, and log time spent in each.
- Check StarterGui.ScreenOrientation in the place.
- If portrait players are real and bounce more, force LandscapeSensor (Roblox's default) rather than designing the 10/10 version around a portrait HUD.
- **(medium)** The toy names ('Popper', 'Big Popper', 'Rattler', 'Belt Buster', 'Rocket Tube') go further than the mild-content goal needs, and they work against the audience the game can reach today:
- BRP is rated Mild and uses 'Pistol'.
- HRR is rated Moderate and still qualifies for Roblox Select (ages 9-15).
- During the trial phase the game reaches only age-checked players aged 16 and over.
- The owner never confirmed TOY_NAMES; CLAUDE.md says 'Owner to confirm'. *Evidence:* - Toys.luau lines 109-123.
- CLAUDE.md Phase 0 owner decisions ('Owner to confirm').
- create.roblox.com content-maturity: 'Games with a Moderate rating are eligible for Roblox Select (ages 9-15)'.
- RESEARCH_FIRST_SESSION §2.2 (BRP loadout: Grab, Fists, Pistol).
- Games API: HRR, BRP and RR are not content-restricted. *For us:* Keep BLOOD off and no severing, but use plain generic names: Pistol, Revolver, Shotgun, SMG, Sniper, Minigun, Rocket Launcher. These are not trademarks and still fit Mild. Put the decision to the owner explicitly.
- **(medium)** The genre is a crowded, moderation-sensitive wave, and copying features is not an edge:
- Around 15 Nov Roblox pulled HRR ('under review'); it was back by 17-19 Nov and has 85k CCU today.
- Videos claim that BRP and Ragdoll Physics were also removed. BRP's page says its blood was 'reduced to comply'.
- About 10 near-identical rival sandboxes were created between 12 Oct and 3 Nov and update almost daily.
- HRR's 'Update 1' (14-21 Nov, with a countdown) added multiplayer quick-join and a server list, a gorilla, a bull, vehicles and smarter dummies. Ragdoll Havoc built the same list in V3-V4. *Evidence:* - hyper-realistic-ragdoll.wiki (15 Nov 2026) and YouTube 'Roblox BANNED 4 HUGE Ragdoll Games' (Nov 2026); unofficial sources.
- Games API, 20 Nov: HRR 85,345 playing, updated 19 Nov.
- allthings.how HRR events schedule (updated 10 Nov 2026).
- RESEARCH_FIRST_SESSION §1 table (creation dates).
- CLAUDE.md v3/v4 (gorilla, bull, cars, PortalService). *For us:* The mild-content decision is validated: keep it. The 10/10 version needs one sharp twist that can be shown in a 15-second clip and fits Mild, for example slapstick crash-test comedy or friend-tossing combos. It also needs a visible weekly countdown update. Adding the 20th gun or the 3rd creature will not set it apart.

**Sources:**
- Roblox Games API: Ragdoll Havoc + rivals (details, votes, thumbnails, media, icons) (https://games.roblox.com/v1/games?universeIds=10774775314,10773618503,10773926254,10773425091,2668101271), read 2026-11-20
- Roblox creator-docs: Roblox Kids and Select (kids-and-select.md) (https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/kids-and-select.md), read 2026-11-20
- Content maturity and compliance (Creator Hub) (https://create.roblox.com/docs/production/promotion/content-maturity), read 2026-11-20
- DevForum: Content Maturity is Minimal but still only locked on 16+ (and related threads) (https://devforum.roblox.com/t/content-maturity-is-minimal-but-still-only-locked-on-16/4675361), 2026 (mid-year)
- DevForum: Roblox Kids and Select Global Launch: Upcoming Updates to Eligibility, Ads Manager, and Expedited Review (https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717), 2026-06
- Roblox newsroom: Optimizing Discovery: How Great Games Reach Millions of Players on Roblox (https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox), 2026-06-15
- Dubit: What makes a new Roblox game take off? (https://dubit.io/library/what-makes-a-new-roblox-game-take-off), 2026-09-16 (updated 2026-09-23)
- Roblox Creator Hub: Discovery (https://create.roblox.com/docs/discovery), read 2026-11-20 (via search snippet)
- Hyper Realistic Ragdoll Wiki: Roblox Banned / Current Status (https://hyper-realistic-ragdoll.wiki/updates-and-availability/hyper-realistic-ragdoll-roblox-banned), 2026-11-15
- YouTube: Roblox BANNED 4 HUGE Ragdoll Games?… Why??? (https://www.youtube.com/watch?v=MXvWIf3mkhM), 2026-11 (exact date not visible)
- allthings.how: Hyper Realistic Ragdoll events schedule (https://allthings.how/hyper-realistic-ragdoll-events-schedule/), updated 2026-11-10
- newgamescout: Hyper Realistic Ragdoll (https://newgamescout.com/hyper-realistic-ragdoll), 2026-11-20
- bloxstack: Bloody Ragdoll Physics (https://bloxstack.app/games/140431845542654/Bloody-Ragdoll-Physics), 2026-11 (about 11 days old at search)
- DevForum: Mobile players start the game in portrait mode / ViewportSize changes between join and character loading / Edge case loads in portrait despite Landscape (https://devforum.roblox.com/t/mobile-players-start-the-game-in-portrait-mode/3020806), various (pre-2026)
- DevForum: Free Form User Creation 16+ / May 2026 weekly recap (https://devforum.roblox.com/t/free-form-user-creation-16/4687562), 2026-05/06
- LihFolk vault: Publishing an Experience; Discovery and the Algorithm (C:\Users\tristan\LihFolk-Vault-V2\LihFolk Vault V2\11 Monetization Publishing and Live Ops\Publishing an Experience.md), verified as of Oct 2026
- LihFolk vault: Rescuing a Weak Launch; Launch Strategy - The First Two Weeks; Viral Game Anatomy; Roadmaps Milestones and Scope Control (C:\Users\tristan\LihFolk-Vault-V2\LihFolk Vault V2\27 Marketing and Growth\Rescuing a Weak Launch - Empty Servers, Low CCU and Relaunch Tactics.md), Oct 2026
- Repo docs (RESEARCH_FIRST_SESSION, RESEARCH_V4, V3_PLAN, AUDIT, V4-V7 plans, CLAUDE.md, STORE_TEXT.md, Config/Toys/Shop/HudMenu/SessionStats/SessionClient/OnboardingService) (C:\Users\tristan\Documents\RagdollLab\docs), 19-20 Nov 2026

**Gaps:** **Platform pages that could not be read:**
- Reddit returned no usable results; site:reddit.com searches came back empty.
- TikTok was seen only through search-result titles and captions; no 2026 view counts were verified.
- DevForum page bodies came back empty through WebFetch. Every DevForum point above comes from search snippets.

**Not checked, because this task was read-only:**
- I did not open the owner's Creator Hub, so the Audience Reach status, current threshold, questionnaire answers, ID verification and 2FA are unconfirmed. The claim that the 16+ lock is the reach gate is strong but must be checked on the dashboard.
- I did not touch Studio, so StarterGui.ScreenOrientation and the place file are unchecked.
- I did not read the Session_v1 DataStore. All visit numbers are the repo's own summaries (45 visits / 72 h, 11 on 0.24).

**Numbers that conflict or are unverified:**
- The highly engaged threshold differs by source: 100 (docs), 250 (vault/docs), 500 (DevForum). Expedited review is 50k or 100k Robux depending on the source.
- The echo-heist RESEARCH_V3 file (BRP '2.5k to 21k CCU after its label change') is not local. Search found nothing confirming it; treat it as unverified.
- The HRR/BRP removal wave rests on a fan wiki and YouTube titles, with no official Roblox statement.
- The 'first play bounce rate' signal and its <60 s and 61-180 s windows come from Dubit's reading of the 15 Jun 2026 DevForum post; the Roblox newsroom post confirms only the signal groups.

**Not established:**
- I could not verify whether the top ragdoll games allow portrait play on phones.
- I could not tell who made the live AI-style thumbnails and icon, or when they were uploaded. Their ids are not in the repo.
- 'Never seen by players' is an inference from time gates, menu placement, zero ids and 0 CCU. No usage telemetry exists to prove it.

### Reddit-style player and developer research (via DevForum, Roblox APIs, trackers, Steam, guides; Reddit itself blocked): why players quit Roblox games in the first 2-5 minutes, what makes ragdoll sandboxes fun or boring, what the Oct-Nov 2026 ragdoll wave does, mobile, progression, monetisation, UI clutter, and growth lessons for Ragdoll Havoc
- **(high)** The ragdoll sandbox genre is booming right now, and it is being won by SOLO dummy sandboxes that launched in the same weeks as Ragdoll Havoc. The idea is proven. The gap is execution, the first minute, and presentation. *Evidence:* Roblox games API (20 Nov 2026):
- Hyper Realistic Ragdoll (HRR): created 2026-10-29, maxPlayers 1, 85,534 playing, 31.66M visits, 130,400 favorites.
- Bloody Ragdoll Physics (BRP): created 2026-10-31, maxPlayers 1, 18,509 playing, 29.6M visits.
- Ragdoll Physics: created 2026-10-12, maxPlayers 1, 44.4M visits.
- Ragdoll Havoc: created 2026-11-05, maxPlayers 6, 0 playing, 1,328 visits, 17 favorites.

Rolimons:
- HRR: all-time peak 200,997 CCU, average playtime 20.35 min, 90.5% rating.
- BRP: peak 62,907, average 11.58 min.
- Realistic Ragdoll Playground: peak 12,449, average 11.21 min.

ragdollsandbox.net: Rise To Top's solo 'Ragdoll Sandbox' went from 118,560 visits to 4.07M in one week (27 Oct to 3 Nov 2026). *For us:* Don't hunt for a new genre. Rebuild so it clearly beats HRR and BRP on first-minute feel and on being kid-safe. Set the target at the genre leaders' 11-20 min average playtime, not '5 min'. Move fast while the wave is weeks old; the HRR takedown also showed its players will jump to alternatives.
- **(high)** What the winners sell is hit reactions by body part: each body part reacts on its own, and a dummy gets a visible state. The ragdoll reaction is the product. Players reward 'realism of the reaction', not the number of weapons. *Evidence:* - HRR description: 'Real ragdoll physics: each body part reacts on its own'.
- newgamescout: shoot a leg and the dummy limps, break an arm and it hangs limp, a head hit makes it faint.
- AllThingsHow HRR guide (16 Nov 2026): the scan shows CONSCIOUS / DROWSY / OUT COLD / DEAD plus a BLEED rate.
- BRP: dummies 'stumble, beg, fight back' and fall the way they were hit; 'Every dummy is a real physics body'.
- Realistic Ragdoll Playground: 'Every hit is real physics'.
- A DevForum active-ragdoll sandbox drew praise for 'very fluid and responsive' characters, but was called 'a good tech demo' (Oct 2026). *For us:* Make each hit region give a distinct, readable reaction within about 0.1 s, kid-safe:
- leg: hop or limp;
- arm: dangles;
- head: dizzy stars, then knocked out;
- torso: double over or stagger.
Show a mild state word over the dummy (Dizzy / Wobbly / Out cold / Knocked out). Show this in the first 10 seconds, in the store video and in the thumbnail. ActiveRagdoll and MILD_TEXT already know the region; turn that into body motion, not just a text line.
- **(high)** Leaders hand new players a FULL toy bar on spawn and sell or unlock only the extras. Ragdoll Havoc starts with 3 tools and holds 69 weapons behind a kill grind. *Evidence:* - AllThingsHow HRR starter guide (16 Nov 2026): 'You begin with ten filled slots, so nothing needs buying first': Assault Rifle, Pistol, Shotgun, Golf Club, Physics Hand, Brick, Fists, Med Kit, Fire Extinguisher, Force Push. A test range of labelled dummies sits at spawn. Cash rises per knockdown; Revolver $750, Sniper $3,500, Grenade at 50 kills, 'R$ UNLOCK NOW'.
- Fling Things and People: 'no upgrades to your throwing arm' (earnaldo).
- DevForum (Jan 2026): lower early-game prices 'so players reach the more interesting gameplay sooner'.
- DevForum (2025): a 1k to 25k cost jump was flagged as a drop-off point.
- Ragdoll Havoc: Toys.DEFAULT_LOADOUT = G17, Grab, Punch, with a kill ladder to 69 weapons. *For us:* Spawn with 8-10 varied toys already on the bar:
- 2-3 guns;
- one explosive (grenade or C4);
- grab/throw;
- one launcher-type toy (gravity gun or force push);
- a medic/scan tool;
- one silly melee.
Keep the ladder for the other ~60, paid with a soft currency per knockout, with prices shown. The bar of toys is content, not clutter.
- **(high)** New players leave over menus and forced tutorials, not over toys. Several buttons on join feel overwhelming, forced tutorials feel forced, and a share of players quits before ever equipping a tool. Hiding the whole HUD to fix that hides the fun too. *Evidence:* DevForum 'what makes people leave this after 30 seconds' (30 Sep 2025):
- 'it was overwhelming seeing those many buttons as soon as you join';
- 'I saw a lot of gui that made me feel a bit overwhelmed';
- the developer suspected players were 'feeling forced to do the tutorial'.

DevForum (12 Oct 2025): '1 in 5 people leave before even equipping a tool'.

TechCrunch (26 Mar 2021), Gamefam on Speed Run Simulator: a 'significant increase in D1 retention when we removed the tutorial entirely'.

Ragdoll Havoc: the 20 Nov build holds the HUD until 35 s. *For us:* From frame 0, show the toy bar, the crosshair or SHOOT button, and nothing else. Hold back only shop, rewards, settings, map and offer tiles until after the first wow. Use no tutorial screens: a row of labelled test dummies right in front of the spawn is the tutorial. Measure 'equipped and fired within 10 s'.
- **(high)** Ragdoll games die at 'what now?' after the first knock or fall. Pure sandboxes run out of ideas quickly, so players need a stream of small goals and scores. *Evidence:* - DevForum 'Ragdoll Game Feedback' (7 Sep 2025; 3.70% D1, 6-7 min sessions): players 'leave right after the ragdoll fall', which 'could suggest a lack of post-fall engagement or goals'. Suggested fixes: leaderboards for highest damage, longest airtime and combo score, and short goals like 'Break X bones in one fall'.
- DevForum active-ragdoll sandbox (29 Oct 2026): 'I would love to see more objective-based gameplay'.
- People Playground Steam threads: 'you run out of ideas'; if you need a win condition 'this will feel empty inside two hours'.
- DevForum (Jan 2026, ~3 min playtime, ~1% D1): 'the main core game loop just wasn't engaging enough'. *For us:* Make Experiments the spine of the game, not a side card. Chain 30-60 s micro-challenges from the first knockout, for example:
- 'Launch a dummy into the bullseye';
- 'Knock 3 with one barrel';
- 'Longest airtime'.
Each gets a number (distance, airtime, combo) that feeds the lab boards. Always show one next challenge on screen, and never leave a dead gap of more than about 20 s.
- **(medium)** Dummies with their own behaviour are free, endless content: routines, fighting back, helping each other. This is where the leaders are investing next. *Evidence:* - HRR Update 1 (AllThingsHow, Nov 2026): dummies 'take cover, dodge, pull out lodged objects, revive each other, and remember the player', plus a gorilla and bull with animal events.
- BRP: dummies 'stumble, beg, fight back', plus NPC wars with team setup.
- Realistic Ragdoll Playground (Rolimons): dummies have routines 'such as mowing lawns or dancing', some fight back, and red barrels set off chain reactions. *For us:* Give each lab dummy a routine (sweeping, jogging, carrying boxes, dancing) and kid-safe reactions to the others:
- run to help a fallen friend;
- drag a friend away;
- pillow-slap back.
Other ideas: a 'dummy team battle' sandbox toggle, and chain-reaction props (barrels, dominoes, bowling pins). Ragdoll Havoc's flee/zigzag dummies are a start; social reactions make each session play out differently.
- **(medium)** A reversible medic/scan loop (hurt, look, fix, hurt again) is a core verb in the top game, not a hidden setting. *Evidence:* - AllThingsHow HRR guide: Med Kit on slot 8 'restores consciousness, repairs broken bones, and revives DEAD bodies'; Z opens an X-ray scan that names injuries.
- HRR sells an 'All Medic' pass for 69 R$ (Roblox game-passes API).
- Ragdoll Physics 2 lists a medical system (bandage, splint, defibrillator).
- Ragdoll Havoc: the dead monitor is off by default, and bodies revive by themselves after 10 s. *For us:* Put a kid-safe 'Doctor' tool on the starting bar:
- X-ray bones view with Dizzy/Out cold states;
- a 'Patch up!' fix with a funny bounce-back animation;
- the player revives the dummy, with auto-revive kept only as a slow fallback.
This doubles the verbs, gives a calm moment between explosions, and is easy to clip.
- **(medium)** Solo servers are the genre norm, and multiplayer comes as an opt-in second place. The big multiplayer exception, Fling Things and People, pays for it in griefing and a lower rating. *Evidence:* Roblox games API:
- maxPlayers 1 for HRR, BRP and Ragdoll Physics;
- also maxPlayers 1 for Rise To Top's Ragdoll Sandbox and Ragdoll Engine (2026) (ragdollsandbox.net).

HRR's 'Update 1 Multiplayer' used a separate 50-player sub-place (hyperrealisticragdollroblox.wiki), and the wiki notes 'complex ragdoll simulations place heavy demands on Roblox server physics replication'.

Fling Things and People: 25 players, 33,071 playing, 3.76B visits, the lowest rating in its comparison at 80.47% (earnaldo). Its fan pages describe griefing ('sticking' AFK players out of bounds) and plot protection ('you cannot be thrown while inside a house plot').

Ragdoll Havoc: server size 6 with a shared plaza. *For us:* Test a solo-first entry: the main place at maxPlayers 1, so each lab gets the whole server's physics and phones run smoother, with no strangers and no waiting. PortalMulti and Prank Party then lead into a separate social place. The trade-off is the 'intentional co-play days' signal, so keep invite-a-friend easy.
- **(medium)** Kid-safe content is a moat in this genre, and blood is a takedown risk. The biggest ragdoll game was pulled 'under review' at 150k+ CCU, and the field is visibly toning blood down. *Evidence:* - Fan wiki (15 Nov 2026): HRR 'has been removed from Roblox and is currently under review'.
- An X post: deleted 'with 150k+ ccu at the time of the deletion'.
- Speculated cause (unconfirmed): blood effects and the age rating. Several YouTube titles say 'Roblox BANNED 4 HUGE Ragdoll Games'.
- HRR is live again per the API (85k playing on 20 Nov).
- BRP's description says blood effects are reduced to meet Roblox moderation rules.
- HRR's label is reported as Mild with Blood and Violence.
- DevForum: one game was taken down over its maturity label, and a studio lost about 500 CCU after a label change.
- HRR also ran a 'FREE BOW + $2,500' board for liking the game page and joining the group (AllThingsHow). *For us:* Keep BLOOD off and SEVERING off. Fix the maturity questionnaire to the lowest honest label, and use 'no blood, all ages' as a selling line in the description and thumbnail; parents and kids looking for a safe HRR alternative are an open audience. Never put the blood-drop emoji in the name. Never reward likes (HRR's like-for-loot board is exactly what to avoid).
- **(medium)** The leaders sell a handful of permanent CATEGORY passes and one 'Everything' pass. Because the labs are solo, there is little pay-to-win harm. Per-weapon egg tiers are not what this genre buys. *Evidence:* Roblox game-passes API:
- HRR has 17 passes, including:
  - All Guns 99, All Melee 79, All Throwables 69, All Medic 69, All Powers 129;
  - Double KO 129, Endless Events 299, VIP 199, Lab Controls 69, Dummy Wardrobe 49, Demolition Pack 39;
  - Monster Truck 249, Battle Tank 399, Vehicle Pack 549;
  - Everything 699.
- BRP trimmed to 5 on sale: Everything 499, Sandbox 99, Arsenal 249, Injections 199, VIP 199. Thirteen older passes are off sale.
- Fling Things and People: 7 convenience passes (95-460 R$); earnaldo calls them 'a convenience'.
- Players dislike pay-to-win: Hacker News, 'almost all of the games seem to have a pay to win aspect'; Polygon on Steal a Brainrot, 'the best items are only available for cash'.
- Ragdoll Havoc: Weapon25/49/99/199 egg products plus ULTRA 249 and VIP 149. *For us:* Replace the weapon-egg tiers with 4-6 clear category passes:
- All Explosives;
- All Guns;
- Vehicles;
- Creatures/Events;
- Lab Tools;
- Everything at about 499-699.
Keep products only for one-off event triggers (Mega Bomb, Zero-G). One clean shop page, no egg odds needed.
- **(medium)** Pop-ups and prompts that break play annoy players openly. Some players say they downvote and report games that use them, and pop-ups also hit first-play bounce, a top discovery signal. *Evidence:* - DevForum feature request (23 Jun 2026): favorite, group and event prompts are 'abused and INTRUSIVE'. One player says there 'should be a way to block these popups' and that they will report and downvote games that use them.
- Fortune (20 May 2026): an advocacy complaint to the FTC targets Roblox 'manipulative design', meaning pop-ups and buy buttons.
- Roblox Discovery FAQ: 'first play bounce rate' is among the most important signals. *For us:* Set a hard ceiling:
- no favorite, notification, egg, offer or 'what's new' pop-up in the first 5 minutes;
- at most one ask per session, only after a wow moment, never covering the play area on a phone.
Notify.goodMoment and the LikePrompt gating are the right tools; tighten them to one per session.
- **(medium)** Phones dominate, and Roblox's default is landscape. Ragdoll Havoc's upright players most likely hold the phone that way because the game lets them, not by choice. Mobile complaints centre on small, overlapping or blocked buttons and on fire buttons that fight the camera. *Evidence:* Platform share:
- About 80% of Roblox DAU play on mobile (Roblox 2024 report via PocketGamer.biz and other stats sites).
- GameAnalytics 2025: PC+mobile 48.39%, mobile-only 7-10%.

Orientation:
- Roblox docs: the default LandscapeSensor means the game 'always appears in landscape mode (no portrait mode)'.
- Ragdoll Havoc allows portrait (Phase 0), and most phone visits are 414x814 portrait.

DevForum mobile complaints:
- buttons 'way too small to tap comfortably, or they overlap';
- buttons inside the joystick area cannot be clicked;
- 'a button to buy a knife stand with Robux was over the jump button on mobile' (14 Sep 2026);
- shooter threads: hold-to-fire must survive camera drags, and long-press input is 'too slow for a gun'. *For us:* Test forcing LandscapeSensor; on phones it roughly doubles the width of the 3D view for the dummies. Keep:
- tap-the-dummy-to-shoot plus one big hold-to-fire button that allows camera drag;
- nothing in the left 40% thumbstick zone;
- no Robux button near jump.
Record orientation in Session_v1 before and after to confirm.
- **(high)** The 2026 discovery system rewards first-session play-through and playtime. Gameplay video is now a measured lever. *Evidence:* Roblox Discovery FAQ: the most important signals are 'Play through rate, First play bounce rate, Play days per user, Playtime per user'; then co-play days, qualified play sessions, and spend. 'If retention is low, focus on core gameplay first.'

DevForum 'How we are improving Home this year' (9 Mar 2026, updated through 29 Jul 2026):
- a new 'deep play through rate' signal;
- '7-day qualified play sessions per user';
- gameplay videos autoplay on Recommended For You, with 'up to +39% increase in playtime from RFY' for games with video;
- a 'Standout Games' sort for novel games, with a nomination form;
- video rules: no cinematic trailers, voiceovers or promotional text. *For us:* After the rebuild:
- upload a real gameplay video (Creator Hub > Place > Videos) that opens on a body-part reaction and a cannon launch within 3 s;
- nominate the game for Standout Games if the kid-safe crash-test lab is the hook;
- track first-play bounce, not just the median.
- **(high)** A ~2-minute median visit puts Ragdoll Havoc in Roblox's 'casual bounce' band. The data shows a clear payoff for crossing into the 7-12 and 13-18 minute bands. *Evidence:* GameAnalytics 2025 Roblox report:
- 'Casual Users leave the experience in under 2 minutes';
- platform session P25 is 2.36 min;
- median D1 retention by session length: 4.31% (0-3 min), 6.20% (4-6), 7.91% (7-12), 10.24% (13-18);
- median ARPPU is $0.48 at 0-3 min and $1.21 at 13-18 min.

Genre leaders: 11-20 min average playtime (Rolimons).

Ragdoll Havoc: median about 120 s (Session_v1, 45 visits). *For us:* Use explicit gates for the rebuild:
- step 1: median of 7 min or more (the 7-12 bucket, about 8% D1 by these benchmarks);
- step 2: 12 min or more;
- the stretch goal is HRR's ~20 min.
Grade every first-session change against these, not against 'feels better'.
- **(medium)** Retention comes before ads, but 45 visits cannot measure retention. Developers also report that thumbnails move CCU more than gameplay updates. *Evidence:* - DevForum '15k visits, 4.3% CTR, near-zero retention' (14 Sep 2026): spending more on ads without retention is 'basically a leaky bucket'. Their best thumbnail got 'over 20,000 clicks'; the critique: 'thumbnails... so dark and washed out, no one will ever notice them'.
- DevForum (2025-26): one developer saw CCU rise after a new thumbnail, not after gameplay updates.
- DevForum 'This is how my game got on the algorithm' (Jul 2025): fixed weak metrics first, then ads.
- Ragdoll Havoc: 45 visits in 72 h; the '15 joined, 2 stayed' report is n=15. *For us:* Treat the current funnel numbers as directional only. After the rebuild:
- run a small, fixed ad burst to get a few hundred new sessions;
- read the Session_v1 funnel (first shot, first knock, first challenge, 3 min, 5 min, 10 min);
- iterate the thumbnail separately: bright, a dummy mid-flight, no bottom text.
- **(medium)** Leaders use the Roblox Events feature for an early scheduled update, and it pulls large opt-in interest. *Evidence:* AllThingsHow (10-13 Nov 2026): HRR's 'Update 1 Multiplayer & more' was 'the first scheduled event'. About 38,000 players marked it as one they plan to join, about two weeks after launch. It added 14 tools, aim-down-sights, bikes, quads and jeeps, a gorilla and a bull, and smarter dummies. *For us:* Ship the rebuild as a named Update with a Roblox Event card and countdown. Do the same for the Christmas Lab on 1 Dec, then keep a weekly or biweekly update rhythm. UPDATE_TITLE and WHATS_NEW already exist; make them public-facing events.
- **(low)** A distinct, instantly clear hook matters more than more features. A generic ragdoll title reads as 'another copy', and the wave's games all pitch 'realistic' or 'bloody'. *Evidence:* - DevForum 'Ragdoll Game Feedback' (Sep 2025): the title 'may make the game seem like a generic copy of Ragdoll Engine'.
- DevForum (Jan 2026): 'make a game that's unique but also quite easy to figure out what you're doing'.
- DevForum 'So your game died' (2023): find a niche; 'Before anything, you must think about if your game's concept is fun'.
- The wave's names: Hyper Realistic Ragdoll, Bloody Ragdoll Physics, Ragdoll Physics, Realistic Ragdoll Playground. *For us:* Own one clear angle: the kid-safe crash-test lab. Human cannon, launch pads, bullseye scoring, experiments and creatures, Broken-Bones-style scores (distance, airtime, combo) instead of gore. Put that one idea in the thumbnail, the first line of the description and the first 10 seconds of play. Keep 'Ragdoll' in the title for search.
- **(medium)** Grab-and-throw of other players is loved as social comedy, but needs consent and escape. *Evidence:* - earnaldo (15 Nov 2026) on Fling Things and People: it 'replays because the other 24 people in the server are the content'.
- Its passes include Farther Reach 460 R$ and Escape Faster 240 R$; escaping a grab takes 12 s, or 4 s with the pass.
- Its fan pages describe griefing and chat fights.
- It has a destructible map and slot machines that pay coins on a 15-minute cooldown. *For us:* Keep player-vs-player throws inside an opt-in party, with a short escape: wriggle in 2-3 s, never paid. Put the comedy in the party mode, and keep strangers out of each other's labs by default; Ragdoll Havoc's current rules already lean this way.

**Sources:**
- Roblox games API: Hyper Realistic Ragdoll (universe 10773618503) (https://games.roblox.com/v1/games?universeIds=10773618503), 2026-11-20 (live read)
- Roblox games API: Bloody Ragdoll Physics, Ragdoll Physics, Ragdoll Physics 2 (https://games.roblox.com/v1/games?universeIds=10773926254,10770575733,10771269188), 2026-11-20 (live read)
- Roblox games API: Ragdoll Havoc (10774775314) and Fling Things and People (2668101271) (https://games.roblox.com/v1/games?universeIds=10774775314), 2026-11-20 (live read)
- Roblox game-passes API: HRR, BRP, Fling Things and People (https://apis.roblox.com/game-passes/v1/universes/10773618503/game-passes?passView=Full&pageSize=50), 2026-11-20 (live read)
- Rolimons: Hyper Realistic Ragdoll (https://www.rolimons.com/game/101277003916102), 2026-11-20
- Rolimons: Bloody Ragdoll Physics (https://www.rolimons.com/game/140431845542654), 2026-11-20
- Rolimons: Realistic Ragdoll Playground (https://www.rolimons.com/game/75673503074101), 2026-11-20
- Hyper Realistic Ragdoll Starter Guide (Zones and Tools), AllThingsHow (https://allthings.how/?p=358267), 2026-11-16
- Hyper Realistic Ragdoll Update 1: Start Time and Countdown, AllThingsHow (https://allthings.how/hyper-realistic-ragdoll-events-schedule/), 2026-11-10 (figures as of 13 Nov)
- Hyper Realistic Ragdoll banned: status (fan wiki) (https://hyper-realistic-ragdoll.wiki/updates-and-availability/hyper-realistic-ragdoll-roblox-banned), 2026-11-15
- Hyper Realistic Ragdoll multiplayer guide (fan wiki) (https://hyperrealisticragdollroblox.wiki/guides/multiplayer/), 2026-11-15
- newgamescout: Hyper Realistic Ragdoll (https://newgamescout.com/hyper-realistic-ragdoll), 2026-11-20
- Ragdoll games on Roblox (2026): places and IDs, ragdollsandbox.net (https://ragdollsandbox.net/roblox/), 2026-11-03
- RoWatcher: Bloody Ragdoll Physics (https://rowatcher.com/games/10773926254/bloody-ragdoll-physics), 2026-11-20
- X post by Valra: 'Hyper Realistic Ragdoll just got deleted with 150k+ ccu' (https://x.com/ValraSwag/status/2122045577827381299), 2026-11 (from search snippet; page not readable)
- YouTube: Roblox BANNED 4 HUGE Ragdoll Games?... Why??? (https://www.youtube.com/watch?v=MXvWIf3mkhM), 2026-11 (title only; content not readable)
- DevForum: Ragdoll Game Feedback (https://devforum.roblox.com/t/ragdoll-game-feedback/3924157), 2025-09-07
- DevForum: Active Ragdoll Physics sandbox, feedback wanted (https://devforum.roblox.com/t/active-ragdoll-physics-sandbox-feedback-wanted/4891251), 2026-09-24 (replies to 2026-10-29)
- DevForum: Why are players leaving in the first 5 minutes? (https://devforum.roblox.com/t/why-are-players-leaving-in-the-first-5-minutes/4262028), 2026-01-16
- DevForum: Game's retention and average session time extremely low (https://devforum.roblox.com/t/game%E2%80%99s-retention-and-average-session-time-extremely-low/4269329), 2026-01-18
- DevForum: The age old question: what makes people leave this after 30 seconds? (https://devforum.roblox.com/t/the-age-old-question-what-makes-people-leave-this-after-30-seconds/3969002), 2025-09-30
- DevForum: My onboarding/analytics seem ridiculously bad (https://devforum.roblox.com/t/my-onboarding-analytics-seem-ridiculously-bad/4003426), 2025-10-12
- DevForum: 15k visits, 4.3% CTR, near-zero retention (https://devforum.roblox.com/t/15k-visits-43-ctr-near-zero-retention-%E2%80%94-what-am-i-missing/4871576), 2026-09-14
- DevForum: Let us disable non essential in-game prompts (https://devforum.roblox.com/t/let-us-disable-non-essential-in-game-prompts/4699372), 2026-06-23
- DevForum: Help improving game's average session time (https://devforum.roblox.com/t/help-improving-games-average-session-time/3981871), 2025-10-07
- DevForum: How we are improving Home this year (https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571), 2026-03-09 (updates through 2026-07-29)
- Roblox Creator Docs: Discovery FAQ (https://create.roblox.com/docs/discovery-faq), accessed 2026-11-20
- DevForum: Boost Your Discovery with the Improved Recommended For You Algorithm (https://devforum.roblox.com/t/boost-your-discovery-with-the-improved-recommended-for-you-algorithm-and-analytics-for-creators/3587441), 2025 (global release announced Dec 2025)
- GameAnalytics 2025 Roblox Benchmark Report (https://www.gameanalytics.com/cn/reports/2025-roblox-report), 2025 (page updated 2026-08-24)
- PocketGamer.biz: 80% of Roblox users are on mobile (https://www.pocketgamer.biz/80-of-roblox-users-are-on-mobile-contributing-46-of-robux-revenue/), 2025
- Roblox Creator Docs: Mobile input / ScreenOrientation (https://create.roblox.com/docs/reference/engine/enums/ScreenOrientation), accessed 2026-11-20
- DevForum mobile threads (Frustrated with Mobile UI Scaling; Mobile UI Feedback; How to fix guns for mobile devices) (https://devforum.roblox.com/t/frustrated-with-mobile-ui-scaling-and-need-advice/4403768), 2025-2026
- Launch vs Fling Things and People (2026), earnaldo (https://earnaldo.com/blog/launch-vs-fling-things-and-people), 2026-11-15
- Fling Things and People fan wiki pages (Anti-Cheat, house plots) (https://roblox-fling-things-and-people.fandom.com/wiki/Anti-Cheat), accessed 2026-11-20 (search snippets; page returned 402)
- Steam: People Playground discussions ('Game got boring', 'people playground has fallen') (https://steamcommunity.com/app/1118200/discussions/0/4327475903877616423/), 2024-2026
- TechCrunch: 5 mistakes creators make building new games on Roblox (Gamefam) (https://techcrunch.com/?p=2129906), 2021-03-26
- DevForum: So your game died... (game design and the market) (https://devforum.roblox.com/t/so-your-game-died-a-thread-on-game-design-and-the-market/2644450), 2023-10-13
- Fortune: Advocacy groups file complaint against Roblox over manipulative design (https://fortune.com/2026/05/20/exclusive-advocacy-groups-file-complaint-roblox-manipulative-design/), 2026-05-20
- Hacker News: Roblox is the biggest game in the world, but is unprofitable (https://news.ycombinator.com/item?id=41287099), 2024-08

**Gaps:** REDDIT WAS NOT REACHABLE.
- WebSearch refuses reddit.com outright ("domains are not accessible to our user agent").
- WebFetch answers "unable to fetch from www.reddit.com".
- Plain searches never surfaced a Reddit thread.
So there are NO direct Reddit quotes here. As the nearest substitute I used Roblox DevForum threads, read through Discourse .json, which worked, plus Steam discussions, Hacker News and news articles. A PC session with the owner's own browser could read r/roblox, r/robloxgamedev and r/RobloxDevelopers if Reddit evidence is required; I did not use the owner's Chrome.

OTHER GAPS:
- TikTok and YouTube page contents (video bodies, comments) were not readable; only titles and snippets.
- The Fling Things and People fandom wiki and NamuWiki returned 402/403, so FTaP griefing details come from search snippets.
- The reason HRR was taken down is unofficial speculation (blood, age rating). HRR is live again per the Roblox API (85k playing on 20 Nov).
- Average playtime figures come from Rolimons, a third-party tracker, not Roblox.
- HRR's starting hotbar, prices and the 38k Event interest come from AllThingsHow guides, which conflict on some details (the scan key, Update 1 dates).
- I did not verify maturity labels for HRR or BRP through an official API (the endpoint returned 404); 'Mild with Blood and Violence' for HRR is from a search snippet.
- The claim that portrait players are upright only because the game allows it is an inference from Roblox's landscape default, not measured. I did not check competitors' orientation by playing.
- There are no ragdoll-genre-specific retention benchmarks; the GameAnalytics numbers are platform-wide.
- Ragdoll Havoc's own data is very small (45 visits in 72 h; the owner's 15-joined report), so every funnel number is directional.
- No dev postmortem with before/after numbers from a ragdoll game was found; growth lessons are from general DevForum threads and Roblox announcements.
- All numbers are as reported by the cited source; none are invented, and estimates are marked as such.

### TikTok, YouTube Shorts and YouTube for Roblox ragdoll and physics games (2025-2026): which moments spread, which games creators play, how TikTok LIVE gift games work with Roblox, and what Ragdoll Havoc must build so players make and share clips and TikTok viewers find and stay in the game
- **(high)** The lab-and-dummies ragdoll niche is booming, and its leaders put each player in a 1-player server. Ragdoll Havoc already matches their feature list, so more features will not close the gap. What we lack is being found, plus clip moments the others do not have. *Evidence:* Hyper Realistic Ragdoll (HRR, created 29 Oct 2026):
- peak 200,997 concurrent players (CCU) about 15 Nov;
- 31.6M visits, 90.5% likes;
- average playtime 20.35 min;
- 1 player per server (Rolimons, read 20 Nov).

Its features:
- Body Scan X-ray;
- unlocks by KO count with a Next indicator;
- events, vehicles and animals;
- its Update 1 adds a gorilla and a bull, and multiplayer through a server list.

Other leaders:
- Bloody Ragdoll Physics (BRP): peak 62,907, 11.6 min average, 1 player per server.
- Ragdoll Sandbox by Rise To Top: created 16 Oct, peak about 31.4k, 13-14 min average, 1 player per server, rated Mild 9+.

Players online on 20 Nov (Roblox search API):
- HRR 86,415
- Fling Things and People 33,544
- Ragdoll Soccer 26,422
- BRP 18,687
- Realistic Ragdoll MMA 18,407
- Ragdoll Research 11,929
- Ragdoll Destruction Playground 10,545

Ragdoll Havoc (games API, 20 Nov): 0 playing, 1,328 visits in total, 17 favourites, server size 6. *For us:* - Stop adding weapons, animals or events to catch up: HRR's Update 1 is our v4.
- Spend the new version on what clips need: friend moments, the X-ray crack, sharing, and being found by name.
- Offer a one-tap SOLO LAB (the reserved server PortalService already has) for creators and streamers who want a clean shot with nobody walking in.
- Keep the 6-player plaza for friends.
- **(high)** A TikTok viewer who types our name into Roblox search does not find our game. Ragdoll clips always tell viewers to search by name, so this breaks the path from TikTok to Roblox. *Evidence:* - Roblox search for "ragdoll havoc", 20 Nov 2026: place 126037745825106 is not in the top 80 results. Result #1 is "Ragdoll Physics Havoc" (DozenGarlic, about 376M visits). The next 79 are other ragdoll games, often with a 🩸 in the name.
- TikTok captions in this niche always name the game: "GAME NAME - RAGDOLL SWORD BATTLES", "The name of this game is Ragdoll Universe", "Game: Advanced Euphoric Ragdoll", "Game:Ragdoll Football", "game name is ragdoll boxing 3d".
- On TikTok the link sits in the bio, so most viewers search by name (metaclip guide, via search).
- Creator Rewards' Audience Expansion pays only for new players who arrive by share link, direct link or a search for the game by name and then play 10+ min. *For us:* Three steps:
1. Owner decision: make the title searchable and distinct, for example add a unique word that no rival uses, and test search after each title change.
2. Put the name into every clip:
   - a big in-world sign on the cannon or the crash-test gantry, facing the default camera;
   - a small "RAGDOLL HAVOC" tag and the share code on the X-ray replay's end card.
3. Give the owner's TikTok bio a share link, so taps skip search.

Check the search rank in SessionStats and the release checklist.
- **(high)** Our clip and share code does not work, so even a great moment never reaches TikTok. *Evidence:* - **ReplayController.luau (about lines 286-291):** CLIP IT calls `CaptureService:StartVideoCaptureAsync(function(capture: any) ... PromptSaveCapturesToGallery({ capture }` ...). The Roblox docs say the callback gets (result, capture), and CreatorUI.luau uses `function(_result, capture)`. So CLIP IT passes the result enum as the clip, the save fails silently inside pcall, and no share is ever offered.
- **CreatorUI.luau:** sharing only happens from the CREATOR window (a launcher on PC, inside MENU on phones). It sends `PromptShareCapture(capture, "clip", ...)`, but no server code reads `LaunchData`; `GetJoinData` is only used for `SourcePlaceId`.
- **PolicyService:** no file checks it. A DevForum thread reports that shares are always denied without checking `IsContentSharingAllowed`.
- **Roblox API facts:** video clips stop at 30 s. `PromptShareCapture` opens the device's own share sheet with an invite link and launch data. Roblox's Moments post says games can trigger a capture automatically and prompt the player to share at peak moments. *For us:* Fix and redesign as 'auto-clip':
1. Correct the callback signature.
2. Check PolicyService before offering a share.
3. When a predictable wow moment fires (cannon shot to landing, nuke, toss combo, chimney), the X-ray replay already re-plays it. Record that replay, then show one big SHARE button.
   - On a phone it opens the share sheet straight to TikTok.
   - Most of our players hold phones upright, so the recording is already 9:16, the TikTok format.
4. Move SHARE out of MENU and onto the replay card.
5. Try `UICaptureMode.None` for video; it may not apply to video, so test it.
- **(medium)** Shared links can carry launch data that drops a friend straight into the moment from the clip. This fixes the gap between what a TikTok viewer saw and what the game shows them first. *Evidence:* - The Share Link API (`SocialService:PromptLinkSharingAsync`, DevForum) makes links that 'put them directly into a specific spot or moment within an experience', using JSON launch data.
- Dashboard share links can carry custom LaunchData 'to provide in-game perks', there is no limit on links per game, and each link has acquisition analytics (Roblox creator-docs).
- The older deeplinking beta limited LaunchData to 200 bytes, available on the first join only (2023; may be out of date).
- RoWatcher: viewers who click through from an accurate clip are 'pre-qualified'. Viral traffic bounces when the game does not match the clip. *For us:* - Put the existing ShareCode (toy + score) plus the machine id into launchData.
- On join, read `player:GetJoinData().LaunchData` on the server. For that player:
  - skip quiet-start pacing;
  - spawn them at that machine with that toy;
  - show a 'BEAT 412' target.
  Their first 10 s then repeat the clip they saw.
- Make one dashboard share link per channel ('tiktok_bio', 'creator_X') and log the link name in SessionStats, to compare D1 retention per source.
- Any perk stays public and cosmetic, and never stacks.
- **(medium)** Roblox now turns store-page videos and shared links into direct entry points for players. It is also testing ranking games by how many new players they bring to Roblox. A ready store page now pays more than before. *Evidence:* - **Roblox RDC press release (11 Sep 2026):**
  - store-page gameplay preview videos 'will start appearing in Moments';
  - by end of 2026, games can be joined in Chrome from a link: 'A shared link, anywhere on the web, becomes a direct path from discovery to play';
  - Roblox is 'testing optimizing for direct growth, measured by how many new players a game brings to the platform'.
- **Roblox newsroom (28 Jul 2026):** each Moments clip has a Join button. Discovery is for age-checked players 16+ (fully live in the US).
- **Roblox docs (via search):** an approved video shows first on the game page; consoles and VR do not show video thumbnails.
- **Our page (fetched 20 Nov):** one image visible, no video, title "[EVENT] RAGDOLL HAVOC". *For us:* Before any TikTok push:
- Upload an honest gameplay video as the first item. Show the clip moment within the first seconds: cannon, impact, X-ray CRACK, number.
- Make 3-5 16:9 thumbnails of the same moments the TikToks show.
- Open the description with the verb ('Launch crash-test dummies out of a cannon').
- Keep 'no blood, all ages'.
- Put share links in the TikTok bio, and get ready for browser play (the link then skips the app install).
- **(medium)** A TikTok spike is short. If new players leave fast, the spike can hurt our ranking for weeks. The first session has to hold before we push. *Evidence:* - RoWatcher:
  - concurrent players rise for 24-72 h after a viral moment, then D1 'craters';
  - low-retention viral traffic hurts discovery for 'several weeks, sometimes longer';
  - have D1 of about 25-30% on normal traffic before taking a viral spike.
- Rolearn trend report (24 Oct 2026): 'a viral TikTok can drive a game from zero to 100,000 CCU in under 48 hours', and it usually fades within days.
- Our data (Session_v1, 72 h): median visit about 120 s, 1 in 11 past 4 min.
- Audience Expansion needs 10+ min of play.
- RDC 2026 extends the ranking window to 28 days. *For us:* - Order: fix the first session, then clips and the store page, then creators and TikTok.
- Gate: 'no paid or creator push until D1 ≥ 25% and median first visit ≥ 5 min'.
- The first 10 s after join must show the clip moment (cannon in view, one tap to fire). From there, chain the friend and the next goal.
- **(medium)** In late 2026 the ragdoll clips that spread most are friend-versus-friend 'big hits' (ragdoll football, soccer, MMA, boxing), cut fast to phonk music and captioned 'play with your friends'. Solo dummy clips are second. *Evidence:* - Players online on 20 Nov: Ragdoll Soccer 26,422, Realistic Ragdoll MMA 18,407 (an X post from IDK Stats says it peaked near 40k), Ragdoll Wars 7,968, Technical Ragdoll MMA 4,929 (Roblox search API).
- Ragdoll Football: big-hit and tackle clips, 'phonk-edited viral game clips', about 8.7k peak by mid-October 2026 (search summary of a fan wiki; weak source).
- One Ragdoll Robot Boxing clip has about 199K likes (TikTok search summary, unverified).
- Common captions: 'MUST PLAY GAME WITH YOUR FRIENDS', 'FUN ROBLOX GAME TO PLAY W FRIENDS', 'Holy hit'.
- Rolearn: games need 'moments that are visually striking, surprising, or absurd enough to stop a scroll'.
- Fling Things and People (33.5k online): a person flying across the map is 'a perfect short video' (vault teardown). *For us:* - Make the friend hit the headline clip, not a side mode:
  - throw your friend into the cannon or bullseye (TOSS COMBO already exists);
  - add a plaza 'tackle' or shove with a 1-frame hit-strength number and a slow-mo payoff;
  - a short 2-6 player plaza mini-game (tackle tag, or knock the friend into the target) gives repeatable 15 s clips.
- Show the invite button right after any friend moment.
- **(medium)** X-ray bone breaking is a proven hook for video titles and clips, and it stays kid-safe because it shows bones, not blood. Our X-ray replay is our best clip asset, but it does not yet end on a frame ready to post. *Evidence:* - A YouTube video is titled 'This Roblox Physics Game Has X-RAY BONE BREAKING...'.
- HRR's Body Scan is an X-ray view of broken bones.
- Bone games: 'Break your Bones' pays per broken bone with on-screen pop-ups; Broken Bones IV still has 978 players online.
- Other YouTube titles: 'I BROKE ALL MY BONES...', 'Roblox Ragdoll BUT I BREAK ALL My Bones'.
- Ragdoll Playground binds slow-mo to G because flings are too fast to read (bloxodes wiki).
- Clip rules: most viewers drop in the first 2 s, so lead with the action already moving, no menus. 15-30 s clips are said to do best on TikTok (Eklipse blog, Apr/May 2026; numbers unverified). *For us:* Build the X-ray replay as a ready-made TikTok:
- start about 1.5 s before impact;
- slow-mo only on the impact;
- at most about 12 s;
- end on a still card with a big number ('CRACK! 412 · 7 BONES'), the game name tag and the share code, which loops cleanly back to the start;
- text kept in the safe middle area, nothing at the bottom or right where TikTok's buttons sit.

Keep MILD_TEXT and no blood.
- **(high)** No outside TikTok LIVE streamer can use our Streamer Mode, because private servers are switched off for our game. *Evidence:* - `StreamerService.mayStream` returns false unless `game.PrivateServerId ~= ""` and the player owns that private server (or is the game creator).
- The live game has `createVipServersAllowed: false` (games.roblox.com API, 20 Nov 2026). So outside streamers can never turn on the gift keys F1-F8.
- The PortalService 'Solo' reserved server has no private-server owner, so a streamer there fails the check too.
- Precedent: +1 Speed Keyboard Escape (peak 7.26M CCU per the vault teardown) has a TIKFINITY button in its top bar:
  - a green on/off toggle;
  - default hotkeys K chicken, L super slow, H banana slip, M tiny, N invisible, plus earthquake, disco, explode and jail;
  - every key can be rebound;
  - the effects are cosmetic or slow the streamer down, and never raise Speed or Wins (nerdschalk, updated 3 Jul 2026).
- TikFinity sends keystrokes into any game on a Windows PC, and a 10-gift combo fires the action 10 times. *For us:* - Allow LIVE mode in a reserved Solo lab when the player is alone in it, and/or turn on free private servers on the dashboard (owner).
- Give it a clear 'LIVE MODE' entry (PC; no brand name in the button) that shows the key list and the GIFT GUIDE card.
- Make streamer-targeted effects the core: fling the streamer, tiny, slow, banana slip, dummy rain on the streamer. Viewers playing the villain is what makes these streams fun.
- Keep the owner rule: nothing from LIVE is saved or counted (`NoCredit`), and the existing pacing queue handles combos.
- **(medium)** TikTok LIVE gift games work best with instant, fixed, visible effects; two sides pulling against each other; likes so non-gifters can join in; and short rounds with big finishes. Gifts that buy a chance at something are a policy risk. *Evidence:* - TikLive Games summary of TikTok rules (3 Nov 2026):
  - LIVE Studio help: 'Interactive Games lets viewers influence the game you are playing by sending Gifts that trigger in-game effects';
  - LIVE guidelines: 'Do not promote gambling', creators should stay present, no QR codes or third-party info on screen;
  - only users 18+ can send or receive gifts.
- Streamline Agency (7 Oct 2026): gifts may trigger only in-game actions, with no off-platform promises. Scale small gifts to small effects and show on screen what each gift does.
- ScrollPlay (29 Sep 2026):
  - tug-of-war climb is its 'most-streamed format';
  - other formats: 'beat the bomb' and red vs blue;
  - 'likes and follows can fire actions too, so everyone watching can take part';
  - 'Short rounds, big finishes'.
- Crowd Control added official TikTok LIVE support in 2025 (gifts, likes, follows and shares trigger effects).
- All of these are vendor sources; I did not read TikTok's own policy text. *For us:* Add 2-3 built-in LIVE formats on top of the 8 gift keys:
- **SAVE vs SEND:** a big on-screen bar where one gift key lifts a dummy to safety and another drags it to the cannon; at the end it launches or is saved.
- **BEAT THE BOMB:** a nuke countdown that gift keys speed up or slow down.
- **LIKE GOAL:** TikFinity maps likes to a key, and every N presses fires a big event.

Also:
- No random wheels, eggs or loot per gift.
- Never show TikTok names (no free text).
- The GIFT GUIDE card stays visible in LIVE mode.
- **(medium)** Moderation is volatile for gory ragdoll games. Several top ones went offline for days in mid-November. A kid-safe ragdoll game can sell its safety and be the safe pick. *Evidence:* - **About 15 Nov 2026:** HRR (an X post says it had 150k+ players at deletion; a fan wiki says about 200k) was marked 'unavailable / under review'. YouTube Shorts reported BRP, Ragdoll Physics and others removed, for '50 million combined visits', with no reason from Roblox.
- **Suspected cause:** fan wiki and community speculation point to violent or blood content, plus attention from short-form clips. This is unconfirmed.
- **Back up:** by 20 Nov, HRR (86k) and BRP (18.7k) are live again (Roblox search API).
- **BRP's own page:** 'Blood effects have been reduced to comply with Roblox's content moderation guidelines.'
- **A clone sells safety in its title:** '[FREE VIP AND ALL AGE🌟] Bloody Ragdoll Physics 🩸'.
- **Creators covered the takedowns:** 'Hyper Realistic Ragdoll is GONE… play these instead'. *For us:* - Keep BLOOD off, SEVERING off and TOY_NAMES on.
- State it on the store page and in clips ('cartoon stars, no blood, all ages').
- Redo the maturity questionnaire.
- Pitch Ragdoll Havoc to the creators who made 'play these instead' videos as the safe alternative.
- Avoid realistic gun names and visuals in thumbnails and clips: viral reach brings reviews.
- **(low)** On YouTube, codes videos and 'I tested / I played for 24 hours' formats get the most views, and paying mid-size creators is cheap. A creator video can bring players within hours. *Evidence:* - Rolearn report (24 Oct 2026, data to 5 Mar 2026):
  - codes/secrets videos have the highest average YouTube views, about 320K;
  - '24 hours' endurance videos are growing;
  - flat-fee creator deals run $500-$5,000 per video;
  - brainrot and meme edits have the highest TikTok engagement (11.3%).
- RoWatcher: one small game rose from 233 to 878 CCU within 60 min of a creator promotion.
- YouTube titles in this niche: 'TESTING WEAPONS IN ROBLOX RAGDOLL SANDBOX!', 'I Tested Roblox REALISTIC Ragdoll Engine...', plus many 'ALL WORKING RAGDOLL SANDBOX CODES' videos.
- Ragdoll Sandbox runs codes (MILITARY, TANKS, JETS).
- Moments now shows select creators' videos that link straight to the game (Roblox newsroom, Jul 2026). *For us:* Once retention passes the gate:
- Release a code for everyone on each update day (never tied to likes).
- Keep docs/CREATOR_KIT.md as a public creator page with the 3 clip formats, the codes and a SOLO LAB how-to.
- Contact 3-5 mid-size ragdoll or Roblox Shorts creators (one share link each), and track D1 per link.
- **(medium)** Roblox players already record and post clips in huge numbers. Our job is to create the moment and offer a one-tap share, not to teach players how to record. *Evidence:* - Medal Gaming Insights 2025 (9 Dec 2025): Roblox was the most-clipped game, with 342M clips from January to October 2025.
- RDC 2025 (via search): 930M screenshots and 240M+ video captures since Roblox launched its video tools in July 2025.
- Roblox Replay 2025: 1 in 5 game-related TikTok videos posted in Jul-Aug 2025 mentioned Roblox.
- Moments: posting is for users 13+, discovery for age-checked users 16+.
- The Upload and Recommendations APIs are 'now available to all' (David Baszucki on X). Moments is not available in some countries, such as the UK (DevForum replies). *For us:* - The SHARE button after an auto-replay is the main growth feature, more important than another weapon.
- Later: for eligible players (policy checks), add 'POST TO MOMENTS' through the Upload API, and an in-lab 'Best launches today' wall through the Recommendations API. Roblox moderates that content.
- Under-13s get save and share only, as the platform allows.
- **(low)** Friends as props is a proven hook: 'I launched my best friend out of a cannon' works even when the friend is offline, and it ends with an invite. *Evidence:* - Very Realistic Ragdolls: 'pick someone from your friends list and spawn them as a ragdoll with their full avatar', then blow them up or drop a piano on them. It also lists 100+ weapons and 13 vehicles.
- Fling Things and People: people are the props, 'within a minute you have flung, been flung, and laughed' (vault teardown).
- The CreatorKit 'Friend launch prank' format needs two players online today.
- Our crowd already wears real Roblox clothes (CrowdService). *For us:* - Add 'LAUNCH A FRIEND': pick from your Roblox friends list. A ragdoll copy wears their avatar, with no name text (owner rule), and the cannon, traps and toss combo all work on it.
- Then offer the share sheet with the challenge launchData: 'You got launched. Join and get revenge.'
- Kid-safety: friends list only and cartoon effects only. Check the bullying angle against Roblox Community Standards before shipping.
- **(medium)** There are clear rules for how short clips are made. Our replay and the owner's own posts should follow them by default. *Evidence:* - **Vault (Short-Form Video Marketing):**
  - hook in the first 1-2 s;
  - no logo or title card first;
  - text in the safe middle, not the bottom or right edge;
  - no real player names visible;
  - a UI-hide toggle and free camera;
  - a clip runs hook (0-2 s), then context, then payoff (6-15 s), then a loop.
- **Eklipse (Apr 2026):** completion rate is the strongest signal. Put the game name in the first caption line and the hashtags. Post 5-7 clips a week. The numbers are vendor estimates.
- **Our tools:** CREATOR MODE (U) hides UI, and the Director (F8) gives the owner a 9:16 frame. *For us:* - Bake these rules into the auto-replay:
  - framing starts on a body already in the air;
  - no HUD;
  - captions placed in the TikTok safe area;
  - the end card loops back;
  - other players' names hidden in replays.
- Owner routine: 3-5 clips a week from the Director's 6 one-tap shots, each with the share code and the 'Game: <name>' first caption line.

**Sources:**
- Hyper Realistic Ragdoll - Rolimons (https://www.rolimons.com/game/101277003916102), read 2026-11-20
- Bloody Ragdoll Physics - Rolimons (https://www.rolimons.com/game/140431845542654), read 2026-11-20
- Ragdoll Sandbox (Rise To Top) - Rolimons (https://www.rolimons.com/game/113398609378596), read 2026-11-20
- Ragdoll Sandbox - Rotrends (https://www.rotrends.com/game/10771155665/Ragdoll-Sandbox), read 2026-11-20
- Roblox omni-search API: query 'ragdoll havoc' (pages 1-2) and 'bloody ragdoll physics' (https://apis.roblox.com/search-api/omni-search?searchQuery=ragdoll%20havoc&pageType=all), fetched 2026-11-20
- Roblox games API - universe 10774775314 (https://games.roblox.com/v1/games?universeIds=10774775314), fetched 2026-11-20
- Ragdoll Havoc store page (https://www.roblox.com/games/126037745825106), fetched 2026-11-20
- CaptureService (Engine API reference) (https://create.roblox.com/docs/reference/engine/classes/CaptureService), read 2026-11-20
- [Beta] Video Captures API: Bring Your Gameplay Moments to Life (DevForum) (https://devforum.roblox.com/t/beta-video-captures-api-bring-your-gameplay-moments-to-life/3823116), 2025 (search snippets; page did not render)
- Captures APIs are now available! (DevForum) and PromptShareCapture docs (https://devforum.roblox.com/t/captures-apis-are-now-available/2838188), 2024 (search snippets)
- Share links (Roblox creator-docs on GitHub) (https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/share-links.md), read 2026-11-20
- Introducing the Share Link API: Deep Link Players Directly Into the Action (DevForum) (https://devforum.roblox.com/t/introducing-the-share-link-api-deep-link-players-directly-into-the-action/3972678), 2025 (search snippets)
- Roblox announces short-form video feed for gameplay clips (TechCrunch) (https://techcrunch.com/2025/09/05/roblox-announces-short-form-video-feed-for-gameplay-clips-new-ai-tools-for-creators-and-more), 2025-09-05
- Moments: More Ways to Discover Your Next Favorite Game on Roblox (Roblox Newsroom) (https://about.roblox.com/newsroom/2026/07/moments-new-homepage-unlocks-gaming-for-all), 2026-07-28
- Roblox Unveils New Ways to Play, Build, and Grow at RDC (Roblox IR) (https://ir.roblox.com/news/news-details/2026/Roblox-Unveils-New-Ways-to-Play-Build-and-Grow-at-the-Roblox-Developers-Conference-RDC/default.aspx), 2026-09-11
- RDC 2026: What It Actually Means for Solo Roblox Creators (Panstag) (https://www.panstag.com/2026/09/rdc-solo-creator-guide.html), 2026-09
- Content Sharing APIs beta (DevForum) / David Baszucki post on X (https://devforum.roblox.com/t/beta-content-sharing-apis-use-upload-api-and-recommendations-api-to-drive-discovery-and-engagement/4065417), 2025-2026 (search snippets)
- How do I make money? / Creator Rewards (Roblox docs, DevForum) (https://create.roblox.com/docs/get-started/monetization), 2025-2026 (search snippets)
- Why Your Roblox Game Goes Viral on TikTok and Dies on Platform (RoWatcher) (https://rowatcher.com/news/why-your-roblox-game-goes-viral-on-tiktok-and-dies-on-platform), undated (2026)
- Roblox YouTube & TikTok content trends 2026 (Rolearn) (https://rolearn.dev/trend-reports/roblox-youtube-tiktok-content-trends-2026), 2026-10-24
- How YouTubers and TikTokers Move the Charts in 2026 (RoWatcher) (https://rowatcher.com/news/how-youtubers-and-tiktokers-move-the-charts-in-2026), undated (2026)
- Roblox YouTube Shorts strategy / TikTok algorithm for gaming (Eklipse blog) (https://blog.eklipse.gg/beginner-guide-2/tiktok-algorithm-gaming-creators.html), 2026-04-27 and 2026-05-04
- TikTok LIVE Gift Games: What TikTok's Rules Say (TikLive Games) (https://tiklivegames.io/articles/tiktok-live-gift-game-rules), 2026-11-03
- Interactive TikTok LIVE gaming guide (Streamline Agency) (https://streamlineagency.eu/guides/live-gaming-interactif-tiktok?lang=en), 2026-10-07
- TikTok LIVE Game Ideas: 14 Interactive Formats (ScrollPlay) (https://scrollplay.live/guides/tiktok-live-game-ideas), 2026-09-29
- How to enable TikFinity in +1 Speed Keyboard Escape (Nerdschalk) (https://nerdschalk.com/how-to-enable-tikfinity-in-1-speed-keyboard-escape-roblox/), 2026-07-03
- TikFinity (official site and setup blog) (https://tikfinity.com/), 2026
- Crowd Control officially supports TikTok LIVE (X) (https://x.com/CrowdControl/status/1918030979786252536), 2025
- Hyper Realistic Ragdoll Roblox Banned: Current Status (fan wiki) (https://hyper-realistic-ragdoll.wiki/updates-and-availability/hyper-realistic-ragdoll-roblox-banned), 2026-11-15
- Roblox BANNED 4 HUGE Ragdoll Games?… Why??? (YouTube) (https://www.youtube.com/watch?v=MXvWIf3mkhM), 2026-11 (search snippet)
- Bloody Ragdoll Physics store page (https://www.roblox.com/games/140431845542654/Bloody-Ragdoll-Physics), fetched 2026-11-20
- Hyper Realistic Ragdoll Update 1 (allthings.how) and HRR guide (newgamescout) (https://allthings.how/hyper-realistic-ragdoll-events-schedule/), 2026-11-10 / 2026-11-20
- Very Realistic Ragdolls store page (https://www.roblox.com/games/107751141760658/Very-Realistic-Ragdolls), fetched 2026-11-20
- TikTok captions found by search (muscledevsofficial, mrpikachu_06, baconprodgoat, mrboo79, brody.gio, rokkorblx) (https://www.tiktok.com/@muscledevsofficial/video/7535673898709290295), 2025-2026
- This Roblox Physics Game Has X-RAY BONE BREAKING... (YouTube) (https://www.youtube.com/watch?v=OKrqbbAkgH4), 2026 (search result)
- Medal Gaming Insights Report 2025 (https://medal.tv/blog/posts/medal-gaming-insights-report-2025), 2025-12-09
- The 2025 Roblox Replay: Decoded Through Search and Style (Roblox Newsroom) (https://about.roblox.com/newsroom/2025/12/roblox-replay-decoded-search-style), 2025-12
- Ragdoll Playground wiki (bloxodes) (https://bloxodes.com/wiki/ragdoll-playground), 2026
- LihFolk vault: Short-Form Video Marketing; Teardown - +1 Speed Keyboard Escape; Viral Game Anatomy (C:\Users\tristan\LihFolk-Vault-V2\LihFolk Vault V2\27 Marketing and Growth\Short-Form Video Marketing.md), vault, as of Oct 2026
- Repo code read (read-only) (C:\Users\tristan\Documents\RagdollLab\StarterPlayerScripts\StarterPlayerScripts\Client\ReplayController.luau), 2026-11-20

**Gaps:** **What could not be read:**
- TikTok pages return no text, only titles in search results. TikTok evidence is limited to captions and search summaries: no view counts, no trend lines and no per-clip watch data.
- Reddit was not reached: the earlier v4 research found its crawler blocked, and this session ran out of searches before any Reddit-specific query.
- YouTube video pages redirect to a consent wall from Denmark, so video titles and dates come from search results only.
- DevForum announcement pages (Moments, Video Captures, Content Sharing APIs, Share Link API) did not render. Their details come from search snippets and the Roblox docs pages that did load.

**Unconfirmed claims:**
- Whether the video share sheet works on every device, and whether `UICaptureMode.None` applies to video. Test both in a live build.
- The 200-byte LaunchData limit comes from a 2023 beta post and may be out of date.
- Why HRR, BRP and Ragdoll Physics went down in mid-November. All reasons are community speculation. HRR and BRP were live again on 20 Nov.
- TikTok LIVE policy points come from vendor summaries; I did not read TikTok's own LIVE Studio or Community Guidelines pages.
- Whether Roblox explicitly allows gift-to-game links. No official ruling turned up.

**Numbers that need care:**
- Tracker and API player counts are snapshots from 20 Nov 2026.
- Rolimons 'average playtime' is probably a mean, so it does not compare one-to-one with our Session_v1 median.
- Vendor and blog figures (Eklipse completion thresholds, rolearn engagement and deal prices, the 199K-like boxing clip, Ragdoll Football peak) are unverified estimates.

**Not checked:**
- What the 'Crowd Control' game pass in Ragdoll Sandbox does.
- Which named big creators (KreekCraft, Flamingo and others) covered ragdoll games in 2026. None did in what I found.

**Budget:** the session's shared web-search limit was hit near the end, so no further TikTok-specific queries for Hyper Realistic Ragdoll were run.

### Ragdoll Havoc 2 to 10: vault research for a full rebuild (FTUE, retention, feel, ragdoll networking, phones, compliance, case studies, marketing, level design, testing)
- **(high)** The first minute has to pay out a reward and a next goal before the median player leaves. Ragdoll Havoc's median visit is about 120 s and almost nobody passes 4-5 min, so the first reward and the first next goal must land inside 60 s, and a core-loop completion must happen 3 or more times in 5 min. *Evidence:* Onboarding and FTUE note: first meaningful action 10-20 s, first reward under 60 s (reference project aimed for 40 s), core-loop completions in 5 min 3 or more, whole tutorial under about 3 min. FTUE note: first verb by 30 s, first big reward by 40 s. Discovery note: 'First 60 seconds: player acts and gets rewarded without reading'. *For us:* Make the first egg/gift or the first takedown reward fire by about 40-60 s (the owner's 35-45 s HUD and mission hooks are in the right window but unmeasured). Put 3 quick loop closes (shoot, takedown, reward) into the first 5 min. Keep the first session to one visible next goal, not a list.
- **(high)** Pop-ups and tutorial text are the first-session killers. Ragdoll Havoc has many stacked prompts (egg card, LikePrompt, mission, next-weapon cards, hint toasts), which the vault says to gate away from the first minutes. *Evidence:* Discovery note: 'No pop-ups in the first minutes of a first session', 'Pop-ups: daily reward, group prompt, starter pack on join' listed as bounce causes. Retention note TL;DR: at least one 'ready' thing on every join, never more than one automatic pop-up at a time. Tutorial Step Design note: one focused step at a time, objective 8 words or fewer. *For us:* Run a single notification queue: at most one auto pop-up at a time, none before the first takedown or 60 s, objective text under 8 words. Remove any prompt (LikePrompt, favourite ask) that can appear in the first 3 min.
- **(high)** Discovery penalises sessions that bounce under 60 s and those between 61-180 s. A median of 120 s sits in the worst band, so the goal for the rebuild is a visible reason to stay past 3 min, not a longer tutorial. *Evidence:* Onboarding and FTUE note, citing Roblox docs Discovery: first-play bounce is negative under 60 s and at 61-180 s. Discovery note: 'Join time measured on phone'. Core Loops note: a loop that brings players back on 5 separate days beats one long binge; playtime counts up to 60 min per user per day. *For us:* Target median first visit above 180 s as the first KPI (Session_v1 already logs this). Give a reason to stay at 2-3 min: a timed event, a tough lab stage or a Prank party card. Plan a D2 hook (calendar, daily goal) because play days 2-7 feed ranking.
- **(high)** Teach by doing with one verb and a server completion signal, and let the first grab or shot teach the mechanic. Ragdoll Havoc already has first shot in 3-17 s, which the vault treats as the good pattern. *Evidence:* Viral Game Anatomy: 'let the first tap, step or grab teach' (avoid a tutorial before the first action). Fling Things teardown: 'Someone grabs you. You learn the escape mechanic by needing it.' Tutorial Step Design: step done must come from the server system, not the client. *For us:* Keep the first shot as the teacher. Cut any text-based onboarding screens and replace them with one-line world prompts that clear on the server event (takedown, egg open).
- **(high)** Game feel rule: every input gets a pop and a sound within 100 ms, every reward gets motion plus a number, and only rare big moments get shake or flash. Hit-stop of 40-90 ms on big hits gives weight. Pool effects and throttle sounds. *Evidence:* Game Feel and Juice note: pop plus sound on every input within 100 ms; layers by cost; big moments get anticipation, reveal, payoff. Procedural Death Knockdown note: hit-stop 40-90 ms on attacker and target, 0.1 s flash; hit flash capped at 8 pooled Highlights. Juice note: throttle a click that plays 30 times a second. *For us:* Give the rebuild a feel budget per device tier: hit-stop only on takedown-class hits, shake on rare moments, screen effects only for the player's own actions, and a reduced-motion setting (no scale bounce, no shake, fades only).
- **(high)** Ragdoll networking has to be a deliberate owner per body. Grabbing players needs the grabber as owner or server forces, with server distance and rate checks, velocity clamps and a per-player prop cap. Ragdoll states need the Physics state and RequiresNeck or BreakJointsOnDeath set before death. *Evidence:* Network Ownership TL;DR: every gameplay-critical unanchored object has a deliberate owner; no valuable interaction on client-owned Touched alone. Grabs/Throws note: root priority plus SetNetworkOwner(grabber), victim massless and input off, single guarded release with max duration. Fling Things teardown: clamp velocities, cap props per player, validate grabs on the server. Ragdolls note: RequiresNeck=false before death, BreakJointsOnDeath=false, Physics state on the owner. *For us:* Write one grab/throw state machine (grab, held, thrown, release) with a max duration, a server distance and rate check, a velocity clamp and a per-player prop cap. Add a short immunity after being thrown and a no-grab toggle, which the Fling teardown uses to keep the comedy friendly.
- **(high)** Content maturity: stay on the lowest label that still fits the look. Light, unrealistic blood is Minimal. Heavy unrealistic blood is Mild. Realistic blood is Moderate. Realistic dismemberment or visible organs is Restricted (18+ only), and Roblox forbids realistic extreme gore at any label. Answer the questionnaire for the most extreme reachable content, including settings and modes. *Evidence:* Gore Policy and Kid-Friendly Hit Feedback note, citing Roblox docs 'Content maturity labels' (Oct 2026): label table; dismemberment and visible organs push to Restricted; answer for most extreme content anywhere. Policy and Age Rules 2026: maturity questionnaire required for every published place. *For us:* Keep blood off and severing off as defaults (the owner already did this). Use non-red hit colours, no persistent decals, and make sure no setting, mode or Creator Store asset reaches realistic gore. Re-check the questionnaire after every content change, since the vault says mislabelling can lead to moderation.
- **(high)** Paid random items need numeric odds on the same table that the server rolls, and they must sum to 100% before purchase. Luck passes must state the resulting odds. Server-side flags ArePaidRandomItemsRestricted and IsPaidItemTradingAllowed must be honoured. *Evidence:* Policy and Age Rules 2026 TL;DR: every paid random item and luck modifier shows numeric odds summing to 100%; avoid 'Rare/Epic/Legendary' with no numbers; honour the two flags server-side. Paid Random Items note: display table must be flattened from the same tables the server rolls; uncapped odds shown in a capped area must pass the cap. *For us:* If the event packs or egg-style rolls remain, show the exact odds from the roll table, in Robux or with a Robux equivalent, and keep the purchase flow to fixed-price products where possible. The Fling Things teardown kept every pass fixed-price, which is the simpler compliance path.
- **(high)** Purchase grants go only in ProcessReceipt, saved before returning PurchaseGranted, and never from PromptProductPurchaseFinished. Rewarded ads, if used, grant only in the receipt path. *Evidence:* Developer Products and ProcessReceipt TL;DR: grant in ProcessReceipt only, save then acknowledge, one handler per product, NotProcessedYet when the player is missing. Monetization Overview: no purchase log; no hard-coded prices. Ads and Rewarded Video: reward granted twice when granted both after ShowRewardedVideoAdAsync and in ProcessReceipt. *For us:* Confirm the single ProcessReceipt owner in the codebase (grep), keep purchase logs server-side, and keep prices read live. The owner's dev products and passes should follow this path in the rebuild.
- **(medium)** Phone-first layout: the vault's rules are concrete (12 px text floor, 44 px taps, 8 px gaps, zero overlaps on five viewports plus a notched phone), and the thumb zones are the bottom-left and bottom-right quarters. Test on a real phone for 15 minutes per release. The vault is weak on portrait-only phones. *Evidence:* Responsive UI for Phone Tablet Console and PC TL;DR: numbers enforced 12 px text, 44 px taps, 8 px gaps, 0 overlaps; five viewports plus notched phone. Mobile and Low-End Optimization: avoid testing phones only in the Device Simulator; 15-minute soak on a real phone each release; baseline low Android device. Figma UI note: movement thumb zone is the bottom-left quarter. Responsive UI note: 'TouchEnabled used as is a phone' is wrong. *For us:* Treat the upright phone (414x814) as the primary layout: thumb row for shoot and grab, HUD top band kept clear, and one bar row. Keep the LayoutCheck numbers from the vault and add a real-device soak on a low-end Android. Gap: no vault note covers portrait-first HUD design, so decide from the owner's data.
- **(medium)** Case studies of the big games give a repeatable first-session shape: a visible round or timer, the full loop shown in the first round, and a payout for everyone with a top-tier reward. *Evidence:* Dress to Impress: full loop shown within the first round (under 8 min), every participant paid, top three on a podium, visible timer. Grow a Garden: buy, plant, collect, upgrade within two minutes with no tutorial screen; a shared visible timer creates moments players gather for. Fisch: first catch in under a minute. Doors: every death shows a one-line cause and counter. *For us:* Add a shared visible timer or a round-style event (the Prank Party card and lab events are the start) so players gather, a payout for all participants so no one leaves empty, and a one-line cause on every knockout (who hit whom, with what).
- **(medium)** Viral physics toys work because the verb is one sentence and clip-ready. Fling Things kept a mild, fixed-price monetisation and a social verb. Its thumbnail shows a person in mid-flight, which matches the first minute. *Evidence:* Fling Things and People teardown: 'A toy, not a task'; first grab within ten seconds; thumbnail promise a person or object mid-flight; all passes fixed-price; approval about 80% because being grabbed is part of the friction. Viral Game Anatomy: the core verb is understandable from a 15-second clip; the twist is one sentence visible in the thumbnail. *For us:* Lead the store icon and thumbnails with the strongest ragdoll moment (a launch or a takedown mid-flight), match the title and first minute to it, and keep a clean 15-second clip in the first minute. Keep the toy-first identity; avoid a progression treadmill the first session has to climb.
- **(high)** A thumbnail must show one focal subject at 30-45% of the frame, with a readable face or emotion, and pass a greyscale test. Test icon and thumbnail variants for 7-14 days, one variable each, and do not judge by play-through rate alone (it trades off against bounce). *Evidence:* Thumbnail Composition note: one focal subject roughly 30-45% of the frame on a thirds point; greyscale test passes. Thumbnail and Icon A-B Testing: run at least 7 days, ideally 10-14, one variable per challenger. From CTR to CCU: never chase only play-through; misleading thumbnails raise clicks and bounce together. Game Icon Design: icon readable at 50-64 px, one big subject. *For us:* Build 2-5 thumbnails on one template with one changing slot, check the icon at 50 px, and run one change at a time for 10+ days outside update days. Judge by 60-120 s retention, not clicks.
- **(high)** Low CCU is a funnel diagnosis, not a verdict. Lower the server size while traffic is low so players land together, and fill servers fully. Design for one to three players, because a round-based loop that needs 8 players empties on a weak launch. *Evidence:* Rescuing a Weak Launch note: diagnose from the funnel stage by stage; wait for a few hundred attributed sessions; server size 8-12 for social games at low CCU (rule of thumb); prefer filling servers fully; waiting screens with '1/8 players' are where launches die. Launch Strategy note: do not treat day 1 CCU as the verdict. *For us:* Keep server size 6 (already low) with Fill Maximum set. Make the lab and plaza fun with 1-2 players (visitors, chasers and the solo lab). Read Session_v1 by stage (first shot, 60 s, 180 s, 5 min) before changing the game again.
- **(medium)** Level layout should guide by light, motion, skyline and openings, with one critical path that most first-time testers find without UI. Spawn and exits are designed first, and every new mechanic gets show, try, test and combine spaces with a soft floor. *Evidence:* Level Design Principles: each space audited for light, motion, skyline and openings; the brightest object must be the objective; critical path found without UI. Teaching Through Level Design: show, try, test, combine spaces; soft floor and instant retry; one cue per meaning. Lobby and Hub Design: first station under 15 s, exit under 20 s; spawn and exits first. *For us:* Light the objective (the bullseye or cannon) brighter than the decor, show each hazard with a demo, and keep spawn-to-first-station under 15 s. Put the spend station on the way out of the lab.
- **(high)** Retention hooks must be server-timed, mark-then-pay, and must not be chores. Log-in and playtime quests reward presence and double-count, so they were retired in the reference game. End each session with an unfinished, time-bound hook, and cap timers per day. *Evidence:* Retention and Return Hooks TL;DR: server os.time only; mark then pay; scale rewards to progress; at least one ready thing per join. Retired chore quests: log in, play 20/45/90 minutes, claim a gift, spin the wheel. Playtime gift note: the largest gift at one hour matches the 60 min discovery cap. Core Loops: AFK pays less than active play, with caps. *For us:* Keep the playtime gifts, but replace any log-in or claim-only chores with gameplay goals (takedowns, eggs). Keep the 7-day calendar and the daily goal as the D2 and D7 hooks, and ensure each reward is saved before it is granted.
- **(medium)** Ship in a fixed rhythm: feature freeze at T-10 days, public event at T-7, publish before go-live, and compare the first three days of players who joined after each update with the three days before. *Evidence:* Update Cadence and Hype Cycles note: a written cadence; feature freeze at T-10; event public at T-7; publish before go-live; content gated by server time. Discovery note: after every update compare first-three-day players before and after; the algorithm notices if new players are hurt. *For us:* Build the rebuild in one place with a feature freeze, a release-day checklist (the owner's RELEASE.md gate fits), and a first-3-day comparison for every release. Do not stack new features on the same week as a retention fix.
- **(high)** Measure the funnel server-side, forward-only, one event name with a field (no user ids or free text in custom fields), and batch counters with UpdateAsync. A/B tests need the outcome metric, minimum detectable effect and a fixed duration written before the test. *Evidence:* Measuring Onboarding note: log join, every step and Finished on the server, forward-only; Analytics and Funnels: one event name with a field, no user ids or free text (cardinality); Heatmaps note: per-server counters merged with UpdateAsync, batched. A-B Testing note: write hypothesis, metric and guardrails; check MDE; run the full duration. *For us:* Add funnel steps (join, first shot, first takedown, first reward, 60 s, 3 min, 5 min) to Session_v1 as forward-only server events. Make the rebuild's first-session changes testable one at a time.
- **(medium)** Accessibility is cheap to build in now: every information colour needs a second channel, rarity needs names as well as hue, and captions and reduced motion need settings with one owner. *Evidence:* Colour-Blind Safe Design: red/green for ally/enemy needs a second channel; rarity must not differ only by hue. Motion Sensitivity note: one comfort module, camera shake scalable to zero, one FOV owner. Readable Text: no TextScaled for body text; one UIScale controller. Difficulty Options note: named assists stored and enforced on the server. *For us:* Use shape or text next to every team or rarity colour, keep the shake and FOV owners separate, and add a reduced-motion switch to Settings. This also supports the kid-safe brief.

**Sources:**
- First-Time User Experience and Onboarding (10 Game Design and Genres)
- Onboarding and FTUE - Tutorials That Keep Players (05 UI and UX)
- Onboarding by Genre - The First Five Minutes (10 Game Design and Genres)
- Tutorial Step Design Patterns - Teach by Doing (05 UI and UX)
- Measuring Onboarding - Funnels, Drop-off and A-B Tests (11 Monetization Publishing and Live Ops)
- Core Loops and Session Design (10 Game Design and Genres)
- Retention and Return Hooks (10 Game Design and Genres)
- Discovery and the Algorithm (11 Monetization Publishing and Live Ops)
- Ethical Design and Player Trust (10 Game Design and Genres)
- Game Feel and Juice (07 Lighting VFX and Audio)
- Procedural Death Knockdown and Hit Reactions (08 Animation/04 Procedural)
- Ragdolls and Physics-Based Animation (08 Animation/04 Procedural)
- Network Ownership (03 Architecture and Networking)
- Grabs, Carries and Throws - Moving Players Safely (09 Gameplay Systems)
- Physics Performance (12 Performance Testing and Debugging)
- Gore Policy and Kid-Friendly Hit Feedback (07 Lighting VFX and Audio)
- Policy and Age Rules 2026 (49 Roblox Platform Features)
- Paid Random Items and Odds Disclosure in Practice (11 Monetization Publishing and Live Ops)
- Roblox Policies Ratings and Compliance (11 Monetization Publishing and Live Ops)
- Developer Products and ProcessReceipt (11 Monetization Publishing and Live Ops)
- Age Checks and Safety Features (11 Monetization Publishing and Live Ops)
- Robux Price Points and Offer Design (11 Monetization Publishing and Live Ops)
- Subscriptions and Premium Payouts (11 Monetization Publishing and Live Ops)
- Responsive UI for Phone Tablet Console and PC (05 UI and UX)
- Mobile and Low-End Optimization (12 Performance Testing and Debugging)
- Designing Roblox UI in Figma - Frames, Safe Areas and Tokens (05 UI and UX)
- Colour-Blind Safe Design (42 Accessibility and Inclusive Design)
- Motion Sensitivity and Camera Comfort (42 Accessibility and Inclusive Design)
- Case Study - Dress to Impress (32 Case Studies of Top Roblox Games)
- Case Study - Grow a Garden (32 Case Studies of Top Roblox Games)
- Case Study - Fisch (32 Case Studies of Top Roblox Games)
- Case Study - Doors (32 Case Studies of Top Roblox Games)
- Case Study - Forsaken (32 Case Studies of Top Roblox Games)
- Teardown - Fling Things and People (59 Viral and Trend Game Teardowns)
- Viral Game Anatomy - Hooks, Loops and Timing (59 Viral and Trend Game Teardowns)
- What Craft Looks Like on Roblox - Lessons from Top Studios (60 High-Craft Game Teardowns)
- Thumbnail Composition for High CTR - Focal Point, Contrast and Readability (61 Thumbnails and CTR)
- Thumbnail and Icon A-B Testing - Method, Sample Size and Reading Results (61 Thumbnails and CTR)
- From CTR to CCU - Impressions, Play-Through and the Discovery Loop (61 Thumbnails and CTR)
- Game Icon Design - Readable at Small Sizes (27 Marketing and Growth)
- Rescuing a Weak Launch - Empty Servers, Low CCU and Relaunch Tactics (27 Marketing and Growth)
- Launch Strategy - The First Two Weeks (27 Marketing and Growth)
- Update Cadence and Hype Cycles (27 Marketing and Growth)
- Marketing to Kids and Teens - Age Rules and Paid-Promo Disclosure (27 Marketing and Growth)
- Short-Form Video Marketing (27 Marketing and Growth)
- A-B Testing and Experiments on Roblox (27 Marketing and Growth)
- Level Design Principles - Flow Sightlines and Landmarks (33 Level Design)
- Teaching Through Level Design (33 Level Design)
- Lobby and Hub Design (33 Level Design)
- Playtest Heatmaps - Position and Death Maps (33 Level Design)
- Multi-Client and Device Playtesting Protocols (12 Performance Testing and Debugging)
- Genre QA Passes - Test Checklists per Game Type (12 Performance Testing and Debugging)
- Live Ops Events and Updates (11 Monetization Publishing and Live Ops)

**Gaps:** Not in the vault: (1) no teardown of the ragdoll-specific top games (Ragdoll Engine, Ragdoll Reality, Realistic Ragdoll Engine) beyond one mention in the Fling Things teardown; (2) no portrait-first (upright phone) HUD guidance, the mobile notes assume landscape or generic thumb zones; (3) no vault numbers for phone frame-time budgets or low-end RAM beyond rules of thumb; (4) nothing on like/favourite prompts (vault only states Roblox rules are not a like-reward path, which the owner already follows); (5) no live data here: the 120 s median, the 1-of-11 past 4 min and the 0.25.0 numbers come from the task text and are not verified in the vault. The Discovery note is dated Oct 2026 per Roblox docs; re-check the Creator Hub before relying on the bounce windows.

