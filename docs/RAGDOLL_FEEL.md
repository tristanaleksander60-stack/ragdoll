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

## SMOOTH AND REAL, NOT CLUMSY (owner, 26 Nov 2026 late: "Planen mangler at gøre ragdolls smooth så de er mere realistiske og ikke så klodsede")
**Why they look clumsy today** (read in the code):
- **Hand-made sine waves, not real motion:** the walk, run, limp and crawl are hand-coded sine waves in `Client/DummyLife.luau` `gaitPose`. A few joints swing back and forth: the hip ±22 degrees, the knee, the arms. There is:
  - no heel-to-toe roll and no push-off;
  - no hip sway, no shoulder counter-turn, no weight shift;
  - the same swing at every speed;
  - feet that slide when the stride does not match the speed.
- **A floating pelvis:** the server holds it at one fixed height by the `lift` (`ActiveRagdoll` `updateMoving`), so the body glides like a cardboard figure; the legs do not carry it.
- **Snaps:** standing, walking, talking, looking and turning switch poses with little or no blending, so they pop.
- **Stepping:** the animation runs at a lower rate in the middle distance, so you can see it step.
- **A blocky body:** 15 separate R15 blocks with seams at every joint (BODY_V2 4c).

**The fix: S1 SMOOTH MOTION** (behind `Config.SMOOTH_MOTION = true`; client animation in DummyLife, server movement in ActiveRagdoll):
1. **Real human animation clips instead of sine waves:**
   - use a Roblox-made animation package (those work in every game): pick the most natural, realistic one (Rthro or the Adidas packs; never Zombie, Toy or Cartoony for normal walking);
   - the clips: idle (breathing and weight shift), walk, jog, run, sprint, start, stop, turn-in-place left and right (for F73), a limp walk, a crawl, and talk gestures (point, shrug, nod, wave, laugh). Any clip missing from the packages: make it in Studio's Animation Editor and publish it to the group;
   - play them with an `Animator` on the rig, so the `AnimationConstraint`s (the active ragdoll's joints) follow the clips with physics, and hits still knock limbs off their pose.
   - If the Animator cannot drive the AnimationConstraints in this rig, read the clips' keyframes (`KeyframeSequenceProvider`) once on the client and write the joints' `Transform` from them yourself (still real motion, not sine waves).
2. **A speed blend with no foot sliding:**
   - idle, walk, jog and run play together with weights from the real ground speed (`AnimationTrack:AdjustWeight`), so the gait changes smoothly as it speeds up;
   - each clip's playback speed is `ground speed / the clip's own speed` (`AdjustSpeed`), so the feet stay planted.
3. **Layers on top of the walk:**
   - the upper-body gestures (talking, pointing, waving, holding a hurt arm) play on top of the walk with only upper-body keys;
   - LOOK AT YOU (the head and the chest) stays on top of everything.
4. **Never a snap:** every change of clip or state fades over 0.2-0.3 s (`Play(fadeTime)`), and every hand-made pose (hit reactions, braces) blends in and out over at least 0.15 s.
5. **The body carries its weight** (server, `updateMoving`):
   - **the hips:** the pelvis bobs with the steps (the lift's target follows the gait: down at each foot strike, up mid-stride, about 0.15-0.25 studs), and the lift is softer, so the legs look like they carry the body;
   - **acceleration:** a lean forward when speeding up, a lean back and a small settle when stopping (about 0.4 s);
   - **turns:** a small lean into a turn at speed; the even, capped turn from F73;
   - **idle:** a weight shift from foot to foot every few seconds, and breathing.
6. **Feet on the ground** (client, within 40 studs): one `IKControl` per foot puts it on the ground under it (slopes, stairs, kerbs, the plaza step), so feet never float or sink.
   - The same tool for the hands where they must touch something: CPR hands on the chest, a hand on a hurt limb, hands on the edge when climbing out of water (F78).
   - Phone: at most 5 bodies with foot IK.
7. **Smooth at every distance:**
   - full animation every frame within 60 studs on every device;
   - a lower rate only beyond 60 studs, where steps cannot be seen, with a hysteresis border (in at 60, out at 70) and a crossfade, never a jump.
8. **Smooth on the network:**
   - near bodies are simulated by the nearby player's own client (ownership, with F65's hysteresis: 15 studs, 3 s), so they move at the screen's frame rate;
   - never set CFrame directly on a moving body in view (only out of view);
   - a hand-off of ownership never teleports or hitches.
9. **The fall, the lying and the get-up are the RAGDOLL_FEEL upgrade below (items 1-6):**
   - a tone per limb;
   - balance recovery with stumble steps;
   - realistic masses and joint friction;
   - the landing sequence;
   - get-ups chosen by how it lies and matched to the lying pose;
   - hurt behaviour.

   Build them in the SAME pass as S1, with real get-up clips where the packages have them.
10. **Cost:**
    - one Animator per near body;
    - a few tracks each;
    - IK only near you;
    - all of it on the client except the pelvis bob and the leans (server numbers).

    Phones keep their caps (Part C of `RAGDOLL_DIRECTOR.md`).

**S2 SMOOTH BODY:** the skinned body with real fingers, `BODY_V2.md` 4c. Do it right after S1, so the smooth motion shows on a smooth body. The R15 parts stay as the physics skeleton; the skinned mesh follows them.

**Check (the owner):**
- ragdolls walk, jog, run, stop and turn like people: heel to toe, the hips swaying, the arms swinging naturally, the feet not sliding;
- no pose pops when they start talking, turn or stop;
- they fall, land and get up smoothly;
- no seams at the joints;
- the hands have fingers.

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

## PERFECT physics: the bar (owner, 26 Nov 2026: "Sørg for vi har PERFEKTIONERET physics")
Everything in this doc, plus these hard checks. (26 Nov late: the OWNER tests them at the end. Build to them from the code; no bench, clips or scores.)
- **The hit lands where it hits.** Every hit pushes the body with `ApplyImpulseAtPosition` at the exact hit point, in the shot direction, scaled by weapon force:
  - a shot in the shoulder turns the torso;
  - a shot in the knee buckles that leg;
  - a head shot snaps the head back.
- **No explosions and no flings:** no body ever shoots off at crazy speed from an overlap or a joint fight. Clamp speed at about 250 studs/s; a watchdog resets a NaN or a runaway.
- **No clipping:** limbs never pass through floors, walls, the tower, cars or each other. Use CCD-like checks for fast bodies (raycast the step; shrink the step when fast).
- **Stable at rest:** a lying body goes still within 2 s and sleeps. No jitter and no slow sliding on flat ground.
- **Stable in piles:** 5 bodies thrown on top of each other settle without vibrating.
- **Moving things:** bodies in cars, wheelchairs, on the trampoline, on the slide and on rotating machines move with them, and fly off naturally.
- **Water:** bodies float, bob and drift in the tanks and pools (buoyancy by part volume), never sink through the bottom or skate on top.
- **Ownership:** the player touching or hitting a body owns it, so it reacts at once. The hand-off back to the server is smooth (no hitch, no teleport).
- **Weight is felt:**
  - a light pistol rocks the body;
  - a shotgun knocks it down;
  - a sniper spins it;
  - a cannon sends it flying in a clean arc.
- **Same everywhere:** the same feel on 60 and 30 fps (physics independent of frame rate).
- **The bar:** score each check 0-10 on the bench clips. All must be 9.5+, compared side by side with the top ragdoll game.

## The bench: NOT RUN (26 Nov late: the owner tests; this list is what the owner will look at)
~~Record~~ The owner looks at 5 moments; build them to look right. (Old text:) Record 5 short clips in Studio and compare them with a video of the top ragdoll game, side by side:
1. a light shot (a flinch and a recover);
2. a hard shot (a stumble and a fall);
3. a fall from the tower;
4. a cannon launch and its landing;
5. lying, then getting up face down and face up.

Score each 0-10 on weight, reflexes, landing, get-up and jank, harshly. The bar is 9.

**Performance:**
- phones keep the existing caps (fewer ragdolls, lighter far bodies);
- the tone system must not add more than about 0.3 ms per body per frame.
