--!strict
-- V9-0d (owner, 21 Nov 2026: "upgrade the plaza so people want to meet there"; Config.PLAZA_V9): the
-- plaza as a town square round its fountain (WorldMaps puts the fountain in the middle and calls
-- this). Everything here is a model under PlazaDressing, most marked KeepOut (CrowdService: the crowd
-- never meets inside it):
--   * four seating groups on the diagonals: a real picnic set (6 seats) under a shade tree, a
--     planter either side;
--   * two benches facing each other across the fountain (V3Assets "Bench", 2 working seats each);
--   * string lights between the six lamp posts: warm neon bulbs on a sagging wire (Beams, no parts);
--   * the TOSS PIT (the grab-and-throw spot, marked by its shape: a round sand pit with a padded rim)
--     on the way in, the MEET STAGE (a round stage, "Dance" prompt: Client/PlazaClient plays the
--     emote) in front of the leaderboards, and the PHOTO SPOT outside the entrance (a gold frame on a
--     step with the game's name; "Photo" prompt: PlazaClient frames you in it with the square behind).
-- Sounds (the fountain's water, an outdoor murmur) are played by each screen itself (PlazaClient).

local V3Assets = require(script.Parent:WaitForChild("V3Assets")) :: any

local TownSquare = {}

TownSquare.SEAT_R = 33 -- studs from the middle: the four seating groups
TownSquare.TREE_R = 43.5
TownSquare.BENCH_R = 19 -- the two benches facing each other across the fountain
TownSquare.PIT_AT = Vector3.new(0, 0, -27) -- from the middle: on the way in from the arrival
TownSquare.PIT_D = 18
TownSquare.STAGE_AT = Vector3.new(0, 0, 26) -- in front of the boards
TownSquare.STAGE_D = 11
TownSquare.PHOTO_AT = Vector3.new(-34, 0, -49) -- outside the entrance, on the grass
TownSquare.BULBS = 9 -- per span between two lamps
TownSquare.SAG = 2.4

export type Kit = {
	part: (parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, props: { [string]: any }?) -> Part,
	plant: (parent: Instance, at: Vector3) -> (),
	sign: (parent: Instance, text: string, cf: CFrame, size: Vector3, back: Color3, fore: Color3) -> (),
	ground: (at: Vector3) -> Vector3, -- the floor's top under a spot
}

local function model(parent: Instance, name: string, keepOut: number?): Model
	local m = Instance.new("Model")
	m.Name = name
	if keepOut then
		m:SetAttribute("KeepOut", keepOut)
	end
	m.Parent = parent
	return m
end

-- A flat round piece (a cylinder standing on its end), its top at `top`.
local function disc(kit: Kit, parent: Instance, name: string, at: Vector3, diameter: number, thick: number, top: number, color: Color3, material: Enum.Material, collide: boolean): Part
	return kit.part(parent, name, Vector3.new(thick, diameter, diameter), CFrame.new(at.X, top - thick / 2, at.Z) * CFrame.Angles(0, 0, math.rad(90)), color, material, {
		Shape = Enum.PartType.Cylinder,
		CanCollide = collide,
		CanQuery = collide,
		CanTouch = false,
		CastShadow = false,
	})
end

-- The four seating groups and the benches.
local function seating(kit: Kit, into: Instance, middle: Vector3)
	for _, deg in { 45, 135, 225, 315 } do
		local a = math.rad(deg)
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local group = model(into, "SeatGroup", 8)
		local at = kit.ground(middle + out * TownSquare.SEAT_R)
		local placed = V3Assets.place("PicnicSet", group, CFrame.lookAt(at, at - out), { size = 12.5, collide = true })
		if not placed then
			kit.part(group, "Table", Vector3.new(8, 0.4, 3.4), CFrame.lookAt(at, at - out) + Vector3.new(0, 3, 0), Color3.fromRGB(132, 92, 58), Enum.Material.WoodPlanks)
		end
		-- (Its shade tree behind it, outward: its crown over the table, its trunk off the walkway.)
		local treeAt = kit.ground(middle + out * TownSquare.TREE_R)
		V3Assets.place("TreeRound", group, CFrame.new(treeAt) * CFrame.Angles(0, a * 3, 0), { height = 17, collide = false, name = "ShadeTree" })
		local side = Vector3.new(-out.Z, 0, out.X)
		kit.plant(group, kit.ground(middle + out * (TownSquare.SEAT_R + 1) + side * 8.5))
		kit.plant(group, kit.ground(middle + out * (TownSquare.SEAT_R + 1) - side * 8.5))
	end
	-- Two benches facing each other across the fountain.
	for _, sx in { -1, 1 } do
		local at = kit.ground(middle + Vector3.new(sx * TownSquare.BENCH_R, 0, 0))
		local bench = model(into, "BenchPair", 3)
		V3Assets.place("Bench", bench, CFrame.lookAt(at, Vector3.new(middle.X, at.Y, middle.Z)), { size = 8.2, collide = true })
	end
end

-- Warm bulbs on a sagging wire between each lamp post and the next (round the square).
local function stringLights(kit: Kit, into: Instance, posts: { Vector3 })
	if #posts < 2 then
		return
	end
	local lights = model(into, "StringLights")
	-- (The wire is Beams between attachments on one invisible anchor: no parts for it.)
	local anchor = kit.part(lights, "WireAnchor", Vector3.new(1, 1, 1), CFrame.new(posts[1]), Color3.new(), Enum.Material.SmoothPlastic, {
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	local warm = Color3.fromRGB(255, 206, 140)
	for i, a in posts do
		local b = posts[i % #posts + 1]
		local last: Attachment? = nil
		for k = 0, TownSquare.BULBS + 1 do
			local t = k / (TownSquare.BULBS + 1)
			local p = a:Lerp(b, t) - Vector3.new(0, TownSquare.SAG * 4 * t * (1 - t), 0)
			local att = Instance.new("Attachment")
			att.Parent = anchor -- (parented first: WorldPosition is read against its part)
			att.WorldPosition = p
			if last then
				local wire = Instance.new("Beam")
				wire.Attachment0 = last
				wire.Attachment1 = att
				wire.Width0 = 0.07
				wire.Width1 = 0.07
				wire.FaceCamera = true
				wire.Color = ColorSequence.new(Color3.fromRGB(40, 36, 32))
				wire.LightInfluence = 1
				wire.Segments = 1
				wire.Parent = anchor
			end
			last = att
			if k > 0 and k <= TownSquare.BULBS then
				kit.part(lights, "Bulb", Vector3.new(0.55, 0.55, 0.55), CFrame.new(p - Vector3.new(0, 0.3, 0)), warm, Enum.Material.Neon, {
					Shape = Enum.PartType.Ball,
					CanCollide = false,
					CanQuery = false,
					CanTouch = false,
					CastShadow = false,
				})
			end
		end
	end
end

-- The TOSS PIT: a round sand pit with a padded rim, where thrown friends land.
local function tossPit(kit: Kit, into: Instance, middle: Vector3)
	local at = kit.ground(middle + TownSquare.PIT_AT)
	local pit = model(into, "TossPit", TownSquare.PIT_D / 2 + 1)
	disc(kit, pit, "TossPitSand", at, TownSquare.PIT_D, 0.3, at.Y + 0.2, Color3.fromRGB(212, 172, 112), Enum.Material.Sand, false)
	local pads = 16
	local r = TownSquare.PIT_D / 2 + 0.5
	for i = 0, pads - 1 do
		local a = (i + 0.5) / pads * math.pi * 2
		local p = at + Vector3.new(math.cos(a) * r, 0.35, math.sin(a) * r)
		local len = 2 * math.pi * r / pads - 0.25
		kit.part(pit, "TossPad", Vector3.new(len, 0.7, 1.1), CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a))) * CFrame.Angles(0, math.rad(90), 0), if i % 2 == 0 then Color3.fromRGB(255, 201, 60) else Color3.fromRGB(43, 47, 56), Enum.Material.SmoothPlastic, {
			CanCollide = true,
			CastShadow = false,
		})
	end
end

-- The MEET STAGE: a low round stage with a warm glowing edge; its "Dance" prompt plays the emote.
local function stage(kit: Kit, into: Instance, middle: Vector3)
	local at = kit.ground(middle + TownSquare.STAGE_AT)
	local m = model(into, "MeetStage", TownSquare.STAGE_D / 2 + 0.5)
	disc(kit, m, "StageGlow", at, TownSquare.STAGE_D + 0.6, 0.5, at.Y + 0.5, Color3.fromRGB(255, 170, 90), Enum.Material.Neon, true)
	local top = disc(kit, m, "StageTop", at, TownSquare.STAGE_D, 0.8, at.Y + 0.8, Color3.fromRGB(150, 104, 66), Enum.Material.WoodPlanks, true)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PlazaDance"
	prompt.ActionText = "Dance"
	prompt.ObjectText = "Meet stage"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = top
end

-- The PHOTO SPOT: a gold frame on a wooden step with the game's name over it, facing the way in.
local function photoSpot(kit: Kit, into: Instance, middle: Vector3)
	local at = kit.ground(middle + TownSquare.PHOTO_AT)
	local m = model(into, "PhotoSpot")
	local face = CFrame.lookAt(at, at - Vector3.new(0, 0, 1)) -- (its front to the south: the arrivals see it)
	local gold = Color3.fromRGB(240, 186, 64)
	local step = kit.part(m, "PhotoStep", Vector3.new(11, 1, 5), face * CFrame.new(0, 0.5, 0), Color3.fromRGB(136, 96, 62), Enum.Material.WoodPlanks, { CanCollide = true })
	for _, sx in { -1, 1 } do
		kit.part(m, "FramePost", Vector3.new(0.8, 8.4, 0.8), face * CFrame.new(sx * 5.1, 1 + 4.2, 0.6), gold, Enum.Material.Metal, { CanCollide = true })
	end
	kit.part(m, "FrameTop", Vector3.new(11, 0.8, 0.8), face * CFrame.new(0, 9.4, 0.6), gold, Enum.Material.Metal, { CanCollide = false })
	kit.sign(m, "RAGDOLL HAVOC", face * CFrame.new(0, 11.1, 0.6), Vector3.new(12, 2.4, 0.4), Color3.fromRGB(24, 28, 44), Color3.fromRGB(255, 140, 40))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PlazaPhoto"
	prompt.ActionText = "Take a photo"
	prompt.ObjectText = "Photo spot"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = step
	-- (Where PlazaClient's camera stands: in front of the frame, the square behind you.)
	m:SetAttribute("CameraAt", (face * CFrame.new(0, 5.5, -15)).Position)
	m:SetAttribute("LookAt", (face * CFrame.new(0, 4.5, 0)).Position)
end

-- Flower beds either side of the way in (V3Assets "FlowerBed"; planters where the place has none).
local function entranceFlowers(kit: Kit, into: Instance, middle: Vector3)
	for _, deg in { 252, 288 } do
		local a = math.rad(deg)
		local at = kit.ground(middle + Vector3.new(math.cos(a), 0, math.sin(a)) * 41)
		local bed = model(into, "EntranceBed", 4)
		if not V3Assets.place("FlowerBed", bed, CFrame.lookAt(at, Vector3.new(middle.X, at.Y, middle.Z)), { size = 8, collide = false }) then
			kit.plant(bed, at)
		end
	end
end

-- Builds the town square into `into` (PlazaDressing) round `middle` (the floor's top there);
-- `posts` are the lamp posts' tops, in order round the square.
function TownSquare.build(kit: Kit, into: Instance, middle: Vector3, posts: { Vector3 })
	seating(kit, into, middle)
	stringLights(kit, into, posts)
	tossPit(kit, into, middle)
	stage(kit, into, middle)
	photoSpot(kit, into, middle)
	entranceFlowers(kit, into, middle)
end

return TownSquare
