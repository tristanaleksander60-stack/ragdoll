# NOW: the current work list (read this first on every /klar)

Status: **waiting for the owner's corrections** (plan sent 26 Nov 2026). Do not start before the owner says go. Then work top to bottom.

**Targets and order of levers:** `docs/STRATEGY.md`, the 1-week column. Every item is judged against those funnels.

For each item:
- build it;
- do one quick Play (no errors);
- publish through RELEASE.md;
- write a Danish **"Test selv"** list;
- mark the item done here.

0. **WEAPONS list: no BUY, no TRY FREE, only the next weapon shows its KOs** (owner, 26 Nov 2026; do this first, it is small).
   > "Gør så man ikke kan se "Buy" ved hver ting i WEAPONS, men man kun kan se hvor mange KOs man mangler. Så man skal kun kunne se hvor mange KO's man mangler ved det våben man er kommet til, ikke hvor mange KO's det tager at få en sniper fx. og fjern try free ved alle våbene."
   - **File:** `StarterPlayerScripts/.../Client/ToolCatalog.luau` (BUY around line 200-225, TRY FREE around 650-690, the count line at 288, the intro at 427).
   - **Remove BUY** from every weapon card in WEAPONS. Behind a Config switch (`WEAPONS_NO_BUY = true`); the weapon products stay live in the shop, only the cards lose the button.
   - **Remove TRY FREE** from every weapon card (`WEAPONS_NO_TRY = true`). Also stop the "free try is over … or BUY it" toast and any other TRY FREE prompt (TrialService, ProgressService). Do not delete TrialService; just switch it off.
   - **The KO bar shows only on the next weapon to earn** (the first locked one in unlock order): "12 KOs to go" plus its bar. Every later locked weapon shows a lock and "Locked" only, with no number and no bar.
   - **Unlocked weapons:** EQUIP as now.
   - **Texts:** the line "Locked: earn KOs, BUY, or TRY FREE for 2 min" becomes "Earn KOs to unlock the next weapon". The intro loses "or BUY".
   - **Test selv:** open WEAPONS on PC and on a phone. There are no BUY or TRY FREE buttons, only one card shows "X KOs to go", and the rest say Locked.
   - This overrides item 8's "TRY before buy" and "Get it now" for weapons.

1. **Ragdolls fall through or half into the ground.**
   - Find the cause: a thin floor for fast bodies, the pad floor, new dummy masses, the time bubble, or spawning half inside the floor.
   - Fix: an invisible thick safety floor under the lab and every map; bodies always created above the floor; any body below the floor put back.
2. **Lag on every platform.**
   - Measure first: server heartbeat, script time, network, phone FPS.
   - Fix the 5 heaviest things: loops, bodies and effects caps, lights, far things, leaks.
   - Lower detail on weak phones without losing the PC look.
3. **Fix the 1-5 minute leak and find why people dislike** (the funnels of 26 Nov, `docs/FUNNELS.md`: half the players at 2 min are gone by 5 min, and 47 % stop between 10 and 25 KOs; targets are in that file).
   - **A new pull every minute in the first 5 minutes:**
     - unlocks close together early: a new weapon at about 3, 6, 10, 15, 20 and 25 KOs (retune `LADDER_V9_KEEP` / the first rungs, and keep the later gaps);
     - each unlock a big, satisfying reveal;
     - the "Next" bar is always visible.
   - **A planned moment at about 1, 2, 3 and 4 minutes** for new players, without pop-up spam:
     - about 1 min: the angry dummy (item 5);
     - about 2 min: a free mini event in your lab (the red button lights up: "Press me!");
     - about 3 min: the first terminal or creature gets pointed out (a calm glow);
     - about 4 min: the Map board gets pointed out ("New place unlocked: Island").
     - These go through Notify / FirstVisit and the V9-0g phone sizes.
   - **Variety past 10 KOs:** the walkers, the GOD mode spawns and the machines are in view. The dummy line-up changes now and then (new dummy types walking in), so there is always something new to hit.
   - **Measure:** add custom funnel steps (AnalyticsService funnel events) so the Creator Hub shows:
     - the minute moments above;
     - the first unlock, the first terminal used, the first map trip;
     - the tutorial steps (item 6);
     - shop: opened → item viewed → prompt → **bought**.
   - **Dislikes:**
     - read Session_v1 (leave times, errors, FPS by device) and the like ratio by version;
     - add an optional "How's the game?" thumbs + reason (no reward);
     - write a short report with the top 3 reasons and the fixes into `docs/FUNNELS.md`.
   - **Test selv:** play 5 minutes as a new player (StudioFresh) and note what happens each minute.
4. **Answer Roblox's mail about the maturity questionnaire** (they rejected the last answers).
   - Needs the owner to paste the mail and the old answers.
   - List what the game really contains: purple blood, guns, the words "Dead" and "bled out".
   - Draft honest answers, and offer the choice: keep the content and the label it gives, or tone it down for a lower age label.
   - **The owner submits.**
5. **The first dummy you hit twice gets angry**, unless the first shot kills it; then it is the next dummy hit twice.
   - Red face and a short tantrum; it runs at you and gives a harmless, funny shove or slap (no damage), then flees.
   - Once per player early on, then rarely.
   - (Owner to confirm: shove allowed, or only scolding?)
6. **A tutorial on every device** (PC, phone, tablet, console).
   - 3-4 short show-don't-tell steps: shoot a dummy, grab and throw, use a terminal, find the Map board.
   - The right input glyphs per device; skippable; newcomers only; no pop-ups on top.
   - Measure step completion.
7. **Everything better on phones**, learning from the biggest games and the audience (about 9-14):
   - fewer, bigger buttons under the thumbs;
   - aim and fire help;
   - a simple shop;
   - readable text;
   - a fast start;
   - upright and landscape.
8. **Best sellers, the shop and Robux** (funnel: only 8 % open the shop, and 11 % of them press buy).
   - **Read the sales:** what sells, where it stood, and whether it was tried first. Write the analysis into `docs/FUNNELS.md`.
   - **The shop opens more:**
     - a clear SHOP button;
     - the booths in the lab show a real, cheap, cool item;
     - (not on weapons: item 0 removes BUY there).
   - **More presses buy:**
     - one cheap starter offer first (R$ 25-49, clear big value);
     - a few strong items up front instead of a wall of passes;
     - "Popular" and "Best value" tags from the real sales;
     - TRY before buy on things that can be tried (not weapons, see item 0);
     - pictures and 3D that show what you get.
   - **Move the best sellers forward** in the lab and the shop, and rework or move the weak ones. Change what is shown in the lab.
   - **New items:**
     - **death effects** (fireworks, confetti, a ghost dummy floating up, gold sparkle, cartoon blast);
     - more cosmetics (trails, KO sounds, dummy skins, emotes);
     - fair, with no pay-to-win.
   - Give the owner the product list to create.
   - **Measure:** the shop funnel with a "Bought" step.
