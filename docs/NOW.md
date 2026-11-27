# ⚠⚠ FIRST OF ALL (27 Nov late): `docs/FIXES_27NOV_LATE.md` 0-7. Cloud code to push into Studio: Client/BodyCard.luau, Client/SmoothBody.luau, Client/LabGuideClient.luau (DROP_HERE_V2: a fixed on-screen size, the one nearest machine within 40 studs, no flicker), Systems/Lab.luau, Systems/RagdollDirector.luau, Systems/VehicleService.luau (no white sedan on the new kinds, SOON says "Coming soon"), Shared/Config.luau (also: `ADVENT` is declared twice in Config, lines ~360 and ~574; keep one).
# ⚠ OWNER (27 Nov late): "næste gang jeg ser på min computer skal jeg have et færdig spil, ikke noget 5/10". Read OVERVIEW "THE FINISH LINE" and follow it for the rest of the run. First: `RAGDOLL_10.md` A2 (X-ray only on the shot limb, 2 s + a 1 s fade; the whole v6 mesh must never turn to glass from one limb). A2 DONE v1343 (the mesh is glass only with the toggle; a shot limb glows alone, 2 s + 1 s fade). Round-head accessories DONE v1344 (anything welded on above the old head's middle is lifted to the round head's top, on this screen; no hats were on at the check, December hats will show it). Head balance: no change needed (the round head is a massless look; the physics head and its mass are the same). Ride grips: one server sample showed a "Ride" body 398 studs from its saddle (likely a hidden other lab, gone a moment later): OWNER CHECK on the bike.
# PHYSICS_DEEP DONE (27 Nov late, v1328-v1334): every probe goal met or close (standing still 0.000-0.025 studs in 10 s, no self-contact, no state flapping, no bounce off kerbs, 87% of walks on a path, run form, gun back-off once). The owner tests it (PHYSICS_DEEP "Check"). Then go on with the next rows.
# OWNER'S v6 TEST (27 Nov late): A (X-ray 3 in a row / 3 s, the torso bug) DONE v1327; C (round grey head with the face) DONE v1327; D measured upright with the arms down (the old long arms were the cause), run tuning left; E slugs only in X-ray on the bones and only the 3 newest holes drip (already). B (the whole skeleton in every limb) is LEFT: check that the hand, foot and head bones show. See RAGDOLL_10 "the OWNER'S TEST". B: the kneecap (DummySkins) and a skull, eye holes and jaw in the round head (SmoothBody, shown in X-ray) are in the repo; PENDING into Studio (Studio was in Play when built: sync DummySkins + SmoothBody by length, then one quick Play).
# CLOUD CODE (27 Nov late, owner: "Fiks så der ikke er lilla striber"): the purple sticks were the welded Trickle parts under dripping holes; off now (`Config.DRIP_TRICKLE = false`, `Client/BloodFx.luau`). Push both files into Studio (length check), one quick Play. Holes still drip drops (the 3 newest).
# v6 FIT PASS (27 Nov run 6, v1319-v1325): DONE 0 hookup, 1 BodyShape, 2 physics sizes, 3 X-ray glass shell, 4 holes on the v6 surface, 5 CPR hands on the deeper chest, 6 arms shortened so props sit in the drawn hand, 8 bandages, 9 face (no change). LEFT (see RAGDOLL_10 "THE v6 FIT PASS"): 7 ride grips (owner check), 10 far bodies as a cheap v6 mesh, the head balance, accessories on the round head.
# The dog (A0) is APPROVED FOR NOW by the owner (27 Nov late: "hunden er godkendt for nu, men ... vi skal gøre den bedre, men først til sidst"). Use it as it is. Make it better only at the very END of the run (OVERVIEW PHASE 8 row DOG3, before END), and remind the owner in the final message. The cloud's review (4/10) for that pass: (1) real hind legs with a dog's hock bend, both standing, never a lifted sock shape; (2) real paws with toe pads, not round stumps; (3) a longer, crisp muzzle with a clear black nose and a mouth line; (4) a shorter, thicker neck (a dog, not a llama or deer); (5) a deep chest and a broad body from the front, not two tubes; (6) a crisp black saddle on the back with clean edges, not smudged; (7) a long, bushy tail.


(Old runs, probe numbers and done instructions: `docs/NOW_ARCHIVE.md`; grep it, never read it whole.)

## RULE FOR EVERYTHING IN THIS PLAN (owner, 26 Nov 2026): mobile first, simple enough for a 10-year-old on an iPad
- **Phone and iPad first:** every new thing is built and checked on the phone and iPad emulators before PC and console.
- **One tap per action:**
  - big buttons (at least 60 px);
  - icons rather than words; at most 2 words on any button;
  - no reading needed to understand it.
- **Hints:** a first-time hint is one short line plus a pointing hand, shown once.
- **Performance:** within the phone caps (ragdolls, particles, parts); light stand-ins far away.

## ANSWERS (cloud session for the owner, 27 Nov): use these, do not ask again
1. **X-RAY on I, REVIVE ALL on X:** yes, keep both.
2. **The angry dummy:** keep the harmless shove (1-3, a cooldown). Never in a NEW player's first 3 minutes (FTUE_10 fix 2).
3. **The dummy colour:** the light grey of F89 (about 163,162,165), as in the owner's reference shots; not the dark 92,95,102 and not yellow.
4. **Maturity:** gore OFF for all ages (decided 26 Nov). Purple cartoon only. Do not ask again.
5. **Death effects for sale:** NOT now. Keep them hidden; revisit after the owner's test and release.
6. **Script Sync:** do not wait for it and do not ask again; keep using the MCP with the length check. (The owner may turn it on later; nothing depends on it.)
7. **Places:** Studio is on the START place. Publish BOTH places only at the very end, after the owner has tested (the steps go in the final message).
8. **The German Shepherd:** no purchase. Blender is installed, so A0 builds a RIGGED shepherd in Blender (CREATURES_ANIM: the dog row), with real leg, tail, ear and jaw animation.
9. **The Ford:** the owner wants only the bicycle and the dirt bike free. Keep the code as it is (the pass is used once it is for sale). The owner puts pass 2092632252 on sale in the Creator Hub.
10. **The 5 new vehicles:** build them fully now (models, features, the touch button), each with SOON until the owner sends the pass ids. The suggested prices stand.
11. **The smooth body v2 (F89):** the owner imports `art/models/mannequin/mannequin_v2.fbx` once (Studio, Home or Avatar tab, Import 3D, as a rig, into ReplicatedStorage as SmoothBody, replacing v1). Until then keep v1 hidden if its arms are still up: show the slim grey block body rather than the bodybuilder pose. No Open Cloud key.
12. **3.18 boxing:** use the default: a free "PICK THE WINNER" (no BOLTS stake; a cheer, a streak and a small streak badge if right). No betting with currency in a kids' game. Now build the fight: 2 ragdolls, the bell, punches with the active ragdoll, knockdowns and the referee's count to 10.
13. **Row 14, a ragdoll in a wheelchair:** build the "ride welded" state in ActiveRagdoll (balance, lift and drive off; the pelvis welded to the seat; the client simulation stays with the chair's owner; a sitting pose; it falls out on a hard stop or a hit) and use it for the wheelchairs, the bicycle passenger and the rocket strap.
14. **F68, the water button:** closed. Real water is always on (F78/F87); nothing to find.

## ANSWERS 2 (cloud, for the owner, 27 Nov late): the open questions below are ANSWERED; do not ask them again
- **Body v3, v4, v5, v6 and the dog:** settled. v6 is APPROVED and imported; the dog is approved FOR NOW (row DOG3 at the very end).
- **Ragdolls per lab (40 on PC):** keep 40, but `DeviceTier` lowers it by itself when the frame rate drops under 50 for 5 s (to 30, then 24). Phones 9, tablets 14, console 20 stay.
- **The police siren (a community sound):** keep it.
- **The body voices (PSE "oof" and the grunt):** keep them, pitched per ragdoll.
- **The control kit (C10):** yes, build on: the Blender look for the button, lever, crank and dial, then move ALL the ~39 machine prompts onto it (CONTROLS_10).
- **Keys, the angry shove, the colour, maturity, death effects, Script Sync, publishing both places, REVIVE ALL on X, the German Shepherd, F68 water, the smooth body import:** all answered in "ANSWERS" (27 Nov) and since. Nothing is waiting on the owner but the PASSES below.
- **The passes the owner still has to make** (until then: SOON, never free by mistake): go-kart 49, police car 99, monster truck 149, bulldozer 149, fire truck 199 Robux; and the Ford's pass 2092632252 put on sale. The bicycle and the dirt bike are FREE (they must never show SOON).

## Questions for the owner (filled in during the run)
- **New badges (AUDIT 15):** make 8 badges on the Creator Hub and send the ids: 7-day streak, all weapons, all hats, every machine tried, every animal fed, Legend, first gold mastery star, advent finished. Also change the "Bullseye" badge text to "Fire a ragdoll onto a cannon target." Default: none added until the ids come (a 0 id is never awarded).
- **BODY V6 APPROVED (27 Nov late)**: do THE v6 FIT PASS. (Old:) (27 Nov, run 6) **BODY V6 is ready for your OK:** `art/models/mannequin/review_v6/` (as v5, plus closeup_neck, closeup_shoulder, closeup_hand_thigh). A short thin neck, no dark bands (one clean light grey), the marks on the upper arms and thighs away from the joints, no specks, slivers or holes (checked: one closed shell). 14.5k tris, 44 bones. Say "BODY V6 APPROVED" or what to change. Default: wait.
- **BODY V5: the owner asked for changes (27 Nov late)**: build v6 with `RAGDOLL_10.md` "v6 FIXES". (Old:) (27 Nov, run 6) **BODY V5 is ready for your OK:** `art/models/mannequin/review_v5/` (front, side, three_quarter, back, knocked_down, next_to_player with a real blocky avatar, closeup_hand, closeup_hand_side, closeup_hand_back, closeup_marking, closeup_head). One round SDF body (1.67 deep), 4 separate curled fingers and a short thumb along the index (no hook), clean black bands as mesh loops (one per joint), the head with the face on. 19.1k tris, 44 bones. Say "BODY V5 APPROVED" or what to change. Default: wait.
- (27 Nov, run 6) **The dog, rebuilt:** look at `art/models/dog/review/` (side, three_quarter, front, closeup_head). Say "DOG APPROVED" or what to change. Default: wait.
- **BODY V4: NOT APPROVED by the owner (27 Nov late, "nej")**; build v5 with `RAGDOLL_10.md` "v5 FIXES". (Old:) (27 Nov, run 6) **BODY V4 is ready for your OK:** `art/models/mannequin/review_v4/` (front, side, three_quarter, back, knocked_down, next_to_player, closeup_hand, closeup_marking). One smooth mesh; crisp vector markings and a chest plate in a 2048 map; the rings are flush bands in the surface; big round toy hands; round boots. Say "BODY V4 APPROVED" or what to change. Default: wait (nothing in the game changes before the OK and the import).
- (27 Nov, run 6) **The German Shepherd (A0):** look at `art/models/dog/review/` (side, three-quarter, front). Say OK or what to change; then import `art/models/dog/shepherd.fbx` and I animate it in code. Default: wait.
- (27 Nov, run 5) **Ragdolls per lab (WATCH_EVERY):** a real watcher at every machine needs more bodies: your lab now holds 40 on PC, 20 console, 14 tablet, 9 phone (`LAB_DUMMIES_PC`). If a PC drops frames, say a lower number. Default: 40.
- (27 Nov, run 5) **Body v3:** look at `art/models/mannequin/review_v3/` (front, side, posed, knocked down, next to a player). Say "BODY V3 APPROVED" or what to change. Default: wait (nothing in the game changes until you import it).
- (27 Nov, run 5) **Police siren:** a community upload ("main hi lo", 103787335792735), no PSE siren found. Default: keep it.
- (27 Nov, run 5) **Body voices:** PSE "Video Game Effects 15" (oof) and "Seahorse Whine 10" (get-up grunt), pitched per ragdoll. Default: keep; tell me if they sound wrong.
- (27 Nov, run 5) **The control kit (C10)** is built from parts in code now; the Blender look and moving the ~39 old machine prompts onto it come next. Default: build on.
- X-RAY key: B is already Build mode, so X-RAY is on I now (default). OK, or another key?
- Angry dummy: a harmless shove (now) or scolding only? (`ANGRY_SHOVE`)
- Dummy colour: darker grey (92,95,102, now) or the old (112,114,118)?
- Maturity: keep the gore (13+/17+) or switch it off for all ages? See docs/MATURITY.md.
- Death effects to sell (fireworks, confetti, ghost, gold sparkle, cartoon blast, R$ 49-99 each): create them as passes and send the ids?
- Script Sync is off in Studio: turn it on again, or allow localhost in MCP HTTP allow list (faster, cheaper sessions).
- (26 Nov, F12) Studio now saves to the Multiplayer place. Publish BOTH: File > Publish to Roblox As > the start place (126037745825106) > Overwrite, and the multiplayer place. OK?
- (27 Nov) Script Sync: after turning it on, a change to a file on disk still did not reach Studio. Check the 3 folders show the sync icon and point at DocumentsRagdollLab (ServerScriptServiceServer, ReplicatedStorageReplicatedStorageShared, StarterPlayerScriptsStarterPlayerScriptsClient).
- (26 Nov, F13) REVIVE ALL kept its key X (R and Z are taken). OK?
- (26 Nov, F10) The German Shepherd is one rigid mesh (no free rigged one found), moved by code (trot bob, wiggle, bite shake). For real leg animations: buy or send a rigged German Shepherd (Creator Store id), or keep this?
- (27 Nov, F76) The Ford: its pass 2092632252 is used only if Roblox says it is for sale; otherwise the Ford stays FREE. Put it on sale (or tell me to keep it free). The 5 new vehicles + the bicycle show SOON until you send their pass ids (suggested: go-kart 49, police 99, monster truck 149, bulldozer 149, fire truck 199).
- (27 Nov, S2) The smooth body is built in Blender: art/models/mannequin/mannequin.fbx. Import it ONCE: Studio > File > Import 3D > that file (as a rig), or allow me to upload it as a Model asset on your account (Open Cloud asset:write + an approved folder). Default: waiting; the real hands from parts are on now.

## Phone button map (checked 26 Nov 2026, 0.63.0, iPhone landscape 750x381 in the emulator with DevTouch)
- **Left:** Shop and Menu in row 1, then Multiplayer (`HudMenu.PHONE_KEEP`, `PortalUI` launcher). The move stick is under them.
- **Top centre:** goal pill and gift (no red ! under `PHONE_QUIET`).
- **Top right:** first-person eye, with the body-card arrow just left of it. The arrow moves left of LAB VIEW when that shows.
- **Right column:** X-RAY (60 px, y 62), RELOAD, JUMP.
- **Right bottom:** SHOOT, with TRY right over it (FirstTwo places TRY from SHOOT's real spot).
- **Bottom centre:** the hotbar, 62x56 slots.
- **Studio note:** without DevTouch the emulator reads as a touch laptop and shows the PC sandbox column (1ST/SLOW-MO/REVIVE/RESET), which overlaps JUMP. Real phones never show it.
- Picture: `art/store/phone_hud_0.63.jpg`.
- **F68 water button:** I found no button that turns water on in the start place (0 prompts, click detectors or scripts near water). Which place is it in, and where (a screenshot)? Default: parked until you say.
- **S2 smooth body:** built in Blender (27 Nov), see the question above (one import).
- **M4 smaller map:** Python is installed now; the compact plan is ready (cloud). Built in M4.
- ~~Row 6 new faces~~: done 27 Nov (Pillow installed by the owner; FACES_V2, v1241).

