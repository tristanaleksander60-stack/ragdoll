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
