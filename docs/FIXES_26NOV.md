# Owner's fix list (26 Nov 2026, evening): do these FIRST in the next /klar, then continue the RUN ORDER
Owner's words (Danish, abridged): "Fiks følgende. Try skal kun vises 1 gang per maskine. Ragdolls laver den samme animation hver gang de bliver skudt … hænderne flyver bare hurtigt op i luften når man skyder dem i benene … Fjern den sorte skærm … hver eneste kugle i knoglerne med xray … de knækker lige hvor de bliver skudt/slået alt efter hvad våben. Fiks så talebobler ikke står inde i hovedet … telefon UI kun viser det nødvendige … pladen ved kanonen ikke launcher en, men ragdollen skal HELT ind i kanonen … ragdolls snakker om præcis det de kigger på … Hundeikonet skal kun være fremme når man er ved hundehuset … ikke en robothund men en schæferhund … Fiks det problem på computer som du ser på screenshot … Fiks multiplayer server, har skiftet til en gruppe."

## F1 TRY only once per machine
- After a machine is tried once, its TRY button and highlight never show again for that player. Save `Tried_<kind>` in the player's data, across visits, not only this visit.
- Only untried machines ever show TRY.

## F2 Hit reactions by where the hit lands (no more "arms fly up")
Today almost every hit plays the same reaction: the hands shoot up fast, even for a leg shot. Replace it with reactions chosen by the hit spot and the direction, all driven by the impulse at the hit point (`docs/RAGDOLL_FEEL.md` "PERFECT physics": ApplyImpulseAtPosition plus the per-limb tone drop).
- **Arms rise only for head and upper-chest hits** (a protective flinch), never for leg, hip, arm or back hits.

| Hit spot | Reaction |
|---|---|
| foot or shin | the leg kicks out, a hop on the other leg or the knee buckles, then a limp |
| thigh or knee | the knee buckles, the body dips to that side, a hand goes to the thigh |
| hip or belly | doubles over forward, a step back, both hands to the belly |
| chest | jolts back, a step back, the shoulders curl |
| back | arches forward, stumbles a step forward |
| arm or hand | that arm swings back with the shot and is clutched with the other hand; the rest of the body barely moves |
| shoulder | the torso twists round with the shot |
| head | snaps back; a strong shot drops it |
| from the side | the body turns away from the shot |

- **Variety:** at least 3 variants per spot, the strength scaled by weapon force, plus a random small extra (a step, a turn), so no two hits look the same. Never the same variant twice in a row on one body.
- Light weapons give small reactions; heavy ones knock down.

## F3 Remove the black screen
Sometimes the screen goes black when the player is pushed, knocked or ragdolled.
- **Find every source:**
  - a full-screen frame or fade on player knockback / PlayerRagdoll / WASTED-style screens;
  - ColorCorrection or Blur tweens to dark;
  - the camera going inside the player's own body or inside a wall (CameraOcclusionMode, camera subject swaps to a ragdoll part).
- **Remove the fades.** Keep the camera outside geometry (occlusion "Zoom"; keep the camera subject on the head or root and never on a part that goes inside walls). Never fade to black in play.

## F4 X-ray: every bullet visible in the bones, breaks exactly where hit
- **Lodged bullets:** every bullet that hits leaves a small metal slug (a grey-gold mesh, about 0.15 studs) stuck in the bone at the exact hit point, visible in X-ray.
  - Shotgun pellets: several small slugs.
  - Arrows: the tip in the bone.
  - Melee: a dent mark on the bone instead.
  - Max 15 slugs per body; they stay while the body lives and clear on a full heal.
- **The break is at the exact hit point** on that bone (not the middle). Its style is set by the weapon:

  | Weapon | Break |
  |---|---|
  | pistol | a crack line at the point (a break only at high force) |
  | rifle | a crack line, or a clean break at high force |
  | sniper / railgun | a clean snap right at the point, pieces offset |
  | shotgun | several small cracks round the point |
  | bat / hammer / fist | a crushed dent with radiating cracks, or a snap at high force |
  | blade | a thin notch |
  | explosion and falls | a break at the weakest middle of the nearest long bone |

- **Force rules:** as in `docs/BODY_V2.md` 1b.
- **Everything is shown inside the X-ray shell only.** Nothing pokes out.

## F5 Talk bubbles never inside the head
Bubbles sometimes sit inside the head, most likely when the ragdoll lies down or tilts: StudsOffset follows the head's rotation.
- **Fix:**
  - anchor bubbles in WORLD space (StudsOffsetWorldSpace, or an Attachment updated to the head position + world up);
  - put them above the highest point of the body (the head top + 1.5);
  - when the body lies down, lift the bubble above the body, not the head direction.
- Check it standing, lying, upside down, and in a machine.

## F6 Phone UI: only what is needed, clean
Audit the phone HUD on the iPhone landscape emulator. Keep only:
- the joystick, jump, SHOOT, the hotbar (max 4 slots shown);
- Shop and Menu on the left (Multiplayer inside Menu on phones, or as one small icon);
- the goal line (top centre);
- the gift clock;
- context buttons only while they apply: TRY near an untried machine, SLAM while holding, dog only at the doghouse, RELOAD only when low;
- X-RAY as one small toggle.

Everything else goes into Menu or is hidden on phones: key chips, help lines, F/V/Z chips, extra counters, badges.
- Nothing overlaps; there is a safe-area margin; consistent icon sizes.
- Take before and after screenshots.

## F7 Cannon: no launch plate; the ragdoll goes fully INSIDE
- Remove or disable the plate or pad in front of the cannon that launches whoever steps on it. Players walking there are never launched.
- The cannon fires only when a ragdoll is put **fully inside the barrel**: grab it, carry it to the muzzle, and let go into the glowing load spot. It slides in, then the cannon fires.
- No other trigger launches people by standing near the cannon.

## F8 Ragdolls talk about what they look at
Lines are chosen from what is in front of them. Max one line every 4 s per player, never repeated twice in a row.
- **Near a machine:**
  - cannon: "I'm NOT getting in that."
  - gyro cage: "That looks… dizzy."
  - fan: "My hair! My beautiful hair!"
  - press: "Flat is not a look."
  - washer: "Is that on the delicate cycle?"
  - shark tank: "Nice fishy. Good fishy."
  - T-rex: "Is that thing real?"
  - tower: "I'm scared of heights."
  - trampoline: "Wheee? No. No wheee."
- **The weapon the player holds:**
  - pistol: "Is that a toy?"
  - sniper: "Why is it so LONG?"
  - bow: "Robin Hood, is that you?"
  - shotgun: "Okay, that's a big one."
  - lasso: "Yeehaw? No thanks."
  - hammer: "Put the hammer down, buddy."
- **The dog nearby:** "Nice doggy…"
- **A grave nearby:** "Rest in peace, Gary."

About 6 lines per machine and per weapon class. Kept in `Shared/TalkLines` (fixed text, no free text).

## F9 Dog icon only at the doghouse
- The dog HUD icon shows only within about 15 studs of the doghouse; elsewhere it is hidden.
- The dog still follows when whistled. To send it home, walk back to the doghouse (or wait for its 3 minutes).

## F10 A German Shepherd, fully animated (no robot dog)
- Replace the robot dog with a **German Shepherd**: realistic proportions, tan and black coat, pointed ears. Use a rigged Creator Store model with animations (malware pass, scripts removed).
- **Animations:** idle (breathing, ear twitch, tail sway), walk, trot, run, sit, wag (tail plus the body wiggle), bark, the bite-and-tug (head shake), lie down.
- Use an AnimationController / Animator.
- **No sliding:** the walk and run speed match the move speed.

## F11 The PC left nav (owner's screenshot)
The left stack is broken:
- Shop sits outside the dark panel, offset from the others;
- More, Lab and Multiplayer sit in a panel;
- Multiplayer has no key chip;
- its icon (two emoji smileys) does not match the drawn style of the others.

**Fix:**
- one panel holding all 4 tiles, the same size and spacing;
- key chips on all 4 (Multiplayer gets one, e.g. "7" or "M" if free);
- a drawn two-people icon in the same style as the cart, gear and crate;
- check it on PC 1080p and 1440p, and on console.

## F12 Multiplayer place after the group move
**The owner moved the game to a group.** `Config.MULTI_PLACE = 81638873302354` and `START_PLACE = 126037745825106`.
- **If the experience was transferred:** the ids stay. Check that both places are listed under the group's experience in the Creator Hub.
- **If the multiplayer place is missing:** the owner adds a place and publishes the game to it (the owner's steps are in the chat reply, below). Then put the new place id in `Config.MULTI_PLACE`.
- **Every publish from now on publishes BOTH places** (start: Alt+P; multiplayer: Publish to Roblox As → the multiplayer place → Overwrite), or both through Open Cloud if the key has `universe-places:write` for the group's universe.
- **Server sizes (Creator Hub):** the start place 1; the multiplayer place 10.

## F13 REVIVE ALL instead of the Z chip (PC and tablet)
The bottom-left chip row (F run figure, V eye, Z clock) changes: the Z time-dial chip becomes **REVIVE ALL**.
- **Look:** a revive icon (a heart with a plus) in the same style.
- **Key:** R if it is free (the old HUD used R for Revive), else Z.
- **What it does:** it wakes every knocked-out ragdoll in your lab at once (the existing revive-all), with a short sparkle on each.
- **Tablets:** check which HUD they get (the phone or the PC layout). Show REVIVE ALL on tablets too: in the chip row if they use it, else as one small button.
- **Phones:** keep the existing small REVIVE (only when a ragdoll is down).
- **The time dial:** stays reachable from Menu.

## F14 Remove the white blob round shots
On PC, every shot shows a white blotch round the hit or the crosshair. Likely sources:
- the white "plink" flash or the white cartoon dust puff on hit;
- a white hit-marker image;
- a muzzle-flash billboard drawn white.

**Find it and remove it on ALL devices.** The hit feedback is the plastic chips, the grey dust and the purple splatter (`docs/BODY_V2.md` 2b and 3), plus a small thin crosshair hit-tick, never a white blob.

## F15 CPR faces the right way
- **The helper:**
  - kneels at the side of the knocked-out ragdoll, level with its chest;
  - its torso and face turn TOWARD the patient's chest;
  - its hands are on the chest centre.
- **Each compression:** before each compression, re-aim from the patient's current torso position and orientation (the body may have slid or turned).
- **Never** from behind or facing away.
- Check with the patient lying face up, face down (the helper rolls it over first, or does it from the side) and on a slope.

## F16 Hold-to-fire only for automatic weapons
- On phones (and the same rule on PC and console), holding SHOOT fires continuously ONLY with automatic weapons (SMG, minigun, Belt Buster, Drum Rattler, Auto Shotgun…).
- Semi-automatic weapons (Glock/pistol, revolver, sniper, shotgun, bow…) fire ONE shot per tap or click. Holding does nothing more.
- The fire rate cap stays per weapon.
- **The data:** put an `auto = true/false` field on every weapon in `Shared/Toys` and use it in the client fire loop. The server also refuses shots faster than the weapon's rate.

## F17 Remove the hint strip under the hotbar on phones
On phones a small dark strip under the weapons shows input hints (a mouse icon, a gun, a grab hand). Remove it on phones and tablets. PC may keep a slimmer version only if it helps.

## F18 Fewer ragdolls at the spawn (PC and all devices)
Too many ragdolls spawn right where the player spawns.
- **At the spawn:** only the 3 of the "3 near you" rule within about 25 studs (`docs/ALWAYS3.md`).
- **All other lab ragdolls start spread out:** at the machines as watchers, on walkways and on benches, never piled on the spawn.

## F19 Machine demos: once each, far apart, with REAL ragdolls
Today the attract mode sends test dummies flying out of machines in turn, often.
- **Each machine shows its demo ONCE per visit.**
- **Only one demo in the whole lab at a time, about every 45-60 s** (not every 2-3 s).
- **Real ragdolls, no extra test dummies:** the machine's watcher walks in, gets launched or spun, lands, and gets up again (with the normal ragdoll physics and impact effects). No extra demo dummies are spawned.
- **No demo** at a machine the player is using or standing at, and never during the first-2-minutes TRY lesson.

## F20 The bottom of the PC screen (owner's screenshot, 0.6x)
**What is wrong:**
- A dark bar runs across the WHOLE width of the bottom of the screen, behind the chip row (F run, V eye, X revive heart). The chip row's background frame is stretched to full width.
- Under the hotbar, the old input-hint strip is still there, but dim and almost empty (faded mouse and gun icons). It looks broken.

**Fix:**
- The chip row is a compact rounded pill sized to its chips (AutomaticSize X), bottom-left, with a safe-area margin. Nothing behind it across the screen.
- Remove the input-hint strip under the hotbar on ALL devices (PC too; this supersedes F17's "PC may keep it").
- Check at 1080p, 1440p and an ultrawide, and on console: nothing stretched, nothing empty.

## F21 A key for X-RAY, shown in the chip row
- X-RAY already has key I (Claude Code, 26 Nov). Add it to the chip row: `I` + an X-ray icon (a small skeleton in a blue glass outline). It lights up while X-ray is on.
- The keys in the row: F (run), V (eye), I (X-RAY), X (REVIVE ALL). If the owner wants X for X-ray later, swap them in one place (Config keybinds), not in many files.
- Console: a button for X-ray (D-pad left if free). Phone: the small X-RAY toggle button (F6).

## F22 The dog moves like a real dog and faces the right way when it bites (owner: "Hunden skal bevæge sig meget mere realistisk, modellen ser godt ud, hunden vender den forkerte vej når den bider en")
Keep the German Shepherd model. Fix the movement and the bite.

**Facing the bite (the bug).** The model's front is probably not its LookVector; the mesh or rig faces another axis.
- Find the model's real forward: the head direction.
- Add a fixed rotation offset in ONE place (e.g. `DOG_FORWARD_OFFSET`) used by every move, turn and bite.
- **When it bites:** the head and jaw point AT the bitten limb. The body lines up behind the head, along the line from the dog to the limb.
- **During the tug:** it keeps facing the limb, leaning back and pulling with its legs braced.

**Realistic movement:**
- **Real gaits:**
  - walk (4-beat, head bobbing);
  - trot (diagonal legs);
  - gallop (bounding, the back stretching);
  - the animation speed matched to the ground speed (no foot sliding).
- **Smooth speed changes:**
  - it accelerates and decelerates (no instant start or stop);
  - it turns in an arc with its body bending, never spinning on the spot.
- **Following:** it stays on your side, 4-6 studs back. It slows to a walk near you, stops and sits or stands when you stop, and looks up at you.
- **Head and ears:**
  - the head turns to look at what is near (ragdolls, you, noises) before the body turns;
  - the ears twitch;
  - the tail position shows its mood (up and wagging when happy, level when focused, low when coming back slowly).
- **The ground:**
  - its feet stay on the ground on slopes and steps (raycast foot or body height, tilt with the slope);
  - it jumps small obstacles and goes round big ones (PathfindingService, re-planned every 0.5 s);
  - it never walks through walls or ragdolls.
- **The run-up to a bite:** it fixes its eyes on the target, crouches a moment, sprints, slows in the last 2 studs, and bites from the right angle. Not a straight-line snap.
- **After the bite:**
  - it shakes its head with the limb for 2-3 s, then lets go;
  - it shakes its own body like a wet dog (fun detail);
  - it trots back wagging.
- **Idle at you:** it sniffs the ground, sits, scratches its ear, and lies down after 20 s of no action.
- **Sounds** fit each action: panting while running, a short bark, a growl before the bite, happy whines.
- **Check:** one quick Play. Follow, stop, turn sharply, go up stairs and a slope, then bite an arm, a leg and the bottom from different sides. The dog always faces the bitten limb, and its feet never slide.

## F23 Nicer shell casings (owner: "Gør patronerne flottere")
The ejected casings (since 0.43.1) look plain.

**Real meshes by weapon:**

| Weapon | Casing |
|---|---|
| pistol, SMG | a short straight brass casing (9 mm style) |
| revolver | no ejection: the casings drop out on reload, all at once |
| rifle, sniper, minigun | a longer bottleneck brass casing |
| shotgun | a red plastic shell with a brass base |
| bow, lasso, melee | none |

- **Detail:** a rim and a primer dot at the base, a darker open mouth.
- **Material:** polished brass (metal, a warm gold 200,160,70, with a little reflectance) so it glints in the sun. The shotgun shells are glossy red plastic.

**Ejection like a real gun:**
- out of the ejection port on the right side of the gun, up and to the right;
- spinning end over end, with a little random speed and angle;
- a thin wisp of smoke from the mouth for 0.3 s.
- In first person, clearly visible as it flies past the edge of the view.

**Landing:**
- it bounces 1-2 times (elasticity about 0.3) and rolls a little on hard floors, settling on its side;
- a high metallic "tink" on concrete and metal, a dull tick on grass and wood, never the same pitch twice;
- the shotgun shells land with a plastic clack.

**Clean-up:**
- casings stay 8 s, then fade;
- pooled;
- max 20 per player on PC and 8 on phones (the oldest goes first);
- no collisions with players;
- CastShadow on only for the nearest few.

**Check:** fire a pistol, a rifle and a shotgun in third and first person. Each casing looks different, glints, ejects to the right, bounces and tinks.

## F24 The washing machine: in and out through the front door (owner's screenshot: "Fiks vaskemaskinen så ragdollen kommer ind og ud det rigtige sted")
**What the screenshot shows** (the giant white front-loader next to the press):
- The round glass DOOR floats ABOVE the machine's top, tilted, not on the front porthole.
- A washing line with 4 towels (red, blue, yellow, green) hangs straight across the front of the porthole and blocks it.
- The load zone is a cyan dashed square on the floor under the machine, not at the door.

**Fix:**
- **The door:**
  - put it ON the front porthole: the same centre and size as the round opening, flush with the front face;
  - hinge it on the left side of the porthole (a HingeConstraint or a tweened CFrame round the hinge);
  - it opens outward about 100° and closes again.
- **The washing line:** move it to the side or behind the machine (or raise it well above the door), so nothing crosses the porthole.
- **IN:**
  1. The load spot is the open porthole: a soft glow ring on the door opening (F7 / `docs/FIRST_2_MIN.md` style), at its real height.
  2. When the player brings a ragdoll (or a TRY ragdoll walks up), the door swings open and the ragdoll is pulled IN through the porthole, head first, curling up into the drum.
  3. The door closes.
- **SPIN:** the drum turns with the ragdoll tumbling inside, clearly visible through the glass door, with suds and water (blue-white), the machine shaking and a washing sound. Calm, cartoon: no red water (gore is off); the water may get a light purple tint.
- **OUT:**
  1. The spin stops.
  2. The door swings open.
  3. The ragdoll slides OUT through the porthole onto the floor in front, dizzy (spiral eyes), soaked (a short drip effect), with a few soap bubbles floating up.
  4. It gets up dizzy and wobbles away.
  5. The door closes after 2 s.
- **Fit:** the ragdoll must fit the drum without poking through the machine walls. Shrink the ragdoll's collision inside the drum while it spins, or scale the drum, and keep it inside the glass.
- **Check:** load a ragdoll from the front and from the side. It always enters and leaves through the door. The door sits on the porthole, the line does not block it, and the tumbling shows through the glass.

## F25 No turning 3D pictures on the weapon bar (owner: "Fjern 3D roterende ikoner fra weaponsbar")
- **What it is:** `Client/PokeController.luau` `live3D()` (UI audit, 21 Nov) puts the held weapon's real 3D model on its slot, turning slowly (Ui3D), over its drawn picture.
- **Fix:** add `Config.BAR_LIVE3D = false`; `live3D` returns at once when it is false. The slots show only the flat drawn icons, the same style for every slot.
- **Remove anything already made:** any existing "Live3D" child goes on the next refresh.
- **Leave the rest alone:** the selected slot keeps its orange highlight and the ammo count. The shop and the catalog keep their 3D pictures.
- **Check:** select each weapon on PC and phone. Nothing turns on the bar.

## F26 The angry dummy shoves 1-3 times
- The angry dummy (`ANGRY_FIRST` / `ANGRY_SHOVE`, Mourning.provoke) shoves the player a random 1, 2 or 3 times, not once.
- Each shove gets a short wind-up and a step forward. If the player backs off, it follows a few steps.
- A different line before each shove: "Hey!", "Stop that!", "How do YOU like it?"
- Then it turns and flees as now.
- A hit on it during the shoves interrupts them.

## F27 Every bone can break, the belly too (the hit card says "Belly")
- **The skeleton has breakable bones in every body part.** That includes the torso: ribs (left and right, upper and lower), sternum, spine (upper, middle, lower vertebrae), pelvis and collarbones. Also the skull and jaw (a crack only on the skull, cartoon), and the hands and feet.
- **A hit on the belly** works on the lower ribs, the lower spine or the pelvis, whichever bone the bullet's path really reaches (F28).
- **Force rules:** the same as `docs/BODY_V2.md` 1b and F4.

## F28 X-ray: the bullet hits the bone where it really would, from where it was shot
**Today** a lodged slug or a break may sit at a fixed place on the bone.

**Fix:**
- **Model the bones as simple capsules** (one per bone, in the part's space, matching the X-ray skeleton mesh). On a hit, take the REAL shot ray (from the muzzle, in its direction) and cut it through the body part: the bullet meets the FIRST bone capsule on its path.
- **Where it ends up:**
  - **it hits a bone:** the slug lodges at that exact point on the bone's surface, entering from the shot's side, and the crack or break starts there;
  - **it passes no bone** (a shot through the side of the belly): the slug lodges in the shell along the path, or goes out the far side for strong guns (an exit hole), and no bone is hurt;
  - **strong guns** (sniper, railgun, rifle) go through the first bone and can hit a second one behind it (ribs then spine).
- **In X-ray, a short bright tracer line** shows the bullet's path through the glass body for 1 s after each hit, so you see it go from where you shot to the bone.
- **Melee:** the same with the weapon's contact point and swing direction. Blunt weapons dent and crack the nearest bone under the contact point.

## F29 Shoot and smash bones to pieces
- **A bone has stages:** whole → cracked → broken (2 pieces) → **shattered** (4-6 pieces).
- **More hits or more force move it on:**
  - shots at a broken bone shatter it;
  - a charged hammer or a point-blank shotgun can shatter in one hit;
  - each new bullet adds pieces where it lands.
- **The pieces** stay loose inside the X-ray glass shell of that limb: they rattle, follow gravity a little, and never leave the shell (constrained inside). White bone chips with jagged cartoon edges.
- **Outside X-ray:** a shattered limb is fully limp, the ragdoll cannot use it, and it holds or drags it.
- **Healing:** a bandage, sling or splint, or a full heal, puts the bone back whole.
- **Maturity (honest):** cartoon X-ray bones breaking and shattering inside a see-through body, no exposed bones, no blood from it. Update the answer in `docs/MATURITY.md`.
- **Caps:** max 40 bone pieces per body; phones 20 (the smallest merge).

## F30 Every lab is singleplayer; the multiplayer place has ONE lab with everyone (owner, 26 Nov late)
> "Fiks så at alle labs er singleplayer så man skal ikke kunne se andre, multiplayer versionen åbner et lab med alle i."

**Start place (126037745825106): solo.**
- A player never sees other players or other labs.
- **Server size 1:** after the move to the group, the owner sets it in the Creator Hub (Places → the start place → Settings → server size 1). Tell the owner in the final message.
- **Safety net in code** (if a server ever holds 2+ players, e.g. a friend joins):
  - each client hides the other labs (do not stream or show them; parent them out locally);
  - hide the other players' characters, name tags, ragdolls, effects and sounds;
  - the server never builds two labs next to each other in view (plots stay 1100+ apart), and no shared plaza is shown in the solo place.
- **Joining a friend in the start place:** the friend is taken to the MULTIPLAYER place instead (PLAY WITH FRIENDS), not into a solo server.

**Multiplayer place (`Config.MULTI_PLACE`):**
- ONE shared lab for everyone on the server (the existing "shared lab": no own labs built);
- everyone spawns in it and sees everyone;
- the server size is set in the Creator Hub (10);
- the same new big map (`LAB_OWNERMAP`) is used there too.

**Check:**
- 2 test clients in the start place: they do not see each other or each other's labs.
- 2 test clients in the multiplayer place: one lab, both see each other.

## F31 Machine demos must not happen "out of the blue": a ragdoll walks there and climbs in (owner, 26 Nov 2026: "Gør så test ikke bare sker ud af det blå, men der en ragdoll der løber derhen og går ind i fælden så man ikke tror det er en bug")
**Today (F19, `DEMO_REAL`, Systems/MachineDemos):** a real lab ragdoll is SET at a machine and thrown at once. To the player it looks like a body appearing and flying for no reason, like a bug.

**Fix: the demo is a little story you can follow:**
1. **The pick:** a free ragdoll that is visible to the player, or that can walk into view, is picked. Never one teleported into place; never one the player cannot see start.
2. **On its way:** it says one line as it sets off ("I wonder what this does…", "Hold my juice.", "Science!", "Watch this!", "Don't tell my mum."); it looks at the machine (`LOOK AT YOU` style, at the machine); it walks or jogs there on a pathfinding route (pace by distance, max about 12 s).
3. **The watchers notice:** they turn, point at it, and one says "Oh no, he's doing it again."
4. **Into the trap, the way a person would:**
   - it climbs the steps;
   - it crawls into the cannon's muzzle;
   - it opens the washer door and climbs in;
   - it lies down on the press bed;
   - it sits on the rocket seat and buckles up;
   - it steps into the gyro cage, and the straps close;
   - it walks onto the fan's pad and leans into the wind;
   - it walks to the plank end on the tower;
   - and so on for every machine. Use the machine's real load spot (`FIRST_2_MIN.md` per-machine load spots).

   A short animation of 1-2 s, with a little hesitation (looks down, shrugs, goes).
5. **Then the machine runs** with its full show (`MACHINES_10.md`). The ragdoll lands, gets up dizzy, and sometimes says "Again!" or "Never again."

**Rules:**
- only when the player is within about 80 studs and can see the machine (otherwise skip it; no off-screen demos);
- one demo at a time in the lab, about every 45-60 s, each machine once per visit (as F19);
- never during the TRY lesson or while the player uses that machine;
- if the walker is knocked or grabbed on the way, the demo is cancelled quietly.

**The same rule for EVERY automatic event that moves a ragdoll** (surprises, the train, the T-rex gate, the whale spout):
- a visible cause first (someone walks there, a warning, a countdown);
- never a body that suddenly flies.

**Check:** stand near 3 machines for 3 minutes. Every demo starts with a ragdoll you see walking there and climbing in; nothing flies without a reason.

## Answers to Claude Code's questions (owner direction or safe default)
- **X-RAY key:** I is fine (B is Build). Phone: a small X-RAY toggle button.
- **The big map (step 7):** YES, do it now.
- **The robot dog:** NO. A German Shepherd (F10).
- **Wheelchair:** yes, get one from the Creator Store (malware pass).
- **The long goal after all weapons:** ranks with prizes first (the simplest for kids); collections and upgrades later.

## State (Claude Code)
- 0.70.0 (place v1126): F1 done (Tried_<kind> saved as eco counts "T_<kind>", read back on join, no reward again). F5 done (bubble and line above the body's highest point in world space, bottom edge on it). F7 done (`CANNON_MUZZLE_LOAD`: pad invisible and never launches players; a ragdoll let go within 4 s at the glowing "DROP A RAGDOLL HERE" spot under the muzzle slides in and fires; the nearest player gets Tried_Cannon). F9 done (dog button only within 15 studs of a doghouse, CollectionService tag "Doghouse"). Also: IMPACT_FX smoke trail (`FLIGHT_TRAIL`, Client/FlightTrail).
- 0.71.0 (place v1127): F3 done (`NO_BLACK_SCREEN`, Client/NoBlackScreen: while your own body is loose the camera is held in third person at 9 studs on the head, then put back; WASTED no longer darkens). F8 done (`TALK_CONTEXT`, Shared/TalkLines: machine, weapon, dog and grave lines, 6 each; one every 4 s, never twice in a row; picked in DummyLife.updateLine). No gyro cage or T-rex exists in the lab, so they have no lines yet.
- Place v1128: F11 done (HudV3: the dock is sized for 4 squares when MP_ICON, so Shop sits inside; key chips on all 4, Multiplayer = 0 (Keybinds MultiWindow); a drawn two-people icon built from frames replaces the emoji picture). Checked in Studio with the PC dock shown; 1440p and console not checked (the dock scales with HudV3 UIScale).
- 0.72.0 (place v1129): F6 done (`PHONE_CLEAN`, Client/PhoneClean: on touch no hotbar key chips or slot numbers, no BodyCardArrow, no FirstPersonTouch; TouchShoot shows RELOAD only at 30% of the clip or less). Before/after: Studio captures ScreenCapture_F6a / F6b (iPhone landscape, DevTouch). Left: Shop, Multiplayer, Menu (+ REVIVE as a context button); right: X-RAY, SHOOT, jump; top: goal line, gift.
- 0.73.0: F2 done (`HIT_REACT_V2`: Poses.spotOf + Poses.hitReact, 9 spots x 3 variants, scaled by force 0.6-3, arms up only for head v2 and chest v3; ActiveRagdoll.hit picks spot/variant (never the same twice), shotReaction adds a random trunk turn and a forward step for back hits). NOTE: from here Studio has the file open as the MULTIPLAYER place (81638873302354): saves went to it (v48). The start place (126037745825106) was last saved at v1129 (0.72.0).
- 0.74.0 (multiplayer place v49): F4 part 1 (`XRAY_SLUGS`: a slug per BulletHole in the X-ray bone at its exact spot, max 15 a limb; hole Scale 1.35+ adds a crack line there, 1.6+ a snap with two lines; BulletHoles stores Scale). Left: shotgun pellet clusters, arrow tips and melee dents (blows leave no hole), breaks by weapon type beyond the force scale. F12: both places are in universe 10774775314 (Studio shows the multiplayer place there), so the ids in Config stay; teleport not testable in Studio. F10 (German Shepherd) next.
- Multiplayer place v50: F10 part 1: ServerStorage.V3Assets.GermanShepherd (Creator Store "K9" 16561332423 by Jvmezz10: only its Dog mesh and collar kept, 13 scripts, guis, remotes and the R15 rig removed; pivot faces the head). GuardDog uses it (robot dog only as fallback); code motion: trot bob and rock, a faster run, breathing and a body wiggle when standing, the existing bite head-shake. No free rigged German Shepherd was found (the K9 mesh is one rigid mesh), so no leg animation yet: question for the owner.
- 0.75.0 (multiplayer place v51): F13 (`REVIVE_CHIP`: the time chip is REVIVE ALL with a heart, on the existing ReviveAll key X since R/Z are taken, a click works; tablets get it when they use the PC HUD, phones keep their small REVIVE). F14 (`NO_WHITE_HIT`: no white-yellow puff and no white body flash on hits; grey dust instead). F15 (`CPR_FACE`: the helper kneels at the chest side facing it and re-aims at the chest before every compression round). F16 (TouchShoot: holding SHOOT repeats only for `auto` weapons; PC already did; the server keeps the per-weapon rate).
- 0.76.0 (multiplayer place v52): F17+F20 (`HINT_STRIP = false`: no hint strip under the hotbar anywhere; the full-width bar was the F13 REVIVE click area, a scale-sized child of the auto-sized chip row: now on the fixed key square; row measured 254 px in a 750 px window). F21 (`XRAY_CHIP`: chip "I X-ray", Keybinds XRay = I (change it there only), lit blue while on, click toggles, D-pad left on a pad). No drawn skeleton icon exists yet: the chip shows the word.
- 0.77.0 (multiplayer place v53): F18 (`SPAWN_FEW`: Lab.PLAZA_SLOTS 3, so 3 ragdolls near the spawn, measured 3 within 25 studs; the rest roam out). F19 (`ATTRACT_MODE` off, `DEMO_REAL` on, Systems/MachineDemos: every 45-60 s (first at 50 s) the nearest free real lab ragdoll is set at one machine and thrown with its arc/spin/drop/lift, each machine once a visit, never within 14 studs of you, during a TRY (TryFor) or a surprise). Machine watchers (step 1) still not built.
- Multiplayer place v54: F22 part 1: the model faced backwards (head opposite its LookVector): template attribute ForwardYaw = pi, every placement goes through GuardDog place(). Heading turns at 5 rad/s (arcs), speed eases (ACCEL/BRAKE), gait by speed with the beat from the distance (walk bob, trot, gallop bound), slope tilt, follows on your right ~5 back, looks at you, sits after 6 s, lies after 20 s; bite: crouch, sprint, slow in, stops with the head on the limb facing it, tug + head shake, then a wet-dog shake. Checked: following, head toward the player (dot 1.00). Left: pathfinding round walls, sounds (bark/growl/pant), head-turn before body, ear/tail (one rigid mesh).
