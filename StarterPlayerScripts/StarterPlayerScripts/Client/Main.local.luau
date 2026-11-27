--!strict
-- Client bootstrap.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Log = require(Shared:WaitForChild("Log"))

local Client = script.Parent
local FxController = require(Client:WaitForChild("FxController"))
local AvatarMoves = require(Client:WaitForChild("AvatarMoves"))
local PokeController = require(Client:WaitForChild("PokeController"))
local ReplayController = require(Client:WaitForChild("ReplayController"))
local OnboardingController = require(Client:WaitForChild("OnboardingController"))
local DummySim = require(Client:WaitForChild("DummySim"))
local PropContacts = require(Client:WaitForChild("PropContacts"))
local GrabController = require(Client:WaitForChild("GrabController"))
local DummyLife = require(Client:WaitForChild("DummyLife"))
local LabCamera = require(Client:WaitForChild("LabCamera"))
local ChaosMeter = require(Client:WaitForChild("ChaosMeter"))
local BuildController = require(Client:WaitForChild("BuildController"))
local PlayerBody = require(Client:WaitForChild("PlayerBody"))
local EventShop = require(Client:WaitForChild("EventShop"))
local Ghosts = require(Client:WaitForChild("Ghosts"))
local HospitalCharts = require(Client:WaitForChild("HospitalCharts"))
local HitInfo = require(Client:WaitForChild("HitInfo"))
local Crosshair = require(Client:WaitForChild("Crosshair"))
local BulletHoles = require(Client:WaitForChild("BulletHoles"))
local ToolCatalog = require(Client:WaitForChild("ToolCatalog"))
local PlaceMenu = require(Client:WaitForChild("PlaceMenu"))
local ZoneLighting = require(Client:WaitForChild("ZoneLighting"))
local ProgressUI = require(Client:WaitForChild("ProgressUI"))
local HudMenu = require(Client:WaitForChild("HudMenu"))
local FriendsUI = require(Client:WaitForChild("FriendsUI"))
local MinigameHud = require(Client:WaitForChild("MinigameHud"))
local ControlsUI = require(Client:WaitForChild("ControlsUI"))
local CreatorUI = require(Client:WaitForChild("CreatorUI"))
local Net = require(Shared:WaitForChild("Net"))
local PlotPrivacy = require(Client:WaitForChild("PlotPrivacy"))

local log = Log.new("Boot")
log.info(string.format("%s %s client started", Config.GameName, Config.Version))

require(Client:WaitForChild("SessionClient")).start() -- (first: the boot time is read now)

-- V8-0.9 (safe boot): every client system starts under pcall, so one error no longer stops the ones
-- after it. A failure is logged and listed in the player attribute ClientBootFailed (SessionClient
-- reports script errors in the visit record).
local safe = require(Shared:WaitForChild("SafeStart")).new(function(failedList: string)
	game:GetService("Players").LocalPlayer:SetAttribute("ClientBootFailed", failedList)
end, "ClientBoot")
-- The hand-drawn icons (Shared.DrawnIcons), before anything draws an icon.
require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIIcons")).registerMany(require(Shared:WaitForChild("DrawnIcons")).ASSETS)
local PhoneDiet = require(Client:WaitForChild("PhoneDiet"))
safe("PhoneDiet", PhoneDiet.start) -- 23 Nov 2026: what a phone does not draw
local LATER = if PhoneDiet.wanted() then 8 elseif not game:GetService("UserInputService").KeyboardEnabled then 5 else 2 -- s: on a phone the living decor starts once the first seconds are over
safe("PlotPrivacy", function() PlotPrivacy.start() end) -- (first: other labs leave this screen before anything draws them)
task.spawn(require(Client:WaitForChild("DummySkins")).start) -- the dummies' sculpted mannequin bodies
safe("SoundMix", function() require(Client:WaitForChild("SoundMix")).start() end) -- v4 A3: the mix's groups and compressor
task.spawn(require(Client:WaitForChild("NpcTalk")).start) -- v4 B4: the talk panel
task.spawn(function() require(Client:WaitForChild("NoticeState")).start() end) -- V9-0g: small notices on phones (who fired when)
task.spawn(require(Client:WaitForChild("SlowMotion")).start) -- v4 C5: smooth slow motion
task.spawn(require(Client:WaitForChild("VehicleFeel")).start) -- v4 C2: wheels, lean, lights, engine, horn
task.spawn(require(Client:WaitForChild("BikePedal")).start) -- F76: riders on a bicycle pedal (Config.BIKE_PEDAL)
task.spawn(require(Client:WaitForChild("ControlsFX")).start) -- C10: the control kit's prompt, press feedback and states (Config.CONTROLS_V2)
task.spawn(require(Client:WaitForChild("CarRock")).start) -- row 7: a ragdoll slamming into a car rocks it (Config.CAR_ROCK)
task.spawn(require(Client:WaitForChild("AdventCalendar")).start) -- AUDIT 27 Nov 2: the advent calendar window (Config.ADVENT)
task.spawn(require(Client:WaitForChild("CprGame")).start) -- 3.34: the CPR rhythm game (Config.PLAYER_CPR)
task.spawn(require(Client:WaitForChild("CreatureAnim")).start) -- v4 C3: the gorilla and bulls move and sound
task.spawn(require(Client:WaitForChild("FirstVisit")).start) -- audit area 1: a newcomer's first visit (one objective, the HUD comes in at 90 s)
task.spawn(require(Client:WaitForChild("AdminWorld")).start) -- V6-2: the owner's time of day and weather for everyone
-- V6-3: F8 director mode (owner only). (V8-1.7, phone diet: loaded only once this player is the
-- owner, IsOwner from AdminService; nobody else ever loads it.)
do
	local me = game:GetService("Players").LocalPlayer
	local started = false
	local function startDirector()
		if not started and me:GetAttribute("IsOwner") == true then
			started = true
			task.spawn(require(Client:WaitForChild("Director")).start)
		end
	end
	me:GetAttributeChangedSignal("IsOwner"):Connect(startDirector)
	startDirector()
end
task.delay(LATER, function() require(Client:WaitForChild("Birds")).start() end) -- V6-6: birds round the lab and the maps
task.delay(LATER, function() require(Client:WaitForChild("CreatureLife")).start() end) -- 20 Nov: the lab creatures move while they wait
task.delay(LATER, function() require(Client:WaitForChild("BoothSpin")).start() end) -- V6-7: the booth items turn on their pedestals
safe("FxController", function() FxController.start() end)
safe("AvatarMoves", function() AvatarMoves.start() end)

-- Effects from our own simulation play here at once and are relayed to everyone else.
local relay = Net.event(Net.Names.FxRelay)
DummySim.onEvent = function(kind: string, _model: Model, position: Vector3, speed: number)
	if kind == "Shatter" or (kind == "Land" and speed < 14) then
		return -- shattering is announced by the server; soft landings are silent
	end
	FxController.localEvent(kind, position, speed, "")
	relay:FireServer(kind, position, speed, "")
end
PropContacts.onHit = function(toyId: string, position: Vector3, speed: number)
	FxController.localEvent("Hit", position, speed, toyId)
end
safe("DummySim", function() DummySim.start() end)
-- V8-0.2: a newcomer's first Config.FIRST_HITS hits knock a dummy flat (ActiveRagdoll.firstHitsLeft,
-- on this screen, which simulates the lab's dummies). Armed once, when the server says Newcomer.
safe("FirstHits", function()
	if not (Config :: any).V8_FIRST_HIT or (Config :: any).SHOT_FLINCH then
		return -- (V9-0ac: a newcomer's first KOs come from more damage, not a knock-flat: HitService)
	end
	local AR = require(Shared:WaitForChild("Ragdoll"):WaitForChild("ActiveRagdoll")) :: any
	AR.FIRST_HIT_PUSH = (Config :: any).FIRST_HIT_PUSH
	local me = game:GetService("Players").LocalPlayer
	local armed = false
	local function arm()
		if not armed and me:GetAttribute("Newcomer") == true then
			armed = true
			AR.firstHitsLeft = (Config :: any).FIRST_HITS
		end
	end
	me:GetAttributeChangedSignal("Newcomer"):Connect(arm)
	arm()
end)
safe("DummyLife", function() DummyLife.start() end)
safe("PropContacts", function() PropContacts.start() end)
safe("PokeController", function() PokeController.start() end)
safe("GrabController", function() GrabController.start() end)
safe("PlayerBody", function() PlayerBody.start() end)
safe("PlayerGrabClient", function() require(Client:WaitForChild("PlayerGrabClient")).start() end) -- grab and throw players in the plaza
safe("ReplayController", function() ReplayController.start() end)
safe("LabCamera", function() LabCamera.start() end)
safe("Sprint", function() require(Client:WaitForChild("Sprint")).start() end) -- hold Shift / RUN / L3 to sprint (round 4, M10)
safe("ChaosMeter", function() ChaosMeter.start() end)
safe("BuildController", function() BuildController.start() end)
safe("OnboardingController", function() OnboardingController.start() end)
safe("EventShop", function() EventShop.start() end)
safe("CodesWindow", function() require(Client:WaitForChild("CodesWindow")).start() end) -- V9-0t: the CODES window (MENU, SHOP)
safe("Spectate", function() require(Client:WaitForChild("Spectate")).start() end) -- the owner's SPECTATE (admin menu)
safe("Ghosts", function() Ghosts.start() end)
safe("HospitalCharts", function() HospitalCharts.start() end)
safe("DoubleEventChip", function() require(Client:WaitForChild("DoubleEventChip")).start() end) -- (V9-NOW 12: the 2X chip)
safe("NoNeon", function() if (require(Shared:WaitForChild("Config")) :: any).NO_NEON then require(Shared:WaitForChild("NoNeon")).start(4) end end) -- V9-NOW 18: what this screen builds glows no more either
safe("HitInfo", function() HitInfo.start() end) -- what you are shooting: two lines that add up (round 2, N2; round 3, M2)
safe("Crosshair", function() Crosshair.start() end) -- with a gun picked: a crosshair and hit marks (round 3, M2)
safe("TouchShoot", function() require(Client:WaitForChild("TouchShoot")).start() end) -- touch: SHOOT button, centre crosshair, "tap a dummy" (round 5)
safe("BloodFx", function() require(Client:WaitForChild("BloodFx")).useHoles(BulletHoles) end) -- bodies bleed from their bullet holes
safe("PlaceMenu", function() PlaceMenu.start() end)
safe("MapBoardClient", function() (require(Client:WaitForChild("MapBoardClient")) :: any).start() end) -- V9-0e: the Map Board tiles, the portal swirls
safe("TerminalClient", function() (require(Client:WaitForChild("TerminalClient")) :: any).start() end) -- V9-2b: the feed terminals' screens
safe("ZoneLighting", function() ZoneLighting.start() end)
safe("Settings", function() require(Client:WaitForChild("Settings")).start() end) -- SETTINGS, in MENU (round 3, M6)
safe("ChristmasFx", function() require(Client:WaitForChild("ChristmasFx")).start() end) -- falling snow while the Christmas theme is on (round 3, M7)
safe("ScheduleUI", function() require(Client:WaitForChild("ScheduleUI")).start() end) -- the ADMIN SHOW countdown and the free weekend (round 3, M9)
HudMenu.onSandbox = BuildController.toggle -- (MENU's SANDBOX on a phone)
safe("HudMenu", function() HudMenu.start() end)
safe("ProgressUI", function() ProgressUI.start() end)
safe("FirstPerson", function() require(Client:WaitForChild("FirstPerson")).start() end) -- V: first person (round 5)
safe("FirstShotFP", function() require(Client:WaitForChild("FirstShotFP")).start() end) -- V9-0w: the first shot ever shows first person
safe("TimeDial", function() require(Client:WaitForChild("TimeDial")).start() end) -- V9-2c: Z opens the time dial
safe("Viewmodel", function() require(Client:WaitForChild("Viewmodel")).start() end)
safe("FeelV2", function() require(Client:WaitForChild("FeelV2")).start() end) -- World/Feel v2: trails, casings, recoil, combo beat, world lamps (Config.FEEL_V2)
safe("GiftNotice", function() require(Client:WaitForChild("GiftNotice")).start() end) -- 24 Nov 2026: VIP / ULTRA from the owner
safe("ChaseHud", function() require(Client:WaitForChild("ChaseHud")).start() end)
safe("StuntHud", function() require(Client:WaitForChild("StuntHud")).start() end) -- V8-1.1: the CRASH score, the cannon's slow-mo beat, AGAIN
safe("SpawnKey", function() require(Client:WaitForChild("SpawnKey")).start() end) -- V8-2.5: H drops a dummy of a type where you aim
safe("GodMode", function() require(Client:WaitForChild("GodMode")).start() end) -- 21 Nov 2026: GOD MODE, the pass that creates life (spawning ragdolls)
safe("LabGuideClient", function() require(Client:WaitForChild("LabGuideClient")).start() end) -- 21 Nov 2026: the lab guide's rings breathe; DROP HERE! while you carry a dummy
safe("RexAnim", function() require(Client:WaitForChild("RexAnim")).start() end) -- FIXES_28NOV 16: the real T-rex plays its own idle, walk and roar clips
safe("PlayerSwim", function() require(Client:WaitForChild("PlayerSwim")).start() end) -- (owner 27 Nov late: swim and climb out of the aquarium, never stuck)
safe("LavaClient", function() require(Client:WaitForChild("LavaClient")).start() end) -- 21 Nov 2026: the lava pit breathes, flickers and its crust drifts
safe("NpcGlow", function() require(Client:WaitForChild("NpcGlow")).start() end)
safe("PortalUI", function() require(Client:WaitForChild("PortalUI")).start() end) -- SINGLEPLAYER / MULTIPLAYER portals, the server list (round 5)
safe("HudPlus", function() require(Client:WaitForChild("HudPlus")).start() end) -- big WEAPONS, LEVEL, today's deal, sandbox column (round 5)
safe("VehicleClient", function() require(Client:WaitForChild("VehicleClient")).start() end) -- v3 Phase C: drive the lab cars
safe("Cockpit", function() require(Client:WaitForChild("Cockpit")).start() end) -- V9-NOW 16: the driver's seat view, wheel, speedometer, car sounds
safe("BowClient", function() require(Client:WaitForChild("BowClient")).start() end) -- V9-NOW 23: hold to draw, let go to shoot
safe("PromptGate", function() if (require(Shared:WaitForChild("Config")) :: any).NO_HOLD_E then require(Client:WaitForChild("PromptGate")).start() end end) -- V9-NOW 24: no hold E; press the thing itself
safe("Speedometer", function() require(Client:WaitForChild("Speedometer")).start() end) -- V9-0c: the round gauge while you drive
safe("TargetArrow", function() require(Client:WaitForChild("TargetArrow")).start() end) -- NOW 1.3: an arrow over the nearest dummy for a new player
safe("MinuteMoments", function() require(Client:WaitForChild("MinuteMoments")).start() end) -- NOW 4: the 2, 3 and 4 minute moments for a newcomer
safe("LabShowcase", function() require(Client:WaitForChild("LabShowcase")).start() end) -- LAB10 R2: machines show off (attract mode) and the "TRY!" chain
safe("FirstTwo", function() require(Client:WaitForChild("FirstTwo")).start() end) -- FIRST_2_MIN: TRY at the machine, a ragdoll comes, the grab lesson once
safe("XRayToggle", function() require(Client:WaitForChild("XRayToggle")).start() end) -- BODY_V2 1: the X-RAY button and B key
safe("GuardDogClient", function() require(Client:WaitForChild("GuardDogClient")).start() end) -- GUARD_DOG: tap a limb to send the dog, the dog button, GOOD BOY!
safe("FlightTrail", function() require(Client:WaitForChild("FlightTrail")).start() end) -- IMPACT_FX: smoke trail behind flying ragdolls
safe("NoBlackScreen", function() require(Client:WaitForChild("NoBlackScreen")).start() end) -- F3: the camera stays out of your body while you are knocked
safe("PhoneClean", function() require(Client:WaitForChild("PhoneClean")).start() end) -- F6: only what is needed on a phone
safe("WatcherStandIns", function() require(Client:WaitForChild("WatcherStandIns")).start() end) -- OVERVIEW 0.7: light watcher stand-ins at the far machines
safe("GateMotion", function() require(Client:WaitForChild("GateMotion")).start() end) -- OVERVIEW 0.97: the spawn and gate moving parts, the first-join glide
safe("SoloHide", function() require(Client:WaitForChild("SoloHide")).start() end) -- OVERVIEW 2 / F30: in the start place nobody else is seen
safe("LagGuard", function() require(Client:WaitForChild("LagGuard")).start() end) -- OVERVIEW 0.1: no light shadows, far lights off, sign distances
safe("LegJitter", function() require(Client:WaitForChild("LegJitter")).start() end) -- F65: the always-on leg jitter detector
safe("MiniBar", function() require(Client:WaitForChild("MiniBar")).start() end) -- F71: the phone hotbar is small until tapped
safe("TextFloor", function() require(Client:WaitForChild("TextFloor")).start() end) -- AUDIT 25: phone text at least 14 px
safe("FontSweep", function() require(Client:WaitForChild("FontSweep")).start() end) -- AUDIT 33: one house font
safe("HighlightCap", function() require(Client:WaitForChild("HighlightCap")).start() end) -- LAG-FREE 2 item 5: at most 3/5/10 Highlights drawn
safe("SoundCap", function() require(Client:WaitForChild("SoundCap")).start() end) -- LAG-FREE 2 item 6: at most 12 world sounds on a phone, none too far to hear
safe("BooButton", function() require(Client:WaitForChild("BooButton")).start() end) -- MILD_EXTRAS C3: the BOO! button
safe("WorldGuiPass", function() require(Client:WaitForChild("WorldGuiPass")).start() end) -- FIXES_27NOV_LATE 6: signs never eat the mouse
safe("RealHands", function() require(Client:WaitForChild("RealHands")).start() end) -- S2: real hands with fingers, not hooks
safe("SmoothBody", function() require(Client:WaitForChild("SmoothBody")).start() end) -- S2: the smooth skinned body from Blender
safe("ViewReport", function() require(Client:WaitForChild("ViewReport")).start() end) -- 0.158: the camera report for "in view"
safe("PathWalkers", function() require(Client:WaitForChild("PathWalkers")).start() end) -- 0.1568: people on every path (client only)
safe("QualityGovernor", function() require(Client:WaitForChild("QualityGovernor")).start() end) -- 8: the automatic quality governor (FPS)
safe("PlazaClient", function() require(Client:WaitForChild("PlazaClient")).start() end) -- V9-0d: the town square (stage dance, photo spot, its sounds)
safe("HudV3", function() require(Client:WaitForChild("HudV3")).start() end) -- LOOK_V3: the big ragdoll games' HUD (squares, key chips, Next pill, LAB window)
safe("RewardsUI", function() require(Client:WaitForChild("RewardsUI")).start() end) -- REWARDS: daily, play gift, dares, trophies, group (round 5)
safe("GiftClock", function() require(Client:WaitForChild("GiftClock")).start() end) -- the clock to the next free gift for time played
safe("MinigameHud", function() MinigameHud.start() end)
safe("FriendsUI", function() FriendsUI.start() end)
-- (Round 5: no background music; the owner removed the radio.)
safe("ControlsUI", function() ControlsUI.start() end)
safe("LikePrompt", function() require(Client:WaitForChild("LikePrompt")).start() end) -- a friendly "like the game" ask (round 4)
safe("CreatorUI", function() CreatorUI.start() end)
safe("ExperimentCard", function() require(Client:WaitForChild("ExperimentCard")).start() end) -- phase 1: the experiment card and EXPERIMENTS window
ReplayController.currentToy = PokeController.getSelected -- (phase 1: the X-ray replay's SHARE CODE)
ReplayController.onScore = require(Client:WaitForChild("ExperimentCard")).scored
safe("GamepadControls", function() require(Client:WaitForChild("GamepadControls")).start() end) -- phase 0: the whole game on a gamepad (Shared\PadMap)
-- (Blind review 21 Nov: the safe() wrap had cut this call in two; the DOCTOR MODE button did nothing.)
safe("ToolCatalog", function()
	ToolCatalog.bindHospital(HospitalCharts.isDoctor, function(on: boolean)
		HospitalCharts.setDoctor(on)
	end)
end)
HospitalCharts.onChanged = function()
	ToolCatalog.refreshHospital()
end

-- V5 (Studio only): a capture hook for the UI review. Setting the player's "DevOpen" attribute to a
-- window's name opens it ("Weapons" opens the catalog); "" closes all. Never active in a live game.
if game:GetService("RunService"):IsStudio() then
	local devPlayer = game:GetService("Players").LocalPlayer
	-- ("DevLayoutCheck" = true runs LayoutCheck in this real client, with every icon registered, and
	-- prints each line tagged [LayoutCheck].)
	devPlayer:GetAttributeChangedSignal("DevLayoutCheck"):Connect(function()
		if devPlayer:GetAttribute("DevLayoutCheck") == true then
			local ok, res = pcall(function()
				return require(Client:WaitForChild("LayoutCheck")).run()
			end)
			for line in string.gmatch(tostring(res), "[^\n]+") do
				print("[LayoutCheck] " .. line)
			end
			if not ok then
				warn("[LayoutCheck] failed: " .. tostring(res))
			end
		end
	end)
	-- (V9-0i: "DevShopCheck" = true runs ShopV9.selfCheck in this real client: [ShopCheck] lines.)
	devPlayer:GetAttributeChangedSignal("DevShopCheck"):Connect(function()
		local ask = devPlayer:GetAttribute("DevShopCheck")
		if type(ask) == "string" and string.sub(ask, 1, 5) == "open:" then
			(require(Client:WaitForChild("ShopV9")) :: any).openFor(string.sub(ask, 6))
		elseif type(ask) == "string" and string.sub(ask, 1, 10) == "celebrate:" then
			(require(Client:WaitForChild("ShopV9")) :: any).celebrateForTest(string.sub(ask, 11))
		elseif type(ask) == "string" and string.sub(ask, 1, 4) == "tab:" then
			(require(Client:WaitForChild("ShopV9")) :: any).showTab(string.sub(ask, 5))
		elseif ask == true then
			local ok, res = pcall(function()
				return (require(Client:WaitForChild("ShopV9")) :: any).selfCheck()
			end)
			print("[ShopCheck] " .. (if ok then tostring(res) else "failed: " .. tostring(res)))
		end
	end)
	devPlayer:GetAttributeChangedSignal("DevOpen"):Connect(function()
		local name = devPlayer:GetAttribute("DevOpen")
		local Ctl = require(game:GetService("ReplicatedStorage"):WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIController")) :: any
		if name == "Weapons" then
			require(Client:WaitForChild("ToolCatalog")).toggle()
		elseif type(name) == "string" and name ~= "" then
			Ctl.open(name)
		else
			Ctl.closeAll()
		end
	end)
end

-- V8-0.9: a paid purchase is no longer silent (Theme.Sounds "purchase"), for products and passes.
safe("PurchaseSound", function()
	local MarketplaceService = game:GetService("MarketplaceService")
	local Kit = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIComponents")) :: any
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(_, _, bought: boolean)
		if bought then
			Kit.playSound("purchase")
		end
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_, _, bought: boolean)
		if bought then
			Kit.playSound("purchase")
		end
	end)
end)
