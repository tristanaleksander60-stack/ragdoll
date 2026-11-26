# The big RACETRACK south of the lab + the F1 car to buy (owner, 26 Nov 2026)
> "Tilføj en racerbane der udfylder resten af det stykke hvor der ikke er noget i hele bunden, det skal altså være en kæmpe racerbane, så skal man kunne købe adgang til en F1 bil derfra Creator Store med scripts og det hele, det er fint, så længe den er god og har mange reviews."

The owner's top view shows the lab compound in the north and middle, and a big empty green area across the whole bottom (south). The racetrack fills that area.

Behind `Config.RACETRACK = true`. It is part of THE MAP (OVERVIEW item 1b).

## 1. Where and how big
- **Area:** south of the railway's south line (railway z 420) to the map's south edge, extended as needed: about x -500..450, z 450..1000 (lab-space studs, `OwnerMapPlan` axes). Grow the grass base and push the backdrop's forest belt and hills further south, so the track sits INSIDE the landscape (forest edge round it, hills behind).
- **The circuit:**
  - a real F1-style layout, about 2,500-3,500 studs a lap;
  - a long start/finish straight along the north side (parallel to the railway, visible from the station);
  - a hairpin at each end;
  - a fast sweeping S-section;
  - a chicane;
  - a long back straight;
  - one banked corner.
  - **No self-crossing:** use a bridge if the layout crosses itself.
- **Track width:** 50-60 studs (F1 cars are fast and wide); 70 on the start straight and in the pit lane.

## 2. How it looks (a real circuit, not a grey loop)
- **Surface:** dark asphalt with a fine texture, white edge lines, a start/finish chequered line, grid boxes for 10 cars, and the pole and lap markers painted on.
- **Kerbs:** red and white striped kerbs on every corner apex and exit (raised slightly, with a rumble sound when driven on).
- **Run-off:** green grass and grey gravel traps on the outside of fast corners (gravel slows cars a lot, with dust).
- **Barriers:**
  - tyre walls (stacked black tyres) at the hairpins;
  - steel Armco rails along the straights;
  - a catch fence in front of the stands.
- **The start/finish gantry** over the straight: the start lights (5 red lights that go out), a big lap-time screen, and sponsor-free signs with our own made-up brands.
- **Pit lane and paddock:**
  - a pit building (garages with roll-up doors, a roof terrace);
  - a pit wall with a timing desk;
  - a paddock with trucks and tents.
- **Grandstands:** 2-3 big covered grandstands on the straight and at the main hairpin, with ragdoll spectators who cheer, wave flags and do the wave when cars pass.
- **Details:**
  - marshal posts with flags at the corners;
  - a big screen;
  - a podium (1-2-3) by the pit building;
  - the track name sign: our own name, e.g. "RAGDOLL RING".
- **Getting there:** from the lab's south station, a footbridge over the railway leads down to the paddock; a sign "RACETRACK" stands at the Tower Square's south road.

## 3. The F1 car (bought access)
- **The model:** from the Creator Store, with its scripts, as the owner allows. Pick a well-made open-wheel F1 / formula car with MANY favourites and good reviews, ideally on a known chassis system (e.g. A-Chassis based). Prefer one recently updated. Write the asset id, the creator, the favourite count and why it was chosen in this doc's State.
- **Security check, even though scripts are allowed** (backdoors are common in free models). Read EVERY script in it and remove anything that:
  - calls `require(<number>)`;
  - uses `getfenv` / `setfenv` / `loadstring`;
  - uses HttpService;
  - is obfuscated (long strings of escaped bytes, junk variable names);
  - inserts other assets;
  - touches other players or the DataStore;
  - makes remotes that run code.

  Keep only the chassis, the drive and the UI scripts. If the car depends on a removed loader, pick another car.
- **Wiring into the game:**
  - its remotes are wrapped or replaced so they go through our `Net` rules where possible;
  - the server checks who may drive it (pass owner).
- **Feel:**
  - fast (about 180-250 studs/s top speed on the straight), grippy, with braking zones, a high-revving engine sound and gear shifts;
  - a speedometer, a gear and RPM HUD (phone: simple throttle/brake buttons plus tilt or the stick, big and clear);
  - a cockpit and a chase camera.
  - Tune it so a 10-year-old on an iPad can drive a lap without crashing every corner: mild steering assist, plus stability on phones.
- **Buying access:**
  - a game pass "F1 RACER" (the owner creates it in the Creator Hub and sends the id; until then the id stays 0 and the buy button is hidden);
  - in Studio, a test-buy works;
  - suggested price R$ 199-299 (the owner decides).
  - **A free test lap:** non-owners get ONE free lap a day (`F1_TEST_LAP = true`), then "Get the F1 RACER pass to keep racing!". Try-before-buy sells better; it is behind a switch, and the owner can turn it off.
  - The pass is shown at the pit building (a big 3D display of the car on a turntable plus BUY) and in the SHOP (VEHICLES).
- **The track has free cars too:** a go-kart for everyone (slower, about 90 studs/s), so non-buyers can race and want the F1.

## 4. Racing gameplay
- **Lap timing:**
  - a timer starts at the start line;
  - sector splits (3 sectors, purple/green/yellow like real F1);
  - a "NEW BEST LAP" pop;
  - your best lap is saved.
- **Leaderboards:** a BEST LAP board at the pit building and on the big screen (top 20, scrolling, like the lab boards). Separate boards for kart and F1.
- **Ghost:** your best lap as a see-through ghost car to race against (phones: on only within the caps).
- **Ragdolls:** ragdoll marshals and spectators can wander onto the track. Hit by a car, they fly with full physics and impact effects, then get up dizzy and wave a fist. Score: "MARSHAL BONK". Gore stays off.
- **Multiplayer place:** players race each other with the start lights, a 3-lap race and a podium.

## 5. Performance (phones)
- The asphalt is a few big parts or terrain; kerbs and barriers are meshes (instanced, cheap); the grandstands are simple meshes with a few animated ragdoll stand-ins.
- The track streams out when far away (StreamingEnabled).
- Keep the lab's part budget separate. The track region has its own budget: about 3,000 parts.
- Check the FPS on the phone emulator while driving a full lap.

## 6. Check
- One quick Play:
  - walk from the station over the bridge to the paddock;
  - drive a kart lap and see the lap time;
  - test-buy the F1 pass in Studio and drive a lap (the start lights, timing, NEW BEST);
  - knock a marshal ragdoll;
  - check the free test lap as a non-owner.
- Capture the track from above and at the start straight, PC and phone.

## State
- (none yet)
