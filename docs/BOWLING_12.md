# RAGDOLL BOWLING 12/10: our HOOK (owner, 26 Nov 2026 late)
> "Sørg for bowling delen er vores bedste aspekt både udseendemæssigt og animationsmæssigt, det skal være vores HOOK som holder spillerne, da det er den første maskine alle prøver"

**Why:** it is the first machine every new player tries (FTUE_10), 4 seconds from the spawn. If THIS feels amazing, they stay. So it gets the best model, the best animation and the most "juice" in the whole game.

This doc REPLACES the build part of F88 (its place in the plan and the chicken move stay). It is built in PHASE 4 (the map), right after M4, as ONE pass: model, animation and game together.

## 0. FIRST FIX (owner, 27 Nov: "Gør så man faktisk ser ragdollen blive krøllet hurtigt sammen og flyve ind i keglerne, ikke bare halvejs ind på banen")
**Why it fails today** (`Systems/Bowling.luau` ~226-262):
- the ragdoll is only put on its side (`PivotTo` with -80 degrees, NOT curled) and given ONE push (`DummyControl.hit`) plus a spin, so a limp body slides and flops with the lane's friction and stops halfway;
- the first-roll STRIKE knocks the pins over on a 1.5 s timer whether the ragdoll got there or not, so the pins fly while the ragdoll is still lying halfway down the lane.

**The fix** (`Config.BOWL_BALL = true`):
1. **The curl, fast and visible (0.25 s):**
   - the ragdoll tucks into a tight BALL: knees to the chest, arms round the shins, head down;
   - held by a strong pose (tone 1 on every joint) while it rolls;
   - its face scared and dizzy (BODY_V2 4b).
2. **A real ball:**
   - while curled, the ragdoll rides inside an invisible SPHERE collider (about 3.6 across, the curled body welded and massless inside, its limbs' own collisions off), so it ROLLS like a bowling ball instead of flopping;
   - the lane is low friction (about 0.08), the ball 0.3 with no bounce; the gutters keep it on the lane.
3. **The throw:**
   - the sphere gets a real speed down the lane: 45-65 studs/s (by the swipe power, BOWLING_12 3; a tap = 55), and a forward spin to match;
   - a tiny curve by the swipe angle;
   - **min-speed guard:** if it drops under 25 studs/s before the pin deck, the lane gives it a soft push, so it ALWAYS reaches the pins (except a real gutter ball, which rolls on in the gutter to the pit).
4. **The impact:** as the sphere reaches the first pin, the ragdoll BURSTS out of the curl (the sphere removed, the tone drops, its speed kept) and flies into the pins as a full ragdoll, so the pins scatter from a real body. A slow motion of 0.4 s on a strike (BOWLING_12 2).
5. **The guaranteed first STRIKE (FTUE):**
   - it comes from the BALL: the first roll's sphere follows the lane's centre line exactly (an AlignPosition along the lane, ending at the head pin) at 60 studs/s;
   - the knock-over of any pin still standing happens only AFTER the ball has hit the pins (an impact trigger, not a timer).
6. **Smooth on every screen:**
   - during a roll, the bowler's client owns the sphere AND the 10 pins (`SetNetworkOwner`), so the roll and the crash are smooth with no hitch;
   - the server owns them again when the pins are counted.
7. **Afterwards:** the ragdoll gets up dizzy in the pit, takes a bow on a strike (or a face-palm on a gutter) and walks back (BOWLING_12 2.7).
8. **Check (the owner):** tap BOWL or TRY. The ragdoll curls up into a ball in a blink, rolls fast all the way down, and smashes into the pins; the pins fly only when it hits them. 10 rolls in a row: all reach the pins (a gutter rolls to the end in the gutter).

## 1. The look (Blender, the CREATURES_ANIM 4 style pushed to its best)
- **The lane:**
  - about 44 long, 8 wide, glossy maple wood planks with a clear coat (SurfaceAppearance: roughness 0.25, a soft reflection);
  - dark wood edges; 7 aiming arrows and the dots inlaid in the wood;
  - the foul line in red; round chrome gutters on both sides.
- **The approach:** a lighter wood run-up area with a small stand where the "bowler" ragdoll waits.
- **The pins:**
  - 10 GIANT pins (about 5 high), the real classic shape (a curved neck and belly), glossy white with 2 red neck stripes;
  - bevelled and smooth, a baked soft shadow on the deck;
  - a light physical weight and a high bounce (Elasticity about 0.35), so they fly and spin nicely.
- **The pin deck:** a dark back pit (a soft padded "cushion"), side kickback walls with a retro stripe, and the PIN-SETTER: a hood above the pins with a sweep bar that comes down and lifts.
- **The ball return:** a chrome-and-blue return rack by the approach. A curled-up ragdoll pops out of it on TRY: it is the "ball dispenser".
- **The scoreboard:**
  - a big retro screen on 2 posts above the pins (a dark frame, a chrome trim, bulb lights round the edge that chase on a strike);
  - it shows the frame score, the player's BEST, and "TODAY'S BEST" with the top 3 names (no free text);
  - a big animated word on events: STRIKE!, SPARE!, SPLIT!, GUTTER…
- **The setting:**
  - a low roof over the lane on slim posts, open at the sides, so it reads from the spawn and the camera never fights it;
  - warm under-roof lights (2 PointLights, no shadows) that make the lane glow;
  - 2 benches with watchers, a small rack of spare "balls" (curled ragdolls asleep), a pair of giant bowling shoes as a prop.
- **Budget:** about 12,000 triangles for the whole set; the pins 400 each.

## 2. The animations: the ragdoll IS the ball (Blender clips through `BoneAnimator`, then physics)
**One roll is a 4-second show, in beats:**
1. **The dispenser (0.6 s):** the ball return thumps and the curled ragdoll pops out onto the approach with a bounce, uncurls and stands up.
2. **The stretch (0.8 s):** it shakes out its arms, cracks its neck, blows on its hands, and looks down the lane (determined face, BODY_V2 4b).
3. **The run-up (0.7 s):** 3 fast steps with its arms swinging.
4. **The dive (0.3 s):** it jumps forward, tucks its knees to its chest, its arms round its legs, and curls into a BALL in the air (squash and stretch). Then it lands on the lane rolling.
5. **The roll (1-1.5 s):**
   - real physics: the ball body (one round collider with the curled ragdoll welded inside it, posed) rolls down the lane;
   - the curled body spins with it, and its face shows each half-turn (dizzy, then scared just before the pins);
   - wood "rumble" sound; speed lines and a faint trail;
   - the camera does NOT move (no camera grab), but a soft zoom (FOV -6) helps the moment.
6. **The impact:**
   - **STRIKE:** a slow-motion of 0.4 s at the hit (TimeScale on this screen only, `SlowMotion`); the pins explode back and spin, a sparkle burst, the bulbs chase, a bell, and a crowd cheer from the watchers;
   - **SPLIT:** "SPLIT!" and a groan;
   - **SPARE** (the second roll): a big "SPARE!";
   - **GUTTER:** the ball drops into the gutter with a clunk, rolls past sadly, and a sad trombone plays.
7. **The aftermath (1 s):** the ragdoll uncurls in the pit, dizzy (stars circle its head), staggers out, takes a bow on a strike (or face-palms on a gutter), and walks back along the side to the bench.
8. **The pin-setter (1.2 s):** the sweep bar lowers and sweeps the fallen pins back, the hood lowers and sets 10 fresh pins with a "clack-clack-clack" (pins tweened into place, then put back to physics, asleep).

**Pins:**
- they wobble when hit gently (a little tilt-and-recover) and fall with real physics;
- each fallen pin flashes once;
- a pin that is "almost falling" gets a teetering animation (the suspense) before it decides.

## 3. The game: easy for a 10-year-old, deep enough to keep going
- **Bowling:**
  - TRY (the first time; the FTUE guided strike) or the big RED LEVER on the approach (any time);
  - on a PHONE, **one-swipe bowling**: put your thumb on the ball area and swipe up the lane; the direction is the aim and the swipe speed is the power, with a dotted aim line while you drag. A tap instead is a straight medium roll;
  - on a PC: hold the left mouse to aim with the mouse, release to roll (or E for a straight roll);
  - you can also THROW any ragdoll down the lane yourself, and it counts.
- **Scoring:**
  - a frame is 2 rolls; pins knocked = points, real bowling rules made simple (a strike = 10 + the next 2 rolls, shown as a big number);
  - a 3-frame "mini game" (about 40 s) gives a total score: **TODAY'S BEST** and **YOUR BEST**;
  - "NEW BEST!" with confetti.
- **Juice and surprises:**
  - **TURKEY** (3 strikes in a row): a turkey trophy pops out on the scoreboard and gobbles;
  - **GOLDEN PIN** (1 in 8 setups): one pin is gold; knock it for bonus BOLTS;
  - **BIG BALL** (1 in 12): the dispenser sends out a giant ragdoll (2x size) that flattens everything;
  - **the WATCHERS:** CURIOUS ragdolls come to watch and cheer or boo, and a HERO might stand behind the pins and get bowled over;
  - **the gutter guard** in the first session: after 2 gutters in a row the bumpers rise ("kid mode") for the next roll.
- **Rewards:** BOLTS per strike and spare (small), a one-time badge for the first strike and the first turkey, and a "bowling" line in the collection page.
- **Never:** a purchase prompt here in the first session; long waits (a roll is at most about 4 s, the reset 1.2 s).

## 4. Phones first, and cheap
- **Swiping:** the swipe area is the lower middle of the screen while you stand on the approach (a soft hand icon shows "Swipe!" the first time only); the joystick and buttons stay where they are.
- **Pins:** the 10 pins sleep until touched; at most 10 physics pins plus the ball at a time.
- **Effects and sounds:** pooled; the slow motion is local; the lights only within 140 studs; the scoreboard is one SurfaceGui with a MaxDistance.
- **Frame rate:** 60 fps on a mid phone while bowling.

## 5. Check (the owner, phone first)
1. From the spawn, the lane is the first thing you see, and it looks like the best thing in the game.
2. TRY: the ball return pops out a ragdoll, it stretches, runs, dives, curls up and rolls; the first one is a STRIKE with slow motion, bulbs, bell and cheers.
3. Swipe to bowl again: the aim and the power follow your swipe.
4. The pin-setter sweeps and sets the pins.
5. A gutter plays the sad trombone; a turkey shows the trophy.
6. The score and the bests show on the board.
