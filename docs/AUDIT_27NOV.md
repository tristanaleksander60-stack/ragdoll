# AUDIT 27 Nov 2026: the whole game checked (owner: "Tjek hele spillet efter forbedringer")
Three parallel reviews by the cloud session: gameplay and content, phone UI, and technical (security, data, performance). Only things NOT already in the plan.

## Already FIXED in code by the cloud (27 Nov; the PC pushes them into Studio: klar "Code written by the cloud session")
- **F90:** ragdolls never vanish in view (RagdollDirector.mayRemove + REMOVAL_LOG, Unstick push-out, path walkers swap via Systems/PathSwap).
- **Paid BOLTS offers** complete the order only after the profile is saved (OfferService).
- **Never two saves of one player at once** (ProgressService; the duplicate saveNow removed).
- **Texts:**
  - the gory weapon blurbs are rewritten (Axe, Cleaver, Shotgun, Katana, Chainsaw);
  - the Welcome badge names the game;
  - "Like the game?";
  - Places → MAPS;
  - the missions toasts are gone;
  - "Tap the ground" on touch.
- **The group gift** reads the game's group id (Shop.GROUP_ID).
- **No auto first person on touch screens** (Config.PHONE_AUTO_FP = false).

## URGENT (build right after F90/F89)
1. **DONE v1289 (`LAB_CONTROLS_BUTTON`, Systems/PassLint):** the stand shows only in a pass owner's lab, only they can press; the shop sells the pass again; PassLint prints an error at startup for any pass on sale whose feature is off. **Was:** The "Lab Controls" pass (179 R$) is sold, but its BIG RED BUTTON is switched off** (`Config.BIG_BUTTON = false`; Shop.luau ~338). Buyers get nothing.
   - **Fix:** bring the button back ONLY for pass owners, in their own lab, on the new map (a small pedestal by the spawn plaza).
   - Add a startup lint: every pass on sale must reach a live feature (log an error otherwise).
2. **DONE v1290 (`ADVENT`: Shared/Advent, Systems/AdventService, Client/AdventCalendar):** 24 doors, one a UTC day from 1 Dec, a missed day caught up later (until 31 Dec), fixed gifts shown on the doors (BOLTS; Rainbow Trail, Fire Trail and Crash-Test Suit for 3 days on doors 6/12/21; a weapon egg on 18; door 24: 1,000 BOLTS + an egg + Gold Dummies 7 days), kept in eco.codes (no new save field); the gift button opens it while a door waits; one validated remote, 1 call a second. NOT built: Christmas-only hats/trails, the snowball launcher and the sleigh event (new content; question in NOW). **Was:** CHRISTMAS ADVENT CALENDAR, live from 1 Dec (4 days):
   - 24 doors, one claim per UTC day through one validated `Net` remote (the DailyGoals day maths, the streak freeze);
   - fixed rewards shown in advance: BOLTS, Christmas-only hats and trails, and a big day 24 (a snowball launcher toy and a Santa sleigh event);
   - a festive calendar window opened from the gift chip in December;
   - it must be in the build the owner publishes before 1 Dec.
3. **DONE v1291 (`PROFILE_LOCK`, ProgressService):** a lock {job, t} taken in UpdateAsync before the read (another server's fresh lock: wait up to 10 s for its leave save, then read anyway), refreshed by every save, cleared by the leave/close save (which now always goes out); the eco merges as changes: BOLTS a delta since the last save (boltBase), codes/journal/got unions, perks/counts the larger. **Was:** DATA SAFETY: a session lock on the profile:
   - today `m.eco = session.eco or stored.eco` (ProgressService ~356) lets BOLTS and codes come back or get lost on a fast hop between the two places;
   - take a lock `{job, t}` in UpdateAsync on load (retry about 10 s; a lock older than 2 min is stale), clear it on leave and close;
   - also merge safely: BOLTS as a change since the last save (a `boltBase`, like eggs), `eco.codes` and `eco.got` as unions, `perks` as the larger value;
   - use the `roblox-datastore-safety` skill.
4. **DONE v1291 (`TAKEDOWN_GUARD`):** each server-stamped hit makes at most one takedown (a client toggling Down/Standing needs a new real hit), and at most 120 takedowns a minute a player (over: refused, Metrics "TakedownCap"). (No separate force threshold: every stamp already comes from a real server hit.) **Was:** Takedowns must not be farmable by a hacked client:
   - credit a takedown only when the server's own hit would knock the body down (HitMath's threshold, stored by `stampServerHit`);
   - refuse a `Standing` report sooner than MIN_DOWN after a fall;
   - cap takedowns per player per minute (anything over the cap goes to Metrics).

## BEFORE THE RELEASE (fairness, kids, compliance)
5. **PART DONE v1306 (`EGG_ODDS`):** what an egg holds and the hat odds shown under OPEN EGG (Rewards); the paid VIP's faster eggs off where PolicyService restricts paid random items (asked in the background, never yields; the free launch VIP keeps it). LEFT: the parked starter pack's "3 weapon eggs" (it is not live). **Was:** Egg odds shown in the egg window (60/28/10/2). The VIP "egg every 50 instead of 75" is a paid speed-up of random rewards: change it to a non-random VIP perk (a VIP-only hat + BOLTS), or gate it with PolicyService `ArePaidRandomItemsRestricted`. The parked starter pack's "3 weapon eggs" must never go live as written.
6. **PART DONE v1307:** the Events Pass reads "Every server event, free, for good" (a permanent pass). Single weapons for Robux are OFF today (`WEAPONS_NO_BUY`), so no single price can beat a category pass; when they come back, BUY must show the category pass when it costs the same or less. **Was:** Prices:
   - a single weapon (up to 199 R$) can cost more than "All Guns" (149): when the category pass costs the same or less, BUY shows the pass instead;
   - cap single prices below their category pass;
   - "Events Pass … all season" is a permanent pass: fix the wording.
7. **PART DONE v1309:** the Economy remote (Hello, BuyNext, Redeem) has a token bucket per player (4 a second, a burst of 8; the rest dropped and counted). LEFT: a shared `Net.on` for every remote, and the 3 remotes made outside Net (MechArms, BoughtChat, Wasted). **Was:** Net with rate limits:
   - add `Net.on(name, argTypes, {rate, burst}, handler)` (a token bucket per player per remote; bad requests dropped and counted) and move the handlers to it, starting with Economy Hello/BuyNext (no limit today; Hello fires the full state back);
   - the 3 remotes made outside Net (MechArms, BoughtChat, Wasted) go into Net.Names.
8. **DONE v1309 (`JOIN_SIGN`, Systems/JoinSign):** our servers sign TeleportData (a keyed tag over from/code/target/time); Lab and PortalService read it only when the tag fits, it is under 2 min old and SourcePlaceId is one of our places. The key is NOT in git: it is the ServerStorage attribute "JoinSignSecret" in the place file (both places get it when published from this file). **Was:** TeleportData can be forged: accept `from`/`code` only when `join.SourcePlaceId` is one of our two places, and sign the payload on the sending server (an HMAC of `{from, code, userId, t}`, under 60 s old).

## GAMEPLAY AND CONTENT (after R10, with the machines phase)
9. **A BOLTS cosmetics shelf** (fixed prices, no randomness):
   - hit and KO effects, ragdoll tints, trails, titles, a few hats;
   - a duplicate egg hat pays BOLTS ("+40 BOLTS");
   - T1's rank prizes are items here.

   This makes 2x BOLTS and the Everything pass worth having.
10. **Weapon MASTERY** as the long goal: bronze, silver and gold stars per weapon at 25/100/300 KOs, each unlocking a cosmetic finish (gold, rainbow, candy). The goal line shows "12 KOs to GOLD Katana".
11. **Endless LEGEND STARS:** one star every 500 KOs after Legend, a title colour per 5 stars, BOLTS per star. The goal line never goes empty.
12. **WEEKLY boards:**
    - "THIS WEEK'S KOs" (resets on Monday);
    - one "BEST OF THE WEEK" board rotating between bowling, cannon, tower drop and target run;
    - a statue for the weekly #1 (the F77 code).
13. **PLAY TOGETHER:** from the solo start place, the invite first takes you to a reserved multiplayer server (PortalService), then opens the invite there, so friends really meet.
14. **Daily goals use the map:** "Bowl a strike", "Fire the cannon 3 times", "Feed 2 animals", "Break 5 bones", "Use 4 different weapons".
15. **Badges:**
    - add 7-day streak, all weapons, all hats, every machine tried, every animal catch, Legend, the first gold mastery star, the advent finish;
    - re-point "Bullseye" (its bullseye is removed) to the cannon's PERFECT landing.
16. **A co-op chip:** "Together: 40 KOs in 3 min" for friends in one lab or the multiplayer place, stars and BOLTS for everyone. Not the old mission card.
17. **A Roblox Premium perk:** a Premium tag, +10% BOLTS, a Premium-only hat; a soft PromptPremiumPurchase on the shop card.
18. **Private servers** (multiplayer place): an owner panel (ragdoll count, a free event every 2 min, a theme). The owner turns private servers on, cheap, on the dashboard.
19. **5 gentle "SILLY" toys** for the younger players: Rope, Glue, Paint Blaster, Bubble Gun, Magnet Glove. They fill early ladder rungs, so not every unlock is a gun.
20. **(Owner decision first, in NOW.md) The Game Arena** (`ARENA_ENABLED = false`) as a "challenge of the hour" pad on the map, feeding the weekly boards.
21. **BUILD OF THE WEEK** wall: 3-5 owner-picked share codes; a tap loads a copy.

## PHONE UI (with T1 / PHASE 7)
22. **MORE on a phone:**
    - merge RANK & EGGS into REWARDS (two tabs; they repeat each other);
    - FAVORITE out of phone MORE;
    - BACK TO SPAWN gets a home icon;
    - at most 6-7 entries in 4 rows.
23. **The shop on touch:**
    - one tap opens the detail view;
    - the card's price button also opens the detail (BUY only there, so a child always sees what it is);
    - CODES moves to the window header;
    - each tab gets a one-line kid subtitle ("BOLTS: coins for weapons").
24. **The mini hotbar** (F71) at rest:
    - icons only (no names), the selected slot full size, `SMALL = 0.75` (slots at least 44 px);
    - it stays open 1.5 s after a pick.
25. **Text at least 14 px on phones:**
    - the caption minimum `ceil(14 / scale)`;
    - "ONLINE" instead of "Multiplayer" on the tile;
    - the gift clock 15-16 px in a 64x20 box.
26. **DONE v1313:** the LAB window's key letters show only where keys are shown (ViewMode.showKeys). **Was:** Key letters left on phones: the LAB window's `keyed()` uses `ViewMode.showKeys()`.
27. **Settings:**
    - hide Notices while COUNTERS_ONLY;
    - on phones only Sound, Graphics, Camera shake, UI size, Body card;
    - kid wording;
    - delete the WALK leftovers.
28. **Slow-mo:** 3 speed chips and START/STOP right in the LAB row (not 4 taps through 3 windows).
29. **X-RAY button:**
    - "X-RAY ON" in words (not colour only);
    - the HUD font;
    - a HudSlots slot (so LayoutCheck measures it);
    - the pulse with a UIScale from the centre.
30. **One word for each thing:** RAGDOLL (not dummy), KO (not takedown), MAPS (not Places), SOLO, in a small Shared word list, for every player-facing string.
31. **The loading screen:** a progress bar from the real `ready()` checks, the logo and one rotating kid tip.
32. **Icons:** MORE gets a dots/grid icon (not the settings cog), Multiplayer a globe, Eggs an egg, Codes a ticket.
33. **One font helper:** `KitStyle.font("display"|"body")` for the 21 modules still on FredokaOne, Gotham or SourceSans.
34. **The CPR game:** rebuilt as a kit panel, an 88 px PUSH on the right thumb, a SKIP, the hotbar kept visible.
35. **DONE v1313:** the map board's window is "Go to a map", the shared one "Shared lab". **Was:** Window titles: "Go to a map" and "Maps", "Shared lab" and "Multiplayer" no longer share titles.

## PERFORMANCE (with row 8 / R8)
36. **Wounds are resent whole** (up to 80 entries, about 2 KB) to every client on every hit: send only the new one (`WoundNew` + a sequence number); the full list only when a body streams in; `WoundsReset` for heals and the pick-out.
37. **PART DONE v1315 (`HOLE_CAP_PHONE`):** a phone keeps the newest 24 holes a body (a PC all 80, the owner's choice); the holes were already pooled and massless with no query/touch. **Was:** Bullet holes:
    - capped per device: about 12 on a phone, 30 on a PC per body;
    - only on the nearest bodies, pooled;
    - Massless with CanCollide, CanQuery and CanTouch off.
38. **SmoothBody:** pool the meshes (no clone/destroy at the edge), a phone tier (`MAX_BODIES` 4-6), one shared candidate list with RealHands.
39. **The server loops:** one body scheduler in the RagdollDirector tick; systems register a callback with a rate and a time slice (N bodies a frame).
40. **The DataStore budget:**
    - at close, save Progress first, then Orders; skip SessionStats and leaderboard writes when the budget is low;
    - later, fold the small per-player stores into the profile (one read on join, one write on close).
41. **DONE v1316:** LabCreatures `lastRevenge` has weak keys; MechArms clears `held` on the body's Destroying; PurchaseChat already cleared `last` on PlayerRemoving. **Was:** **Small leaks:** PurchaseChat `last[userId]` (clear on PlayerRemoving), LabCreatures `lastRevenge` (weak keys), MechArms `held` (clear on Destroying).
42. **DONE v1317 (`HIT_OWN_MARGIN`):** a tap on your own simulated dummy more than 6 studs outside the server's part box is refused as Missed and logged (once per 10 s a player). **Was:** **HitService on your own dummy:** check the tap point against the server's part with a 6-stud margin and log misses.
