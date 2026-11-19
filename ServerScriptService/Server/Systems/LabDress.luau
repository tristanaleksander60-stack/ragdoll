--!strict
-- v3 (19 Nov 2026): each lab dressed like the leader's test ground with real models (V3Assets):
-- a giant fan and a rocket on the west side, barrels and crates in the corners, benches and street
-- lamps along the edges, a fence along the back. Scenery only (no collisions on small pieces, so
-- play is the same); placed only for the roles the place has, nothing code-built.

local V3Assets = require(script.Parent.V3Assets)

local LabDress = {}

type Spot = { role: string, x: number, z: number, yaw: number, size: number?, height: number?, collide: boolean? }

-- Lab space (x across, z along; the dummies' row at z -20, the crash wall at z -74, the stations
-- at z 52, the cars on the east side at x 66-68; Playground keeps the middle free).
LabDress.SPOTS = {
	{ role = "BigFan", x = -70, z = -60, yaw = 90, height = 16, collide = true },
	{ role = "Rocket", x = -72, z = 12, yaw = 0, height = 26, collide = true },
	{ role = "Barrel", x = 50, z = -82, yaw = 0, height = 4 },
	{ role = "Barrel", x = 53, z = -80, yaw = 40, height = 4 },
	{ role = "Barrel", x = 51, z = -77, yaw = 80, height = 4 },
	{ role = "Barrel", x = -46, z = -84, yaw = 10, height = 4 },
	{ role = "Barrel", x = -43, z = -82, yaw = 60, height = 4 },
	{ role = "Crate", x = -60, z = -80, yaw = 15, height = 4.5 },
	{ role = "Crate", x = -64, z = -78, yaw = 50, height = 4.5 },
	{ role = "Crate", x = -62, z = -74, yaw = 5, height = 3.5 },
	{ role = "Bench", x = -40, z = 66, yaw = 180, size = 7 },
	{ role = "Bench", x = 40, z = 66, yaw = 180, size = 7 },
	{ role = "StreetLamp", x = -78, z = -90, yaw = 45, height = 16 },
	{ role = "StreetLamp", x = 78, z = -90, yaw = -45, height = 16 },
	{ role = "StreetLamp", x = -78, z = 68, yaw = 135, height = 16 },
	{ role = "StreetLamp", x = 78, z = 68, yaw = -135, height = 16 },
	{ role = "Cone", x = 58, z = 30, yaw = 0, height = 2.2 },
	{ role = "Cone", x = 58, z = 10, yaw = 0, height = 2.2 },
	{ role = "Cone", x = 60, z = -24, yaw = 0, height = 2.2 },
	{ role = "Cone", x = 60, z = -40, yaw = 0, height = 2.2 },
} :: { Spot }

-- v3 phase C: the throw tower (north-west corner): a stone watch tower, a lift pad at its foot
-- (MapActivities TeleportTo) that puts you on top, and a launcher up there that throws you out
-- over the lab, the way friends throw each other off it.
LabDress.TOWER = { x = -66, z = 44, height = 30 }

function LabDress.throwTower(folder: Instance, origin: Vector3)
	if not V3Assets.has("CastleTower") then
		return
	end
	local spec = LabDress.TOWER
	local base = origin + Vector3.new(spec.x, 0, spec.z)
	local tower = V3Assets.place("CastleTower", folder, CFrame.new(base), { height = spec.height, collide = true, name = "ThrowTower" })
	if not tower then
		return
	end
	-- Its real top: a ray down onto the tower only.
	local only = RaycastParams.new()
	only.FilterType = Enum.RaycastFilterType.Include
	only.FilterDescendantsInstances = { tower }
	local hit = workspace:Raycast(base + Vector3.new(0, spec.height + 30, 0), Vector3.new(0, -spec.height - 40, 0), only)
	local top = if hit then hit.Position else base + Vector3.new(0, spec.height, 0)
	local function pad(name: string, at: Vector3, size: number, colour: Color3): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = Vector3.new(size, 0.6, size)
		p.CFrame = CFrame.new(at + Vector3.new(0, 0.3, 0))
		p.Color = colour
		p.Material = Enum.Material.Neon
		p.Parent = folder
		return p
	end
	local _, size = tower:GetBoundingBox()
	-- The lift on the side that faces the lab's middle (east), just outside the wall.
	local lift = pad("TowerLift", base + Vector3.new(size.X / 2 + 4, 0, 0), 6, Color3.fromRGB(80, 200, 255))
	lift:SetAttribute("TeleportTo", top + Vector3.new(0, 4, 0))
	lift:SetAttribute("What", "the THROW TOWER")
	local jump = pad("TowerJump", top + Vector3.new(2, 0, 0), 5, Color3.fromRGB(255, 120, 40))
	jump:SetAttribute("Launch", Vector3.new(85, 60, -10))
	jump:SetAttribute("What", "the THROW TOWER")
	jump:SetAttribute("Kind", "Tower")
	local MapActivities = require(script.Parent.MapActivities)
	MapActivities.wire(lift)
	MapActivities.wire(jump)
end

-- The fence along the back edge (z -94), a piece every FENCE_STEP studs.
LabDress.FENCE_STEP = 12

function LabDress.dress(into: Instance, origin: Vector3)
	local folder = Instance.new("Folder")
	folder.Name = "Dress"
	folder.Parent = into
	for _, s in LabDress.SPOTS do
		if V3Assets.has(s.role) then
			local at = CFrame.new(origin + Vector3.new(s.x, 0, s.z)) * CFrame.Angles(0, math.rad(s.yaw), 0)
			V3Assets.place(s.role, folder, at, { size = s.size, height = s.height, collide = s.collide == true })
		end
	end
	if V3Assets.has("Fence") then
		local x = -78
		while x <= 78 do
			local at = CFrame.new(origin + Vector3.new(x, 0, -94))
			V3Assets.place("Fence", folder, at, { size = LabDress.FENCE_STEP, collide = true })
			x += LabDress.FENCE_STEP
		end
	end
	LabDress.throwTower(folder, origin)
	if #folder:GetChildren() == 0 then
		folder:Destroy()
	end
end

return LabDress
