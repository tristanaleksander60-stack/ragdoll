# V9: everything you can use a ragdoll with looks and moves top class (owner, 21 Nov 2026)

## The owner's words (verbatim)
> Lig en plan for at gøre alle modellerne man kan benytte ragdolls med bedre, altså hajen, edderkoppen osv, alle de ting som man kan købe med robux også. Fx. hvalen som skal være under vandet og fed animation når den spiser en ragdoll og bedre akvarium og sårn. Sammel alt i 1 plan så jeg bare kan skrive klar til claude code. Imens så opretter jeg alle produkterne

## How it runs
- One `/klar` runs all of V9 in order: V9-0 → V9-6, then `docs/RELEASE.md` (it publishes by itself).
- **Then** go back to V8 at its State line.
- Between steps, report in Danish and go straight on. Do not wait for the owner.
- **Ids:** the owner is creating the products and passes while this runs. If ids arrive in chat, paste them in (V9-0, F5) and carry on.

## Rules for every step
- **The look:**
  - Real Creator Store models with the malware pass, rigged where they move, in one style (bright, readable, slightly cartoon, kid-safe).
  - Nothing code-built from blocks or balls, no clipping, nothing floating, and the right scale against a 5-stud dummy.
- **Motion:**
  - Every creature and machine has idle, notice, act (eat, launch, spin), react and reset motion.
  - Animate on the rig's bones or Motor6Ds, client-side, from one server start event (as `Client/CreatureAnim` does), so the server stays cheap and every screen is in sync.
  - Asset uploads need an approved folder that is not set, so use procedural / tweened animation, not uploaded AnimationIds.
  - Easing with anticipation and overshoot; squash and stretch where it fits.
- **The "eat" beat** (every creature that takes a ragdoll):
  1. It notices the ragdoll (head turns, eyes widen).
  2. A wind-up.
  3. A snap.
  4. The body is hidden (`MachineHidden`) in a cartoon way: no gore, no blood.
  5. Chewing or a wobble for 1-2 s, with sound.
  6. A spit or launch with a trail. The ragdoll flies out whole and lands on the lab side (`toLab`).
  7. A happy beat.

  The camera may punch a little (FeelBus BigHit), with no shake for the reduced-motion setting.
- **Sound:** each thing gets idle, act and react sounds (Pro Sound Effects / Roblox-licensed), played through SoundMix, at most 2 at once per lab.
- **Server decides:**
  - who is taken, the cooldowns (`MachineCool`), the throw;
  - the physics of the ragdoll stays the same;
  - works on dummies and players (V8-2.7), cartoon-style.
- **Phone budget:**
  - triangles and parts per creature in Config;
  - LOD: past 120 studs only idle at 10 Hz, past 250 hidden;
  - low tier keeps the frame time.
- **Each step:**
  - before/after captures (still + a short act sequence of 4 frames) from fixed spots;
  - one blind reviewer per step (pass bar 8.5);
  - the tests;
  - commit and push;
  - a State line here;
  - a short Danish report (Lavet / Test selv / Brug for fra dig).

## V9-0 First: the open fix plan
Run all of `docs/FIX_PATHS_SHOP.md`:
- F1 real bushes;
- F2 no grey strips through paths;
- F3 no dead-end paths;
- F4 captures;
- F5 purchase pictures and id paste-in.

## V9-1 The water: a real aquarium, the whale under water, a shark
- **The aquarium.** Replace the flat glass "WhalePool" with a real aquarium/lagoon in the creature yard:
  - glass walls with frames and rivets, deep enough to see into (about 14-18 studs deep, partly sunk into the ground, with a viewing side facing the path);
  - Roblox **terrain water**, or a water mesh with a moving surface (gentle waves, caustic light on the floor);
  - sand floor, rocks, seaweed that sways, coral, bubbles rising, a few small fish (client-side, cheap);
  - a ladder/ramp and a feeding platform with a sign icon (LabGuide).
- **The whale** lives **under water**:
  - It swims slow loops with a tail beat, blinks, and breaches now and then (a splash and a spray).
  - **Eat:** it rises under the dropped ragdoll, opens wide, gulps it with a big splash, swims a happy loop with the cheeks puffed, then blows it out of the blowhole as a geyser. The ragdoll flies to the lab side. Water ripples, spray particles, a deep whale call and a splash sound.
- **The shark** (the owner's "hajen"): add a shark in the same aquarium, or its own tank, if there is room in the yard (one water body is cheaper).
  - It circles with its fin above the surface.
  - It snaps at a ragdoll that drops in: a fast bite, a shake, then spits it out over the glass, cartoon style.
  - It is a real rigged shark model, with a friendly cartoon face (kid-safe).
- **Swimming:** players and ragdolls float and swim in the water. Nothing gets stuck under the glass. A body under water for more than 6 s pops back up.
- **Tests:** T151_Aquarium.
  - The whale and the shark take a ragdoll and throw it to the lab side.
  - Nothing is left inside the glass.
  - Budget held.

## V9-2 Every creature in the yard
Go through each one in `Server/Systems/LabCreatures` and its model in V3Assets (M prefix). Replace any model that looks cheap with a better rigged one, and give it the full beat set from the rules:
- **Spider:**
  - a big rigged cartoon spider in a real web (strands that sway and stick);
  - it scuttles down on a thread, wraps the ragdoll in silk while spinning it, hangs the cocoon, and munches with a wobble;
  - the "burrito" spit;
  - the hunger meter as a small icon in the world;
  - napping with Zzz.
- **Plant:** a carnivorous plant with leaf jaws that sway and track the nearest body, chomp, chew (the stem bulges) and spit.
- **Frog:** it sits on a lily pad or rock, its throat puffs, the tongue shoots out in an arc (a stretchy beam), reels the body in, gulps, then a burp-hop launch.
- **Chicken:** a giant chicken that pecks, clucks and sits; then a big egg pops out and cracks, and the ragdoll tumbles out.
- **Washer:** a real washing-machine model. The door opens, it spins with a wobble and suds, then the door flies open and throws the body out.
- **Slingshot tree:** a real tree with a rubber band. It stretches back with a creak and snaps forward with leaves falling.
- **Mole:** a dirt mound with real dirt particles. The mole peeks and dives, the ground cracks, and it pops up under a ragdoll.
- **Vacuum robot:** a real robot vacuum. It roams with blinking lights, sucks the body in (with suction lines) and shoots it out.
- **Yard layout:**
  - each creature on its own small "habitat", reached by the paths (F3);
  - a clear drop ring (LabGuide) and a sign icon;
  - spaced so their acts never overlap.
- **Tests:** T103 updated, plus a T152_CreatureBeats check (each creature: notice → act → release within its time, the body is released, it is not stuck).

## V9-3 The lab machines
Give the same pass to everything in the lab that takes or throws a ragdoll:
- the **cannon** (barrel recoil, smoke ring, breech, a turn/aim motion);
- the **bullseye** (score rings that light up where the body lands, a wobble on hit);
- the **trampoline** (springs and a stretchy mat that dips);
- the **launch stations** (a real launcher model with a lever pull and a clank);
- the **wrecking ball** (real chain links, swing with weight);
- the **spinning mace**;
- the **lava pit** (it already has LAVA_V2; only the throw-out beat);
- the **tower**;
- the **BIG RED BUTTON** (a press-down with a click and a cover that flips up);
- the **knockables** (V8 Knockables: barrels, crates, cones).

For each one:
- a real model at the right scale;
- a readable "ready" state;
- a satisfying act;
- a return to rest.

Keep the gameplay numbers the same unless the act needs a small timing change (note it in State).

## V9-4 Everything sold for Robux, perfect
These are the `map = true` OFFERS and the passes that put a thing in the world. Each must look and move as good as its price (the turning booth model **and** the thing in use):
- **Spider Deluxe:** a golden version of the V9-2 spider with sparkle, a bigger spit and its own sound.
- **Mega Trampoline:** a big premium trampoline with a padded frame and a deeper bounce dip.
- **Giant Fan:** an industrial fan whose blades spin up, with a visible wind (streaks, leaves) and a roar.
- **Robot Dog:** a rigged robot dog with a walk cycle, a tail wag, a sit when you stop, a head tilt and a little bark. It never clips through you.
- **Parrot:** it sits on your shoulder, flaps when you jump or ragdoll, and flies a loop now and then.
- **Gold Dummies:** real gold with a reflection (MaterialVariant), still reading as a dummy, and the dead green still shows.
- **Crash-Test Suit:** a proper suit with clean seams, the target marks and a helmet. It fits R6/R15 and stays on in ragdoll.
- **Rainbow Trail / Fire Trail:** smooth trails with no gaps at speed. The fire has embers and is never blinding.
- **Bolt Crate / Starter Crate:** a crate that opens with a pop and bolts spilling, in the booth and on purchase.
- **Booths (V6-7):** each booth's turning item is the same improved model. Lit well, with the price readable at 20 studs.
- **TRY:** TRY shows the real thing working for 60 s.
- **Tests:** T105 updated (every booth model present and script-free; every item works after purchase and after TRY; delivered once).

## V9-5 Event creatures and big models
- **Bring every event model up to the same bar:** Gorilla, Bull, UFO, Train, Balloon, Giant Dummy, Tornado, Meteor, Bowling balls, Magnet, Rocket rain and so on.
- **Each needs:** a real model, an entrance, an act on the ragdolls, an exit and sound.
- **Match V8-2.9:** only the events that stay get the work. The rest stay hidden and are not sold.

## V9-6 Final check and release
- **Full self-test suite** and LayoutCheck.
- **10-minute play:** on PC and in the phone emulator, feeding every creature and using every machine and every bought item at least once, with no errors.
- **Low tier frame time** held with the whole yard active.
- **A capture sheet** for the owner: every creature, machine and Robux item, before and after.
- Then `docs/RELEASE.md` (it publishes by itself), then back to V8.

## State
- 21 Nov 2026: plan written (cloud). Nothing done.
