# All our weak points (26 Nov 2026)

The owner asked: "Find alle vores svagepunkter".

This list comes from:
- the funnels of 26 Nov (`docs/FUNNELS.md`);
- the analytics and store screenshots;
- the PC and phone screenshots;
- the lab after LAB10 round 1;
- the repo itself.

Ranked by how much each one costs us. Each line ends with where the fix lives.

## TOP 10 (biggest first)

| # | Weak point | Evidence | Fix |
|---|---|---|---|
| 1 | **We only live on paid ads.** Home Recommendations are about 0. If the ads stop, the players stop. | Impressions and plays: almost all from Sponsored Ads. | Retention + likes (2-5) earn the recommendations; STRATEGY lever 7. |
| 2 | **Players leave in minutes 1-5.** | 48 % left at 2 min, 23 % at 5 min, 10 % at 10 min. | LAB10 round 2, attract mode + "try me" chain, NOW 4. |
| 3 | **The lab looks bad** (owner 3/10): an empty white slab, scattered props, nothing moves, no hero. The first thing every player sees. | Owner screenshots, round 1. | `docs/LAB10.md` ROUND 2. |
| 4 | **Phone is our biggest group and was our worst experience.** The phone fixes in 0.53 are not yet checked on a real phone (FPS, aim help, menus). | Concurrent players mostly phone; owner: "now I understand why they leave". | NOW 1 left items + a real-phone check. |
| 5 | **Likes about 65 %** (22/12). Roblox needs about 80-90 % to recommend. We do not know why people dislike. | Store page. | NOW 4 (dislike analysis + thumbs with a reason). |
| 6 | **The maturity label is at risk.** Rejected answers; "Content May Vary" from Fri 27 Nov 17:34 UTC if not resubmitted. Today it is "Minimal 16+", which already hides us from most of our 9-14 audience. | Roblox mail. | `docs/MATURITY.md`; the owner decides gore on or off and submits. |
| 7 | **The content does not match the audience.** Bones breaking, "pull ragdolls apart", blood (purple) and realistic gun names are aimed at kids of 9-14. That pushes the age label up, and up means fewer players. | Store text, Config. | The owner's gore choice; then the store text and the questionnaire match it. |
| 8 | **The store page is weak and partly wrong.** It says "UFO Beam" (removed). It has a long feature list instead of 1 clear hook. The thumbnails and icon are not tested. The name in code ("Ragdoll Havoc") differs from the store ("Ragdoll Anatomy"). | Store screenshot. | `STORE_TEXT.md` rewrite, A/B thumbnails (STRATEGY). |
| 9 | **The wall at 10-25 KOs, and nothing after "All weapons".** 47 % stop between 10 and 25 KOs. A player with every weapon has no next goal (the owner at 8,960 KOs sees "All weapons!"). | KO funnel; screenshot. | New unlock pacing (NOW 4), and a long goal after the weapons: ranks with rewards, prestige, a collection of dummy skins and machines, daily and weekly challenges. |
| 10 | **The shop converts badly.** 8 % open it; 11 % of those press buy. GOD MODE is free in the beta (a top seller given away). Weapons at R$ 99 each. No death effects or cosmetics yet. | Shop funnel. | NOW 8, product list for the owner, "Bought" funnel step. |

## Growth and social
- **Server size 1 (solo by default, V11 phase C).**
  - Nobody sees other players having fun.
  - The plaza is empty.
  - Friends do not drag friends in.
  - There are no "look at this" moments to share.
  - This was a choice, but it removes the main way small Roblox games grow (playing with friends).
  - **Fix:** a clear "PLAY WITH FRIENDS" button; invite rewards that comply with the rules; a small shared server as an A/B test.
- **No reason to come back tomorrow that people can see.**
  - The daily gift is now hidden on phones (`PHONE_QUIET`). That is good for calm, but bad for D1.
  - **Fix:** one quiet "Daily" spot in the lab (a chest that glows when ready) and a streak, not pop-ups.
- **No seasonal hook yet for December.** Christmas is the biggest Roblox month. **Fix:** a winter lab skin and a Christmas event before about 10 Dec.
- **No content for creators or sharing.** There is no replay or "best fling" clip, and no photo mode moment.

## Game and feel
- **Too much, too thin.**
  - About 72 weapons, 22 events, about 99 server systems and 129 on/off switches in Config.
  - New players drown in it.
  - Each feature gets little polish.
  - Bugs and lag have more places to hide.
  - **Fix:** cut to the best (keep what the data shows people use; hide the rest).
- **Physics: the owner's "most important".** Bodies still fall through or sink (a GroundGuard rescue was added, not a root fix). There is no proof we feel better than Hyper Realistic Ragdoll and the other big ragdoll games. **Fix:** a side-by-side feel test against them (`docs/PHYSICS.md`).
- **Lag on every platform** is not measured on a real mid phone. **Fix:** NOW 3 + measure first.
- **The maps** (the city in fog, the plaza) are in the same state the lab was in. **Fix:** after LAB10, the same treatment for each map.
- **There are few "wow" moments in the first minute.** Attract mode will help; a big first-minute event (a free mini event, the red button) must feel huge.

## Money
- Too many passes, and "Everything" is the hero of FEATURED.
- No cheap cosmetics.
- Weapons are sold one by one at R$ 99.
- No limited-time offers that people can see (on phones these are now quiet).
- The GOD MODE pass is free in the beta; decide when the beta ends.

## How we work (process)
- **Script Sync is off,** so every script goes in through the MCP: slower, more expensive and riskier.
- **Self-scoring was far too kind** (7/10 against the owner's 3/10). Fix: harsh scoring next to the reference images (LAB10 R5).
- **No automatic tests run any more** (139 test files exist). Bugs can come back unseen. Fix: run one short smoke test before each publish (about 1 minute), not the full suite.
- **Plan sprawl:** V3-V11 plans, AUDIT, MASTER_PROMPT, several root PLAN/TEST files. Sessions can read old, conflicting orders. Fix: NOW.md is the only work list; archive the rest into `docs/archive/`.
- **Huge files:** ActiveRagdoll 2.7k lines, PokeController 2.5k, ProgressService 2.2k. Changes get risky and expensive to read.
- **Publishing still sometimes needs the owner's Alt+P** (0.54.0 is not published).
- **Measuring is new:** the per-device funnels arrived in 0.53. There are no A/B tests yet, and no daily report reaches the owner without asking.

## Order to fix
1. **Maturity questionnaire** (deadline Fri 27 Nov 17:34 UTC), owner.
2. **LAB10 round 2** (look, attract mode, try-me chain).
3. **Real-phone check:** FPS, aim, menus; fix the top 5.
4. **Dislike reasons, likes to 80 %+;** fix the store page text and thumbnails.
5. **The goal after 25 KOs and after all weapons** (ranks with rewards, collections, daily and weekly).
6. **Shop:** cheap cosmetics and death effects, fewer passes, decide the GOD MODE beta.
7. **Social:** a "play with friends" button and a test of a small shared server.
8. **The Christmas lab skin and event** by about 10 Dec.
9. **Cut the features nobody uses;** archive the old plans; Script Sync on; a 1-minute smoke test before publish.
10. **The maps** get the LAB10 treatment.
