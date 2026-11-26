# Gore off, X-ray 10/10, purple blood look, new hit marks, burial + revenge (owner, 26 Nov 2026)
> "Slå gore fra, gør vores x-ray 10/10 så det ser sådan her ud når man har xray til. Blod skal se sådan her ud. Skudhuller skal ændres. Gør så en ragdoll kommer hen og begraver deres døde kammerater hvis cpr ikke virkede og gør så de angriber efter de har begravet ham istedet og sagt noget lidt cringe "Its your time" agtig"

The owner sent 4 pictures (described here; the images were not saved):
1. **The X-RAY target:**
   - a ragdoll lying on concrete, its whole body a see-through glassy light-blue shell (soft cyan, about 60 % see-through) with a thin bright-blue outline round every limb;
   - inside, a full clean white cartoon skeleton in the right place in every limb: a round skull, a ribcage with curved ribs, a cream/yellow spine of small vertebrae, a pelvis, upper and lower arm bones, hand bones with fingers, leg bones and foot bones;
   - smooth rounded bone ends, slightly glossy, no cracks, nothing broken or sticking out;
   - the purple puddle under it shows through.
2. **The BLOOD target:**
   - one glossy cartoon puddle in a bright violet-purple (about RGB 110,40,220), smooth blobby edges, a shiny highlight;
   - a few star-shaped splats at its edge;
   - 1-2 separate small puddles nearby and small round droplets;
   - it looks like paint or slime, not real blood.
3. **The bullet holes today:** small dark round holes with a white rim in the body. **These must change.**
4. **The grave look:**
   - a rounded mound of brown earth (dirt texture) on the grass;
   - a grey stone headstone standing at its end.

## 0. URGENT: gore off, published BEFORE the maturity questionnaire (deadline Fri 27 Nov 2026 17:34 UTC)
The owner chose option 2 in `docs/MATURITY.md`.
- **Do this first in the next /klar.** Publish it as soon as it is done (quick gate), so the live game matches the answers. Then tell the owner it is live, so they can submit the questionnaire.
- **Switch OFF (behind switches, do not delete):**
  - `SEVERING = false`: no limbs off, no cutting in half, no bursting heads, no "head off at 2 rounds";
  - the mech-arms rip/tear (pull a limb off, strands of flesh, widening wound): the arms may still grab and throw;
  - stumps, flesh, meat, spine sticking up, exposed bones on a living body;
  - the X-ray bone that is "shot away bit by bit" or broken: X-ray bones are always whole (section 1);
  - creatures that tear, bleed, "spit bones with meat", red water (shark, washer), the frog's "slime and bones". Creatures now swallow and spit out the dummy dizzy with cartoon stars, or a puff;
  - the press pancake's "blood dripping" and "wet splat": it becomes a flat cartoon pancake that pops back up;
  - rot or decay on death;
  - any red blood anywhere (search every red `Color3` in the blood, wound and FX code).
- **Keep:** purple cartoon blood (section 2), knock-outs, CPR, mourning, the burial (section 4).
- **Words** (`MILD_TEXT`): "Dead", "killed", "bled out", "WASTED" become "KO", "knocked out" and "OUT COLD". The body card shows "Energy" instead of "Blood".
- **Store text** (`STORE_TEXT.md` + the owner copies it to the Creator Hub): remove "watch the bone break", "pull ragdolls apart" and "UFO Beam". Write "X-ray: see their skeleton glow", "grab, swing and SLAM ragdolls".
- **Then update `docs/MATURITY.md` "Final answers"** (written below) and send the owner the Danish answer list.

## 1. X-RAY 10/10 (`XRAY_V2 = true`)
- **When:**
  - an X-RAY toggle: a button on the HUD (phone: a small button by the hotbar; PC: V or X; console: a button);
  - on: every ragdoll within about 80 studs shows its X-ray view (alive, knocked out, flying);
  - off: normal;
  - the short automatic X-ray flash on a big hit stays, using the same look.
- **The look** (exactly picture 1):
  - **Shell:** each body part becomes Glass/SmoothPlastic, light cyan (about 170,220,255), Transparency about 0.6, with a thin bright-blue edge (a Highlight with OutlineColor 80,170,255, FillTransparency 1, DepthMode Occluded).
  - **Skeleton:** one white cartoon skeleton per rig, built from a few MeshParts per limb (skull, ribcage, spine, pelvis, upper/lower arm, hand, upper/lower leg, foot), welded inside its limb. It follows the body exactly, never pokes out of the shell.
    - Bones: white (245,245,240), the spine cream (240,220,170), slightly glossy.
  - Prefer one good skeleton mesh set (Creator Store, malware pass) over many parts. Max about 16 parts per skeleton.
  - Faces and skins are hidden while X-ray is on. The purple puddles stay visible under the body.
- **Performance:**
  - skeletons are made only while X-ray is on and pooled;
  - phones: max 6 X-rayed bodies at once (the nearest).

## 2. Blood look (`BLOOD_V2 = true`, still `BLOOD = "purple"`)
Exactly picture 2:
- **Puddle:**
  - one glossy cartoon puddle under a hurt or knocked-out body;
  - it grows smoothly to its size over about 1 s;
  - a flat blobby mesh or decal, violet-purple (110,40,220), shiny (SmoothPlastic + a highlight or Reflectance);
  - 2-4 star-shaped splats on its edge;
  - fades after about 20 s.
- **Hits:** 1-2 small round purple droplets fly out and land as tiny dots.
- **Second puddle:** a hard landing leaves a smaller second puddle nearby.
- **Limits:**
  - never on the body as wounds or streaks; only on the ground;
  - a cap per lab (pooled);
  - phones: half.

## 2b. Purple splatter on EVERY hit (owner, 26 Nov 2026: "Der skal komme purple splatter hver gang et skud rammer en ragdoll")
- **Every bullet, arrow, pellet and melee hit** that touches a ragdoll gives a purple splatter burst at the exact hit point:
  - 4-8 glossy purple droplets fly out from the hit in the shot's direction, with a small cartoon star splash;
  - they land on the ground or nearby walls as small splats that fade after about 10 s.
- **Never skipped,** even on phones; only the droplet count drops (phones 3-4, far hits 2).
- **The colour and look** of the section 2 blood (110,40,220, glossy). Pooled parts and emitters; a hard cap per lab.
- **Shotguns:** one splatter per pellet that hits, capped at 4 per shot.

## 3. New hit marks (replace the bullet holes; `HIT_MARKS_V2 = true`)
- **No holes into the body.** A hit leaves a small purple paint splat sticker (a star-edged blob, the same purple as the blood) on the body where it hit, about 0.6 studs.
- **Fade:** it fades after 8 s.
- **Cap:** max 6 per body (the oldest goes first).
- **On a hit:** a tiny white "plink" flash plus a puff of white cartoon dust.
- **Melee and impacts:** a short white "dent ring" flash on the body instead of a hole.
- **The body card** lists hits as "Hits: 5", not wounds.

## 4. Burial + revenge (`BURIAL = true`)
- **When:** a ragdoll's CPR fails (the existing Mourning/CPR flow) and it stays knocked out.
- **Then:**
  1. One nearby ragdoll comes over with a small shovel (a Creator Store prop, malware pass, or a simple mesh).
  2. It digs about 3 s (a dig animation, dirt puffs).
  3. The body sinks into the ground and a grave appears where it lay: a rounded brown dirt mound plus a grey stone headstone (picture 4).
     - The headstone shows only "R.I.P." (no names, no free text).
     - The grave fades after 60 s; max 3 graves per lab.
  4. A short sad beat (head down, 1.5 s).
- **Then revenge:**
  1. The burying ragdoll turns to the player who knocked out its friend, and says ONE cringe line in its talk bubble. Pick at random:
     - "It's your time."
     - "This one's for Gary."
     - "You messed with the wrong dummy."
     - "Prepare to get… ragdolled."
     - "I'm doing this for him."
     - "Say goodnight, buddy."
     - "Your time has come. Probably."
     - "He was two days from retirement."
  2. It runs at the player and attacks, using the existing attack (ANGRY / ATTACK). Cartoon only:
     - shoves and punches with stars;
     - the player gets knocked down, never anything gory;
     - it stops after the player is down once, or after 10 s, or when knocked out itself.
- **Limits:**
  - max 1 burial at a time per lab;
  - not for newcomers in their first 2 minutes (they are learning);
  - phones: the same.
- **Funnel:** "Burial seen" and "Revenge survived".

## 4b. Injury stages, real bandages, changing faces (owner, 26 Nov 2026: "Gør så de har flere stadier end bare 1 når de er skadet og mere realistiske bandager og ændrende ansigtsudtryk")
The owner's picture shows today's look:
- the whole torso flat-tinted lavender;
- one plain white band on a forearm;
- the same neutral face.

That is one stage only. Make it `INJURY_V2 = true`.

**Stages per body part** (head, torso, each arm, each leg), counted from the hits on that part:

| Stage | Hits on the part | Look | Behaviour |
|---|---|---|---|
| 0 Fine | 0 | grey | normal |
| 1 Bruised | 1-2 | 1-2 small soft-edged lavender bruise patches (decals with soft edges) where it was hit, not the whole part | flinch |
| 2 Hurt | 3-4 | bigger, darker violet patches that merge; a small purple drip on the ground now and then | holds it (a hand on the hurt arm or torso), limps on a hurt leg, walks slower |
| 3 Badly hurt | 5+ | deep violet over most of the part | staggers, holds the part, sits down or kneels sometimes to rest, cannot run |
| 4 Knocked out | | as now (CPR, burial) | |

- The colour blends smoothly between stages (no flat tint).
- It heals slowly back one stage every 60 s, or at once with a bandage.

**Real bandages** (put on by `FirstAid`: a helper ragdoll kneels, wraps for about 2 s with a short wrap animation; or a ragdoll does it to itself at stage 2-3):
- **Gauze wrap on arms, legs and torso:**
  - off-white (235,232,222) with a woven texture;
  - overlapping wrap ridges (2-3 slightly offset rings, not one flat band);
  - a loose end with tape;
  - at stage 3, a small violet seep spot in the middle.
- **Adhesive plasters** (cross-shaped, skin-beige) on the head or face for stage 1-2.
- **A head wrap** round the forehead for a hurt head.
- **An arm sling** for a badly hurt arm (the arm stays bent in it).
- **A knee wrap** for a hurt leg, and the ragdoll still limps a little.
- **Removal:** bandages stay until the ragdoll is fully healed or knocked out, then fade.
- **Cap:** max 4 bandages per ragdoll.

**Changing faces** (decal swap in the ragdolls' own face style, with a quick blink between faces):

| Face | When |
|---|---|
| neutral | fine |
| worried | a gun is pointed at it ("Is that a gun?", hands up: exists) |
| pain squint | at the moment of a hit |
| hurt | stage 2: brows up, mouth tight |
| crying, with small cartoon tears | stage 3 |
| dizzy (spiral eyes) | while getting up |
| X eyes or closed eyes | knocked out |
| angry (brows down) | revenge and attacks |
| sad | mourning and burial |
| relieved smile | just bandaged or healed |
| scared (wide eyes, small mouth) | fleeing |

- The face follows the most important state at that moment (KO > pain flash > angry > scared > crying > hurt > worried > neutral).
- About 11 face decals, one style. Make them in the same style as the current face.

**Performance:** bruise decals are pooled; max 6 per ragdoll; phones the same, but far ragdolls (40+ studs) show only the stage colour, no decals or bandage detail.

## 5. Check
- One quick Play: shoot a dummy (purple splat marks, no holes), knock one out (puddle like picture 2), let CPR fail (burial, line, attack), and toggle X-RAY (looks like picture 1).
- **Search the code** for leftover gore words and red colours.
- **Test selv list** (Danish, in the run's one list).

## MATURITY: final answers (after section 0 is live)
- **Violence:** yes, repeated, against grey crash-test dummies and the player, cartoon/slapstick, unrealistic: Mild.
- **Blood:** yes, but unrealistic: cartoon purple paint-like puddles, no red blood.
- **Gore and dismemberment:** none.
- **Weapons:** toy-style guns, bombs and melee used on dummies.
- **Fear:** mild (creatures swallow dummies, a T-rex, graves with "R.I.P.").
- **Crude humour:** mild (cringe lines).
- **Romance, alcohol, drugs, gambling, swearing:** none.
- **Free-form user text:** none in the world (Roblox chat only).
- **Spending:** Robux passes and products (cosmetics, weapons, boosts); no random paid boxes. If eggs or crates with random rewards are sold for Robux, say yes and show the odds.

**Expected label: Mild (9+).** The owner submits only after the gore-off build is live.
