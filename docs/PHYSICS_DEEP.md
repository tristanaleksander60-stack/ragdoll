# PHYSICS DEEP FIX: the ragdolls jitter back and forth and stand wrong (owner, 27 Nov 2026 late)
> "De bugger stadig frem og tilbage, står urealistisk, det hele er 3/10 physics, kig DYBT i det og løs det nu, det her taber mig så mange penge."
> (Screenshot: a v6 ragdoll standing with its legs wide and bent, its arms held out from the body like a gorilla, a purple trickle stick on its back; the trickle is fixed in code, `DRIP_TRICKLE`.)

**STATE (27 Nov late, v1328-v1333): mostly DONE, see NOW.md "PHYSICS_DEEP probe numbers": no self-collision, calm states, standing hold, smoothed lean, no waypoint backtrack, ghost shins and feet while walking (the bounce off kerbs and steps), blocked walkers stop pushing, path budget queue, v6 arms in, run form, a coward backs off a gun once. LEFT: the last standing drift (0.06-0.28 studs in 10 s), walkers still bumping a few walls.**

**This is now the TOP priority, above every other row, A-E included where they overlap (A-E's walk and run, D, is part of this).**
**The owner's order overrides the NO TESTING rule for THIS item only:** measure in Play with the probe below as much as you need, until the numbers pass. No other testing.

## The goal (the numbers the fix must reach)
- **Standing still:** no visible movement at all. The pelvis moves less than 0.02 studs and turns less than 0.05 rad/s over 10 s; no state flips.
- **Walking:** smooth, one direction, no stopping and starting, no back-and-forth, no foot sliding; a turn is one smooth arc.
- **The stance:** like a real standing person (and the v6 renders): feet under the hips (about 1.0 apart), knees almost straight (3-5 degrees), the chest up, the head level, the arms hanging relaxed close to the body (8-10 degrees out, just enough for the hands to clear the thick v6 thighs), elbows bent about 10 degrees. Never legs wide and bent, never arms held out.

## Step 1: measure (a probe, `Config.PHYSICS_PROBE`, off by default; turn it off again when done)
On 3 standing and 3 walking dummies near the player, for 10 s, log per body:
1. the pelvis position jitter (max-min) and its angular speed;
2. the state changes per second (Standing, Walking, Fleeing, Flinch, Stumble…) and why (which rule started each one);
3. the sign flips of `drive.VectorVelocity` along the heading (back and forth) and of the heading itself;
4. the self-contacts: for each body part, `GetTouchingParts()` that belong to the SAME body (the thicker v6 parts: thigh against thigh (only 0.08 studs apart), hand and forearm against thigh, upper arm against the deeper chest);
5. the feet: touching the ground or not while the lift holds the pelvis (the lift and the floor fighting), the lift's force;
6. the outside movers acting on it: RagdollDirector calls (ALWAYS3, DRAWN_TO_YOU, the watcher spots), the personal-space push (`avoidDummies`, PERSONAL_SPACE 2.6, also from the player), the gun flee and wary (`GUN_FLEE`, `GUN_WARY`: a coward runs from your held gun, then gets drawn back to you), Unstick, GroundGuard lifts, network owner changes.

Write the numbers in NOW.md before and after.

## Step 2: fix every cause the probe shows. The likely causes (cloud's code read, 27 Nov):
- **a. Self-collision of the thicker v6 parts** (`DummyFactory.fitV6` made the thighs 0.92 wide on centres 1.0 apart, the torso 1.5 deep; `prepareParts` sets every part `CanCollide = true`; there is NO `NoCollisionConstraint` between a body's own parts anywhere): the limbs rub and push on each other all the time. **Fix:** a NoCollisionConstraint between every pair of the same body's parts that can touch (neighbours across each joint, left and right thighs, shins and feet, each hand and forearm against both thighs and the lower torso, each upper arm against the upper torso), made once in `ActiveRagdoll.prepare`. The body still collides with the world, other bodies and props.
- **b. State flapping and steering back and forth:** Standing ↔ Walking at the home radius (`HOME_LEAVE`/`HOME_ARRIVE`), the director re-targeting every 0.25 s, the personal-space push on a body that is standing still, and gun flee → drawn back → flee again. **Fix:** a minimum of 1.5 s in a state; an arrive dead zone (once arrived, it stays until the goal moves more than 4 studs); a STANDING body is never push-steered: it turns to face, or takes ONE deliberate step away; the director never calls a body that fled from a gun in the last `GUN_WARY` s; while the player holds a gun close, cowards back off once and stay off (no ping-pong).
- **c. The lift, the balance and the feet:** `lift` (AlignPosition, Responsiveness 20, MaxVelocity 30) holds the pelvis at `standOffset + WALK_HOVER` while the feet also press the floor (friction 0.25, weight 3) and the S1 bob moves the target every frame. **Fix:** upright, the lift alone carries the weight: the hover so the feet sit 0.02 above the floor, the legs' friction 0 while upright (the body's 0.75 back when it falls); check the balance (AlignOrientation, Responsiveness 40) for overshoot: no oscillation at rest.
- **d. The lean from acceleration** (`R.lean` from the per-frame speed change in the walk drive): noisy speed makes the body rock forward and back. **Fix:** compute the acceleration from a speed smoothed over about 0.3 s, a dead zone (no lean below 1 stud/s or small changes), a capped lean rate.
- **e. The standing pose for v6:** `Poses` (Standing, the idles, Flinch/Stumble recovery) were tuned for the old R15 blocks; with the v6 proportions they read as wide, bent and arms-out. **Fix:** re-tune them to the stance above (`Shared/Ragdoll/Poses.luau`), and the per-screen leg animation (`Client/DummyLife`, `ClipGait`) to the v6 leg length: feet planted under the hips, no sliding.
- **f. Anything else the probe finds.** Fix the real cause, never hide it with smoothing.

## Step 3: the walk and the run (`RAGDOLL_10.md` THE OWNER'S TEST D)
Done with the fixed base: the toy waddle walk (arms swinging down by the sides) and the bouncy run (arms bent, pumping), with the stride matched to the v6 legs.

## Check (the owner, phone first, in the final test list)
1. Stand next to 3 ragdolls for 20 s: they stand still, relaxed and natural; nothing shakes or shuffles.
2. Hold a gun near them: a scared one backs off ONCE and stays back; no back and forth.
3. Watch 3 walk: smooth, natural, no sliding feet, smooth turns.
4. Hit one: it falls, gets up and stands still again.
