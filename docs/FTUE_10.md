# THE FIRST 30 SECONDS TO THE FIRST 20 MINUTES, 10/10 on phones and tablets (owner, 26 Nov 2026 late)
> "Sørg for vores tutorial, altså det hvor det får en i gang med de første 2 minutter, 5 minutter osv er bedst mulig, og fungerer med det nye map, kig dybt i hvordan vi gør bedst så tlf/tablet får den absolut bedste oplevelse for et ragdoll spil lige nu i roblox. Ikke noget 7/10 arbejde, 10/10"

**This REPLACES** `FIRST_2_MIN.md` (its TRY lesson is gone: F81 makes TRY automatic) and merges `STAY_LONGER.md`'s plan into one timeline. Build it ONCE, here.

## The principles (what the best Roblox games do in their first minutes)
1. **Action in the first 5 seconds, a "WOW" before 30 seconds.** No reading, no menus, no waiting.
2. **Show, don't tell:** at most 3 words on screen at a time, plus an icon. A faint line on the ground shows the way; nothing floats over the action.
3. **ONE goal and ONE hint at a time,** never two. A small goal line at the top says what to do next, and it is always close: under 30 seconds of walking or doing.
4. **A reward every 30-90 seconds in the first 5 minutes,** then every 2-3 minutes up to 20.
5. **The world shows off by itself:** ragdolls react, animals do things, machines run with watchers. The player should feel "there is so much here".
6. **Phone first:**
   - thumbs only, big targets (at least 48 px, the main ones 70);
   - no key letters;
   - nothing covers the middle of the screen;
   - the mini hotbar (F71);
   - 60 fps at the spawn on a mid phone.
7. **Never again for returning players:** every beat is saved as done in the profile. A returning player starts at their next goal, and a rejoin in the middle of the timeline resumes it.

## ONE director runs it all (`Client/FirstTen.luau` + a small server part; `Config.FTUE_10 = true`)
- **It owns these and runs them as beats:** the goal line, the ground line (a faint dotted Beam along the walkways to the next target), the single hint, and the timed moments.
- **Turn off, or route through it:** FirstVisit's steps, `MINUTE_MOMENTS`, `TARGET_ARROW`, the old TRY sign, and any other first-minute pop-up.
- **The rules:**
  - a beat waits while another runs, while a machine show plays, or while the player is in a menu;
  - every beat can be skipped by simply doing something else; the director then picks the next nearest goal;
  - the funnel step of each beat goes to Analytics (by device).

## The timeline (a new player, on the new compact map)
The spawn is on the raised plaza facing south. Right below the stair: RAGDOLL BOWLING on the west side of the spine (F88) and the VEHICLE ROW on the east side (F76). Down the spine are the boxing ring (west) and the sandcastle, fan and tesla (east), then the tower; the cannon is in the south-west.

| When | What happens | The goal line | Notes |
|---|---|---|---|
| **0-3 s** | Loading is short: the spawn area is preloaded (a persistent streaming area; the first weapon's sounds, the splash and the bone-crack effects preloaded). The first-join camera glide lasts 3 s at most and stops at any touch. | - | the quality governor picks the device tier BEFORE the first frame |
| **3-10 s** | The 3 near ragdolls stand ON the spawn plaza within 8-12 studs of you (not below the stair), facing you; one waves, "Hey! Over here!". A new player starts with the FIST selected (the only weapon). | "Hit a ragdoll!" | on a phone: TAP a ragdoll = hit, HOLD = grab (fix 3) |
| **10-20 s** | The first ragdolls are "newcomer soft": 2 hits knock one out. The first hit shows everything at once: the push, the purple splash, a bone CRACK (D12), the angry or scared reaction (P1). | - | the first KO must happen within 15 s |
| **20-40 s** | The ground line leads down the stair to the bowling lane (about 60 studs, 4 s). TRY there: a ragdoll rolls down. **The FIRST roll of a new player is always a STRIKE** (fix 5). Confetti, cheers, "+BOLTS". THIS IS THE WOW. | "Bowl a STRIKE!" | the TRY button (big, right side on a phone) shows when you are near; after TRY, the lane's LEVER bowls again any time |
| **40-60 s** | The first weapon unlock: a toy PISTOL at 3 KOs (the unlock happens when earned; its BEAT waits until the bowling is done, fix 1). The mini hotbar opens 1.5 s with the new slot popping (F71). | "Shoot a ragdoll!" | the pistol: the different shot, the splash and drips, bone damage adding up |
| **60-90 s** | The first gift is ready (the gift chip, 1 min). | "Open your gift!" | tap the chip; a short, satisfying open |
| **1:30-3:30** | THE TOUR, one walking loop with no back-tracking (fix 6): BOXING RING (beside the spine) → GIANT FAN → TESLA → the TOWER slide (the landmark) → the CANNON (south-west, about 12 s walk from the tower). TRY: automatic (F81), with the machine's show (CREATURES_ANIM). Pops "2/6" … "6/6". | "Try the BOXING RING" … | each step under 15 s of walking at the normal speed (16) |
| **about 2:00** | The first SURPRISE: a GOLDEN RAGDOLL runs past (it is worth 10 KOs), with a 10 s countdown on the goal line. | "Catch the GOLDEN one!" | only when no beat runs |
| **2:30-3:30** | **The X-RAY moment:** after the first bone break (or at 3:00), the X-RAY button pulses once. Tap it: the cracked bones show. | "See the bones!" | the pulse only once, ever |
| **after the tour** | **The BIKE, only when useful** (fix 7): the first time the next goal is more than 150 studs away, the goal line says "Faster: free BIKE" and points to the NEAREST free bicycle (a second free bicycle stand at the tower square, so it is never a walk back to the spawn) | "Faster: free BIKE" | the paid vehicles in the entrance row are seen on the way out of the spawn, never pushed |
| **3:00-4:00** | **The CANNON** ends the tour, the biggest show: TRY; BOOM; the landing distance pops with "NEW BEST"; then "6/6" | "Fire the CANNON!" | |
| **4:00-5:00** | "Tried 6/6" gives the TOUR REWARD (a free egg or crate, opened at once, server-checked); the 3 min and 5 min gifts are ready in between (their beats wait for the shows) | - | |
| **5-10 min** | **The world takes over:** the personalities (P1), the animals' idles and catches, the 2-minute surprises (a ragdoll rain, a giant ragdoll, the free red-button event), the next weapons close together (6 unlocks by about 25 KOs), "NEW BEST" moments (bowling, cannon, slide). | the goal line always shows the next weapon ("3 KOs to the BOW") or the next untried machine | one goal at a time |
| **about 8 min** | One quiet offer: "Play with friends" opens MULTIPLAYER (once, never again) | - | |
| **10-20 min** | **Long goals:** RANK 2-3 with a reward each (a ragdoll skin, a hit effect, a title), the collection page (machines tried, animals fed, bones broken), the 8, 12, 16 min gifts; at 12 min a quiet line "Tomorrow: DAY 2 chest"; at 20 min the big gift (a rare skin or weapon). After the first great moment (a strike, a cannon best), ask ONCE for Roblox experience notifications. | the next rank or gift | |
| **Day 2+** | The DAILY CHEST on the spawn plaza (a streak, day 1-7, growing), and the next goal where they stopped | "Claim DAY 2!" | |

## The deep review: problems found in this plan, and how they are solved (26 Nov late)
1. **Two beats at once:** the pistol unlock, the gift, the golden ragdoll and the tour can all fire in the same minute.
   - **Fix:** the director has a QUEUE with priorities (a show playing > the tour step > the unlock pop > the gift > a surprise).
   - Unlocks and gifts are earned at once but SHOWN when the queue reaches them.
   - Surprises only start between tour steps, never during a show.
   - The goal line swaps to a surprise and back.
2. **Frustration at the start:** a SCARED ragdoll flees at the first hit, and the angry shove (ANGRY_FIRST) knocks a 10-year-old over in their first 20 seconds.
   - **Fix:** for a new player's first 3 minutes, the 3 near are CURIOUS, CHILL or HERO only, and do not flee; there are no angry shoves; the hero only says "Hey!" and stands up for the victim.
3. **Touch controls:** "tap to hit" can clash with grab, camera drag and the Push/Fall buttons.
   - **Fix, one simple rule on touch:**
     - a short TAP on a ragdoll in reach hits with the selected melee;
     - HOLD 0.35 s on it grabs;
     - a drag that starts on empty space turns the camera;
     - the PUSH and FALL buttons stay as they are.
   - The hotbar's hand slot is not needed to grab on touch.
4. **The spawn is raised:** the 3 near used to stand below the stair. **Fix:** for new players they stand ON the plaza within 8-12 studs, so the first hit is 2 seconds away.
5. **"The first roll is always a STRIKE"** cannot be left to physics, or it will fail sometimes.
   - **Fix:** the first roll of a new player is guided: the curled ragdoll follows the lane's centre line (an AlignPosition along the lane), and the pins get their knock impulses on contact.
   - Every roll after that is real physics.
6. **Back-and-forth walking:** the first draft sent the player down to the tower and then back up to the bike at the spawn. Since F83 there is no sprint (walk speed 16), so every detour costs time.
   - **Fix:** ONE loop with no back-tracking, each step under 15 s of walking: bowling → boxing ring → giant fan → tesla → tower slide → cannon.
7. **The bike was a detour.** **Fix:**
   - a SECOND free bicycle stand at the tower square;
   - the bike beat only when the next goal is over 150 studs away, pointing to the nearest stand.
8. **TRY is once per machine (F1):** after the tour a player might not know how to run a machine again.
   - **Fix:** at the end of every TRY show, the machine's own button or lever glows once ("Again? Press it!", 2 words).
   - The bowling lane has its lever.
9. **The golden ragdoll on a phone** is hard to catch while running.
   - **Fix:** in the first session it jogs (not sprints) in a circle round the player's area for 15 s, and any hit counts.
10. **Rewards must be safe:** the gifts, the tour reward and the daily chest are claimed through validated `Net` remotes. The server checks the time, the tries and the day, never the client.
11. **Returning players:** they must never see the beginner rules. **Fix:**
    - each beat is a saved flag;
    - a returning player gets the FULL HUD, the normal personas and the angry shoves;
    - a day-2 player starts with the daily chest beat, then the next goal (the next weapon, rank or untried machine).
12. **Money:**
    - **no purchase prompt** in a new player's first 10 minutes. The shop can be opened, and the vehicles show their prices passively.
    - The starter offer may show once after 10 minutes, never over the action.
13. **The first frame, on weak phones:**
    - the quality governor picks the tier before the first frame;
    - the spawn area is a persistent streaming model;
    - the preload (`ContentProvider:PreloadAsync`: the fist and pistol sounds, the splash, the crack, the bowling pins, the confetti) runs in the background and never holds the spawn longer than 3 s;
    - no hitch on the first hit: the effects are pooled, made in advance;
    - the floor: 30 fps on a low phone, 60 on a mid phone.
14. **Orientation:** phones and tablets play in LANDSCAPE (`ScreenOrientation` LandscapeSensor), where the thumbs and the HUD were designed.
15. **Too much at once later:** after 5 minutes the world "takes over", but the goal line must not go empty.
    - **Fix:** the goal line ALWAYS has one next goal, in this order: the next weapon if 5 KOs away or less; else the next untried machine; else the next rank; else the next gift.
16. **The 8-minute multiplayer offer** teleports the player away and can cut the session.
    - **Fix:** it is a small, quiet chip for 10 s that is easy to ignore, only when the player is idle (not in a show or a fight), once ever.
17. **The notification ask** must follow Roblox's rules: it is asked once, right after a great moment the player caused (a strike, a cannon best), with the Roblox prompt only (`ExperienceNotificationService`), never forced.

## Phones and tablets: the details that make it 10/10
- **The HUD at the start** is only: the joystick, jump, the action button (HIT/SHOOT), the mini hotbar, the goal line, the gift chip, and the MENU. Everything else appears when it is first needed (X-RAY at the X-ray beat, the Events button after the first surprise, MAPS after 10 min).
- **Tap to hit:** on a touch screen, a tap on a ragdoll within reach attacks it with the selected melee weapon (as well as the button). Guns get a light aim assist toward the nearest ragdoll in the crosshair cone for the first 10 minutes on touch.
- **Big targets:** TRY at least 70 px; gift CLAIM at least 64 px; nothing under 48. Safe areas respected (notch, home bar). Landscape and portrait both work; the tablet gets the phone layout at a larger scale.
- **Feel:** a light haptic (`HapticService`, where supported) on a strike, a bone break and a cannon boom. Sound mixed for phone speakers (the splash, the crack, the cheer are clear).
- **Speed:** 60 fps target at the spawn on a mid phone; the bowling pins asleep until hit; effects pooled; the path walkers' phone numbers (LIFE_IDLE 4).
- **Text:** never more than 3 words in the goal line; no tutorials in boxes; no "press E" on a phone.

## Order and no double work
- This is the first row of PHASE 7. It uses everything built before it: TRY (F81), the bowling (F88), the vehicles (F76), the cannon, the gifts, the surprises, the unlocks, D12, P1 and the X-ray.
- It REPLACES `FIRST_2_MIN.md`, and builds what is left of `STAY_LONGER.md`: the gift steps, the 2-minute surprises, the unlock pacing, ranks with prizes, the collection, best scores, the daily chest, the notification ask. Row 16 is folded in here.
- The A/B test and the pacing check stay dropped: the owner tests.

## Check (the owner, on a phone first): one list in the final message
Start as a NEW player (reset the profile with the Studio command the run leaves for this: `_G.ResetMe()` or an admin button), then go through the timeline above. Each row is one line of the test list.
