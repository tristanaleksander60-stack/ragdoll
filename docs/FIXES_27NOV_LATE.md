# FIXES 27 Nov late (owner, while testing): do these FIRST, in this order, as ONE batch where files overlap

## 0. Cloud code already written (push into Studio, ONE quick Play)
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
