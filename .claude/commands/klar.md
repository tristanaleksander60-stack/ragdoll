---
description: Build ALL of docs/RUN.md properly (find causes, prove each item with captures), then one test list at the end
argument-hint: "[optional: what the owner wants first]"
---
# /klar: the whole list, every item done properly

## 1. Read (in this order, nothing else first)
1. `docs/RUN.md`: the ONE ordered to-do list, its rules and the item statuses. It overrides every banner in OVERVIEW and NOW and any other plan doc.
2. `CLAUDE.md` (project rules).
3. Only the doc sections an item points to: grep them, never read big docs whole (V8_PLAN, V9_PLAN, HISTORY, DONE, NOW_ARCHIVE).

## 2. Preflight (always, before any item): RUN.md rule 1
1. `git pull --rebase`.
2. List every `.luau` file that commits NOT made by you changed since your last commit (`git log <your last commit>..HEAD --format=%ae --name-only`).
3. Parse each one (`stylua --syntax Luau - < file > /dev/null`, non-zero = a syntax error: fix it).
4. Push each one into Studio via the MCP, with a length check.
5. One Play: read the output and fix every error first.

## 3. Work through EVERYTHING, without stopping
Do every item in `RUN.md`: batch 1, then batch 2, then batch 3 and on, top to bottom. Do NOT stop between batches: the owner checks only when everything is done. For each item:
1. **Find the exact cause in the code** (the file, the function and why) and write it in the item's State.
2. **Build the fix behind a Config switch.** Every remote through `Net`. The server decides. No plain-part art for anything visible (a Blender model with the quality gate, or a malware-checked Creator Store model).
3. **Push into Studio** (length check) and run one Play.
4. **Prove it:** a capture from the angle the item names, on PC AND in the phone emulator. If the capture does not show it working, it is not done: find the real cause and go again. After 2 failed tries, mark it LEFT with what you found and go on to the next item.
5. **Record it:** commit, push, and set the State (`DONE` plus the capture's line, or `LEFT` plus the reason).
6. **Pull again** (`git pull --rebase`): the cloud may have added items or code. Run the preflight for any new cloud code, then continue.

**Stop ONLY when:**
- (a) every item in RUN.md is DONE or LEFT; or
- (b) Studio or the MCP cannot be reached after 3 tries.

When the context fills up it is summarised: keep going from RUN.md.

## 4. The ONE final message (only when you really stop), in Danish, short
1. **One line per item:** DONE / LEFT, and what the capture showed or why it is left.
2. **"Test selv":** ONE numbered list for everything built in this run, phone first, each line with where to go and what must happen.
3. **Owner steps** (only if any): Studio saves, passes, the questionnaire.
4. **If DOG3 is not done:** one line reminding the owner the dog is approved only for now and gets better at the end.

## 5. Never
- Publish.
- Force-push or rewrite history.
- Restart or shut down servers.
- Write to live DataStores beyond the game's own saving.
- Delete owner content without a backup.
- Mark something DONE without a capture that shows it.
- Ask the owner mid-run: pick the safe default behind a Config switch, note it, and go on.

## 6. Standing facts (no need to ask)
- **Script Sync is off:** push scripts through the MCP with a length check.
- **Vehicle passes:**
  - GoKart 2098603396;
  - Police 2098855450;
  - MonsterTruck 2099065438;
  - Bulldozer 2098381516;
  - FireTruck 2101716732.

  The Ford pass is 2092632252 (used when on sale).
- **Missing models:** take them from the Creator Store (malware pass, one matching style). A model's scripts run only after the security check; build features in our own code.
- **Blender:** check `blender --version` (or `C:\Program Files\Blender Foundation\Blender*\blender.exe`); build with the LihFolk `roblox-blender-modeling` skill and its quality gate.
- **Map changes** are built on the compact plan (`OwnerMapPlan.luau`, `tools/masterplan.py` lint at 0).
- **Talk to the owner in Danish,** short and plain.

The owner's wish for this session: $ARGUMENTS
