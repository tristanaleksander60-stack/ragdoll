# V9: everything you can use a ragdoll with looks and moves top class (owner, 21 Nov 2026)

## The owner's words (verbatim)
> Lig en plan for at gøre alle modellerne man kan benytte ragdolls med bedre, altså hajen, edderkoppen osv, alle de ting som man kan købe med robux også. Fx. hvalen som skal være under vandet og fed animation når den spiser en ragdoll og bedre akvarium og sårn. Sammel alt i 1 plan så jeg bare kan skrive klar til claude code. Imens så opretter jeg alle produkterne

## How it runs
- One `/klar` runs all of V9 in order: V9-0a, V9-0, V9-0f, V9-0b, V9-0c, V9-0d, V9-0e, V9-1, V9-2, V9-2b, V9-2c, then V9-3, V9-3b, V9-3c, V9-4, V9-4b, V9-5, V9-5b, V9-6, then `docs/RELEASE.md` (it publishes by itself).
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

## V9-0a Hitting a ragdoll never opens Talk (owner, 21 Nov; do it first, it is quick)
> "Fiks så at når man forsøger at slå en ragdoll at man ikke åbner talk menuen hele tiden."

**Cause to confirm.** The Talk prompt (`NpcCommand` addPrompt: a ProximityPrompt on the Head, Default style, `HoldDuration` 0, reach 9) is clickable/tappable by default (`ClickablePrompt`). A click or tap meant as a hit on a close dummy lands on the prompt, and `Client/NpcTalk` opens the panel. E (the key) may also clash with tools.

**Fix:**
- Set `prompt.ClickablePrompt = false`, so a mouse click never opens Talk.
- On PC and pad, Talk only through its key: E, or L3 on a pad.
- **Hide the Talk prompts on this screen** (`NpcTalk.setPrompt`) during any attack and for 2 s after any attack: fire held, a swing, a shot (`AmmoClient.onSpent` / `FeelBus` Shot), or a grab. Also hide them while Grab holds a body.
- **Touch** (no key there): never let a tap meant as a hit open Talk.
  - The prompt shows only when the player stands still near a living dummy with no attack in the last 3 s.
  - Talk needs a short hold (`HoldDuration` about 0.4 s on touch).
  - Or move Talk to a small TALK chip beside the HUD that appears near a dummy, never on the dummy's body.
- **NpcTalk:** never opens the panel if an attack happened in the last 0.5 s, even if the prompt fires.

**Test:** T158_HitNotTalk.
- 30 quick clicks/taps on a dummy at 3-8 studs open the Talk panel 0 times.
- E (or a hold on touch) next to a calm dummy still opens it.

## V9-0f GOD MODE lives in the SHOP like every other pass (owner, 21 Nov; quick, do it next)
> "Fiks så at god menuen ikke er synlig for alle men bare er i shop som de andre passes."

**Now (0.30.0):** GOD MODE has its own HudV3 square between Shop and Lab off phones, and a MENU entry on phones. Every player sees it.

**Change:**
- **No GOD MODE square or MENU entry for players without the pass.** HudV3Layout.LEFT goes back to Shop, Lab. The God window (`Client/GodMode`) is not reachable from the HUD for them.
- **In the SHOP:**
  - GOD MODE is a normal pass card among the others, in the same style and order as `Shop.PASSES` / OFFERS: picture `art/icons/god.png`, name, one line ("Spawn dummies anywhere, twice as many, with a golden beam"), price R$199, BUY.
  - It has a **TRY 60 s** button on the card that starts the existing free trial (`DummySpawn.startTrial`, once a visit) and opens the God window for those 60 s.
- **Owners of the pass** (player attribute `God`): the God window opens from a small GOD button. It shows **only for them**, in the HUD square off phones and as a MENU entry on phones. They can also open it from their owned card in SHOP ("OPEN").
- **During a trial:** the same small button shows with a countdown, then it disappears again.
- **Unchanged:** the server rules stay as they are (`godGated` / `mayCreate`, the trial once a visit, the device caps).
- **Gamepad:** reaches the card and the button.
- **Layout:** LayoutCheck shows 0 problems with and without the pass.

**Tests:** update T148_GodMode.
- Without the pass and the trial: no GOD launcher in the HUD or MENU, and the card is in SHOP.
- TRY opens the window and starts the trial.
- With the pass (`OfferService.grantPass`): the launcher shows and the window opens.

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

## V9-0d The ground stops flickering, the bench set is fixed, a plaza people want to meet in (owner, 21 Nov)
> "Også fiks bordet bænke sættet her på plazaen og generelt upgrade plazaen så folk for lyst til at mødes. Desuden så bugger jorden når man kigger rundt på grund af alt det grussten tror jeg."

**What the capture shows** (`art/store/look_target/plaza_bench_now.png`):
- a green bench floating on a stack of overlapping stone discs, with a table that is missing or broken;
- layers of round paving pieces on top of each other;
- the booth signs crowding the seating.

**1. The ground flicker (z-fighting and shimmer). Fix it everywhere, not only on the plaza.**
- **Find it.** Write a tool script that lists every pair of overlapping parts whose top faces are within 0.06 studs of each other. These are:
  - path stones on stones;
  - paving discs on discs;
  - paving on the plaza floor or the baseplate;
  - verge pieces on grass parts.

  Run it in the lab, the plaza and every map. The list must reach 0.
- **Fix the cause:**
  - one surface layer per area: merge the overlapping round paving pieces into single clean slabs or shapes, or use terrain paint where the ground is terrain;
  - where layers must stack, at least 0.1 stud apart and never the same material on the same height;
  - remove hidden duplicates (older path versions under newer ones).
- **Shimmer at a distance** (the busy "gravel" texture): use a calmer paving material or MaterialVariant with a larger `StudsPerTile` and less high-frequency detail. Keep the stone look up close.
- **Check:** slow 360° camera turns at the spawn, the plaza and 2 maps, on PC and phone. No flicker seen.
- **Test:** T156_NoZFight (the overlap scan returns 0 in the lab and on the plaza).

**2. The bench and table set.**
- Replace it with a real picnic set: a table with two benches as one model, or matching table plus benches, at the right height, standing on the ground (not on discs).
- Every seat works: Seat parts at the right height, facing the table, and a player sits correctly.
- Check every other bench and table in the game the same way.

**3. A plaza people want to meet in.** Design it as a town square, with:
- **A centre piece:** a fountain or a landmark statue (a giant crash-test dummy).
- **Seating:**
  - picnic sets and benches facing each other in small groups, under shade trees;
  - string lights between lamp posts, warm at dusk.
- **Things to do together:**
  - a photo spot (a frame with the game's logo and a step);
  - the plaza grab and throw area clearly marked by its shape, not by paint;
  - a high-five or emote spot;
  - the leaderboards together in one place;
  - the portals.
- **A market row:** the map-shop booths as a proper market row along one side (V9-4b spacing). They never stand among the seats.
- **Life:**
  - a few calm crowd NPCs sitting, chatting and walking (existing CrowdService);
  - pigeons (Birds);
  - ambient town sound, with no music (owner rule).
- **Layout:** clear walking lanes from the arrival to everything, open space in the middle, flowers and planters at the edges, and no clutter.
- **Light:** the bright thumbnail light from V9-0b.

**Done when:**
- before/after captures from the arrival, the seating, the centre and from above;
- the blind reviewer passes it (≥ 8.5);
- the walking and crowd tests pass;
- T156 passes.

## V9-0e A beautiful Places portal you see at once (owner, 21 Nov)
> "Lav en portal til places som er flot og ses hurtigt af spilleren så de udforsker."

**Today.** Travel to the maps is a HUD button (Maps), plus the lab's two server portals (PortalSolo / PortalMulti, `PortalService`). Players rarely leave the lab (V8 data: maps are seldom used).

**The new portal:**
- **One big, beautiful "PLACES" portal in every lab**, placed in the spawn view (inside the V8 spawn cone, at about 25-40 studs from spawn, on a path, not blocking the cannon/dummies view).
  - **Look:** a round stone or metal ring gate (a real model) with a swirling animated surface (a slowly turning texture plus particles), a soft glow and a hum.
  - **Pictures:** small live picture panels of the 5 maps round it (the map card pictures), turning slowly.
  - **Look and sound:** in the V9-0b bright look, plus a low hum.
- **Walk in (or press E / tap):** a picture carousel of the places opens (Plaza, Arena, Island, City, Site, Farm, Military, with only the maps that are live). It shows:
  - each place's picture, name and one line ("Feed the shark", "Drive the tank");
  - who is there now;
  - a NEW tag.

  Pick one, then the V8-2.10 travel: stream ahead, a short whoosh transition through the portal swirl, and you arrive in front of that map's hero thing.
- **Ways home:** the same portal stands at every map's arrival ("Back to my lab" plus the other places), so the maps feel connected.
- **Hints, never spam:**
  - after the first 3 minutes, and only once a visit, a subtle beam or sparkles call from the portal;
  - one Notify tip the first time ("Explore other places →");
  - an experiment card "Visit 2 places".
- **The existing PortalSolo / PortalMulti** become part of the same gate family (one style). They must not be confused with PLACES: they get different colours and clear icons.

**Done when:**
- a capture from spawn on PC and phone (the portal is visible in the first frame);
- the carousel on 16 LayoutCheck screens;
- a trip to each place and back works;
- Session_v1 logs `used.portalPlaces` so its effect can be read.

**Tests:** T159_PlacesPortal.
- The portal is in the spawn view at 1920x1080 and 414x896.
- Each place travels and returns.
- Travel is refused while seated or grabbing.

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

## V9-2c Z opens a time dial: faster or slower in a bubble round you (owner, 21 Nov)
> "Gør så at Z ikke bare stopper tiden i ens lab et lille sted, men åbner en lille menu hvor man kan skrue tiden hurtigere eller langsommere i en bobbel rundt om en selv."

**Now:** Z = `SandboxService` "SlowMo", a fixed slow-motion bubble over the lab's middle (ToyService Slowmo), with a gap of 8 s.

**New: Z opens a small time menu** (it closes with Z again or Esc):
- a round dial or slider with steps **0.1x · 0.25x · 0.5x · 1x · 2x · 3x**, the current speed shown big;
- a size control for the bubble (small / medium / big, for example 12 / 20 / 30 studs radius);
- ON/OFF.

The UI v2 tokens; drag or click on PC; tap on phones (the button sits under More/sandbox and is phone-sized); LB/RB or the D-pad on a pad.

**The bubble:**
- It is centred on the player and follows them (only in their own lab, or a party lab).
- **Look:** a clear, slightly refractive sphere with a soft rim glow. Blue for slow, orange for fast, with ripples where things cross the edge, a clock-tick sound slowed or sped up, and the sky/colour inside the bubble faintly tinted.
- **Inside, time really runs at the chosen speed** for dummies and props (the server decides; Roblox has no per-region time scale, so it is simulated):
  - **gravity:** a VectorForce per body in the bubble counters gravity to `g·s²`;
  - **speed:** velocities are scaled by `s` on entering and by `1/s` on leaving;
  - **launches and throws:** launch impulses inside are scaled;
  - **creatures, machines and animations:** they run at `s` (their tweens, the AnimationTrack/procedural speed and the cooldowns);
  - **effects:** particles get `TimeScale = s`, and sounds get `PlaybackSpeed` × `s` (limits 0.5-2);
  - **at 3x:** dummies fall and fly fast and machines cycle fast, with caps so nothing explodes or tunnels through walls.
- **Players** keep their own walking speed (so they can enjoy the effect). The camera gets the C5 slow-mo look only when the bubble is slow.

**Rules:**
- **Server checks:**
  - owner or party only;
  - inside their lab;
  - the speed from the list only;
  - one bubble per player;
  - a rate limit on changes.
- **Remote:** goes through `Net` with a validator; it is listed in CLAUDE.md (extend the Sandbox remote, do not add a new one if it can be helped).
- **Performance:** at most N bodies affected per bubble per device tier. On the low tier the visual is simpler.
- The old one-tap behaviour stays reachable: the dial opens on 0.25x by default, so Z then Enter is the old slow-mo.

**Tests:** T157_TimeBubble.
- A dummy dropped inside at 0.25x falls about 4x slower than outside (±15 %).
- At 2x it falls faster.
- Leaving the bubble returns it to normal.
- Bad speeds and a stranger's lab are refused.
- The menu fits on 16 LayoutCheck screens.

**Capture:** the menu and the bubble at 0.1x and 3x, on PC and phone.

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

## V9-3b Bigger gaps between weapon unlocks (owner, 21 Nov)
> "Lav større mellemrum på når man unlocker nye våben."

**Now:** takedown rungs come from `Toys` (the base rungs → `squeeze` under `LADDER_V2` with `LADDER_KEEP` / `LADDER_V2_SCALE` → `V8_RUNGS` / `START_BAR_V9` / `HARD_RUNGS`).

**Change:**
- **Widen the gaps** between unlocks, so each new weapon feels earned and the ladder lasts longer.
- **Keep the first-minutes hook** (V8's evidence: players who get early takedowns and a first present stay longer):
  - the start bar stays as it is;
  - the first present (Launch at 3) stays;
  - the next 2 unlocks stay within the first ~10 minutes.
- **From there on**, the gaps grow:
  - make it a smooth curve, for example each gap about 1.35-1.5x the one before, set as Config numbers (`LADDER_V9_GROWTH`, `LADDER_V9_KEEP`);
  - the top end stays reachable, about 2-3x today's top;
  - keep `HARD_RUNGS` items (the Rocket at 470) in proportion.
- **Show the progress well,** so the wait never feels empty: the NEXT pill / NextUnlocks bar shows "x / y KOs" and fills smoothly, there is a small reward sound at 50 % and 90 %, and the unlock moment is a big satisfying reveal.
- **Never take anything away:** a profile keeps every weapon it already owns (grandfather, like Ladder 5). The Robux weapon tiers and Bolts prices are re-checked so nothing looks like a pay wall (V8-5 fair shop).
- **Switch:** `Config.LADDER_V9` (false = today's ladder).

**Tests:**
- T35, T64 and T110 updated;
- a new pure test checks that the gaps grow monotonically after the kept early rungs, that no owned weapon is lost, and that the top is at most `LADDER_V9_TOP`.

**Watch after release:** Session_v1 takedowns-per-visit and leaves just before an unlock. If early leaves rise, shrink the growth.

## V9-3c The big rocket in the lab: strap a ragdoll on and launch it from a computer (owner, 21 Nov)
> "Gør så man kan bruge den store raket i ens lab så man trykker ved en computer og strap en ragdoll på."

**Now:** a big Rocket model stands in the lab only as decoration (LabDress role `Rocket` at x -72, z 12, height 26).

**New: a working launch pad.**
- **Pad:** the rocket stands on a launch pad with a gantry and arms. Beside it is a launch **computer terminal**, the same family as V9-2b: screen, big red LAUNCH button and a countdown display. Pick it up: a real rocket model, a launch tower and a terminal, from the Creator Store with the malware pass.
- **Press LAUNCH** (click/tap on the screen, or E / ButtonX):
  1. The lab's nearest free dummy is carried in an arc to the rocket (or a spare one drops from the gantry). It is strapped on with belts, standing at the nose, and given a little helmet.
  2. The gantry arms swing away.
  3. A 3-2-1 countdown on the screen and above the rocket, with steam venting and a rumble.
  4. Lift-off: a big flame and smoke trail, a camera shake nearby and a roar. The rocket climbs, wobbles a little and arcs over the lab.
  5. At the top, the straps pop: the ragdoll flies free, spinning, with a trail. It lands toward the bullseye or the crash zone (with BULLSEYE scoring), or uses a small cartoon parachute some of the time for fun variety.
  6. The rocket bursts into a cartoon firework (kid-safe, no debris that hurts).
  7. A fresh rocket rises back onto the pad from below, ready again.
- **"Ride it yourself"** (optional second button on the terminal): the player straps themselves on, with the same flight. Your own lab, or a party lab, only.
- **Server rules:**
  - owner or party only;
  - near the terminal;
  - cooldown about 10 s (one flight at a time);
  - a press during a flight queues at most 1;
  - the flight is server-driven for the body (network owner stays the lab's player for the fall);
  - the ragdoll physics stays the same;
  - LabGuide gives it a ring and a sign icon.
- **The same V9 rules apply:** juicy beats, sound, a phone budget, and the first launch of a visit gets the slow-mo beat. An experiment card "Launch a dummy to space" and a journal page.

**Tests:** T161_RocketPad.
- One press = one dummy strapped, launched and landed whole on the lab side.
- Spam respects the cooldown and queue.
- Strangers are refused.
- The rocket resets.
- No body is left stuck on the rocket.

**Capture:** a 4-frame launch sequence and the terminal.

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

## V9-4b Buying and trying must look premium (owner, 21 Nov)
> "Lig også en plan for man undgår det ser så grimt ud når man skal købe eller try."

**What the owner's capture shows now** (`art/store/look_target/booth_now.png`):
- **Prompts:** two default Roblox ProximityPrompts stacked ("Gold Dummies / Try 60 s free", "Gold Dummies / Buy").
- **Overlap:** they overlap the neighbouring booth's sign ("FIRE TRAIL"), so the names do not match what you look at.
- **Pole:** a pole runs through the gold dummy.
- **Spacing:** the booths stand so close that their signs and prompts collide.

**One card per booth, our own style:**
- Hide the default prompts: `ProximityPrompt.Style = Custom`, drawn in `ProximityPromptService.PromptShown`.
- Show one clean card for the nearest booth only, in the UI v2 tokens:
  - the item's picture or icon (`art/shop`);
  - the name;
  - the one-line pitch;
  - the price with the Robux mark;
  - two real buttons: **TRY 60 s** (secondary) and **BUY** (primary, gold).
- The buttons work by click or tap, and through the E/T keys and pad glyphs. Pads can select them.
- The card pops in softly and leaves when you walk away. Only one card shows at a time.
- The world sign above the booth fades while its card is open.
- **States:** the card shows OWNED ✓ / EQUIP when owned, TRYING 0:42 during a trial, and TRY USED when today's try is spent.
- **Phones:** the card sits above the thumb zone, has 44 px targets and passes LayoutCheck. No text is cut off.

**The booths themselves:**
- No pole or light post through any item. Move the spotlight to the booth's frame, or use a hidden light.
- Spacing: at least about 14-16 studs between booths, so signs and prompts never overlap. A prompt's reach (`MaxActivationDistance`) stays inside its own booth, and `RequiresLineOfSight` is on.
- The sign belongs to its own booth: the same name and price as the prompt, readable at 20 studs and never overlapping its neighbour.
- Each item on a clean pedestal, lit, turning slowly, at the right scale.

**Buying feels good:**
- **On BUY:** Roblox's own purchase prompt.
- **On success:**
  - a short celebration: confetti, the item flies to the player or equips at once, and a "YOURS!" banner through `Client/Banner`;
  - a purchase sound;
  - the booth switches to OWNED.
- **On cancel:** nothing nags.

**Trying feels good, with no pressure:**
- **TRY** equips the real thing at once.
- A small HUD chip shows "Trying <item> 0:42" with the item icon and a small BUY button.
- When the try ends, there is one gentle line through Notify ("Liked it? It's at the booth"). No pop-up window, no repeat (Roblox policy, and V8's calm rules).

**Tests:** T155_BoothCard.
- One card at a time.
- The card's item always matches the nearest booth.
- No prompt reach overlaps a neighbour.
- No booth part intersects its item.
- The card fits on 16 LayoutCheck screens.
- The OWNED / TRYING states are right.

**Capture:** the same angle as the owner's screenshot, before and after, on PC and phone.

## V9-5 Event creatures and big models
- **Bring every event model up to the same bar:** Gorilla, Bull, UFO, Train, Balloon, Giant Dummy, Tornado, Meteor, Bowling balls, Magnet, Rocket rain and so on.
- **Each needs:** a real model, an entrance, an act on the ragdolls, an exit and sound.
- **Match V8-2.9:** only the events that stay get the work. The rest stay hidden and are not sold.

## V9-5b A clean server and no lag, without losing quality (owner, 21 Nov)
> "Sørg for serveren kører så clean som overhovedet muligt med så lidt lag som overhovedet muligt, uden at ødelægge eller svække noget kvalitet mæssigt."

**Measure first, with numbers.** Use a full lab session with 6 players (4 test clients if MCP multi-client allows, else 2 plus bots), all creatures, machines and events used, and 10 minutes on a map. Record:
- **server:** heartbeat Hz, physics step time, script activity per script (the Script Performance view), memory per category, instance count, Data send/receive KB/s per player, remote calls/s per remote;
- **clients:** FPS p50/p5, frame time, draw calls, triangles, memory (MicroProfiler dumps), on PC and the low-tier phone emulator.

Write the baseline into `docs/PERF.md`.

**Fix the heaviest first:**
- **Loops:** every `while true` / Heartbeat loop on the server.
  - Event-driven where possible, at the lowest rate that still looks the same (for example 10-15 Hz for AI, 0 when no player is near).
  - No per-frame `GetDescendants`, `FindFirstChild` chains or new tables.
  - Sleep the whole lab's AI, creatures and machines when its owner is away or not in the lab.
- **Physics:**
  - set the network owner of every ragdoll and prop correctly (the lab's player);
  - anchor or sleep idle props;
  - limit the bodies per lab by device tier (already there: check it holds);
  - CanQuery/CanTouch off on all decoration;
  - collision groups so decoration never collides;
  - CollisionFidelity Box/Hull for props;
  - Touched handlers only where needed.
- **Network:**
  - no per-frame attribute writes;
  - batch updates;
  - UnreliableRemoteEvent for cosmetic streams;
  - send only to players in that lab or place;
  - check every remote's rate limit;
  - nothing replicated that only one client needs (creatures' animation stays client-side, V9 rules).
- **Memory and leaks:**
  - disconnect every connection on cleanup (players leaving, bodies removed, events ending);
  - destroy temp parts;
  - pool effects;
  - run a 30-minute soak and check that server memory and instance count stay flat.
- **Streaming:**
  - StreamingEnabled with sensible radii;
  - models atomic or persistent only where needed;
  - far maps never loaded until visited.
- **Rendering:**
  - CastShadow off on small parts;
  - LOD (RenderFidelity Automatic, `ModelStreamingMode`);
  - lights within FX_CAPS;
  - particles pooled and capped per tier;
  - textures sized sensibly.
- **Start time:** time to the first playable frame; preload only what the first minute needs.

**Rule:** nothing may look or feel worse. Every fix needs a before/after capture where it could change the look. A change that lowers quality is reverted.

**Done when** `docs/PERF.md` shows, against the baseline:
- the server heartbeat stays at 60 with 6 players in full chaos;
- server script time and memory are flat over 30 minutes;
- network per player goes down;
- the low-tier phone holds 30+ FPS p5 in the lab;
- no errors and no warnings in the output.

**Tests:** T160_PerfBudget (instance count, loop count and remote rate per lab under its budget; leak check after a lab reset).

## V9-6 Final check and release
- **Full self-test suite** and LayoutCheck.
- **10-minute play:** on PC and in the phone emulator, feeding every creature and using every machine and every bought item at least once, with no errors.
- **Low tier frame time** held with the whole yard active.
- **A capture sheet** for the owner: every creature, machine and Robux item, before and after.
- Then `docs/RELEASE.md` (it publishes by itself), then back to V8.

## State
- 21 Nov 2026: plan written (cloud). Nothing done.
- 21 Nov 2026, V9-0a DONE (PC): `Shared/TalkRules` (pure). The server's TalkPrompt is `ClickablePrompt = false`. `Client/NpcTalk` hides every Talk prompt for 2 s after a click, R2 or own shot (3 s on touch; on touch only while standing still, with a 0.4 s hold) and while Grab holds a body, and ignores an "Open" within 0.5 s of an attack. T158_HitNotTalk passes (18 live prompts not clickable). Live in Studio: 30 quick clicks with the Popper on a dummy 5-9 studs away opened Talk 0 times (the prompt hid at once and came back after 2 s); E next to a calm dummy still opens it (capture).
- 21 Nov 2026, V9-0 DONE (PC) for the lab (details in FIX_PATHS_SHOP State): real foliage (FOLIAGE_V9), no grey strips (kerb runs, warm kerbs), nothing on the paving, every path end at its thing; T150 passes, T106/T112/T147/T50/T103 pass. Captures: spawn, yard, garden after. The plaza's and maps' old stone-disc paths move to V9-0d. Place saved v683 (new V3Assets roles).
- 21 Nov 2026, V9-0b DONE (PC), owner to sign off: `Config.LOOK_THUMB` + `LOOK_THUMB_LIGHT`. `Client/ZoneLighting` (thumbSky) works on this screen only; the server and the place keep the realistic sky.
  - Sky: Roblox's classic cloud skybox ("ThumbSky"), a big sun (SunAngularSize 18) behind the spawn camera's left shoulder (ClockTime 14.5 and GeographicLatitude 50 put the sun at about (-0.54, 0.71, 0.45)), plus dynamic Clouds (cover 0.58).
  - Light: Brightness 3.3, blue ambient (shadows read blue-grey), a warm ColorShift_Top, light-blue air (density 0.22, glare 0.6), saturation +0.22, contrast +0.08, a warm tint, bloom 0.4 at threshold 1.4, sun rays 0.1, no depth of field.
  - Terrain grass (96,158,62).
  - Captures: the cannon and the spawn, before and after. Phones keep the bright base light when the post effects drop at low quality.
