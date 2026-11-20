--!strict
-- V9-0d (owner, 21 Nov 2026: "fix the table and bench set on the plaza and upgrade the plaza so people
-- want to meet there"; Config.PLAZA_V9): the plaza is a town square. The fountain stands in the middle
-- with open paving round it; four seating groups (a picnic set under a shade tree); two benches facing
-- each other; string lights between the lamps; the toss pit, the meet stage (Dance) and the photo spot
-- (Photo); the welcome board is the gate on the way in. Every seat in the game's benches and picnic
-- sets works: enabled, level, at a sitting height, and a player really sits on one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

return {
	name = "T168_TownSquare",
	timeout = 60,
	run = function(): string?
		if not Config.PLAZA_V9 then
			return "skipped (PLAZA_V9 off)"
		end
		assert(TestLib.waitFor(function()
			return Workspace:FindFirstChild("PlazaDressing") ~= nil
		end, 40), "no plaza dressing")
		local dressing = (Workspace :: any).PlazaDressing :: Model
		local middle = Vector3.new(0, 0, 85)
		local function flat(v: Vector3): Vector3
			return Vector3.new(v.X, 0, v.Z)
		end
		-- The centre piece in the middle, open round it.
		local fountain = dressing:FindFirstChild("Fountain")
		assert(fountain and fountain:IsA("Model") and flat(fountain:GetPivot().Position - middle).Magnitude < 2, "the fountain is not the square's centre piece")
		local count: { [string]: number } = {}
		for _, c in dressing:GetChildren() do
			count[c.Name] = (count[c.Name] or 0) + 1
			if c:IsA("Model") and c.Name ~= "Fountain" and c.Name ~= "StringLights" and c.Name ~= "Paving" then
				local d = flat(c:GetPivot().Position - middle).Magnitude
				assert(d >= 12, c.Name .. " stands in the open ring round the fountain (" .. math.floor(d) .. " studs)")
			end
		end
		assert((count.SeatGroup or 0) == 4, "not four seating groups")
		assert((count.BenchPair or 0) == 2, "not two benches facing each other")
		for _, name in { "StringLights", "TossPit", "MeetStage", "PhotoSpot" } do
			assert((count[name] or 0) == 1, "no " .. name)
		end
		-- Shade trees and lights.
		local trees, bulbs = 0, 0
		for _, d in dressing:GetDescendants() do
			if d.Name == "ShadeTree" then
				trees += 1
			elseif d.Name == "Bulb" then
				bulbs += 1
			end
		end
		assert(trees == 4 and bulbs >= 40, string.format("%d shade trees, %d bulbs", trees, bulbs))
		-- The prompts.
		local dance = dressing:FindFirstChild("PlazaDance", true)
		local photo = dressing:FindFirstChild("PlazaPhoto", true)
		assert(dance and dance:IsA("ProximityPrompt") and photo and photo:IsA("ProximityPrompt"), "the stage or the photo spot has no prompt")
		local spot = dressing:FindFirstChild("PhotoSpot")
		assert(spot and typeof(spot:GetAttribute("CameraAt")) == "Vector3", "the photo spot has no camera spot")
		-- Every seat of every bench and picnic set in the game works.
		local seats, checked = {}, 0
		for _, d in Workspace:GetDescendants() do
			if d:IsA("Seat") then
				local owner = d:FindFirstAncestor("Bench") or d:FindFirstAncestor("PicnicSet")
				local name = owner and owner.Name or ""
				if name == "Bench" or name == "PicnicSet" then
					checked += 1
					assert(not d.Disabled, name .. " has a seat switched off at " .. tostring(d.Position))
					assert(d.CFrame.UpVector.Y > 0.95, name .. " has a tilted seat")
					local base = owner and (owner :: Model):GetPivot().Position.Y or d.Position.Y
					local h = d.Position.Y - base
					assert(h > 0.7 and h < 3.2, string.format("%s seat at %.1f studs, not a sitting height", name, h))
					table.insert(seats, d)
				end
			end
		end
		assert(checked >= 4 * 6 + 2 * 2, "only " .. checked .. " bench and picnic seats found")
		-- A player sits on one of the plaza's picnic seats.
		local sat = "no player to sit"
		local p = Players:GetPlayers()[1]
		local humanoid = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local seat: Seat? = nil
			for _, s in seats do
				if s:IsDescendantOf(dressing) and (s :: Seat).Occupant == nil then
					seat = s :: Seat
					break
				end
			end
			assert(seat, "no free plaza seat")
			local home = (p.Character :: Model):GetPivot()
			;(p.Character :: Model):PivotTo((seat :: Seat).CFrame + Vector3.new(0, 3, 0))
			task.wait(0.3)
			;(seat :: Seat):Sit(humanoid)
			assert(TestLib.waitFor(function()
				return humanoid.SeatPart == seat
			end, 3), "the player did not sit")
			local root = humanoid.RootPart
			local above = if root then root.Position.Y - (seat :: Seat).Position.Y else 0
			assert(above > 0.5 and above < 4, "the player sits at a wrong height: " .. above)
			-- (Moved away while sitting, a trip or a respawn: the seat stays home, V3Assets.guardSeat.)
			local seatHome = (seat :: Seat).Position
			;(p.Character :: Model):PivotTo(home)
			task.wait(0.6)
			local drift = ((seat :: Seat).Position - seatHome).Magnitude
			assert(drift < 0.5, string.format("the seat was dragged %.0f studs by a player moved while sitting", drift))
			humanoid.Sit = false
			sat = string.format("a player sat (root %.1f over the seat); moved away sitting, the seat stayed home", above)
		end
		return string.format("fountain in the middle, 4 seating groups under shade trees, 2 benches facing, %d bulbs, toss pit, stage, photo spot; %d seats working; %s", bulbs, checked, sat)
	end,
}
