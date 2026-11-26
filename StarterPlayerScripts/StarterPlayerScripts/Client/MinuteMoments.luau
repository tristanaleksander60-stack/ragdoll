--!strict
-- NOW 4 (owner, 26 Nov 2026: "half the players at 2 min are gone by 5 min"): a planned moment at about
-- 2, 3 and 4 minutes for a newcomer, with no pop-up: the top goal pill says it for a few seconds
-- (HudV3.moment) and the thing itself gets a calm white outline. (The 1-minute moment is the angry
-- dummy, on the server: AngryDummy.)
--   2 min: the cannon            "Try the cannon!"
--   3 min: the nearest creature   "Feed a creature!"
--   4 min: the MAPS board         "New place: Island!"
-- Only for a player the server marks Newcomer; each moment once a visit; skipped while a window is
-- open (it waits up to WAIT_MAX s). Config.MINUTE_MOMENTS.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net")) :: any

local MinuteMoments = {}

MinuteMoments.SHOW = 8 -- s the line and the outline stay
MinuteMoments.WAIT_MAX = 40 -- s a moment waits for a closed window before it is dropped
MinuteMoments.LIST = {
	{ at = 120, text = "Try the cannon!", key = "Cannon" },
	{ at = 180, text = "Feed a creature!", key = "Creature" },
	{ at = 240, text = "New place: Island!", key = "Maps" },
}

local player = Players.LocalPlayer

local function root(): BasePart?
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r else nil
end

-- The nearest thing for a moment (within 300 studs of the player), or nil.
local function target(key: string): Instance?
	local me = root()
	if not me then
		return nil
	end
	local best: Instance? = nil
	local bestD = 300
	local function consider(inst: Instance, at: Vector3)
		local d = (at - me.Position).Magnitude
		if d < bestD then
			best, bestD = inst, d
		end
	end
	if key == "Cannon" then
		local playground = Workspace:FindFirstChild("Playground")
		for _, d in if playground then playground:GetDescendants() else {} do
			if d.Name == "CannonPad" and d:IsA("BasePart") then
				consider(d.Parent or d, d.Position)
			end
		end
	elseif key == "Creature" then
		for _, c in CollectionService:GetTagged("CreatureLife") do
			if c:IsA("Model") then
				consider(c, c:GetPivot().Position)
			end
		end
	elseif key == "Maps" then
		for _, s in CollectionService:GetTagged("MapBoardScreen") do
			if s:IsA("BasePart") then
				consider(s.Parent or s, s.Position)
			end
		end
	end
	return best
end

local function outline(inst: Instance, seconds: number)
	local h = Instance.new("Highlight")
	h.Name = "MinuteMoment"
	h.FillTransparency = 1
	h.OutlineColor = Color3.fromRGB(255, 255, 255)
	h.OutlineTransparency = 0.15
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Adornee = inst
	h.Parent = player:WaitForChild("PlayerGui")
	task.delay(seconds, function()
		h:Destroy()
	end)
end

local function show(m: { at: number, text: string, key: string })
	local Controller = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIController")) :: any
	local giveUp = os.clock() + MinuteMoments.WAIT_MAX
	while (Controller.getCurrent() ~= nil or player:GetAttribute("TryBusy") == true) and os.clock() < giveUp do -- (FIRST_2_MIN: never during a TRY)
		task.wait(1)
	end
	if Controller.getCurrent() ~= nil then
		return
	end
	local thing = target(m.key)
	if not thing then
		return
	end
	pcall(function()
		(require(script.Parent:WaitForChild("HudV3")) :: any).moment(m.text, MinuteMoments.SHOW)
	end)
	outline(thing, MinuteMoments.SHOW)
	-- (The dashboard sees which moments were shown: Funnels "Moments".)
	pcall(function()
		Net.event(Net.Names.Session):FireServer("Moment", m.key)
	end)
end

function MinuteMoments.start()
	if not Config.MINUTE_MOMENTS then
		return
	end
	task.spawn(function()
		-- (The server says whether this is a newcomer once the profile is read.)
		local waited = 0
		while player:GetAttribute("Newcomer") == nil and waited < 20 do
			task.wait(1)
			waited += 1
		end
		if player:GetAttribute("Newcomer") ~= true then
			return
		end
		local began = os.clock()
		for _, m in MinuteMoments.LIST do
			local wait = m.at - (os.clock() - began)
			if wait > 0 then
				task.wait(wait)
			end
			if player.Parent == nil then
				return
			end
			show(m)
		end
	end)
end

return MinuteMoments
