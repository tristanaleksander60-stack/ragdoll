# Wheelchairs: drive them, put ragdolls in them (owner, 26 Nov 2026)
> "Tilføj kørestole man kan køre rundt i og placere ragdolls i"

Behind `Config.WHEELCHAIRS = true`. Built like the bike and cars (`VehicleService` / `BikeService` patterns); the server decides seats; free for everyone.

## The chairs
- **3 wheelchairs in every lab,** parked in a neat row near the first-aid / test-floor area, plus 1 at the top of the tower by the slide.
- **The model:** a real-looking wheelchair:
  - a steel frame, black seat and back;
  - two big rear wheels with push rims, two small swivel front casters;
  - footrests.

  Get it from the Creator Store (malware pass; delete all scripts), else build it from a few parts. Realistic size for a Roblox character.
- **Physics:**
  - the two rear wheels on HingeConstraint motors, the casters free-swivelling;
  - low centre of mass so it does not tip on flat ground, but it CAN tip on hard turns at speed and on ramps (funny, not annoying);
  - network owner = whoever drives or pushes it.

## Drive it yourself
- Walk up and press E / tap the seat prompt: you sit and drive with the normal move controls (phone thumbstick, WASD, console stick).
- **Speed:** about 18, a boost down slopes, real roll-out momentum when you stop pushing.
- **Get out:** jump / the exit button.
- **Hard crash** (into a wall at speed, off the tower): you are thrown out as a ragdoll with impact effects (`docs/IMPACT_FX.md`), and the chair tumbles.

## Put a ragdoll in it
- **Grab a ragdoll** (PlayerGrab) and let go over or next to an empty chair: it snaps into a seated pose in the chair. The prompt "Put in chair" shows while holding one near a chair. It stays seated (a soft weld) until something knocks it out.
- **Push it:** stand behind an occupied chair, press E / tap "Push": you walk behind it holding the handles and steer it. Press again to LET GO: it keeps rolling with its momentum.
- **Fun the chair is for:**
  - let go at the top of a slope, the slide or a ramp;
  - push it into the cannon's landing field, the lava edge, the trampoline or the boxing ring;
  - crash it into the brick wall.

  On a hard hit, a sharp turn at speed, or a big drop, the ragdoll flies out with full ragdoll physics and impact effects. The chair tips or rolls away.
- **Ragdolls do it themselves too:**
  - a badly hurt ragdoll (injury stage 3, `docs/BODY_V2.md`) is sometimes pushed around in a chair by a helper ragdoll;
  - after a bandage, the helper parks it in the shade.

  Calm, caring tone: no jokes about disability in any text or line.

## Rules
- **Respawn:** a chair that is flipped, stuck, or more than 150 studs from its spot for 30 s fades and comes back at its spot.
- **Caps:** 3 chairs per lab (4 with the tower one). Chairs on other maps only if the owner asks.
- **Phones:**
  - simple collision (box wheels);
  - far chairs are anchored when nobody is near (sleep).
- **Server checks:** only one rider or pusher at a time, distance checks on seat and push requests (Net validators and rate limits).
- **Funnel:** "Chair driven", "Ragdoll seated", "Chair crash".

## Check
- One quick Play:
  - drive a chair;
  - put a ragdoll in it;
  - push it, let go down a slope, and crash it into the brick wall (the ragdoll flies out);
  - drive off the tower top (you fly out).
- **Test selv** (Danish) in the run's one list: on phone and PC.
