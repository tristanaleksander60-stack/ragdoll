---
description: Build the WHOLE plan in docs/OVERVIEW.md, phase by phase, without stopping; the owner tests only at the end
argument-hint: "[optional: what the owner wants first]"
---
Read `CLAUDE.md`, then `docs/OVERVIEW.md` (the one-page plan: the owner's situation, how to work, what only the owner can do, THE ORDER in 8 phases, DONE). Then read only the doc section of the row you are on. If the owner wrote something after /klar, do that first.

## THE OWNER'S ORDERS (26 Nov 2026)
- "Gør så den laver alt nu uden at stoppe så jeg bare skal teste alt til sidst"
- "Sørg for den ikke tester alt selv dybt, men at det er min opgave, den skal bare lave det bedst mulige produkt og så tester jeg når alt er færdigt"

**So:** build EVERYTHING in OVERVIEW's ORDER, phase by phase, top to bottom, in ONE run, as well as you possibly can the first time. Do not test it: the owner does.

### The loop, per row (details in OVERVIEW "How to work")
1. Read the row and its doc section (grep), and the code it touches.
2. Find the real cause in the code and build the WHOLE row.
3. Put the scripts into Studio via the MCP (checksum).
4. ONE quick Play for errors only (plus one capture if the row is about looks).
5. Run the fast lints the doc asks for.
6. Save the place, commit and push `release`, and update the row in OVERVIEW.
7. `git pull --rebase` (the cloud session pushes the owner's new wishes and generated files, such as `OwnerMapPlan.luau`), re-read THE ORDER, and go straight on to the next row.

### Never
- **Never end the turn after one row, one phase or a short while.** The only reasons to stop:
  - (a) every row is DONE or PARKED;
  - (b) Studio or the MCP cannot be reached after 3 tries.

  A long run is wanted; when the context fills up it is summarised, and you keep going from OVERVIEW.
- **Never test beyond the one quick Play.** No runs, watches, benches, clips, scores, comparisons, 2-client tests, emulator rounds, FPS sessions, suites or reviewers, even where a doc asks for them: the docs' "Check" lines are what the OWNER will test. Keep the cheap always-on logs and detectors.
- **Never ask the owner anything mid-run.** Pick the default (below, or the safe one behind a Config switch), write it in NOW.md "Questions for the owner", and go on.
- **Never stop for a blocked row.** PARK it in OVERVIEW with the reason and go on.
- **Never publish.** The owner tests first, then publishes both places from your instructions.

## Standing answers (use them; do not ask again)
- **Script Sync not landing:** put every changed script into Studio through the MCP and check it by length or checksum. Note it once in the final message.
- **The dog is one stiff mesh:**
  - find a RIGGED German Shepherd in the Creator Store yourself (bones or Motor6D legs, neck, tail, jaw; clean license; malware pass; keep only the model);
  - else use the best rigged realistic dog, recoloured tan and black, with its joints animated in code.
- **Missing models** (wheelchair, cave, rocks, vehicles, animals, props): get them from the Creator Store yourself (malware pass, one matching style). Use Terrain where the doc prefers it.
- **Creator Store scripts** (vehicles): build the features in our own code. A model's script may run only if it passes F76's security check.
- **Game pass ids not sent yet:** the vehicle shows SOON; it is never free by mistake.
- **Keys:** REVIVE ALL is X; X-RAY is I; MORE is a gear (9); WEAPONS is T.
- **Python and Blender:** the owner is installing both (26 Nov late).
  - Check with `python --version` and `blender --version`; if `blender` is not on PATH, look for `C:\Program Files\Blender Foundation\Blender*\blender.exe`.
  - **With Python:** you may run `tools/masterplan.py` yourself after a plan change (the lint must report 0). Without it, the cloud session runs it and you only build from `OwnerMapPlan.luau`. Never work around a missing tool on the old map.
  - **With Blender:** do S2 for real:
    1. make the skinned mannequin body with real hands and fingers in Blender from a Python script (`blender --background --python <script>`), with the LihFolk `roblox-blender-modeling` skill;
    2. export it as FBX with R15 bone names and skin weights, into `art/models/mannequin/`;
    3. if the MCP cannot import an FBX, put "Studio: File > Import 3D > art/models/mannequin/mannequin.fbx" in the final message as ONE owner step, and finish the hookup in the next run. Meanwhile, build the real hands from parts (S2 plan B) so the hooks are gone.
  - **Without Blender:** S2 plan B (hands from parts, Roblox body bundles). Never park the hands.
- **Code written by the cloud session:** after `git pull`, list the `.luau` files that commits since your last run changed (`git diff --name-only <your last commit>..HEAD -- "*.luau"`).
  - Put every one into Studio through the MCP (the length check); new files are created where their folder says.
  - One quick Play, then fix any error before anything else.
  - The cloud cannot run Studio, so its code is untested until you do this.
- **Never change the old map layout:** since M4 every map change is built on the compact plan (OVERVIEW M4).

## The ONE final message (Danish, short, only when you really stop)
1. **Step 0 reminder:** the questionnaire was SENT on 27 Nov (Roblox rating Mild), so do not remind about it again. (Old line, kept for history:) "Husk punkt 0: tryk Alt+P i Studio for at udgive gore-off, og send aldersspørgeskemaet med svarene i docs/MATURITY.md."
2. **What was built,** phase by phase, one line per row, and what is parked and why.
3. **How to publish BOTH places** after testing (OVERVIEW PHASE 8).
4. **ONE LONG "Test selv" list covering EVERYTHING built in the run** (owner, 26 Nov late: "send en lang test liste med alt, så sender jeg hvis der er noget som skal ændres"):
   - grouped by area (the first minutes, ragdolls, the body and bones, the map, life, the machines and animals, vehicles, phone UI, PC);
   - phone first, then PC;
   - one line per thing to try, saying where to go and what should happen;
   - taken from every row's Check lines;
   - no length limit;
   - numbered, so the owner can answer "12: ...".
5. **The "Questions for the owner" list:** each with the default you chose.

**Keep `docs/OVERVIEW.md` true:** update a row's State and LEFT whenever you finish or start it.

The owner's wish for this session: $ARGUMENTS
