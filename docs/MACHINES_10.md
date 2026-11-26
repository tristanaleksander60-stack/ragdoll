# Every machine, animal and activity from 2/10 to 10/10 (owner, 26 Nov 2026)
> "Lav en detaljeret plan for hvordan Claude Code skal gøre hver eneste af vores maskiner og dyr og ting man kan gøre derinde fra 2/10 til 10/10 på alle parametre og at det er satisfying."

**How to use this doc**
- Work through the items in the PRIORITY order (section 2).
- Each item must pass the **SATISFY-10 standard** (section 1). Score it honestly before and after, 0-10 per point, and write the scores in "State" at the end.
- An item is done at 9+ on every point.
- One quick Play per item, commit and push, then go on. Never stop to ask; questions go into the NOW.md owner list.
- Gore stays OFF everywhere: purple cartoon splats, X-ray bones (breaks and shatters allowed inside X-ray), dizzy stars and soot. Never red blood, flesh or loose body parts.
- Phone first: every input is one tap, and every effect stays inside the phone caps (`docs/PERF_MOBILE.md`).
- Positions come from `Shared/OwnerMapPlan` (`docs/MAP_MASTERPLAN.md`).

## 1. SATISFY-10: the standard every item must hit

| # | Point | What 10/10 means |
|---|---|---|
| 1 | **Read it in 1 second** | Its shape says what it does. A big pictogram sign; a watcher line about it ("I'm NOT getting in that"). |
| 2 | **One easy input** | TRY at the machine, then put a ragdoll in (grab + drop on the glowing load spot), or one big button. Phone: 60 px+, never two steps that could be one. |
| 3 | **Anticipation** (0.5-1.5 s) | A wind-up before the payoff: a charging hum that rises in pitch, warning lights, a shake, 3 beeps or a lever pull. The watchers lean in. |
| 4 | **A big physical payoff** | A REAL ragdoll on the real physics (never a canned animation), with exaggerated force, plus a clear arc or spin you can follow. |
| 5 | **Juice** | Layered sound (wind-up, hit, tail and echo); particles (dust, sparks, smoke, splash, by surface); for the player who started it: a camera shake, a quick FOV kick, a 40-60 ms hit-stop at the peak and a phone haptic. |
| 6 | **The ragdoll lives through it** | A face for each moment (fear going in, dizzy after). Injury stages and bones in X-ray (breaks by force). It lands with the impact effects and gets up dizzy, or is knocked out (CPR, burial). |
| 7 | **Score and reward** | A number pop that fits the item (distance, height, spins, G-force, "FLAT x3"), NEW BEST, and a small leaderboard on its sign. First use +25 BOLTS (exists); a KO counts. |
| 8 | **Variety** | 2-3 outcomes by input (charge, timing, where you drop it) or by chance, plus a rare golden result (1 in 20) with a gold flash and a bonus. |
| 9 | **Social** | Watchers react (cheer, wince, cover eyes, a line about it). In multiplayer everyone sees it, and the name of whoever started it shows on its sign for 5 s. |
| 10 | **Flow and reset** | Ready again in 5 s or less, with a ring showing the cooldown. Nothing gets stuck (the machine ejects the ragdoll after 15 s at most). The attract demo runs once per visit with a real ragdoll that you SEE walk there and climb in (F19 + F31); never a body flying out of the blue. It works in the solo and multiplayer places. |

**Tech for every item:**
- The server decides; remotes go through Net with validators.
- Effects are client-side and pooled.
- It works with StreamingEnabled.
- A Config switch per item (`M10_<NAME>`); false = today.

## 2. PRIORITY (by how many players touch it in the first 5 minutes)
1. Cannon
2. Tower + slide + plank
3. Gyro cage
4. Giant fan
5. Trampoline
6. Wrecking ball
7. Press
8. Washer
9. Rocket
10. Launch pads + brick wall
11. Guard dog
12. Shark (aquarium)
13. Spider
14. Frog
15. Plant
16. Cars + tank + monster truck
17. Boxing ring
18. Stretch machine
19. Tesla coil
20. Shredder
21. Sweeper
22. Lava strip
23. Mole
24. Slingshot + archery
25. Chicken
26. Whale (pool)
27. Bear (cave)
28. Crocodiles
29. T-rex
30. Red-button events
31. Weapon range
32. Bicycle, motorbike, wheelchairs
33. The small fun spots (playground, seesaw, sandbox, sand circle, picnic and grill, duck pond, training yard, train)
34. The player actions (grab, throw, SLAM, lasso, CPR, revive, X-ray, burial)
35. Weapons (by class)

## 3. The items
For each item: **today's problems** (what makes it 2/10), then the **10/10 build**.

### 3.1 CANNON (Launch Field, fires west over the landing field)
- **Today:** the load is new (F7). The flight is plain, with no aiming and no score that feels good.
- **10/10:**
  - **Load:** drop a ragdoll on the glowing muzzle spot. It slides in feet first and its legs kick as it goes in.
  - **Aim:** a big round lever (phone: drag left or right on a semicircle, or tap the left/right arrows) turns the barrel ±25°, and the elevation goes up and down. A dotted arc preview shows on the field (it fades after 2 s).
  - **Wind-up:** the fuse sparks and hisses for 1 s, the barrel shakes, and the watchers cover their ears.
  - **Payoff:** a BOOM with a smoke ring, the barrel recoils, the ragdoll spins out with a smoke trail and a long arc, then lands with a dust burst and bounces.
  - **Score:** the distance in studs pops where it lands, plus 3 targets on the field (a hay bale ring, a pool, a bullseye-free paint circle) for bonus.
  - **Golden:** a gold confetti burst.
  - **Reset:** ready in 3 s.

### 3.2 TOWER, SLIDE and PLANK (Tower Square)
- **Today:** it is a big climb. The slide and the plank are not clear, there is no height score, and no reason to go up.
- **10/10:**
  - **Up:** the stairs (fast, with a 1.5x climb speed on the steps) or a quick freight LIFT (a cage on the side, a button, 4 s up).
  - **Top deck:** a PUSH plank sticking out over the airbag or trampoline below, with a height board ("95 studs"). Grab a ragdoll and walk it to the plank's end, or a TRY ragdoll walks out.
  - **Push:** tap PUSH: it windmills, then falls.
  - **Payoff:** a long fall with the arms flailing, a whoosh that rises in pitch, a big airbag "FWUMP" with a bounce, or a splat if it misses.
  - **Score:** fall height, flips counted ("2 FLIPS"), a NEW BEST.
  - **The slide:** sit a ragdoll at the top. It speeds down with sparks on the bends and launches off the end into the square. Score: launch distance.
  - **Golden:** a perfect landing on the airbag bullseye gives a slow-mo replay of the last 2 s, only for that player.

### 3.3 GYRO CAGE (Machine Hall)
- **Today:** the rings turn, but it is unclear how to load it and nothing happens after.
- **10/10:**
  - **Load:** drop a ragdoll in the middle and leather straps snap round its wrists and ankles.
  - **Spin:** press the big red button (phone: HOLD to spin faster: the longer you hold, the faster, shown on a dial).
  - **Payoff:** the rings spin on 3 axes, with motion blur. The ragdoll's face goes from scared to dizzy to green. A whirring motor sound rises.
  - **Release:** the straps pop at full speed, it is flung out in the direction of the spin, tumbles, and lands dizzy (spiral eyes, it wobbles for 5 s).
  - **Score:** the top RPM and the G-force ("9.4 G!").
  - **Golden:** a rainbow ring trail.

### 3.4 GIANT FAN (Machine Hall)
- **10/10:**
  - **Start:** a dial (phone: a big slider) for 3 speeds.
  - **Wind-up:** the fan spins up with a jet sound, and leaves and dust blow out in a cone.
  - **Payoff:** any ragdoll in the cone is pushed, then lifted, then blown backwards tumbling, by speed. Its clothes and limbs flutter.
  - **Score:** the distance blown.
  - **Extra:** at full speed the player is pushed too, but can lean into it (a slow walk).

### 3.5 TRAMPOLINE (raised, Tower Square)
- **10/10:**
  - **Bounces:** drop or throw a ragdoll on it, or jump on it yourself; each bounce goes higher (up to 5). Its arms and legs flop with every bounce. A spring "boing" sound rises in pitch.
  - **Score:** the bounce count and the max height.
  - **Combo:** the player bounces with a ragdoll ("DOUBLE BOUNCE"), with the bigger launch going to the ragdoll.

### 3.6 WRECKING BALL (Crash Yard)
- **10/10:**
  - **Pull back:** a lever pulls the ball back with a ratchet click (phone: hold to pull, release to swing). Pull farther = more force.
  - **Payoff:** a heavy whoosh, then THE HIT: a hit-stop, a dent ring, the ragdoll flying, plus barrels and crates in its path flying too (breakables).
  - **Score:** the force and the distance.
  - **Variety:** a ragdoll standing on the crate stack is a big multi-hit.

### 3.7 PRESS (Machine Hall)
- **10/10:**
  - **Load:** drop a ragdoll on the bed. Warning lights and a hydraulic hiss.
  - **Press:** HOLD for a slow press (the creaking rises); TAP for a slam.
  - **Payoff:** a cartoon pancake with its face, a "FLAT" pop.
  - **After:** it peels off the bed, flutters like paper, and pops back to shape with a "boing" after 2 s.
  - **Score:** "FLAT x1/x2/x3" for pressing again before it pops back.

### 3.8 WASHER (Machine Hall; F24 door and porthole)
- **10/10:** in through the porthole (the door swings), then a spin you choose (Delicate, Normal or TURBO), with suds and a light purple tint. The machine walks across its pad on TURBO. Out, dizzy and dripping, with bubbles.
- **Score:** the spins ("142 SPINS").

### 3.9 ROCKET (Launch Field)
- **10/10:**
  - **Load:** strap a ragdoll on the seat.
  - **Countdown:** 3-2-1 on its sign, steam, the gantry arm swings away.
  - **Lift-off:** a roaring rise with a smoke column. The camera follows for the player who launched it (2 s, skip on tap).
  - **At the top:** fireworks. The ragdoll comes down on a small parachute (no gore), drifting, and lands somewhere random in the lab.
  - **Score:** the max height.
  - **Golden:** a "MOON" pop with stars.

### 3.10 LAUNCH PADS + BRICK WALL (Crash Yard)
- **10/10:** step a ragdoll on a pad (3 pads = 3 strengths). It launches into the brick wall with a SPLAT on the wall; bricks crack and loosen (breakables), and it slides down the wall.
- **Score:** the impact speed.
- **The wall:** bricks fall out after hard hits and rebuild after 20 s.

### 3.11 GUARD DOG (Picnic Park; GUARD_DOG.md + F22)
- **Left to do:**
  - tooth marks;
  - the X-ray jaws;
  - the limb-specific reactions;
  - the gaits polished;
  - sounds (pant, growl, bark);
  - the GOOD BOY pop with a heart and a treat animation;
  - a pet button (tap the dog: it rolls over).

### 3.12 SHARK (glass aquarium, Animal Cove)
- **10/10:**
  - **Feed:** drop a ragdoll in at the top hatch.
  - **The fin:** it circles, then the shark charges from below, grabs it and spins underwater (a death roll, cartoon).
  - **The spit:** it spits it out up the water column, so the ragdoll pops out of the top dizzy and soaked, with bubbles.
  - Visible through the glass. The water churns with foam.
- **Score:** "CHOMP" and the time in the jaws.

### 3.13 SPIDER (fenced pen, Splash Zone)
- **10/10:**
  - **Feed:** throw a ragdoll in the web: it sticks, struggling.
  - **Wrap:** the spider runs down and wraps it in a silk cocoon, spinning it, then hangs it up.
  - **Free it:** you can shoot the cocoon to free it: it drops out covered in web strands.
- **Score:** the wrap speed.

### 3.14 FROG, 3.15 PLANT and 3.16 CHICKEN (gore off)
- **FROG:**
  - its tongue shoots out to a ragdoll within 15 studs and reels it in;
  - a gulp with a lump wiggling in its belly, a big burp;
  - it spits the ragdoll out covered in green slime, dizzy.
  - Score: the tongue length.
- **PLANT:**
  - its jaws open while a ragdoll is near, then SNAP;
  - it chews (a cartoon munch with stars), then spits it out spinning.
  - Variety: it sometimes keeps it for 3 s and you see only the legs kicking.
- **CHICKEN:**
  - it pecks a ragdoll's head (comic bonks), chases it in circles, sits on it;
  - it lays an egg; tapping the egg hatches a chick that follows you for a while.

### 3.17 CARS, TANK and MONSTER TRUCK (Crash Yard car bays + the car park)
- **10/10:**
  - **Getting in:** walk up and tap: you are in, and a cockpit view is offered.
  - **Driving:** weighty handling, a speedometer, engine sounds rising with the revs.
  - **Hits:** ragdolls hit by a car fly over the bonnet with real physics. A dent on the car, a "BONK" score by speed.
  - **The tank:** its turret aims with the camera, and its shell launches ragdolls in a blast.
  - **The monster truck:** it can drive over ragdolls (a bounce), and its big wheels crush crates.
  - **Crashes:** cars explode after a big crash (cartoon smoke and fire) and respawn in their bay after 15 s.
  - **Ragdolls in seats:** you can put a ragdoll in the passenger seat, and it flies out through the windscreen on a crash.

### 3.18 BOXING RING (Crash Yard)
- **10/10:** put 2 ragdolls in the ring: they fight. A bell; real punches with the active ragdoll; stagger and knockdown; a referee counting to 10 (a ragdoll in a striped shirt).
- **Bets:** you bet on one (BOLTS), the winner raises its arms, and confetti.
- **Join in:** you can climb in yourself.

### 3.19 STRETCH MACHINE (Machine Hall)
- **10/10:** strap the hands and feet, crank the wheel (hold); the ragdoll stretches like rubber (a cartoon, a long neck), with a creaking-rubber sound.
- **Release:** it bounces off with a SPROING and KEEPS its long limbs for 30 s, then they shrink back slowly over 10 s (owner, 26 Nov 2026: `FIXES_26NOV.md` F74; it never tears a limb off).
- **Score:** the stretch percentage.

### 3.20 TESLA COIL (Machine Hall)
- **10/10:** a button charges it (a rising hum, sparks crawling up the column), then ZAP: a lightning arc to the nearest ragdoll within 20 studs. It shows its X-ray skeleton for 0.3 s (the classic cartoon), its hair stands up, it is soot-black with a smoke puff, and it jumps.
- **Chain zap:** it arcs on to 2 more ragdolls nearby.

### 3.21 SHREDDER PIT (Danger Zone; cartoon: "Tumble Rollers")
- **10/10:** pull the lever. The rollers turn with a grinding sound. A ragdoll dropped in tumbles through the rollers and is spat out the far end FLAT and folded like paper, then it pops back to shape (no cutting, no gore).
- **Score:** the folds.

### 3.22 SWEEPER (Danger Zone)
- **10/10:**
  - **Speed:** press its button: the beam turns faster (3 speeds).
  - **Payoff:** ragdolls standing on the pad are swept off and flung over its edge.
  - **Challenge:** the player can stand on it and jump the beam. Survived turns are counted (a skill score, a NEW BEST).

### 3.23 LAVA STRIP (Danger Zone)
- **10/10:**
  - a ragdoll in the lava does a hot-foot dance and jumps out soot-black and smoking, then runs in circles fanning its bottom (cartoon);
  - the lava glows, bubbles and splashes;
  - a ragdoll that stays in too long is knocked out (CPR possible).
  - Score: the time it danced.

### 3.24 MOLE (Fun Fair)
- **10/10:** the mole drags a ragdoll under the ground (a dirt mound travels fast across the plot) and bursts up elsewhere, throwing it up.
- **Whack-a-mole:** you can hit the mole as it pops up (a whack-a-mole score).

### 3.25 SLINGSHOT + ARCHERY (Fun Fair)
- **SLINGSHOT:**
  - **Pull back** (phone: drag back and release, like Angry Birds style but our own art): the trees bend, then whip.
  - **The shot:** the ragdoll flies at the archery target and the targets round the field.
  - **Score:** the target rings.
- **ARCHERY:** the bow (a weapon) on the target: the score rings.

### 3.26 WHALE (Splash Zone big pool)
- **10/10:** the whale surfaces and blows a water spout that launches a ragdoll in the pool sky-high. It slaps its tail (a splash wave that pushes ragdolls).

### 3.27 BEAR (cave, Animal Cove)
- **Today:** decoration only.
- **10/10:**
  - **Wake it:** throw a ragdoll in the cave mouth, or poke the bear. It wakes, roars (a camera shake), and swats the ragdoll out like a ball (a big arc).
  - **Hug:** sometimes it hugs it instead (a bear hug squeeze, cartoon) and goes back to sleep holding it until you pull it free.

### 3.28 CROCODILES (pond, Animal Cove)
- **10/10:** a ragdoll at the pond edge or in the water: the crocs swim in (eyes above the water), one snaps and does a cartoon death-roll splash, then tosses it onto the bank, dizzy.

### 3.29 T-REX (walled pen, Animal Cove)
- **Today:** decoration only.
- **10/10:**
  - **The gate:** a big lever opens the wooden gate; the T-rex stomps (ground shake, footstep booms).
  - **Hunt:** it hunts the ragdolls inside the pen: it picks one up in its jaws, shakes it and tosses it into the air.
  - **ROAR:** a ROAR with a shock ring that knocks every ragdoll in the pen flat.
  - The gate closes again after 30 s.
  - **Safety:** players watching from the viewing platform are safe; inside, it may push the player out (no harm).

### 3.30 RED-BUTTON EVENTS (22 events)
- **10/10 for each event:**
  - a clear countdown banner (10 s, "TORNADO INCOMING");
  - the sky and light change;
  - the event's own sound, a big visual and real physics on the ragdolls;
  - an end banner with stats ("37 ragdolls flung!").
- **Cut the weak ones:** keep the 10 best (by how often players press them again), hide the rest behind switches.

### 3.31 WEAPON RANGE
- **10/10:** lanes with moving targets (ragdolls on rails), a timer course (30 s: hit as many as you can), a score board per weapon, NEW BEST.

### 3.32 BICYCLE, MOTORBIKE, WHEELCHAIRS
- **Riding:** see `docs/LIFE_IDLE.md` (cyclist) and `docs/WHEELCHAIRS.md`.
- **For all of them:** riders are knocked off with real physics; the player can ride; jumps off the plaza stairs and ramps score airtime.

### 3.33 THE SMALL FUN SPOTS (each 10/10, small)
- **Playground:** swings (push a ragdoll on a swing higher and higher: it flies off at the top, scored by distance), a slide, a roundabout (spin it: ragdolls fly off).
- **Seesaw:** drop a heavy thing (a crate, or yourself jumping) on one end and the ragdoll on the other launches.
- **Sandbox and sand circle:** ragdolls landing make sand splashes. Bury a ragdoll up to its head (hold on it in the sand): it wiggles out.
- **Picnic and grill:** ragdolls sit and "eat". The grill smokes; knock it and sausages fly.
- **Duck pond:** ducks swim. A ragdoll thrown in makes a splash and the ducks flap off.
- **Training yard:** ragdolls do push-ups and run the tyres. Knock them over mid-exercise.
- **Train:**
  - **Ride:** it runs the loop every 2 min with a horn; you can ride it, and ragdolls ride on the roof.
  - **Crossing:** at the crossings, barriers come down with bells.
  - **Hits:** it knocks a ragdoll on the track flying (it slows for players).

### 3.34 PLAYER ACTIONS (each 10/10)
- **GRAB and THROW:**
  - **Hold the limb you grabbed:** the body dangles from that limb. The throw strength is charged by holding, with an arc preview on phones.
- **SLAM:** a big impact with a dust ring and hit-stop; the "SMASH x3" combo.
- **LASSO** (`docs/DESTRUCTION.md`): rope, drag and swing. Not built yet.
- **CPR:**
  - a rhythm minigame (tap on the beat, 5 beats); a good rhythm raises the chance;
  - a heart line on a small monitor;
  - "IT'S ALIVE" when it works.
- **REVIVE ALL:** a sparkle wave from you outward.
- **X-RAY:** the glass shell, the bones, the slugs on their real path, breaks and shatters (`docs/BODY_V2.md` + F27-F29).
- **BURIAL:** exists. Add the funnel steps.

### 3.35 WEAPONS (by class; 72 weapons)
**Every weapon has:**
- its own sound with a tail;
- recoil;
- a muzzle flash by type;
- casings (F23);
- the right fire mode (F16);
- the right hit reaction by spot (F2);
- holes by size (BODY_V2 3);
- X-ray slugs (F4/F28).

**Per class:**

| Class | 10/10 |
|---|---|
| Pistols | crisp, a small push |
| SMGs | a fast rattle, many small pushes |
| Rifles | punchy, through one bone |
| Shotguns | a big knockdown, a pellet spread |
| Snipers | a scope, a loud crack, a spin; through 2 bones |
| Bows | the arrow sticks and pins a limb to a wall if close |
| Melee | the swing arc, a charged hit, dents, bones by force |
| Explosives | a blast ring, flying ragdolls, the shock ring, debris |
| Specials | each with its unique effect, made extra |

**Cut duplicates** that feel the same, and keep the best.

## State (per item, scores before and after)
- (none yet)
