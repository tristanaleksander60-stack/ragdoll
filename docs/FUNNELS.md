# Funnels, 26 Nov 2026 (Creator Hub, last 1 day, data 26 Nov 08:00)

## The numbers
**KOs per player** (3,450 players):

| KOs | Players | Share | Lost since the step before |
|---|---|---|---|
| 1 | 3,353 | 97.2 % | 2.8 % |
| 5 | 2,667 | 77.3 % | 20.5 % |
| 10 | 1,941 | 56.3 % | 27.2 % |
| 25 | 1,026 | 29.7 % | **47.1 %** |
| 50 | 469 | 13.6 % | 54.3 % |
| 100 | 116 | 3.4 % | 75.3 % |

**Time in game:** two funnels, nearly the same (3,554 and 3,453 players).

| Time | Share | Lost since the step before |
|---|---|---|
| 30 s | 87 % | 13 % |
| 1 min | 70 % | 20 % |
| 2 min | 48 % | 31-32 % |
| 5 min | 23 % | **51-52 %** |
| 10 min | 10-11 % | 54-55 % |
| 20 min | 2.4-2.7 % | 75-77 % |

**Shop:**
- 281 opened it, which is about 8 % of all players.
- 32 pressed a buy button (Roblox prompt), which is **11 %** of those who opened it. 89 % close the shop without trying to buy.

## What it says
1. **The first seconds work.** 97 % get a KO and 87 % stay past 30 s. Don't touch the start.
2. **Players leave between minute 1 and minute 5.** Half of the players at 2 min are gone by 5 min, so the median visit is about 2 min. This is the main leak. They have shot dummies, and then nothing new pulls them on.
3. **The KO wall is 10 → 25.** 47 % of players stop between 10 and 25 KOs. That is where the "next weapon" feels far away (the LADDER_V9 gaps, `LADDER_V9_KEEP` 5) and where the novelty of shooting the same dummies runs out.
4. **The late drop (10 → 20 min, 75 %)** is normal for a sandbox. It improves only once 2 → 5 min is fixed.
5. **The shop:**
   - few players open it (8 %), and of those, almost no one presses buy;
   - the offers do not convince: the price, the value or the look;
   - GOD MODE being free may also take away the strongest pull.

## Targets for the next week (same funnels)
- 2 min: 48 % → **60 %**.
- 5 min: 23 % → **35 %**.
- 25 KOs: 30 % → **45 %**.
- Shop opened → prompt: 11 % → **25 %**.
- Shop opened: 8 % → **15 %** of players.
