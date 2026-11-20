# Research v4: play, stay, like, favourite, return

Written 20 Nov 2026 for V4_PLAN Phase E (E0). Feeds E1 (retention), E2 (icon/thumbnails) and E3 (KPI targets).

Source labels:
- **[V: title]** is a LihFolk vault note (`C:\Users\tristan\LihFolk-Vault-V2\LihFolk Vault V2`), read from its TL;DR block or named section.
- **URL** is a web page read on 20 Nov 2026.
- **[3rd party]** marks a tracker or blog, not Roblox. Treat its numbers as rough.

Reddit could not be read (the crawler is blocked) and the TikTok pages returned no text. So the "player voice" below comes from store pages, trackers, TikTok captions in search results and DevForum. That is a known gap.

## 1. Our own baseline (why this matters)

- Launch data from 152 profiles: median play 83 s, 71 % left before 3 min, median 4 takedowns. The ThreeToys funnel step was reached by 32 % (CLAUDE.md, "Gun ladder", 10 Nov 2026).
- The game is listed as "Minimal, Ages 16+". The v3 research flagged a redo of the maturity questionnaire as the biggest single lever (CLAUDE.md, "v3"; source: echo-heist `RESEARCH_V3.md`; that CCU claim was **not re-verified** here).
- No code uses `ExperienceNotificationService` yet. `LikePrompt` already uses `PromptSetFavorite`, and `FriendsUI` already uses `PromptGameInvite` (repo grep, 20 Nov).

## 2. Retention and the first session (FTUE)

- Give control within about 10 s. The first verb should come by 30 s, the first big reward by 40 s, and the core loop should close 3+ times in 5 min. [V: First-Time User Experience and Onboarding]
- The first meaningful action should come 10-20 s after control, and the first reward inside 60 s. Use one verb, one goal and one pointer per step, with objective text of 8 words or fewer. [V: Onboarding and FTUE - Tutorials That Keep Players]
- Physics toys: the first grab should happen within 10 s. In Fling Things and People, "within a minute you have flung, been flung, and laughed", with no tutorial at all. [V: Teardown - Fling Things and People]
- In the first 60 s the player acts and gets rewarded without reading. Show no pop-ups in the first minutes of a first session, measure join time on a phone, and review the funnel weekly. [V: Discovery and the Algorithm]
- Since 15 Jun 2026, Recommended For You values 28-day retention. qPTR was removed and replaced by PTR and **first-play bounce rate**. So the first session must hook, and weeks 2-4 need reasons to return. [V: Discovery and Monetization Changes 2025-2026]; https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575
- Log funnel steps on the server only, forward-only, with a versioned funnel name. [V: Measuring Onboarding - Funnels, Drop-off and A-B Tests]
- A third-party write-up says players who leave in the first 90 s weigh heavily. It treats a sub-60 s exit rate above 15 % as a thumbnail/game mismatch. [3rd party] https://rowatcher.com/news/roblox-thumbnail-a-b-testing-what-the-data-actually-shows

## 3. What keeps players in ragdoll / physics sandboxes

- **Fling Things and People:**
  - One verb (grab and throw objects *and players*), emergent games invented by each server, a calm personal house, and friends. It sits in the "Fun with Friends" chart. [V: Teardown - Fling Things and People]
  - About 31.7k players a full year after its last update, 3.68 B visits, 2.6 M favourites, ~80 % likes. Its approval is lower than calmer games because being grabbed against your will causes friction. [V: Teardown - Fling Things and People]
  - Peak 65.8k, 80.5 % like ratio, last update 29 Oct 2025. [3rd party] https://www.rotrends.com/game/2668101271/Fling-Things-and-People
- **Bloody Ragdoll Physics** (our closest rival, released Oct 2026):
  - Numbers: peak 63k (Nov 2026), 28.8 M visits, 907k favourites, 86.8 % likes, "updated 2 min ago". [3rd party] https://rowatcher.com/games/10773926254/bloody-ragdoll-physics
  - Contents: a test lab with reactive dummies, 23 weapons (gravity gun, black hole, minigun ...), 14 syringes (zombie, exploding, balloon), drivable cars, NPC Wars (pick teams and hand out weapons), world events (Nuke, Black Hole, Fire Storm, Zero-G, Flash Freeze), spawn / slow time / rewind, and PC + phone + console. Its blood was **reduced to comply with moderation**. (Same page.)
  - Takeaway: it has almost our exact feature list and ships very often. The edge has to come from feel, the first minute, social play and cadence, not from more weapons.
- **Ragdoll Engine (classic):** 212 M visits, but now about 800 players (peak 3k, Jul 2026) and 86.7 % likes. It gives a free Push, Potion and Speed Coil for joining its Roblox group. [3rd party] https://rowatcher.com/games/2007050448/ragdoll-engine
- **Ragdoll Universe:** the round-based ragdoll shooter on Roblox peaked at only 126 CCU in Feb 2026. [3rd party] https://rowatcher.com/games/580765040/ragdoll-universe
- **Hyper Realistic Ragdoll:** dummies react per body part and "do not simply fall over", headshots kill instantly, and there is "no real progression" because most weapons are open from the start (search snippet of https://progameguides.com/roblox/complete-hyper-realistic-ragdoll-beginners-guide-roblox/; the page itself returned 403).
- **TikTok:**
  - Clips are short fails and chaos. One creator points viewers to a game with "more weapons and a revive button", and a dev promo sells "30-player chaos, fling yourself into someone, natural disasters". https://www.tiktok.com/@muscledevsofficial/video/7535673898709290295 ; https://www.tiktok.com/discover/ragdoll-physics-roblox?lang=en
  - The #ragdollphysics tag has about 38 M views (search summary of https://www.tiktok.com/discover/roblox-cool-ragdoll-physics).
- **Pattern across these games:** instant physics comedy, per-limb reactions, big world events, friends to throw, and frequent updates. Deep progression is optional: Fling has almost none.

## 4. Likes and favourites: the rules

- **Do not reward likes, favourites or social posts.** A like reminder with no reward is safe. One reference project asked once, at 10 min. [V: Community Building]; [V: Marketing to Kids and Teens - Age Rules and Paid-Promo Disclosure]
- Status of this rule:
  - It is project law (CLAUDE.md: "Never tied to liking"). It is also the widely held community reading.
  - I found **no official Roblox text** that forbids it outright. The DevForum is split, and a community thread says players say the practice "isn't against the rules" (no staff reply). https://devforum.roblox.com/t/the-issue-of-bribing-players-for-likes/4495969 ; https://devforum.roblox.com/t/is-rewarding-players-for-liking-favoriting-a-game-allowed/2926286
  - Keep it forbidden: it is a kid audience and it is ratings manipulation.
- Likes cannot be detected by code. Favourites can be (`AvatarEditorService:GetFavoriteAsync`). https://devforum.roblox.com/t/is-rewarding-players-for-liking-favoriting-a-game-allowed/2926286
- `PromptSetFavorite(itemId, itemType, shouldFavorite)` exists, and `PromptSetFavoriteCompleted` returns Success / PermissionDenied / Failed. https://create.roblox.com/docs/reference/engine/classes/AvatarEditorService
- Our call (place id + `AvatarItemType.Asset`) is still **untested live** (CLAUDE.md, v0.17.1).
- Favourite prompt timing in a reference project: 25 s after the tutorial for new players, 180 s for returning players. [V: Community Building]
- Roblox has no in-game thumbs-up prompt. The like has to be asked for in words, pointing to the game page (CLAUDE.md, v0.17.1).

## 5. Daily rewards and streaks

- Have at least one "ready" thing on every join, and never more than one automatic pop-up at a time. Scale soft rewards to the player's stage. [V: Retention and Return Hooks]
- The day boundary is a server-side integer from UTC. Write down a missed-day policy. Mark, then save, then pay. The claim takes no arguments and is rate-limited. [V: Daily Rewards System End to End]; [V: Retention and Return Hooks]
- Risk: a calendar "feels like a chore" and losing a streak causes anger, so consider a grace day. [V: Retention and Return Hooks]
- Which window each hook serves:
  - D1: a great first session plus an unfinished goal.
  - D7: short and long goals.
  - D30: content cadence plus social play.
  - Source: Docs "Retention", via [V: Retention and Return Hooks].

## 6. Experience Notifications (Roblox API)

- Three channels. [V: Experience Notifications and Return Prompts]
  - **Experience notifications:** personal, 1 per user per day, users **13+ only**.
  - **Update announcements:** 60 characters, once every 3 days, reach under-13s too.
  - **Event notifications:** for players who tapped "Notify Me".
- Eligibility: 100+ visits and not under moderation. Strings are made on the dashboard (no default), 99 characters max. Send with the Open Cloud Luau package `createUserNotification` (type `MOMENT`) or by REST. Delivery is not guaranteed, and reach shrinks when CTR is low or the **Turn Off** rate is high. (Same note.)
- Opt-in rules (same note):
  - `ExperienceNotificationService:PromptOptIn()` is client-only; call `CanPromptOptInAsync` first.
  - Its text cannot be changed, and it shows **at most once per 30 days** per user.
  - Fire it after a delayed-payoff action, with our own one-line context first.
- **Forbidden:** gating anything behind enabling notifications. (Same note.)
- Kid audience consequence: under-13s can only be reached by update announcements and events. Never build the return plan on personal notifications alone. (Same note.)

## 7. Update cadence

- Write the cadence down: a weekly rotation, weekend events, content every 2-4 weeks. Publish before go-live and gate the content by server time. Never run fake countdowns, untrue "last chance" claims or teasers for unbuilt features. [V: Update Cadence and Hype Cycles]
- Roblox docs suggest small updates every 2-4 weeks and big feature updates every 2-3 months. [V: Retention and Return Hooks]
- Play days on days 2-7 and 8-28 are ranking signals, so a steady rhythm also feeds discovery. [V: Update Cadence and Hype Cycles]
- Bloody Ragdoll Physics updates near-daily (rowatcher, above). Fling survives a year without updates on social play alone ([V: Teardown - Fling Things and People]).

## 8. Icons, thumbnails, CTR and Roblox's thumbnail testing

**Specs and must-haves**
- Since 19 Oct 2026 a custom 16:9 thumbnail is **required** for Home recommendations. [V: Discovery and Monetization Changes 2025-2026]; https://devforum.roblox.com/t/homepage-recommendation-eligibility-now-requires-a-custom-thumbnail/4945086/1
- Icon 512x512, tested at 150x150. Make 2-5 thumbnails at 1920x1080, each under 3 MB. Keep nothing critical near the bottom edge (the player-count overlay sits there). No collages, and no renders that look better than the game. [V: Thumbnails Icons and Store Page]

**What works**
- Icon (sources: [V: Game Icon Design - Readable at Small Sizes]; [V: Cross-Game Patterns - Thumbnails Icons and Titles That Get Clicks]):
  - one big subject with a readable expression, on a simple background;
  - must pass the greyscale test, and use a hue that stands apart from the genre;
  - a face, readable at 50 px, with no text or update tags.
- Strong emotion (shock, joy, fear) beats a neutral face. Warm orange/red/yellow stands out against Roblox's cool UI. Leave the title text off the icon. Icon changes alone reportedly swung CTR 30-50 %. [3rd party] https://rowatcher.com/news/your-roblox-game-icon-is-losing-you-players-before-they-click
- Thumbnails share one template, the title keeps a fixed brand with one changing slot, and the key text stays clear of the bottom. [V: Cross-Game Patterns - Thumbnails Icons and Titles That Get Clicks]
- For a ragdoll game this points to a dummy face in mid-air shock, one big readable action (cannon launch, car hit, gorilla) and a warm explosion against a cool sky. This is our inference from the rules above, not a measured result.
- CTR is only half the funnel. A misleading thumbnail raises CTR and then loses players in the first minute, which costs more. [V: Click-Through Rate]

**Thumbnail personalisation (Roblox's A/B tool)**
- How it runs:
  - Turn on 2-5 active thumbnails. A multi-armed bandit reassigns impressions every hour, per user group.
  - The result columns are impressions, qualified plays, average playtime and play-through rate.
  - Under 1,000 DAU the results may not mean much.
  - There is **no built-in icon test**.
  - Source: [V: Thumbnail and Icon A-B Testing - Method, Sample Size and Reading Results]; https://devforum.roblox.com/t/live-now-personalize-your-thumbnails-to-attract-more-users/3257233
- Roblox staff tips (https://devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689):
  - wait at least 7 days or until the next update;
  - keep up to 5 active;
  - show new content, no clickbait;
  - test thumbnails that look clearly different;
  - expect a dip after a Home surge.
  - Results: average +12 % qPTR lift, some +56 %, over 8,000 games using it.
- Method (same vault note): write down the hypothesis, metric and stop rule first; keep the control running; change one idea per challenger; run 7-14 days, not on update days; don't delete every "loser", because the bandit serves each segment its best image.
- The icon can only be tested indirectly: swap it week by week, or use Sponsored ads creatives. (Same note.)

## 9. Sound mixing

- Set attenuation per category (the default 10,000-stud max distance makes distant fights audible everywhere). Use InverseTapered so sounds don't cut off. Choose the listener position for the camera style (own sounds 2D or close). Measure every sound and level it to a category target. [V: Spatial Audio and Mixing]
- Play the neutral contact on the attacker's client. Make kill and hurt confirms 2D, personal, and never predicted. A crit needs a tonal sting above the impact, not just more volume. [V: Combat Sound Design and Feedback]
- For us: guns are "loud" on purpose (CLAUDE.md, 10 Nov). Give them a category ceiling so a Minigun plus a Nuke does not clip on phones (rule of thumb from the note above).

## 10. Maturity label (affects reach)

- Minimal or Mild games are eligible for Roblox Kids (5-8) and Roblox Select (9-15). Moderate games are eligible for Select and standard (16+). You can "Get a new rating" at any time. https://create.roblox.com/docs/production/promotion/content-maturity
- Answer for the **most extreme content reachable**, including settings and modes. Default hit feedback should use non-blood colours and leave no persistent marks for a Minimal or Mild target. [V: Gore Policy and Kid-Friendly Hit Feedback]
- Moderation can act regardless of label on realistic or excessive blood (search summary of https://devforum.roblox.com/t/updates-to-content-maturity-and-compliance-moderation-policies/3709028). Bloody Ragdoll Physics had to reduce its blood (rowatcher, above).
- So `Config.BLOOD = "off"` and `SEVERING = false` (Phase 0 defaults) fit an all-ages target. The questionnaire must still cover the switches if they can be turned on live.

## 11. What to change in Ragdoll Havoc (ranked)

Impact and effort are our estimates. H/M/L = high/medium/low.

| # | Action | Maps to | Impact | Effort |
|---|---|---|---|---|
| 1 | **Redo the maturity questionnaire for all ages** (Minimal/Mild), answered for the maximum reachable content. Keep BLOOD off and SEVERING off, or remove the live switches. | E1/E3 reach | H | L (owner, dashboard) |
| 2 | **First 60 s script:** control and a gun in hand at once, first shot under 5 s, first takedown under 15 s, first wow (cannon launch or a live event) by 60 s. No windows, eggs or cards before 90 s (`QUIET_START` already exists). Check join time on a phone. Log each step in SessionStats. | E1 | H | M |
| 3 | **Upload 3-5 honest custom thumbnails and turn on personalisation**, 7-14 days, never on an update day. Use one template and one big subject: a white dummy mid-air with a shocked face, the cannon arc, a car hit, the gorilla. Use warm blast colours on a cool sky and keep the bottom edge clear. A custom thumbnail is required for Home. | E2 | H | M |
| 4 | **Icon:** one dummy face in shock, big, warm background, no text. Make 2 variants and swap them week by week (no built-in icon test). Check at 50 and 150 px and in greyscale. | E2 | H | L |
| 5 | **Chained goals always visible:** after each experiment card the next one shows at once; the next weapon ("N kills to go") and the next machine/map are on screen. This is the D7 lever (short and long goals). | E1 | H | M |
| 6 | **Throw-your-friend social play:** surface Prank Party and plaza grab/throw early, add an invite at "with company" moments (after a combo or a bullseye), and reward only a *qualified arrival* of the invited friend, never the prompt. Fling's whole engine is friends plus throws. | E1 | H | M |
| 7 | **Daily streak with a grace day:** on every join one "ready" thing (daily chest, today's machine, Daily Experiments). A server UTC day index, a written missed-day rule, mark, save, pay. Escalating rewards in bolts and weapons, never Robux-only. | E1 | M | L (mostly exists: RewardsUI, DailyGoals) |
| 8 | **Experience Notifications:** create 2 dashboard strings (for example "Your daily chest is ready in {experienceName}" and "Today's machine: {machine}"). Show our context line, then `PromptOptIn` right after the player starts something that pays off tomorrow (the streak card). At most 1 per user per day. Watch the Turn Off rate. | E1 | M | M |
| 9 | **Favourite ask after a wow moment, once per session:** keep LikePrompt's wow trigger (bullseye, chase cleared, combo). Lower the floor to about 3 min for new players. Never ask in the first 90 s. **Verify `PromptSetFavorite(placeId, Asset)` live.** The like stays a reminder in words only. | E1 | M | L |
| 10 | **Update rhythm we can keep:** a small named drop twice a week (Thursday/Saturday per `UPDATE_DAYS`: a new event, machine or map piece), an update announcement every 3+ days (reaches under-13s), a feature update every 2-4 weeks, real countdowns only. Bloody Ragdoll Physics updates near-daily, so a silent week loses. | E1 | M | M |
| 11 | **Sound ceiling per category:** levelled targets for guns, blasts, UI and creatures, per-category distances, and own shots 2D. Big moments (Nuke, Gorilla) should feel big without clipping on phones. | E1 feel | M | L |
| 12 | **KPI dashboard (SessionReport), read the day after each release:** see the targets below. | E3 | M | L |

**E3 KPI targets** (V4_PLAN E3, checked against the sources):

| KPI | Now | Target | Why |
|---|---|---|---|
| Median first session | 83 s | > 4 min | V4_PLAN; FTUE notes want 3+ loops in 5 min |
| Reach 5 min | ~16 % (10 Nov) | > 30 % | V4_PLAN |
| Leave < 60 s (first-play bounce) | unknown | < 15 % | Roblox now ranks on bounce; rowatcher's mismatch line is 15 % |
| First shot / first takedown | unknown | < 5 s / < 15 s | [V: Teardown - Fling Things and People] (first grab < 10 s) |
| 0-takedown sessions | unknown | < 10 % | CLAUDE.md Phase 00 goal |
| D1 / D7 | unknown | > 20 % / > 6 % | D1 from V4_PLAN; the D7 figure is a rule of thumb (no official benchmarks: [V: Retention and Return Hooks]) |
| Like ratio | unknown | > 85 % | BRP 86.8 %, Ragdoll Engine 86.7 %, Fling 80.5 % (trackers above) |
| Notification Turn Off rate | n/a | as low as possible; cut a string that rises | [V: Experience Notifications and Return Prompts] |

## 12. Roblox rule flags (do not do)

- **Rewards for likes, favourites, follows or social posts.** Project rule; strongly discouraged; ratings manipulation. A reminder with no reward is fine. [V: Community Building]
- **Rewarding on the invite prompt** (open or closed). Reward only a qualified arrival. [V: Friend Invites Referrals and Experience Invites]
- **Gating any content behind enabling notifications.** [V: Experience Notifications and Return Prompts]
- **Personal notifications to under-13s.** The platform blocks them, so don't plan on them. (Same note.)
- **Misleading thumbnails or renders nicer than the game.** Moderation and bounce risk. [V: Thumbnails Icons and Store Page]
- **Fake countdowns, untrue "last chance" claims or teasers for unbuilt features.** [V: Update Cadence and Hype Cycles]
- **Maturity questionnaire answered for the default only.** It must cover every reachable switch and mode. [V: Gore Policy and Kid-Friendly Hit Feedback]
- **Paid random items** (weapon eggs sold for Robux) need odds disclosure under the 2026 rules. [V: Paid Random Items and Odds Disclosure in Practice] (title from INDEX_SLIM)
