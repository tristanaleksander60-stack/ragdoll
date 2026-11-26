--!strict
-- 20 Nov 2026 (the owner: "they must all work"): every one of the nine lab creatures, in the test
-- player's own yard:
--   has its own little home (CreatureHabitats: a Habitat folder) and, where it has a body, is tagged
--   to move on the screens (CreatureLife, with its kind and rest pose);
--   takes a lab body dropped into its trigger (InMachine = its id), marks itself Busy while it
--   works, lets the body go again and counts the event for the lab's owner.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local LabCreatures = require(Systems:WaitForChild("LabCreatures")) :: any
local ExperimentService = require(Systems:WaitForChild("ExperimentService")) :: any
local Lab = require(Systems:WaitForChild("Lab")) :: any

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

local NO_BODY = { Slingshot = true, Vacuum = true } -- (a tree with bands; the robot drives itself)

return {
	name = "T108_CreaturesWork",
	timeout = 200,
	run = function(): string?
		waitFor(function()
			return Players:GetPlayers()[1] ~= nil
		end, 15)
		local p = Players:GetPlayers()[1]
		if not p then
			return "skipped (no player)"
		end
		local yard: Instance? = nil
		assert(waitFor(function()
			local pg = Workspace:FindFirstChild("Playground")
			for _, f in if pg then pg:GetChildren() else {} do
				local y = f:FindFirstChild("CreatureYard")
				local pad = f:FindFirstChild("CannonPad")
				if y and pad and pad:IsA("BasePart") and Lab.ownerAt(pad.Position) == p then
					yard = y
					return true
				end
			end
			return false
		end, 15), "no creature yard in the player's lab")
		local y = yard :: Instance
		-- Homes and life.
		for _, spot in LabCreatures.LAYOUT do
			local found = y:FindFirstChild(spot.id)
			assert(found, spot.id .. " was not built")
			local f = found :: Instance
			assert(f:FindFirstChild("Habitat"), spot.id .. " has no home of its own")
			if not NO_BODY[spot.id] then
				local alive = false
				for _, c in f:GetChildren() do
					if CollectionService:HasTag(c, "CreatureLife") and c:GetAttribute("Creature") == spot.id and typeof(c:GetAttribute("LifeHome")) == "CFrame" then
						alive = true
					end
				end
				assert(alive, spot.id .. " is not tagged to come alive on the screens")
			end
		end
		-- Every machine works, one at a time, with the lab's own bodies.
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
		local worked = {}
		local ok, err = pcall(function()
			local function freeBody(): Model?
				for _, m in Workspace:WaitForChild("Dummies"):GetChildren() do
					if m:IsA("Model") and (m:GetAttribute("LabOwner") == p.UserId or m:GetAttribute("LabOwner") == p.Name) and m:GetAttribute("InMachine") == nil and m:GetAttribute("Held") ~= true and os.clock() >= ((m:GetAttribute("MachineCool") :: number?) or 0) then
						return m
					end
				end
				return nil
			end
			local frogF = y:FindFirstChild("Frog")
			local frogAt = if frogF then frogF:GetAttribute("Trigger") else nil
			for _, spot in LabCreatures.LAYOUT do
				local spotF = y:FindFirstChild(spot.id)
				assert(spotF, spot.id .. " is gone")
				local f = spotF :: Instance
				assert(waitFor(function()
					local at = f:GetAttribute("Trigger")
					-- (The frog's tongue reaches over the robot's east half: drop it in the west half.)
					return typeof(at) == "Vector3" and not (spot.id == "Vacuum" and typeof(frogAt) == "Vector3" and (at - frogAt).Magnitude < 34)
				end, 20), spot.id .. " never looked into its trigger")
				local body: Model? = nil
				assert(waitFor(function()
					body = freeBody()
					return body ~= nil
				end, 15), "no free lab body for " .. spot.id)
				local b = body :: Model
				local at = f:GetAttribute("Trigger") :: Vector3
				b:PivotTo(CFrame.new(at + Vector3.new(0, 1, 0)))
				local busySeen = false
				local function taken(): boolean
					return waitFor(function()
						busySeen = busySeen or f:GetAttribute("Busy") == true
						return b:GetAttribute("InMachine") == spot.id
					end, 6)
				end
				-- (A body can bounce out or run off before the machine's next look: one more drop.)
				local ok1 = taken()
				if not ok1 and b:GetAttribute("InMachine") == nil then
					b:PivotTo(CFrame.new((f:GetAttribute("Trigger") :: Vector3) + Vector3.new(0, 1, 0)))
					ok1 = taken()
				end
				assert(ok1, spot.id .. " did not take a body dropped into it (taken by " .. tostring(b:GetAttribute("InMachine")) .. ")")
				assert(waitFor(function()
					busySeen = busySeen or f:GetAttribute("Busy") == true
					return b:GetAttribute("InMachine") == nil
				end, 12), spot.id .. " never let the body go")
				assert(busySeen, spot.id .. " was never marked Busy while it worked")
				assert(waitFor(function()
					return (counted[spot.id] or 0) >= 1
				end, 4), spot.id .. " was not counted")
				table.insert(worked, spot.id)
				task.wait(0.5)
			end
		end)
		ExperimentService.onEvent = old
		if not ok then
			error(err, 0)
		end
		return string.format("all %d creatures have a home, %d come alive, every one took, worked and let go a body: %s", #LabCreatures.LAYOUT, #LabCreatures.LAYOUT - 2, table.concat(worked, ", "))
	end,
}
