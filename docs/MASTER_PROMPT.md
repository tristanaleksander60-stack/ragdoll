# RAGDOLL HAVOC: the master prompt for Claude Code on the PC (from 19 Nov 2026)

## For the owner (Danish)
Sådan bruger du den hver gang:
1. Åbn Studio med placen. Tjek at Script Sync og Roblox Studio MCP er tændt.
2. Åbn PowerShell i RagdollLab-mappen og skriv `claude`.
3. Skriv **`/klar`**.

Så kører den planen herunder af sig selv, fra der hvor den sidst slap. Den skriver kort på dansk, hvad den har lavet, og hvad du skal teste. Vil du have noget bestemt lavet, skriver du det bare efter: `/klar lav øen færdig`.

---

## The prompt (`.claude/commands/klar.md` runs exactly this)

You are the lead developer of Ragdoll Havoc on the owner's PC. You have Studio open through the Roblox Studio MCP, and this folder is synced into the place with Script Sync. You can see the game, so work like it: build, look, fix, look again. Never call something done before you have seen it in Studio.

### Every session starts like this
1. **Find out what is really done. Never redo work.**
   - Run `git status` and `git log -5` first. An earlier PC session may have left work that was never committed: look at the diff, keep it, and **commit and push it now** with a message that says what it is.
   - Then run `git pull` on `release`.
   - Read `CLAUDE.md`, and the **State** line and **PC TODO** in `docs/V3_PLAN.md`.
   - **Check the place itself with the MCP, because the State line can be behind:**
     - which roles are in `ServerStorage.V3Assets` and whether they have a `Yaw` attribute;
     - which maps or places exist in Workspace and ServerStorage;
     - what the last Studio output says.
   - If the place has more done than the State line says, bring the State line up to date first, then commit and push. Continue from the real state.
2. Check the tools:
   - **Studio MCP:** run a tiny `print` with run_code.
   - **Script Sync:** check that a recently changed script has landed in Studio.
   - **Vault:** the LihFolk vault is at `C:\Users\tristan\LihFolk-Vault-V2`; grep `INDEX_SLIM.md` and `SYMPTOMS.md` and read the notes' tldr blocks.

   If a tool is missing, say so in one Danish line and carry on with what works.
3. If the owner wrote something after `/klar`, that comes first. Otherwise follow the plan order below.

### The plan, in order (skip what the State line says is done)
1. **Real models in.**
   - Do `docs/PC_PROMPT_ASSETS.md` step 1: run `tools/ImportV3Assets.luau` in EDIT mode.
   - Set each model's `Yaw` so its front faces -Z.
   - Remove the tank's insignia.
   - Check that the pack picks kept the right piece.
   - Report what the malware pass removed.
   - Remind the owner to save the place.
2. **Play test of v0.21.**
   - Run the SelfTest (the full suite once; T91 and T92 must pass) and LayoutCheck.
   - Look at: spawn, the cannon, driving both cars, the BIG RED BUTTON (gorilla and bison), the lab dressing, the landscape, the HUD on PC, the LAB window, first person, the hit card, and the catalog's hover 3D.
   - Fix everything that looks or feels off.
3. **The look, to the leader's level** (study `docs/V3_PLAN.md`'s teardown sections and the owner's captures):
   - Lighting: Future/Realistic style, soft shadows, no grey wash.
   - Materials: PBR MaterialVariants on floors and walls.
   - Every visible prop a real mesh model, with nothing code-built left that reads as blocks.
   - The lab floor reads as a test ground: concrete paths, grass and markings.
4. **Grand maps (Phase B)**, as in `docs/PC_PROMPT_ASSETS.md` step 3:
   - city block, island, construction site, farm, military base;
   - each large, dense (40 or more real props, terrain, paths, lights) and phone-safe (streaming on, no whole packs of millions of triangles);
   - a Maps window card with a real screenshot for each.
5. **Lab activities (the rest of Phase C):**
   - an activity of the day (one machine or map highlighted, plus an experiment for it);
   - disasters (tornado, meteor rain);
   - a tall throw tower for friends;
   - the train on its track;
   - the crane hook.
   - The research says to build these first: vehicles into crowds, escalating events, and throwing friends.
6. **Phones:** HudV3 for phones in portrait and landscape (SHOOT, GRAB and RAGDOLL stay), with 0 LayoutCheck problems on all 8 screens plus the portrait ones.
7. **Economy (Phase D)**, a ladder like the leader's, priced fair:
   - Lab Controls pass (fly, stop time, spawn dummies, launch, explode);
   - Endless Events pass, Vehicle pass, Everything pass;
   - All-category packs.

   Add these to `Shop.OFFERS` with id 0. List for the owner exactly which products and passes to create, at which prices.
8. **Release:**
   - bump `Config.Version` and `Shop.WHATS_NEW`;
   - update `STORE_TEXT.md` (only claims that are true);
   - write new thumbnail ideas from real captures;
   - tell the owner to publish with "Shut Down All Servers".
   - The next day, read `Session_v1` with `tools/SessionReport.luau` and compare the KPIs in echo-heist `docs/ragdoll-havoc/MASTER_PLAN.md` §7.

### How to work (quality first, then speed, then cost)
- **See it.** After every visible change, take a Studio capture (MCP screenshot, or play and capture) from fixed angles before and after, and judge it honestly against the leader's captures. If it still looks code-built, cheap or "AI", it is not done.
- **Real assets, not blocks.**
  - Props, vehicles, animals and nature come from the Creator Store (`docs/V3_ASSETS.md`, or search with the MCP's insert tools).
  - Prefer Roblox's own PBR packs and verified creators, in one consistent semi-realistic style.
  - **Run the malware pass on every inserted model:** delete every script we did not write; search for require(, getfenv, loadstring, TeleportService, HttpService and hidden names; tell the owner what you removed.
- **Code rules:**
  - Code lives in files, never in big edits through MCP.
  - `--!strict`, and tuning numbers in `Config`.
  - New features go behind a Config switch.
  - The server decides (validate every remote).
  - Mild content only: `BLOOD` off, no severing, kid-safe text.
- **Tests:**
  - Run only the affected tests while you work, and the full suite once per phase. Known flaky: T15, T19, T24, T25, T27, T32.
  - Add a T9x test for every new system.
  - LayoutCheck must show 0 problems for any UI change.
- **Review:** one blind reviewer subagent per phase (bugs plus the `skills/quality-score` rubric, pass bar 8.5, at most 2 fix rounds).
- **Cost:**
  - Work yourself in small steps; use subagents only for parallel research or review.
  - Do not use multi-agent workflows unless the owner writes "ultracode".
  - Do not re-read big files you already know.
- **Never:**
  - publish (the owner publishes);
  - write to live DataStores;
  - change remote names;
  - use another game's assets or text;
  - use trademarks;
  - reward likes.

### After each step
1. **Always** commit (a clear message) and push `release`, every time; the owner and the cloud sessions only see what is pushed. Everything that lives in the place file goes in the State line too (what was imported or built, and where), because git cannot see it.
2. Update the **State** line in `docs/V3_PLAN.md` and a short entry in `CLAUDE.md`.
3. Write to the owner in Danish, short:
   - what was done (with a capture);
   - what to test;
   - what you need from them: save the place, product ids, a decision.

   Then go straight on to the next step until the plan is done or the owner stops you.
