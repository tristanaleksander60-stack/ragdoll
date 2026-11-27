# BUTTONS, LEVERS and the CANNON LOADER at 10/10 (owner, 27 Nov 2026)
> "Fiks kanonkuglen hvor man skal ligge en ragdoll, og gør kvalitet af røde knapper og levers osv meget bedre så man faktisk kan se hvad det er, sørg for at lave alt teknisk smartest der som de helt store spil"

## 1. The CANNON LOADER (replaces F7's glowing disc)
**Today** (`Playground.luau` ~259-340): a flat, half-transparent orange NEON DISC under the muzzle with a floating "DROP A RAGDOLL HERE" billboard. It looks like a glowing cannonball or a puddle, it reads as nothing, and you must let go of the ragdoll exactly on it.

**New: a real LOADING HOPPER on the cannon** (`Config.CANNON_HOPPER = true`):
- **The model** (Blender, CREATURES_ANIM 4 style):
  - a big round metal FUNNEL (about 6 wide at the top) on the back of the cannon, with a yellow-black hazard rim and a short chute into the breech;
  - a painted down-arrow inside, and a small ragdoll pictogram plate on its side;
  - no floating text (the pictogram says it).
- **Loading is easy:**
  - drop, throw or carry a ragdoll ANYWHERE into the funnel: a generous trigger volume fills the funnel;
  - the ragdoll slides down the chute with a "whoosh" (a short guided slide), the barrel clunks shut, the fuse lights, 3-2-1, BOOM (MACHINES_10 3.1);
  - TRY (F81): the ragdoll runs up the steps beside the hopper and jumps in;
  - players can never be loaded or fired (characters are filtered out);
  - while a ragdoll is inside, the funnel shows a red "busy" light and a second one waits on the rim.
- **Feedback:** the funnel rim glows soft yellow while you carry a ragdoll near it (within 20 studs), so you know where it goes; nothing glows otherwise.
- **The cannon model:** the CREATURES_ANIM 4 look (a dark iron barrel with brass bands on a wooden carriage); the hopper is part of the same Blender model.

## 2. ONE kit for every BUTTON, LEVER, CRANK and DIAL (how the big games do it)
**Today:** every machine builds its own red button or lever from plain parts (a red cylinder, a grey box), with different sizes, colours and prompts. Players cannot tell a button from a pole, and nothing shows if it is ready, busy or locked.

**The kit** (`Shared/Controls.luau` + `Client/ControlsFX.luau`, `Config.CONTROLS_V2 = true`):
1. **Four Blender models, made once, reused everywhere** (as packages, the clean toy style, baked AO):
   - **BIG RED BUTTON:** a glossy red mushroom cap on a black-and-yellow hazard base with a chrome collar, about 2.2 wide, on a short post at hand height. A pictogram plate under it shows what it does (a cannon, a spin, a fan, a bolt, a ragdoll…);
   - **LEVER:** a metal box with a chunky handle and a red ball knob, and an ON/OFF arc plate (green and red);
   - **CRANK WHEEL:** a spoked wheel on a gearbox;
   - **DIAL:** a round dial with 3 settings (slow, normal, fast), for the sweeper, the fan and the washer.
2. **Tags, not code per machine:**
   - each control is tagged (`CollectionService` "Control") with attributes `Kind` (Button/Lever/Crank/Dial), `Machine`, `Action` and `Icon`;
   - the machine's code only listens to "this control was used", so a new machine needs no new control code.
3. **Instant feedback (client prediction):** on press, YOUR screen moves the button at once:
   - it sinks 0.15 studs with a squash;
   - a light flash and a chunky CLICK (a lever: a clunk, a throw with a spring overshoot; a crank: it turns while held);
   - the server then validates (reach, cooldown, owner or plot, pass) and runs the machine;
   - if it refuses, the button pops back with a "nope" buzz.
4. **The state is always visible, in shape and light, not only colour:**
   - **READY:** a soft slow pulse of the cap's light;
   - **COOLING:** the cap dims, and a ring of light round the collar fills up as it recharges;
   - **BUSY:** the lever is down and the light is red;
   - **LOCKED:** grey with a small lock plate (for example a pass needed: the Lab Controls BIG BUTTON for its buyers, AUDIT 1).
5. **Prompts:**
   - ONE custom prompt style (`ProximityPrompt.Style = Custom`, drawn by `ControlsFX`): a big round icon of the action with a hold ring where a hold is needed, the word under it ("FIRE", "SPIN", "BOWL");
   - on phones a large tap target (at least 72 px), never key letters (F70);
   - only the nearest control shows its prompt;
   - `RequiresLineOfSight` off, a sensible reach (12 studs).
6. **Cheap:**
   - every movement is a local tween on the client; the server moves no parts, it only sets the state attributes (`Ready`, `CoolUntil`, `Busy`, `Locked`);
   - sounds pooled; lights only within 80 studs;
   - the models are shared, about 600-1,200 triangles each.
7. **Replace ALL of them** in one pass:
   - the cannon (fire), the gyro cage ("Spin!"), the shredder ("Shred!");
   - the stretcher (green, red and the 4 claw buttons → one lever plus a crank);
   - the bowling lever, the sweeper speed dial, the tesla coil button, the press, the washer dial, the fan;
   - the events' red button, the Lab Controls BIG BUTTON (pass owners only), the launch pads (a lever per pad);
   - and any other `ProximityPrompt` on a machine (grep: about 39 in Systems).

   Remove the old part-built ones.
8. **The TRY button (F81) and the controls work together:** after a TRY show, the machine's control glows once ("Again? Press it!", FTUE fix 8).

## Order
In PHASE 6 (machines), right before row 3's remaining items: first the kit (2), then the cannon hopper (1) as its first user, then every machine's control.

## Check (the owner, phone first)
- **The cannon:** throw a ragdoll into the funnel; it slides in, 3-2-1, BOOM.
- **Every red button looks like a real big red button,** and every lever like a lever. They move at once when you press, show when they are recharging or locked, and the prompt shows a clear icon.
