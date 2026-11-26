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

## F32 Ragdolls stuck in the tree belts and walls
Ragdolls get stuck inside the tree belts and the walls (the owner saw it).
- **The belts and walls block them for real:** each tree belt gets an invisible solid wall volume (CanCollide on for ragdolls, CanQuery off) along its length, so no ragdoll walks or is thrown deep into it. The pathfinding marks it as a no-go area (`ALWAYS3.md` "never walk INTO things").
- **Unstick:**
  - any ragdoll whose root is inside a belt, wall, rock or building volume for more than 1 s is moved out to the nearest free walkable point (a short slide or step, not a pop), standing;
  - a thrown or knocked body that lands inside a belt is pushed out to the room side when it gets up.
- **Spawns, recruits and walker targets** are never inside or right next to a belt or wall (2 studs clearance).

## F33 The aquarium sticks half into a wall
The owner's screenshot shows the glass aquarium intersecting a wall or building edge.
- **Move it** to its `OwnerMapPlan` spot with at least 6 studs clear on every side.
- **Lint:** extend the map lint to report any attraction whose bounding box intersects a wall, a building, a belt, a path or another attraction. The report must be 0.

## F34 A REAL T-rex (today it is a green leafy block "bush")
- **Replace** the leaf-textured block dinosaur with a real T-rex model: a rigged mesh with skin detail (scales), stylised-realistic, from the Creator Store, with many favourites (malware pass, scripts removed).
- **Animations:**
  - idle breathing (the chest moves);
  - head turns tracking ragdolls and players nearby;
  - tail sway;
  - a blink;
  - a walk round its pen (footstep booms, a small camera shake near it);
  - the ROAR (a mouth wide open, a head toss, a shock ring);
  - the bite-and-toss (`MACHINES_10.md` 3.29).
- **Scale:** about 25-30 studs tall; it must fit the pen.

## F35 The ENTRANCES of attractions must be exciting (not a grey wall with 2 lamps)
The T-rex pen's entrance is a plain grey concrete wall with 2 lamp posts and a small "T-REX" plate. Every attraction entrance gets the `SPAWN_11.md` gate treatment, sized to the attraction. The T-rex pen gets:
- a huge timber gate in a steel frame (Jurassic-style but our own design);
- warning lights;
- a big "T-REX" sign in 3D letters with claw marks;
- a viewing platform with a railing to look over the wall;
- deep scratches on the gate;
- the gate shudders when the T-rex bumps it from inside (every 20-40 s, a boom), so you want to look.

The bear cave, the crocodile pond, the aquarium, the pool, the spider pen and the danger zone pieces all get a fitting entrance or front: a sign, a frame, something moving.

## F36 The BEAR: alive, and no black slab
- **The black plate:** the cave's mouth is a flat black slab or wall. Replace it with a real cave entrance: depth into the rock, a dark interior that fades, rocks and roots round the mouth, and a soft eye-glint in the dark.
- **The bear today stands still.** It needs a rigged bear model (if the current one is a single mesh, replace it; Creator Store, malware pass) with animations:
  - idle breathing;
  - sniffing the air;
  - scratching against a tree;
  - walking round its yard;
  - sitting;
  - lying down and sleeping;
  - standing up on its hind legs to roar.
- **It reacts:**
  - it looks at ragdolls and players nearby;
  - it wakes on noise (shots nearby);
  - the cave interaction in `MACHINES_10.md` 3.27 (it swats a ragdoll thrown in, or gives a bear hug).

## F37 A cyclist and bikes you notice early (owner: "Gør så man ser en cykler ret hurtigt på fortovet, så man finder et transportmiddel, hvis man ikke ville gå")
- **The cyclist** (`LIFE_IDLE.md` 2):
  - in the first 20-30 s of every visit, a cyclist rides past the spawn on the walkway at the foot of the plaza stair;
  - it rings its bell, waves at the player, and parks at a BIKE RACK right there;
  - then it walks off.
- **The bike rack** by the plaza stair holds 3-4 free bicycles (and 2 scooters if a good model exists):
  - a big "RIDE" prompt (E / tap);
  - riding is calm, fast enough to cross the map (about 40 studs/s);
  - easy on phones;
  - get off with jump or a button; the bike stays where you leave it and returns to the rack after 60 s unused.
- **More racks:** at every room gate and at the station, so bikes are always near.
- **A first-visit hint, shown once:** a small pointing hand at the rack, "Ride a bike!".

## F38 Walking speed in Settings (owner: "gør så man kan adjust speed i sine settings")
- **The slider:** Settings gets a "Walk speed" slider from 16 to 40, default 28 (`LAB_TARGET` RUN FASTER), saved per player.
- **SPRINT:** it stays at the slider value x1.5 (max 60), with an on/off toggle for the sprint button on phones.
- **Phone:** the slider is big and easy (or 3 buttons: Normal / Fast / Very fast).
- **Server:** it checks the value (clamped to 16-40, sprint max 60); the anti-cheat speed checks follow the player's setting.

## F39 Every SIGN redesigned (owner: "Skiltene ligner AI slop, og grenen splitter teksten")
**The owner's picture:** the "ANIMAL COVE" sign is a flat black board with plain white text, and its single post runs up THROUGH the middle of the text, splitting it.

**Rules for every sign in the lab** (room signs, attraction signs, signposts, the MAPS frame, the plates):
- **No post or part ever crosses the text or the pictogram.** Use 2 posts at the sides, a hanging sign on chains from a beam, or a wall-mounted board. Check the text area is clear from the front (a raycast grid over the text area must hit only the board).
- **A real sign, not a flat rectangle:**
  - a framed board with depth (a border frame, rounded or chamfered corners, bolts or nails at the corners);
  - its material fits the place (painted timber for Animal Cove and Picnic Park; riveted steel for the Machine Hall and Crash Yard; hazard-striped metal for the Danger Zone; tiled or enamel for the Splash Zone; a carnival board with bulbs for the Fun Fair);
  - a slight weathering decal (scratches, a little dirt).
- **The text:**
  - big, chunky, rounded letters (one display font for the whole game, readable on a phone from 30+ studs);
  - a coloured fill with a dark outline and a small drop shadow, or real 3D letters on the bigger signs (`SPAWN_11.md` gates);
  - the room's pictogram next to the name (bear paw, wave, crashed car, gear, balloon, rocket, warning);
  - never stretched, cut off or touching the frame edge.
- **Colour:** each room has its colour (the same one the wayfinding signpost uses), so signs read as one designed system.
- **Fixing:** SurfaceGui with LightInfluence 0, PixelsPerStud high enough to be crisp, no flicker or z-fighting with the board (offset 0.05); the back side is a plain board, or has the same face (no mirrored text).
- **Check:** capture every sign from the front on PC and phone. No crossings, nothing cut or blurry, and each one fits its room. Harsh score 9.5+.

## F40 No lamp posts in the middle of paths
The owner still sees lamp posts standing in the middle of walkways.
- **Where lamps may stand:** only beside a walkway or road, 2 studs OUTSIDE its kerb, never on any walkable surface.
- **The check covers EVERY walkable surface:** the roads, the boulevard, the spurs, ALL inner paths (also where several merge), the junction plazas, the courtyards, the spawn plaza, the Tower Square, the station platform and the bike racks' pads.
- **The lint must report 0 lamps on walkable surfaces;** any lamp that fails is moved to the nearest legal spot beside the path, or removed.
- **Also check** bins, signposts, benches, trees and flower beds against the same surfaces.

## F41 No white blobs round the bullet holes
**The owner's picture:** every hole on the dummy has big pale or white see-through discs round it (several overlapping), plus a purple dot. It looks like white stickers. The "stress-whitened ring" (`BODY_V2.md` 3) and/or a white hit decal is drawn as large translucent white circles.

**Fix:**
- **Remove every white or pale disc round the holes:** no stress-whitening ring and no white or translucent circle decals.
- **A hole is only:**
  - the dark centre with depth;
  - a thin rim of slightly darker grey plastic (tight to the hole, at most 1.3x the hole's size);
  - 3-6 thin hairline cracks;
  - the small purple glint inside.
- **Check old leftovers:** no old hit-flash decals that never fade (F14).
- **Check:** shoot a dummy 20 times with different guns, close up, on PC and phone. No white or pale circles anywhere on the body.

## F42 An X-RAY button with its key on PC (owner: "Tilføj X-ray keybind-knap på computer")
- **On PC (and tablets with the PC HUD):** a clear round **X-RAY button**, the same style as the phone's round X-RAY button.
  - It sits on the right side of the screen above the hotbar's right end.
  - It has a key chip "I" in its corner.
  - It lights up blue while X-ray is on.
  - A click toggles it; key I toggles it.
- **The bottom-left chip "I X-ray" (F21) stays** if there is room. Otherwise the round button replaces it.
- **Settings:** the X-RAY key can be rebound in Settings → Controls (`Keybinds`, one place).
- **Console:** D-pad left, shown on the button as the controller glyph.
- **Check:** PC at 1080p and 1440p. The button is visible, readable and not covering anything. Key I and a click both work.

## F43 X-ray bullets look like REAL BULLETS pointing the way they went in (not peas)
**Today:** the lodged slug in the bone is a small round ball, like a pea.

**Fix (`XRAY_SLUGS` look):**
- **A real bullet mesh:**
  - a cylinder body with a pointed or rounded ogive nose and a flat base;
  - a copper jacket (warm copper-brass, slightly shiny), with a little darker base ring.
  - Make it as a small MeshPart, or 2-3 parts welded as one; it is shared, so it is instanced.
- **Aligned with the shot:** the bullet's long axis lies along the real shot ray (F28). The NOSE points INTO the bone in the direction the bullet travelled. The base faces back toward the shooter.
- **Embedded:** about 60 % inside the bone (the nose in, the tail sticking out). Never floating beside the bone or fully hidden in it.
- **By weapon:**

  | Weapon | Bullet |
  |---|---|
  | pistol / SMG | short, about 0.3 studs long |
  | rifle | longer and slimmer, about 0.45 |
  | sniper / railgun | the longest, about 0.6 (it often passes through: a slug only in the last bone it stopped in, plus a clean tunnel mark in the first) |
  | shotgun | small round pellets: the only round ones, a cluster of 3-6 |
  | bow | the arrowhead (a steel broadhead) with a short broken shaft end |
  | revolver | a flat-nosed big slug |

- **High force:** a pistol bullet at high force (point-blank) shows slightly mushroomed: a flattened nose, the tip squashed.
- **A short dark crack line** starts at the entry point on the bone (as F4).
- **Check:** in X-ray, shoot a dummy from the front, the side, from above and at an angle. Every bullet points along the line it was fired and sits partly in the bone. No round peas except shotgun pellets.

## F44 A bench stuck in the boxing ring (owner's screenshot), and every prop clear of the attractions
**The picture:** a blocky wooden bench (an L of 2 planks) sticks into the boxing ring's corner post and apron.

**Fix:**
- **Move that bench** out to the ring's yard, facing the ring, at least 3 studs clear of the ring's apron and ropes.
- **Check EVERY placed prop** (benches, bins, crates, barrels, lamps, signs, flower beds, trees, rocks) against EVERY attraction's full bounding box, including ropes, aprons, stairs, gates, rails and moving parts' sweep areas (the wrecking ball's swing, the sweeper's beam, the gyro rings, the fan cone).
  - Keep 3 studs clear.
  - The map lint reports 0 overlaps (extends F33).
- **The yard-dressing placer** must place props only on free yard spots: try a spot, test it with GetPartBoundsInBox (and the sweep areas), and if it is blocked take the next spot. Never place blind.
- **This bench model** is also replaced by a real bench mesh (`DETAILS_10.md`).
- **Check:** walk round every attraction. No prop touches or sticks into any of them.

## F45 Remove the yellow "random dummies" (owner, 26 Nov 2026: "fjern de gule random dukker")
**What they are:** most likely the light-yellow watcher stand-ins (`Client/WatcherStandIns`, OVERVIEW 0.7: "light yellow stand-ins … at every other spot within 220 studs"). They look like odd yellow figures standing about (the owner's screenshot: by the launch pads and the walkway).

**Fix:**
- **Turn the yellow stand-ins OFF** (`WATCHER_STANDINS = false`).
- **Watchers stay REAL grey lab ragdolls only.** As the player comes within about 90 studs of a machine, a real ragdoll WALKS to its watch spot (never pops in), so the machines near you always have their watcher. The tree belts hide the rooms further away anyway.
- **If light stand-ins are ever needed for performance,** they must look IDENTICAL to the real grey ragdolls (the same body, colour, skin and face), never yellow or any other colour.
- **Find every other yellow or gold dummy source too** (old GOD-mode spawns, test dummies, the "gold dummies" offer) and remove them. The only exception: a player who BOUGHT a gold-dummy cosmetic sees theirs.
- **Check:** walk round the whole map. No yellow dummies anywhere; every machine you walk up to has its grey watcher.

## F46 The ragdoll FREEZES when it dies (owner, 26 Nov 2026: "Fiks så ragdollen ikke fryser når den dør")
**The bug:** when a ragdoll is killed or knocked out, it freezes stiff, mid-pose or even mid-air, instead of collapsing and lying loose.

**Find the cause.** Check each of these and fix all that apply:
1. **A death or knockout handler anchors the parts or the root** (VitalsService death, DummyControl, Mourning, burial prep, BLOOD_KILLS, or a "rest-sleep" / performance sleep anchoring bodies too early).
2. **The motors stay at full strength:** the active-ragdoll pose freezes the last pose with tone 1 instead of going limp.
3. **The network owner changes on death** (owner set to nil or to another player while the body moves), so the body hitches or stops on screen.
4. **The Humanoid state goes to Dead or Physics in a way that stops the joints** (constraints disabled or Motor6Ds re-enabled).
5. **On the client, StreamingEnabled or the LOD swaps to a stand-in at the moment of death.**
6. **The X-ray, purple splatter or wound code welds or anchors something to the body.**

**The right death:**
- **Limp, at once:** the tone of every limb drops to about 0.05 over 0.2-0.3 s (`RAGDOLL_FEEL.md`). The body sags and collapses naturally with its momentum, and the limbs fall into place. It is never stiff and never stops in the air.
- **It lands with the impact effects,** slides or rolls a little, and settles.
- **It stays fully physical while dead:** you can shoot it (it reacts), push it, grab and drag it, throw it, lasso it, and see it in X-ray.
- **Rest-sleep only when really resting:** speed under about 0.5 studs/s for 1.5 s AND touching the ground. Even then, any touch, hit, grab or nearby blast wakes it instantly (unanchor and impulse in the same frame). Never anchor a body that is in the air or touching nothing.
- **Network ownership stays with the player who killed it** (or the nearest player) until it rests; then the server. No change in mid-fall.
- **CPR, burial and wake-up** start from the body's real lying pose; nothing freezes it before.

**Check:** kill 10 ragdolls in different ways (shots, melee, explosion, a fall from the tower, the cannon, a car, the dog, in water), on PC and phone. Each collapses loose, lands, settles and stays pushable and grabbable. None freezes.

## F47 After being dead, ragdolls pick the bullets out of each other (owner, 26 Nov 2026: "Gør så ragdolls piller skuddene ud fra hinanden efter de har været døde, så de ikke sidder overalt på alle")
**The goal:** bullet holes and lodged bullets do not pile up on everyone forever. Clearing them is a little scene, not a silent fade.

**When:** a ragdoll that was dead or knocked out wakes up (by itself, by CPR, or by REVIVE ALL) with bullet holes or lodged bullets.

**What happens:**
1. **A helper comes.** A nearby free ragdoll comes over (`FirstAid` / the helper logic; the CPR helper if there was one). If none is free within 30 studs, the woken ragdoll does it itself, sitting down.
2. **It picks the bullets out.** The helper kneels at the patient, which is sitting up, holding a pair of tweezers (a small prop). For EACH hole, up to 8, about 0.4 s each:
   - it leans to that hole and pulls the bullet out with a little tug;
   - a small "plink" sound and a tiny purple fleck;
   - the bullet (the same mesh as the X-ray slug, F43) drops to the ground and tinks, then fades after 5 s;
   - the hole closes with a small skin-coloured plaster (`BODY_V2.md` 4b) or simply fades out;
   - in X-ray, that slug disappears from the bone at the same moment.
3. **They react.** The patient winces at each pull ("Ow!", "Careful!", "Is that all of them?"). The helper says "Hold still." / "Almost done." (`LOOK AT YOU` rules: they look at each other).
4. **After the last bullet,** the patient gets up, thanks the helper ("Thanks, doc!"), and both go on.

**Limits:**
- **More than 8 holes:** the rest fade out quietly at the end.
- **Breaks:** broken bones (1b) stay until a bandage or sling (that is the injury system); only the bullets and holes are cleared here.
- **Interruptions:** if the scene is interrupted (shot, grabbed), it stops; the rest of the holes fade after 60 s as a fallback, so bodies never stay covered.
- **One scene at a time** within 40 studs of the player; others clear quietly off-screen.
- **Phones:** the same, with the effects pooled.

**Check:** shoot a dummy 10 times, kill it, and let it wake. A helper comes and pulls the bullets one by one, the holes close, and X-ray shows no slugs after. No body walks round still covered in holes.

## F48 The brick wall reacts to CARS, and resets 10-15 s after it has fallen (owner, 26 Nov 2026: "Fiks så at muren reagerer hvis man kører ind i den med en bil, og den resetter efter 10-15 sekunder efter den er faldet ned")
**Cars do nothing to the wall today.** The likely cause: the driver's client owns the car, so the server's Touched or velocity checks see no speed (or never fire) for the car's parts.

**Fix (`Systems/BrickWall`):**
- **Detect car impacts on the server reliably:**
  - every 0.1 s, check each vehicle near the wall (within 40 studs) with a box query along the wall's panels;
  - measure the car's speed from its position change between checks (this works whoever owns it), or read AssemblyLinearVelocity on the server.
  - A vehicle part inside or touching a panel's box at more than about 20 studs/s is an impact.
- **The force** comes from the speed × the car's weight class:

  | Vehicle | Force |
  |---|---|
  | bike | ×0.5 |
  | car | ×1 |
  | drift car | ×1 |
  | monster truck | ×1.8 |
  | tank | ×2.5 |

  It knocks out a CAR-SIZED hole at the contact point: 6-20 bricks by force. A tank at speed goes right through, and unsupported bricks above then fall in their cascade.
- **The car reacts too:**
  - a hard stop or bounce back (it loses most of its speed, unless it is a tank that ploughs through);
  - a dent on the car and a crunch sound;
  - bricks falling on the bonnet and roof with physics;
  - a dust cloud;
  - a camera shake for the driver;
  - at high speed, the driver may fly out (the existing car-crash eject).
- **Also from the car's own crash system:** if VehicleService already detects crashes, call BrickWall.hit from there too, so both paths work.

**Reset 10-15 s after it has fallen** (it was 45 s):
- **The rule:** 12 s (10-15) after the LAST brick has come to rest or fallen, the wall rebuilds brick by brick from the bottom up (about 3 s in total).
- **The fallen bricks** fade away as the new ones slide in.
- **Not on top of anyone:** if a player, a ragdoll or a car stands where bricks would go, those bricks wait until the spot is free (no rebuilding through someone).
- **The concrete walls** use the same 12 s rule (`DESTRUCTION.md` 2c). The crates keep 20 s.

**Check:** drive the car, the monster truck and the tank into the wall at low and high speed. The wall breaks round the hit, the bricks cascade, the car reacts, and the wall is back 10-15 s after the last brick fell. Check on PC and the phone emulator, with no lag.

## F51 A bit faster walking and running by default (owner, 26 Nov 2026: "Gør så man går og løber lidt hurtigere ved standard, så det ikke tager så længe at gå rundt")
- **The default walk** (Settings NORMAL = `StarterPlayer.CharacterWalkSpeed`, or what the game sets) goes to **30**. Check what it really is now in the place and write it in State.
- **Sprint** stays 1.65x the walk (`Client/Sprint`), so about 50.
- **The Settings choices:**

  | Choice | Walk speed |
  |---|---|
  | CALM | 22 |
  | NORMAL | 30 |
  | FAST | 36 |
  | VERY FAST | 44 |

- **The walk and run animations' speed** scales with the speed (no foot sliding).
- **Speed checks:** the server's anti-cheat and speed checks allow the new values (sprint at the highest setting is about 73; clamp anything above).
- **Ragdolls that run to you** (`ALWAYS3`) go to about 36, so they still keep up.
- **Check:** walk from the spawn to the Danger Zone on NORMAL. It must feel brisk; time it and write it in State.

## F52 The SWEEPER and the SHREDDER are "pure AI slop": rebuild them for real (owner's screenshot)
**Today:**
- **The sweeper:** a flat, bright-yellow polygon disc on the grass, an orange plank as the beam, a dark cube as the pivot, and a lamp post standing ON the pad.
- **The shredder:** a black rectangle with a railing and a yellow box.

No shape, no material, nothing that says "machine". This is what F49 means, and these two go FIRST.

**THE SWEEPER, rebuilt as an arena** (our own design):
- **The platform:** round, raised about 1.5 studs, with a padded rubber floor (a dark blue-grey rubber material, subtle tile seams) and a yellow-and-black hazard ring round its edge (a texture, not a flat colour).
- **Edge and access:** soft padded bumpers round the edge with 2 gaps; steps up at each gap.
- **The central hub:** a cylindrical motor housing with bolts, vents and a turning cap, and a warning beacon on top that spins while it runs.
- **The arm:**
  - a thick padded foam beam (red and white stripes, rounded ends) on a steel core that shows at the hub;
  - it sweeps just above the floor;
  - it turns smoothly on the CLIENT (`MACHINES_10.md` 3.22: 3 speeds, flinging ragdolls, the jump-the-beam challenge).
- **The control podium** at the edge: a big lever, a speed dial and a red button; the framed "SWEEPER" sign (F39).
- **Nothing on the platform:** no lamp post (it moves off the pad, F40 extended to attraction pads).

**THE SHREDDER, rebuilt as cartoon "Tumble Rollers"** (no gore):
- **The machine:** a steel machine frame over a sunken pit, with 3 big visible rollers covered in rounded rubber bumps (no blades or teeth) that turn with a grinding hum.
- **In:** a short conveyor belt feeds the rollers from a hopper ("PUT RAGDOLL HERE" glow).
- **Out:** a chute on the far side spits the ragdoll out flat like paper, folded; it pops back to shape (`MACHINES_10.md` 3.21).
- **Safety and controls:**
  - a yellow safety railing with hazard stripes;
  - warning lights;
  - a control box with a big lever and a red button;
  - grease stains and bolts.
- **The pit:** dark steel walls with ribs and a drainage grate. NOT a flat black rectangle.

**For both:**
- **Materials:** real ones (Metal, DiamondPlate, Rubber, Foil) with colour variation; edges bevelled or trimmed; 5+ small details each (bolts, cables, labels, vents, lights).
- **Lag-free:** meshes where possible; the moving parts animate on the client only near you.

**The rule for ALL floors and pads** (the same problem everywhere): no flat single-colour polygon discs or slabs. Every pad gets a fitting material or texture (rubber, concrete, sand, dirt, metal) with an edge or trim.

**Check:** close-ups and a medium view of both; a harsh score "would a player call this a box or slop?" They must be 9+.

## F53 Trees block the WEAPON TESTING building (owner: "Man kan ikke komme ind i Weapons Testing, fordi træerne dækker")
**The screenshot:** the weapon range ("WEAPON TESTING") in the Danger Zone has trees and bushes planted right in front of its open front and inside the entrance. They hide the sign, block the way in, and stand on the range's floor.

**Fix:**
- **Clear zone:** remove every tree, bush and prop from a clear zone in front of every building entrance and door (at least the entrance width plus 4 studs each side, 12 studs deep), and from INSIDE every building and covered attraction.
- **Paths:** a path (`MAP_MASTERPLAN.md` PATHS rules) leads straight to the weapon range's entrance with a landing at its front.
- **The sign:** the sign above the entrance must be fully visible from the path (no leaves in front).
- **The general rule** for the tree and dressing placer: trees, bushes and the belts' planting never go:
  - inside any building or attraction bounding box (+3 studs);
  - in front of any entrance, door, gate or sign (a clear cone 12 studs deep);
  - on any path or landing.
- **The map lint** reports trees or bushes in entrance zones and inside buildings, and it must be 0.
- **Check:** walk into the weapon range and every other building or gate from its path. Nothing blocks the way or the sign.

## F54 Players can run straight THROUGH trees and bushes (owner: "Fiks så man kan løbe igennem træerne")
- **Players:** every tree (trunk and crown), bush, hedge and flower plant is non-collidable for PLAYERS. Use a collision group "Foliage" that does not collide with "Players" (or CanCollide off on all foliage parts). Players run through the tree belts too, so shortcuts into the rooms are fine.
- **Ragdolls:**
  - the solid belt volumes from F32 stay, but ONLY for ragdolls (the collision group "RagdollBlock": collides with ragdolls, not with players), so walkers do not wander into the belts;
  - thrown bodies that land in foliage simply lie on the ground there (no tree parts to get stuck in), and the F32 unstick rule moves them out when they get up.
- **Cars and bikes** also pass through foliage (no sudden stops on a bush).
- **Bonus:** fewer collision parts, so less physics cost (`RAGDOLL_DIRECTOR.md` part A).
- **Still solid:** the rocks, walls, fences, buildings, machines and benches (they are not foliage).
- **Check:**
  - run through a belt, a grove and a hedge on PC and phone: no blocking, no camera bump;
  - a walker ragdoll still keeps out of the belts.

## F55 A path that runs into a WALL with no opening (owner: "Man kan ikke gå denne sti, fordi muren ikke har en dør eller en indgang")
**The screenshot** (Animal Cove, by the aquarium): a walkway leads straight into a grey concrete wall (a pen or room wall), and the wall has no gap. The path is useless.

**Fix:**
- **Every place where a path meets or crosses a wall, fence, railing or pen edge** gets ONE of these:
  - **an OPENING:** a proper gate or doorway, at least the path's width + 2, with a frame (posts or pillars and a lintel), a gate that swings open or an open archway; for pens, a gate in the fence (`MAP_MASTERPLAN.md` PATHS rule 4);
  - or the path is re-routed round the wall, if the wall must stay closed (a dangerous animal's pen: then the path leads to a viewing platform or window instead).
- **Wall ends:** walls never end in the middle of a path, and walls never cross a path diagonally.
- **The lint** (part of F50): every path leg against every wall, fence or railing piece. Any intersection without an opening counts, and it must be 0.
- **Check:** walk every path in Animal Cove and the other rooms to its end. Each one leads somewhere you can enter, or to a viewing spot. Nothing dead-ends at a wall.

## F56 Players get kicked out of cars while driving (owner: "Fiks så man ikke bliver kicked fra bilerne, når man kører")
**The bug:** while driving, the player is thrown or dropped out of the car without pressing exit.

**Find the cause.** Check each of these and fix all that apply:
1. **The crash-eject rule** (high-speed crashes throw the driver out; F48's wall crash; MACHINES_10 3.17).
2. **The player-ragdoll system** (PlayerRagdoll, knockback, blasts, being hit by flying bricks, ragdolls or debris): it switches the driver's Humanoid to Physics or Ragdoll, which breaks the SeatWeld.
3. **Speed and anti-cheat checks** (F51 / MOVE_FAST / the server watchdog) seeing a driver at car speed and resetting or teleporting the character.
4. **OutOfBounds, GroundGuard or the unstick rule** (F32) moving the CHARACTER instead of the car.
5. **StreamingEnabled** streaming out or re-anchoring a car part, or the vehicle respawn/"take home" logic running while someone sits in it.
6. **NO_BLACK_SCREEN, the camera code or the X-ray** changing the Humanoid state.
7. **The seat being set Disabled** or the car being re-parented while it is used.

**Fix:**
- **The driver stays in the seat until THEY choose to leave** (jump or the exit button).
- **Automatic eject is OFF by default** (`CAR_EJECT = false`; owner). A big crash shakes the camera, dents the car and makes a crash sound, and the driver stays in.
- **While seated, the player is immune** to the player-ragdoll knockback, blasts and debris (the CAR takes the push instead), and to the speed and unstick checks for the character.
- **Out of bounds:** OutOfBounds or GroundGuard moves the whole CAR with the driver, never the driver alone.
- **Never touch a used car:** no respawn, re-parent, re-anchor or streaming-out of a car that has a driver or a passenger (persistent while used).
- **Passenger ragdolls** may still fly out on big crashes (the fun part), but the player never does.
- **Check:**
  - drive every car, the tank, the monster truck and the bike for 2 minutes each, at full speed;
  - crash into the brick wall, other cars and ragdolls; jump off the plaza stairs; drive through an event;
  - the player is never thrown or dropped out; only the exit button gets you out;
  - check PC and phone.

## F57 LAUNCH PADS launch CARS too (owner: "Fiks så launch pads virker med biler")
**Today:** the 3 launch pads in the Crash Yard (aimed at the brick wall) only launch ragdolls. Driving over them does nothing. The likely cause: the car is owned by the driver's client, so a server impulse or Touched check does nothing to it.

**Fix (`PAD_CARS = true`):**
- **Detect on the server by position:** every 0.1 s, check for any vehicle whose wheels or body are over a pad's box (the same method as F48's wall check), moving at more than about 8 studs/s.
- **Launch it on the machine that simulates it:**
  - **a car with a driver** (owned by the driver's client): the server sends a validated "launch" to THAT client (one Net remote, with the pad id); the client applies the impulse to the car's assembly. The server checks the pad, the distance and a cooldown of 2 s per car per pad, and refuses anything else.
  - **a car without a driver** (owned by the server): the server applies the impulse itself.
- **The launch:** forward along the pad's arrow direction (toward the wall), up at about 25-35°, adding about 50-90 studs/s by pad strength (3 pads = small, medium, BIG). The car's mass is taken into account, so the tank jumps less than the drift car.
  - A whoosh and a spring-pad "thunk", a dust burst and a short camera FOV kick for the driver.
- **In the air:** the car keeps its rotation physics (it may flip; that is fun). The driver STAYS in (F56).
  - An "AIR TIME 2.4 s" pop on landing, plus a NEW BEST.
  - Landing makes a heavy thud, sparks or dust, and a camera shake.
- **The wall:** a launched car hitting the brick wall breaks it (F48), and passenger ragdolls fly out on the big hit.
- **The pads look the part:** arrows painted on each pad pointing at the wall, a strength label (1, 2, 3) and lights that flash when something is launched.
- **Check:** drive the car, the drift car, the monster truck and the tank over each pad at 2 speeds, on PC and phone. Each launches in the arrow direction by strength, the driver stays in, the landing works, and the wall breaks on a hit.

## F58 The SLIDE at the top of the tower is broken (owner's screenshot)
**What the picture shows** (the tower's top deck, the green slide's start):
- the chute is made of separate green blocks that do not join: gaps, a piece sticking up at an angle, side walls that stop and start, and blocks overlapping;
- the slide's start pokes through the tower's edge or railing with no proper opening, so it is unclear how to get in;
- the supports do not meet the chute.

**Fix: rebuild the slide as ONE smooth, continuous chute:**
- **The chute:** a constant cross-section (a rounded or U-shaped trough with side walls about 2 studs high), following a smooth curve from the deck to the runout. Two ways to build it:
  - (a) a proper slide or chute mesh set from the Creator Store (straight and curve pieces that join cleanly, one style, malware pass);
  - (b) many short segments along a spline, each joined edge to edge with matching angles: no gaps, no overlaps, no steps.

  The inside surface is smooth and slippery (low friction CustomPhysicalProperties), with a slight bank in the curve.
- **The start:** a proper start platform built into the tower deck.
  - An OPENING in the railing (posts both sides, a top bar with a "SLIDE" sign and the slide pictogram).
  - A small sit-down step, and handrails into the chute.
  - Players walk in, sit and go; ragdolls are dropped or pushed in.
- **Supports:** steel truss legs that actually meet the chute's underside at regular spacing and stand on the ground (or on the tower), with bolted brackets.
- **The end:** a smooth run-out curve that levels out onto the landing in Tower Square (`OwnerMapPlan` SlideRunout), with a soft mat.
- **Ride feel:** players and ragdolls speed up, follow the curve and shoot off the end (`MACHINES_10.md` 3.2: sparks on the bends, the launch distance score). Nobody gets stuck on a joint.
- **Lag-free:** a few meshes, and the collision as a simple smooth surface (CollisionFidelity PreciseConvexDecomposition only on the trough, or invisible smooth collision parts).
- **Check:** a quick look from above and from the side (no gaps, nothing sticking out), plus one ride down as a player and one ragdoll pushed in.

## F59 X-ray: shots in the BELLY and the BACK must show on the bones (owner: "Gør så man kan se skud på knoglen i maven/ryggen")
**Today:** a shot in the belly or the back shows nothing on the skeleton. The likely causes:
- the torso has no real bones in the X-ray (only a simple block, or only the limbs have bone capsules);
- the slugs are only placed on limb bones (`XRAY_SLUGS`: "max 15 a limb");
- the belly part of the torso has no bone at all.

**Fix:**
1. **A full torso skeleton in the X-ray**, cartoon but anatomically placed:
   - the **ribcage**: about 6 visible curved ribs each side, joined at the front to a **sternum** and at the back to the spine;
   - the **spine**: a column of vertebrae from the neck down to the pelvis (neck, chest and lower back vertebrae);
   - the **pelvis** at the bottom of the belly;
   - 2 **shoulder blades** (scapulae) on the upper back;
   - the **collarbones**.

   Each bone has its capsule (or capsules) for the hit test (F28).
2. **The real bullet path through the torso** (F28):
   - **the belly from the front:** the bullet goes between or into the lower ribs, then on to the lower spine (the lumbar vertebrae) or the pelvis, depending on height and angle;
   - **the chest from the front:** a rib or the sternum first; strong guns go on to the spine;
   - **the back:** a shoulder blade or a rib, or the spine first;
   - **from the side:** the ribs on that side.
   - A bullet that misses every bone stops in the shell, or exits on strong guns (an exit hole).
3. **What shows on the bone:**
   - the lodged bullet (F43: a real bullet, nose pointing in the direction it travelled, about 60 % embedded) at the exact spot;
   - crack lines from the entry point;
   - breaks and shatters by force (1b / F29), e.g. a cracked rib, a broken rib, or a chipped vertebra (still cartoon; nothing pokes out of the body).
4. **Visible:** the torso's X-ray shell is see-through enough (the same glass look as the limbs) that the ribs, spine and bullets read clearly, from the front and the back.
5. **The hit card** shows "Rib", "Spine", "Pelvis" or "Shoulder blade" for torso hits, not only "Belly" or "Chest".

**Check:** in X-ray, shoot the belly, the chest, the lower back and the upper back from the front, the back and the side with a pistol, a rifle and a sniper. Each bullet shows on the right bone, pointing the right way, with cracks or breaks by force.

## F60 Your shots fade after 4 newer ones: smoothly, not all at once (owner: "Gør så ens skud forsvinder efter 4 skud, ikke forsvinder med det samme, men bliver mindre og mindre tydelige")
**The rule (owner clarified: "Altså på ragdollen": it is about the holes ON THE RAGDOLL, `SHOT_FADE = true`):**
- **Each RAGDOLL keeps its newest 4 bullet holes** fully visible.
- **When a 5th hole lands on that ragdoll,** the oldest starts to FADE: over about 3 s it gets lighter and smaller (Transparency 0 → 1, scale 1 → 0.6), then it is removed.
- Every later hole pushes the next oldest out the same way, so a burst gives a soft trail of fading holes, never a sudden pop.
- **Only the holes on ragdolls follow this rule.** Holes in walls, crates and the ground keep their own rules (`DESTRUCTION.md`: cracks, planks, fade after 30 s).
- **What fades with the hole:** its purple splat (2b) and its X-ray bullet (F43) fade together with it, so the body never keeps old marks the player cannot see.
- **Automatic weapons:** the same rule. At high fire rates the oldest fade quicker (about 1.5 s), so there are never more than about 8 marks fading at once.
- **Shotguns:** one shot's pellet cluster counts as ONE shot (its holes stay and fade together).
- **Multiplayer:** the 4 count per ragdoll, whoever shot.
- **Kept as they are:** the F47 bullet picking (after death) and the bone BREAKS (1b) stay as they are. Only the holes, splats and slugs fade.
- **Lag-free:** pooled decals and parts; the fade is one client tween per mark.
- **Check:** fire 10 single shots at a dummy. Only the last 4 are sharp, and the older ones visibly fade one by one.

## F61 The owner is removed from ALL leaderboards (owner: "Fjern mig selv fra alle leaderboards")
- **Who is excluded:**
  - the game's owner: the group owner, rank 255 in the group (`Systems/Owner.isOwner`);
  - every admin in `Systems/Admins`;
  - the owner's known accounts (RolingStudios and any test accounts);
  - all listed in `Config.LEADERBOARD_EXCLUDE` (userIds, so more can be added).
- **Display:** they are skipped on every board (all 4 lab boards, any race or best-lap boards, the global, friends and "here" lists, the in-game player list ranks). The next players move up, so the top 20 is still 20 real players.
- **The #1 gold statue** is never the owner or an admin.
- **Stop submitting:** excluded players' scores are no longer sent to the OrderedDataStores. Do not delete old entries (no writes to live DataStores beyond the game's own saving); filtering them out at display time is enough.
- **Check:** in Studio as the owner, the boards show no owner row and #1 is someone else (use a fake board list in Studio if needed).

## F62 The other MAPS must not sit inside a mountain (owner: "Fiks alle de andre maps, så de ikke er inde i et bjerg")
**The maps** (`Shared/Places`, built by WorldMaps / OutdoorMaps): Tropical Island, Downtown, Building Site, Old Farm and Army Base (the outdoor row at OUTDOOR_Z 1400, OUTDOOR_SPACING 1200), plus the rooms (ROOM_HEIGHT 4000). The Arena and the UFO stay hidden.

**The problem:** in at least one map the player stands inside or right against a mountain or hill. Likely causes:
- the new backdrop's terrain hills and the far mountain meshes (`LabOwnerMap` backdrop) reach out over the other maps' areas, or are placed relative to a shared origin;
- the maps' own hill rings sit too close or too high;
- the map spawn spots lie inside terrain.

**Fix, for each map:**
1. **Visit it** (MAPS board → each map) and capture its spawn view, plus a top view of its area.
2. **Find any terrain or mesh from ANOTHER area** (the lab's backdrop, the hill ring, other maps) inside the map's bounds (`Places` size) plus a 150-stud margin.
   - Terrain: use `Terrain:ReadVoxels` over the area.
   - Meshes and parts: use a box query.
3. **Fix the source:**
   - keep the lab's backdrop (hills, forest, mountains) strictly round the LAB only (clip its terrain and remove its meshes outside the lab's backdrop ring);
   - move a map further away if it is too close to the lab or another map;
   - never cut into a map's own play area.
4. **Give each map its own small, fitting backdrop** outside its bounds, so it never looks empty or clipped:
   - Island: sea and a distant island;
   - Downtown: a city skyline;
   - Building Site: fences and a city edge;
   - Old Farm: fields and hills;
   - Army Base: desert hills.
5. **Spawn spots:** each map's spawn is on its open ground, with clear space round it and facing into the map.
6. **Check:** visit every map and stand at its spawn. Nothing is inside a mountain; the edges look finished.

## F63 The left nav: MORE becomes WEAPONS (owner: "Skift More til Våben-menuen, altså den røde mappe med T keybinded")
**Today** (PC screenshot), the left nav shows Shop (Y), More (9), Lab (8) and Multiplayer (0). The WEAPONS menu is the red toolbox slot "T" at the start of the hotbar.

**Change:**
- **The left nav becomes:** Shop (Y), **WEAPONS** (the red toolbox icon, key **T**), Lab (8), Multiplayer (0). The same tile size, style and key chip as the others; it opens the WEAPONS menu exactly as the toolbox did.
- **The hotbar:** the red toolbox slot is REMOVED, so the hotbar holds only the weapons (1, 2, 3…). There is no duplicate.
- **MORE moves:** a round gear button in the top bar next to the Roblox buttons (key 9 stays; console: a menu button glyph). Everything in More (MAPS, GOD MODE, REWARDS, RANK & EGGS, FRIENDS, SETTINGS, FAVORITE…) is still one tap away there.
- **Phones and tablets:** the same idea.
  - **Left stack:** Shop, WEAPONS (red toolbox), and Multiplayer (if it fits; otherwise inside the gear menu).
  - **The gear** (More) goes top-left.
  - **The hotbar** has no toolbox slot.
  - Keep the phone HUD clean (F6).
- **Hints:** the first-time hints and the TRY lesson that pointed at the toolbox slot now point at the WEAPONS tile.
- **Check:** PC, tablet and phone. T opens WEAPONS from the nav; the gear opens More; there is no toolbox on the hotbar; nothing overlaps.

## F64 V always toggles first person, also while holding a weapon (owner: "Fiks så at V putter en ud af first person, også hvis man holder et våben")
**Today:** V (the eye chip, first person on and off) does not take you OUT of first person while you hold a weapon. Something forces first person with a weapon: the "the first strike or picking a weapon goes to first person" rule, an aim mode, `fpStart`, or the camera code that locks LockFirstPerson / CameraMaxZoomDistance while a gun is held.

**Fix:**
- **V is a true toggle at all times:** first person ⇄ third person, with or without a weapon, while aiming, in the shoulder cam, and in vehicles where first person exists.
- **When the player leaves first person with V,** nothing pulls them back in. No re-entry on the next shot or the next weapon pick, until they press V again.
- **The automatic "go to first person" on picking a weapon or on the first shot** only applies if the player has NOT chosen third person with V this session. The player's choice always wins.
  - Remember the choice in Settings (`fpStart` / `fpShot`); the existing settings stay in charge.
- **Phones:** the eye button does the same.
- **Console:** its bound button does the same.
- **Weapons keep working in third person:** the crosshair, aiming and recoil all work in third person (the shoulder cam on phones, PHONE_SHOULDER_CAM).
- **Check:** hold each weapon class, press V several times, shoot, switch weapons. V always switches, and nothing forces you back.

## F65 Ragdolls' LEGS jitter wildly when they turn, walk or animate (owner: "Flere af ragdollsne bugger når de vender sig, helt random når de går eller laver animationer, deres ben bugger helt vildt hurtigt")
**The bug:** at random moments, while turning, walking or doing an idle or gesture, a ragdoll's legs shake extremely fast (vibration or flicker).

**Find the cause first.** Record one in Studio (a slow-motion capture), and log the legs' joint targets and the root's network owner each frame for a jittering ragdoll. Likely causes; check each:
1. **Two systems drive the legs at once:** the walk animation, the active-ragdoll pose (Poses / tone), the new turn-in-place and look-at (F0.9 LOOK_AT_TALK turns the waist and body), the idle actions, and RagdollNav steering all set targets in the same frames, so the targets fight.
2. **Motor gains too stiff with too little damping:** the AnimationConstraint or AlignOrientation (or the Motor6D) on the hips and knees overshoots and oscillates, worse at low frame rates.
3. **Network ownership flapping:** the owner of the body switches between the server and a client (or between 2 clients) many times a second as the player moves near and far, so each switch snaps the legs.
4. **Steering flips the facing direction:** each path waypoint or avoidance tick sets a new facing, so the root's orientation target flips back and forth, and the legs try to step each way.
5. **Feet touching or colliding with the ground, kerbs or each other:** the legs get pushed up and down (collisions between the legs or the feet and the kerbs).
6. **The light (stand-in) mode switching on and off** at the 60-stud border every frame.

**Fix:**
- **ONE pose blender owns all leg targets:** walk, idle, gesture, turn, look-at and hit reactions are layered in one place with weights. Each target changes smoothly (a capped speed per frame). The upper-body layers (look-at, gestures) never touch the legs.
- **Joints:** critically damped joint motors (raise the damping, lower the max torque or angular speed on the hips, knees and ankles while standing or walking), so there is no overshoot. Tune at 30 and 60 fps.
- **Turning in place:** a real turn-step cycle (small alternating steps at a calm turn rate, about 180°/s max). The facing target is smoothed (it never flips). The steering updates the facing at most 10 times a second, with a dead zone of ±10°.
- **Ownership with hysteresis:** a body changes its network owner only when it is 15+ studs nearer to the new player, and not more than once every 3 s. A walking ragdoll nobody touches stays with the server.
- **Collisions:** no collisions between a ragdoll's own legs and feet; the feet's collision is a smooth box; the kerbs are not climbable steps for the feet (or the walkers keep off them).
- **The light-mode border has hysteresis:** switch at 60 studs going in and 75 going out, never back and forth.
- **A watchdog:** if a leg joint's angular speed stays very high for 0.3 s while the ragdoll is standing or walking, drop that leg's tone to 0.5 for 0.5 s (it settles), and log it with Metrics, so new causes show up.

**Check:** watch 10 walkers and chatters for 2 minutes (turning, walking, gestures, LOOK AT YOU) at 60 fps and in the phone emulator. No leg jitters.

### F65 UN-PARKED (owner, 26 Nov 2026: "Benene hakker stadig helt randomly i 1-2 sekunder")
The owner sees it again: the legs jitter for 1-2 seconds at random moments. The 10 s measurement (v1151) was too short and too calm to catch it. Do NOT wait for a reproduction. Do both:

1. **Build all the preventive fixes from F65 anyway:**
   - one pose blender owns the legs;
   - critically damped hip, knee and ankle motors (tuned at 30 and 60 fps);
   - smoothed facing with a dead zone, and a turn-step cycle;
   - ownership hysteresis (15 studs, 3 s);
   - no self-collision of the legs and feet;
   - hysteresis on the light-mode border (60 in / 75 out);
   - the watchdog: a leg spinning too fast for 0.3 s → that leg's tone 0.5 for 0.5 s.
2. **Catch it when it happens** (a jitter detector, always on in Studio and live, cheap):
   - for each full-physics ragdoll near the player, count the knee-angle direction reversals per second;
   - more than 6 a second for 0.3 s = a JITTER event.
   - **Log the context at that moment:**
     - its state (walking, turning, idle action, look-at, recruit run, chatter role switch, demo walk, bump);
     - the network owner and any owner change in the last 2 s;
     - the light/full mode and any switch in the last 2 s;
     - its speed and its facing changes in the last 1 s;
     - what its feet touch (kerb, path edge, another ragdoll, a slope);
     - the frame rate;
     - which systems set leg targets in the last 0.5 s.
   - Send it to Metrics (live) and print it in Studio.
3. **(26 Nov late: NO run; the owner tests. Keep the detector on for the owner's test.)** ~~A longer Studio run to provoke it:~~ 5 minutes with about 12 ragdolls near the player, while the player moves around a lot (walking in and out of the 60-stud border, onto kerbs and slopes), with roles switching and look-at talking; once at 60 fps, once in the phone emulator at a low frame rate.
4. **Fix every cause the log points to.** Write the findings in this section and in OVERVIEW's State.
5. **The likely "1-2 s" causes** to look at first:
   - a network-owner hand-off or the full/light mode switch (both are short bursts);
   - a role switch (chatter ⇄ comer) or the start or stop of LOOK AT YOU fighting the walk;
   - a foot catching on a kerb edge.

**Findings (Claude Code, v1155):**
- Built the always-on detector (`LEG_JITTER_LOG`, Client/LegJitter): knee reversals per second for every ragdoll within 60 studs; an event logs state, role, watch job, pace, parked, Home changes in 2 s, who simulates it, speed, the surface under the feet and the fps.
- A 100 s provoking run (10 jumps round the map) gave 29 events at 7 rev/s: all normal running (Pace 2-2.5, speed 7-17) at Studio's ~15 fps. The threshold is now 10 rev/s AND 70 % of the frame rate (real jitter flips almost every frame); a 60 s run after that: 0 events.
- REAL CAUSE FOUND and fixed (in my own RagdollNav, 0.95): a system that sets Home many times a second (the Newspaper route, Pace 1.4: 7-10 Home changes in 2 s; FirstAid each tick) made RagdollNav start a path each time and put its own waypoint back, so Home flipped between two points several times a second: the legs stepped each way = the 1-2 s jitter. Now a system that changes Home more than once a second steers on its own (no path), and FirstAid's same-goal resets drop the path.
- Still to build from the list: one pose blender for the legs, damped hip/knee motors, the turn-step cycle, the leg watchdog.
- A real event caught at 60 fps (v1160 Play): 23 rev/s, a "Chat" role ragdoll WALKING (speed 5) with 2 Home changes in 2 s: the chatter walking in while LOOK AT YOU turns it = the role switch / look-at fighting the walk (cause 5b). Next: no look-at while walking (DummyLife lookWhileTalking only when standing).

## F66 Remove the HIT CARD on phones (owner: "Fjern denne på telefon")
**What it is:** the small dark hit card ("Chest · Belly · Left leg · Right leg +8 / 0% health · knocked out · KO") that shows the hit parts and the health of the ragdoll you hit (the body card / hit card / vitals text).

**Fix:**
- **On PHONES:** it never shows (`PHONE_HIT_CARD = false`), and neither does any tap target or arrow that belonged to it.
- **What phone players still get:** the KO pop, the hit sounds, the splatter, the reactions and the goal line.
- **Tablets:** follow phones if they use the phone HUD.
- **PC and console:** keep it as now.
- **Check:** shoot and knock out ragdolls on the phone emulator. No hit card appears.

## F67 The tower STAIRS must work indoors (owner: "Fiks trappen så man kan bruge den indendørs også")
**The screenshot:** inside the steel tower, a flight of diamond-plate stairs runs straight up into the underside of the next flight or floor. There is no headroom, so you hit your head or get stuck. It is dark and cramped, and the camera is squeezed against the steps.

**Fix (the 5-floor tower, `LabOwnerMap` hero):**
- **Headroom:** at least 9 studs of clear headroom above EVERY step and landing. Cut openings in the floor or flight above wherever a flight rises under it (a proper open stairwell).
- **Real switchback stairs:** flight → landing → turn → flight, between each floor. Steps sized for a Roblox character (about 1 stud rise, 2 studs deep), at least 8 studs wide.
  - A smooth invisible ramp under the steps, so walking up never catches or bounces.
  - Railings on the open sides.
- **Floors:** each floor has a clear walkable landing at the stair top, with an opening out to the deck or balcony.
- **Light inside:** a few cheap lights (client-only, near the player) or a lighter interior material, so it is not dark.
- **The camera indoors:** when the player is inside the tower, the camera does not clip into steps or walls. Use CameraOcclusionMode "Invisicam" while inside (or a shorter max zoom inside the tower), so you always see your character.
- **Ragdolls:** walkers and recruits can use the stairs (the pathfinding sees them as walkable); thrown ragdolls tumble down them with physics.
- **Phones:** the stair turns are wide enough that the thumbstick steers through easily.
- **Check:** walk from the ground to the top deck and back down on PC and phone, without hitting your head, getting stuck or losing the camera; and a ragdoll walks up.

## F68 Remove the button that turns the WATER on: the water is always on (owner: "Fjern knappen der slår vandet til, bare gør så det altid er til")
**Find it.** There is a button or prompt somewhere that switches water on (I could not find it in the repo code, so it is probably in a place-file model or added in the map rounds). Search the place for every ProximityPrompt, ClickDetector and red button near water:
- the spawn fountains;
- the Splash Zone gate jets;
- the pools and the aquarium;
- the duck pond;
- the water tower;
- the washer;
- any Creator Store fountain or pool model (these often carry a "turn on" script; that also belongs to the malware pass: remove the script).

**Fix:**
- **Remove that button or prompt** (and its script).
- **The water is ALWAYS on:** fountains spray, jets arc, pools have their water surface and gentle waves, the duck pond ripples, all the time.
- **Lag-free:** the sprays and ripples animate on the client, only within about 120 studs and in view (pooled emitters), and on low tier with fewer particles. The water sound plays only near.
- **Check:** walk past every water feature. No button, and the water is running.

## F69 The motorbike rider gets STUCK (owner's screenshot: the rider and the dirt bike are wedged on a row of grey plates or a fence)
**The cause:** BikeService steers between "clear spots of the lab" with AlignPosition and AlignOrientation in more or less straight lines. On the new big map those lines cross fences, railings, kerbs, stairs and props, and the bike gets wedged.

**Fix (BikeService + the cyclist):**
- **Ride on ROADS only:** build the route from `OwnerMapPlan` (the road and avenue centre lines: the outer avenues, the cross roads, the boulevard sides), as a loop of waypoints along the road centres. Never across grass plots, belts, plazas with props, stairs or rooms.
- **Smooth turns** at junctions (a curve through the junction pad); the speed drops before corners.
- **Obstacles:** it slows and steers round players, ragdolls, cars and anything on the road (a short look-ahead raycast); it stops and waits if the road is blocked.
- **The stuck guard:**
  - if the bike moves less than 2 studs in 2 s, it backs up 4 studs, turns and re-joins the nearest road waypoint;
  - if it is still stuck after 6 s, the rider gets off and walks away;
  - the bike is taken back to its pad only when no player can see it (Part C, never vanish in view), and a new rider comes later.
- **Upright:** if the bike tips over, the rider gets off and picks it up (the existing "comes off" logic), never lying wedged.
- **The same rules for the pedal-bike cyclist** (`LIFE_IDLE.md` 2) and the ridden wheelchairs.
- **Check:** let the rider do 3 full loops of the map. It never leaves the roads and never gets stuck. Block it with a car, and it waits or goes round.

## F70 No KEY LETTER on the gift on a phone (owner: "Fjern keybind (J) fra gaven på tlf")
**Why it shows:** the gift's key chip (`Client/HudV3.luau`, `giftKey`, about line 364-383) is shown when `KeyboardEnabled and not ViewMode.isTouch()`. `ViewMode.isTouch()` is false in Studio's phone emulator (it keeps the mouse) and on an iPad with a keyboard or trackpad, so the "J" shows there. It is also drawn only on `Keybinds.onChanged`, never again when the device or view changes. `RewardsUI.keyLabel` already uses the right rule (`not TouchEnabled`); the gift chip does not.
**Fix** (behind `Config.PHONE_NO_KEYS = true`):
- **One rule for every key letter on the HUD:** add `ViewMode.showKeys(): boolean` = `UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled` (in Studio with `DevTouch`, false). Any touch screen (phone, iPad, the Studio emulator) shows no key letters.
- **The gift:** `drawGiftKey` uses `ViewMode.showKeys()`, and is redrawn on `ViewMode.onChanged` and on `UserInputService` `KeyboardEnabled` / `TouchEnabled` changes, as well as on `Keybinds.onChanged`. The J key itself still opens Rewards on a PC.
- **The same rule** for the other chips that use `KeyboardEnabled and not ViewMode.isTouch()`: the HudV3 chip row (about line 710), `HudPlus.keyboard()` (the left launchers, incl. `Hud_Rewards`), `LabCamera` (about line 509) and `FirstShotFP` (line 42). Also make `PhoneClean` hide any GuiObject named `Key` or `KeyChip` under HudV3 on a touch screen (its once-a-second sweep), so a new chip can never slip through.
- **Only the letters go.** The gift button, its red counter and its wiggle stay as they are.
- **Check:** phone (the Studio emulator) and iPad: no "J" on the gift and no letter on any HUD button. PC: the "J" chip is on the gift and J opens Rewards.

## F71 The phone HOTBAR is SMALL until you tap it; then it grows and you pick a weapon (owner: "Gør så hotbaren er mindre på telefon, indtil du trykker på den og så bliver den forstørret og så kan du vælge våben")
**Now:** on a landscape phone the bar (`Client/PokeController.luau`, gui `ToyBar`, `PokeController.plan`) has slots of 62 x 56 (`Config.PHONE_BIG_HOTBAR`), between the move stick and SHOOT/GRAB. It takes a big bite of the screen all the time.
**New** (behind `Config.PHONE_MINI_BAR = true`; phones only: touch with the short screen side 500 px or less, both landscape and upright; iPad and PC keep today's bar):
- **Small (rest):**
  - the same bar at about 0.6 size (a `UIScale` on the bar frame, anchored bottom centre, so it shrinks downward to the bottom edge);
  - the held weapon keeps its outline so you still see what you hold;
  - the next-weapon cards and the WEAPONS label are hidden while it is small (the WEAPONS square stays, small);
  - ammo numbers and slot numbers are hidden (too small to read).
- **One tap anywhere on the small bar opens it.** In the small state the slots do not react one by one; one invisible button covers the whole small bar, at least 48 px high and 8 px wider on each side than the bar, so it is easy to hit. A tap on the small bar never fires, never equips and never moves the camera (the button sinks the touch).
- **Open (big):**
  - the bar grows to today's size (the size LayoutCheck already measured clear of the thumbs) in 0.15 s with a small spring (Back Out);
  - now each slot can be tapped and works as today (tap a weapon to hold it; tap the WEAPONS square for the Weapons menu);
  - the next-weapon cards show again.
- **It closes by itself:**
  - 0.3 s after you pick a weapon (so you see your pick light up);
  - after 4 s with no tap on the bar;
  - when you touch anywhere else (the stick, SHOOT, the camera): it closes AND that touch still works as normal (do not sink it);
  - when a window opens (Shop, Weapons, Rewards).
- **New weapon:** when you unlock or get a weapon, the bar opens by itself for 1.5 s with the new slot popping, then shrinks again.
- **Everything placed over the bar follows its visible top** (small or big): the pick chip (`PickChip`), the next-weapon row, `ChaseHud`, `Speedometer` and `HudPlus`'s bar-relative parts. Read the bar's visible size (frame size x the UIScale), not `plan.size`.
- **Cheap:** only the UIScale and the outline are tweened (one tween at a time); no new GUIs per frame. No text hint: the first time a player is on a phone, the small bar does one soft pulse (scale 0.6 to 0.66 and back, twice), then never again (a local flag, and nothing if it cannot be stored).
- **Gamepad and keyboard** never see the small bar (a phone with a pad: today's bar).
- **LayoutCheck:** check both states on the phone sizes (small and open) for overlap with the stick, SHOOT/GRAB, jump and the safe area.
- **Check:** in the Studio phone emulator (landscape and upright): the bar is small; one tap opens it; picking a weapon holds it and the bar shrinks; tapping the stick closes it and you walk at once; after 4 s it closes alone. iPad and PC: today's bar, unchanged.

## F72 Ragdolls still WALK INTO THINGS all the time (owner: "Sørg for at ragdolls ikke går ind i ting hele tiden")
**What is wrong now** (read in `Shared/Ragdoll/ActiveRagdoll.luau` `updateMoving`, `blocked`, `avoidDummies`, and Systems/RagdollNav):
- **No path for most walks:** RagdollNav only paths a Home more than 8 studs away, and since the F65 fix (v1155) a system that changes Home more than once a second "steers on its own" with no path at all: the Newspaper route, FirstAid, the recruit runners, NEVER ZERO and anything following the player. These are exactly the walkers you see, so they walk straight into things.
- **The obstacle check is one thin ray:** `blocked` casts ONE ray from the pelvis centre at knee height, 2.5 studs ahead. The body is about 2 studs wide, so a lamp post, a bench end, a fence post, a table corner or a machine edge off the centre line is never seen. At a run (speed 10-17) 2.5 studs is less than 0.25 s, so it sees things only when it is already touching them.
- **The detour is random and late:** after 1.5 s without progress it turns a fixed 70 degrees to a RANDOM side for 1.2 s, and flips side when that fails. It walks into the thing first, then wiggles left and right (which also shakes the legs, see F73).
- **Goals inside things:** roam, chat and watch spots can still be a point inside a bench, a bush, a machine or a wall (ALWAYS3 "only valid targets" is still in LEFT).

**The fix** (behind `Config.NAV_V2 = true`; server, the same code for every walker):
1. **A path for every walk, also to a moving goal.** No walker ever walks without a path when the line to its goal is not clear.
   - A goal that moves (a player, a runner's target, the Newspaper route, FirstAid) keeps ONE path and re-plans only when the goal has moved more than 4 studs from the end of that path, at most once a second per walker. Between re-plans it follows the path it has; the last waypoint is the live goal only when the line to it is clear (step 2's cast).
   - This keeps the F65 fix (Home never flips between two points), because the walker steers to its own waypoint and the systems keep setting Home as they like.
   - A short walk (under 8 studs) does the clear-line cast first and paths only if it is blocked.
2. **See the whole body, early:**
   - replace the single ray with a `Workspace:Blockcast` the size of the walking body (about 2.4 wide x 3.5 high x 1 deep, from the shins to the chest) along the heading;
   - look ahead `max(3, speed x 0.6)` studs, so a runner sees things in time;
   - ignore other ragdolls (`avoidDummies` handles them), the ground, anything with CanCollide off and the Foliage group (people walk through leaves and bushes, F54; tree trunks are solid and avoided).
3. **Choose the free side, not a random one:**
   - when the cast hits, cast the same box at 25, 50, 75 and 100 degrees to each side and take the free direction nearest to the goal;
   - keep that side for at least 0.8 s, and for as long as the thing is still beside it (hysteresis), so it never flips left and right;
   - it starts turning as soon as it sees the thing (look-ahead), so it curves round it smoothly instead of bumping and backing off.
4. **Only valid goals:** every Home goes through one function, `NavTarget.snap(point)`. If the point is inside or within 1.5 studs of a solid part, on water, lava, a belt, a flower bed or a machine floor, it moves to the nearest free walkable point: test a ring of 8 points at 2, 4 and 6 studs, using a Blockcast down plus the body-box overlap check. Cache the result per spot. The watcher spots in front of machines are checked once at map load.
5. **Touching = react at once:** a walker that wants to walk but moves at less than 30 % of its wanted speed for 0.4 s (or whose body box overlaps a solid part) steps back about 1 stud, takes the free side (step 3) and re-plans. Do not wait 1.5 s. After 3 failures it picks a new goal (as today).
6. **Moving things:** a car, the train, a bike or a player on the walker's line within 12 studs makes it stop and wait (or step aside if it is standing in the way). It goes on when the line is clear.
7. **A count, like the leg detector:** `NAV_BUMP_LOG` (Studio and Metrics), always on. A BUMP is a walker in Walking/Fleeing whose body touches a non-ground solid part that is not a ragdoll or a player. Print the part's full name and the walker's system (who set its Home). (26 Nov late: NO watch session; the owner tests, and the log tells the next session what to fix.)
8. **Cost:**
   - the cast runs at 10 Hz per walker (not every frame); the side casts run only on a hit;
   - paths stay under about 6 a second in total (as today), and the re-plans of moving goals share that budget;
   - far stand-ins without physics follow the same paths.

**Check:** follow 5 walkers each for 1 minute through busy rooms, plus 2 runners coming to you over the plaza and the roads. None walks into a tree trunk, bench, lamp, fence, machine, wall, car or kiosk. They curve round things before they reach them.

## F73 = F65 part 2: the legs still JITTER sometimes WHEN THEY TURN (owner: "deres ben hakker stadig en gang imellem når de drejer sig")
**The likely causes** (read in the code, v1155):
- **The legs do not step when the body turns on the spot.**
  - The step cycle (`Client/DummyLife.luau` `gaitPose`) is timed ONLY by how fast the pelvis moves over the ground. `amount = groundSpeed / 2.5`, so with no ground speed the legs stand still.
  - Meanwhile the server's `balance` AlignOrientation turns the whole body (`ActiveRagdoll` `updateMoving`). The feet stay planted with friction and are twisted round, stick, then slip = a short burst of jitter.
  - This happens on every turn on the spot: arriving home and turning to HomeLook (up to 5 s), a talker turning to you (LOOK AT YOU), a turn of 90 degrees or more at a corner.
- **The speed drops during a turn.** `speed = wantSpeed x facing`, so a sharp turn drops the speed to about 0 and back. The client's `groundSpeed` then rises and falls, and the step cycle fades in and out several times = the legs flicker between walking and standing.
- **The turn itself is uneven.** `rig.heading:Lerp(wantHeading, k)` on unit vectors turns slowly and then whips round near the end for a big turn, and SNAPS when the lerp passes near zero (a turn of about 180 degrees: `if heading.Magnitude < 0.05 then heading = wantHeading`). The AlignOrientation then yanks the body round in one go.
- **The way it wants to go flips left and right:** `avoidDummies` and the random detour flip the wanted direction from side to side around another ragdoll or an obstacle. The body turns back and forth several times a second, and so do the legs (F72 step 3 fixes the detour side; add the same hysteresis to `avoidDummies`: keep the passing side for 0.8 s).
- **The detector misses it:** since v1155 a jitter event needs 10 knee reversals a second AND 70 % of the frame rate. A turn twist is slower than that (a foot sticking and slipping 3-6 times a second).

**The fix** (behind `Config.TURN_STEP = true`):
1. **Turn-in-place steps** (DummyLife `gaitPose`): drive the step cycle by ground speed PLUS turning, so the legs step round when the body turns.
   - `drive = groundSpeed + 1.4 x |yawRate|`, where yawRate is the pelvis's turn speed in rad/s from its LookVector, smoothed like groundSpeed;
   - `phase += drive x dt / stride`; `amount = clamp(drive / 2.5, 0, 1)`;
   - while the body turns with little ground speed (`yawRate > 0.8` and `groundSpeed < 1.5`), use a TURN pose instead of the forward swing: short steps with the knee lifting about 25 degrees, the hip turning toward the turn about 15 degrees on the stepping leg, and little forward and back swing. Blend between the walk and turn poses over 0.15 s, never switching in one frame.
2. **Hysteresis on the cycle:** the step cycle fades in above `drive 0.6` and out only below `drive 0.3` (with a 0.2 s hold), so it never flickers on and off.
3. **An even, capped turn** (ActiveRagdoll `updateMoving`): replace the unit-vector Lerp with a yaw angle and a critically damped spring:
   - max turn speed 3.5 rad/s walking, 6 fleeing, 2.5 on the spot;
   - for a turn bigger than 160 degrees, keep the side it was already turning to, never the snap;
   - set the `balance` AlignOrientation's `MaxAngularVelocity` to the same cap, so the body never whips.
4. **Keep moving through a turn:** `speed = wantSpeed x (0.35 + 0.65 x facing)` for turns up to 120 degrees, so a corner is walked round in an arc and not stopped at. A bigger turn slows to about a third and steps round (step 1).
5. **No dragged feet:** while Standing/Walking upright, the feet have low friction (about 0.25, set once on entering those states, not every frame); back to the normal body friction on Ragdoll/Out. The pelvis is held up by `lift`, so the feet only need to touch, not grip.
6. **Arriving and turning to HomeLook:** if the way it will face at home is more than 100 degrees from its heading, it starts turning in the last 2 studs of the walk (a curved arrival), so it seldom turns on the spot. `ARRIVE_TURN_MAX` stays the safety net.
7. **LOOK AT YOU:** only the head and the chest turn up to 60 degrees; past that the whole body turns with the turn steps (step 1), at 2.5 rad/s, never a snap.
8. **The detector sees turns too** (Client/LegJitter): a TURN TWIST event is the foot's speed crossing below 0.5 and above 3 studs/s more than 4 times a second while the pelvis's yawRate is over 0.8 rad/s, for 0.3 s; or a hip twist angle over 35 degrees. Log it with the same context as the F65 events plus the yawRate, the wanted-direction flips in the last 1 s and who set Home.
9. **(26 Nov late: NO run; the owner tests.)** ~~A short turn run in Studio~~ (1-2 minutes, not a long session): stand among 8 ragdolls and walk round them in circles, so they turn to look at you; let 3 arrive home; make 2 walk round a bench. The goal is 0 TURN TWIST events. Write the counts before and after in F65's findings.

**Check:** watch ragdolls turn on the spot, turn to look at you and turn at corners. The feet step round, the legs never shake, and the body never whips round.

## F74 The STRETCH MACHINE works again, and it STRETCHES limbs long instead of pulling them off (owner: "Fiks så at tortur maskinen som trækker ragdolls lemmer af virker igen, den skal bare ikke trække dem af, bare strække dem og så give slip på ragdollen så man kan se lemmer man har forlænget er mega lange, fx. 1 ben er så langt som det er blevet strukket - det går væk igen efter 30 sekunder langsomt")
In the game it is the **STRETCHER** (the sign in `LabOwnerMap` NAMES; the prompts say "Stretch machine"). Never call it a torture machine anywhere in the game.

**Why it does not work now** (read in the code; confirm in Studio first):
- `Playground.buildRamp` builds it at `PathPlan.RAMP_AT` (the old ramp spot). `LabLayout10.STRETCH` = the plan's Machine Hall spot (245, -48, `OwnerMapPlan` ITEMS `StretchMachine`) is defined but never used.
- `StretchMachine.build` keeps the `floor` CFrame it was built at as `mc.middle` and uses it for everything:
  - `onPlatform` (is a body on the platform?);
  - `someone` (is a player within NEAR?);
  - `may` (the buttons answer only within REACH 16 of that point, and only if `Zones.mayEnter(player, Zones.plotAt(floor.Position))` passes);
  - `Lab.ownerAt`.

  If the model stands anywhere else than that point (moved by a map step, or built at an old spot under the new map), it never sees a body and none of its buttons do anything.
- **Check in Studio:** where the StretchMachine model stands vs `mc.middle`; does `Zones.plotAt` at the new spot give the player's own plot.

**The fix: it works** (behind the existing `Config.STRETCH_MACHINE`; new numbers in Config):
1. Under the owner map, build it at `LabLayout10.STRETCH`, facing the plan's `face`, with a clear platform (no trees or props on it, F53).
2. Never use the build CFrame afterwards. `mc.middle` is read from the live `mc.platform` CFrame each time (one function `middleOf(mc)`), so a later move can never break it. The same goes for `may`'s distance and plot checks.
3. Every prompt (green "Pull all four", red "Release", each claw) works on a phone (ProximityPrompt, `RequiresLineOfSight` false, a clear tap target) and on a PC (E).
4. Its watcher (the ragdoll at every machine) and the TRY lesson put a ragdoll on the platform, as at the other machines.

**The fix: it STRETCHES, it never tears** (behind `Config.STRETCH_LONG = true`):
1. **Remove the tear:**
   - no `tear()`, no `VitalsService.sever`, no BREAK / BREAK_TIME;
   - a joint never gives way here (severing stays off in the whole game).
2. **The limb grows while it is pulled** (like rubber, the MACHINES_10 3.19 idea):
   - each claw's limb chain (arm: UpperArm + LowerArm; leg: UpperLeg + LowerLeg; the hand or foot keeps its size) gets the length the claw has pulled it to: `factor = distance(shoulder or hip joint, claw) / the limb's rest length`, clamped 1 to `STRETCH_MAX = 3.2`;
   - raise `TRAVEL` so a leg can reach 3x (about 9 studs);
   - the tension stays small, because the limb follows the claw. At the max the winch stops with a "MAX!" pop and the creak sound peaks;
   - the stretch % on the panel and in the words is the score (MACHINES_10 3.19).
3. **How to make a limb long** (server, one function `Stretch.setLimb(model, limb, factor)` in a new module `Shared/Ragdoll/Stretch.luau`):
   - **grow the parts:** multiply the part's Size on its long axis (Y for R15 limbs);
   - **keep the joints joined:** multiply on the same axis every Attachment position on that part (the BallSocket, AnimationConstraint and rig attachments), and the C0 (Part0 = the part) or C1 (Part1 = the part) position of every Motor6D on it. Always scale from the ORIGINAL values, stored once per part, never from the current ones, so nothing creeps;
   - **keep the weight:** divide the density by the factor (the same mass, so the body does not tip or sink);
   - **step it:** change the size in steps of at least 0.04 and at most 10 times a second, so the solver never jolts;
   - **the X-ray bones of that limb stretch too** (their parts or meshes follow the limb's factor), so in X-ray you see a long thin bone.
4. **Release** (the red button, or all claws at max, or `MAX_TIME`):
   - the claws open and the body drops with a SPROING and a small bounce (MACHINES_10 3.19), lands, lies a moment, then gets up and walks away with its long limbs;
   - **one long leg:** the ragdoll stands on its normal leg (the stand height of the shortest leg). The long leg is floppy (its tone about 0.25) and drags along like a noodle, with low foot friction;
   - **both legs long:** it walks tall on stilts (the stand height of the shorter long leg), slowly, wobbling;
   - **long arms:** they hang down to the ground and drag along;
   - the tilt guard (`TRIP_DEG`) must not knock it down just because a leg is long: measure the tilt from the trunk.
5. **It goes back slowly:**
   - **full length for `STRETCH_HOLD = 30` s after the release;**
   - then it shrinks back to normal smoothly over `STRETCH_SHRINK = 10` s (eased out), at 10 Hz in steps.

   The timer keeps running through a knockout and a revive. The doctor's heal (L) shrinks it back over 2 s. Stretching it again starts from the length it has now. A pooled ragdoll is always reset to normal before it is reused (`RAGDOLL_DIRECTOR.md`).
6. **The same everywhere:**
   - the sizes are set on the server and replicate, so every player sees the long limbs;
   - the client's DummyLife walk animation keeps working, because the joints stay joined (step 3);
   - only one stretched body is resized at a time per machine. It costs nothing when nobody uses it.
7. **Kid-friendly:** cartoon rubber, a boing sound, the purple-cartoon rule; no pain sounds and no tearing.

**Check:** on the phone and on the PC:
- put a ragdoll on the STRETCHER and press the green button: the arms and legs grow long as the claws go out, and stop at MAX;
- press release: it bounces off, gets up and walks away with a long noodle leg (or on stilts);
- in X-ray the bone is long too;
- after 30 s the limbs shrink back slowly; no limb ever comes off.

## F75 The MOTORBIKE is stuck IN THE BIKE RACK (owner: "Fiks så motorcyklen ikke er stuck", screenshot: the rider sits on the dirt bike between the rack's bars, the rail across its front, by the "P BIKES" sign)
**The cause (found in the code):** the motorbike's home pad is the bike rack itself:
- `LabLayout10.CARS.Bike = V(-235, 95) -- the BikeRack` is the exact middle of `OwnerMapPlan` ITEMS `BikeRack` (-235, 95);
- `LabOwnerMap` builds the rack there: 7 solid `BikeRackBar`s 3.6 studs apart and a solid `BikeRackRail` 26 long at 2.4 high;
- so the bike (2.4 x 1.6 x 6.4) is placed among the bars under the rail. The ragdoll gets on there (BikeService takes the bike only when it stands within 6 studs of its home) and can never ride out.

Also, `BikeService.nextSpot` still drives circles 40-84 studs round the LAB ORIGIN (the spawn circle, with the old lab's limits `|lx| > 92`, `lz > 44`, `lz < -84`). On the new map that is across the grass and through the tree belts, far from the car park: it gets stuck again as soon as it is out.

**The fix** (do it together with F69, which is the same machine; `Config.BIKE_FIX = true`):
1. **A free parking bay for the motorbike next to the rack, never in it:**
   - a painted bay on the paved apron in front of the rack (south side), beside where the inner path lands, about 12 studs east of the rack's middle;
   - facing the path, with nothing solid within 4 studs;
   - set `LabLayout10.CARS.Bike` there.
2. **A guard for every vehicle home** (Bike, Car, Truck, MuscleCar and the new ones in F76): at build, `VehicleService.homeClear(kind)` does a `GetPartBoundsInBox` with the vehicle's body plus 1.5 studs.
   - If anything solid is there (except the floor), it slides the pad along the bay row to the nearest clear spot and warns in the output.
   - Add the same check to the masterplan lint: no vehicle pad inside an ITEM.
3. **The rack holds bicycles:** the cyclist's pedal bicycle (`LIFE_IDLE.md` 2) and decorative ones. A rider takes a bicycle out by walking it backward 3 studs out of its slot before getting on, never riding out through the rail.
4. **The motorbike rides the roads (F69):** replace `nextSpot`'s spawn-circle with F69's route on the road centre lines from `OwnerMapPlan` ROADS, starting from the car-park road. Add F69's stuck guard: back up, re-route; get off and walk away after 6 s; the bike goes home only out of view.
5. **Check:** watch the car park from the start. The rider gets on in the bay, rides out onto the road and does full loops of the map without stopping in a rack, a fence or a tree belt.

## F76 VEHICLES IN FRONT OF THE ENTRANCE: one FREE bicycle and cool PAID vehicles from the Creator Store, with cool features (owner: "Tilføj køretøjer herud foran indgangen, en gratis cykel og så ellers betalte fede køretøjer fra creator store, gerne med fede scripts", screenshot: the welcome arch and the wide path out to the fountain junction, grass with flower beds on both sides)
**Where:**
- a VEHICLE ROW just outside the welcome arch, on the grass beside the path between the arch and the fountain junction (the side with more room; both sides if 8 bays do not fit on one);
- the bays are angled about 45 degrees toward the path (a herringbone), so every vehicle is seen as you walk out of the spawn;
- the bays are paved (the same slab as the paths), with painted lines; the flower beds in that strip move or go;
- clear of the arch (12 studs, F53's clear zones), of the path itself and of the fountain;
- add it to `tools/masterplan.py` as an ITEM (`EntranceVehicles`, zone SpawnPlaza approach) with its bays, re-run the plan and the lint (0), and take the pads (`LabLayout10.CARS`) from it.

**What stands there (8 bays):**
1. **FREE: a BICYCLE** (a pedal bike; "cykel"):
   - a real rigged bicycle from the Creator Store;
   - your legs pedal (a pedal animation tied to the speed), with a bell on the horn button;
   - anyone can ride it;
   - a new kind `Bicycle` in VehicleService, free (`FREE = { Bicycle = true, Bike = true }`: the dirt bike the ragdoll rides stays free, as the owner said on 24 Nov).
2. **The paid vehicles we have:** the Silvia drift car (pass 2092302232), the Panzer tank (pass 2093220108) and the Ford truck.
   - The code notes its pass 2092632252, but it is set to free today. The owner now wants only the bicycle free, so use that pass if `MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass)` says it is for sale; else keep it free and ask.
   - They move here from the Crash Yard's CarBays (the CarBays stay painted, as parking).
3. **NEW cool paid vehicles from the Creator Store** (5, each with its own feature, fitting a ragdoll game, kid-friendly):
   - **Monster truck:** huge wheels, drives over ragdolls and bounces, a JUMP button;
   - **Go-kart:** low and fast, a BOOST button with exhaust flames;
   - **Police car:** a SIREN button with flashing lights and the siren sound; ragdolls near it put their hands up;
   - **Fire truck:** a WATER CANNON button that sprays a water jet, pushing ragdolls over and making them wet (water drips; no harm, the purple rule);
   - **Bulldozer:** the blade pushes ragdolls and crates in a heap; a BLADE up/down button.

   Find them yourself (rigged, good-looking, one matching realistic-cartoon style, wheels named or easy to map). Keep only the model (the malware pass).
4. **The features ("fede scripts"), safely:**
   - Build every feature in OUR code: VehicleService / VehicleFeel plus one `Net` remote `VehicleAction` with a whitelist (`Horn`, `Lights`, `Siren`, `Boost`, `Jump`, `Spray`, `Blade`, `Bell`), validated (the player is the driver of that vehicle, the action exists for that kind) and rate-limited.
   - Do NOT run the model's own scripts. Read them for ideas (sounds, lights, particle effects, numbers) and copy the look.
   - **If a model's chassis script is truly needed**, it must pass the security check before it may run. It must NOT contain:
     - `require(<number>)`, `loadstring`, `getfenv`/`setfenv`, or obfuscated or encoded strings;
     - HttpService, InsertService, TeleportService, MarketplaceService, DataStore, chat or `Kick` calls;
     - a remote that takes a CFrame, a force or a player from the client without checks.

     Write the result per vehicle in this section. (The owner allowed this for the F1 car earlier, with the same check.)
5. **Buying:**
   - each bay has a low plaque on the ground at its front (the no-billboard rule) with the vehicle's name and FREE, the price with the Robux icon, or OWNED;
   - tap the vehicle or its prompt (big on a phone): owned or free = DRIVE; not owned = the game-pass prompt;
   - after a purchase you drive at once.
6. **Game passes:** the owner creates them on the Creator Hub and sends the ids (CLAUDE.md "Money").
   - **Until an id arrives,** that vehicle stands in its bay with a "SOON" plaque and cannot be driven. It is never free by mistake: change the rule "0 = free" to "0 = SOON" for every kind not in `FREE`.
   - Suggested prices (questions for the owner): go-kart 49, police car 99, monster truck 149, bulldozer 149, fire truck 199 Robux.
7. **Phone first:**
   - while you drive, the vehicle's feature is ONE extra big touch button next to the drive controls (max 2 extra buttons: BOOST or JUMP, and the special); no key letters on a phone (F70);
   - PC keys: Shift boost, Space jump, H horn or siren, F the special; gamepad: the face buttons.
8. **No lag:**
   - each vehicle under about 500 parts and 40k triangles;
   - the body details CollisionFidelity Box or Hull, small parts CastShadow off;
   - lights only while driven and only within 140 studs (lamp lint);
   - sounds pooled; particle effects capped on phones.

   The parked vehicles in the row are anchored and do nothing until someone drives one.
9. **Return:** a vehicle left alone goes back to its bay only when no player can see it (never vanish in view); a vehicle in use leaves its bay empty, with the painted lines.

**Check:** walk out of the spawn. The row of vehicles is right there by the path.
- **Phone:** tap the bicycle and ride it (the legs pedal, the bell rings). Tap a paid one: the pass prompt (or SOON).
- **PC:** the same with keys.
- **Every feature:** jump, boost, siren, water cannon (ragdolls go over) and blade (pushes ragdolls).
- The FPS at the spawn does not drop.

## F77 The #1 STATUES at the leaderboards FLOAT in the air and are all GOLD (owner: "Fiks så de ikke flyver i luften og de ikke bare er guld men man kan se deres skin ordentligt", screenshot: VIP TAKEDOWNS and VIP TIME PLAYED, a gold figure hanging in front of each board's list, above its plinth "#1 axelinin1920")
**The causes (found in `LabOwnerMap.luau` `statueOf` and the #1 loop):**
- **It floats:** `statueOf` pivots the rig to `at + size.Y / 2`. The pivot is the HumanoidRootPart (at the hips), not the bounding box's middle, and the box is taller than the body because of the raised VICTORY arms and the accessories (hats, hair, wings). So the feet end up several studs above the plinth.
- **It is gold:** `statueOf` paints every part GOLD with Foil, removes every texture, decal, Shirt, Pants, ShirtGraphic and SurfaceAppearance, so no skin, face or clothes show.
- **It hides the list:** the plinth stands at the board's middle 7 studs in front, so the statue stands in front of the names.

**The fix** (`Config.STATUE_SKIN = true`):
1. **The real avatar:**
   - for the #1 statues, keep the player's real look: colours, face, clothes (Shirt, Pants, ShirtGraphic, layered clothing), textures, SurfaceAppearance and accessories;
   - remove only scripts (and the Animate script, as now);
   - the stone statues at the stair foot keep their stone look (`statueOf` takes a `keepSkin` flag).
2. **Feet on the plinth:**
   - after posing, find the lowest point of the rig's feet (LeftFoot and RightFoot: their CFrame and size, the bottom face), and move the rig down or up by exactly that much, so the soles touch the plinth top;
   - never use the bounding box to place it;
   - anchor the root, keep the joints (as now).
3. **Size:** if the avatar (with accessories) is taller than 7 studs or wider than 5, `Model:ScaleTo` it down to fit.
4. **Beside the board, not in front of the names:** move each plinth to the board's side (its right edge + 3 studs), with the statue facing south like the boards and turned about 15 degrees toward the path. The name plaque stays on the plinth's front.
5. **Still special:** the plinth gets a gold top edge (a thin gold trim, Metal) and the plaque "#1 name" in gold, so it reads as the winner without painting the player gold. The board itself stays as is.
6. **The empty case:** no #1 yet = the plain grey lab ragdoll on the plinth, the plaque "#1 COULD BE YOU" (as now). The owner and admins never stand there (F61).
7. **Check:** both VIP boards and the normal boards: each #1 stands ON its plinth beside the board, in their own skin and clothes, and no statue covers a board's names.

## F78 REAL WATER: the aquarium, the croc pond and every pool; ragdolls SWIM or DROWN (owner: "Hajen er nede i concrete i akvariet. Og der sker ikke noget hvis man kaster en derned og det ligner ikke der er vand, ragdollen skal svømme eller drukne", and "vandpøl over landet med sten"; screenshots: an empty concrete basin with dark corner posts and a "SURPRISE! MOON GRAVITY" banner; the croc pond as a flat teal disc on the grass, flat crocodiles, round grey balls for stones)
**The causes (found in the code):**
- **The shark is in the concrete:**
  - the SHARK TANK creature (`LabCreatures` ~860) builds its OWN sand floor (`SharkTankFloor`) and a 1-stud `SharkTankWater` at `LabLayout10.CREATURES.Whale`, at ground level, and pushes the shark 0.7 under that surface;
  - the aquarium (`LabOwnerMap` northRow) stands on a 3-stud concrete `AquaBase`;
  - so the shark, its floor and its thin water are all INSIDE the concrete base.
- **No water:**
  - the aquarium's `AquaWater` is a Glass part (0.45 transparent, no collision); it is not water for the physics;
  - in the owner's screenshot neither the water nor the glass walls show at all. Check in Studio whether `AquaWater` / `AquaGlass` exist and why they are hidden (a HIDE list, LagGuard, streaming, F68's "water" switch, or a cleanup step);
  - the croc pond is a 0.6-stud teal cylinder lying ON the grass (`CrocWater`), and the pool a 0.4-stud glass sheet. Nothing anywhere is real water, so a ragdoll thrown in just lies on the floor.

**The fix** (behind `Config.REAL_WATER = true`):
1. **Every water body is REAL TERRAIN WATER in a real basin:**
   - the aquarium, the croc pond, the big pool, the lounge pool (and the fountains if they are cheap enough);
   - fill each with `Terrain:FillBlock` / `FillCylinder` (`Enum.Material.Water`); this gives the water look, the underwater view, player swimming and part buoyancy for free;
   - set the terrain water once: clear blue-green, `WaterTransparency` about 0.6 (the shark and the fish show), small waves (`WaterWaveSize` 0.05), `WaterReflectance` about 0.4;
   - terrain voxels are 4 studs: put every basin on the 4-stud grid (inner sizes and floors in multiples of 4), so no water pokes through a glass wall or a rim. Look at each from all 4 sides;
   - remove the fake water parts (`AquaWater`, `CrocWater`, `PoolWater`, `SharkTankWater`, `SharkTankFloor` when inside the aquarium).
2. **The AQUARIUM:**
   - the glass tank on its base, filled with water to 2 studs under the rim;
   - a sand floor, rocks, swaying seaweed (client), coral, small fish schools (client-only, cheap), bubbles from an air stone;
   - **the shark swims laps INSIDE the tank at mid-depth.** Its height comes from the aquarium's floor and water surface (not the old shallow pool), and it turns smoothly at the ends;
   - **a feeding platform:** stairs or a ladder up the side to a platform with a rail over the water, so you can carry a ragdoll up and THROW IT IN (and drop one in from the platform);
   - the shark notices a body in the water and comes for it: the existing feed move (lunge, grab, shake, spit it out). Kid-friendly: a purple cartoon cloud, no limbs off;
   - a ragdoll that is not taken swims to the inside ladder and climbs out (step 4), or drowns if it cannot.
   - Fix F33 at the same time: at least 6 studs clear on every side, the lint 0.
3. **The CROC POND: a real sunken pond, not a disc:**
   - dig it into the ground: about 60 across, 8 deep in the middle, with sloped muddy banks (Terrain Mud and Sand) and the water 1 stud under the grass;
   - reeds and lily pads;
   - natural rocks half buried (Terrain Rock or Creator Store rock models, irregular), never round grey balls;
   - the crocodiles swim slowly with only their eyes and backs above the water, and one suns itself on the bank;
   - a ragdoll in the water: a croc goes for it (a death roll: it spins it, then lets go; no limbs off).
   - The speaker wall south of the pond stays (it is from the owner's old map), but looks like a real speaker stack: grille texture, a brand plate, small LEDs.
   - The cave yard's round `YardStone` balls become natural rocks the same way (F79).
4. **Ragdolls in water: a SWIM state** (`ActiveRagdoll`, server; animation in `DummyLife`):
   - **Detect:** the pelvis inside a water box. Every water body registers its box (CollectionService tag `WaterVolume`); the point-in-box test runs at 5 Hz per ragdoll near water only.
   - **Splash:** on entry, a splash (particles plus a sound scaled by speed) and ripples; the first second is panicky splashing with the arms flailing, and a bubble line ("Help!", "I can't swim!", "Cold!"; `TalkLines` water lines).
   - **Swim:**
     - a living, awake ragdoll in water deeper than its chest keeps its head above the surface (the lift holds the head 0.6 over it), the body tilted about 30 degrees;
     - front-crawl arms and a flutter kick while moving; treading water (slow arm sweeps) while still;
     - it swims to the nearest exit (pool steps, a ladder, the pond bank) and CLIMBS OUT: hands on the edge, pull up, a knee up, stand;
     - then it shakes off (water drips for 20 s, slightly darker clothes).
   - **Drown (kid-friendly, a cartoon):** if it is knocked out, held under (shark, croc, a grab), or cannot reach an exit within 25 s, it tires:
     - its head dips and bubbles rise;
     - after 6 s under it is knocked out: eyes closed, `Vital` Unconscious;
     - it floats face down at the surface, drifting.
   - **The rescue:** pull it out (grab) and do CPR (F15): it coughs up a splash of water and wakes. If nobody helps, it wakes after the normal knockout time and swims out.
   - **Bodies float:** a knocked-out or limp body floats (density about 0.9 of water), bobs and drifts slowly. It never sinks through the floor and never skates on top (the RAGDOLL_FEEL water bar).
   - **Players** swim with Roblox's own swimming in terrain water, as everywhere.
5. **Cost:** terrain water costs little; the water checks run only for ragdolls within 10 studs of a water box; the particles are capped on phones (the splash max 20 particles, the drips off beyond 60 studs).
6. **F68** (remove the water button; water always on) is solved by this: terrain water is always there. Remove any old water switch you find.

**Check:**
- **phone and PC:** look at the aquarium. Clear water to the rim; the shark swims inside, never in the concrete;
- carry a ragdoll up the platform and throw it in: a splash; it swims and panics; the shark takes it, or it climbs out. Hold one under (or let the shark grab it): bubbles, then it floats knocked out; pull it out and do CPR: it coughs and wakes;
- the croc pond is a real pond with banks, and a ragdoll thrown in swims; a croc goes for it;
- the big pool: bodies float and bob.

## F79 The BEAR CAVE is a grey ball and a loose black slab (owner: "Hulen er også bare en cirkel med en masse og en sort flad væk der ikke hænger sammen", screenshot: a huge grey sphere, a black flat panel standing in front of it, round grey stone balls on a dirt yard, the bear on the path)
**The cause:** `LabOwnerMap` northRow builds the cave from two `CaveRock` BALL parts (110 x 70 x 90 and 70 x 52 x 60), a flat black `CaveMouth` block (26 x 22 x 3) standing in front of them, and 26 round `YardStone` balls. F36's "real cave mouth" was never built.

**The fix** (behind `Config.CAVE_V2 = true`; this replaces F36's cave part; F36's bear animations stay):
1. **A rock hill from terrain, joined to the ground:**
   - Terrain Rock and Slate (some Basalt) sculpted from several overlapping irregular shapes (`FillBall`, rotated `FillBlock`, `FillWedge`), with Grass and Ground on its top and sides, so it grows out of the land with no seam;
   - moss patches, a few bushes and a tree on top, roots hanging over the mouth.
2. **A real opening carved INTO it:**
   - `FillBlock` / `FillBall` with Air: an arch about 22 wide and 18 high, a tunnel going in and turning, and a chamber about 30 deep;
   - the inside goes dark by itself, deeper in. Add a soft dark gradient at the back (a part with a black-to-clear Decal, only visible from the front) and two glinting eyes (small Neon dots that blink every few seconds) when the bear is not out;
   - the bear sleeps inside sometimes (F36 states).
3. **Remove:** the `CaveRock` balls and the `CaveMouth` slab.
4. **A Creator Store cave instead:** only if one looks clearly better and real (rock with a hollow inside, a clean license, the malware pass), sized to the plan's `CaveBear` box. Terrain is the default: cheap, natural, and it joins the ground.
5. **The yard:**
   - dirt (Terrain Ground) with natural half-buried rocks (no round balls), a fallen log, and a tree stump the bear scratches against (F36);
   - a low natural rock line round the yard keeps the bear in, with the path entering through a gap;
   - the bear walks its yard and comes to the edge, but does not walk out along the path (it turns back at the gap).
6. **Lint:**
   - the terrain never covers a path, a lamp or a sign (`onPath` check before every fill; the plan's path into the yard stays clear and walkable to the mouth);
   - nothing else stands inside the hill.
7. **Cost:** terrain carving runs once when the map is built; no extra parts, except the decal, the eyes and the props.

**Check:** walk up the path to the cave. A natural rock hill with a dark opening you can walk into; the bear in its yard; no ball, no floating black panel, no round stones.

## F80 A BACK TO SPAWN button in MORE (owner: "Lav en back to spawn knap i more")
- **Where:** the MORE menu (the gear, F63; `Client/HudMenu.luau` entries), near the top, with a home icon (DrawnIcons) and the text "BACK TO SPAWN". It is in the menu on every device; on a phone it is one of the first rows.
- **What it does:**
  1. the screen fades to black for 0.25 s;
  2. you stand at the spawn, on a free spot (a random spot in a small ring on the spawn plaza, so two players never land on each other), facing down the boulevard;
  3. the screen fades back in.
- **Safe:**
  - one `Net` remote `Teleport.Spawn` (no arguments), validated on the server: a 5 s cooldown;
  - not while you are being carried, in a machine, or in a ragdolled fall (it waits until you stand, then goes);
  - out of a vehicle first (the vehicle stays where it was and goes home only out of view);
  - a held ragdoll is dropped where you stood;
  - the server chooses the spot.
- **Both places:** in the multiplayer place it takes you to that place's spawn.
- **Check:** phone and PC: walk far away, open MORE, tap BACK TO SPAWN. A short fade, and you stand at the spawn. Tapping it twice fast does not teleport twice.

## F81 TRY: a ragdoll comes and JUMPS INTO the machine by itself (owner: "Gør så når man trykker TRY ved en kanon fx. at dukken automatisk spawn og hopper ind i kanonen")
**Today:** TRY (`Lab.luau` ~1018, FIRST_2_MIN) calls the nearest free ragdoll, which runs to you and waits (`TryFor` for 20 s), so you must grab it and carry it to the machine yourself.

**New** (behind `Config.TRY_AUTO = true`, every machine):
1. **TRY = it happens by itself.** Within 1-2 s of the tap, a ragdoll is at the machine and gets in.
   - First choice: the machine's watcher, or the nearest free ragdoll within 15 studs of the machine. It runs straight to the machine.
   - Else: one POPS OUT of a small **RAGDOLL DISPENSER** next to the machine:
     - a short metal tube or hatch, the same at every machine, beside its plinth;
     - a hiss, a puff of smoke, and a pooled ragdoll pops up out of it, standing;
     - this is the one place a ragdoll may appear in view on purpose, because the tube makes it a show, not a pop-in.
2. **It gets in, by the machine's own move** (one `hopIn(machine, ragdoll)` per machine kind, from a list):
   - **the cannon:** a run-up, a big jump in an arc into the muzzle, and it slides in (F7's muzzle load); then a 3-2-1 on the barrel and BOOM;
   - **the washer:** in through the door (the owner's earlier wish), the door shuts, the spin;
   - **the shredder or sweeper pit:** it jumps in;
   - **the press, the stretcher, the gyro cage:** it climbs on or lies down on its spot, and the machine starts;
   - **the trampoline and the launch pads:** it jumps on;
   - **the tesla coil:** it walks into the zap ring;
   - **the boxing ring:** two climb in;
   - **the aquarium:** it runs up the platform and dives in (F78);
   - **the croc pond:** it wades in;
   - **the bear cave:** it walks up to the bear;
   - **the wrecking ball and the crash wall:** it stands on the X.
   - A machine with no move yet uses "walk to the machine's load spot, then the machine's normal start".
3. **The machine runs by itself** once the ragdoll is in. You just watch, and the camera does not move.
4. **Rules kept:**
   - TRY only once per machine (F1);
   - the TRY reward and `Tried_<kind>` as now;
   - the try ragdoll is marked `TryFor` while it does this, so no other system takes it;
   - a second TRY tap while one is on its way does nothing.
5. **Grabbing:** TRY no longer teaches grabbing. The first time a player has tried a machine, one small tip shows once: "Tip: you can grab ragdolls and throw them in yourself". On a phone it is a short toast with no key letters.
6. **Check:** phone and PC: at the cannon, tap TRY. A ragdoll runs (or pops out of the tube), jumps into the cannon, 3-2-1, BOOM. The same at the washer (through the door), the shredder and the trampoline.

## F82 RANDOM THINGS ON THE PATHS and OVERLAPPING "SHADOWS" in the paths (owner: "Sådan noget som en random grøn kasse på stien og flere forskellige skygger der overlapper hinanden eller jeg ved ikke hvad det er i stien"; screenshots: a plain green cube standing on a path tile (it takes bullet holes); the path floor with lighter and darker rectangles overlapping)
**The green box:**
- **Find out what it is:** its full name and parent (a hedge cut down by a clear step, a leftover crate or bin, a test part, a FoliagePass block?). Write it here.
- Remove it, and every other thing standing on a walkable surface that is not allowed there.
- **A PATH LINT** (`tools`/Studio command, also run by the map build), which lists every part whose box overlaps a road, path or plaza footprint (from `OwnerMapPlan`) above the walking surface:
  - **allowed:** the slabs, kerbs, junction pads, fountains placed by the plan, and benches, bins and lamps beside the path (2 studs outside, F40);
  - **not allowed:** everything else (boxes, crates, bushes, hedges, rocks, signs, leftover parts).
- The count must be 0.

**The "shadows" (light and dark rectangles in the path):**
- **Likely causes:**
  - several walkable slabs on top of each other at almost the same height (the old LAB10 walkways and Paths hidden only by transparency, plan legs AND junction pads overlapping, the old grid paths, the zone pads), which z-fight and show as patches of different shades;
  - half-transparent parts lying on the path (hidden-but-not-removed parts at Transparency 0.7-0.95, guide rings, zone pads, `HIDE_IN_LAB` parts made see-through);
  - decals or SurfaceGuis on the path;
  - overlapping tree-canopy shadows (normal, and not a bug).
- **Fix:**
  - exactly ONE walkable slab per spot: one part per leg and one pad per junction (F50's rule), never two at the same height;
  - the old hidden walkways and pads are DELETED (the backup of the place is the saved version), not made transparent; or, if code needs them, moved under the ground with CanCollide off;
  - no half-transparent parts on or just above any path;
  - add both to the PATH LINT: overlapping walkable slabs within 0.3 studs of height = an error, and any part with 0 < Transparency < 1 within 1 stud above a path = an error.
- This is part of F50 (PATHS to 9/10). Do it at the same time.
- **Check:** walk the boulevard and 3 inner paths, and look at the floor from above. One clean even surface, no patches or flickering squares, nothing standing on it. The lint reports 0.

## F83 NO extra walk or run speed at all: back to Roblox's standard (owner, 26 Nov late: "Fjern hastighed på gå og løbe helt igen også fra standard")
This replaces F51 (NORMAL 30, sprint about 50), F38 (the Walk speed setting) and LAB_TARGET's MOVE_FAST.
- **Walking:** everyone walks at Roblox's standard speed, `WalkSpeed` 16. Put it back in the place's `StarterPlayer.CharacterWalkSpeed` and in every script that sets WalkSpeed (Sprint, Settings, the weapon slow-down keeps its x0.84 of 16).
- **Running:** no extra running speed. Remove the sprint completely:
  - the RUN button on phones;
  - Shift on PC and the stick press on a pad;
  - the run FOV widening and the sprint dust.

  Turn them off behind `Config.NO_SPEED = true`, so they can come back with one switch.
- **Settings:** remove the "Walk speed" option (NORMAL / FAST / VERY FAST / CALM) and ignore any saved choice (do not delete the saved value; just do not use it).
- **The server's speed checks** (anti-cheat, `Sprint` clamps): the max allowed is 16 (plus the usual tolerance), so nobody can be faster.
- **Not changed:** the ragdolls' own walking and running (Pace), vehicles, launch pads, the trampoline and the cannon.
- **The question in NOW.md** ("Gangfart: skal NORMAL ned fra 30 til ca. 22?") is answered: 16, no setting. Remove it.
- **Check (the owner):** walking speed is the normal Roblox speed on phone and PC; there is no RUN button, Shift does nothing, and Settings has no walk speed option.

## F84 REMOVE every attraction NAME SIGN (owner, 26 Nov late: "Fjern alle der her skilte", screenshot: the green "SANDCASTLE", "GIANT FAN" and "TESLA COIL" boards on 2 wooden posts)
- **Remove ALL the name signs:**
  - the `signV2` boards and their posts (F39), the old `nameSign` boards, the courtyard signposts with arms, and the "IN HERE" boards;
  - every one in the lab, delete them (do not hide them: no see-through leftovers, F82);
  - turn off the code that builds them (`Config.NAME_SIGNS = false`), so M4's rebuild never makes them again.
- **Kept:** the leaderboards and their plaques (F77), the TRY dispensers, the vehicle row's ground plaques (F76: low, on the ground, not boards on posts), and the machine buttons and panels.
- This overrides F39 and the M4 table's "Name sign" row.
- **Check (the owner):** no name boards anywhere in the lab.

## F85 The FACES (heads) spin round when ragdolls run (owner, 26 Nov late: "fiks så ansigterne ikke drejer rundt når de løber hvis de løber og bugger")
**The cause (found in `Client/DummyLife.luau`):**
- the head turns are worked out with `atan2`, which jumps from +180 to -180 degrees when the target is BEHIND the body;
- LOOK AT YOU (`neckYaw = clamp(yaw, -70, 70)`, ~1546) and the turn to a bang (`clamp(..., -75, 75)`, ~512) then flip between +70 and -70 every frame when you or the noise are behind a running ragdoll, so the head whips from one side to the other: the "spinning face";
- several systems also write the Neck in the same frame (the gait ~401-498, the noise look ~516, the moods ~815-839, look-at ~1569, ClipGait's Head).

**The fix** (`Config.NECK_SAFE = true`):
1. **No look behind:** if the target is more than about 100 degrees from where the chest faces, do not look at it; ease the head back to forward. In between, use hysteresis: start looking at under 90, stop at over 110.
2. **No look while running:** in Fleeing, a run (Pace 1.5 or more) or a sprint, the head faces forward with only the gait's small bob. LOOK AT YOU and the bang turn only happen standing or walking slowly.
3. **Smooth turning:** the neck's yaw and pitch move toward their target at most about 4 rad/s (a damped spring), never set straight to a new value, so it can never jump.
4. **ONE owner of the Neck per frame:** a small priority list, the highest wins and blends:
   - hit reaction;
   - mood pose (CPR, mourn);
   - talk look;
   - bang look;
   - the walk clip / gait.

   Every other system only asks for its look; it never writes `Neck.Transform` itself. The same rule for the Waist.
5. **Check (the owner):** run past ragdolls and make them run from you; their heads face forward and never spin.

## F86 The LEGS still jitter while a ragdoll gives CPR (owner, 26 Nov late: "Benene bugger STADIG når de giver cpr fx")
**The likely cause** (read the code): during a mood (CPR or mourn, `Server/Mourning` sets Mood and the pose; `DummyLife` moods ~815-839), the body is in a standing or walking state, so:
- the server's `lift` still holds the pelvis at STANDING height and the `balance` keeps it upright, while the mood pose bends the legs into a kneel, and the legs fight the lift;
- the client's gait or clip still runs on the legs, from the ground-speed noise of the pumping arms;
- each CPR pump jolts the pelvis, the ground speed blips, and the walk cycle starts and stops.

**The fix** (`Config.MOOD_LEGS = true`):
1. **A real KNEEL state for moods** (CPR, mourn, kneel by a body, the burial dig) in `ActiveRagdoll`:
   - the lift's target drops to kneeling height (the knee on the ground);
   - the balance keeps the trunk at the mood's angle;
   - the drive is zero;
   - the feet and knees get high friction, so they do not slide.
2. **The mood OWNS the legs:** while a mood runs, no gait, no clip, no foot IK, no turn steps and no walk cycle on the legs (the F85 priority list: the mood wins). Only the arms and the head animate (the pumping, the bowed head).
3. **Blend in and out:** kneel down over about 0.5 s and stand up over about 0.6 s with the get-up's motor blend (RAGDOLL_FEEL), never a snap.
4. **The leg detector** (`LEG_JITTER_LOG`) also logs the Mood, so any jitter left in a mood is named in the log for the next session.
5. **Check (the owner):** watch a ragdoll give CPR and one mourn: kneeling still, the legs calm, only the arms and head move.

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
