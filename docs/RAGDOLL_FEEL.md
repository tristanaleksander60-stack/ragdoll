# Ragdoll feel 10/10: falls, landings, lying, getting up (owner, 26 Nov 2026)
> "Gør alle effekterne på ragdolls når de falder, rejser sig op osv meget mere realistiske, gå dybt i hvordan de største ragdoll spil gør"

**What we have** (`Shared/Ragdoll/ActiveRagdoll`, 2.7k lines; numbers in `docs/PHYSICS.md`):
- an active ragdoll (AnimationConstraints + BallSockets) with Standing → Stumble → Fall;
- a brace (arms reach out);
- get-up styles Kneel / SitUp;
- flinch, leg buckle, stagger.

The parts exist. The gap to the best games is in **timing, weight, secondary motion and transitions**. This doc is the upgrade, behind `Config.FEEL_V2 = true`.

## How the biggest ragdoll games do it

The best Roblox ragdoll games are Hyper Realistic Ragdoll, Bloody Ragdoll Physics, Ragdoll Engine and Fling Things and People. The best console games (GTA's Euphoria / NaturalMotion, Red Dead) solve the same problems. They all do these things:
1. **Partial ragdoll, not on/off.**
   - A hit drives only the struck chain (the arm, or the upper body) loose for a moment while the rest keeps its pose.
   - The body is never "animation OR ragdoll"; it is a blend of muscle strength (tone) per limb, from 0 (limp) to 1 (animated).
2. **Balance before the fall** (Euphoria's signature):
   - a hit body tries to stay up: 1-3 stumble steps in the push direction, arms windmilling, the hips lowering;
   - it falls only when the push is too big;
   - small hits rock, then recover.
3. **Protective reflexes.**
   - Falling forward: arms out, the head turned aside.
   - Falling backward: the chin tucked, the arms back.
   - Off a height: the legs cycle, the arms flail.
   - A hurt limb is held (the other hand goes to it).
4. **Weight.**
   - Realistic mass per part: the torso heavy, the hands light.
   - Speed is kept through a landing: the body rolls and slides after it lands instead of stopping dead.
   - Joint friction: a limb settles instead of swinging forever.
   - No bouncing (elasticity about 0), ground friction about 0.6-0.8.
5. **The landing sequence:**
   - impact → a small rebound of the limbs → slide or roll → the limbs relax over about 0.4 s;
   - one or two small twitches;
   - stillness: breathing (the chest rises), an occasional groan or move.
6. **Getting up like a person,** chosen by how it lies:
   - **face down:** push up on the arms → a knee under → kneel → stand;
   - **face up:** sit up (hands behind) → roll to one side → kneel → stand;
   - **on its side:** roll to face down first.

   Each start pose is matched to the body's real lying pose (no snap). The motors blend from limp to strong over about 0.3 s, the get-up animation drives the motors (physics stays on), so a hit during a get-up knocks it down again. After standing: a wobble (dizzy sway, a hand to the head, 1-2 s), then normal.
7. **No jank, ever:**
   - joint limits like a human: elbows and knees hinge one way only (HingeConstraint with limits), twist limits on the neck, shoulders and hips;
   - limbs never pass through the torso (collision between body parts on, except at joints);
   - no jitter at rest (sleep after settling);
   - no sinking into the floor;
   - no stiff T-pose for a frame;
   - no teleport on get-up.
8. **Smoothness.**
   - The player who touches a body gets network ownership of it, so it reacts on their screen at once. Ours does this in a shared lab.
   - Physics runs at 240 Hz; the server checks only results.
9. **Sound and effects follow the physics:**
   - every contact makes a sound by speed and surface: thud, scrape while sliding, clatter of limbs;
   - dust on landing and sliding (`docs/IMPACT_FX.md`);
   - grunts on hits, a groan on landing, heavy breathing while getting up. No voices for the dead.
10. **Faces:** pain squint on a hit, eyes closed when knocked out, dizzy eyes on the get-up.

## The upgrade (build in this order)
1. **A tone per limb** (0-1) replacing global states where they are on or off:
   - hits lower the struck limb's tone for 0.3-0.8 s, then it returns;
   - a knockout sends every tone to about 0.05 over 0.25 s (not 0 at once: the body sags, it does not collapse like a cut string).
2. **Balance recovery:**
   - push below a threshold: 1-3 stumble steps (feet placed by the push), arms out, recover;
   - above it: the fall with the protective reflex for the fall direction (item 3 of the list above).
3. **Body numbers** (set, then tune by eye on the 5 test shots below):
   - masses: torso about 40 % of the body, head 8 %, each leg 16 %, each arm 5 %;
   - joint friction by a weak AngularVelocity (0) per joint, MaxTorque scaled by tone;
   - friction 0.7, elasticity 0;
   - human joint limits (knees and elbows as hinges, about 0-140°).
4. **The landing sequence:** keep the speed (no extra damping on contact), slide or roll, relax over 0.4 s, 1-2 twitches, then breathing plus an occasional small move while lying.
5. **Get-ups:**
   - three real get-up animations (face down, face up, side), from Creator Store or made in Studio's animation editor;
   - started from a pose matched to the lying body;
   - motors blending in;
   - a hit can interrupt them;
   - then 1-2 s of dizzy wobble.
6. **Hurt behaviour:**
   - a hand holds a hurt arm or leg;
   - a limp on a hurt leg (exists: tune);
   - the hurt body walks slower.
7. **Sound and faces** (item 9 and 10 of the list above), pooled sounds, max 4 per body per second.
8. **Jank guard** (a watchdog in the rig): it catches and fixes these:
   - a limb inside the torso;
   - jitter at rest;
   - sinking (GroundGuard exists);
   - a NaN or a flung body.

   It logs a count per session (Metrics).

## The bench (one Play, no suites)
Record 5 short clips in Studio and compare them with a video of the top ragdoll game, side by side:
1. a light shot (a flinch and a recover);
2. a hard shot (a stumble and a fall);
3. a fall from the tower;
4. a cannon launch and its landing;
5. lying, then getting up face down and face up.

Score each 0-10 on weight, reflexes, landing, get-up and jank, harshly. The bar is 9.

**Performance:**
- phones keep the existing caps (fewer ragdolls, lighter far bodies);
- the tone system must not add more than about 0.3 ms per body per frame.
