# Ragdoll Havoc (Roblox ragdoll game)

Studio place: "[💥] Ragdoll Havoc", placeId 126037745825106. Game name: **Ragdoll Havoc** (owner changed it back on 10 Nov 2026; 'Santa's Sandbox' is dropped).
Talk to the owner in Danish, short and plain.

## How every session runs (owner order, 19 Nov 2026)
The owner types **`/klar`** (`.claude/commands/klar.md`) or **"klar"**. Then follow `docs/MASTER_PROMPT.md` ("The prompt"): the newest plan with unfinished steps (now `docs/V8_PLAN.md`, the new Ragdoll Havoc from 2/10 to 10/10, evidence in `docs/V8_EVIDENCE.md`; V7/V6/V5/V4/V3 hold the history), step by step from its State line: automatically and without questions; quality first, then speed, then cost. The PC session (Studio + Roblox Studio MCP) is the main one. A cloud session (no Studio) only does research and code, and lists the Studio steps under PC TODO.

The owner types **`/tjek`** (`.claude/commands/tjek.md`) for a full quality audit of the whole game on every parameter, then fixes to 9/10+ per area (`docs/AUDIT_PROMPT.md`, results in `docs/AUDIT.md`).

## Code and deploy
- This folder is synced into Studio with Script Sync (each service is the sync root):
  - `ServerScriptService/` -> ServerScriptService (code in `Server/`)
  - `ReplicatedStorage/ReplicatedStorage/` -> ReplicatedStorage (code in `Shared/`)
  - `StarterPlayerScripts/StarterPlayerScripts/` -> StarterPlayer.StarterPlayerScripts (code in `Client/`)
- `src/` is a leftover from before the restructure; not synced.
- `X.luau` = ModuleScript, `X.server.luau` = Script, `X.local.luau` = LocalScript. `--!strict` everywhere.
- Parts, attributes and tags are built by code at startup. Imported models (`N7Assets` in ReplicatedStorage and ServerStorage) live only in the place file: remind the owner to save the place.
- After editing, check the script landed in Studio (Roblox Studio MCP) before testing; sync can lag.

## Tests
- `ServerStorage.RunSelfTest = true`, then Play. `Server/Tests/T01..T59` print `[SelfTest] PASS/FAIL <name>` and `DONE pass= fail=`. Full suite ~10-12 min; run only affected tests while working, the full suite once per phase.
- Known flaky: T15, T19, T24, T25, T27, T32. LabLive must be off during tests.
- LayoutCheck (client) checks 8 screen sizes; it is the phone evidence.

## Quality process
- Use the LihFolk vault (plugin `lihfolk`, folder `C:\Users\tristan\LihFolk-Vault-V2`). No Python on this PC: grep `INDEX_SLIM.md` / `SYMPTOMS.md` and read notes' `tldr:start` blocks.
- One blind reviewer per phase against `skills/quality-score` rubrics, pass bar 8.5, max 3 fix rounds.
- Copy what the top Roblox ragdoll games do (Ragdoll Engine, Ragdoll Reality, Fling Things and People).

## Owner decisions
- Purple blood; severed limbs allowed behind the `SEVERING` switch in Config; real-ish gun names via nicknames (G17, Deagle), no trademarks. **Phase 0 (19 Nov) changed the defaults, each one switch away:** `Config.SEVERING = false`, `Config.BLOOD = "off"` ("purple" = the old choice), `Config.TOY_NAMES = true` (G17 -> Popper ...; ids unchanged), `Config.MILD_TEXT = true` (hit line by body region). Owner to confirm.
- Gunshot sounds: community uploads.
- Own lab per player, others' plots not visible, shared plaza (players can hit each other, no damage), friends enter a lab by invite.
- Christmas theme on now; admin/troll menu owner-only.
- No new free-form text in the world; nothing from TikTok LIVE is saved or counted (`Source = "Live"`).

## Open with the owner
- Create developer products (weapon tiers 25/49/99/199, event packs) and gamepasses ULTRA/VIP; send IDs.
- Publishing: since 20 Nov 2026 the `/klar` run publishes by itself at the end of a whole plan, through `docs/RELEASE.md` (gate, backup, publish, restart old servers, check). Server size 6 (`Config.SERVER_SIZE`, release 0.20.0; was 10).

## 10 Nov 2026
- M11 PASSED (blind review 9.2 system / 9.2 UI): real Roblox clothes + hair on the crowd (CrowdService), small quiet bubbles (DummyLife), auto dead-body monitor beside the mouse (HospitalCharts, Settings "Dead monitor").
- Guns: one realistic recording per gun (SoundManifest: G17 LilHuggito "Glock 9mm Shot Close", Deagle/Shotgun SoundEffects+ "HM"), loud, tail fades (owner: must sound like real guns, not airsoft).
- Admin: "ALL WEAPONS FOR EVERYONE HERE" (AdminService.setAllWeapons, Workspace "OwnerParty", session only, ends when the owner leaves; everyone gets a toast) and an OWNER tag over the owner's head.
- Saving verified against real DataStores (profile, boards, play time on leave).
- Robux LIVE (owner created them on the dashboard): passes ULTRA 2075722841 (249), VIP 2075632736 (149); products Weapon25 3730106832, Weapon49 3730106862, Weapon99 3730106880, Weapon199 3730106940, DummyRain 3730106983, MegaBomb 3730107002, ZeroG 3730107024, BouncyFloor 3730107042, FlashFreeze 3730107067 (Shared/Shop.luau, Shared/Events.luau). The owner owns both passes (creator). Open Cloud reads work; uploads need an approved folder (not set).
- Launch gift: LaunchGift.luau gives everyone ONE free weapon egg until 10 Dec 2026 (DataStore LaunchGift_v1 claim). Never tied to liking (Roblox forbids rewarding likes). LikePrompt.luau: a "like us" window after 6 min of play + "LIKE US" in MENU (HudMenu CELL 172x46 so 7 fit on phones).
- Launch numbers (10 Nov, from Profile_v1, 76 players): median 1.6 min, 71% left before 3 min, 16% reached 5 min, NO new player opened an egg, LaunchGift claimed once = live build was older. Open Cloud analytics (`/analytics-query-api/v1/universes/10774775314/metrics`, scope universe.analytics:read) works but lags 1-2 days; read Profile_v1 for fresh data.
- Retention fixes: PlaytimeGifts.luau (weapon egg at 2/5/10/15 min a day, DataStore PlaytimeGifts_v1, clock "GIFT m:ss" on the WEAPONS tile via GiftClock.luau), ProgressUI egg-offer card "Free egg!" (opens when calm; won weapon equipped; waits while picking a slot). T43_GiftsSpectate.
- Admin SPECTATE (Spectate.luau, AdminService "Spectate" sets ReplicationFocus, PlotPrivacy.setPeek shows the watched lab). Admin menu = SHOP -> SERVER EVENTS -> ADMIN EVENTS (OWNER).
- Dead monitor now settings key `deadMon`, default OFF (old `monitor` key ignored).
- Lab hazards like the ad thumbnail (Playground.luau, labs only): lava pit, bullseye where the cannon lands (Playground.cannonLanding, "BULLSEYE!" notice), red spike blocks, spinning spike mace, bigger red wrecking ball that throws players; first-minute tip toast. Backup `2026-11-10-retention-m12`.
- Hand-drawn icon set (owner: "less AI-like"): art\tools\Doodles.cs + build-icons.ps1 -> art\icons\*.png, uploaded with Studio MCP upload_image (serve art\ over a localhost HttpListener, batches of 8), ids in Shared\DrawnIcons.luau, registered at client start; ToolPicture prefers drawn "tool_<id>". Store art: art\tools\Scenes.cs + build-art.ps1 -> art\store\icon.png + 3 thumbnails (sent to the owner to upload).
- Explosions by size: SoundManifest banks boomPop/boomMid/boomBig/debris/cannonShot/slam, FxController.blast(); Mega Bomb event now plays as BigBoom.
- Maps: WorldMaps.dress (skirting, cornice, pilasters, windows, floor border per LOOKS) + EXTRAS (Office cubicles/reception/cabinets/whiteboard; WhiteRoom grid, course, crash pad, foam pit).
- Blind review fix round 1 done (PlaytimeGifts backoff/rollback/minute saves/BindToClose; egg card only with no window open and 2.5 s quiet; hazard tip only with a lab; Spectate bar narrow-screen + pop; lava/spikes throw dummies too).
- Dummies: sculpted grey mannequin skin from ReplicatedStorage.DummySkin (place file only; a Creator Store R15 "Tall Dummy Rig", 2 malware scripts removed), worn client-side by Client\DummySkins.luau (LocalTransparencyModifier, 12% overlap at joints; no network cost), bullet holes raycast onto the skin. Thin R15 scales + smaller head in DummyFactory. Dead = green (VitalsService.paintDead), revives after REVIVE_AFTER 10 s (3 s out cold, then up). All but Brave flee bangs/guns, zigzag + flailing arms; speech bubbles off (DummyLife BUBBLES=false).
- 7 big weapons: Grenade, C4, Minigun, Sniper, RPG, GravityGun, Nuke (Toys, ToyService grenade/c4/rpg/nuke, SoundManifest.GUNS, models built by code in N7Assets.Weapons: place file only), icons in DrawnIcons (all 76 re-uploaded centred).
- Lab leaderboards (LeaderboardService.buildLabBoards: TAKEDOWNS + TIME PLAYED at each lab's far end, glow frame, crown, spotlight). Phone left column: Shop, Weapons, Places; SANDBOX in MENU on phones.
- Lighting: ZoneLighting Day profile (sun 3, low ambient, env reflections), SunRays, DepthOfField, stronger grade. Owner should set Lighting.Technology = Future in Studio.
- Full audit 10 Nov (PLAN-2026-11-10-fuld-test.md): first 2 eggs give a WOW weapon (ProgressService.WOW_POOL), Grenade unlock 14 / Minigun 58, egg offer never gives up, Toast time by text length + queue 4 + isRedirected fix, gold "next weapon" bar on the WEAPONS slab (PokeController.setNext), hold-to-fire guns (LabCamera), automatic-gun burst budget 26/s (HitService), DummySkins/PlotPrivacy leak fixes, Metrics fixed event names + item custom field, greeter never flees. Suite 43-44/47 (T19/T25 flaky). Phase D still open: ALL WEAPONS pass + starter pack (owner creates on dashboard), badges, player grab/throw in plaza, free ULTRA as 5-min gift.
- Phase D (10 Nov): free ULTRA now the 5-minute gift (Shop.FREE_ULTRA_AFTER 300, MoneyService); badges (Shared/Badges ids 0 until the owner creates them on the dashboard and sends ids; BadgeAwards: Welcome, FirstTakedown, FirstEgg, FiveMinutes, Bullseye, Takedowns100, Nuke, Takedowns1000; Studio/tests never send); grab and throw players in the plaza (Server PlayerGrab + Client PlayerGrabClient + PlayerBody.setHeld/freeHeld, remote PlayerGrab; jump 3x (phone: RAGDOLL 3x) to wriggle, HOLD_MAX 6 s, every end = plaza knock gap, PAIR_GAP 10 s, VICTIM_GAP 8 s); T44_GrabBadges. PASSED blind review 8.9 after fix round 1. Backup `2026-11-10-phase-d`. Left: badge ids from the owner; open labs. Fixed PokeController.setNext error spam after the bar rebuilds. Note: execute_luau on Client gets its own module copies; test client code through the server's remotes.
- Badges live: Welcome 2511026255505077, FirstTakedown 3373445548782736, FirstEgg 3474625754262331, FiveMinutes 260717568329975, Bullseye 3887603893235173 (others 0: owner made only the 5 free ones). Icons: art\tools\build-badges.ps1 -> art\badges\*.png.
- Steam look pass (10 Nov): Lighting.LightingStyle = Realistic + PrioritizeLightingQuality (new Studio's "Future"; settable from execute_luau Edit, Technology is not); realistic sky (Creator Store 9589448285; old sky in ServerStorage.OldSky_Backup); MaterialVariants in MaterialService.AssistantMaterials (LabFloorTiles, SafetyRubber, PaintedSteel, BrushedSteel, LabWallPanels; place file only) used via Server\Systems\Finish.luau (Playground defaults -> painted steel, spikes/mace chrome, lab floor tiles, rubber test mat, baseplate tiles, WorldMaps Metal -> painted steel, concrete tower with yellow stair edges). Stray generated dummy model moved Workspace -> ServerStorage.StrayGeneratedDummy. Owner must SAVE the place.
- Gun ladder (10 Nov, data: 152 profiles, median play 83 s, 71% < 3 min, median 4 takedowns; funnel ThreeToys 32%): 13 new guns in Toys (Revolver 5, SMG 17, AK 27, FlareGun 65, M4 95, DoubleBarrel 140, TommyGun 175, AutoShotgun 340, LMG 430, DMR 530, LaserRifle 680, Railgun 1050, GoldenDeagle 1600) + SoundManifest.GUNS + FxController.REAL_GUNS (tracer colour) + DrawnIcons; models built by code in N7Assets.Weapons (place file only). Early ladder: Slap 7, Grenade 10. PokeController.autoEquip: an unlocked gun/explosive goes straight onto the bar (replaces Shove/Punch/Crowbar/Bat), ProgressUI toast "It's on your bar"; first minute waits via whenFree. 69 tools. Backup `2026-11-10-gun-ladder`.
- Round 5 APPROVED plan: PLAN-2026-11-10-runde5.md, start prompt PROMPT-runde5.md (UI like the big game, locked weapons with TRY FREE, reload/ammo/first person/sounds, roaming visitor ragdolls, better lab models, multiplayer portal + server list). Not started as of 10 Nov.
## Round 5 (started 10 Nov 2026, auto-approved; PROMPT-runde5.md wins)
- No background music (owner, 10 Nov): Client\Radio.luau deleted, RADIO gone from MENU / WEAPONS footer / Keybinds (J). Server still accepts old "Radio" prefs (harmless).
- Phase 00 DONE (v0.14.0): SessionStats (Server, DataStore Session_v1 key userId_jointime: v, plat, touch/keys/pad, w/h, boot, firstShot, shots, hits, knocks, takedowns, eggCard, eggOpened, autoEgg, lab, left; Studio writes only with ServerStorage SessionStudio=true) + Client\SessionClient (Hello/EggCard/FirstShot, remote Session). Read script `tools\SessionReport.luau` (Studio Edit, table per build x device). Takedown fixes: first hit on your greeter = +1 (ProgressService.greeterHit, once), onDown retries once after 0.8 s when the state report beat the server hit, 3 rounds in arms/legs within 8 s fell a body (ActiveRagdoll LIMB_SHOTS_TO_FELL). "+1 TAKEDOWN" pop for the first 300 s (ProgressUI.popTakedown). First egg opens by itself at 60 s for anyone who never opened one (ProgressService.firstEgg, client "AutoEgg"). Touch: aim help (PokeController.ASSIST, nearest body within 12% of the short side), Client\TouchShoot (SHOOT button in HudSlots "Shoot" = GRAB's box, centre crosshair, "TAP A DUMMY!" hand until the first shot, 45 s). T45_FirstMinute; T38 updated. T23/T38/T45 pass, LayoutCheck 0 problems. Goal still to measure after a day live: median first visit > 3 min, < 10% with 0 takedowns (run SessionReport). Bump Config.Version with every live change.
- Phase 0 DONE: 5 redrawn icons uploaded (DrawnIcons), SMG blue / LMG olive / AutoShotgun dark red in Toys. Analytics API refused our query shape (400); Session_v1 replaces it.
- Phase 1 DONE (UI like the big game): Client\HudPlus (big red WEAPONS button HudSlots "Weapons" with next weapon + "Next: X a/b" + bar, replaces the bar's gold line: PokeController.NEXT_ON_BAR=false; PokeController.weaponsHud = it (GiftClock tag); LEVEL badge + XP line following ToyBar.Bar (Shared/Level: takedowns*10 + minutes*4); TODAY'S DEAL card (Shop.STARTER_PACK 0 = SOON, R$29, 3 eggs + Revolver via RewardsService/Purchases "StarterPack"); sandbox column PC only: 1ST PERSON V (Client\FirstPerson), SLOW-MO Z, REVIVE ALL X, RESET Del (Server SandboxService, own lab, paced; VitalsService.reviveNow); key chips on launchers). Client\RewardsUI (J): 7-day calendar (DailyGoals.STREAK_WEAPONS day 2 AK, day 7 Minigun; owned = extra egg), play gift clock, dares (goals), trophies (BadgeService), group gift (Shop.GROUP_ID 0 = SOON; Server RewardsService, DataStore GroupGift_v1). Left column KEEP = Shop, Rewards, Places, Sandbox, Settings (+Menu); phone PHONE_KEEP = Shop (+Menu), Rewards/Places/Sandbox/Settings in MENU. COLUMN_TOP 144 / PHONE 130 (set in HudMenu). Keys: Doctor V->L, Clip L->Semicolon, FirstPerson V, Rewards J, SlowMo Z, ReviveAll X, Reload R. Kit HudButton.setCount/setKey. T46_RewardsSandbox; T42 calendar updated. LayoutCheck 0 problems.
- Phase 1b DONE: start bar = G17, Grab, Punch (Toys.DEFAULT_LOADOUT); Toys.SLOTS fixed 6; Bat 2, Crowbar 4, Shove 6; ProgressService LADDER 3 grandfathers Bat/Crowbar/Shove for older profiles (grandfather(profile, td, eggs, fromLadder)); early unlocks (<=10) auto-equip. Weapons window: "x/69 OWNED", red kills bar, LOCKED, BUY price, EQUIP/EQUIPPED (green), TRY FREE on locked cards (Server TrialService: 2 min, once/weapon/UTC day in DataStore Trials_v1, one at a time; attrs TrialWeapon/TrialUntil honoured in ProgressService.isUnlocked and ToolCatalog.stateOf; bar prunes it after). Kept 6 slots (LayoutCheck fits; starters fill 3). T35 updated, T47_TryFree. Watch Session_v1: if 0-takedown share rises, give Bat back at 0.
- Phase 2 DONE: magazines Shared/Ammo (SPECS per gun, SERVER_SLACK 0.25); HitService.takeRound refuses "Reload" (off during self-tests unless HitService.AMMO_IN_TESTS), remote Ammo "Reload" for R; Client\AmmoClient ("12 / 17" by the crosshair and on the slab, reload ring, auto reload, R or tap the counter). First person V: Client\FirstPerson (LockFirstPerson) + Client\Viewmodel (clone of HeldTool at 0.55 scale, forearm, sway, kick via AmmoClient.onSpent, muzzle flash, reload dip). Sounds: 13 own recordings + 7 reload banks in SoundManifest (mostly "M9K" uploads by diman's group), GUNS[*].reload, FxController.reload. T48_Ammo; T41 passes (55 banks).
- Phase 2b IN PROGRESS: 21 real mesh models in N7Assets.Weapons (attr Round5; place file only, old box models in ServerStorage.OldWeapons; normalizer tools\NormalizeWeapon.luau: Grip origin, -Z forward, Tip, Weld per piece). Malware scripts "Runtime"/"ScreenBuilder"/"CoreValidation"/"LightConfig" found and removed. Mechanics: Server WeaponMechanics (pellets, sniper/rail pierce, flare, GoldSpark), ToyService grenade throw+countdown, C4 remote detonation (Ammo remote "Detonate", attr C4Armed), RPG trail, nuke mushroom; Client GunFeel (AK climb, LMG/SMG spread, revolver fan, M4 burst, minigun spin-up, railgun charge, zoom RMB/ZOOM button, laser beam, double-barrel recoil), blade slash, Bat/Golf lift up. T49 passes. Not done: icon redraws to match new models, Viewmodel tuning per model.
- Owner extras (PLAN-2026-11-10-ctr-og-fixes.md, approved; icon/thumbnails SKIPPED by owner): Roblox Assistant's work was NOT in the place. Built: guns fire on press in the air + hold (PC player view, PokeController); lab boards retry reads every 5 s until filled (LeaderboardService); 3 PUT RAGDOLL HERE stations (Playground.STATIONS: SKY LAUNCH, FLING PAD, ROCKET WALL + crash wall; sign on the cannon); NPC Chase (Server ChaseService: 4-10 chasers in your own lab for players < 300 takedowns, 90 s in then every 6-8 min, 100 HP, 4/punch, respawn 1 s, +3 bonus; Client ChaseHud); LikePrompt after a wow moment (BULLSEYE, chase cleared, combo 10) after 3 min, else 8 min, mentions Favorite; Client NpcGlow (purple pulse, green = dead). T50_ChaseStations. Owner: set Server Fill = Maximum on the dashboard.
- Phase 3 DONE: Server VisitorService (3 roaming visitor ragdolls per owner in their own lab, going for CannonPad/StationPad/TrampolinePad/LavaPool; ROOM_KEEP 8). Real cannon model ServerStorage.N7Assets.Props.LabCannon (asset 14278051688, place file only).
- Phase 4 DONE: Server PortalService (MemoryStore Servers_v1, fun server names, List/PlayNow/Join/Own/Solo, ReserveServer + TeleportAsync; Studio answers Refused) + two portal arches in each lab (PortalSolo, PortalMulti); Client PortalUI (server list, black screen kept through the teleport, cleared on Refused or after 12 s). T51_Portals.
- Phase 5 DONE (v0.15.0): full suite 52/55 (T19, T25, T32 flaky). Blind review: system 7.9 -> 8.6 PASS; UI 7.6 -> 8.0, the last open point was phone evidence: LayoutCheck now also checks ChaseHud and ZOOM -> 0 problems on 8 screens (HudSlots "Zoom": phone over SHOOT in THROW's place, tablet left of SHOOT; HitInfo rests during a chase; ChaseHud steps aside for the pick chip). No 2nd UI re-review run (credits). Owner feedback: NPC glow is now a faint GREEN pulse (NpcGlow), not purple; HudPlus "NEXT: <weapon>" picks the next exciting weapon (HudPlus.goalOf), "N kills to go!", gold breathing when <= 3 left. Known: the phone RUN button (HudSlots Sprint) is not in LayoutCheck and may touch RAGDOLL on short phones. Not done: icon redraws for the new models, Viewmodel tuning per model. Backup `2026-11-10-runde5-fase5`.
- Aim + next unlocks (v0.16.0, 10 Nov): the gun follows the mouse (touch/pad/shift-lock: screen centre). AvatarMoves.ownAim -> pitch/yaw from the chest, gun stance goes "ready" while aiming (not on the run), shoulders lift by pitch, waist turns up to AIM_TURN_MAX, a standing body turns past it; a learnt per-gun trim (trimAim) puts the barrel on the point (measured 0-1 deg ahead/up/down/sides/behind). Sent ~10/s on UnreliableRemoteEvent Net Aim -> Server AimService (clamp, 0.02 rad steps, 20/s cap) -> character attribute Aim, drawn on every screen. Studio hook: player attr AimTestPoint. T52_Aim. Hotbar: Client\NextUnlocks = the next 3 weapons by kills (not owned), dark card, gold-ringed padlock, "310/330", gold bar; tap opens WEAPONS; HudPlus.drawWeapons feeds it. PokeController.plan(..., upcoming): one row = 3 extra slots (PC side margin NEXT_SIDE 226, CHIP_MAX 720); two rows (phones, iPad player) = the cards stack in the first column instead of the bar's WEAPONS slab (it comes back as CANCEL while picking). LayoutCheck 0 problems; T23/T35/T38/T45/T47/T48/T49/T52 pass. Backup `2026-11-10-aim-next`.
- Quiet HUD + 3 slots (v0.17.0, 10 Nov, owner): Toys.SLOTS = 3 (+ the 3 locked NextUnlocks cards; older saved loadouts keep their first 3: LoadoutStore.validate). Bar plan: one row WEAPONS + 3 slots + 3 next; too narrow (phones) = the next cards on a row under the slots (plan.nextRow). "+1 TAKEDOWN" small (100-150 px), silent, first 120 s only. LEVEL: 22 px badge, short 3 px line, silent level-up. HudSlots.QUIET controls drawn at HUD_SCALE 0.8 via a UIScale "HudScale" (touch never under 44 px; NEXT weapon button and touch fire buttons keep size); launcher column Controller.HUD_SCALE 0.85 with caption floor C.HUD_CAPTION_MIN 11. LayoutCheck uses the scaled rects; mouse tap floor 32 px (touch 44). LayoutCheck 0 problems, live 0; T23/T35/T45/T46 pass. Backup `2026-11-10-quiet-hud`.
- In-game favorite (v0.17.1, 10 Nov): LikePrompt window "Favorite Ragdoll Havoc?" with a FAVORITE button = AvatarEditorService:PromptSetFavorite(game.PlaceId, Asset, true) (Roblox's own prompt, no leaving; does not show in Studio, untested live), PromptSetFavoriteCompleted Success -> thanks toast, no more auto-asks. Roblox has NO in-game like/thumbs-up prompt (only SocialService:PromptFeedbackSubmissionAsync for written feedback), so the window still points to the game page for the like. MENU entry is now "FAVORITE". No reward (Roblox rules).
- M12 started. Name is Ragdoll Havoc again (Config.GameName + 4 player texts). Owner dropped the desert oasis: improve the spawn lab instead; dead monitor off by default (on only via Settings).

## Phase 0 (19 Nov 2026, branch `fase0`, v0.18.0; plan: echo-heist docs/ragdoll-havoc/MASTER_PLAN.md)
- Gamepad: Shared\PadMap (pure) + Client\GamepadControls (CAS at Medium+100, under the kit's B close). R2 fire at screen centre (hold = auto), L2 zoom, LB/RB + D-pad L/R slots (tabs in WEAPONS), Y WEAPONS, X grab/throw, B ragdoll (Spectate: B stop, LB/RB next), Select view cycle (player -> 1st person -> lab; sticks orbit/pan), D-pad up SHOP, down MENU (Start is Roblox's). AutoSelectGui off; MENU shows every launcher to a pad. Pad glyphs in onboarding hints.
- Portrait phones: HudSlots `ctx.portrait` (thumb row: SHOOT/GRAB by jump, RUN + THROW/ZOOM above), bar over it (PokeController.PORTRAIT_BOTTOM 180), full-width toasts under the top cluster, toasts shrink text to fit. Phone: LAB VIEW + RUN after `Config.QUIET_START` (90 s), BUILD in MENU (SANDBOX entry was commented out by accident), landscape RUN shares THROW's box. LayoutCheck: 4 portrait phones + RUN. Not forced to landscape.
- Quiet start 90 s: no view card (`Config.VIEW_CARD`), egg card / auto egg / gift note / tips after 90 s, chase at 150 s, the first-minute hint steps aside for a toast.
- Bar: `Toys.SLOTS = 6`; NEXT cards only from `Config.NEXT_UNLOCKS_MIN_TAKEDOWNS` 25 and `NEXT_UNLOCKS_AFTER` 180 s (BarRules.nextUnlocksShown).
- SessionStats: `pv` (PlaceVersion), usedPad/Keys/Mouse/Touch + `input`, portrait, funnel `step`; tools\SessionReport updated. SOON cards hidden while ids are 0. STORE_TEXT.md, TEST-FASE0.md.
- New tests T53_Gamepad, T54_PortraitHud, T55_QuietStart, T56_BarSixSlots, T57_MildContent, T58_SessionRecord, T59_NoSoonCards; T35 updated. Pure ones were also run off-Studio with a lune harness. Nothing here was play-tested in Studio yet.

## Phase 1 (19 Nov 2026, branch `fase1`)
- Experiment cards: Shared\Experiments (pure list, step, daily pick) + Server ExperimentService (leaf; events from ProgressService takedowns/eggs and Playground cannon/bullseye/hazards; remote Experiment Card/Done/Late, client Skip; stars as player attr Stars, `onReward` hook) + Client ExperimentCard (HudSlots "Experiment": phone = big WEAPONS box, hidden there by `Config.PHONE_HUD_MAX7`; else top middle in Chase's place) + EXPERIMENTS window (SKIP, friend's code). MENU "EXPERIMENTS" for pads.
- X-ray replay (`Config.XRAY_REPLAY`): ReplayController copies go see-through blue with neon bones, "CRACK! +N" (ShareCode.scoreOf), SHARE CODE (Shared\ShareCode: toy + score, checksum), "CLIP IT" = the old Record clip.
- Device tiers (Shared\DeviceTier, `Config.DEVICE_CAPS`): visitors/chasers per device (phone 1/4). Bodies already have one network owner (the lab's player) for life.
- Tests T60_Experiments, T61_ShareCode, T62_DeviceTier; T54 has the Experiment box. TEST-FASE1.md.

## Phase 2 (19 Nov 2026, branch `fase2`)
- Economy (`Config.ECONOMY`): Shared\Economy (pure: eco clean/count/rollDay/price/nextBuy/redeem, BONE JOURNAL 15 pages) in profile field `eco` (ProgressService.ecoOf/ecoChanged, merge keeps the session's). Server EconomyService: bolts from experiments (stars x10), daily bonus +30, journal +25, playtime gifts +40 instead of eggs (`EGG_RATION`, PlaytimeGifts.RATION), BuyNext = cheapest locked weapon for bolts (grantWeapon "Bolts"), like-milestone codes (`Config.LIKE_CODES`, owner sets live). Remote Economy. UI lives in the EXPERIMENTS window.
- Daily Experiments: Experiments.daily(UTC day) dealt first (ExperimentService.setDeck), same on every server.
- Ladder v2 (`LADDER_V2`): rungs above 30 squeezed x0.363 (top 600), price tier bounds squeezed too (same prices).
- Shop.OFFERS: the monetisation ladder as data, ids 0 (owner creates them). DoubleBolts attribute doubles bolts.
- Tests T63_Economy, T64_Ladder, T65_OffersCodes; T43 runs with RATION off. TEST-FASE2.md.

## Phase 3 (19 Nov 2026, branch `fase3`, v0.19.0)
- Christmas from 1 Dec (`CHRISTMAS_FROM_DEC1`, Christmas.FIRST_START); Christmas lab (`CHRISTMAS_LAB`): Playground builds "ChristmasLab" per lab (chimney launcher, present trap, sleigh ramp; Playground.CHRISTMAS_SPOTS), shown while Workspace "Christmas"; events Chimney/Present. Advent (`ADVENT`): Experiments.advent(day) first in the daily deck 1-24 Dec.
- Prank Party (`PRANK_PARTY`, `PARTY_MAX` 6): PartyService (Lab.ownerAt groups every 5 s) -> ExperimentService.startParty: one shared card, everyone's events count, everyone paid. `SERVER_SIZE` 6 is documentation for the dashboard setting.
- Update rhythm: `UPDATE_TITLE`, `UPDATE_DAYS`; Shop.WHATS_NEW[1].version must equal Config.Version (T66). docs/CREATOR_KIT.md.
- T66_ChristmasParty; T40, T58, T63 adjusted. TEST-FASE3.md.

## Release 0.20.0 (19 Nov 2026, branch `release` from `fase3`; not merged, never run in Studio)
- One owner checklist for everything: **TEST-ALT.md** (the TEST-FASE0..3 files point to it).
- Bug fixes from the review of `main...fase3`: the profile's `eco` was never written by UpdateAsync (bolts lost every save; ProgressService save/saveOnto); a Prank Party card past its time stayed up forever (ExperimentService timer); play-gift texts promised eggs while EGG_RATION pays BOLTS (GiftClock, RewardsUI); T33 expected organ names under MILD_TEXT; T22 expected a 7-tool bar refused (validate cuts to SLOTS); strict-type fixes (string.upper on gsub, advent list, PadMap, HudMenu).
- Throw your friend (`PARTY_THROWS`, `THROW_COMBO_WINDOW` 4, `THROW_COMBO_CHAIN` 20): Prank Party members may grab/throw each other inside that lab (Zones.mayGrab, used by PlayerGrab and PlayerGrabClient; attribute PartyLab = owner UserId while the card runs); plaza stays as it was. A thrown player landing in the cannon/bullseye/station/trap within the window = TOSS COMBO (ExperimentService.thrown -> tossCombo): "Combo" pop on both screens (ExperimentCard.combo), x2/x3 chains, a "Toss" event for the thrower (party card PartyToss "TOGETHER: toss friends into 3 traps", journal page "Toss"). Playground passes trap names (TRAP_NAMES). T67_PartyToss.
- Shop.OFFERS sold (owner pastes ids into Shop.OFFERS only): Shared\Offers (GRANTS + effectsOf/covers), Server OfferService (remote Offers Buy; products via Purchases "Offer:<key>" in Orders_v1, deliver once per purchase id via eco.got; passes checked on join + PromptGamePassPurchaseFinished, session-only attributes PassToys / DoubleBolts / VipLab / EventsPass / Offer_<key>), PassToys honoured by ProgressService.isUnlocked/isMine and ToolCatalog.stateOf, VipLab +`VIP_LAB_VISITORS` in VisitorService, EventsPass = free event per `EVENTS_PASS_GAP` in EventService.onBuy, SHOP window OFFERS section (EventShop.buildOffers; id 0 hidden live, TEST in Studio). T68_Offers.
- Static checks: lune compile all changed files, luau-lsp 1.53.1 analyze (roblox defs; only type-only noise left), selene (std roblox, pre-existing warnings only), LihFolk check 0 errors / 0 warnings. No stylua/selene config in the repo, so no reformatting.

## World/Feel v2 (19 Nov 2026, branch `world-polish` from `release`; not merged, never run in Studio)
- Switches: `Config.WORLD_V2` (code-built dressing + dummy suits) and `Config.FEEL_V2` (hit feel + limb guard); both false = 0.20 exactly. Budgets per device tier: `Config.FX_CAPS` (lights, flashes, particles, trails, casings, ragdolls), read through `Shared\FeelTuning` (pure: strength -> trauma/stop, flop tiers, GUN_FX per gun, platOf). `WORLD_V2_LAB_PARTS` 320, `WORLD_V2_LAB_LIGHTS` 12, `COMBO_SLOWMO` 5.
- World: `Server\Systems\WorldDress` builds into `Workspace.Playground.<Lab|Plaza>.WorldV2` (called at the end of Playground.build, and into ChristmasLab from buildChristmas). Pictures only: every part anchored, CanCollide/CanQuery/CanTouch off; names start with V2. Lab: backdrop wall (panels, chamfered pilasters, cornice, striped skirting, lamps), CRASH TEST ZONE gantry at z -9, floor arrows + HUMAN CANNON board, dotted flight arc cannon -> bullseye, warning boards, station boards, tower rails/sign, wrecking-ball braces, ramp rails, cannon beacon, crates/barrels/tyres/carts/light towers/cables; Christmas: chimney cap + hearth, bow, sleigh runners. ~296 parts, 11 lamps per lab. Lamps are built off and tagged `WorldLight`; `Client\WorldLights` lights the nearest FX_CAPS[tier].lights. Workspace.Labs untouched (T36 LAB_BUDGET 80). Geometry was checked off-line with a lune build + a numpy renderer (spawn, portrait, top views), not in Studio.
- Dummies (WORLD_V2): DummyFactory.SUITS test-suit torso colours by turns (never green) + back number (a `CrashMark` SurfaceGui, so the crowd strips it).
- Feel: `Client\FeelV2` (started from Main after Viewmodel; FxController calls in): trauma^2 noise shake (Settings shake off = none, Motion LESS = half), hit-stop for big non-melee moments via HitFeel's budget, pooled ParticleEmitter stars/sparks/dust (FxController.sparks uses them instead of a part per spark), flop layers by landing speed, speed trails on launched/thrown/knocked bodies (LAUNCHERS in FxController), muzzle flash at the Tip for every shot + casings (not Revolver/DoubleBarrel/energy guns) + camera recoil on own shots (AmmoClient.onSpent), combo slow-mo beat (colour/FOV/whoosh only, physics unchanged) on ProgressService "Combo". `Client\FeelBus` = remote-free signal for the UI: Combo, SlowMo, BigHit, Launch, Land, Shot.
- Ragdoll: ActiveRagdoll.guardLimbs (FEEL_V2) every PostSimulation: a limb at most LIMB_REL_MAX 110 studs/s against the pelvis, LIMB_SPIN_MAX 32 rad/s; skipped while held, frozen or with a severed limb. Ownership unchanged (one owner for life, DummyControl).
- Tests: T80_FxCaps (pure caps, ragdoll budget per tier, GUN_FX for all 20 guns, lamp picker), T81_WorldDress (non-colliding, budgets, lamps off + tagged, suits not green), T82_LimbGuard. Danish checklist: TEST-ALT.md section 13. Uploads: Open Cloud key reads the universe, but the assets API answers "User not authenticated" (no approved folder), so no new meshes.

## UI v2 (19 Nov 2026, branch `ui-polish` from `release`; never run in Studio)
- Switch: `Config.UI_V2` (true). false = the round 5 dark-glass look, untouched. Owner checklist: TEST-ALT.md §10b.
- Tokens only in `LihFolkUI/LihFolkUITheme` (V2 block, `Theme.V2`): navy canvas, havoc-orange `accent` role, livelier roles, Fredoka One display + Builder Sans body, radii 18/14/12, strokes, `Theme.Shadow` (window drop shadow), `Theme.Focus` (yellow gamepad ring), `Theme.IconSize`, Motion pressScale 0.92 + popFrom/popTime/countTime, text floor MinTextSize 17 (= 14 px at the 0.85 touch floor). Components read them (selection ring, window shadow, HudButton caption cap 17).
- `Client/KitStyle`: `fit` (TextScaled + cap/floor; a later TextSize moves the cap), `fitOrHide`, `press` (squish + kit click, once per button), `pop` / `countUp` (on the object's ONE UIScale: `HudScale`, rest = attribute `KitBase` written by HudSlots.apply), `icon` (drawn icon left or top; `HUD_ICONS`). Ad-hoc second UIScales in PlayerBody/LabCamera/GrabController/ExperimentCard replaced.
- Screens: icons on LAB VIEW, RAGDOLL, BUILD, PLAY, GRAB, THROW, RUN, SHOOT, CLIP IT and every MENU entry (`HudMenu.ICONS`); bar slabs 14 px or picture only (`PokeController.iconOnly`, `SLAB_MIN_TEXT`, WEAPONS slab -> toolbox icon); weapon cards with rarity (`Shared/UiRarity`: by ladder rung on the price-tier bounds; outline, lit stage, tag, veil when locked, lock/tick icons) and POWER/SPEED/CHAOS 1-10 per shelf on a sqrt curve (`UiRarity.stats`; Toys untouched), CARD 182x346; toasts, experiment card, combo pop, replay overlay, egg card (rarity word), offers (pictures, Robux mark, BEST VALUE), level badge 30 px + count-up (hidden on a phone during QUIET_START), BOLTS count-up, crosshair punch + "KO!", chaos meter/slot numbers/gift tag/next cards at 14 px.
- LayoutCheck: `uiV2` section in `run()` (text floor, role/rarity contrast, drawn icons, stat rows, icon-button room, level badge, first minute <= 7 on portrait phones) + `textLive()`. Test T90_UiV2. PC-only pieces (help line, mouse help, sandbox column, Robux packs, deal) keep their old floors.

## v3 (19 Nov 2026, cloud session on `release`, v0.21.0; never run in Studio)
- Plan: `docs/V3_PLAN.md` (its State line and PC TODO). Research: echo-heist `docs/ragdoll-havoc/research/RESEARCH_V3.md`.
- **Biggest owner lever:** the game is listed "Minimal, Ages 16+". Redo the maturity questionnaire for all ages (Bloody Ragdoll Physics went 2.5k → 21k CCU after its label change).
- `Config.LOOK_V3` (WORLD_V2 now false):
  - ZoneLighting finishV3;
  - white dummies, no marks, no glow;
  - DummyLife lines (Shared/DummyLines);
  - quiet Playground signs, OWNER tag off;
  - `Client/HudV3` + `HudGate` (off phones: Shop/Weapons/Lab left, Maps/Menu right, key chips, top-bar Next pill, LAB window; old HUD pieces step aside);
  - Viewmodel V3 (big gun, white hand);
  - HitInfo black card;
  - `Server/Systems/Landscape` (grass, hills, trees).
- `Config.UI_3D`: `Client/Ui3D` turns weapon models (ToolPicture `turn` argument) in the catalog and the egg card. Live budget comes from `UI_3D_LIVE`.
- Phase C:
  - `Server/Systems/VehicleService` + `Client/VehicleClient` (`Config.VEHICLES`): Car + Truck per lab, the Drive prompt, driver-owned handling, dummies knocked by the PropContacts machine rule.
  - `Server/Systems/Creatures`: the GorillaRampage and BullRun events (productId 0).
  - BIG RED BUTTON per lab (`Config.BIG_BUTTON_GAP`).
  - Tests: T91_LookV3, T92_Creatures.

## v3 PC session (19 Nov 2026, first "klar" on the PC, branch `release`)
- 29 Creator Store models imported into `ServerStorage.V3Assets` (place saved, v471). `tools/ImportV3Assets.luau` also disables seats, strips prompts/clicks/sounds/fire/headlights and brand marks, keeps one Sedan/palm from packs, squares the fence, pivots on the real lowest part, sets Yaw. Cannon 14 studs.
- First Studio LayoutCheck of the cloud phases: **551 problems → 0** (live 0). Main points:
  - Phones: one bar row clear of GRAB/SHOOT (`PokeController.PHONE_THUMB_RIGHT`, `plan.shown`), no next cards on phones.
  - Upright phones:
    - event bars under the corners (`HudSlots.eventTop`);
    - BUILD/PLAY on the toast row while building (toasts via `Toast.setMinTop`, the arena bar and the nuke banner go under them; the chase bar steps aside);
    - the monitor is full width over the thumb row (`HospitalCharts.UPRIGHT_BOTTOM`);
    - 3 arena lines.
  - Tablet RUN under the jump button.
  - The hit line keeps clear of the thumb buttons (`HitInfo.widthOn`).
  - The experiment card and RECENTER rest in doctor mode.
  - Contrast fixes: premium has ink text, the go bottom is #13A04C, and rarity tags use `KitStyle.tagInk`.
  - `CHIP_MAX` 700.
- Tests fixed for the cloud phases:
  - T36 (marks off under LOOK_V3);
  - T35 (Ladder v2 Pan rung);
  - T38 (MILD_TEXT "Head");
  - T40 (tall hair = own hat);
  - T63 (journal page);
  - T82 (spawn in the air).
- Landscape keeps the plaza front flat and free of trees (`PLAZA_HALF_X`/`PLAZA_FRONT`); the plaza boards stood on a hill.
- Full suite before those fixes: 71/78 (T19, T32 flaky). After: every fixed test passes alone.
- Phase B started: `Places` has an outdoor row (`outdoor`, `row`, `OUTDOOR_Z` 1400, `OUTDOOR_SPACING` 900). `Server/Systems/OutdoorMaps` builds the **Island** (terrain sea/sand/grass, a cliff with steps, a jetty, a boat, beach huts, a lighthouse, a catapult base, palms/bushes/rocks/crates). T26 accepts outdoor maps (no ceiling, budget 3000).
- 19 Nov (owner): the old rooms are gone from `Places` (Hangar, Cafe, Office, FoodCourt, Market, WhiteRoom, Metro). Maps now: Lab, Plaza, Game Arena + the 5 open-air maps. Their builders still sit unused in WorldMaps. Crowd floor tolerance is 2 studs (the city crowd had piled up in the middle). Tests moved: T26 to City/Site, T31 to Island, T36/T42 skip removed rooms.
- After the Studio restart: 5 open-air maps were built and seen. They are Island, City "Downtown", Site, Farm "Old Farm" and Military "Army Base", all in `OutdoorMaps` with `Places.OUTDOOR_SPACING` 1200.
  - **Pack pieces:** `piece(m, pack, name|"A>B>2", at, yaw, fit, collide)` reads from `ServerStorage.V3Packs.*`. That folder lives only in the place file (saved, v485).
  - **Terrain:** fill the ground first, then measure its top (`ground()`); terrain lands a few studs off the asked height.
  - **Arrival:** `Places.arrive` sets how far south of the middle the arrival pad sits.
  - **Materials to avoid:** terrain Pebble showed as grass, Sand reads white from above, and the Farm pack's row/wheat tiles drew as white bits.

## M10 progress (9 Nov 2026, NOT yet tested in Studio)
**M10 PASSED (9 Nov 2026): blind review 8.75 after fix round 1.** Latest backup: `Documents\RagdollLab-backups\2026-11-09-m10-done` (pre-M10: `2026-11-08-baseline`). Full suite 44/46 before the fixes; the two failures were fixed (T40 Golf grip, T38 quiet-mode) except T37, which fails at ~24 Hz on this PC with the pre-M10 code too (environmental). Golf grip and Tip were moved onto the handle/head in the place (N7Assets) with welds rebuilt: the place must be saved. MAX_CORPSES = 16 server-wide. Scope cuts (owner may ask later): per-weapon Palm attachments, two-handed left-hand stance retune, server movement guard for sprint, client-side sprint self-test.
Notes below are the pre-test M10 log.
Backups: `Documents\RagdollLab-backups\2026-11-08-baseline` (before M10 fixes) and `2026-11-09-m10-untested`.
Done in code: headshot = any gun round to Brain/Skull/Jaw kills at once (Anatomy.HEADSHOT, `round` flag), flat line at once (DeathCause), kill never throttled, crosshair kill mark, dead held body limp, dead bodies kept the full 60 s on every path, Heal refuses the dead; community gun sounds + SoundManifest.GUNS, FxController builds BANK from the manifest with pooled voices, failed-asset pruning and fallbacks, swing whoosh before contact, one sound per plaza hit, dry-fire clicks, shotgun pump, casing; Sprint wired in Main.local, Shift sunk, mouse lock off, stuck-input fixes, FxController.fovExtra; HeldService welds to RightGripAttachment (and a grip's 'Palm' attachment if present).
Still to do: syntax/play test everything in Studio (T33, T34, T38, T41, T42_Sprint, T24, LayoutCheck); write T43_DeadHold; place 'Palm' attachments on N7Assets.Weapons in Studio and re-tune two-handed stances (AvatarMoves); rewrite T40_GripAlignment as a live-character test; RUN touch button into HudSlots (check overlap with GRAB via LayoutCheck); Sprint row in Controls window; optional server movement guard; then one blind review.

## Status (8 Nov 2026)
Phases 0-4b, A-M, N1-N5, N7 (graphics accepted as is), M1-M8 done. M9 was under review. Round 4 "Santa's Sandbox" (auto-approved) was in progress:
- M10 combat: headshot = instant death (monitor shows it), dead NPCs lie 60 s, hit sounds on impact, weapon held in the hand, community gunshot sounds, sprint.
- M11 NPCs: much nicer NPCs, smaller speech bubbles, hospital monitor uses the mobile layout by default (can be turned off), shown only for a dead NPC under the mouse.
- M12 world: rename, desert-oasis spawn lab, clear glass walls between plots, much better maps.
- M13: Christmas icon and thumbnails, then test everything.
- Mobile fixes (v0.17.2, 11 Nov): sound on phones (FxController: POOL 1 on phones, pool grows to POOL_MAX 6, busy asset restarts its oldest loaded voice, LOAD_WAIT 0.2 phone / own shots LOAD_WAIT_OWN 0.35, start-bar guns + hit banks made first). Walking no longer shoots: Client\MoveStick (touch that starts on TouchGui's DynamicThumbstickFrame/ThumbstickFrame, fallback lower-left 40%x55%) is claimed in LabCamera.onPress and skipped by Crosshair. Play test clean; not yet tested on a real phone.

## v4 (20 Nov 2026, PC, branch `release`; plan docs/V4_PLAN.md)
- A1-A6, B1-B4 done (details in V4_PLAN.md). New remote **NpcCommand** (Net; server Open/Done/Refused, client Follow/Stay/Attack/Bye, validated in Server/Systems/NpcCommand). New systems: SoundMix (client), GroundGuard, MapActivities, OutdoorMaps, NpcCommand; Client NpcTalk. Crowd roles Worker/Farmer/Soldier/Beachgoer; DummyLines.PLACE.
- **v4 C-E (20 Nov, release 0.23.0):**
  - C1 LabZones: zones, today's machine by UTC day, NEW tags.
  - C2 VehicleFeel: wheels on Welds, lean, lights, engine/horn/crash; remote **VehicleHorn**, server-checked.
  - C3 rigged gorilla and bull. `ServerStorage.V3Assets.GorillaRig`/`BullRig` live in the place file only; Client/CreatureAnim animates them by `Gait`.
  - C4 Surprises: 11 events and mini surprises (`LAB_SURPRISES`).
  - C5 Client/SlowMotion (`SLOWMO_V2`).
  - D1 `ARENA_V2` sports hall. D2 `UI_CLEAN` leaderboards and real event card pictures (art/events).
  - E0 docs/RESEARCH_V4.md. E1 `FIRST_WOW_AT` 50. E2 art/store/v4. E3 What's New and STORE_TEXT v4.
  - Blind reviews:
    - A+B 7.6/6.5, fixed;
    - C 7.5, fixed;
    - no re-reviews run.

## V6 (20 Nov 2026, PC, branch `release`; plan docs/V6_PLAN.md)
- **V5 is closed.** Its leftovers went into V6-4 and V6-8.
- **V6-1, the notification centre** (`Config.NOTIFY`): `Shared/NotifyRules` (pure, T100) and `Client/Notify`.
  - API:
    - `Notify.say(kind, text, color)` / `push`, with kind critical, reward, info or tip;
    - `Notify.waitBig(name)` / `releaseBig` for windows that open by themselves;
    - `Notify.goodMoment()` for the Roblox Experience Notifications opt-in (`EXPERIENCE_NOTIFY`, after 8 min and a wow).
  - Unsolicited toasts and the EggReady, AutoEgg, Like and WhatsNew pop-ups go through it. Replies to the player's own presses still call Toast. Toast takes an icon and closes on a tap.
- **The audit's first visit** (`Client/FirstVisit`, docs/AUDIT.md area 1):
  - Server attributes:
    - `Newcomer`: set only on a real profile read, and not after a teleport;
    - `CannonShots` and `ThrownBy_<part>`, set by Playground.
  - Client: the player attribute `NewcomerUntil`, plus HudSlots `setNewcomerUntil`, `newcomerChanged` and `quietUntil`.
  - The HUD is held from frame 0; on PC, WEAPONS stays.
  - Studio hooks: player attribute `DevLayoutCheck` (runs LayoutCheck in the real client) and ServerStorage `StudioFresh`.
- **V6-2 admin:** `Client/AdminPanel` ("AdminV2", `Config.ADMIN_V2`) is a tabbed window with SERVER / PLAYERS / WORLD / DEBUG tabs. Its tools are in `Server/Systems/AdminTools`, behind `AdminService` (owner check, pacing, fixed choices, logging). `Client/AdminWorld` draws the owner's time of day (`AdminClock`) and weather (`AdminWeather`) on every screen. When the owner leaves, these reset.
- **V6-3 director:** `Client/Director` (`Config.DIRECTOR`), owner only.
  - Keys: F8 turns it on and off, H is REC.
  - It hides the game UI and shows a 9:16 frame.
  - Cameras: free, orbit, follow, drone, first person and camera paths.
  - It also has lens and time controls, actions, presets (`OwnerSetting` "DirectorPresets") and 6 one-tap TikTok shots.
  - The server side is AdminTools `LaunchDummy` / `Shot` / `DirectorSave` / `DirectorGet`. Player attribute `IsOwner`.
- **V6-4 lab:** with `Config.LAB_V6`, plots are 250 apart (`Zones.PLOT_SPACING`) and `Lab.CORE_HALF` is 85.
  - The garden is `Server/Systems/LabGarden`.
  - Place-file pieces: BaseplateEast/West.
  - New models in V3Assets: GardenFountain, FlowerBed, GardenShed, Hedge.
- **V6-5 creatures:** `Server/Systems/LabCreatures` (`Config.LAB_CREATURES`) is a yard in front of each lab with spider, plant, frog, whale, chicken, washer, slingshot, mole and vacuum.
  - Body attributes: `InMachine`, `MachineHidden` (DummySkins hides the skins) and `MachineCool`.
  - Each creature has an experiment card and a journal page.
  - Models are in V3Assets with an M prefix.
- **V6-6 birds:** `Client/Birds` (`Config.BIRDS`, `BIRDS_MAX`). Models are in ReplicatedStorage.BirdModels.
- **V6-7 map shop:** `Server/Systems/MapShopService` + `Client/BoothSpin` (`Config.MAP_SHOP`).
  - There are 10 `map = true` Shop.OFFERS (ids 0 until the owner creates them) with TRY 60 s.
  - Pets are PetRobotDog and PetParrot in V3Assets.
- **V6-8:** all 18 event cards have pictures, there is less outdoor haze, and version 0.24.0.

## UI audit before the ads (21 Nov 2026, release 0.27.1)
- **The owner asked for:**
  - check everything visually;
  - question every piece of UI;
  - keep only what is needed, in the right place;
  - make everything 3D and interactive.
- **What it covered:** PC (1043x635), iPhone 17 Pro landscape and portrait (Device Simulator plus the workspace attribute **DevTouch**, Studio only: `ViewMode.isTouch` treats the simulator as a real phone), and every window.
- **HUD:**
  - **One WEAPONS:** only the bar slab. HudV3's left squares are `HudV3Layout.LEFT` = Shop, Lab.
  - **Chips:** three key chips: F Ragdoll, C Lab view, Z Slow-mo.
  - **Lab view on PC (big HUD):** a key; the button shows only as WALK, in the lab view.
  - **Help line:** only the tool's hint, and only as wide as its words.
  - **Level badge:** off under LOOK_V3, phones too.
  - **Ammo counter:** off the slot on touch (it is by the crosshair) and hidden while a window is open.
  - **Gift button:** a drawn present (`present` in DrawnIcons, art\icons\present.png).
  - **Window names:** Maps opens "Maps" and More opens "More". The More window is as tall as its rows off a phone (`HudMenu.HEAD`).
  - **Weapon cards:** POWER/SPEED/CHAOS name box is 84 units wide; EQUIPPED has no tick.
- **One voice at the start:**
  - Touch: no top pill for step 1 (TouchShoot's "TAP A DUMMY!" hand says it).
  - The mission card waits while `FirstVisitGoal` exists.
  - A newcomer's launch gift comes at `LaunchGift.NEWCOMER_AT` 120 s, and the weekend news at `ScheduleUI.NEWS_AFTER` 200 s.
- **Windows:** a tap on a HudV3 square while a window is open switches to its window (`LihFolkUIController.passThrough`, set by HudV3).
- **3D:**
  - The selected bar slot shows the weapon's real model, turning (`PokeController` live3D, Ui3D budget, drawn icon on low end).
  - World signs are in studs: `LabZones.PX_PER_STUD`, the spider's HUNGRY, and dummy lines (`IDLE_MAX` 1, `DISTANCE` 45).
- **Knockables:** `Server/Systems/Knockables`. The lab's barrels, crates and cones (LabDress) are solid things.
  - What knocks them: a touch at 14+ studs/s, a shot (`HitService` onShot), a blast (`Blasts`).
  - The server simulates them; they go home after 10 s still (30 s at most) and on RESET (`SandboxService`).
  - Test: T146_UiAudit.

## Sounds, start bar, banners, paths, lab guide (21 Nov 2026, release 0.28.0)
- The owner: "you decide everything from the vault and the big ragdoll games".
- **Every weapon its own sound:**
  - Guns: `SoundManifest.GUNS`. AutoShotgun and GoldenDeagle now have their own banks.
  - Everything else: `SoundManifest.TOOLS`, keyed by tool. `on` is "Hit" or "Place", plus bank, volume, pitch, cut and `maxSpeed`. `TOOL_ALIAS` maps BananaPeel to Banana.
  - FxController `toolSound` plays it in `onFx`. A tool with one skips its old shared identity sound and the cartoon BONK.
  - 45 new banks (`tool...`), mostly Roblox-licensed Pro Sound Effects; the few community uploads have their creator noted. All load-checked.
  - Tool banks preload in a second wave (20 s on phones).
  - Punch keeps the shared Punch Kit thud. Bat, Golf, Axe, Chainsaw and Crowbar keep their WEAPON_HITS banks.
  - Test: T147.
- **Start bar v9 (`Config.START_BAR_V9`):**
  - Players start with 4 tools (Popper, Grab, Bat, Grenade) and 2 empty slots. The big games start small: BRP 3 slots, RDP 1 tool and 3 empty.
  - Launch is the first present at 3.
  - The Rocket is among the hardest (`Toys.HARD_RUNGS` Rocket = 470, the R$199 tier) and is out of `WOW_POOL`.
  - Ladder 5 (`ProgressService.grandfather`): older profiles keep Launch, plus the Rocket if they had 3+ takedowns.
  - Tests T110 and T35 were updated.
- **Banners:**
  - `Shared/BannerRules` (pure) and `Client/Banner`. `Toast.show` hands these lines to the banner: SURPRISE! X, BULLSEYE!, CHASE!, CHASE CLEARED!, KNOCKED OUT!
  - Look: a coloured ribbon that unrolls, a round badge with a drawn icon or an emoji, a gold title that pops in, a sub-pill and a sting.
  - Vault timing: enter 0.26 s, exit 0.16 s, hold 2.6 s (1.4 s when busy), a queue of 4.
  - Toasts wait while a banner shows, and the experiment card steps aside. Toasts also got an accent strip in their colour.
- **Paths (`Config.PATHS_V3`, `PathBuilder.dressLine`):**
  - Warm sandstone cobbles (`PAVING_V3`) with a grass verge.
  - Lamp posts every 26 studs, sides taking turns; a PointLight in every second one, 8 per lab at most.
  - Grass tufts and flowers at uneven gaps.
  - `DRESS_MAX` 300; `PathPlan.BUDGET` is now 780.
- **Lab guide (`Config.LAB_GUIDE`):** `Server/Systems/LabGuide` (built after LabCreatures) and `Client/LabGuideClient`.
  - **Signs:** every creature gets a studs-sized sign over its head: the drawn `guide_feed` picture (a dummy and an arrow) and FEED ME! (WASH ME! for the washer, LOAD ME! for the slingshot).
  - **Rings:** every creature and every PUT RAGDOLL HERE station gets a cyan neon drop ring. Cyan is the one "use me" colour.
  - **Button:** a ProximityPrompt ("Feed / Spider", E or ButtonX, reach 18). It tosses the lab's nearest free dummy in an arc (`LabGuide.arc`) into the creature's trigger.
  - **Carrying a dummy:** the nearest ring lights up with a bouncing DROP HERE!.
  - Tested: E at the spider puts a dummy in the web.

## The new lab (21 Nov 2026, release 0.29.0)
- The owner: "always use the vault AND the biggest ragdoll games; publish it all".
- **Research of 20 Nov.** The biggest game is Hyper Realistic Ragdoll: 125K CCU, 19 min sessions, a full kit with 3 guns from the start, one "Next" goal, machines that teach themselves.
  - Players quit over UI clutter and constant pop-ups with sounds, no goal and pay walls.
  - The direct competitor is Dummy Lab: 6.9 min sessions, 25 passes.
- **Start bar (`START_BAR_V9`):** full 6: Popper, Buzz Blaster (SMG 0), Grab, Bat, Grenade, Launch (0). The Rocket stays at 470. T110 and T35 were updated.
- **Paths (`LAYOUT_V2`, PathPlan V2 block):** a network, not a tree.
  - A round plaza at the spawn hub, plus east, south and west loops.
  - A yard road joins both garden walks (`GARDEN_WALK_NORTH` -66 starts them by the spider and the plant).
  - The only ends are at things: the bullseye, the lava's rocks, the tower's stairs and the portals.
  - The west garden crossing and both -30 crossings are gone; they ran into barriers and the portals.
  - The mace moved to (-38, 48) and the Christmas present to (-56, 62).
  - Straight segments are one slab.
  - Verges are raised grass on a dark soil edge, with bush clumps, flowers and lamps.
  - `PathPlan.BUDGET` is 1400 and `DRESS_MAX` is 700.
  - The lava stays at its spot, beside the bullseye at the edge of the spawn view; the west has no room.
- **Lava (`LAVA_V2`, `Server/Systems/LavaPit`, `Client/LavaClient`):**
  - The pool is overlapping CrackedLava discs whose colour breathes, with crust islands that drift.
  - The rim is V3Assets "Rock" meshes on a scorched ring.
  - Embers, haze and blobs (LightInfluence 0), a flickering PointLight and a bubbling sound (PSE, slowed).
  - A warning sign post (sign_lava). The trigger shrinks to fit inside the oval.
- **Icons (`ICON_SIGNS`):**
  - 15 drawn pictograms (`sign_*`, `hud_*` in DrawnIcons).
  - Playground word signs became round icon badges (`Playground.iconBadge`).
  - Signposts show icon + arrow (`PathBuilder.LABEL_ICONS`); today's machine is a gold star badge.
  - The HUD key chips are key + icon, and the help line is click → tool → arrow → dummy/floor.
  - Dummy lines are emoji (`DummyLines.EMOJI_*`).
- **Lab guide:** the cannon (Fire), the lava (Toss) and the trampoline (Bounce) got buttons too (`LabGuide.MACHINES`). Rings are dashed glowing pieces round an invisible part (`GuideRingSeg`).
- **Fewer pop-ups:** "Walking again" is gone, the lab-view how-to shows once a visit, and `TOMORROW_AT` moved from 80 to 480.

## Wide paths and GOD MODE (21 Nov 2026, release 0.30.0)
- The owner: the paths were "far too narrow and still stick out at the bullseye, 5/10".
- **Paths (`LAYOUT_V2`, PathPlan V2 block):**
  - Paving is `PathPlan.WIDE_PAVING` 7.4 (was 4.2), with `WIDTH_MIN` 8.3 / `WIDTH_MAX` 8.6. The lab's walkways and their dressing read it through `PathBuilder.walkWidth()`.
  - Fewer segments: three arms from the spawn plaza with loops, and the yard road round both gardens. There are no BULL or LV stubs; the only ends are the tower's first step, the portals and the garden walks.
  - The plaza is bigger (disc 18). The mace is at (-41, 50) (`Playground.MACE_V2_AT`), the Christmas present at (-58, 64), and two LabDress benches moved under LAYOUT_V2.
  - Lamps, tufts and flowers also keep off the two garden walks (`avoid` in `PathBuilder.lab`).
- **GOD MODE (`Config.GOD_PASS`):**
  - The pass: `Shop.PASSES` God, "GOD MODE", 199 Robux planned. Its **id is 0**: Open Cloud refused to create it (multipart needs an approved upload folder), so the owner creates it on the dashboard and sends the id.
  - With id 0 live, spawning stays free for everyone and the window shows no offer. In Studio it is gated.
  - Server: `DummySpawn.godGated` / `mayCreate` / `startTrial`. Without the pass, the first creation starts a free 60 s trial once a visit (player attribute `GodTrialUntil`, the GOD MODE! banner); after it a creation is refused with "god".
  - With the pass: twice the device cap, and a gold beam of light plus a chime at every creation. MoneyService sets the player attribute `God`.
  - Client: `Client/GodMode`, a window of 4 coloured kinds (TINY/HEAVY/BOUNCY/FLOPPY). A tap drops one 12 studs ahead of where the camera looks; GET GOD MODE goes through MoneyService "Buy".
  - Launchers: a HudV3 square between Shop and Lab off phones (`HudV3Layout.LEFT`); on a phone, the GOD MODE entry in MENU (phone column has no room, LayoutCheck). CLIPS & LIVE is `notPhone`.
  - Icon `god` (art\icons\god.png, DrawnIcons). Tests: T148_GodMode; T128 resets the trial around itself.
- **Ids live (21 Nov 2026, the owner sent them):** GOD MODE 2093692966 (199). Every Shop.OFFERS id is set (17 passes, Starter Crate 3733992321 and Bolt Crate 3733992403 products), the 16 new event products are in Events.luau, and the badges Havoc Maker, Nuked It and Havoc Legend are in Badges.luau. Each id was checked against Roblox (name, price, for sale; badges enabled). `Shop.GROUP_ID` stays 0 (no group sent). GOD MODE is gated live now (free 60 s trial, then the pass).
- **The creator owns every pass in Studio** once ids are real: tests that try or sell a pass start with `OfferService.resetForTest`, and they deliver through `OfferService.grantPass` instead of a buy (a real id opens Roblox's own prompt). T105 was updated this way.
