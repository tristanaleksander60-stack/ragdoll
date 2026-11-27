# THE RAGDOLLS from 4/10 to 10/10 (owner, 27 Nov 2026: "Tag ragdollsene fra 4/10 til 10/10")
The ragdolls ARE the game. This doc is the one umbrella for making them 10/10. It points to the rows that already exist (do not build those twice) and adds what is still missing. Build it as ONE pass, right after F90 and F89, in the order below.

## Why they are 4/10 today (from the owner's screenshots and the code)
| Area | Today | 10/10 |
|---|---|---|
| **Body** | lumpy, yellow, arms up like a bodybuilder (F89); the old block body far away | one slim, smooth, grey crash-test mannequin everywhere (F89, S2), with soft plastic shading |
| **Face** | flat decals; no pupils; no blinking; the mouth never moves | eyes that look at you, blink and react; a mouth that talks; clear expressions |
| **Walk** | robotic arms, stiff, little weight | human walk and run clips, hips that carry weight, natural arm swing, feet on the ground (S1) |
| **Hit and fall** | reacts, but falls often look like a cut string; get-ups pop | stumble steps first, protective reflexes, heavy landings that slide, get-ups matched to how it lies (RAGDOLL_FEEL) |
| **Damage** | done to 12/10 (D12) | keep, and make it SEEN on the new body (holes and bandages on the mesh surface) |
| **Behaviour** | personas exist (P1), but many look alike and idle | each one readable at a glance: persona accessories, persona walks and idles, real reactions to others |
| **Sound** | few body sounds | footsteps by surface, thuds by speed, cartoon voices (oof, ow, hey) by persona |
| **Bugs** | vanishing (F90), heads spinning (F85), legs jitter (F73, F86), walking into things (F72) | ZERO of each, guarded by the always-on logs |

## The pass, in order
**R1. The body, everywhere** (F89 + S2's rest):
- the slim grey v2 body on EVERY ragdoll you can see: the nearest 12 with full bones, the rest with a cheap version of the SAME mesh (no finger bones). Never a block body in view;
- soft plastic shading: SurfaceAppearance roughness 0.45, a faint sheen, baked AO in the joints;
- the iconic crash-test marks: the black-and-yellow quarter circles on the temples, the chest and the knees (small decals), so they read as crash-test dummies at a glance;
- **size variety:** 0.92-1.08 scale, so a crowd never looks copy-pasted.

**R2. The face that lives** (new; `Client/FaceLife.luau`, `Config.FACE_LIFE = true`):
- **The eyes:**
  - two eye decals (white + pupil) on the face, the pupils offset by the look target (you, a bang, a machine, the talking partner);
  - they lead the head turn by 0.15 s; they never look behind (F85 rule).
- **Blinking:** every 2.5-6 s, a 0.12 s blink (a lid decal); a double blink now and then; no blinking when knocked out (closed) or dizzy (spirals).
- **The mouth:**
  - while a talk bubble is up, the mouth flaps between 3 shapes (closed, open, wide) at the syllables (a simple rhythm from the line length);
  - expressions from BODY_V2 4b and the v2 faces (FACES_V2) for the states: happy, hurt, scared, angry, dizzy, KO, relieved.
- **Cost:** decal swaps only, within 40 studs; beyond that, a fixed face.

**R3. The walk with weight** (S1's rest + F73's rest): build what is not done yet:
- the speed blend (walk, jog, run) with playback speed matched to the ground speed;
- the upper-body gesture layer;
- foot IK on slopes, stairs and kerbs;
- the turn pose and curved arrivals;
- smooth ownership hand-offs;
- **secondary motion:** the head bobs a little and settles after a stop; the arms follow through when the body stops; the hips sway;
- **persona walks:** HERO walks upright and faster; SCARED hunched and quick, looking round; CHILL slow and loose; CURIOUS stops to look at things.

**R4. Hits, falls, landings and get-ups** (RAGDOLL_FEEL "The upgrade" items 1-6): build what is not done yet:
- **a tone per limb:** a hit loosens only the struck chain for 0.3-0.8 s;
- **balance:** a small push gives 1-3 stumble steps with the arms out, then a recover; only a big push makes it fall;
- **protective reflexes:** falling forward, the arms go out; falling backward, the chin tucks and the arms go back; off a height, the legs cycle;
- **the landing:** it keeps its speed, slides or rolls, relaxes over 0.4 s, 1-2 twitches, then breathes;
- **get-ups chosen by how it lies:**
  - face down: push up, a knee under, kneel, stand;
  - face up: sit up, roll to one side, kneel, stand;

  each started from the real lying pose (no snap), the motors blending in over 0.3 s, a hit knocking it down again, then 1-2 s of dizzy wobble;
- the hurt behaviour: holding the hurt limb, the limp, a slower walk.

**R5. Readable personalities** (P1's rest):
- **one small accessory per persona,** made in Blender, in the clean style:
  - HERO: a red sweatband;
  - CURIOUS: a cap (and the phone when filming);
  - SCARED: round glasses;
  - CHILL: headphones round the neck;
- **persona idles:**
  - HERO: stretches, does a push-up;
  - CURIOUS: points at things, looks round;
  - SCARED: nervous foot tapping, looks over its shoulder;
  - CHILL: yawns, leans, sits;
- **reactions to OTHERS:** wincing when one nearby is hit hard; laughing at a funny fail (CHILL, CURIOUS); running to help (HERO); "Oh no!" at a knockout. They react to the world, not only to you.

**R6. The sound of a body** (new; pooled; `Config.BODY_SOUND = true`):
- **footsteps** by surface (tiles, grass, wood, metal, sand, water) and speed;
- **body thuds** by impact speed and surface (soft grass to a hard tile crack);
- a light scrape while sliding;
- **cartoon voices** (kid-friendly: "oof", "ow!", "hey!", "whoa!", "heh", a grunt on getting up), a different pitch per ragdoll (0.9-1.1) and a set per persona;
- at most 4 sounds per body per second; voices only within 40 studs.

**R7. Zero bugs** (the guards that exist, made strict):
- **no vanishing** (F90), **no spinning heads** (F85), **no leg jitter** (F73, F86), **no walking into things** (F72);
- **no T-pose frame:** a body is never shown before its first pose is applied;
- **no sinking:** GroundGuard;
- **no floating dead body:** F46;
- **the logs** (LEG_JITTER_LOG, NAV_BUMP_LOG, REMOVAL_LOG) stay on. In the ONE quick Play after this pass, the output must show 0 lines from them in a normal minute. That is reading the output of the same quick Play, not a test session.

**R8. Phones:**
- the caps stay (`RAGDOLL_DIRECTOR` Part C);
- the face, the sounds, the foot IK and the accessories only near;
- the cheap mesh far;
- at least 30 fps on a low phone and 60 on a mid phone with 7 ragdolls near.

## Check (the owner, phone first)
Stand among the ragdolls for a minute, then hit some:
1. they look like slim grey crash-test dummies with small persona accessories and slightly different sizes;
2. their eyes follow you and blink, and their mouths move when they talk;
3. they walk like people;
4. a light hit makes them stumble and recover; a big one makes them fall with their arms out, slide, and get up the right way, dizzy;
5. you hear their steps and their "oof";
6. none vanishes, spins its head, jitters or walks into things.
