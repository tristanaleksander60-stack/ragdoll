# PHYSICS: the V9-P bench and its numbers

The bench (`ServerScriptService/Server/Tests/Lib/PhysicsBench.luau`) runs a fixed set of repeatable scenes on a floor of its own (8 studs thick, 200 x 200, high above every map), with server-simulated dummies, which run the same ActiveRagdoll code as everywhere else. Bodies are kept out cold for the whole scene, so the numbers cover the fall and the rest, never the getting up.

**How to run it:**
- In a self-test, run `T183_PhysicsBench`. It prints `[PhysicsBench]` lines.
- The test holds the targets once `Config.PHYSICS_V9` is on.

**What is measured, per scene:**
- **peak:** the highest part speed, studs/s.
- **spikes:** frames over the scene's cap (an "explosion").
- **sunk:** frames with a part's middle under the floor's top.
- **settle:** seconds from the action until every part stays under 1.5 studs/s for 0.5 s.
- **jitter:** mean linear speed (studs/s) and angular speed (rad/s) over 2 s at rest.
- **physics:** the server's mean physics step during the scene, in ms (Stats).

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
