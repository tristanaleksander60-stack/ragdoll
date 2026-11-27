# RAGDOLL V7: animated until hit (owner, 27 Nov late)
> "TÆNK NU LÆNGE I FORHOLD TIL RAGDOLLS OVER NUVÆRENDE SYSTEM OG HVORDAN DET BEDSTE SYSTEM SER UD OG HVORFOR"
> The owner's test the same evening:
> - they still jitter back and forth just standing, and on the bike;
> - they lean far back when walking;
> - the legs still bug;
> - old ragdolls still show;
> - plasters and bandages can't be seen;
> - holes are missing in places and some show as a purple blob;
> - the X-ray looks 2/10 and hurts the eyes.

## 1. Why the current system keeps failing (from the code, not guesses)
1. **Every living ragdoll is a full physics body balancing on its feet with forces, all the time.**
   - Each body has an AlignOrientation (balance), an AlignPosition (lift), a LinearVelocity (drive) and 15 AnimationConstraints (`ActiveRagdoll`).
   - Standing still is a constant fight between gravity, balance torque, joint motors and ground contact. That fight is the "back and forth when they just stand".
   - Walking pushes the hips with the drive while the chest lags behind. That is the "leaning far back".
   - Feet and knees are motor targets against contact. That is "the legs bug".
2. **Every fix so far was a patch on top**: GroundGuard, Unstick, the settle assist, LegJitter, STAND_HOLD, LEAN_SMOOTH, NAV_NO_BACKTRACK, hardChecks, the limb guard and the speed governor.
   - Each one fixes one symptom and adds one more thing pushing the same body. Eight or more systems now move the same parts.
   - That is why the same bugs come back after "DONE".
3. **What you see is a second body.**
   - The v6 mesh is driven in Lua every frame from the hidden block parts (`SmoothBody`).
   - Everything on a body must be re-mapped from the blocks to the mesh: the head, holes, the face, bandages, accessories and the X-ray. Each re-map is a bug source:
     - the head wobbled;
     - holes float or sit under the skin;
     - bandages sit on the hidden blocks, so they are invisible;
     - the X-ray needed a separate glass.
   - A body shows as the OLD block ragdoll whenever the mesh is not built for it:
     - beyond 80 studs, or after the nearest 12 on a phone;
     - for a moment after it spawns;
     - always for the crowd people: `CrowdService` calls `DummyFactory.removeMarks`, which sets `Mannequin = false`, and SmoothBody skips them.
4. **Two simulators fight over one thing.**
   - The bike is steered by the server (AlignPosition targets replicated over the network). Its rider is simulated by the lab player's client and held over the saddle with forces. The two disagree every frame, so it jitters on the bike.
   - The phone simulates its whole lab, and everyone else sees replicated physics, so it stutters on other screens.

**Conclusion:** more tuning of an always-balancing physics body cannot reach 10/10. Patching it has failed 5 times today. The architecture is the bug.

## 2. What the best ragdoll games do, and why
- **The best Roblox ragdoll games** (Ragdoll Engine, Bloody Ragdoll Physics, Hyper Realistic Ragdoll):
  - their people are ANIMATED (Motor6D joints plus animation clips) while nothing happens to them;
  - they switch to PHYSICS only when hit, killed, flung or grabbed;
  - they get up again with an animation.
- **That is why they never jitter standing:** an animation cannot jitter, and physics is only used where it is fun.
- **Big games** (GTA's Euphoria, "powered ragdolls") add a short physics reaction blended over the animation on a light hit: the hit limb and the spine react, the body stays up. On a heavy hit they go fully limp.

## 3. The best system for us: V7, "animated until hit" (`Config.RAGDOLL_V7`)
### 3.1 One body, natively skinned (no SmoothBody, no old blocks, nothing to re-map)
- The approved v6 mesh is split in Blender into the 15 R15 parts, each a MeshPart holding its own bone. The skin weights blend across the joints, the way Roblox's skinned avatars work.
- The engine deforms the skin itself from the part positions: no Lua per frame, no lag between the physics and the look.
- **The physics part IS the visible part**, so whatever is welded to a part sits exactly on the skin and moves with it:
  - the bullet holes (a small curved hole mesh, inset 0.02 studs);
  - the face and the plasters/bandages (a ring mesh at the limb's own v6 radius);
  - hats and props in the hand.
- The old block look can never show again. There is no second body.
- **SPIKE FIRST (1 hour, owner looks):** import the split v6, check the shoulder, hip and knee bending in 6 poses and in a limp fall, and capture it next to the current v6. Go on only if it looks the same or better.

### 3.2 Two modes
- **ANIMATED** (alive and nothing is happening to it):
  - a Humanoid with only Running, Climbing and Jumping on, Motor6D joints, and an Animator playing real clips (from the PC's animation pipeline, Blender or the Animation Editor);
  - the clips: 4 idle variants with small weight shifts, walk, run, a scared run, talk gestures, look at something, sit on a bench, read the newspaper, use the phone, watch a machine and cheer, CPR, boxing, pedalling the bike, pushing the wheelchair;
  - Humanoid walking handles slopes and stairs and is smooth on every screen. Only the root and the clip replicate.
  - The walk is upright, with the clip's own slight forward lean.
- **PHYSICAL** (hit, flung, fallen, dead, held, in a machine):
  - at the moment of the hit, the Motor6Ds go off and limited BallSocket/Hinge constraints take over at the SAME pose. The animation's velocities are copied in, and the impulse goes at the hit point;
  - a light hit (under a threshold by weapon) is a **stagger**: the joints are powered back toward the last animation pose with low torque for 0.3-0.8 s, and the body stays up and goes back to ANIMATED;
  - a heavy hit is fully limp.
- **Back up:** when calm, the get-up clip is picked by how it lies (face up, face down, on its side). The clip starts from the lying pose (pose match over 0.25 s), then the body is ANIMATED again.
  - A hurt body may fail the get-up: a clip with a fall back.
  - Both legs broken means it crawls (a clip).
- **Sleep:** a physical body lying still for 1.5 s is anchored and costs nothing (`PERF_MOBILE.md` §6 item 2). Any touch, hit or grab wakes it.

### 3.3 One brain, clear ownership
- The server holds one state machine per body: Idle, Activity, Walk, Talk, React, Physical, Down, GetUp, Sleep, Ride, Machine.
- Clients only animate and draw. A physical body is owned by the player who hit or grabbed it (instant feel); otherwise by the server.
- **Removed for living bodies:**
  - balance, lift and drive (no more balancing on forces);
  - GroundGuard, Unstick, LegJitter, STAND_HOLD, LEAN_SMOOTH and NAV_NO_BACKTRACK.

  They stay only where a physical body needs them.

### 3.4 Life instead of standing around
- Authored ACTIVITY SPOTS by the map:
  - benches (sit, read);
  - the newspaper stand;
  - a phone by a lamp post;
  - watching a machine and cheering;
  - the boxing ring crowd;
  - kicking a ball;
  - the parking lot (look at the cars).
- **Spacing:**
  - at most 3 per spot;
  - at least 4 studs apart;
  - at most 4 bodies in any 20 x 20 stud cell. The owner saw too many in one place.
- Only 1-2 come to talk to the player; the rest do their activity.

### 3.5 Rides
- On the bike or a wheelchair, the rider is WELDED to the saddle in the pedal or sit clip: rider and bike are one assembly with one owner, so there is nothing to fight.
- The route is driven by that one owner.
- A hit makes the rider PHYSICAL. They fall off, and the bike falls too.

## 4. Why this is the best, in one line each
- **Stability:** an animation cannot jitter, lean wrong or bug its legs. Physics is used only where it is fun.
- **Looks:** authored clips look like a real person. One skinned body means holes, bandages, the face and the X-ray sit ON the skin, always.
- **Cost:** animated bodies cost a fraction of balanced physics bodies, which matters most on phones. Sleeping bodies cost nothing.
- **Fewer systems:** about 8 patch systems are removed for living bodies, so fewer bugs can come back.
- **Better ragdoll fun:** the physical mode can be tuned on its own (the push at the hit point, the stagger, the falls) without breaking standing and walking.

## 5. The steps (each one ends with a SHORT test list for the owner, then STOP and wait)
1. **V7-1 the spike** (3.1): the natively skinned v6 in Studio, 6 poses plus a limp fall, captured next to the current v6. Owner: "same or better?"
2. **V7-2 animated plus hit:**
   - idle, walk and run clips;
   - the switch to PHYSICAL on a hit at the same pose;
   - the stagger;
   - limp, sleep, the get-up by orientation, the failed get-up and the crawl.

   Owner test: stand next to 5 for 1 minute (no movement at all except breathing and idle); walk with them; shoot an arm, a leg and the head; knock one down and watch it get up.
3. **V7-3 everything that holds a body:** grab and carry (the body is physical while held), every machine, CPR, the boxing, the bike and wheelchair, holes, bandages, the face, the X-ray on the skinned parts, the activities and the spacing. Owner test list.
4. **V7-4 clean-up:** the old balance, lift and drive, SmoothBody and the patch systems are switched off for V7 bodies (the switches are kept). The old block skins are removed from the templates.
