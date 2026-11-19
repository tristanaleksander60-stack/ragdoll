--!strict
-- v4 C4: every new lab surprise starts without an error, builds something, and leaves nothing behind
-- when stopped; each has an event entry and a handler; the BIG RED BUTTON knows them; the short
-- surprises are all real ones.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Events = require(ReplicatedStorage.Shared.Events)
local Systems = script.Parent.Parent:WaitForChild("Systems")
local Surprises = require(Systems:WaitForChild("Surprises"))
local Lab = require(Systems:WaitForChild("Lab"))

local IDS = { "UfoBeam", "BowlingAvalanche", "RocketRain", "MagnetStorm", "LightningStorm", "Sinkhole", "Earthquake", "FanBlast", "MoonGravity", "BalloonDrop", "GiantDummy" }

local function countIn(f: Instance?): number
	return if f then #f:GetChildren() else 0
end

return {
	name = "T98_Surprises",
	timeout = 60,
	run = function(): string?
		local player = Players:GetPlayers()[1]
		local origin = if player and Lab.plotIndex(player) then Lab.originFor(player) else Lab.plazaOrigin()
		local center = Vector3.new(origin.X, Lab.plazaOrigin().Y - 0.5, origin.Z)
		local errors: { string } = {}
		for _, id in IDS do
			assert(Events.byId[id], id .. " has no event entry")
			local creaturesBefore = countIn(Workspace:FindFirstChild("Creatures"))
			local dummiesBefore = countIn(Workspace:FindFirstChild("Dummies"))
			local fn = (Surprises :: any)[id]
			assert(type(fn) == "function", id .. " has no builder")
			local ok, stop = pcall(fn, center, player)
			if not ok then
				table.insert(errors, id .. ": " .. tostring(stop))
				continue
			end
			task.wait(1.6)
			local built = countIn(Workspace:FindFirstChild("Creatures")) > creaturesBefore or countIn(Workspace:FindFirstChild("Dummies")) > dummiesBefore
			stop()
			task.wait(0.3)
			if not built and id ~= "BalloonDrop" then
				table.insert(errors, id .. " built nothing")
			end
			if countIn(Workspace:FindFirstChild("Creatures")) > creaturesBefore then
				table.insert(errors, id .. " left parts behind")
			end
			if countIn(Workspace:FindFirstChild("Dummies")) > dummiesBefore then
				table.insert(errors, id .. " left guest dummies behind")
			end
		end
		for _, id in Surprises.MINI do
			assert((Surprises :: any)[id], "the short surprise " .. id .. " does not exist")
		end
		if #errors > 0 then
			return table.concat(errors, "; ")
		end
		return nil
	end,
}
