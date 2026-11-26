# NOW: the current work list (read this first on every /klar)

**All weak points, ranked:** `docs/WEAKNESSES.md` (26 Nov). After LAB10 round 2, take its "Order to fix" from item 3.

**Next after the lab:** `docs/STAY_LONGER.md` (session length). Build items 1-8 in one run. Item 1, the quiet gift timer on phones, goes first.

## THE RUN ORDER (owner, 26 Nov 2026: "sørg for planen bliver lavet i den rette rækkefølge"). `/klar` follows this list top to bottom.
Why this order:
- the owner's deadline first;
- small quick wins next;
- then the FOUNDATION (physics and the body), which everything later builds on (dog, lasso, wheelchairs, walls, effects);
- then the big lab;
- then the features that use the lab and the physics;
- then session length.

| Step | What | Plan | State |
|---|---|---|---|
| 0 | **Owner:** press Alt+P to publish 0.58.0 (gore off), then send the maturity questionnaire, before Fri 27 Nov 17:34 UTC | `docs/MATURITY.md`, `docs/BODY_V2.md` "final answers" | BUILT, waiting for Alt+P |
| 0.3 | **The owner's fix list of 26 Nov evening (F1-F24):** + the washing machine door and in/out through the porthole; + nicer shell casings; + the dog faces the limb it bites and moves like a real dog; + the full-width bar and the dim strip at the bottom on PC, an X-RAY key chip; + no hint strip on phones, fewer ragdolls at the spawn, machine demos once each with real ragdolls; + REVIVE ALL instead of Z, no white blob on shots, CPR faces the patient, hold-to-fire only for automatic weapons; TRY once, hit reactions by spot, no black screen, bullets in bones, bubbles, clean phone UI, the cannon load, talk about what they see, the dog icon, a German Shepherd, the PC nav, the multiplayer place | `docs/FIXES_26NOV.md` | DONE 0.70.0-0.75.0 (all 16; F4 and F10 part 1). State at the end of FIXES_26NOV.md. Studio now saves to the MULTIPLAYER place (v48-v51); the start place was last saved at v1129 |
| 0.5 | **The first 2 minutes + the new TRY:** a TRY button at the machine, a ragdoll comes, grab it (lesson only the first time) and put it in. This replaces the buggy floating TRY! sign (the bug notes below explain why it is removed) | `docs/FIRST_2_MIN.md` | built 0.60.0 (place v1117): `FIRST_TWO`, Client/FirstTwo, Lab.callTo, Session "Try"/"TryStep", +25 BOLTS a machine; `TRY_ME` off. Left: per-machine load spots (the whole machine glows), walk-to-start for no-load machines |
| 1 | Always 3 near you (update: not afraid of weapons; 2 chat, 1 comes all the way, rotating; they come very fast) + a watcher at every machine | `docs/ALWAYS3.md` (read the "Update" at the end) | 3-near built in 0.59.0; the update built in 0.61.0 (place v1118): `FEAR_WEAPONS` false, recruits Pace 2.2, 2 chatters + 1 comer rotating every 15-25 s (Lab assignRoles, Role3). **Left:** the watchers at every machine (stand-ins), new ones spawning out of view |
| 2 | The MULTIPLAYER icon instead of the portal | the section below | built 0.59.0 (`MP_ICON`, `MP_PORTAL` false); left: phone layout of the window |
| 2.5 | **Phones and tablets: much less lag, much smoother** (measure, then fix the top costs, an auto quality governor; the cool details stay) | `docs/PERF_MOBILE.md` | |
| 3 | **PERFECT PHYSICS + THE SMOOTH SKINNED BODY with real fingers** (`docs/BODY_V2.md` 4c): the hard checks, then falls, landings, lying and get-ups | `docs/RAGDOLL_FEEL.md` ("PERFECT physics" first) | part 1 in 0.62.0 (place v1119): a round's turn and push scale with its force, 0.6x-3x (`SHOT_WEIGHT`, ActiveRagdoll shotReaction). Found already: the speed cap (client sim 180 studs/s, ActiveRagdoll) and the server watchdog (over 220: sent home, Lab). To do: hit impulse at the exact point by weapon force, tone per limb, rest-sleep, piles, buoyancy, get-ups, the 5 bench clips |
| 4 | **PERFECT BULLET HOLES** + purple splatter on every hit | `docs/BODY_V2.md` 3 and 2b | checked: 2b exists already (BloodFx.wound: 3-12 purple droplets in the shot direction on every hit, landing; skipped only at the part cap); holes exist (BulletHoles, glued to the limb, sized by weapon).  0.63.0: `HOLE_VARIETY` (owner: "nye skudhuller, ikke det samme hver gang"): every hole its own size, oval by angle, tint, picture, stress ring and edge chip (no rings/chips on phones). Still parked: holes V2 (4 mesh variants, cracks, rim, exit holes, plastic chips) needs new hole art |
| 5 | The body: X-ray 10/10 (bones can break by force), the blood look, injury stages, bandages, faces | `docs/BODY_V2.md` 1, 1b, 2, 4b | part 1 in 0.63.0 (place v1120): X-RAY button + B key (owner: B is fine) (`XRAY_V2`, Client/XRayToggle, DummySkins.setXray: the nearest 16 / phones 6 within 80 studs, whole skeleton). Left: glass shell + blue outline look, mesh skeleton, 1b breaks, 2 blood look, 4b stages/bandages/faces |
| 6 | Impact smoke and dust, grab-swing-SLAM | `docs/IMPACT_FX.md` | part 1 in Studio, 0.64.0 (place v1121): `IMPACT_FX`: Client/ImpactDust (dust + bits by surface and speed, shock ring at 70+, 6 a second, 90 studs, half on phones), hooked in FxController "Land"; SLAM in GrabController (touch button by THROW while holding, right click on PC, "SMASH x2" on the goal line). Left: smoke trail, scuff decals, props react, camera shake/hit-stop on own slams |
| 7 | **The lab:** the owner's map 1:1, 10x bigger, faster running and sprint | `docs/LAB_TARGET.md` ROUND 3 | PARKED for its own long run: a full new map at about 950x820 studs with new set pieces (cave, aquarium, pool, pen, sandcastle, shredder pit, crocodile pond, T-rex pen, garage, railway). It needs several sessions of building and side-by-side captures; done after steps 8-12 unless the owner says go now |
| 8 | Lasso, breakable concrete walls, wooden crates | `docs/DESTRUCTION.md` | part 1 in 0.65.0 (place v1122): `BREAKABLES` wooden crates (Systems/Breakables: 3 stacks a lab, shot holes, 4 rounds or a blast or a flying body break them to planks, back in 20 s). Left: the lasso, breakable concrete walls and brick wall |
| 9 | Burial + revenge | `docs/BODY_V2.md` 4 | built 0.66.0 (place v1123): `BURIAL` (Mourning bury(): shovel, 3 s dig with dirt, body hidden until it wakes, mound + R.I.P. stone 60 s, max 3, 1 burial at a time, not in a newcomer's first 2 min; then one cringe line and a 10 s revenge attack). Left: the funnel steps |
| 10 | The guard dog (tap a limb, it bites) | `docs/GUARD_DOG.md` | built 0.67.0 (place v1124): `GUARD_DOG` (Systems/GuardDog + Client/GuardDogClient): a code-built doghouse at lab (40,22) with Whistle (E); the robot dog follows; tap or click a limb (head picks an arm) and it runs there, bites that part (DummyControl.hit + VitalsService.wound), shakes, GOOD BOY!; dog button sends it home; home after 3 min idle. Tested: whistle + a leg bite. Left: tooth marks, X-ray jaws, a real dog model, limb-specific reactions |
| 10.5 | Human idle behaviour (fingers, stretching, yawning…) + a cyclist on a pedal bicycle round the lab | `docs/LIFE_IDLE.md` | |
| 11 | Wheelchairs | `docs/WHEELCHAIRS.md` | PARKED (`WHEELCHAIRS = false`): no wheelchair model in the place; VehicleService would draw a small car (box, lights). Needs a Creator Store wheelchair (malware pass) and its own run: seating a ragdoll, pushing, let go, crash ejection |
| 12 | Session length, the rest (item 1 is done in 0.57.0) | `docs/STAY_LONGER.md` 2-8 | item 2 in 0.57.0 (TRY reward); item 3 in 0.68.0: `LAB_SURPRISES` on again, about every 2 min (110-130 s), "Surprise in 10 s!" on the goal line (EventService SurpriseAt, LabShowcase); first wow is RocketRain (no extra dummies). Item 6 exists (StuntHud NEW BEST). Item 8 in 0.69.0 (place v1125): the daily gift and streak already exist (ProgressService); a quiet "Come back tomorrow: day N gift!" after 8 min (`COME_BACK_AT`). Left: 4 pacing check, 5 long goal after weapons, 7 A/B shared servers, Roblox experience notifications |

**The TRY! bug (the sign is REMOVED by FIRST_2_MIN; keep these notes only if any marker stays): causes found in `StarterPlayerScripts/.../Client/LabShowcase.luau` `tryMe()`. Fix all of them:**
1. **It flickers every second.** Every second the loop sets `sign.Adornee = nil`, `StudsOffsetWorldSpace = Vector3.zero`, sets `Adornee` again and re-parents the ring and sign, even when nothing changed. For a frame the sign jumps to the ring or the screen origin.
   - **Fix:** create, parent and adorn once. Only move the anchor when the target machine changes.
2. **It flips between machines.** The nearest untried machine is re-picked every second, so walking between two machines swaps the target back and forth.
   - **Fix:** keep the current target until it is tried, or until another machine is at least 40 % closer for 3 s in a row (hysteresis). Also never re-pick while the player moves faster than walking (flying, falling, in a car).
3. **It jumps up and down.** `floorY = hrp.Position.Y - 3` uses the PLAYER's height, so on the tower, when jumping or falling, the ring and sign jump.
   - **Fix:** use the machine's own floor (raycast down from the machine's centre once, when the target is picked).
4. **It shows through everything, from far away.** `AlwaysOnTop = true` with `MaxDistance = 220` shows the sign over walls and the HUD from across the lab.
   - **Fix:** `AlwaysOnTop = false`; `MaxDistance` about 90; hide it while a menu is open, in a car or in first-person aiming; and `ClipsDescendants` so it never sits off-screen as a big shape.
5. **It is too big on phones.** `Size` is 120x54 px fixed.
   - **Fix:** use a scale size that shrinks with distance (`Size = UDim2.fromScale(4, 1.8)`, studs-based), clamped. Max one TRY! at a time.
6. **Check:**
   - walk between 2 untried machines, climb the tower, jump, ride a car: the sign stays on ONE machine, steady, and never flickers;
   - on the phone emulator it is small and clean.

**How to work through it** (owner, 26 Nov 2026: "Sørg for den minder mig om punkt 0 og gør så den ikke stopper og beder mig teste undervejs"):
- **Start:** every /klar run starts with the Danish step 0 reminder, until step 0 is marked done.
- **Never stop to ask the owner to test,** and never wait mid-run. When only the owner can publish, save the place and ask for Alt+P only in the final message.
- **Questions** go into the owner list with a safe default.
- One quick Play after each step, and commit and push.
- **Publish** after steps 3-6 if the tools can do it without the owner; otherwise once at the end. Give ONE Danish "Test selv" list, in the final message only.
- Never ask the owner to test in between. Park questions with a safe default.

## RULE FOR EVERYTHING IN THIS PLAN (owner, 26 Nov 2026): mobile first, simple enough for a 10-year-old on an iPad
- **Phone and iPad first:** every new thing is built and checked on the phone and iPad emulators before PC and console.
- **One tap per action:**
  - big buttons (at least 60 px);
  - icons rather than words; at most 2 words on any button;
  - no reading needed to understand it.
- **Hints:** a first-time hint is one short line plus a pointing hand, shown once.
- **Performance:** within the phone caps (ragdolls, particles, parts); light stand-ins far away.

## Small UI change (owner, 26 Nov 2026): MULTIPLAYER as an icon
> "Det er allerede i spillet i portalen, bare lav det til et ikon i stedet for"

- **What exists:** the Multiplayer window (Play: QUICK JOIN / PLAY WITH FRIENDS; Open games; Private room; Join by code) opens from the multiplayer portal in the world.
- **The icon:** put a **MULTIPLAYER icon button** on the HUD nav (two-people icon, label "Multiplayer" on PC; on phones the icon only, at least 60 px, in the left stack under Shop / More / Lab). It opens the same window.
- **The portal:** hide the multiplayer portal behind a switch (`MP_PORTAL = false`; do not delete it). The SINGLEPLAYER way back stays reachable from the same window ("Back to my own lab").
- **The window on phones:**
  - near full-screen;
  - big buttons;
  - the side tabs as icons with short words;
  - text cut to one short line.
- **Order:** do it in the same run, right after ALWAYS3. It is small.

## FIRST, URGENT: `docs/BODY_V2.md` section 0, gore OFF (owner chose it, 26 Nov)
**State (26 Nov 2026): BUILT and saved as 0.58.0 (place v1114 -> v1115), waiting for the owner to publish (Alt+P).** Switches:
- `SEVERING = false`: no limbs off, no halves, no bursting heads; mech arms cannot tear.
- `GORE = false`:
  - creatures spit gold stars instead of bones or meat, red is purple, and no water turns red;
  - the press has no splat or drips;
  - the X-ray bone stays whole;
  - the words are KO, knocked out, OUT COLD and Energy.
- `STORE_TEXT.md`: "purple cartoon splats; no gore".
- Next: ALWAYS3, then the MULTIPLAYER icon, then LAB_TARGET ROUND 3 and the rest of the run.
**State 0.59.0 (place v1116, not published):**
- ALWAYS3 part 1 done (`ALWAYS_THREE`, Lab `alwaysThree`): far ones run in, near ones walk in and say a line.
- **Left:** the spawn out of view when no ragdoll is free; the "Spectators at every machine" section (`MACHINE_WATCHERS`, stand-ins).
- MULTIPLAYER icon done (`MP_ICON`, a "Multiplayer" square under Lab; `MP_PORTAL = false`). **Left:** the phone layout of its window (near full-screen, icon tabs).
- Next: LAB_TARGET ROUND 3.
- Build it, then **publish at once** (quick gate). The maturity questionnaire is due **Fri 27 Nov 2026 17:34 UTC** and must match the live game.
- Then tell the owner in Danish: "Gore er slået fra og live — send spørgeskemaet nu med svarene i docs/MATURITY.md".
- Only then the rest of the run.
- Right after it (small, big effect): `docs/ALWAYS3.md`, always 3 living ragdolls near the player; replacements run in from afar or walk in and say a line. Plus at least 1 watcher at every machine (section "Spectators").

## CURRENT RUN: `/klar` = LAB_TARGET ROUND 3. Do it now, all of it, without asking.
**Not blocked any more** (owner, 26 Nov 2026): "1:1 10/10 … jeg skal bare skrive /klar".
- Do not search for the old file.
- **The lab is 10x bigger (area) and the player runs faster:** see LAB_TARGET R3.2 "SIZE" and "RUN FASTER".
- Rebuild the owner's own map 1:1 from `art/store/look_target/lab_ref/ref_6` … `ref_10` (and `ref_1` … `ref_5`), as `docs/LAB_TARGET.md` ROUND 3 says.
- Then publish once and give one Danish "Test selv" list.
- In the same run, after the lab: `docs/IMPACT_FX.md` (smoke and dust on every impact, grab and SLAM).
- Then `docs/DESTRUCTION.md`: the LASSO (rope a ragdoll, drag and swing it), concrete walls that break where a body hits, and wooden crates with bullet holes that break into planks.
- Then `docs/BODY_V2.md` sections 1-4b: X-ray 10/10, purple blood look, hit marks instead of holes, burial + revenge, injury stages + real bandages + changing faces.
- Then `docs/GUARD_DOG.md`: whistle the guard dog; tap a ragdoll's limb and it bites exactly that limb. The reaction fits the limb, the damage stays, and X-ray shows the bite.
- Then `docs/WHEELCHAIRS.md`: drivable wheelchairs; put ragdolls in them, push, let go and crash.
- Then `docs/RAGDOLL_FEEL.md`: realistic falls, landings, lying and get-ups like the top ragdoll games.
- Then: `docs/STAY_LONGER.md`.

(Older notes below.)

## CURRENT RUN: LAB TARGET (owner, 26 Nov 2026)

**NOW: `docs/LAB_TARGET.md` ROUND 2.** The references are the owner's OWN old map. Find that version (version history, backups), copy its lab 1:1 into `ServerStorage.OldLabMap`, use it at full size behind `LAB_OLDMAP`, and put every machine where it stood. No rebuilding by eye.

**State (26 Nov 2026, ROUND 2 step 0): BLOCKED on the owner.** The old map is not found:
- not in git (no "Lasso", "Scan" or "Tools" HUD in any commit; git starts 19 Nov 2026);
- not in the local .rbxl files (AutoSaves 20 and 24 Nov and server.rbxl are this game; `Documents\Place1.rbxl`, 31 Oct, 385 KB, is unchecked and is the only candidate);
- Open Cloud asset versions need the `legacy-asset:manage` scope, which is off, and the MCP cannot open a place file.

Asked the owner: which game, version or file is it from? To go on, the owner can do one of these:
- (a) open the old version in Studio (File > Open from Roblox, or Version History > open), so Claude copies the lab from that Studio window;
- (b) open `Documents\Place1.rbxl` if that is it;
- (c) send the game link.

Nothing else in NOW.md can be done without the owner. In WEAKNESSES "Order to fix":
- 3 needs a real phone;
- 4 needs the dislike reasons;
- 5 onwards are new features waiting for direction.

Build `docs/LAB_TARGET.md`: the lab to the owner's reference screenshots (`art/store/look_target/lab_ref/`).
- A realistic plot grid.
- The steel tower and slide in the centre.
- A raised spawn plaza with 4 leaderboards.
- Railway, hills and trees.

It replaces LAB10's cartoon look. Keep attract mode, the "try me" chain and harsh scoring from ROUND 2.

**State (26 Nov 2026):** round 1 of LAB TARGET built and saved (0.56.0, place v1113, `LAB_PARK`). LAB10 R2 part 1 (attract mode, TRY!, zone pads) is in 0.55.0. Not published yet (owner: Alt+P). Next: see LAB_TARGET.md "State": the 50-stud steel scaffold tower, a true plot grid, the 5 reference captures.

The rules are as before:
- one run;
- publish once;
- one Danish "Test selv" list;
- never ask the owner to test in between.

(Older:) ## CURRENT RUN: LAB 10/10 (owner, 26 Nov 2026)

**ROUND 2 NOW** (owner scored round 1 at 3/10): build `docs/LAB10.md` section "ROUND 2". Main things:
- attract mode on every machine;
- the "try me" chain;
- replacing the weak machines;
- 3 new ones;
- the hero tower;
- a denser lab with a floor that has life.

Score harshly.

> "Hele labbet skal tages fra 2/10 til 10/10, ikke vær bange for at ændre ALT"

Build `docs/LAB10.md` in one run: everything, then publish ONCE, then ONE Danish "Test selv" list. Do not ask the owner to test in between. Questions go into the owner list with a safe default.
Then finish what is "Left" from item 1 (More window, bigger hotbar, portrait check) in the same run.

**State (26 Nov 2026):** round 1 built and saved (0.54.0, place v1111): the crash-test lab behind `LAB_V10` (see LAB10.md "State"), plus item 1 leftovers: `PHONE_MORE_FLAT`, `PHONE_BIG_HOTBAR` (portrait was already locked to landscape). Not published yet (owner: Alt+P). Round 2 (signs, hero tower, travel gate, shop row) is listed in LAB10.md "Left".

---

## Earlier run (0.53.0, done 26 Nov; kept for reference)

**URGENT, owner only:** the maturity questionnaire (item 5) must be resubmitted by Fri 27 Nov 2026 17:34 UTC.

Status: **GO** (owner, 26 Nov 2026). Build EVERYTHING in this list in one run before the owner tests.

> "Sørg for at den laver alt før jeg skal teste, så jeg ikke skal ind og teste flere gange i løbet af i dag"

**Targets and order of levers:** `docs/STRATEGY.md`, the 1-week column. Every item is judged against those funnels.

**How this run works (owner order, 26 Nov 2026; it overrides "publish and test after each item"):**
- Build items 0-8 top to bottom in ONE session, without stopping to ask. Item 5 is the owner's (only prepare the answers).
- After each item: one quick Play (no errors), commit and push, mark it done here. **Do not ask the owner to test in between.**
- Anything that needs the owner (new product ids, a picture choice, a yes/no): pick the safe default behind a Config switch, write it in the "Questions for the owner" list at the end, and go on. Never wait.
- **Publish ONCE at the end** through RELEASE.md (quick gate; never restart old servers).
- Then give the owner **ONE combined Danish "Test selv" list** for everything, grouped by device (phone first, then PC, tablet, console), max about 15 lines, plus the "Questions for the owner" list.

0. **WEAPONS list: no BUY, no TRY FREE, only the next weapon shows its KOs** (owner, 26 Nov 2026; do this first, it is small).
   > "Gør så man ikke kan se "Buy" ved hver ting i WEAPONS, men man kun kan se hvor mange KOs man mangler. Så man skal kun kunne se hvor mange KO's man mangler ved det våben man er kommet til, ikke hvor mange KO's det tager at få en sniper fx. og fjern try free ved alle våbene."
   - **File:** `StarterPlayerScripts/.../Client/ToolCatalog.luau` (BUY around line 200-225, TRY FREE around 650-690, the count line at 288, the intro at 427).
   - **Remove BUY** from every weapon card in WEAPONS. Behind a Config switch (`WEAPONS_NO_BUY = true`); the weapon products stay live in the shop, only the cards lose the button.
   - **Remove TRY FREE** from every weapon card (`WEAPONS_NO_TRY = true`). Also stop the "free try is over … or BUY it" toast and any other TRY FREE prompt (TrialService, ProgressService). Do not delete TrialService; just switch it off.
   - **The KO bar shows only on the next weapon to earn** (the first locked one in unlock order): "12 KOs to go" plus its bar. Every later locked weapon shows a lock and "Locked" only, with no number and no bar.
   - **Unlocked weapons:** EQUIP as now.
   - **The weapons stay for sale in SHOP** (owner, 26 Nov). Check that every weapon product is in SHOP (ITEMS, or a WEAPONS tab); add the missing ones, with a picture and the price from Roblox.
   - **Texts:** the line "Locked: earn KOs, BUY, or TRY FREE for 2 min" becomes "Earn KOs to unlock the next weapon". The intro loses "or BUY".
   - **Test selv:** open WEAPONS on PC and on a phone. There are no BUY or TRY FREE buttons, only one card shows "X KOs to go", and the rest say Locked.
   - This overrides item 8's "TRY before buy" and "Get it now" for weapons.

1. **PHONE FIRST: the whole game is built for a phone in landscape** (owner, 26 Nov 2026, after the phone screenshots: "Nu hvor jeg ser det på mobil, kan jeg pludselig godt forstå hvorfor vores spillere ikke spiller så længe"). Most players are on a phone. This is the biggest lever on the 1-5 minute leak, so it comes before everything except item 0.

   **What the phone screenshots show** (iPhone, landscape, 26 Nov):
   - **No clear thing to do.** The top pill reads "Every weapon..." (cut off and meaningless). There is no goal, no KO count and no "shoot that dummy".
   - **Your own FOUNDER and VIP tags sit in the middle of the screen**, right on the crosshair, and your character blocks the dummy you aim at.
   - **Grey dummies on a light grey floor under a white sky.** The targets almost vanish; everything looks washed out. The city map is fog-white.
   - **The left side is cluttered:** Shop, Menu (red !), REVIVE (unclear, shown while alive) and the Roblox buttons. The red ! badges are everywhere: Menu, RANK & EGGS, GIFT.
   - **Menus are a small window on a small screen:**
     - **Shop:** one card visible; FEATURED shows "Everything" even when you OWN it; "CODES" breaks into "CO DES".
     - **Weapons:** 4 tiny cards per row; pictures cut; descriptions cut ("Quick little pops. Your"); COMMON tags bigger than the picture.
     - **More:** a menu inside a menu (MAPS, LAB, GOD MODE, REWARDS, RANK & EGGS, FRIENDS, SETTINGS, FAVORITE…), so key things are 2 taps deep.
   - **The Map board in the world is unreadable** on a phone (tiny text on tiny thumbnails).
   - **The hotbar is small** (an unclear red kit icon, Popper, Sniper, Heal). RELOAD 17/17 is small. The SHOOT button is good.

   **The rule from now on:**
   - On a phone, the screen at any moment shows only the target, SHOOT, the hotbar and ONE goal line. Everything else is at most one tap away.
   - Every new UI is built and checked at phone size first (Studio Device emulator, iPhone landscape + a small Android), then tablet, console, PC.
   - Minimum touch target 44 px (Roblox's own guidance); no text under about 14 px on a phone; never cut text: shorten it.

   **Do, in this order** (each small, each published on its own):
   1. **Clean the centre.**
      - Hide your OWN overhead tags (FOUNDER, VIP, rank) for yourself on every device; others still see them. Smaller, higher tags on others.
      - Over-the-shoulder camera on a phone when holding a gun: the character moves left and down so the crosshair sees the target (`Config.PHONE_SHOULDER_CAM`). The first-person switch on the first shot stays as it is on PC; check what feels best on a phone and keep one.
   2. **Aim help on a phone** (`Config.PHONE_AIM_ASSIST`): a soft pull toward the nearest dummy within a small cone of the crosshair, and "tap a dummy to shoot it". The biggest mobile shooters all do this. Hit marker + a short haptic buzz (HapticService) on hit and on KO.
   3. **Targets you can see.**
      - Dummies must stand out from the floor: darker or warmer floor in the lab, or a slightly darker dummy grey (the owner keeps grey dummies; show 2 options as screenshots before picking).
      - Less fog and brighter, warmer light on the maps on phones; the city map must not be fog-white.
      - A small bobbing arrow over the nearest dummy for new players (first 2 min), off after the first few KOs.
   4. **One goal line instead of "Every weapon..."**: the top pill shows the next goal, short and live: "Next: Bow — 3 KOs" with a bar. When it is reached, a big unlock moment ("BOW UNLOCKED!", sound, buzz, auto-equip). This also carries item 4's minute moments ("Press the red button!", "Try the cannon!").
   5. **A clean left side and fewer badges.**
      - On a phone: Shop and Menu only, bigger (44 px+). REVIVE only shows when you are down.
      - **No notifications on a phone** (owner, 26 Nov: "fjern Free Gift notifikationer osv fra tlf"):
        - the GIFT button with its timer and red ! is gone from the phone HUD; the free gift is claimed from Menu → REWARDS (a quiet dot there only when it is ready);
        - no red ! badges on a phone at all (Menu, RANK & EGGS, …);
        - no pop-up toasts or banners on a phone for gifts, rewards, eggs, codes, "free try", sales, What's New, server events or other players. Only things about YOUR play stay, small and short: a KO, an unlock, low ammo;
        - What's New does not open by itself on a phone;
        - one switch, `Config.PHONE_QUIET = true`; tablets follow phones; PC and console keep today's notices.
   6. **Phone menus.**
      - Every menu opens nearly full-screen on a phone (safe area kept), with big close X.
      - **Weapons:** 2-3 big cards per row, a big picture, name, the lock or EQUIP; no description and no stats on a phone (tap a card for details).
      - **Shop:** FEATURED never shows an owned item (show the best unowned one); 2 big cards per row; tabs that fit (CODES not broken); the cheap starter offer first (item 8).
      - **More:** flatter. The 4 most used (MAPS, LAB, REWARDS, SETTINGS) as big buttons; the rest below. MAPS also gets its own button on the HUD if there is room.
   7. **The Map board:** on a phone, walking up to it (or tapping it) opens the big MAPS menu. The board itself gets fewer, bigger tiles with big names.
   8. **The hotbar:** bigger slots on a phone, a clear icon for the kit (or move it into Menu), the ammo shown on the slot, RELOAD bigger or automatic when empty.
   9. **Phone lag** goes with item 3: measure on a real mid phone, keep 60 fps in the lab and 30+ in events.
   10. **Portrait (upright):** check that the game is usable upright or lock it to landscape on phones; no half-broken middle state.
   - **Measure:** split every funnel step by device (phone / tablet / PC / console) in the custom events, so we see if the phone gap closes. Target: phone 5-min retention equal to PC within 2 weeks.
   - **Test selv** (after each sub-step): on your own phone, in landscape, from a fresh join: can you see what to do, hit a dummy within 10 seconds, and read every menu without zooming?

2. **Ragdolls fall through or half into the ground.**
   - Find the cause: a thin floor for fast bodies, the pad floor, new dummy masses, the time bubble, or spawning half inside the floor.
   - Fix: an invisible thick safety floor under the lab and every map; bodies always created above the floor; any body below the floor put back.
3. **Lag on every platform.**
   - Measure first: server heartbeat, script time, network, phone FPS.
   - Fix the 5 heaviest things: loops, bodies and effects caps, lights, far things, leaks.
   - Lower detail on weak phones without losing the PC look.
4. **Fix the 1-5 minute leak and find why people dislike** (the funnels of 26 Nov, `docs/FUNNELS.md`: half the players at 2 min are gone by 5 min, and 47 % stop between 10 and 25 KOs; targets are in that file).
   - **A new pull every minute in the first 5 minutes:**
     - unlocks close together early: a new weapon at about 3, 6, 10, 15, 20 and 25 KOs (retune `LADDER_V9_KEEP` / the first rungs, and keep the later gaps);
     - each unlock a big, satisfying reveal;
     - the "Next" bar is always visible.
   - **A planned moment at about 1, 2, 3 and 4 minutes** for new players, without pop-up spam:
     - about 1 min: the angry dummy (item 6);
     - about 2 min: a free mini event in your lab (the red button lights up: "Press me!");
     - about 3 min: the first terminal or creature gets pointed out (a calm glow);
     - about 4 min: the Map board gets pointed out ("New place unlocked: Island").
     - These go through Notify / FirstVisit and the V9-0g phone sizes.
   - **Variety past 10 KOs:** the walkers, the GOD mode spawns and the machines are in view. The dummy line-up changes now and then (new dummy types walking in), so there is always something new to hit.
   - **Measure:** add custom funnel steps (AnalyticsService funnel events) so the Creator Hub shows:
     - the minute moments above;
     - the first unlock, the first terminal used, the first map trip;
     - the tutorial steps (item 7);
     - shop: opened → item viewed → prompt → **bought**.
   - **Dislikes:**
     - read Session_v1 (leave times, errors, FPS by device) and the like ratio by version;
     - add an optional "How's the game?" thumbs + reason (no reward);
     - write a short report with the top 3 reasons and the fixes into `docs/FUNNELS.md`.
   - **Test selv:** play 5 minutes as a new player (StudioFresh) and note what happens each minute.
5. **Answer Roblox's mail about the maturity questionnaire** (they rejected the last answers).
   - Needs the owner to paste the mail and the old answers.
   - List what the game really contains: purple blood, guns, the words "Dead" and "bled out".
   - Draft honest answers, and offer the choice: keep the content and the label it gives, or tone it down for a lower age label.
   - **The owner submits.**
6. **The first dummy you hit twice gets angry**, unless the first shot kills it; then it is the next dummy hit twice.
   - Red face and a short tantrum; it runs at you and gives a harmless, funny shove or slap (no damage), then flees.
   - Once per player early on, then rarely.
   - The owner has not answered shove or scold yet: build the harmless shove behind `Config.ANGRY_SHOVE = true` (one switch to turn it into scolding only) and put the question in the owner list.
7. **A tutorial on every device** (PC, phone, tablet, console).
   - 3-4 short show-don't-tell steps: shoot a dummy, grab and throw, use a terminal, find the Map board.
   - The right input glyphs per device; skippable; newcomers only; no pop-ups on top.
   - Measure step completion.
8. **Best sellers, the shop and Robux** (funnel: only 8 % open the shop, and 11 % of them press buy).
   - **Read the sales:** what sells, where it stood, and whether it was tried first. Write the analysis into `docs/FUNNELS.md`.
   - **The shop opens more:**
     - a clear SHOP button;
     - the booths in the lab show a real, cheap, cool item;
     - (not on weapons: item 0 removes BUY there).
   - **More presses buy:**
     - one cheap starter offer first (R$ 25-49, clear big value);
     - a few strong items up front instead of a wall of passes;
     - "Popular" and "Best value" tags from the real sales;
     - TRY before buy on things that can be tried (not weapons, see item 0);
     - pictures and 3D that show what you get.
   - **Move the best sellers forward** in the lab and the shop, and rework or move the weak ones. Change what is shown in the lab.
   - **New items:**
     - **death effects** (fireworks, confetti, a ghost dummy floating up, gold sparkle, cartoon blast);
     - more cosmetics (trails, KO sounds, dummy skins, emotes);
     - fair, with no pay-to-win.
   - Give the owner the product list to create.
   - **Measure:** the shop funnel with a "Bought" step.

## Done in the run of 26 Nov 2026 (release 0.53.0, place saved v1110; Script Sync was OFF: every script went in through the MCP, checked by length)
- **0 done:** `WEAPONS_NO_BUY`, `WEAPONS_NO_TRY` (TrialService refuses), only the next weapon shows "N KOs to go", the rest LOCKED; every weapon sold in SHOP > ITEMS > WEAPONS (its tier product; "NEARLY YOURS" when within 15 KOs).
- **1 mostly done:** own FOUNDER/VIP tags hidden (`HIDE_OWN_TAGS`), phone shoulder cam with a gun (`PHONE_SHOULDER_CAM`), wider touch aim help + hit buzz (`PHONE_AIM_ASSIST`), darker dummies (92,95,102) and warmer hub floor, half the fog on phones (`PHONE_CLEAR_AIR`), bobbing arrow for newcomers (`TARGET_ARROW`), goal pill "Next: X  N KOs" (`GOAL_LINE`), `PHONE_QUIET` (Client/PhoneQuiet: no gift button, no red badges, no pop-ups about gifts/eggs/codes/sales, no event card, no auto What's New, REVIVE only when a dummy is down), `PHONE_MENUS` (3 big weapon cards a row, FEATURED hides owned, CODES on one line, walking to the MAPS board opens MAPS). 1.10: portrait was already locked to landscape (StarterGui + LoadCover). 1.6 `PHONE_MORE_FLAT` (MORE starts with MAPS, LAB, REWARDS, SETTINGS) and 1.8 `PHONE_BIG_HOTBAR` (landscape phone slots 62x56) are in Studio and saved (v1111). **Left:** real-phone FPS.
- **2 done:** GroundGuard rescues a body with nothing under it and lifts a sunk head/chest, taking the body from its player for 0.5 s (`GROUND_RESCUE`).
- **3 partly:** measured (server p95 18 ms; client UI 22.7k objects, WEAPONS alone 8.7k); WEAPONS builds a shelf when shown (`LAZY_SHELVES`, now 16.3k total). **Left:** a real mid phone, lights/beams on phones.
- **4 partly:** the ladder already unlocks at 3,4,5,8,10,13,16,18,21,24 KOs (denser than the target): unchanged. Minute moments at 2/3/4 min in the goal pill with a white outline (`MINUTE_MOMENTS`, Client/MinuteMoments). Funnels NewPhone/NewTablet/NewPC/NewConsole + "Tutorial"; player attribute `Device`. **Left:** read Session_v1 + like ratio, the "How's the game?" prompt, the dislike report.
- **5 prepared:** docs/MATURITY.md (what the game contains + two answer options). Owner submits.
- **6 done:** `ANGRY_FIRST` + `ANGRY_SHOVE` in Mourning.provoke (2nd hit on one dummy, newcomers under 60 KOs, once a visit).
- **7 done:** FirstVisit got "GRAB a dummy and THROW it!" and "Walk to the MAPS board"; each step logs the Tutorial funnel.
- **8 partly:** `SHOP_CHEAP_FIRST` (hero = Starter Crate R$49, cheaper FEATURED picks). **Left:** sales analysis (live data), death effects / cosmetics (need product ids).
- Not published yet: the owner presses Alt+P (no publish action over MCP; Open Cloud cannot upload .rbxl).

## Questions for the owner (filled in during the run)
- X-RAY key: B is already Build mode, so X-RAY is on I now (default). OK, or another key?
- Angry dummy: a harmless shove (now) or scolding only? (`ANGRY_SHOVE`)
- Dummy colour: darker grey (92,95,102, now) or the old (112,114,118)?
- Maturity: keep the gore (13+/17+) or switch it off for all ages? See docs/MATURITY.md.
- Death effects to sell (fireworks, confetti, ghost, gold sparkle, cartoon blast, R$ 49-99 each): create them as passes and send the ids?
- Script Sync is off in Studio: turn it on again, or allow localhost in MCP HTTP allow list (faster, cheaper sessions).
- (26 Nov, F12) Studio now saves to the Multiplayer place. Publish BOTH: File > Publish to Roblox As > the start place (126037745825106) > Overwrite, and the multiplayer place. OK?
- (26 Nov, F13) REVIVE ALL kept its key X (R and Z are taken). OK?
- (26 Nov, F10) The German Shepherd is one rigid mesh (no free rigged one found), moved by code (trot bob, wiggle, bite shake). For real leg animations: buy or send a rigged German Shepherd (Creator Store id), or keep this?

## Phone button map (checked 26 Nov 2026, 0.63.0, iPhone landscape 750x381 in the emulator with DevTouch)
- **Left:** Shop and Menu in row 1, then Multiplayer (`HudMenu.PHONE_KEEP`, `PortalUI` launcher). The move stick is under them.
- **Top centre:** goal pill and gift (no red ! under `PHONE_QUIET`).
- **Top right:** first-person eye, with the body-card arrow just left of it. The arrow moves left of LAB VIEW when that shows.
- **Right column:** X-RAY (60 px, y 62), RELOAD, JUMP.
- **Right bottom:** SHOOT, with TRY right over it (FirstTwo places TRY from SHOOT's real spot).
- **Bottom centre:** the hotbar, 62x56 slots.
- **Studio note:** without DevTouch the emulator reads as a touch laptop and shows the PC sandbox column (1ST/SLOW-MO/REVIVE/RESET), which overlaps JUMP. Real phones never show it.
- Picture: `art/store/phone_hud_0.63.jpg`.
