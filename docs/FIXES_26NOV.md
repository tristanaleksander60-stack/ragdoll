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

## Answers to Claude Code's questions (owner direction or safe default)
- **X-RAY key:** I is fine (B is Build). Phone: a small X-RAY toggle button.
- **The big map (step 7):** YES, do it now.
- **The robot dog:** NO. A German Shepherd (F10).
- **Wheelchair:** yes, get one from the Creator Store (malware pass).
- **The long goal after all weapons:** ranks with prizes first (the simplest for kids); collections and upgrades later.
