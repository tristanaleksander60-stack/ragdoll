# CREATURES and MACHINES ALIVE: idles, catches and knockouts (owner, 26 Nov 2026 late)
> "Nu med blender aktiveret så kan vi vel få en del til opgraderet, idle til alle dyr der spiser ragdolls, fede animationer til alle maskiner og dyr til når de dræber ragdolls. Vær specifik, kreativ og unik."

**The goal:**
- every animal looks ALIVE when nothing happens (3-4 idles each, never one loop);
- every animal and machine has its OWN signature "catch" and knockout, a little cartoon show with an anticipation, the hit, a comic beat and the release;
- no two are alike.

**The kid rules (gore off) hold everywhere:**
- no blood (purple cartoon only), nothing torn off;
- every body comes back out WHOLE, dazed, with a funny leftover (seaweed, a honey pot, a sock);
- squash and flatten are cartoon and temporary;
- a "kill" is a knockout: eyes closed or stars, then the normal wake or revive.

## 0. The pipeline: Blender for the models and the motion, code for the playing (do this once, first)
1. **Models in Blender, from Python scripts** (`blender --background --python tools/blender/<name>.py`, with the LihFolk `roblox-blender-modeling` skill and its quality gate). For every creature:
   - one skinned, rigged mesh in the clean, simple, solid style of the owner's references (MAP ROUND 4: low-poly, smooth shading, plain colours, no busy textures);
   - **budgets:** at most about 4,000 triangles and 40 bones per animal (T-rex 60);
   - the bones named clearly (`Root`, `Spine1-3`, `Neck`, `Head`, `Jaw`, `Tail1-n`, `L/R_Leg1-3` …);
   - export as FBX into `art/models/creatures/<Name>.fbx`.
2. **Motion in Blender, played by code** (so nothing has to be uploaded as an Animation asset):
   - each clip is keyframed in the same Blender script (an Action per clip);
   - the script then writes the clip into a Luau module `Shared/Anim/<Name>.luau`: `{ [clip] = { length, loop, events = { {t, "Sound"/"Fx"/"Grab"/"Release"/"Hit", data} }, bones = { [bone] = { {t, CFrame relative to rest} … } } } }`;
   - one client player, `Client/BoneAnimator.luau`, plays these clips on the imported mesh's Bones (`Bone.Transform`), with cross-fades of 0.2-0.3 s, playback speed and events.
   - The server only says WHAT plays and WHEN (an attribute `Clip` = name and `ClipAt` = server time on the creature), so every client plays it in sync; physics and hits stay on the server as today (`LabCreatures`, `MapMachines`, `GuardDog`).
3. **Importing the meshes:**
   - if the Studio MCP can import an FBX, do it;
   - if not, collect ALL the FBX files of the run in `art/models/creatures/` and put ONE owner step in the final message: "Studio: File > Import 3D > each file in art/models/creatures/ into ServerStorage.V3Assets". The code finds them by name, and until a model is there the old one stays (nothing breaks).
4. **Cost:**
   - animation only on the client, within 120 studs (full rate within 60, 15 Hz beyond, a frozen idle pose beyond 120);
   - phones: at most 4 animated creatures at a time (the nearest);
   - effects pooled; sounds pooled, max 3 per creature per second.
5. **Machines:** their animation is code on their existing parts (tweened CFrames, spring curves) plus the ragdoll's choreography (a short pose sequence through `ActiveRagdoll` tone and hand-made poses, then physics). Blender only where a machine needs a new rigged part (the plant's jaws, the press's piston bellows).

## 1. ANIMALS: idles, the hunt and the signature catch
| Animal | IDLES (pick at random, 6-15 s each, never the same twice in a row) | THE HUNT (a ragdoll in reach) | THE SIGNATURE CATCH, and the funny ending |
|---|---|---|---|
| **Shark** (aquarium) | slow laps with a tail sway; noses the glass where a player stands, its eye following the player; a lazy barrel roll; drifts belly-up near the surface for 2 s, then flips back as if caught napping | the fin breaks the surface and circles the body twice, tighter each time; the music-free tension is a low "dun-dun" sound | **"The Gulp":** it lunges from below and swallows the ragdoll whole. The shark's belly bulges in the ragdoll's shape, with little kicks visible through the skin; a hiccup, a purple bubble ring burp, then "PTOO!": it spits it onto the feeding platform, dazed, with seaweed on its head (10 s) |
| **Crocodiles** (pond) | basking on the bank with the mouth wide open; a huge slow yawn; sinking until only the eyes show; a tail swish that ripples the water; two of them nudging each other | it drifts like a LOG (only the back and eyes showing) toward the body, then freezes 1 s | **"Death Roll and Fetch":** it snaps, spins 3 times in the water with the ragdoll, tosses it into the air and catches it like a dog with a treat, then spits it onto the bank. If a second croc is near, they play a TUG OF WAR first, and the ragdoll stretches a little (cartoon) before both let go and it flies out |
| **T-rex** (pen) | sniffs the air with flaring nostrils; tries to scratch its nose with its tiny arms and can't reach (a sad grumble); stomps a patrol with dust puffs at each step; a roar at the sky; sleeps standing with a snore bubble | **"Don't move":** if the ragdoll stands still, the T-rex leans in close and sniffs it (the ragdoll's face: terrified, sweating)… then SNEEZES it across the pen | **"Chomp Toss":** it picks the ragdoll up by its shirt, shakes it like a toy, throws it up and catches it in its jaws (CHOMP), chews twice with its cheeks bulging, then spits it over the fence. Its tiny arms do a victory clap |
| **Bear** (cave) | scratches its back on the stump (a wiggle dance); licks honey from a pot; sits and pats its belly; sleeps inside the cave mouth with a snore; stands up to sniff | it stands on its hind legs, sniffs, and gives a big ROAR (the ragdoll's hair blows back) | **"Bear Hug":** it waddles over and gives a crushing hug (the ragdoll's eyes pop, cartoon), drops onto it in a belly flop, then drags it by one leg into the cave. 3 s of thumps and a "WHAM!" puff from the cave mouth, then the ragdoll is thrown back out with the HONEY POT stuck on its head |
| **Spider** (pen) | re-spins a strand of its web; rubs its front legs together; hangs upside down from a thread and bobs; drums its legs impatiently | it drops from the web on a thread right in front of the ragdoll's face | **"Burrito":** it spins round the ragdoll in a blur and wraps it into a silk cocoon in 1.5 s, then hangs it from the web, where it wiggles. After 5 s the ragdoll sneezes and bursts free in a puff of silk |
| **Guard dog** (`GUARD_DOG.md`) | wags its tail; scratches its ear with a hind leg; sniffs the ground in zig-zags; chases its own tail; rolls over for a belly rub when the player is near | the existing bite on a tapped limb | **"Tug and Zoomies":** the tug-of-war bite with a head shake (as now), then a victory ZOOMIES lap round the ragdoll; then it trots to the player and drops the ragdoll's SHOE at the player's feet, tail wagging |
| **Man-eating plant** (3.15) | sways; snaps at a fly; licks its "lips" with a leaf tongue; burps a petal; turns its head to follow the player | it opens wide and leans toward the ragdoll, drooling green bubbles | **"Snap and Chew":** it swallows the ragdoll to the waist (the legs kick in the air), chews 3 times, then spits it out covered in yellow POLLEN. The ragdoll sneezes 3 times in a row |
| **Frog** (3.14) | throat pulse; slow blink; catches a passing fly with its tongue; a little hop on the spot | it crouches, its eyes locked on | **"Tongue Lasso":** its long tongue sticks to the ragdoll and reels it in, GULP: the frog swells up round. A huge hiccup shoots the ragdoll out like a cork, in an arc |
| **Chicken** (3.16) | pecking; head bobbing; wing flaps; scratching the ground; lays an egg and looks proud | it puffs up its feathers and charges | **"Peck Storm":** a blur of pecks knocks the ragdoll down; then the chicken SITS on it like an egg, fluffs up and clucks proudly (the ragdoll's feet stick out) |
| **Whale** (big pool) | a slow spout; a lazy roll; a tail slap that splashes the pool edge | it surfaces under the ragdoll | **"Blowhole Launch":** it swallows the ragdoll, then blows it out of the blowhole on a water spout about 40 studs high; the ragdoll lands in the pool |
| **Mole** (3.24) | pops its head out, looks round with a twitching nose, sniffs, dives back; a dirt mound moves along the ground | the mound runs straight under the ragdoll | **"Down and Up":** the ragdoll is pulled into the ground up to its waist (cartoon), it wiggles; then it is popped out on the far side of the field by a fountain of dirt |

**Every animal also:**
- **looks at the player** now and then (the head turns);
- **reacts to a shot nearby** (a flinch, then an angry look);
- **after a catch**, does a small "satisfied" idle (licking lips, belly pat, a burp).

## 2. MACHINES: the signature knockout show
| Machine | The anticipation | The hit | The unique funny ending |
|---|---|---|---|
| **Cannon** (3.1) | the fuse sparks, the barrel creaks up to its angle, the watcher covers its ears | BOOM, recoil, a smoke ring | the ragdoll lands in a STARFISH pose and leaves a ragdoll-shaped DENT in the ground that fades; 1 in 10 shots is a "dud": a sad puff, a pause, then a second bigger BOOM |
| **Tower plank** (3.2) | the ragdoll walks out on the plank, wobbles, windmills its arms | it falls | lands head-first stuck in the ground, legs up and wiggling, then pops out |
| **Slide** (3.2) | it sits at the top, waves | it whooshes down faster and faster (speed lines) | launches off the end like a ski jump with a flip |
| **Gyro cage** (3.3) | the rings spin up with a rising whine | the body tumbles | it stumbles out DIZZY with cartoon stars circling its head, walks in a circle twice and falls over |
| **Giant fan** (3.4) | the blades spin up; its cheeks and clothes ripple (a "windy" face) | it leans into the wind… | it is blown away tumbling like a leaf. Sometimes the fan first runs BACKWARDS and sucks it close to the grille, then blasts it |
| **Trampoline** (3.5) | bounces higher each time with a counter (1, 2, 3…) | the last super bounce | lands head-first stuck in the ground, or bounces off the rim onto the grass |
| **Wrecking ball** (3.6) | it swings back with a long creak | SMACK with a "DING" | the ragdoll flattens against whatever it hits like a pancake poster, then slowly peels off and slides down |
| **Press** (3.7) | it lowers slowly with a warning light; the ragdoll looks up with a terrified face | CRUNCH | it is squashed FLAT like a pancake (cartoon squash), then pops back to shape with an accordion wobble and a "boing" |
| **Washer** (3.8) | it climbs in through the door (F24), the door shuts | the spin cycle: the ragdoll tumbles past the round window in bubbles | the door opens and it stumbles out dizzy, sparkling clean, with a SOCK on its head and 10% smaller for 20 s ("washed too hot") |
| **Rocket** (3.9) | the countdown 3-2-1 with the ragdoll strapped to the side | lift-off in smoke | the rocket loops; the ragdoll's parachute opens… or, 1 in 4, it is a pair of underpants, and it falls with a scream |
| **Launch pads + brick wall** (3.10) | a run-up | it flies into the wall | the bricks fall on it, and the last brick lands on its head with a "bonk" and a bump |
| **Boxing ring** (3.18) | the bell, the two face off | the punches, the knockdown | the referee counts to 10 on its fingers, the winner flexes, the loser sees stars |
| **Stretcher** (3.19) | the claws creak out | the limbs stretch long (F74) | it walks away with a noodle leg (F74) |
| **Tesla coil** (3.20) | the hum rises, sparks crawl up the coil | ZAP | the X-RAY skeleton flashes 3 times (the classic), its hair stands up, its face is sooty, smoke comes out of its ears, and it sneezes a spark |
| **Shredder** (3.21) | it falls between the rollers | the purple confetti (as now) | it is spat out whole, wrapped up like a GIFT with a bow on its head |
| **Sweeper** (3.22) | the beam turns; the ragdolls on the pad JUMP over it in rhythm (jump rope) | one trips | the beam sweeps it off the pad spinning like a bowling pin; the others cheer |
| **Lava strip** (3.23) | it steps too close | it touches the lava | a "HOT HOT HOT" dance: it hops round holding its bottom, smoke from its pants, then falls over sooty (the soot fades) |
| **Archery / slingshot** (3.25) | an APPLE on its head, it trembles | the arrow flies | it hits the apple… or its bottom (1 in 3), and it jumps holding it |
| **Cars, tank, monster truck** (3.17) | headlights flash | it is run over | it lies flat with TYRE TRACKS across it (cartoon), then peels itself off the ground like a sticker |

## 3. How to build it, in order (part of OVERVIEW PHASE 5, with row 3 MACHINES_10)
1. **A0, the pipeline (section 0):** the Blender scripts folder, the Luau clip exporter, `BoneAnimator`, the server `Clip` attributes, and one test creature (the shark).
2. **Per item, in `MACHINES_10.md`'s priority order:** build its MACHINES_10 10/10 AND its section here together, in ONE pass (never twice).
   - The animals get a new Blender model with idles and the catch.
   - The machines get their show with their existing parts.
3. **Sounds:** each signature beat gets its sound (gulp, chomp, boing, ding, zap…) from the licensed sets (`lihfolk-sfx`); pooled.
4. **Faces:** the ragdoll's face follows the show (terrified, dizzy, sooty, sneezing), with the faces of BODY_V2 4b.

**Check (the owner):** walk past every animal (it does something alive) and set off every catch and every machine. Each one has its own show and its funny ending, and the ragdoll always comes back whole.
