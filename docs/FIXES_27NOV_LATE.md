# FIXES 27 Nov late (owner, while testing): do these FIRST, in this order, as ONE batch where files overlap

## 0. Cloud code already written (push into Studio, ONE quick Play)
**DONE v1361:** all five files are in Studio (length check), one Play clean.
- **"." closes and opens the body card on a computer** (`Client/BodyCard.luau`, `Config.NO_EMOTE_MENU`): Roblox's emote wheel also uses ".", and it took the press, so it is turned off.
- **More room round the player** (`Config.MORE_ROOM`, `Systems/Lab.luau`, `Systems/RagdollDirector.luau`): the comer stops 9 studs away (not 5.5); within 45 studs at most 5 on a phone, 6 on a tablet and 8 on a PC (not 7, 9, 12).
- **The head no longer wobbles on the body** (`Client/SmoothBody.luau`): the round head was welded to the physics head, while the mesh's neck is drawn from the bone chain every frame. Now it is anchored and placed from the mesh's own Head bone in the same frame. Check that the face, the X-ray skull and the hats still follow it.

## 1. X-ray on one limb: NOT a cylinder (owner: "Fiks x-ray så det ikke bare er en cylinder")

**PART DONE v1365:** the glass sleeve (the cylinder, and the big one on the torso) is gone; only the bones show through the skin with the Highlight, 2 s plus a 1 s fade. The 15 pieces are BUILT (`mannequin_v6_xray.glb`, 348-2281 tris each, every bone group mapped); the upload was refused (folder not approved): owner step in NOW.md questions. LEFT: import, align to the template, hook into limbGlow and the hit hull.
Today A2 puts a pale capsule round the limb (on the torso a big glass box), which reads as a cylinder stuck on the body.
- **Make the glass the limb's OWN shape:** in Blender, split the approved v6 mesh at its joint planes (the same cuts the v6 build uses) into 15 closed pieces, one per R15 part (each piece = the faces whose strongest bone weight is that part), pushed out 0.015 along the normals. Export them as 15 plain MeshParts named after the parts (`art/models/mannequin/mannequin_v6_xray.fbx`; MCP upload, else ONE owner import step).
- **In the game:** on the limb hit 3 times in a row, the matching piece is shown welded to that physics part at its rest offset, in light-blue Glass at about 0.55 transparency, with a soft blue edge glow. The bones show through with the Highlight (AlwaysOnTop) as in A2. The timing stays: 2 s, then a 1 s fade.
- **Until the pieces exist:** NO sleeve and NO box at all; only the bones through the skin with the Highlight. Never a cylinder or a box.

## 2. CPR: the hands together (owner: "De samler ikke hænderne når de laver cpr")

**DONE v1365 (`CPR_HANDS_TOGETHER`):** the cause: the shoulder ball socket's 110-degree cone held the straight arms 1.97 studs apart. Now the cone opens to 155 for CPR/CPRFast only, and the arms cross in: the hands meet 0.20-0.27 apart on the chest middle, the left a little over the right (measured on the v6 rig). Not changed: CPROne (one hand on the forehead), CPRSlam, the player's own character.
- The medic's two hands are stacked on the centre of the patient's chest plate: one palm on the chest, the other on top of it, fingers interlaced (the v6 finger bones: a CPR grip pose in `HAND_POSES`), arms straight, the shoulders right over the hands.
- Each push goes down from the hips, and the hands stay together the whole time (an IK target on the chest point for both wrists, not two separate arm poses).
- The same goes for the player's own CPR game and for heroes giving CPR.

## 3. Only 1-2 talk to you; the rest do things with what they are at (owner: "de skal interagere med det de er ved, kun 1-2 står og snakker til brugeren")

**PART DONE v1366 (`TALK_TWO`):** at most 2 face and talk to a player (the comer plus one greeter; measured 1 in 25 s); the other Friendly ones stay where they are. The chat pair already faces each other. LEFT: the activity at each spot (bench paper, pond, bikes, cheering at machines) beyond the existing idles and watchers.
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

## 4. Funnels that match the game now
**DONE v1364:** Funnels rebuilt (onboarding 11 steps, Vehicles funnel, Tutorial and TakedownsNew retired, 4 new events), hooked in Bowling, PlayerCPR, VehicleService, SessionStats (X-ray and card through the Session remote). The names are in NOW.md. Not done: the ShopVisit PassPrompt step (the Vehicles funnel has it); "Seen bay" is "Pressed" (the server cannot see a prompt shown).
 (owner: "Sæt funnels op så de passer til alt det nye så vi kan tracke vores data")
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

**PART DONE v1372 (`HOLES_ON_SKIN`):** the hole was already one Decal-carrying part; the purple 3D discs poking through were the chip (BODY_HOLE colour) and the stress ring, both Cylinders welded to the limb: on a v6 body they are not made, the hole is capped at 0.35 (limb) / 0.45 (torso) and lies 0.005 off the BodyShape skin. LEFT: the hit hull and the bone-space follow (need the Blender pieces of item 1), the face as decals on a sphere mesh.
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

## 6. The mouse "cannot move" near many things
**DONE v1362 (`WORLD_GUI_PASS`, Client/WorldGuiPass):** the cause, found in one Play: 181 world GUIs (166 sign/label SurfaceGuis, the 9 ragdoll faces, the boards) were Active with no button, so they caught the mouse (no camera turn, lost clicks). The mouse was never locked; no screen panel covered it. Now every world GUI without a button is inactive (0 left). Owner check: on PC, turn the camera and shoot near the cannon, the boards and a ragdoll head.
 (owner, PC: "Man kan ikke bevæge musen i nærheden af mange af tingene fiks det")
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

## 9. Ragdolls carried into the tower (or any building or machine) are "sent to the top" (owner, screenshot inside the tower)
**The causes (both found in code, fixed by the cloud, `Config.GROUND_INSIDE_ONLY`):**
- `GroundGuard` counted ANY floor, stair or beam within 3 studs ABOVE a body as "buried in the ground" and lifted the body on top of it, every 2 s, storey by storey, up to the roof. It even did this to a body the player was CARRYING (it never checked `Held`). **Now:**
  - a carried body is never lifted;
  - a body counts as buried only when its middle is really inside a solid part (or terrain); a storey above is a ceiling.
- `Unstick` looked for a free spot by casting down from 30 studs up, which inside a building meets the roof first, so the "free spot" was on the top. **Now** it looks from just above the body first, on its own floor.

**Push into Studio** (`Systems/GroundGuard.luau`, `Systems/Unstick.luau`, `Shared/Config.luau`), then **check (one Play):**
- carry a ragdoll up the tower stairs and drop it on the DROP HERE ring inside: it stays there;
- the same at the shredder, the gyro cage and the stretcher.

**If something still blocks it:** look for an invisible collider (a belt wall, a NoGo box, a machine's guard part) in the way of the carried body, and give the carried body a collision group that passes the invisible guards, the same as the player.

## 10. Falls, collapses and get-ups at 10/10 (owner: "Sørg for de falder realistisk ved skud, ved blodmangel, rejser sig op, fejler, alt det skal være 10/10")

**PART DONE v1370 (`GETUP_FAIL`):** 10.4: a hurt ragdoll (hurt over 0.5 from Blood/Damage, or a broken leg) may fail a get-up: the arms shake and give while it pushes up and it slumps back, or it reaches the knee stage and falls again; at most 3 tries, then 8 s rest; two broken legs crawl (already). Not seen in Play (the test shove did not reach a body this screen simulates): owner check. Already there before: face-down kneel / face-up sit-up get-ups, the leg-round limp, the hurt sway. 10.2 DONE v1371 (`BLEED_STAGES`): sway (already) -> in the last 12 % of Blood before out cold it kneels with a hand down (mood Breath) -> at 45 % it passes out and tips over. LEFT: 10.1 hit-place reactions beyond today, 10.3 the side get-up and the dizzy hand, 10.5 landings.
Build on `RAGDOLL_FEEL.md` "The upgrade" and `RAGDOLL_10.md` R4. Finish what is not done; the v6 body and BodyShape are the base. The bar is the big games' "Euphoria" feel: a body REACTS with muscles, it does not just go limp or play a canned clip. Every case below:
- comes from the per-limb tone (a hit loosens only the struck chain) plus the balance and the protective reflexes;
- is eased, never a snap;
- shows on the face (BODY_V2 4b).

1. **Shot, by where and by what:**
   - a leg round: the knee buckles, it hops or limps, a grab at the leg; a second leg round: down on one knee, then the hands;
   - an arm round: the arm jerks back and hangs, the other hand grabs it, the body keeps standing;
   - the chest or belly: a step back from the push (the round's direction), a hunch, the hands to the wound;
   - the head: the head snaps back, and a heavy round knocks it out.

   **The fall** (when the damage says fall):
   - the knees go first, the body folds;
   - the arms reach out to break it (the protective reflex, toward the fall);
   - it keeps its speed into a roll or a slump;
   - never a stiff plank tipping over.
2. **Blood loss** (VitalsService "Bleeding", Blood falling):
   - **stages, slow and readable:** pale and slow → it sways, the steps go wobbly, a hand to the head → it sinks to its knees, one hand on the ground → it tips onto its side and lies still, breathing;
   - over 5-10 s, never a sudden drop;
   - the face goes pale, tired, eyes half shut.
3. **Getting up:**
   - chosen by how it lies: face down (push up, a knee under, kneel, stand), face up (sit up, roll to one side, kneel, stand), on its side (an elbow, a knee, stand);
   - every stage driven by the tones, so it looks heavy and real;
   - the feet planted where the body is, with no snapping into a pose;
   - 1-2 s of dizzy wobble after, a hand on the head.
4. **Failing to get up:**
   - when hurt (a broken leg, low Blood, just knocked out) the get-up FAILS:
     - it pushes up, the arms shake, and it slumps back;
     - or it gets to one knee, sways, and falls again;
     - or it gets up and stumbles 2-3 steps and drops;
   - it tries again after 2-4 s, with at most 3 tries; then it waits for help (CPR, a bandage) or rests longer;
   - a broken leg: it crawls instead (Crawling).
5. **Landing after a throw or a fall from height:**
   - the legs cycle in the air;
   - it lands on what hits first and keeps its speed: it slides or rolls, relaxes over 0.4 s, 1-2 twitches, then breathes.
6. **Never:**
   - a limb through the body or the floor;
   - jitter while lying;
   - a T-pose or snap;
   - a body standing up through another body or a wall.
7. **The check (the quality gate, a few Play looks allowed for THIS item):**
   - shoot a leg, an arm, the chest and the head of 4 ragdolls;
   - let one bleed out;
   - knock 3 down and watch them get up;
   - break a leg and watch it fail and crawl.

   Each must read like a real body at first sight; fix any that do not.

## 11. Vehicles never poke through things (owner, screenshot: the wheelchairs sunk into the grass: "Fiks så køretøjer ikke stikker igennem ting, fx kørestole igennem jorden")

**PART DONE v1369:** measured at rest: the bicycle and the wheelchairs stand on the ground (0.01-0.02); the real fault was HOME_CLEAR: its check box reached into the floor, so every home counted as blocked and only 1 of 13 ever moved (the Ford stood inside the Spawn11 statue, three trucks over the entrance plaque). Now only a part that reaches up into the vehicle box blocks, the search goes out to 60 studs and runs again at 20 s: 8 homes moved, no vehicle box inside anything. LEFT (owner check): the moved vehicles may stand off their painted bays; the physics box is not refitted to the look.
**Cloud code, done** (`VEHICLE_GROUNDED`, `Systems/VehicleService.luau`): `V3Assets.place` assumed every model's pivot is its bottom middle; the wheelchairs and the bicycle have it elsewhere, so they stood sunk in the ground. Now every look is measured and stands on its real lowest point on the ground.

**Left for you:**
1. **Push it into Studio, then one Play look at every vehicle at rest:** the 3 wheelchairs, the bicycle, the dirt bike, the Silvia, the Ford, the Panzer and the 5 new ones. The tyres, or the tank tracks, must touch the ground with nothing below it.
2. **While driving, nothing pokes through walls, props or bodies:**
   - the look does not collide; only the code box (`spec.body`) does;
   - so fit each kind's physics box to its look's real size (from the look's bounds, a little inside it), so it stops where it looks like it touches;
   - each wheel's radius from the look (the existing `Radius` attributes).
3. **Riding over kerbs and slopes:** no sinking into a ramp or a kerb; the wheels follow the ground (the screens' wheel welds).

## 12. The BOXING RING: drop one in, an opponent runs in, they fight to the end (owner, screenshot: two boxers in guard, apart, never hitting: "De slår ikke hinanden og gør så man bare skal tage 1 ragdoll derop og så kommer der en anden ragdoll løbende ind i ringen og så starter kampen og så slås de til døden")

**DONE v1368 (`BOXING_V2`):** drop one ragdoll on the canvas: it is RED; the champion or the nearest free ragdoll (120 studs) runs in as BLUE; the fight places them in guard 3.4 apart and steps in to 2.6 to punch (measured 3-5 studs apart in Play: punches land, stumbles, knockdowns with the count, get-ups), blocks, combos; not up by 10 = the final blow kills the loser (normal death); the winner cheers and stays as CHAMPION (streak on the canvas); a quiet background fight starts 8-15 s after joining (it takes about 25 s more for both to walk there). The START A FIGHT prompt is gone; pick-the-winner prompts for 5 s. LEFT (owner check): hook/uppercut poses and the faces were not added (the existing Box pose and Punch swing are used).
**Why they never hit** (`Systems/BoxingMatch.luau` ~216-250): a boxer "steps in" only by setting its `Home` 2.4 studs from the other, and a punch lands only within 4.6 studs. The walking rules then keep them apart:
- the personal-space push (`avoidDummies`, PERSONAL_SPACE 2.6 × 1.6 with NO_OVERLAP);
- PHYSICS_DEEP's arrive dead zone (once arrived, it stays until the goal moves more than 4 studs) and STATE_CALM (1.5 s least in Standing).

So they stand in guard about 6-8 studs apart, swing at the air, and nothing lands.

**The new flow** (replace the START A FIGHT prompt and the pick-time as the start; keep "pick the winner" as an optional prompt during the fight):
1. **You bring ONE ragdoll:** carry or throw a ragdoll into the ring (the ring is a drop zone with the DROP HERE sign, item 0/DROP_HERE_V2). It climbs to the RED corner and raises its fists.
2. **An opponent RUNS in:**
   - within 1 s, the nearest free ragdoll (within 120 studs, never one you are holding, never a hurt one) runs to the ring, vaults the ropes into the BLUE corner and taunts;
   - if none is free, one jogs in from the edge of the map (out of view).
3. **The bell:** "FIGHT!"; the crowd (watchers) gathers round the ropes.
4. **They really fight:**
   - while boxing, both are `InMachine = "Boxing"`: no personal-space push between them, no arrive dead zone, no roaming;
   - the fight drives their feet: they circle each other at 2.5-3.5 studs, step in to punch, and step back;
   - **punches:** jabs, hooks and an uppercut (`Poses.punch` sides plus new hook and uppercut poses), aimed at the head or body, about one every 0.6-1.2 s each, sometimes a 2-3 punch combo;
   - **a hit that lands** (the fist's path really reaches the other body, checked by distance at the punch's peak) does damage: the head snaps back, the body staggers a step (item 10's shot reactions), a "POW";
   - **blocks:** a guarded punch is blocked (gloves up, a thud, less damage);
   - **the face:** angry, hurt and dizzy as the damage grows.
5. **To the end:**
   - each knockdown, the referee counts; a hurt boxer may get up (the failed get-ups of item 10) and fight on, slower;
   - the fight ends when one is out cold and cannot get up; the winner gives the final blow, and the loser is DEAD (the game's normal death: CPR, REVIVE ALL and the doctor work on it as everywhere; gore stays off, purple blood).
6. **After:**
   - the winner celebrates (arms up, a bow, confetti, "RED WINS!" or "BLUE WINS!");
   - the winner stays as champion, so the next ragdoll you drop in fights the champion;
   - the ring's sign keeps the champion's win streak.
7. **Anyone near can pick the winner** during the first 5 s of the fight (free, no stake, as before; the streak stays).
8. **A background fight in the first 15 s** (owner: "indenfor de første 15 sekunder af man joiner så går der 2 ragdolls derop og starter en boksekamp, det er bare i baggrunden"):
   - 8-15 s after a player joins (once per visit), 2 free ragdolls walk up to the ring by themselves, climb in and start a fight (steps 3-6, the same fight);
   - it is pure background life: no camera move, no pop-up, no prompt in your face, no sound louder than the ambience at the spawn; it never interrupts the bowling hook (FTUE);
   - the ring sits where a new player can glance at it from the spawn area (if it is out of sight, the fight still runs: it is there when they walk past);
   - if the ring is busy (a player's fight), it is skipped.
9. **Check (a few Play looks allowed for this item):** drop one ragdoll in: an opponent runs in within 2 s, they fight close, punches land and show, knockdowns, the count, and it ends with one dead and the winner celebrating. Then drop another in against the champion.
