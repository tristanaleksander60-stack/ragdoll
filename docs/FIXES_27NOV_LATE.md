# FIXES 27 Nov late (owner, while testing): do these FIRST, in this order, as ONE batch where files overlap

## 0. Cloud code already written (push into Studio, ONE quick Play)
**DONE v1361:** all five files are in Studio (length check), one Play clean.
- **"." closes and opens the body card on a computer** (`Client/BodyCard.luau`, `Config.NO_EMOTE_MENU`): Roblox's emote wheel also uses ".", and it took the press, so it is turned off.
- **More room round the player** (`Config.MORE_ROOM`, `Systems/Lab.luau`, `Systems/RagdollDirector.luau`): the comer stops 9 studs away (not 5.5); within 45 studs at most 5 on a phone, 6 on a tablet and 8 on a PC (not 7, 9, 12).
- **The head no longer wobbles on the body** (`Client/SmoothBody.luau`): the round head was welded to the physics head, while the mesh's neck is drawn from the bone chain every frame. Now it is anchored and placed from the mesh's own Head bone in the same frame. Check that the face, the X-ray skull and the hats still follow it.

## 1. X-ray on one limb: NOT a cylinder (owner: "Fiks x-ray så det ikke bare er en cylinder")
Today A2 puts a pale capsule round the limb (on the torso a big glass box), which reads as a cylinder stuck on the body.
- **Make the glass the limb's OWN shape:** in Blender, split the approved v6 mesh at its joint planes (the same cuts the v6 build uses) into 15 closed pieces, one per R15 part (each piece = the faces whose strongest bone weight is that part), pushed out 0.015 along the normals. Export them as 15 plain MeshParts named after the parts (`art/models/mannequin/mannequin_v6_xray.fbx`; MCP upload, else ONE owner import step).
- **In the game:** on the limb hit 3 times in a row, the matching piece is shown welded to that physics part at its rest offset, in light-blue Glass at about 0.55 transparency, with a soft blue edge glow. The bones show through with the Highlight (AlwaysOnTop) as in A2. The timing stays: 2 s, then a 1 s fade.
- **Until the pieces exist:** NO sleeve and NO box at all; only the bones through the skin with the Highlight. Never a cylinder or a box.

## 2. CPR: the hands together (owner: "De samler ikke hænderne når de laver cpr")
- The medic's two hands are stacked on the centre of the patient's chest plate: one palm on the chest, the other on top of it, fingers interlaced (the v6 finger bones: a CPR grip pose in `HAND_POSES`), arms straight, the shoulders right over the hands.
- Each push goes down from the hips, and the hands stay together the whole time (an IK target on the chest point for both wrists, not two separate arm poses).
- The same goes for the player's own CPR game and for heroes giving CPR.

## 3. Only 1-2 talk to you; the rest do things with what they are at (owner: "de skal interagere med det de er ved, kun 1-2 står og snakker til brugeren")
- **Facing and talking to the player:** at most 2 at a time, the comer and one more; the arrival lines only from these.
- **All the others never stand facing the player** (at most a 2 s glance when you pass or shoot near them). They do something with where they are:
  - **at a machine:** watch it, react to its events (cheer, flinch, point, film it on the phone);
  - **at the bowling lane:** watch the rolls;
  - **at a bench:** sit and read the newspaper;
  - **at the fountain or pond:** look into the water;
  - **at the vehicles:** look them over, sit on the bike;
  - **at a path:** walk it.
- The chatter pairs talk to EACH OTHER, facing each other, not the player.
- Use the existing idles and watcher roles (`Watchers`, `LIFE_IDLE`); a spot with nothing to do gets the nearest activity.

## 4. Funnels that match the game now (owner: "Sæt funnels op så de passer til alt det nye så vi kan tracke vores data")
`Systems/Funnels.luau` still tracks the old first minutes (FirstTool, ThirdTool, Takedowns; a "Tutorial" funnel with Throw/Cannon/Wrecking/Maps). Rebuild it around the new first minutes (FTUE_10: bowling first, then free play). Server-side only, each step logged once and in order, from actions the server accepted, never in Studio.
- **Onboarding (new players):**
  1. Joined
  2. Loaded
  3. BowlingTry (TRY pressed at the lane)
  4. FirstStrike
  5. FirstShot (a weapon fired)
  6. FirstKO
  7. FirstXray (an X-ray seen: the 3-in-a-row or the toggle)
  8. SecondMachine (any machine but bowling)
  9. ThirdMachine
  10. FirstCare (CPR, a bandage or the tweezers)
  11. FiveMinutes
- **Custom funnels** (keep the count small; check the current Roblox limits in the LihFolk vault first):
  - **PlaytimeNew / PlaytimeAll and the device split:** keep;
  - **ShopVisit:** keep, plus a step "PassPrompt" for the vehicle passes (SOON bays excluded);
  - **Vehicles:** Seen bay → Sat on the free bike → Prompted a paid one → Bought;
  - **Multiplayer:** keep;
  - **retire "Tutorial" and "TakedownsNew"** (they measure the old game).
- **Custom events** (Metrics.event):
  - FirstUse per machine and animal: keep;
  - add "XrayToggle", "BodyCardHidden", "CPRDone" and "BowlingScore" (bucketed: 0-50, 51-100, 101+).
- **Test:** none in Studio (it does not log there). List the new funnel names in NOW.md, so the owner knows what to look at in the Creator Hub (Analytics, Funnels).

## 5. Bullet holes and the face ON the skin, never poking through (owner, screenshot: a purple disc half through a body: "Fiks så skudhuller ikke glitcher igennem sådan der, men de SKAL sidde på huden ikke udenpå, det samme gælder ansigtsudtryk skal sidde på ansigtet")
**The causes:**
- the holes, their stress rings and chips, and the purple wound discs are flat 3D parts (Cylinders, `BulletHoles.disc`) WELDED TO THE PHYSICS PART. The v6 mesh, though, is drawn from the bone chain every frame (the same wobble the round head had). A flat disc is also wider than the curve of a round limb, so its edges stick out or sink in;
- the face is a flat SurfaceGui on the round Ball head, so away from the centre it floats off the sphere or cuts into it.

**The fix:**
1. **No 3D discs on a body:** on a ragdoll the hole, the rim, the chip and the purple wound are ONE thin, small Decal-carrying part (at most 0.35 across on a limb, 0.45 on the torso), 0.005 off the skin. Rings and chips become part of the decal picture. The floor keeps its 3D splats and pools.
2. **On the visible skin:**
   - place the hole with a client raycast against an invisible HIT HULL that has exactly the v6 skin's shape: the 15 limb pieces from item 1, CanQuery on, invisible, made once per body and following the bones;
   - the hole sits at that hit point along the hull's normal;
   - one asset does both jobs: the X-ray glass and the hit placement.
3. **Following the mesh, not the physics:** holes (and bandages, plasters, the X-ray pieces) are anchored and moved every frame in `SmoothBody.drive` from their bone, with the offset stored in bone space when they are made. Use `workspace:BulkMoveTo` for all of a body's pieces at once; only bodies within ANIM_REACH; the hole caps per device stay (AUDIT 37).
4. **The face on the face:**
   - the round head becomes a sphere MeshPart (Blender, UV-mapped, the face area at the front) in the v6 grey;
   - the expressions (eyes, pupils, brows, mouth, blinks; FACES_V2 / FaceLife) are drawn as Decals on it, which follow the curve, layered and swapped per expression; no flat SurfaceGui on the head;
   - check the face from the side: nothing floats off or cuts into the head.
5. **The check (one Play look, close up):** shoot an arm, a leg and the chest 5 times each and walk round the body: every hole lies flat ON the skin, nothing pokes out or sinks in while it walks, falls or gets up. The face, seen from the front and the side, sits on the head.

## 6. The mouse "cannot move" near many things (owner, PC: "Man kan ikke bevæge musen i nærheden af mange af tingene fiks det")
Find the real cause with ONE Play (allowed for this item):
- walk the mouse player past 8 things: the cannon, bowling, the gyro, the shredder, the fan, a bench, the bikes and the fountain;
- at each, log `UserInputService.MouseBehavior`, `MouseIconEnabled`, `player.CameraMode`, `FirstPerson.isOn()`, the GuiObjects under the cursor (`PlayerGui:GetGuiObjectsAtPosition`: which are Active or Modal), the open ProximityPrompts and ControlsFX prompts, and the FPS.

**Likely causes, in order:**
1. something locks the mouse near a thing: an auto first person, or the crosshair hiding the cursor (`Crosshair.luau` 176) while the camera is locked;
2. a custom prompt or a ControlsFX / PromptGate panel that is Active (or Modal) sits under the cursor and eats the mouse, so the camera cannot turn and nothing can be clicked;
3. the frame rate falls near busy machines (effects, lights, many parts), so the mouse stutters.

**The fix:** near a thing, the mouse moves and turns the camera exactly as anywhere else. Prompts never cover the cursor's way: they are not Active except their own small button. No auto lock of the mouse. If it is the frame rate, fix that machine's cost (row 8, AUDIT 36-42).

## 7. The vehicles (owner, screenshot of the entrance row: "Fiks bilerne")
**What was wrong:**
- the 5 new kinds (go-kart, police car, monster truck, bulldozer, fire truck) had no `look`, so `VehicleService` gave each the default "Car" model, the white sedan, scaled to its length: five white sedans of different sizes, overlapping their bays;
- the SOON ones still said "Drive".

**Cloud code, done** (`Systems/VehicleService.luau`):
- the new kinds no longer get the sedan; they show their own part-built look (`decorate`) until a real model is set;
- a SOON vehicle's prompt says "Coming soon".

**Left for you:**
1. **A real model for each of the 5**, from the Creator Store, in ONE matching style with the Silvia, Ford and Panzer (malware pass; keep only the model; no scripts):
   - a go-kart (open, low, a roll bar);
   - a police car (light bar, POLICE livery);
   - a monster truck (huge wheels, a lifted body);
   - a bulldozer (a yellow body, a front blade, tracks);
   - a fire truck (red, a ladder, a hose).

   Add each to V3Assets and set `spec.look`. Size them to the avatar: a car door at the player's hip, the kart seat at knee height.
2. **The bays:**
   - each vehicle centred in its own painted bay, turned the same 45 degrees, with a clear gap (at least 1.5 studs) to the next one;
   - nothing overlaps, and no two noses touch;
   - re-measure the bay widths from the real models (`LabLayout10` ENTRANCE_ROW `w`).
3. **The SOON plaques:** one clean sign each at the bay's front edge, the same size, readable from the walkway: the name, "SOON", and the price once the pass exists.
4. **Check (one Play look from the walkway):** 9 different, real-looking vehicles in a neat herringbone row, nothing overlapping, nothing white-sedan.

## 8. The bicycle (owner, screenshot: the rider floats high over the bike, faces backwards, and it makes a car sound: "Man vender den forkerte vej på cykel og flyver over cyklen og den siger en billyd")
**Cloud code, done:**
- the bicycle model was turned 180 degrees from where it drives: `flip = true` on Bicycle (`Systems/VehicleService.luau`);
- no engine sound on the bicycle or the wheelchairs (`Client/VehicleFeel.luau`).

**Left for you:**
1. **The seat on the saddle:** the bicycle model has no seat part, so our VehicleSeat sits at a fixed spot over the box, high above the saddle. Find the saddle's top on the (flipped) look (the highest point of the look in its rear half, or the saddle mesh by name) and put the seat's top there, with SEAT_SINK, like the cars' `driverSpot`.
2. **The rider's pose** (BIKE_PEDAL, `Client/BikePedal`):
   - hips on the saddle;
   - both hands on the handlebar grips;
   - feet on the pedals, turning with them;
   - the body leaning a little forward;
   - not the car sit with the legs straight out (owner's screenshot).
3. **The wheels on the ground:** the look is scaled to `b.Z + 1.5` and sits `lift` under the box, and its wheels look half sunk into the grass. Scale it so its wheel radius is right (`spec.wheel / 2`) and its tyres touch the ground exactly.
4. **Its own sounds:** a soft tyre and chain whir that follows the speed, and the bell on the horn button. No engine.
5. **Check (one Play):** get on the bike: you face the handlebars, sit on the saddle, your feet pedal, it rides forward, the tyres roll on the grass, and it sounds like a bicycle.
