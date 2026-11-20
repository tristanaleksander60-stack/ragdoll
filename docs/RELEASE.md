# RELEASE: automatic publish at the end of a `/klar` run

**Owner order (20 Nov 2026):** "Gør så den automatisk publisher når den er færdig og at den bare kører hele planen igennem når jeg skriver klar næste gang til den."

When `/klar` has run every step of the current plan, the session publishes the game by itself. It publishes only if every gate below passes. This replaces the old rule "never publish", for this path only.

## For the owner (Danish)
Når du skriver `/klar`, kører den hele planen igennem. Når alt er færdigt og testet, udgiver den spillet selv og genstarter de gamle servere, så alle får den nye version. Hvis noget ikke består testene, udgiver den IKKE. Så får du en kort besked om, hvad der mangler. Den udgiver højst én gang per `/klar`.

## When
- Only after the last step of the plan is done or parked: all of V7, then V6-8.
  - Parked means written into State with a reason, behind a switch that is off.
- At most once per `/klar` run. Never in the middle of a plan.

## 1. Gate: every check must pass, or nothing is published
- **Code:**
  - The full self-test suite passes; only the known flaky tests (CLAUDE.md) may fail, and each one passes when rerun alone.
  - LayoutCheck shows 0 problems on every screen, consoles included.
  - The latest pushed commit on `release` is what is in Studio: `git status` is clean, and the scripts have landed through Script Sync.
- **Play:**
  - A 10-minute play session on PC and in the phone emulator shows no errors in the output.
  - A 2-client test of the multiplayer parts shows no errors.
- **Reviews:** every step of the plan has passed its blind review, or the leftovers are written in State and the parts that are not ready are switched off.
- **Studio-only things are off:**
  - `ServerStorage.RunSelfTest`, `SessionStudio` and `StudioFresh` are false or removed;
  - no `DevLayoutCheck`, `AimTestPoint`, `TrailerShot` or `TrailerFocus` attributes are left;
  - no test dummies or stray parts are in Workspace;
  - no TEST purchase paths are live, and ids of 0 stay hidden;
  - LabLive is in its normal state.
- **Money:** every product and pass shown live has a real id and has been test-bought in Studio.
- **Content:** mild everywhere (BLOOD off, no severing), and no brands.
- **Version:**
  - Bump `Config.Version`.
  - `Shop.WHATS_NEW[1].version` equals `Config.Version` (T66), with a short What's New text.
  - Update `STORE_TEXT.md` if something big came in.

If a gate fails and cannot be fixed in this run: **do not publish.** Write the reason in State. Send the owner one Danish line: "Ikke udgivet: <grund>. Rettes næste gang."

## 2. Prepare
1. **Back up the place first.**
   - Save a copy of the place file as `Documents\RagdollLab-backups\<date>-pre-publish-<version>.rbxl`.
   - Note the live place version number. Read it with Open Cloud, or from the Creator Hub version history.
2. **Save the place in Studio.**

## 3. Publish
Use the first method that works:
1. **The Roblox Studio MCP's own publish action, if it has one.** This is the same as File → Publish to Roblox.
2. **The Open Cloud Place Publishing API.**
   - Send `POST https://apis.roblox.com/universes/v1/10774775314/places/126037745825106/versions?versionType=Published` with the saved place file as the body, using the `open_cloud_invoke` tool or the owner's Open Cloud key.
   - The key needs the scope `universe-places:write`.
   - Never print or paste the key.
   - If the scope or an approved folder is missing, tell the owner in one Danish line exactly what to add, and use method 3 this time.
3. **Last resort:** one Danish line to the owner: "Tryk Alt+P (Publish to Roblox) nu, så kører jeg videre." Wait, then check that the live version went up.

## 4. Restart old servers (= "Shut Down All Servers")
- **Open Cloud:** `POST https://apis.roblox.com/cloud/v2/universes/10774775314:restartServers`. It needs the scope `universe:write`, and it restarts the servers running an older version.
- **If that is not possible:** tell the owner in one Danish line: "Creator Hub → Ragdoll Havoc → ⋯ → Shut Down All Servers."

## 5. Check after publishing
- The live place version number went up by one.
- After 15-30 minutes, read live `Session_v1` (read only, never write).
  - Players are joining on the new `pv`.
  - No sharp rise in early leaves or zero-takedown sessions against the last build.
- **If something is badly wrong live:**
  - Roll back by publishing the pre-publish backup the same way, or the owner restores the noted version in the Creator Hub version history.
  - Write what happened in State.

## 6. Report (Danish)
- **Udgivet:** version X.Y.Z, plus the 3 biggest news.
- **Test selv:** join from your phone and try <1-3 things>.
- **Brug for fra dig:**
  - ids for new products or passes;
  - the maturity questionnaire (target: all ages) if it is not done yet;
  - new icon and thumbnails if new ones were made (`art/store/...`).
