--!strict
-- v4 A2: a body buried in the ground is lifted onto it; one standing on it is left alone; every
-- open-air map has solid ground under its arrival pad.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Places = require(ReplicatedStorage.Shared.Places)
local Systems = script.Parent.Parent:WaitForChild("Systems")
local GroundGuard = require(Systems:WaitForChild("GroundGuard"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local WorldMaps = require(Systems:WaitForChild("WorldMaps"))

return {
	name = "T96_GroundGuard",
	timeout = 15,
	run = function(): string?
		local body = DummyFactory.spawn(Vector3.new(-40, 3, -320))
		task.wait(0.8)
		local pelvisPart = body:WaitForChild("LowerTorso", 2)
		assert(pelvisPart and pelvisPart:IsA("BasePart"), "no pelvis")
		local pelvis: BasePart = pelvisPart
		-- Standing: left alone.
		assert(not GroundGuard.check(body), "a standing body was moved")
		-- Buried: the pelvis under the ground line.
		local down = pelvis.Position.Y - (-1.2)
		body:PivotTo(body:GetPivot() - Vector3.new(0, down, 0))
		for _, p in body:GetDescendants() do
			if p:IsA("BasePart") then
				p.AssemblyLinearVelocity = Vector3.zero
			end
		end
		assert(GroundGuard.check(body), "a buried body was not lifted")
		local liftedTo = pelvis.Position.Y
		assert(liftedTo > 0.5, string.format("lifted only to %.1f", liftedTo))
		body:Destroy()
		-- Solid ground under every open-air map's arrival.
		local folder = WorldMaps.folder()
		local checked = 0
		for _, place in Places.list do
			if place.outdoor then
				local model = folder and folder:FindFirstChild(place.id)
				local pad = model and model:FindFirstChild("Arrival")
				assert(pad and pad:IsA("BasePart"), place.id .. " has no arrival pad")
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { pad }
				local hit = Workspace:Raycast(pad.Position + Vector3.new(0, 6, 0), Vector3.new(0, -20, 0), params)
				assert(hit and (hit.Instance:IsA("Terrain") or (hit.Instance :: BasePart).CanCollide), place.id .. ": nothing solid under the arrival")
				checked += 1
			end
		end
		return string.format("a buried body lifted (pelvis at %.1f), a standing one left; solid ground under %d arrival pads", liftedTo, checked)
	end,
}
