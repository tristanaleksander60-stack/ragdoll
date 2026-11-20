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
safe("PlotPrivacy", function() PlotPrivacy.start() end) -- (first: other labs leave this screen before anything draws them)
task.spawn(require(Client:WaitForChild("DummySkins")).start) -- the dummies' sculpted mannequin bodies
safe("SoundMix", function() require(Client:WaitForChild("SoundMix")).start() end) -- v4 A3: the mix's groups and compressor
task.spawn(require(Client:WaitForChild("NpcTalk")).start) -- v4 B4: the talk panel
task.spawn(require(Client:WaitForChild("SlowMotion")).start) -- v4 C5: smooth slow motion
task.spawn(require(Client:WaitForChild("VehicleFeel")).start) -- v4 C2: wheels, lean, lights, engine, horn
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
task.spawn(require(Client:WaitForChild("Birds")).start) -- V6-6: birds round the lab and the maps
task.spawn(require(Client:WaitForChild("CreatureLife")).start) -- 20 Nov: the lab creatures move while they wait
task.spawn(require(Client:WaitForChild("BoothSpin")).start) -- V6-7: the booth items turn on their pedestals
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
	if not (Config :: any).V8_FIRST_HIT then
		return
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
safe("Spectate", function() require(Client:WaitForChild("Spectate")).start() end) -- the owner's SPECTATE (admin menu)
safe("Ghosts", function() Ghosts.start() end)
safe("HospitalCharts", function() HospitalCharts.start() end)
safe("HitInfo", function() HitInfo.start() end) -- what you are shooting: two lines that add up (round 2, N2; round 3, M2)
safe("Crosshair", function() Crosshair.start() end) -- with a gun picked: a crosshair and hit marks (round 3, M2)
safe("TouchShoot", function() require(Client:WaitForChild("TouchShoot")).start() end) -- touch: SHOOT button, centre crosshair, "tap a dummy" (round 5)
safe("BloodFx", function() require(Client:WaitForChild("BloodFx")).useHoles(BulletHoles) end) -- bodies bleed from their bullet holes
safe("PlaceMenu", function() PlaceMenu.start() end)
safe("ZoneLighting", function() ZoneLighting.start() end)
safe("Settings", function() require(Client:WaitForChild("Settings")).start() end) -- SETTINGS, in MENU (round 3, M6)
safe("ChristmasFx", function() require(Client:WaitForChild("ChristmasFx")).start() end) -- falling snow while the Christmas theme is on (round 3, M7)
safe("ScheduleUI", function() require(Client:WaitForChild("ScheduleUI")).start() end) -- the ADMIN SHOW countdown and the free weekend (round 3, M9)
HudMenu.onSandbox = BuildController.toggle -- (MENU's SANDBOX on a phone)
safe("HudMenu", function() HudMenu.start() end)
safe("ProgressUI", function() ProgressUI.start() end)
safe("FirstPerson", function() require(Client:WaitForChild("FirstPerson")).start() end) -- V: first person (round 5)
safe("Viewmodel", function() require(Client:WaitForChild("Viewmodel")).start() end)
safe("FeelV2", function() require(Client:WaitForChild("FeelV2")).start() end) -- World/Feel v2: trails, casings, recoil, combo beat, world lamps (Config.FEEL_V2)
safe("ChaseHud", function() require(Client:WaitForChild("ChaseHud")).start() end)
safe("StuntHud", function() require(Client:WaitForChild("StuntHud")).start() end) -- V8-1.1: the CRASH score, the cannon's slow-mo beat, AGAIN
safe("SpawnKey", function() require(Client:WaitForChild("SpawnKey")).start() end) -- V8-2.5: H drops a dummy of a type where you aim
safe("NpcGlow", function() require(Client:WaitForChild("NpcGlow")).start() end)
safe("PortalUI", function() require(Client:WaitForChild("PortalUI")).start() end) -- SINGLEPLAYER / MULTIPLAYER portals, the server list (round 5)
safe("HudPlus", function() require(Client:WaitForChild("HudPlus")).start() end) -- big WEAPONS, LEVEL, today's deal, sandbox column (round 5)
safe("VehicleClient", function() require(Client:WaitForChild("VehicleClient")).start() end) -- v3 Phase C: drive the lab cars
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
