# Keep players longer (owner, 26 Nov 2026: "Undersøg hvordan vi … får folk til at blive længere")

**Today (funnel of 26 Nov):**

| Time in game | Players left |
|---|---|
| 2 min | 48 % |
| 5 min | 23 % |
| 10 min | 10 % |
| 20 min | 2.5 % |

The median visit is about 2 minutes. Good Roblox games of this kind hold 10-20+ minutes. The 1-week target (STRATEGY.md) is 5 min 50 %, 10 min 30 %.

## What keeps people on Roblox (proven patterns, best first)
1. **Something to do in the first 10 seconds, and a "wow" before 30 s.** No reading, no menus. We are partly there (dummies in front, the goal line).
2. **Always a visible next goal that is close.** "3 KOs to the Bow" works; "1,800 KOs" does not. The next reward must always be under about 2 minutes away.
3. **Timed rewards you can see counting down.**
   - "Gift in 0:47" is one of the strongest session-length tools on Roblox: people wait for the next one.
   - **Our problem:** we HAVE playtime gifts (2, 5, 10, 15 min, `PlaytimeGifts`), but `PHONE_QUIET` hides the gift on phones, and phones are most of our players. The 5-min drop lines up with that.
4. **Surprise and variety every 1-3 minutes.** Random events, a rare "golden dummy", a server-wide countdown event ("METEOR SHOWER IN 1:00"). Anticipation keeps people through the boring middle.
5. **A short chain of first tasks with a reward at the end** (tour the machines): "Try 5 machines → open a free crate". Without a mission card (the owner removed those), as the TRY! ring chain with a reward counter.
6. **Progress you can feel.** Unlocks close together early, then a long goal: ranks with rewards, a collection (dummy skins earned by KOs), machine upgrades (a bigger cannon), decorating your own lab.
7. **Mastery and score.** Distance or height scores (StuntScore exists): "Your best fling: 212 studs", a daily best, a leaderboard for it.
8. **Other people.** Playing with others is the biggest driver of session length on Roblox. We run solo servers by default (V11 phase C), so new players never see anyone.
9. **No friction:** no lag, no pop-ups over the action, no dead time (loading, waiting, empty walks).
10. **A reason to come back tomorrow, said before they leave:** a daily streak chest, "Tomorrow: free X". Roblox's opt-in experience notifications ("Your daily chest is ready").

## Our plan (build in this order, each behind a Config switch, measured per device)
1. **Gift timer back on phones, quietly** (`PHONE_GIFT_TIMER = true`).
   - **Show:** one small chip with the countdown ("🎁 1:23") in a corner, and a big CLAIM only when ready.
   - **Leave out:** red !, pop-ups and the old button.
   - **Steps:** 1, 3, 5, 8, 12, 16, 20 minutes; the first one early. The rewards get better each step; the 20-min gift is a real treat (a rare skin or weapon).
   - **Owner said YES (26 Nov 2026):** the quiet gift timer chip comes back on phones; still no red !, no pop-ups, no old button.
2. **TRY! chain with a reward** (on top of the existing ring): "Machines tried 2/6", then a free crate at 6. It shows on the goal line, not as a card.
3. **Something happens every 2 minutes.** A small server surprise on a timer, with a 30 s countdown on the goal line:
   - a dummy rain;
   - a golden dummy worth 10 KOs that runs away;
   - a giant dummy;
   - a free mini event.

   The red button's free event is part of the same rhythm.
4. **Unlock pacing:** the first 6 unlocks at about 3, 6, 10, 15, 20 and 25 KOs (NOW 4), then a reward at least every 2-3 minutes up to 20 minutes. Check it in Studio by playing a normal pace (not a test suite: 10 minutes of real play, once).
5. **A long goal after the weapons:**
   - ranks with a reward each (a dummy skin, a death effect, a title);
   - a "collection" page (skins, machines tried, creatures fed);
   - machine upgrades bought with BOLTS.
6. **Best-score moments:** a distance number pops up after every fling, a "NEW BEST!" flash, and a daily best.
7. **Others (A/B):** with `Config.SPLIT`, half of new players start on a shared server of 6 instead of solo. Compare their 10-min and D1. Keep the winner.
8. **Come back tomorrow:**
   - a daily chest in the lab with a streak (day 1-7, the reward grows);
   - at about 8 min, a quiet line: "Come back tomorrow: day 2 chest";
   - ask for Roblox experience notifications once, after the first good moment.

## Measure
- **Custom funnel steps:** gift claimed (per step), machines tried, surprise seen, best score, chest claimed. Split by device.
- **Compare against the 26 Nov funnel after 2 days.**
- **Success:** 5 min from 23 % → 40 %+, 10 min from 10 % → 25 %+.
