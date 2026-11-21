# PHYSICS: the V9-P bench and its numbers

The bench (`ServerScriptService/Server/Tests/Lib/PhysicsBench.luau`) runs a fixed set of repeatable scenes on a floor of its own (8 studs thick, 200 x 200, high above every map), with server-simulated dummies, which run the same ActiveRagdoll code as everywhere else. Bodies are kept out cold for the whole scene, so the numbers cover the fall and the rest, never the getting up.

**How to run it:**
- In a self-test, run `T183_PhysicsBench`. It prints `[PhysicsBench]` lines.
- The test holds the targets once `Config.PHYSICS_V9` is on.

**What is measured, per scene:**
- **peak:** the highest part speed, studs/s.
- **spikes:** frames where the trunk goes past the scene's physical cap, or a limb past 120 studs/s against its pelvis (an "explosion"; since fix round 1).
- **sunk:** frames with a part's middle under the floor's top.
- **settle:** seconds from the action until every part stays under 1.5 studs/s for 0.5 s.
- **jitter:** mean linear speed (studs/s) and angular speed (rad/s) over 2 s at rest.
- **physics:** the whole server's mean physics step (Stats), in ms, over 3 s from the action (since fix round 1; before, only until the scene settled).
- **down:** frames a living body was down (the "rounds" scene).

## Baseline (21 Nov 2026, PC Studio, before V9-P tuning)

| scene | peak | spikes | sunk | settle | jitter (lin / ang) | physics ms |
|---|---|---|---|---|---|---|
| drop40 (40-stud drop, limp) | 124 | 0 | 0 | 4.06 s | 0.04 / 0.05 | 2.4 |
| stairs (a push down 10 steps) | 47 | 0 | 0 | 0.33 s | 0.01 / 0.00 | 1.3 |
| launch (a cannon-sized launch) | 105 | 0 | 0 | 0.97 s | 0.01 / 0.00 | 1.5 |
| blast6 (a grenade at 6 studs) | 120 | 0 | 0 | 1.05 s | (it got up: now kept down) | 1.5 |
| pile20 (20 bodies dropped on a heap) | 168 | 0 | 0 | 4.60 s | 0.07 / 0.04 | 13.6-30 |
| rest10 (one body lying still) | 0 | 0 | 0 | - | 0.00 / 0.00 | 1.0 |

**Read-out:**
- **Already good:**
  - no explosions, no limbs through the floor;
  - no jitter at rest;
  - the 40-stud drop reaches the right speed (theory 125 studs/s).
- **To improve:**
  1. **Settling.** A long fall and a heap take 4-4.6 s to come to rest (target 1.5 s): the bodies bounce and roll too long.
  2. **Server cost of a heap.** 20 bodies cost 13-30 ms of server physics per step, too much for a busy server. Bodies at rest should sleep, and far ones should drop detail (P5).
  3. **Mass.** The pelvis weighs 0.29 (4.5 % of the body) and each arm 15 %. The centre of mass sits high in the chest, so falls read top-heavy and floppy.
     - Real bodies: pelvis about 14 %, thighs 10 % each, upper arm 2.7 %, forearm 1.6 %.
     - Retune by density, keeping the total (6.4) so the ActiveRagdoll forces stay right (P1).
  4. **Joints.** Roblox's Avatar Joint Upgrade already sets sensible limits and friction: elbows 5-120° twist, knees -120..-5°, neck ±40°/45°, shoulders 110° cones. P1 checks them against real ranges and adds damping for weight.

## Rivals
Side-by-side captures of Hyper Realistic Ragdoll, Ragdoll Engine, Bloody Ragdoll Physics and Fling Things and People come with P6. They need the owner's captures or public videos.

## After P1 + the settle assist (21 Nov 2026, `Config.PHYSICS_V9` on)

**Settle times** are now counted from the hardest moment (the impact or the launch).

| scene | peak | spikes | sunk | settle | jitter (lin / ang) | physics ms |
|---|---|---|---|---|---|---|
| drop40 | 114 | 0 | 0 | 1.02 s | 0.00 / 0.00 | 2.8 |
| stairs | 49 | 0 | 0 | 0.12 s | 0.00 / 0.00 | 1.5 |
| launch | 108 | 0 | 0 | 0.11 s | 0.01 / 0.00 | 1.6 |
| blast6 | 110 | 0 | 0 | 0.37 s | 0.02 / 0.01 | 1.5 |
| pile20 | 175 | 0 | 0 | 0.47 s | 0.04 / 0.03 | 21 |
| rest10 | 0 | 0 | 0 | - | 0.00 / 0.00 | 1.7 |

**What changed:**
- **Mass** (`PHYSICS.MASS`): the parts weigh what a real body's do, over the same total (6.4). The pelvis is now 0.96 and the head 0.55. The arms are light: upper arm 0.18, forearm 0.11, hand 0.04. Falls now read weighty and centred.
- **Joint friction** (`PHYSICS.JOINT_FRICTION`): the neck x2 and the spine x1.5 on top of Roblox's own. The head no longer whips after a landing.
- **Settle assist** (`PHYSICS.SETTLE_SPEED` 10, `SETTLE_DAMP` 3):
  - A limp body on the ground that moves slower than 10 studs/s loses its energy like a soft body would.
  - A 40-stud drop now settles in 1.0 s instead of 3.9 s.
  - It never touches flying, held or fast bodies.
- **The bench floor** is Grass, like the lab's real collision floor (the Baseplate).

**Still open:**
- The heap's server cost, 21 ms (P5: sleep and lower detail when far).
- The rivals side by side (P6).
- P3: muscles, balance and reflexes.
- P4: impacts, including V9-0ac's flinch, not fall.

**Checked:** T183, T23, T38, T45, T82, T109, T166, T50, T22 and T21 pass. T33 fails alone with the physics on and off alike: it depends on the order of the tests, and it passes in the full suite.

## Fix round 1 (21 Nov 2026, after the blind review: V9-P 5.0, V9-0ac 6.0)

**The tables above are not comparable:**
- The P1 commit changed the bench in the same step as the tuning: the floor went from SmoothPlastic to Grass, and settling was timed from the peak.
- Every row was a single run (±50 % noise on a settle time).
- "physics ms" was averaged only until the scene settled, so a scene that settles sooner showed its hard landing only.
- It is the whole server's physics step (Stats), not one body's.

### What the bench measures now
- **Spikes:** a frame counts when the trunk (pelvis) goes faster than the scene's physical cap, or when a limb goes faster than `REL_MAX` 120 studs/s against its own pelvis. The scene's physical cap is what that fall or push can give it, plus 15 %, for example √(2g·42) for drop40. The old caps could not fail: ActiveRagdoll already guards limbs at 110 against the pelvis.
- **"rounds" scene:** six Deagle rounds through HitService into the hands, a forearm, a leg and the chest of a living, standing body. It must never go down, and nothing may flick.
- **Physics time:** the server's physics step over a fixed 3 s from the action.
- **Medians:** `ServerStorage` attribute `BenchRuns` = N runs the bench N times and reports medians. Spikes, sunk and down frames are the worst run's.
- **T183's targets:** settle ≤ 1.5 s (was 3), jitter ≤ 0.3, 0 sunk, 0 spikes, 0 down.

### Before and after, the same bench (median of 3 fresh runs, PC Studio)

| scene | settle off → on | jitter off → on | server physics ms off → on |
|---|---|---|---|
| drop40 | 0.48 → 0.53 s | 0.03 → 0.00 | 1.7 → 1.9 |
| stairs | 0.09 → 0.13 s | 0.00 → 0.00 | 1.6 → 1.7 |
| launch | 0.22 → 0.13 s | 0.00 → 0.00 | 1.5 → 1.6 |
| blast6 | 1.13 → 1.33 s (both bimodal, 0.4 or 1.3 s) | 0.01 → 0.00 | 1.5 → 1.8 |
| pile20 | 2.59 (0.9-4.7) → 0.75 (0.45-0.99) s | 0.07 → 0.05 | 17.9 (15.6-21.7) → 28.3 (26-29) |
| rest10 | asleep | 0.00 → 0.00 | 1.15 → 1.00 |
| rounds (new) | never down; limb against pelvis 86 → 96 studs/s | 0.00 → 0.00 | 1.4 → 1.3 |

**Read-out:**
- **Heaps:** V9 settles a heap three times faster and far more evenly (0.45-1 s against 0.9-4.7 s). It still costs about 40-60 % more server physics while the heap lands.
  - **Tried:**
    - applying the assist at 10 Hz;
    - letting go once the body is calm;
    - leaving bodies under 0.15 studs/s alone, so they can sleep. This fixed rest10, which had gone from 1.0 to 2.2 ms;
    - leaving heaps of 8+ moving bodies to the solver.

    None of these brought the heap under 26 ms, while with the assist off it is 18-20 ms.
  - **Kept:**
    - the rest threshold (a body at rest costs what it did before);
    - the 8-body bound.
  - **The cost is P5's:** level of detail and sleep for far bodies, and the device-tier caps. On a live server, lab bodies are simulated by their player's device (one owner for life), under `FX_CAPS` ragdolls (low 8, mid 14, high 22). A heap of 20 is a pc/high-tier case.
- **Single bodies:** about the same as before, but quieter at rest. A launch settles faster.
- **Later runs:** in one Play session, the 4th and 5th bench runs show sunk frames and jitter in every config, off as well as on. This happens about 3 minutes in, when the server's own timed events load it. Medians come from runs 1-3.

### What changed in the code (fix round 1)
- **Rounds never down a living body** (`SHOT_FLINCH`): every round is a Flinch, never a Stumble. Stumble's weak legs and low balance tipped bodies under a fast Popper or an AK burst.
- **Getting up or crawling:** a round no longer floors the body again.
- **Leg rounds:** a leg round makes it limp on for 4 s (`LEG_LIMP_TIME`).
- **Light parts:** a round's own jerk on the part it hits is capped by that part's real mass (`GUN_LOCAL_MAX` 28 studs/s). A hand weighs 1/50 of the trunk.
- **The killing round:** its push carries into the fall (`DEATH_PUSH` 9 studs/s, within 0.8 s), so the body falls away from the shot.
- **Golden Deagle (2.4)** joins the one-round body kills (`SHOT_ONE_KILL_POWER` 2.4).
- **Gun texts** no longer promise a throw: Revolver, Flare Gun, Double Barrel.
- **Settle assist:**
  - It only acts on a flat floor (normal ≥ 0.9) that is not bouncy, and brakes against that floor's own speed: truck beds, platforms.
  - Never in a time bubble, under gravity 150 (Zero-G, the owner's low gravity), or for 0.4 s after a push: fans, conveyors, the gravity hole.
  - It leaves parts under 0.15 studs/s alone, so the body can sleep.
  - It is off while the machine simulates more than 8 limp bodies in motion.
- **MIN_DOWN 3 s:** a knocked-down dummy lies at least 3 s, as long as before the assist.
- **The brace (P3):**
  - It starts on time to impact: 0.35 s at the body's own clock. A slow bubble braces longer; a fast bubble does not brace.
  - The pose is a straight-armed catch (`Poses.catch`).
  - The arms keep their tone 0.25 s into the landing (`CATCH_TIME`), and bracing arms never break.
- **GOD MODE kinds:** each kind's weight is a factor on the real mass spread. `Mass` and `StandOffset` are written again, so HEAVY (60) stands and MINI (1.4) is not over-driven.

### Still open, honestly
- **P2:**
  - `PhysicsSteppingMethod` was not compared;
  - collision is boxes, not capsules;
  - nothing checks that a body wakes on a hit, or that it spawns in a valid pose.
- **P1:**
  - joint limits were not checked against human ranges;
  - there is no friction or bounce per surface (`BODY_FRICTION_WEIGHT` 3 overrides the floor);
  - buoyancy changed with the mass spread: a heavier pelvis, light arms. Water and the aquarium have not been checked.
- **P3:**
  - no balance or stepping, and no muscles weakened by damage;
  - no roll or slump on landing;
  - no get-up blend for front, back and side;
  - nothing for the players' own ragdoll. The settle assist and the brace do run on it.
- **P4:**
  - no impact sounds by surface and speed, and no dust scaled by speed;
  - the death drop on the shooter's screen waits for the server's `Vital`, one round trip.
- **P5:**
  - the heap cost above;
  - no detail drop or anchoring for far bodies;
  - nothing checks that ownership never flips mid-flight.
- **P6:** the rivals side by side, and the two blind video reviews.
- **Bench scenes not built:** car, grab/throw, water.
- **Measuring:** the bench bodies are server-owned, while live lab bodies are client-owned. There are no captures, no network KB/s and no low-tier frame time.
