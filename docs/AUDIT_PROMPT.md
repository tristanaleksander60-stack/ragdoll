# RAGDOLL HAVOC: the full quality audit (run with `/tjek`)

## For the owner (Danish)
Skriv **`/tjek`** i Claude Code på pc'en (Studio åbent, Script Sync og Studio MCP tændt). Så gennemgår den hele spillet: alt, hvad spillerne kan se, høre og røre, plus koden bag. Den giver hvert område en karakter fra 0 til 10 og retter fejlene, indtil alt står til 9 eller mere. Den skriver kort på dansk undervejs og viser billeder af før og efter.

Vil du have den til at starte et bestemt sted, så skriv det efter, fx `/tjek start med telefonen`.

---

## The prompt

**Role.** You are the lead developer, art director, QA lead and producer of Ragdoll Havoc in one person. You work on the owner's PC with Roblox Studio through the Roblox Studio MCP, and this folder is synced with Script Sync. **Goal: every part of the game at top quality.** Nothing broken, nothing that looks code-built or "AI", nothing that sounds wrong, nothing slow on a phone, nothing exploitable, nothing against Roblox rules. Judge it all against the market leader (Hyper Realistic Ragdoll) and against what a picky 10-year-old would notice in the first minute.

### 0. Start
1. **Real state first.**
   - Run `git status` and `git log -10`. Commit and push any leftover work.
   - Run `git pull` on `release`.
   - Read `CLAUDE.md` and the State lines in `docs/V5_PLAN.md`, `docs/V4_PLAN.md` and `docs/V3_PLAN.md`.
   - Check the place itself with the MCP: `ServerStorage.V3Assets` and `V3Packs`, the maps, the place version, the last output.
   - If `docs/AUDIT.md` exists, continue from its State line.
2. **Tools.**
   - The MCP (run_code), Script Sync, Play/Stop, captures, and multi-client testing.
   - The LihFolk vault at `C:\Users\tristan\LihFolk-Vault-V2` (grep `INDEX_SLIM.md` / `SYMPTOMS.md` and read the `tldr:start` blocks).
   - The LihFolk plugin skills if they are installed: `lihfolk:audit`, `lihfolk:roblox-anti-exploit-review`, `lihfolk:roblox-datastore-safety`, `lihfolk:roblox-performance-audit`, `lihfolk:roblox-monetization-compliance`, `lihfolk:roblox-ui-builder`, `lihfolk:quality-score`.
   - If something is missing, say so in one Danish line and work around it.
3. **Backup.** Copy the place's ServerStorage content you might touch into `ServerStorage.AuditBackup` before you change models or maps. Remind the owner to save.

### 1. Audit: look at everything first, fix nothing yet
Play the game as a new player and as a returning one, on PC and in Studio's device emulator. Cover a phone in landscape and portrait, a tablet and a gamepad. Use solo play and 2-3 clients. Visit **every** place, press **every** button, open **every** window, fire **every** weapon class, run **every** event and machine, drive **every** vehicle, and run every minigame round.

For each area below:
- take captures (fixed, named camera spots, saved so after-shots match);
- write the findings into `docs/AUDIT.md` with a severity (P0 broken or unfair, P1 looks or feels bad, P2 polish);
- give a score from 0 to 10, judged honestly against the leader.

| # | Area | What "top" means |
|---|---|---|
| 1 | **First 60 s** | Action within 5 s, one clear goal, a wow moment within 60 s, no pop-up spam, works on a phone |
| 2 | **Core feel** | Hits, ragdoll reactions, damage and death (shots, punches, headshots), knockback, slow-mo, X-ray, combos, camera shake: punchy and readable |
| 3 | **Weapons** | Every weapon fires, sounds right, looks right in third and first person (mouse wheel and V), ammo/reload, icons match the models, the unlock ladder is fair |
| 4 | **NPCs** | Look (mannequin quality, per-map outfits), spread out (no clumps), natural behaviour per place, lines fit the place, talk and commands (follow, stay, attack) work and are abuse-safe |
| 5 | **Lab** | Clean designed layout, no clutter or overlaps, everything works (cannon, stations, tower, button, cars, machine of the day), something new each day |
| 6 | **Maps** | Plaza, Game Arena, Island, Downtown, Building Site, Old Farm, Army Base: grand, detailed, real models in one style, no floating or sunken props, arrival works, card pictures right |
| 7 | **Events and chaos** | Every event (gorilla, bull, tornado, meteors, train and every newer one) starts, looks realistic, sounds right, ends cleanly and never breaks the lab |
| 8 | **Vehicles** | Look like real cars, wheels spin and steer, lights, engine and horn, handling feels good, they hit dummies, they never get stuck or flip forever |
| 9 | **Minigames** | Red Light Green Light and every arena game: fair, clear, no softlocks, solo and multiplayer |
| 10 | **UI** | One hand-made style, readable, no AI look (leaderboards included), no overlaps (LayoutCheck 0), touch targets of at least 44 px, gamepad focus everywhere |
| 11 | **Sound** | Every sound present and mixed: SoundGroups, levels, no clipping, distance rolloff, voice limits, UI quieter than guns, settings sliders |
| 12 | **Visuals** | Lighting, sky, materials, terrain, shadows, effects; nothing flickers, glows wrongly, or falls through the ground |
| 13 | **Performance** | Frame time and memory on the low tier (phone emulator), the ragdoll/NPC/FX caps hold, streaming works, network traffic is sane. Use the MicroProfiler for the worst spots |
| 14 | **Multiplayer** | Prank Party, throws, the plaza, portals, the server list, joining friends: smooth, synced, no griefing |
| 15 | **Security** | Every remote validated and rate-limited on the server. No client-trusted damage, money, unlocks or events. NPC commands and vehicle speed cannot be abused |
| 16 | **Data** | Saves never lose or duplicate anything (profile, eco/bolts, unlocks, trials, gifts), BindToClose works, migrations are safe |
| 17 | **Money** | Every product and pass works and is delivered exactly once. Prices are fair. No pay-to-win anger. Policy-safe (no rewards for likes, odds shown where needed) |
| 18 | **Retention** | Goals that chain, a daily streak, the daily experiments and machine, the favourite prompt timing, friend invites, What's New, the update rhythm |
| 19 | **Content and policy** | Mild everywhere (no blood, no severing, kid-safe text), no brands or logos, store claims true, maturity questionnaire target is all ages |
| 20 | **Code health** | Every test passes (except the known flaky list), no errors or warnings in the output during play, `--!strict` clean, no dead code paths that run, `CLAUDE.md` accurate |

Finish the audit by writing the **scorecard** at the top of `docs/AUDIT.md` (area, score, top 3 problems). Commit and push, then send the owner a short Danish summary with the worst captures.

### 2. Fix: from worst to best
1. **Order.** All P0 across every area first, then the lowest-scoring areas, then P1, then P2.
2. **For each fix:**
   - reproduce it;
   - fix the root cause (not the symptom);
   - see it work in Studio with an after-capture from the same spot;
   - add or adjust a self-test (`T9x`) where it can break again;
   - run the affected tests;
   - commit and push with a clear message.
3. **Quality rules:**
   - **Real Creator Store models** in one style, with the **malware pass on every insert**: delete every script we did not write, search for require/getfenv/loadstring/Teleport/Http and odd names, and report what was removed.
   - Numbers live in `Config`, new behaviour goes behind switches, and the server decides everything.
   - Phone budgets are respected.
   - Content stays mild.
4. **After each area is fixed:** score it again. An area is done at **9/10 or more**, confirmed by one **blind reviewer subagent** that sees only the captures and the diff, not your notes. Allow at most 2 fix rounds per area; then move on and note what is left.
5. **Full regression once at the end:**
   - the full self-test suite;
   - LayoutCheck on every screen;
   - a 10-minute play session per device type without one error in the output;
   - a 3-client multiplayer session.

### 3. Rules
- **Never:**
  - publish (the owner publishes with "Shut Down All Servers");
  - write to live DataStores;
  - force-push;
  - delete owner content without the AuditBackup;
  - rename remotes without updating `CLAUDE.md`.
- **Ask the owner** only for things only they can do: product or pass ids, a dashboard setting, saving the place, a real phone test. Say exactly what and why, then carry on with everything else.
- **Cost.**
  - Work in small steps.
  - Use subagents only for parallel audits of separate areas and for the blind reviews.
  - Use multi-agent workflows only if the owner writes "ultracode".

### 4. Report (Danish, short, after each area and at the end)
- **Karakter før → efter** per område.
- **Rettet:** the most important fixes, with before/after captures.
- **Test selv:** 1-3 things to try.
- **Brug for fra dig:** for example save the place, ids, a decision.

At the end, the full scorecard. Then: "Klar til at udgive". Include what the owner must do: publish, the questionnaire, the store text, the icon and thumbnails.

### 5. State
Keep the State line at the top of `docs/AUDIT.md` current (area by area: audited, fixing, done with its score), so a new session continues where this one stopped.
