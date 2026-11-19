--!strict
-- v3 Phase C: the open-air maps' launchers (OutdoorMaps marks them, MapActivities throws). Every
-- outdoor map has at least two; each speed is under the cap; a throw (no air drag, Roblox gravity)
-- lands inside its map's walls; and one real touch throws the player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Places = require(ReplicatedStorage.Shared.Places)
local Systems = script.Parent.Parent:WaitForChild("Systems")
local WorldMaps = require(Systems:WaitForChild("WorldMaps"))
local MapActivities = require(Systems:WaitForChild("MapActivities"))

return {
	name = "T93_MapActivities",
	timeout = 20,
	run = function(): string?
		if not Config.MAP_ACTIVITIES then
			return "MAP_ACTIVITIES off (nothing to check)"
		end
		local folder = WorldMaps.folder()
		assert(folder, "no places")
		local total = 0
		local g = Workspace.Gravity
		for _, place in Places.list do
			if place.outdoor then
				local model = (folder :: Instance):FindFirstChild(place.id)
				assert(model, place.id .. " was not built")
				local centre = Places.floorCenter(Vector3.zero, place.id) :: Vector3
				local half = place.size.X / 2
				local n = 0
				for _, d in (model :: Instance):GetDescendants() do
					local v = d:GetAttribute("Launch")
					if d:IsA("BasePart") and typeof(v) == "Vector3" then
						n += 1
						assert(type(d:GetAttribute("What")) == "string", place.id .. ": a launcher with no name")
						assert(v.Magnitude <= MapActivities.MAX_SPEED, string.format("%s: a launcher at %.0f studs/s", place.id, v.Magnitude))
						-- Up and down to the map's floor (a cliff top falls further): y0 + vy t - g t^2 / 2 = 0.
						local h = math.max(0, d.Position.Y - centre.Y)
						local t = (v.Y + math.sqrt(v.Y * v.Y + 2 * g * h)) / g
						local land = d.Position + Vector3.new(v.X, 0, v.Z) * t
						local off = land - centre
						assert(math.abs(off.X) < half and math.abs(off.Z) < half,
							string.format("%s: %s lands outside the map (%.0f, %.0f of %.0f)", place.id, tostring(d:GetAttribute("What")), off.X, off.Z, half))
					end
				end
				assert(n >= 2, string.format("%s has %d launchers (want 2+)", place.id, n))
				total += n
			end
		end
		-- One real throw: the player stood on the first launcher found is thrown up.
		local player = Players:GetPlayers()[1]
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local pad: BasePart? = nil
		for _, d in (folder :: Instance):GetDescendants() do
			if d:IsA("BasePart") and typeof(d:GetAttribute("Launch")) == "Vector3" then
				pad = d
				break
			end
		end
		local thrown = "no player to throw"
		if root and root:IsA("BasePart") and pad then
			local start = os.clock()
			local peak = -math.huge
			local body = character :: Model
			body:PivotTo(CFrame.new(pad.Position + Vector3.new(0, 3, 0)))
			while os.clock() - start < 3 do
				peak = math.max(peak, root.Position.Y - pad.Position.Y)
				task.wait()
			end
			assert(peak > 12, string.format("standing on %s did not throw the player (rose %.1f)", tostring(pad:GetAttribute("What")), peak))
			thrown = string.format("%s threw the player %.0f studs up", tostring(pad:GetAttribute("What")), peak)
		end
		return string.format("%d launchers on %d maps, all land inside; %s", total, Places.OUTDOORS, thrown)
	end,
}
