# Strategy: how we grow Ragdoll Havoc the smartest way (26 Nov 2026)

## Targets: reach the leaders' level
Starting point: the funnels of 26 Nov (`docs/FUNNELS.md`). Old D1 was about 1 % (V8 evidence). The leader (Hyper Realistic Ragdoll) averages about 19-minute sessions.

| Metric | Now | In 1 week | In 4 weeks |
|---|---|---|---|
| Still in at 2 min | 48 % | **70 %** | 80 % |
| Still in at 5 min | 23 % | **50 %** | 65 % |
| Still in at 10 min | 10 % | **30 %** | 45 % |
| Still in at 20 min | 2.5 % | **12 %** | 25 % |
| Reach 25 KOs | 30 % | **60 %** | 75 % |
| Reach 100 KOs | 3.4 % | **15 %** | 30 % |
| D1 return | ~1 % | **8 %** | 15 % |
| Like ratio | (owner sends) | **+15 points** | 85 %+ |
| Players who open the shop | 8 % | **25 %** | 35 % |
| Shop opened → buy prompt | 11 % | **35 %** | 45 % |
| Payers per 100 players | (owner sends) | ×3 | ×5 |

## How we work, so every credit counts
1. **One loop a day (`/dagens`):**
   - read yesterday's numbers;
   - pick the 1-3 changes with the biggest effect;
   - build, publish, and have the owner test;
   - read the numbers again the next day.

   Never change many things at once without measuring.
2. **Measure everything that matters.** Custom funnel steps (AnalyticsService) for:
   - the minute moments;
   - the first unlock, terminal, map trip, car and event;
   - the tutorial steps;
   - the shop: open → view → prompt → bought;
   - the dislike reason.
3. **Test variants where Roblox allows it:**
   - the icon and thumbnails through the Creator Hub's A/B testing;
   - in-game, flip a Config switch per server half (`Config.SPLIT`, by job id) for one thing at a time, and compare the funnels.
4. **Biggest lever first:** the ranking below decides the order.
5. **The owner tests; Claude Code builds.** One quick Play for errors, then a "Test selv" checklist, then publish. No suites or reviewers.

## The levers, ranked
1. **Minutes 1-5** (the biggest leak, about 50 % lost here) → NOW item 3:
   - a new pull every minute;
   - close unlocks early;
   - the angry dummy;
   - a free mini event at 2 min;
   - the creatures and maps pointed out;
   - variety past 10 KOs.
2. **Feel and bugs:**
   - ragdolls through the floor (NOW 1);
   - lag on phones (NOW 2): phones are most of the players, and lag kills retention silently.
3. **The phone first** (NOW 7): fewer, bigger buttons, aim help, a clean screen. What the big games do on mobile.
4. **Why come back tomorrow (D1):**
   - a daily streak with a gift on day 2 that is worth it;
   - a "tomorrow" teaser at the end of a visit ("Tomorrow: the whale event");
   - experience notifications (opt-in after a wow);
   - the 2x weekends;
   - new things each day (the daily machine and missions).
5. **The middle of a visit (5-20 min):**
   - a goal ladder (missions chain into each other);
   - an event every few minutes;
   - map trips with their own fun things;
   - friends: invites and party games.
6. **Money** (NOW 8):
   - a cheap starter offer;
   - fewer and stronger items;
   - try before buy;
   - death effects and cosmetics;
   - "Popular" from the real sales;
   - a shop that shows what you get in 3D.
   - Fair, no pay-to-win: likes depend on it.
7. **Being found (discovery):**
   - the icon and thumbnails A/B tested (show a ragdoll flying from a cannon, bright and readable at phone size);
   - the title and promo text updated with every update;
   - the maturity label fixed (NOW 4) so the game can be shown to more players.
8. **Likes:** fix what the dislike reasons say, never pay for likes, and ask for a favourite only after a wow (already built).

## What the owner should send (screenshots), so decisions use real data
- **Creator Hub, last 7 days:**
  - Retention (D1, D7);
  - average session time;
  - Engagement by device;
  - Acquisition (traffic sources and Home vs Search);
  - impressions and click rate on the icon/thumbnails.
- **Monetization:**
  - sales per product and pass (last 7 days);
  - payers;
  - ARPDAU.
- **The like ratio over time,** and the latest reviews or comments if any.
- **In the game:**
  - the spawn view on PC and on a phone (Studio Device emulator);
  - the HUD on PC, phone and tablet;
  - the shop window;
  - the Map board;
  - one capture per map;
  - any bug that is seen.
- **The Roblox mail** about the maturity questionnaire, plus the old answers.
