--!strict
-- OVERVIEW 0.7 (Config.MACHINE_WATCHERS; docs/ALWAYS3.md "Phone budget"): the light stand-ins. On this screen only, every
-- attraction within SHOW studs of the camera whose spot has no real watcher (the player attribute WatchedIds, set by
-- Systems/Watchers) gets a simple yellow mannequin standing on its watcher spot (Shared/WatchSpots), looking at the
-- machine and swaying a little. Anchored, no physics, no collisions: they cost nothing on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local WatcherStandIns = {}

WatcherStandIns.SHOW = 220
local SKIN = Color3.fromRGB(240, 200, 60)

local player = Players.LocalPlayer
local folder: Folder? = nil
local made: { [string]: Model } = {}

local function piece(m: Model, name: string, size: Vector3, cf: CFrame, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Size = size
	p.CFrame = cf
	p.Color = SKIN
	p.Material = Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Parent = m
	return p
end

-- A simple mannequin, its feet at `base`, facing `look`.
local function mannequin(id: string, base: Vector3, look: Vector3): Model
	local m = Instance.new("Model")
	m.Name = "StandIn_" .. id
	local cf = CFrame.lookAt(base, Vector3.new(look.X, base.Y, look.Z))
	local legs = piece(m, "Legs", Vector3.new(1.8, 2.6, 0.9), cf * CFrame.new(0, 1.3, 0))
	piece(m, "Torso", Vector3.new(2, 2, 1), cf * CFrame.new(0, 3.6, 0))
	piece(m, "Head", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 5.3, 0), Enum.PartType.Ball)
	piece(m, "ArmL", Vector3.new(0.8, 2, 0.8), cf * CFrame.new(-1.45, 3.6, 0))
	piece(m, "ArmR", Vector3.new(0.8, 2, 0.8), cf * CFrame.new(1.45, 3.6, 0) * CFrame.Angles(math.rad(-25), 0, 0))
	m.PrimaryPart = legs
	m:SetAttribute("BaseCF", legs.CFrame) -- (the pivot is the legs' middle)
	return m
end

local function originOf(): Vector3?
	-- the player's own lab: the OwnerMap grass part nearest the character
	local root = Workspace:FindFirstChild("Playground")
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not hrp or not hrp:IsA("BasePart") then
		return nil
	end
	local best, bestD = nil :: BasePart?, math.huge
	for _, lab in root:GetChildren() do
		local om = lab:FindFirstChild("OwnerMap")
		local g = om and om:FindFirstChild("OwnerGrass")
		if g and g:IsA("BasePart") then
			local d = (g.Position - hrp.Position).Magnitude
			if d < bestD then
				best, bestD = g, d
			end
		end
	end
	if not best then
		return nil
	end
	local c = Vector2.new(-22, 22) -- (LabOwnerMap.CENTER)
	return Vector3.new(best.Position.X - c.X, best.Position.Y + 1.05, best.Position.Z - c.Y)
end

function WatcherStandIns.start()
	if not Config.MACHINE_WATCHERS or not Config.LAB_OWNERMAP or Config.WATCHER_STANDINS == false then
		return -- (F45: no yellow stand-ins; the watchers are real grey ragdolls only)
	end
	local WatchSpots = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WatchSpots")) :: any
	local f = Instance.new("Folder")
	f.Name = "WatcherStandIns"
	f.Parent = Workspace
	folder = f
	task.spawn(function()
		local t = 0
		while true do
			task.wait(0.5)
			t += 0.5
			local o = originOf()
			local camera = Workspace.CurrentCamera
			if not o or not camera then
				continue
			end
			local watched: { [string]: boolean } = {}
			for id in string.gmatch(tostring(player:GetAttribute("WatchedIds") or ""), "[^,]+") do
				watched[id] = true
			end
			for _, s in WatchSpots.LIST do
				local base = Vector3.new(o.X + s.at.X, o.Y - 0.05, o.Z + s.at.Y)
				local show = not watched[s.id] and (base - camera.CFrame.Position).Magnitude < WatcherStandIns.SHOW
				local m = made[s.id]
				if show and not m then
					m = mannequin(s.id, base, Vector3.new(o.X + s.look.X, base.Y, o.Z + s.look.Y))
					m.Parent = f
					made[s.id] = m
				elseif not show and m then
					m:Destroy()
					made[s.id] = nil
				end
				-- a little sway now and then (the near ones only)
				if m and m.PrimaryPart and (base - camera.CFrame.Position).Magnitude < 90 then
					local cf = m:GetAttribute("BaseCF")
					if typeof(cf) == "CFrame" then
						m:PivotTo(m:GetPivot():Lerp(cf * CFrame.Angles(0, math.sin(t * 0.7 + #s.id) * 0.25, 0), 0.5))
					end
				end
			end
		end
	end)
end

return WatcherStandIns
