--!strict
-- Round 5, phase 3: a living lab. While you are in your own lab, VISITORS ragdolls wander about it
-- trying the things there on their own: the human cannon, the PUT RAGDOLL HERE stations, the
-- trampoline, the lava. They walk to one (their Home), step on, get thrown (the pads' LaunchVelocity
-- does it: your client simulates them, PropContacts), and once up again pick the next. They are
-- ordinary dummies otherwise (hit them, grab them: takedowns as usual). Gone when you leave your
-- lab or the game. Only with room under the server's body cap (EventService.dummyRoom), so a full
-- server never carries more than it can (T37).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DummyFactory = require(script.Parent.DummyFactory)
local Lab = require(script.Parent.Lab)
local EventService = require(script.Parent.EventService)
local SessionStats = require(script.Parent.SessionStats)
local DeviceTier = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("DeviceTier"))

local VisitorService = {}

VisitorService.VISITORS = 3
VisitorService.ROOM_KEEP = 8 -- bodies always left free under the cap for events and the horde
VisitorService.TRY_EVERY = 14 -- s a visitor stays with one thing before it picks another
VisitorService.SPOTS = { "CannonPad", "StationPad", "TrampolinePad", "LavaPool" }
local SHIRTS = { Color3.fromRGB(60, 160, 255), Color3.fromRGB(255, 170, 40), Color3.fromRGB(120, 220, 110) }

type Visitor = { model: Model, pickedAt: number }
local visitors: { [Player]: { Visitor } } = {}

local function inOwnLab(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local index = Lab.plotIndex(player)
	if not (root and root:IsA("BasePart")) or not index then
		return false
	end
	local zone, at = Lab.zoneAt(root.Position)
	return zone == "Lab" and at == index
end

-- The things in a player's lab a visitor can go and try.
function VisitorService.spotsOf(player: Player): { BasePart }
	local index = Lab.plotIndex(player)
	local root = Workspace:FindFirstChild("Playground")
	local lab = index and root and root:FindFirstChild("Lab" .. index)
	local list = {}
	if lab then
		for _, p in lab:GetChildren() do
			if p:IsA("BasePart") and table.find(VisitorService.SPOTS, p.Name) then
				table.insert(list, p)
			end
		end
	end
	return list
end

local function pick(player: Player, v: Visitor)
	local spots = VisitorService.spotsOf(player)
	if #spots == 0 then
		return
	end
	local spot = spots[math.random(1, #spots)]
	local pelvis = v.model:FindFirstChild("LowerTorso")
	local y = if pelvis and pelvis:IsA("BasePart") then pelvis.Position.Y else spot.Position.Y + 3
	v.model:SetAttribute("Home", Vector3.new(spot.Position.X, y, spot.Position.Z))
	v.model:SetAttribute("HomeLook", Vector3.new(spot.Position.X, y, spot.Position.Z - 5))
	v.pickedAt = os.clock()
end

local function clear(player: Player)
	for _, v in visitors[player] or {} do
		if v.model.Parent and v.model:GetAttribute("Vital") ~= "Dead" then
			v.model:Destroy()
		end
	end
	visitors[player] = nil
end

local function fill(player: Player)
	local list = visitors[player] or {}
	visitors[player] = list
	for i = #list, 1, -1 do
		if not list[i].model.Parent then
			table.remove(list, i)
		end
	end
	-- (Phase 1: the player's device simulates its lab's bodies: a phone gets fewer. DeviceTier.)
	local record = SessionStats.recordFor(player)
	local cap = math.min(VisitorService.VISITORS, DeviceTier.caps(DeviceTier.of(record and record.plat)).visitors)
	local want = cap - #list
	if want <= 0 then
		return
	end
	want = math.min(want, math.max(0, EventService.dummyRoom() - VisitorService.ROOM_KEEP))
	local center = Lab.focusFor(player)
	for i = 1, want do
		local at = center + Vector3.new(math.random(-20, 20), 3, math.random(15, 40))
		local model = DummyFactory.spawn(at, center, player)
		model.Name = "Visitor"
		model:SetAttribute("Visitor", player.UserId)
		model:SetAttribute("Personality", "Brave")
		local shirt = SHIRTS[(#list + i - 1) % #SHIRTS + 1]
		for _, d in model:GetChildren() do
			if d:IsA("BasePart") and string.find(d.Name, "Torso") then
				d.Color = shirt
			end
		end
		local v: Visitor = { model = model, pickedAt = 0 }
		table.insert(list, v)
		-- Thrown, then up again: on to the next thing (a moment after getting up).
		local wasDown = false
		model:GetAttributeChangedSignal("RagdollState"):Connect(function()
			local s = model:GetAttribute("RagdollState")
			local down = s == "Ragdoll" or s == "Out"
			if wasDown and s == "Standing" then
				task.delay(1.5, function()
					if model.Parent then
						pick(player, v)
					end
				end)
			end
			wasDown = down
		end)
		pick(player, v)
	end
end

-- Tests: a player's visitors now.
function VisitorService.of(player: Player): { Model }
	local out = {}
	for _, v in visitors[player] or {} do
		if v.model.Parent then
			table.insert(out, v.model)
		end
	end
	return out
end
function VisitorService.tickForTest(player: Player)
	if inOwnLab(player) then
		fill(player)
	else
		clear(player)
	end
end
VisitorService.clearForTest = clear

function VisitorService.start()
	Players.PlayerRemoving:Connect(clear)
	task.spawn(function()
		while true do
			task.wait(4)
			local testing = game:GetService("RunService"):IsStudio() and game:GetService("ServerStorage"):GetAttribute("RunSelfTest") == true
			for _, player in Players:GetPlayers() do
				if testing then
					continue -- (the tests set their own scenes: VisitorService.tickForTest)
				end
				if inOwnLab(player) then
					fill(player)
					for _, v in visitors[player] or {} do
						if os.clock() - v.pickedAt > VisitorService.TRY_EVERY then
							pick(player, v)
						end
					end
				elseif visitors[player] then
					clear(player)
				end
			end
		end
	end)
end

return VisitorService
