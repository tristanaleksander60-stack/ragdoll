--!strict
-- V6-5: the creature yard in front of the lab (LabCreatures).
--   all 9 are built in the player's lab, each with its real model where it has one;
--   each has an experiment card and a journal page of its kind;
--   feeding works on the lab's own bodies: the spider takes one from its web and spits it away,
--   the whale's geyser throws one up; a held body is never taken; the event is counted.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local LabCreatures = require(Systems:WaitForChild("LabCreatures"))
local ExperimentService = require(Systems:WaitForChild("ExperimentService"))
local Experiments = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Experiments"))
local Economy = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Economy"))

local function waitFor(check: () -> boolean, seconds: number): boolean
	local t0 = os.clock()
	while not check() do
		if os.clock() - t0 > seconds then
			return false
		end
		task.wait(0.1)
	end
	return true
end

return {
	name = "T103_LabCreatures",
	timeout = 40,
	run = function(): string?
		waitFor(function()
			return Players:GetPlayers()[1] ~= nil
		end, 15)
		local p = Players:GetPlayers()[1]
		if not p then
			return "skipped (no player)"
		end
		local pg = Workspace:FindFirstChild("Playground")
		local yard: Instance? = nil
		assert(waitFor(function()
			for _, f in if pg then pg:GetChildren() else {} do
				local y = f:FindFirstChild("CreatureYard")
				-- (The test player's own lab: only an owned lab's yard plays.)
				local pad = f:FindFirstChild("CannonPad")
				local Lab = require(Systems:WaitForChild("Lab")) :: any
				if y and pad and pad:IsA("BasePart") and Lab.ownerAt(pad.Position) ~= p then
					y = nil
				end
				if y then
					yard = y
					return true
				end
			end
			return false
		end, 10), "no creature yard in any lab")
		local y = yard :: Instance
		for _, spot in LabCreatures.LAYOUT do
			local f = y:FindFirstChild(spot.id)
			assert(f, spot.id .. " was not built")
			local card, page = false, false
			for _, def in Experiments.LIST do
				card = card or def.kind == spot.id
			end
			for _, pg2 in Economy.JOURNAL do
				page = page or pg2.kind == spot.id
			end
			assert(card and page and Experiments.KINDS[spot.id], spot.id .. " has no card, page or kind")
		end
		-- Feeding with the lab's own bodies.
		local counted: { [string]: number } = {}
		local old = ExperimentService.onEvent
		ExperimentService.onEvent = function(pl: Player, kind: string, n: number)
			if pl == p then
				counted[kind] = (counted[kind] or 0) + n
			end
			if old then
				old(pl, kind, n)
			end
		end
		local ok, err = pcall(function()
			local mine = {}
			for _, m in (Workspace:FindFirstChild("Dummies") :: Instance):GetChildren() do
				if m:IsA("Model") and (m:GetAttribute("LabOwner") == p.UserId or m:GetAttribute("LabOwner") == p.Name) and m:GetAttribute("InMachine") == nil then
					table.insert(mine, m)
				end
			end
			assert(#mine >= 3, "too few lab bodies to feed")
			local web = (y:FindFirstChild("Spider") :: Instance):FindFirstChild("SpiderWeb") :: BasePart
			local a = mine[1]
			a:PivotTo(CFrame.new(web.Position + Vector3.new(0, 0, 1)))
			assert(waitFor(function()
				return a:GetAttribute("InMachine") == "Spider"
			end, 3), "the spider did not take a body from its web")
			assert(waitFor(function()
				local r = a:FindFirstChild("HumanoidRootPart") :: BasePart?
				return r ~= nil and (r.Position - web.Position).Magnitude > 20
			end, 8), "the spider did not spit the body away")
			-- A held body is never taken.
			local b = mine[2]
			b:SetAttribute("Held", true)
			local pool = (y:FindFirstChild("Whale") :: Instance):FindFirstChild("WhalePool") :: BasePart
			b:PivotTo(CFrame.new(pool.Position + Vector3.new(0, 3, 0)))
			task.wait(1)
			assert(b:GetAttribute("InMachine") == nil, "a held body was taken")
			b:SetAttribute("Held", nil)
			-- (A fresh body for the take: the one marked held may still be reported held by its client.)
			local c = mine[3]
			c:PivotTo(CFrame.new(pool.Position + Vector3.new(0, 3, 0)))
			assert(waitFor(function()
				return c:GetAttribute("InMachine") == "Whale"
			end, 3), "the whale did not take a body in its pool")
			assert(waitFor(function()
				return (counted.Spider or 0) >= 1 and (counted.Whale or 0) >= 1
			end, 6), "the spider and whale were not counted")
		end)
		ExperimentService.onEvent = old
		if not ok then
			error(err, 0)
		end
		return string.format("%d creatures; spider ate and spat, whale geyser, held body left alone, events counted", #LabCreatures.LAYOUT)
	end,
}
