# Ragdoll Havoc (Roblox ragdoll game)

Studio place "[💥] Ragdoll Havoc", placeId 126037745825106, universe 10774775314. Branch `release`. Talk to the owner in **Danish, short and plain**.

## How every session runs
- **The owner types `/klar`.** Read `docs/RUN.md` first: it is the ONE ordered to-do list and overrides every banner in OVERVIEW and NOW. Then follow `.claude/commands/klar.md`:
  1. the preflight (push the cloud's code, parse it, one Play);
  2. every batch in RUN.md, one after the other, WITHOUT stopping between them;
  3. for each item, the exact cause found in the code and the fix proven by a capture on PC and in the phone emulator;
  4. STOP only when every item is DONE or LEFT, with ONE Danish "Test selv" list for everything.

  `docs/OVERVIEW.md` and `docs/NOW.md` are background and history. Do not read the big plans whole (`docs/V9_PLAN.md`, `docs/V8_PLAN.md`): grep them.
- **Proof, not runs:** no long play sessions, benches or suites. But nothing is DONE without a capture that shows it working.
- **Publishing:** NOT until the map is done and the owner has tested. Then the owner publishes both places from the final message's steps. **Never restart or shut down old servers.**
- **Cost:**
  - read only what you need (grep first);
  - small steps;
  - subagents only when the owner says so;
  - multi-agent workflows only on "ultracode".
  - Where `docs/MASTER_PROMPT.md` says otherwise, these owner orders win.
- **After each task:** commit and push `release`, update `docs/NOW.md` (done / left), and add one line to `docs/HISTORY.md` only if a future session needs it.

## Code
- **Synced into Studio** by Script Sync (when it is off, put the scripts in through the Studio MCP and check them by checksum):
  - `ServerScriptService/Server/` (systems in `Systems/`, tests in `Tests/`);
  - `ReplicatedStorage/ReplicatedStorage/Shared/`;
  - `StarterPlayerScripts/StarterPlayerScripts/Client/`.
- **Files:** `X.luau` = ModuleScript, `.server.luau` = Script, `.local.luau` = LocalScript. `--!strict`. Tuning numbers live in `Shared/Config`, new behaviour goes behind a Config switch, and the server decides.
- **Remotes:** every remote goes through `Net` with a validator and a rate limit.
- **Models:** imported models live only in the place file (ServerStorage `V3Assets`, `V3Packs`, `N7Assets`). Remind the owner to save the place. Malware pass on every Creator Store insert.
- **Roblox knowledge:** the LihFolk vault `C:\Users\tristan\LihFolk-Vault-V2` (grep `INDEX_SLIM.md` / `SYMPTOMS.md`, read the `tldr:start` blocks). Study what the big ragdoll games do (Hyper Realistic Ragdoll, Ragdoll Engine, Bloody Ragdoll Physics, Fling Things and People).

## Owner decisions (current)
- Purple blood on (`Config.BLOOD = "purple"`), severing off, toy gun names, kid-friendly tone. Maturity questionnaire: being redone (see NOW.md).
- Own lab per player (others hidden), shared plaza, friends by invite. GOD MODE free during the beta.
- No background music. No rewards for likes or favourites. No free-form text in the world. Nothing from TikTok LIVE is saved.
- Never: write to live DataStores beyond the game's own saving, force-push, publish a gate failure, or delete owner content without a backup.

## Money (live ids)
In `Shared/Shop.luau`, `Shared/Events.luau` and `Shared/Badges.luau`. GOD MODE pass 2093692966. The owner creates new products and passes on the Creator Hub and sends the ids.

## Where to look
- **History** of every system and decision: `docs/HISTORY.md` (grep it).
- **Release steps:** `docs/RELEASE.md`. Codes: `docs/CODES.md`. Physics: `docs/PHYSICS.md`. Store text: `STORE_TEXT.md`. Trailer: `docs/TRAILER.md`.
