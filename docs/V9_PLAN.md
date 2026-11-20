# V9: everything you can use a ragdoll with looks and moves top class (owner, 21 Nov 2026)

## The owner's words (verbatim)
> Lig en plan for at gøre alle modellerne man kan benytte ragdolls med bedre, altså hajen, edderkoppen osv, alle de ting som man kan købe med robux også. Fx. hvalen som skal være under vandet og fed animation når den spiser en ragdoll og bedre akvarium og sårn. Sammel alt i 1 plan så jeg bare kan skrive klar til claude code. Imens så opretter jeg alle produkterne

## How it runs
- One `/klar` runs all of V9 in order: V9-0, V9-0b, V9-0c, V9-1, V9-2, V9-2b, then V9-3 → V9-6, then `docs/RELEASE.md` (it publishes by itself).
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

## V9-0b The thumbnail look: bright, sunny, alive (owner, 21 Nov)
> "Lig en plan for at få spillet til at føle som thumbnailsne ... lige nu ser det mørkt ud og himlen ser død ud i forhold til thumbnailsne."

**Target.** `art/store/look_target/thumb_cannon.webp` and `thumb_gorilla.webp`.

**The look of the target:**
- a deep saturated blue sky with big white fluffy clouds and a visible warm sun with a soft flare;
- bright warm sunlight from one side with soft, blue-tinted shadows (not black);
- high colour: lush green rolling hills with round trees, warm sandstone, red and yellow accents;
- clean white dummies that pop against the background;
- light dust and smoke puffs.

Do this step first, so every later capture in V9 uses the final light.

**Where the look comes from:** Lighting, the post effects and the sky, set per place through ZoneLighting (LOOK_V3 `finishV3`) and AdminWorld (time/weather). This ends the "realistic grey" grade.

**Light:**
- Daytime about 14:00-15:00 (`ClockTime`), with the sun in front of the spawn camera's side so faces and the cannon get light.
- Brightness about 2.5-3.5. Warm `ColorShift_Top`; `Ambient` and `OutdoorAmbient` raised and tinted light blue, so shadows read blue-grey, never black.
- `EnvironmentDiffuseScale` and `EnvironmentSpecularScale` about 0.6-1.0. ExposureCompensation tuned so white dummies are white but not clipped.
- Keep LightingStyle Realistic + PrioritizeLightingQuality. Check that phones (low quality) still look bright.

**Sky:**
- A bright cartoon-blue sky with big cumulus clouds: a Creator Store skybox of that style, or Roblox `Clouds` (Cover about 0.5-0.6, Density about 0.7, white).
- A visible sun (SunTextureId / SunAngularSize larger) and a soft SunRays.
- The old sky stays in ServerStorage as a backup.

**Atmosphere:**
- low Density (about 0.2-0.3), Haze low, a light blue Color/Decay;
- the far hills read soft blue, not grey fog.

**ColorCorrection:** Saturation about +0.15-0.25, Contrast about +0.05-0.1, a slight warm TintColor. Bloom soft (Intensity about 0.4, Threshold high) so only the sun and white highlights glow. DepthOfField only off or very light in normal play.

**Ground and world:**
- greener, brighter grass (terrain colour `SetMaterialColor` for Grass/LeafyGrass), and warm sandstone paving;
- the lab's dark grey/asphalt areas get a lighter, warmer surface where it fits;
- round, lush trees (real models) on the hills;
- red/yellow accents on barriers and barrels.

**Snow (Christmas from 1 Dec):** a sunny snow day: blue sky and sun stay, the snow is light, and it never turns the scene grey.

**Every place.** Lab, Plaza, Arena, Island, City, Site, Farm and Military each get their own profile in the same bright family. Indoor/arena light gets the same lift. The director (V6-3) and admin time/weather still work on top.

**Phones:** the low tier frame time holds; post effects are cheap or off at low quality, and the scene must still look bright without them.

**Done when:**
- side-by-side captures, the game vs the two thumbnails, from the same kind of angle (the cannon with the bullseye; a wide lab shot with hills), on PC and phone;
- the blind reviewer says it matches the target mood (≥ 8.5);
- the owner signs off;
- T91 is updated if it checks light values.

**Switch:** `Config.LOOK_THUMB` (false = the old light).

## V9-0c Cars that drive straight, and a speedometer (owner, 21 Nov)
> "Når man sætter sig ind i bil så drejer den bare rundt i en cirkel fiks det og lav speedometer."

**Reproduce first** on PC (WASD), on a phone (thumbstick) and with a pad, in the Car and the Truck (`VehicleService`, `Client/VehicleClient`, `VehicleFeel`). Log the throttle and steer input, the heading and the angular speed each frame.

**Likely causes to check:**
- **Steering read from the camera:** the steering is taken from `Humanoid.MoveDirection` or relative to the camera, so the car chases its own camera and circles. The steer must come from the input axis only (A/D, stick X, the phone's steer control).
- **The model's forward axis:** the model's forward axis does not match the drive force. The imported model's front is ±X or the `Yaw` attribute is applied twice, so "forward" pushes sideways and the yaw torque never settles.
- **A stuck steer:** a non-zero steer or AngularVelocity/AlignOrientation target that is never reset to 0 when the input is released.
- **Wheels:** the VehicleFeel wheels on Welds touch the ground unevenly, so one side drags. The visual wheels must be non-colliding; the drive body decides.
- **Network owner:** the driver must own the car. A server/client ownership flip makes it fight itself.

**Fix the root cause.**
- Steering:
  - centred when no input;
  - a smooth steer with a speed-dependent turn rate;
  - no turning on the spot at 0 speed.
- Driving:
  - reverse works;
  - the brake works;
  - the car stays upright (anti-flip) and never gets stuck in a spin.
- **Phones:** phones get clear drive controls: GAS/BRAKE pedals plus steering, or the thumbstick X for steering and pedals for throttle. Pads get RT/LT plus the left stick. They follow the HUD and LayoutCheck rules.

**Speedometer.** A round gauge HUD while seated:
- a needle that sweeps and a number (km/h; 1 stud ≈ 0.28 m, or the scale from Config);
- a small gear/R indicator;
- a red zone at top speed.

It follows the UI v2 tokens, phones included (out of the thumb zone), and hides on exit.

**Tests:** T153_CarDrives.
- With throttle only for 3 s, the heading changes less than 3°.
- Steer left or right turns that way, and releasing it stops the turn within 0.5 s.
- No spin at 0 throttle.
- Both vehicles pass.

**Capture:** the speedometer on PC and phone.

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


**Much juicier eating (owner, 21 Nov: "Gør animationerne meget federe på dyrene ... når de flækker ragdolls").** On top of the beat in the rules, every creature's act must feel like a cartoon highlight:
- big anticipation (a long wind-up, eyes popping);
- a hard snap with squash and stretch;
- impact frames: a white flash, a quick hit-stop of about 80 ms through HitFeel, and a small camera punch;
- a comic word pop in the world ("CHOMP!", "GULP!", "SPLAT!", "BOING!") as a drawn sticker, not plain text;
- particles that fit: stars, feathers, splash, silk strands, dust, suds;
- layered sound (whoosh → snap → crunch-free chew → spit);
- the ragdoll launched with spin and a trail;
- a happy victory wiggle;
- a short slow-mo beat for the first feed of a visit.

All of it stays kid-safe (no gore) and within the phone budget.

## V9-2b A feed terminal at every creature, spam allowed (owner, 21 Nov)
> "Gør så at det er en lille computer terminal man kommer hen til og så kan trykke feed ved og spam hvis man ville."

**The terminal.** Replace the floating "Feed" ProximityPrompt (`LabGuide`) with a small computer terminal model beside each creature (and the cannon/lava/trampoline machines that have one):
- a real model: a console on a post, a screen, and a big glowing FEED button;
- the screen is a SurfaceGui showing the creature's picture, its hunger bar and "FEED!";
- it beeps and lights when used.

**Use:**
- Walk up and press FEED:
  - click or tap the button on the screen (SurfaceGui button);
  - or E / ButtonX through a prompt for keyboard and pad.
- **Spam is allowed and fun:** every press sends the next dummy flying in an arc into the creature. Rapid presses chain:
  - a combo count on the screen ("x5!");
  - the creature gets more excited;
  - the feeding speeds up a little.

**Server rules:**
- every press is checked: owner or party member, near the terminal;
- a rate limit of about 4 presses per second;
- a queue of at most 6;
- the feed uses free lab dummies first. When none are free, it drops a spare dummy from a little chute on the terminal, within the device-tier body cap, and the spare is cleaned up after;
- no remote without `Net` validation and a rate limit, listed in CLAUDE.md.

**Tests:** T154_FeedTerminal.
- One press = one feed.
- 20 fast presses respect the rate limit and the queue.
- A press from far away or by a stranger is refused.
- The body cap is held.

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
