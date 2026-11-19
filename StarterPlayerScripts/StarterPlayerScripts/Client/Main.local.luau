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
-- The hand-drawn icons (Shared.DrawnIcons), before anything draws an icon.
require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIIcons")).registerMany(require(Shared:WaitForChild("DrawnIcons")).ASSETS)
PlotPrivacy.start() -- (first: other labs leave this screen before anything draws them)
task.spawn(require(Client:WaitForChild("DummySkins")).start) -- the dummies' sculpted mannequin bodies
FxController.start()
AvatarMoves.start()

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
DummySim.start()
DummyLife.start()
PropContacts.start()
PokeController.start()
GrabController.start()
PlayerBody.start()
require(Client:WaitForChild("PlayerGrabClient")).start() -- grab and throw players in the plaza
ReplayController.start()
LabCamera.start()
require(Client:WaitForChild("Sprint")).start() -- hold Shift / RUN / L3 to sprint (round 4, M10)
ChaosMeter.start()
BuildController.start()
OnboardingController.start()
EventShop.start()
require(Client:WaitForChild("Spectate")).start() -- the owner's SPECTATE (admin menu)
Ghosts.start()
HospitalCharts.start()
HitInfo.start() -- what you are shooting: two lines that add up (round 2, N2; round 3, M2)
Crosshair.start() -- with a gun picked: a crosshair and hit marks (round 3, M2)
require(Client:WaitForChild("TouchShoot")).start() -- touch: SHOOT button, centre crosshair, "tap a dummy" (round 5)
require(Client:WaitForChild("BloodFx")).useHoles(BulletHoles) -- bodies bleed from their bullet holes
PlaceMenu.start()
ZoneLighting.start()
require(Client:WaitForChild("Settings")).start() -- SETTINGS, in MENU (round 3, M6)
require(Client:WaitForChild("ChristmasFx")).start() -- falling snow while the Christmas theme is on (round 3, M7)
require(Client:WaitForChild("ScheduleUI")).start() -- the ADMIN SHOW countdown and the free weekend (round 3, M9)
HudMenu.onSandbox = BuildController.toggle -- (MENU's SANDBOX on a phone)
HudMenu.start()
ProgressUI.start()
require(Client:WaitForChild("FirstPerson")).start() -- V: first person (round 5)
require(Client:WaitForChild("Viewmodel")).start()
require(Client:WaitForChild("ChaseHud")).start()
require(Client:WaitForChild("NpcGlow")).start()
require(Client:WaitForChild("PortalUI")).start() -- SINGLEPLAYER / MULTIPLAYER portals, the server list (round 5) -- the dummies' slow purple glow (round 5) -- the health bar in an NPC Chase (round 5) -- the weapon in front of the camera in first person
require(Client:WaitForChild("HudPlus")).start() -- big WEAPONS, LEVEL, today's deal, sandbox column (round 5)
require(Client:WaitForChild("RewardsUI")).start() -- REWARDS: daily, play gift, dares, trophies, group (round 5)
require(Client:WaitForChild("GiftClock")).start() -- the clock to the next free gift for time played
MinigameHud.start()
FriendsUI.start()
-- (Round 5: no background music; the owner removed the radio.)
ControlsUI.start()
require(Client:WaitForChild("LikePrompt")).start() -- a friendly "like the game" ask (round 4)
CreatorUI.start()
require(Client:WaitForChild("ExperimentCard")).start() -- phase 1: the experiment card and EXPERIMENTS window
ReplayController.currentToy = PokeController.getSelected -- (phase 1: the X-ray replay's SHARE CODE)
ReplayController.onScore = require(Client:WaitForChild("ExperimentCard")).scored
require(Client:WaitForChild("GamepadControls")).start() -- phase 0: the whole game on a gamepad (Shared\PadMap)
ToolCatalog.bindHospital(HospitalCharts.isDoctor, function(on: boolean)
	HospitalCharts.setDoctor(on)
end)
HospitalCharts.onChanged = function()
	ToolCatalog.refreshHospital()
end
