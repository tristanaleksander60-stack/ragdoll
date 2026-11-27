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

## THE LOOK 10/10: a CHUNKY TOY CRASH-TEST DUMMY (owner, 27 Nov late: "Gør dem tykkere, så der er mere at skyde på og giv dem lidt mere liv" and "De ligner nu 5/10, de skal 10/10, undersøg hvad de største ragdoll spil gør, udnyt Blender fuldt ud")
**What the best ragdoll games do with their bodies:**
- **Gang Beasts, Human: Fall Flat, TABS, Fall Guys:**
  - CHUNKY, soft, rounded bodies with thick limbs and a big head: a big target, a readable silhouette, and funny when they flop;
  - simple, very expressive faces;
  - squash, wobble and jiggle on every impact;
  - matte "rubber or plastic toy" materials with soft light, never thin or realistic.
- **Real crash-test dummies** (the Hybrid III look): segmented, with visible JOINT RINGS at the neck, shoulders, elbows, hips and knees, a chest plate, bolts, and the black-and-yellow target markings. That reads "dummy" at a glance, and the rings hide where the skin bends.
- **The top Roblox ragdoll games** use thick R15 bodies (avatars or chunky dummies). Our v2 is THINNER than all of them: less to hit, and it looks fragile and sad (the owner's screenshot: skinny, hunched, hands clasped).

**So the v3 body is a chunky toy crash-test dummy, made in Blender with every tool** (`tools/blender/mannequin_v3.py`, headless):
1. **Proportions:** sturdy and toy-like. In studs, on a 5.2-stud body:
   - **head:** a big rounded head, about 1.25 wide;
   - **neck:** a short neck with a joint ring;
   - **torso:** a broad chest about 2.0 wide x 1.0 deep with a rounded chest PLATE, a firm waist about 1.6 wide, hips about 1.8;
   - **arms:** about 0.66 thick at the upper arm, 0.56 at the forearm, a joint ring at the shoulder and the elbow. The shoulders sit far enough out that the arms hang free of the body, never clipping it;
   - **legs:** about 0.85 thick at the thigh, 0.66 at the calf, a joint ring at the hip and the knee, solid ankles;
   - **hands:** big friendly hands, chunky fingers and a thumb;
   - **feet:** rounded boot-like feet with a sole.

   The hit area is about the old block body's or more.
2. **The surface detail, baked** (not polygons):
   - a NORMAL MAP for the panel seams on the chest plate, the thighs and the forearms, small bolts, the joint ring grooves and a fine plastic grain;
   - an AMBIENT OCCLUSION bake into the colour map (the creases, under the chest plate, between the fingers);
   - a ROUGHNESS map (about 0.5, the rings a little shinier).

   All 1024 px, exported with the FBX and used as a `SurfaceAppearance` (ColorMap, NormalMap, RoughnessMap).
3. **The markings:**
   - the black-and-yellow quarter circles on both temples, the chest plate and the outsides of the knees, painted into the colour map;
   - a small number stencil on the back ("RD-07"), random per ragdoll by a tint swap.
4. **Clean topology:**
   - modelled from primitives, then subdivided, then remeshed and smoothed;
   - edge loops at every joint so it bends without collapsing;
   - automatic weights corrected by hand rules in the script (the rings follow their joint bone 100%);
   - about 9-12k triangles, plus a LOD of about 2.5k for the far bodies.
5. **The rest pose matches R15** (F89 rule): arms down, relaxed.
6. **The face:** our expressive faces (FACES_V2 + R2's living eyes, blinks and mouth) on the big round face area. The eyes are bigger, so the expressions read from far.
7. **Wobble and squash:** on a hard hit, a short squash-and-stretch on the struck part (bone scale is not possible, so a tiny bone offset jiggle), and a soft belly and chest jiggle after impacts (a damped spring on a chest bone). Cheap, only near.
8. **Colour:** the light grey toy plastic (about 163,162,165) with the yellow-black markings. (The persona accessories of R5 sit on top.)
9. **Review renders** (Blender, allowed: about looks): front, side, three-quarter and a "knocked down" pose, next to a Gang Beasts / Human: Fall Flat style silhouette. Fix them until it reads chunky, friendly and fun.
10. **Then BodyShape (R9) is exported from THIS mesh:** the physics parts get thicker to match, so there really is more to shoot at, and the holes, the splash, the X-ray and the bandages all fit.

**THE OWNER APPROVES THE BODY FIRST** (owner, 27 Nov: "Gør så telefon, skud, bandage, avis, x-ray osv alt virker med de nye ragdolls EFTER jeg har godkendt at de er gode nok"):
1. Build the v3 body in Blender, render the review images (front, side, three-quarter, knocked down, and next to the player) into `art/models/mannequin/review_v3/`, and push.
2. **STOP the body work there.** Write in NOW.md "BODY V3: waiting for the owner's OK", PARK R9 and the fit list below in OVERVIEW, and go on with other rows. Do not adapt anything to v3 before the OK (no double work if the body changes).
3. The owner looks at the renders (the cloud session shows them) and answers. The cloud writes "BODY V3 APPROVED (date)" in NOW.md, or the changes to make (then a new v3 and new renders, and wait again).
4. **Only after "APPROVED": the FIT PASS.** The owner imports the FBX once; then EVERYTHING on a ragdoll is made to work with the v3 body, in ONE pass (R9 plus this list):
   - **damage:** bullet holes and exit holes, the splash, drips, pools, bruises, soot, wet, paint, the X-ray shell, skeleton, slugs, cracks and the tracer, the dog's bite marks;
   - **care:** bandages, slings, splints, plasters, the tweezers pick-out, CPR hands, the doctor's hands;
   - **held props:** the NEWSPAPER (reading idles and the paper route), the PHONE (filming), the shovel (burial), the persona accessories (sweatband, cap, glasses, headphones), the egg hats, the lasso and grab points;
   - **poses and rides:** sitting (benches, wheelchairs, the bike, the seesaw), the bowling ball curl, the cannon load, the stretcher (F74), the rocket strap, the machines' grips;
   - **face and marks:** the faces and the living eyes on the new head, the crash-test markings, the tints;
   - **the physics:** the parts and masses from BodyShape (thicker), the hit areas, the far LOD;
   - **phones:** the same with the device caps.
5. In that pass, every item is checked by reading where it attaches (a bone or part, an offset from BodyShape). Nothing may float off or sink into the new body.

**v4 FIXES: the owner rejected v3** (27 Nov: "helt ude og skide"). The cloud's review of the v3 renders found:
1. **The markings are pixelated and smeared:**
   - the colour map is too low resolution, or the UVs are stretched over the round chest plate;
   - **fix:** clean UVs (a planar projection per marking area), a 2048 colour map, the black-and-yellow quarter circles drawn as crisp VECTOR shapes into the texture (Pillow or Blender's own image painting from code, anti-aliased), with a thin black outline.
2. **The rings look like loose donuts stuck on, sticking far out at the shoulders:**
   - **fix:** the joint rings become part of the body: a shallow GROOVE plus a slim, flush band (sticking out at most 0.04 studs), modelled into the surface at the neck, shoulders, elbows, wrists, hips, knees and ankles;
   - no separate torus objects.
3. **The hands are tiny, thin and realistic on a chunky toy:**
   - **fix:** BIG, round, soft toy hands (the palm about 0.55 wide), 4 thick sausage fingers and a thick thumb, rounded tips; mitten-like, but with fingers;
   - the size of the hand reads clearly next to the forearm.
4. **The feet are flat plates:**
   - **fix:** rounded boot-shaped feet (a round toe, a heel, a thick soft sole blended into the foot), about 1.4 long, joined to the ankle with a groove ring.
5. **It reads as a robot or a diving suit, not a cute toy:**
   - **fix:** softness everywhere. Every part rounded (no flat faces, no hard edges anywhere), a slightly bigger round belly and chest, softly tapering limbs, smooth blends at the shoulders and hips (no sharp joins), the chest plate a soft rounded oval set INTO the chest;
   - the target is the soft, friendly volume of Fall Guys and Gang Beasts, with crash-test details on top.
6. **Also:**
   - the arms hang a little away from the body (they never touch it);
   - the whole body is ONE smooth merged mesh;
   - the shading is smooth (auto smooth plus weighted normals);
   - a subtle AO bake.

**The bar before the owner sees it** (Claude Code judges its own renders against this, harshly, and repeats until every line is true):
- the markings are crisp at full size, no pixels or smears;
- no part sticks out like a separate object; the rings are flush bands;
- the hands are big and round, and clearly toy hands;
- the feet are round boots;
- nothing is flat, sharp or robotic; it looks soft, chunky, friendly and fun;
- it looks like it belongs in a top Roblox game next to a player avatar;
- the renders: front, side, three-quarter, back, knocked down (a starfish pose), next to a player, and a CLOSE-UP of a hand and a marking.

**v5 FIXES: the owner rejected v4** (27 Nov late: "nej"; the cloud rated v4 6/10). v4 got the one mesh, the crisp chest plate and marks, and the round boots right; KEEP those. Fix these (build `build_mannequin_v5.py` from v4, renders to `art/models/mannequin/review_v5/`):
1. **The hands still read as mittens with a HOOK** (from the side the thumb sticks out down and forward like a claw, the 4 fingers are one fused lump):
   - 4 separate thick fingers with clear gaps between them (visible in the silhouette from the front AND the side), rounded tips, a relaxed half-open pose (the fingers gently curled, not straight);
   - the thumb shorter and thick, set on the inner side of the palm and pointing forward along the index finger, never sideways or downward;
   - **the hook test:** in the side and front silhouettes, no part of the hand may look like a hook or a claw. Add a side close-up of the hand to the renders.
2. **Too thin, flat as cardboard from the side** (v4 is 1.13 studs deep):
   - the torso about 1.6 deep at the chest and belly (the depth about 75% of the chest width), with a round belly and a round back;
   - every limb round in cross-section (as deep as it is wide): thighs about 0.95, shins 0.8, upper arms 0.75, forearms 0.7;
   - **the side test:** the side render must read as chunky and round, like Fall Guys or Gang Beasts.
3. **The bands have stair-step, notched edges** (the arm bands show square steps at the seams):
   - the bands are whole edge loops in the mesh with their own dark colour (a vertex colour or a second material on the loop's faces), so the edge is a straight clean line all the way round; no band drawn in the colour map;
   - one band per joint only (neck, shoulders, elbows, wrists, hips, knees, ankles), the same width everywhere; no extra stripes on the upper arm or the shin (v4 looks like striped pyjamas).
4. **No head in the renders:** render the whole ragdoll WITH the game's head on it (the big round head with the BODY_V2 4b face, at its real size), and add a close-up of the head. The owner judges the whole doll.
5. **"Next to a player" shows a grey slab:** put a real Roblox-size blocky R15 avatar next to it (head, torso 2x2x1, arms and legs 1x2x1, in normal avatar colours), so the scale reads.
6. **The bar** is the v4 bar plus: no seams or steps on any band at close-up size; the hand passes the hook test; the side render reads chunky. Judge every render against it harshly and fix before you show the owner.

**v6 FIXES: the owner's changes to v5** (27 Nov late: "Gør halsen lidt mindre, sørg for intet overlapper, fjern de sorte striber"; the cloud rated v5 8/10). KEEP everything else from v5 (the round chunky SDF body, the hands with separate fingers, the chest plate, the yellow-black marks, the head and its face). Build `build_mannequin_v6.py` from v5, renders to `art/models/mannequin/review_v6/` (the same set as v5):
1. **A smaller neck:** shorter and thinner (about 0.28 radius instead of 0.36, and about half as long), so the head sits closer to the shoulders with only a short soft neck showing; the head must still turn freely without clipping into the chest.
2. **Nothing overlaps:**
   - no part of the mesh pokes through another: the head and the neck, the arms and the torso, the hands and the thighs (in the standing pose the hands hang just clear of the legs), the thumb and the palm;
   - no marking overlaps anything: each yellow-black mark sits whole on a clean spot (the upper arms and the thighs, away from the joints), never cut or covered;
   - no stray shapes: remove the small black slivers and specks on the neck, the hip and the thigh, and the small spike at the base of the thumb (v5 has them).
3. **No black stripes:** remove ALL the dark joint bands (neck, shoulders, elbows, wrists, hips, knees, ankles), so the body is one clean light grey. The chest plate, the yellow-black marks and the dark boot soles stay.
4. **The bar:** the v5 bar, minus the bands, plus: a close-up of the neck, a shoulder and a hand next to the thigh, with zero overlaps, slivers or spikes. Judge harshly and fix before showing the owner.

**BODY V6 APPROVED by the owner (27 Nov late: "Ja, sørg nu for alt virker med den nye krop, dem der holder telefoner, cykler, avis, x-ray, knogler, vægt, physics og alting. - cpr osv").** v6 is THE body; every other body version (v1, v2, v3) is retired (no work on them, ever).

**THE v6 FIT PASS (now the top priority, one pass, `Config.SMOOTH_BODY_V6 = true` + `Config.BODY_FIT = true`):**
0. **DONE v1319:** SmoothBodyV6 in ReplicatedStorage (moved in Edit mode, SurfaceAppearance ColorMap 127740164602654, uploaded through the MCP), `Config.SMOOTH_BODY_V6` wins in Client/SmoothBody (FK), `SMOOTH_BODY_V3` off; the Play shows 3 of 3 near bodies on v6. **Hookup:**
   - in `Main.server.luau`, the same hook as SmoothBodyV3: `workspace.mannequin_v6` → `ReplicatedStorage.SmoothBodyV6`, with its colour map (`mannequin_v6_color.png`: upload it through the MCP if it can, else ONE owner step);
   - `Client/SmoothBody` uses V6 and wins over every older version; the old body switches are turned off;
   - the owner's step (File > Import 3D > `art/models/mannequin/mannequin_v6.fbx`, then save) goes in the final message if it has not happened; until it has, build everything from `mannequin_v6_stats.json` and the rig's bone names, so it works the moment the model lands.
1. **DONE v1319:** `Shared/BodyShape` (joints, limb radius profiles, torso rings, hand grip, boot, marks, chest plate, head, mass shares; `radius`, `wrapRadius`, `torsoAt`, `active`). **BodyShape from v6** (R9.1): written by a script from the v6 mesh (every bone's length and radius profile, the torso's depth and width at chest, belly and hips). Every item below reads it.
2. **DONE v1320 (part):** DummyFactory `fitV6` resizes the physics cross-sections to sit inside v6 (torso 1.5 deep, hips 1.75x1.4, arms 0.72/0.66, hands 0.4x0.7, thighs 0.92, shins 0.78, feet 0.72x1.25), lengths and joints kept; masses unchanged (Config.PHYSICS.MASS already gives torso 47 %, head 8.5 %, each leg 17 %, each arm 5 %: the RAGDOLL_FEEL shares). LEFT: the head balance and joint centres at v6's joints (the FK body already draws them there). **Weight and physics** (R9.2): the 15 physics parts resized to sit just inside v6's round limbs and deep torso; the masses from v6's volumes in the RAGDOLL_FEEL shares (torso about 40 %, head 8 %, each leg 16 %, each arm 5 %), so the heavier, chunkier body falls, rolls and gets up with weight; the joint centres at v6's real joints; the feet flat on the ground (no float, no sink); the big head balanced so it does not tip over.
3. **DONE v1321:** the skeleton (ribcage, spine, limb bones, slugs, cracks) is built from the physics parts, which item 2 sized to v6, so it sits inside the deep chest and the round limbs; in X-ray the v6 mesh itself is the glass shell (Transparency 0.78, the block skins stay hidden; Client/SmoothBody GLASS_V6). **Bones and X-ray** (R9.5, D12): the skeleton scaled to v6 (the ribcage inside the deep chest, the skull in the round head, the hand bones in the new fingers); the shell is the v6 mesh in glass; breaks, cracks, shatters, slugs and the tracer all INSIDE the body.
4. **DONE v1321+ (holes):** on a v6 body (attribute BodyV6) a bullet hole sits on v6's own round surface from Shared/BodyShape (limb radius by height, the torso's width and depth), not the hidden skin block; the phone cap stays. LEFT: splash, drips, pools and bruises read the hole point, so they follow it. **Holes, splash, drips, pools, bruises** (R9.3, 9.4, 9.7): on the v6 surface by the client raycast; exits on the far side; the hole caps per device kept (AUDIT 37).
5. **DONE v1323:** the v6 patient's chest lies ~0.55 higher (1.6 deep), so the medic leans 13 deg less and lifts its straight arms (Poses CPR_LIFT, under BODY_FIT + SMOOTH_BODY_V6) so the stacked hands land on the chest plate; the leg jitter fix (CPR_STILL kneel hold, F93) stays; the hands are in the Grip pose. **CPR** (both the ragdoll medic and a down patient): the medic kneels beside the patient with both knees on the ground, its hands stacked on the patient's chest plate, arms straight, the pumps from the hips; the patient lies flat; **no leg jitter (F93)**: the medic's legs are welded in the kneel while it pumps; the doctor's hands the same.
6. **PART DONE v1324:** the physics arms are shortened to v6's (0.77 and 0.78 of R15, every rig point moved, the rig rebuilt from the attachments): shoulder to wrist is now 1.25 (v6: 1.26), so the physics hand, which the phone, the newspaper and every held prop are welded to, is where the v6 hand is drawn; the hands take the Grip pose for paper/CPR/Check (HAND_POSES). LEFT: per-prop finger wrap tuning and the accessories on the round head. **Held props in the NEW fingers** (the v6 hand bones, posed by state, HAND_POSES):
   - the PHONE: held in the right hand, the screen to the face (filming: held up, the arm bent), the fingers wrapped round it;
   - the NEWSPAPER: held open in BOTH hands at reading height, the paper route throw from the right hand;
   - the tweezers, the shovel (both hands on the shaft), the lasso and the grab points, the persona accessories (sweatband, cap, glasses, headphones, the egg hats) sized to the round v6 head.
7. **OWNER CHECK (no code change yet):** the rides are welded to the pelvis (SeatOn + Offset) and posed by angles, so they follow the v6 pelvis; the shorter v6 arms may now fall short of the bike grips: in the test list. **Rides and poses:** the BICYCLE (the seat under the pelvis, both hands on the grips, the feet on the pedals and turning with them), the wheelchairs, the seesaw, the benches (sitting with the bigger thighs, never sunk into the seat), the rocket strap, the stretcher (F74), the cannon hopper load, the bowling ball curl (the tight ball with v6's round volumes), every machine's grip and hold point.
8. **DONE v1325 (bandages):** on a v6 body a bandage wraps the limb at BodyShape.wrapRadius (radius + 0.05); slings and splints follow the v6-sized parts. **Care:** bandages, slings, splints and plasters wrapped round v6's thicker limbs at BodyShape radius + 0.05; the pick-out plaster on the hole point.
9. **DONE (no change needed):** the head is the game's own head part (unchanged), so FaceLife, blinks, the mouth and the expressions run on it as before; the marks are in the v6 colour map. **Face and marks:** the face on the v6 head (living eyes, blinks, the talking mouth, the expressions); the marks on the upper arms, thighs and chest as on the renders; soot, wet and paint tints on the one mesh.
10. **DONE v1326 (`V6_FAR_BODIES`):** on a PC the nearest 24 ragdolls within 120 studs wear the v6 mesh (the far ones driven at 15 Hz with no finger poses: the cheap version of the same mesh); phones keep 12 within 80. Stretch moves the physics parts the v6 mesh follows. **Stretch (F74), far bodies (R1/R10 LOD) and phones:** stretch moves the v6 bones and grows the physics parts; the far cheap version is the SAME v6 mesh; the device caps stay.
11. **The check, done by reading each item's attach point** (a bone or part plus an offset from BodyShape): nothing floats off, sinks in or pokes through the v6 body. One quick Play for errors only (NO TESTING rule); the owner tests it all at the end (the final test list gets one line per item above).

**THE v6 FIT PASS: the OWNER'S TEST (27 Nov late, 2 screenshots: a chest X-ray as a pile of loose bone sticks round the torso; a v6 body walking with the OLD grey cylinder head, leaning back with both arms up).** The owner: "Gør så x-ray forsvinder efter 3 sekunder, og kun kommer når man har skudt på lemmen 3 gange i streg, og hvis man slår det til, så er det der hele tiden, slår man det fra, er det kun det andet. De skal have samme knogler som de andre, ikke kun i torsoen - alle lem. Og ansigtet matcher ikke kroppen. Og de løber, og går urealistisk." Fix all four in this pass, before anything else:
- **A. The X-ray rules (exactly):**
  - **toggle OFF** (the I key, the X-RAY button): X-ray shows ONLY on a limb you have hit **3 times IN A ROW** (3 hits on that same limb with no hit on another limb in between; a hit on another limb starts that limb's count and resets the others), for **3 seconds**, then it goes away. The next 3 hits in a row show it again.
  - **toggle ON:** the near bodies are in X-ray ALL the time, until you switch it off.
  - **The bug today** (`Client/DummySkins.luau` ~767-798): for the torso, `n` is the number of BulletHoles, but after the 3 s `x.from` is reset from `Anatomy.parseWounds` matched against `BRUISE_AT`, which never matches "UpperTorso"/"LowerTorso", so `x.from` becomes 0 and `n - 0 >= 3` at once: the chest X-ray comes straight back and stays forever. **Fix:** keep the limb's latest count (`x.n = n` on every pass) and reset `x.from = x.n` when the 3 s end (for every limb, the torso too); add the "in a row" streak (a new hit on limb L sets `x.from = x.n` on every OTHER limb that is not showing).
- **B. The WHOLE skeleton in X-ray, every limb, the same bones as the other bodies:** skull and jaw in the head; the spine, ribcage, sternum, shoulder blades, collarbones and pelvis in the torso; the upper-arm bone, both forearm bones, the wrist and the HAND and finger bones in each arm; the thigh bone, the kneecap, both shin bones, the ankle and the FOOT bones in each leg. Each bone sized and placed from BodyShape INSIDE the v6 limb along its centre line, following the v6 bones (no loose sticks floating round the chest, as on the owner's screenshot: each torso bone is fixed at its anatomical spot, not scattered by hits). The slugs, cracks and breaks sit on these bones.
- **C. The head and face match the body:** the v6 body still wears the OLD grey cylinder head in the game. Give it the ROUND head from the approved renders (`v5_head.py`): a MeshPart (or part of the v6 mesh) in the SAME light grey and material as the v6 body, sized and welded to the Head physics part; the game's living face (eyes, blinks, mouth, expressions) put on THAT head at the size and spot of the renders; the old head and its face hidden on v6 bodies. The far cheap bodies get the same round head.
- **D. Walk and run that look real (for a chunky toy):** today they lean back with both arms up. First find the cause: very likely the v6 bones' rest pose does not match the physics parts' pose (an A-pose mesh driven by T-pose parts, or wrong bone roll), so every pose comes out with the arms up and the body tilted; fix the bone mapping in `Client/SmoothBody` (per-bone rest offsets from the v6 rig) so a standing ragdoll stands straight with the arms down by its sides. Then the gait for v6 (`ClipGait`, BoneAnimator clips; make new Blender clips for v6 if the old ones do not fit):
  - **walk:** upright, a tiny forward lean, the arms swing down by the sides opposite to the legs, the knees bend, heel then toe, the stride matched to v6's shorter legs so the feet never slide, a soft up-down bob and a little side sway (a toy waddle, cute, never stiff);
  - **run:** a bouncy jog with a forward lean of about 10 degrees, the arms bent at 90 degrees pumping, a higher knee lift, the head steady;
  - the switch between them eased; the speed limits stay (F83).
- **E. The rounds INSIDE, on the bone; only nice holes on the skin** (owner, 27 Nov late: "Kun gør så skudene er synlig med x-ray inde på knoglen, ikke ude på huden, der skal bare bløde fra de 3 seneste huller og være custom hul på huden hvor det er flotte skudhuller som altid"):
  - **the slugs** (the brass rounds) exist ONLY in X-ray and ONLY on a bone inside the body: each one on the bone its shot line reaches first (BodyShape centre line), never on or outside the skin (the owner's screenshot shows brass sticks poking out all round the chest: none of that). Out of X-ray, no slug can be seen at all;
  - **the skin** shows only our own custom bullet holes (the nice hole decals as always, on the v6 surface point, `fbf5864`), with their exit holes; no brass, no bone, no sticks on the skin;
  - **the bleeding:** only the **3 newest** holes on a body drip purple (the trickle down the skin, the drops, the pool under the lowest); older holes stay as dry holes. A new hit moves the drip to the newest 3.
- **The owner's checks** (in the final test list): shoot one limb 3 times in a row: it shows its bones for 3 s and goes; shoot 3 different limbs: no X-ray; in X-ray the rounds sit inside on the bones, out of X-ray only nice holes on the skin and only the 3 newest bleed; X-RAY on: all near bodies show the full skeleton in every limb until it is turned off. A walking and a running v6 ragdoll: round grey head with its face, straight body, arms down and swinging, no foot sliding.

**More life:**
- **The stance:** upright and relaxed, never hunched or hand-clasped by default;
- **the face:** R2, living eyes, blinks and a talking mouth;
- **idles:** R3 and R5, weight shift, looking round, persona gestures, scratching the head, stretching;
- **squash and jiggle:** item 7 above.

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

**R9. Everything fits the NEW body** (owner, 27 Nov: "Fiks så at den nye krop og ben passer til skudhuller, x-ray, blod osv. Alt ved den ragdoll skal være 10/10, så vi har de BEDSTE physics"; `Config.BODY_FIT = true`)

Today the holes, the splatter, the X-ray, the bandages and the physics were made for the old 15 BLOCKS. On the slim v2 body they float off the skin, sit inside it, or the hit lands where there is no body. Everything must match the body you SEE:
1. **ONE body shape table** (`Shared/BodyShape.luau`, written by the Blender script from the v2 mesh):
   - for every bone, its length and its radius profile along the length (shoulder, mid, elbow…);
   - for the torso, the front/back depth and the width at chest, waist and hips.

   Every system below reads it. Change the mesh, re-export the table, and everything follows.
2. **The physics matches the look:**
   - the 15 invisible physics parts are resized from BodyShape to fit inside the visible limbs (slim arms, tapering legs, a real chest and waist), so a shot that visibly hits the arm hits it, a shot past the slim arm misses, and feet stand flat on the ground (no floating, no sinking);
   - the masses are re-set to the RAGDOLL_FEEL shares (torso about 40 %, head 8 %, each leg 16 %, each arm 5 %);
   - the joint attachments are moved to the mesh's real joint centres (no gap or overlap at the shoulders and hips);
   - the collision between body parts stays on except at joints.
3. **BULLET HOLES on the skin:**
   - each hole goes on the VISIBLE surface: the client raycasts along the shot against the SmoothBody mesh (a raycast-only query) and places the hole at that exact point, along the surface normal;
   - it is welded to the physics part under it (which the bone follows), so it moves with the body;
   - an exit hole on the far side for the guns that go through (D12), on the surface too;
   - the X-ray slug sits on the bone on that same line.
4. **SPLASH, DRIPS, POOLS:**
   - the splash bursts from the surface point along the normal;
   - the 2-3 dripping holes run a thin trickle DOWN the skin (along the part's down direction) and drop from the lowest point of that limb;
   - pools form under the hole that is lowest on a lying body.
5. **X-RAY:**
   - the shell is the v2 mesh itself made see-through (glass, a blue rim), never the old blocks;
   - the skeleton is scaled to BodyShape (the bones along the mesh's limb centre lines, the ribcage inside the real chest), so cracks, breaks, shatters, slugs and the bullet path (F28 tracer) are INSIDE the body you see;
   - the hand bones in the real hands.
6. **BANDAGES, SLINGS, SPLINTS, PLASTERS:** wrapped round the slim limb at BodyShape's radius at that point (plus 0.05), never floating or sunk; the pick-out plaster on the hole's surface point.
7. **BRUISES, SOOT, WET, PAINT, the crash-test marks:**
   - small surface decal patches at hit points (bruises fade);
   - whole-body tints for soot, wet and paint (a temporary colour on the mesh, eased back);
   - the crash-test marks on the mesh's temples, chest and knees.
8. **STRETCH (F74) on the skinned body:** move the child bones out along the limb (the skin stretches between the bones, rubbery), and grow the physics parts to match (from BodyShape × the stretch factor).
9. **The HANDS:** one set only: the v2 mesh's finger bones, posed by state (RealHands' parts hidden where the mesh is shown).
10. **FAR bodies:** the cheap version of the same mesh (R1) gets the same hole, splash and tint rules (no finger poses, holes capped per device: AUDIT 37).
11. **Damage at the right spot:** HitService and the bone system (D12) read the part hit by the server ray. With the physics parts now matching the mesh, the bone, the hole and the X-ray slug all agree.
12. **Cost:** one extra client raycast per visible hole (pooled); BodyShape is a small static table; nothing per frame.

## Check (the owner, phone first)
Stand among the ragdolls for a minute, then hit some:
1. they look like slim grey crash-test dummies with small persona accessories and slightly different sizes;
2. their eyes follow you and blink, and their mouths move when they talk;
3. they walk like people;
4. a light hit makes them stumble and recover; a big one makes them fall with their arms out, slide, and get up the right way, dizzy;
5. you hear their steps and their "oof";
6. none vanishes, spins its head, jitters or walks into things;
7. shoot one on the new body: the hole sits ON the skin where it was hit, the splash comes from there, the drip runs down the limb, X-ray shows the bone and the slug inside the body you see, a bandage wraps the slim limb.
