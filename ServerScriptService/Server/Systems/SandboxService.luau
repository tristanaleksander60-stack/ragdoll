--!strict
-- Round 5, phase 1: the sandbox buttons on the right edge (like the big ragdoll games: SLOW MO,
-- REVIVE ALL, RESET), for your own lab only. The client asks (remote Sandbox: "SlowMo" | "Revive" |
-- "Reset"); the server checks the player has a lab and stands in it, paces each action (GAP s), and:
--   SlowMo  a big slow-motion bubble over the lab's middle (ToyService's Slowmo, as the spell)
--   Revive  every dead dummy of the lab comes round, every hurt one is healed (VitalsService)
--   Reset   every knocked-about dummy back on its slot (Lab.rewind); the props go with CleanUp
-- Answers with a short notice (remote Progress "Notice", the toast the client already shows).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Lab = require(script.Parent.Lab)
local Knockables = require(script.Parent.Knockables)
local ToyService = require(script.Parent.ToyService)
local VitalsService = require(script.Parent.VitalsService)

local SandboxService = {}

SandboxService.GAP = { SlowMo = 8, Revive = 3, Reset = 2 } :: { [string]: number }
local last: { [Player]: { [string]: number } } = {}

local function inOwnLab(player: Player): boolean
	local index = Lab.plotIndex(player)
	if not index then
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false
	end
	local zone, at = Lab.zoneAt(root.Position)
	return zone == "Lab" and at == index
end

local function notice(player: Player, text: string)
	Net.event(Net.Names.Progress):FireClient(player, "Notice", text)
end

-- Runs one action for a player. Returns what happened (tests read it), or nil when refused.
function SandboxService.run(player: Player, action: unknown): string?
	if type(action) ~= "string" or SandboxService.GAP[action] == nil then
		return nil
	end
	if not inOwnLab(player) then
		notice(player, "Sandbox buttons work in your own lab")
		return nil
	end
	local now = os.clock()
	local mine = last[player] or {}
	last[player] = mine
	if now - (mine[action] or -math.huge) < SandboxService.GAP[action] then
		return nil
	end
	mine[action] = now
	if action == "SlowMo" then
		local centre = Lab.focusFor(player)
		local ok = ToyService.place(player, "Slowmo", centre, Vector3.new(0, 0, -1))
		return if ok then "slowmo" else nil
	elseif action == "Revive" then
		local n = 0
		for _, model in Lab.dummiesOf(player) do
			if VitalsService.reviveNow(model) then
				n += 1
			end
		end
		notice(player, if n > 0 then "Everyone is back on their feet!" else "Nobody needs a doctor")
		return "revived " .. n
	elseif action == "Reset" then
		pcall(function()
			(require(script.Parent:WaitForChild("DummySpawn")) :: any).clear(player) -- (V8-2.5: the spawned ones go)
		end)
		local n = Lab.rewind(player)
		local origin = player:GetAttribute("LabOrigin")
		if typeof(origin) == "Vector3" then
			Knockables.resetNear(origin, 140) -- (UI audit 21 Nov 2026: the knocked barrels go back too)
		end
		return "reset " .. n
	end
	return nil
end

------------------------------------------------------------------------------------------------
-- V9-2c (owner, 21 Nov 2026: "Z should not just stop time in a small spot in the lab, but open a small
-- menu where you turn time faster or slower in a bubble round yourself"; Config.TIME_DIAL): one time
-- bubble per player, centred on them and following them, in their own lab or the lab of the Prank
-- Party they are in. Speeds and sizes come only from the lists; changes are paced (TIME_GAP).
-- The bubble is a data part (tag SlowmoBubble, attributes TimeBubble, Scale, Radius, Owner, Ends): the
-- lab player's client runs the time in it for the bodies it simulates (Client/SlowMotion) and every
-- screen draws it round its owner (Client/TimeDial).

SandboxService.TIME_SPEEDS = { 0.1, 0.25, 0.5, 1, 2, 3 }
SandboxService.TIME_SIZES = { 12, 20, 30 } -- studs radius
SandboxService.TIME_GAP = 0.25 -- s between two changes
SandboxService.TIME_FOLLOW = 0.1 -- s between two moves of the data part

local bubbles: { [Player]: BasePart } = {}
local lastTime: { [Player]: number } = {}

-- Whether the player stands in a lab they may bend time in: their own, or their party's.
local function inTimeLab(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false
	end
	local zone, at = Lab.zoneAt(root.Position)
	if zone ~= "Lab" or at == nil then
		return false
	end
	if at == Lab.plotIndex(player) then
		return true
	end
	local host = player:GetAttribute("PartyLab")
	local hostPlayer = if type(host) == "number" then Players:GetPlayerByUserId(host) else nil
	return hostPlayer ~= nil and Lab.plotIndex(hostPlayer) == at
end

local function dropBubble(player: Player)
	local b = bubbles[player]
	bubbles[player] = nil
	if b then
		b:Destroy()
	end
	player:SetAttribute("TimeScale", nil)
end

-- The player's time bubble now (tests), or nil.
function SandboxService.bubbleOf(player: Player): BasePart?
	local b = bubbles[player]
	return if b and b.Parent then b else nil
end

-- Sets the player's bubble: a speed and a size from the lists, on or off. Returns "on", "off" or nil
-- when refused (and why).
function SandboxService.setTime(player: Player, speed: unknown, size: unknown, on: unknown): (string?, string?)
	if not (Config :: any).TIME_DIAL then
		return nil, "off"
	end
	if type(on) ~= "boolean" then
		return nil, "bad request"
	end
	if on and (type(speed) ~= "number" or not table.find(SandboxService.TIME_SPEEDS, speed) or type(size) ~= "number" or not table.find(SandboxService.TIME_SIZES, size)) then
		return nil, "bad request"
	end
	local now = os.clock()
	if now - (lastTime[player] or -math.huge) < SandboxService.TIME_GAP then
		return nil, "slow down"
	end
	lastTime[player] = now
	if not on then
		dropBubble(player)
		return "off", nil
	end
	if not inTimeLab(player) then
		notice(player, "Time bubbles work in your own lab")
		return nil, "not your lab"
	end
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not (rootPart and rootPart:IsA("BasePart")) then
		return nil, "not your lab"
	end
	local root = rootPart :: BasePart
	local b = bubbles[player]
	if not (b and b.Parent) then
		local p = Instance.new("Part")
		p.Name = "TimeBubble"
		p.Shape = Enum.PartType.Ball
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 1 -- (data only: every screen draws it round its owner, smoothly)
		p.Size = Vector3.one
		p:SetAttribute("TimeBubble", true)
		p:SetAttribute("Owner", player.UserId)
		p:SetAttribute("Ends", Workspace:GetServerTimeNow() + 24 * 3600)
		p.CFrame = CFrame.new(root.Position)
		p.Parent = Workspace
		CollectionService:AddTag(p, "SlowmoBubble")
		bubbles[player] = p
		b = p
	end
	local bubble = b :: BasePart
	bubble:SetAttribute("Scale", speed)
	bubble:SetAttribute("Radius", size)
	player:SetAttribute("TimeScale", speed)
	return "on", nil
end

function SandboxService.start()
	-- lihfolk-ignore: remote-unvalidated-args (action is only compared with fixed words, and run() checks its type; speed, size and on are checked in setTime)
	Net.event(Net.Names.Sandbox).OnServerEvent:Connect(function(player: Player, action: unknown, speed: unknown, size: unknown, on: unknown)
		if action == "Time" then
			SandboxService.setTime(player, speed, size, on) -- (every argument checked there)
			return
		end
		SandboxService.run(player, action)
	end)
	-- Every bubble follows its owner, and goes when they leave the lab.
	task.spawn(function()
		while true do
			task.wait(SandboxService.TIME_FOLLOW)
			for player, b in bubbles do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if not player.Parent or not b.Parent or not (root and root:IsA("BasePart")) or not inTimeLab(player) then
					dropBubble(player)
				else
					b.CFrame = CFrame.new(root.Position)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
		lastTime[player] = nil
		dropBubble(player)
	end)
end

-- Tests: forget the pacing.
function SandboxService.resetForTest(player: Player)
	last[player] = nil
	lastTime[player] = nil
end

return SandboxService
