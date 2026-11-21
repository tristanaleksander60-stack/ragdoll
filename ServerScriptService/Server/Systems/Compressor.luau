--!strict
-- V9-0m / Phase S (owner, 21 Nov 2026: "add a compressor that squashes ragdolls flat"; Config.COMPRESSOR):
-- a hydraulic press in every lab, with its own terminal (LabGuide.addTerminal: PRESS, spam queued up to
-- QUEUE, one press every COOLDOWN s; the lab's player or a party guest, within reach).
-- One press: the nearest free dummy is sent in an arc onto the plate; the PRESS lamp blinks, and the
-- plate slams down (the machine's PressAt, server time: every screen animates the plate, the THUD, the
-- dust, the camera punch and a SQUISH! sticker, Client/CompressorClient). Every body on the plate then is
-- knocked flat and marked Flat (server time) for FLAT_TIME s: every screen draws it as a cartoon pancake
-- (a flattened copy of its look; the body's physics never changes, no gore), and when the plate lifts it
-- pops back with a boing and walks off dizzy. A player standing on the plate is squashed the same way.
-- The plate itself is a picture (CanCollide off): nothing is ever stuck under it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any

local Compressor = {}

Compressor.AT = Vector2.new(-20, 35) -- lab x, z (on the hub's rim; V9-0n fine-tunes it)
Compressor.PLATE = 8 -- studs across the press bed
Compressor.HEIGHT = 13 -- studs from the bed to the top beam
Compressor.COOLDOWN = 2.5 -- s between two presses
Compressor.QUEUE = 3
Compressor.LAND_WAIT = 1.0 -- s for the tossed dummy to land on the bed
Compressor.SLAM_AFTER = 0.45 -- s from the lamp to the slam (the clients time the plate by it)
Compressor.FLAT_TIME = 2 -- s a body stays a pancake

local presses = 0
local machines: { Model } = {}

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, collide: boolean): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = collide
	p.CanQuery = collide
	p.CanTouch = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Bodies on the bed now: dummies (pelvis) and players (root) inside its square, near its top.
function Compressor.onBed(machine: Model): { Model }
	local bed = machine:FindFirstChild("Bed")
	if not (bed and bed:IsA("BasePart")) then
		return {}
	end
	local out: { Model } = {}
	local function check(model: Model, p: Instance?)
		if p and p:IsA("BasePart") then
			local rel = bed.CFrame:PointToObjectSpace(p.Position)
			local half = bed.Size / 2
			if math.abs(rel.X) < half.X + 0.5 and math.abs(rel.Z) < half.Z + 0.5 and rel.Y > -1 and rel.Y < 7 then
				table.insert(out, model)
			end
		end
	end
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		for _, m in dummies:GetChildren() do
			if m:IsA("Model") then
				check(m, m:FindFirstChild("LowerTorso"))
			end
		end
	end
	for _, plr in Players:GetPlayers() do
		local c = plr.Character
		if c then
			check(c, c:FindFirstChild("HumanoidRootPart"))
		end
	end
	return out
end

-- One press: a dummy onto the bed, the slam, the pancakes, the lift.
function Compressor.press(machine: Model, presser: Player?, owner: Player?)
	local bed = machine:WaitForChild("Bed") :: BasePart
	local top = bed.Position + Vector3.new(0, bed.Size.Y / 2 + 1.5, 0)
	if presser and owner then
		if #Compressor.onBed(machine) == 0 then
			lazy("LabGuide").toss(presser, owner, top)
			task.wait(Compressor.LAND_WAIT)
		end
	end
	machine:SetAttribute("PressAt", Workspace:GetServerTimeNow())
	task.wait(Compressor.SLAM_AFTER)
	local flatUntil = Workspace:GetServerTimeNow() + Compressor.FLAT_TIME
	local DummyControl = lazy("DummyControl")
	for _, m in Compressor.onBed(machine) do
		m:SetAttribute("Flat", flatUntil)
		if m:GetAttribute("IsDummy") == true then
			local pelvis = m:FindFirstChild("LowerTorso")
			if pelvis and pelvis:IsA("BasePart") then
				-- (Knocked flat on the bed: down and out cold a moment, never hurt.)
				local mass = (m:GetAttribute("Mass") :: number?) or 6.4
				pcall(DummyControl.hit, m, pelvis, Vector3.new(0, -40, 0) * mass, pelvis.Position, 40, nil)
			end
		end
		task.delay(Compressor.FLAT_TIME, function()
			if m.Parent and m:GetAttribute("Flat") == flatUntil then
				m:SetAttribute("Flat", nil)
			end
		end)
	end
	presses += 1
	local tally = (machine:GetAttribute("Pancakes") :: number?) or 0
	machine:SetAttribute("Pancakes", tally + 1)
	local screen = machine:FindFirstChild("PressScreen", true)
	if screen then
		screen:SetAttribute("Tally", "PANCAKE \u{00D7}" .. (tally + 1))
	end
end

-- The press in one lab (Playground builds the lab): the bed, four steel pillars with pistons, the top
-- beam, the press plate (a picture: the clients move it), the PRESS lamp, warning stripes, and the
-- terminal on the side you come from.
function Compressor.build(folder: Instance, origin: Vector3)
	if not Config.COMPRESSOR then
		return
	end
	local m = Instance.new("Model")
	m.Name = "Compressor"
	local base = origin + Vector3.new(Compressor.AT.X, 0, Compressor.AT.Y)
	local face = CFrame.lookAt(base, Vector3.new(origin.X, base.Y, origin.Z)) -- (its open side to the spawn)
	local steel = Color3.fromRGB(70, 76, 88)
	local dark = Color3.fromRGB(38, 42, 52)
	local yellow = Color3.fromRGB(255, 196, 40)
	local S = Compressor.PLATE
	part(m, "Footing", Vector3.new(S + 3, 0.6, S + 3), face * CFrame.new(0, 0.3, 0), dark, Enum.Material.DiamondPlate, true)
	local bed = part(m, "Bed", Vector3.new(S, 1, S), face * CFrame.new(0, 1.1, 0), Color3.fromRGB(110, 116, 128), Enum.Material.Metal, true)
	-- Warning stripes round the bed (yellow and black blocks).
	for i = -3, 3 do
		local c = if i % 2 == 0 then yellow else Color3.fromRGB(20, 20, 24)
		part(m, "Stripe", Vector3.new(S / 7, 0.12, 0.5), face * CFrame.new(i * S / 7, 1.66, -S / 2 - 0.1), c, Enum.Material.SmoothPlastic, false)
		part(m, "Stripe", Vector3.new(S / 7, 0.12, 0.5), face * CFrame.new(i * S / 7, 1.66, S / 2 + 0.1), c, Enum.Material.SmoothPlastic, false)
	end
	-- Four pillars with piston sleeves, and the top beam.
	local H = Compressor.HEIGHT
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x, z = sx * (S / 2 + 0.9), sz * (S / 2 + 0.9)
			part(m, "Pillar", Vector3.new(1.2, H, 1.2), face * CFrame.new(x, 1.6 + H / 2, z), steel, Enum.Material.Metal, true)
			part(m, "Sleeve", Vector3.new(1.7, 3, 1.7), face * CFrame.new(x, 1.6 + H - 2.2, z), yellow, Enum.Material.Metal, false)
		end
	end
	part(m, "TopBeam", Vector3.new(S + 3.4, 2, S + 3.4), face * CFrame.new(0, 1.6 + H + 1, 0), dark, Enum.Material.Metal, true)
	-- The main ram and the press plate (up; the clients drop it on PressAt).
	part(m, "Ram", Vector3.new(2.2, 4, 2.2), face * CFrame.new(0, 1.6 + H - 2, 0), Color3.fromRGB(200, 205, 215), Enum.Material.Metal, false)
	local plate = part(m, "Plate", Vector3.new(S - 0.4, 1.4, S - 0.4), face * CFrame.new(0, 1.6 + H - 4.7, 0), steel, Enum.Material.DiamondPlate, false)
	plate:SetAttribute("UpY", plate.Position.Y)
	plate:SetAttribute("DownY", bed.Position.Y + bed.Size.Y / 2 + 0.75)
	-- The PRESS lamp and sign on the beam.
	local lamp = part(m, "Lamp", Vector3.new(1.2, 1.2, 1.2), face * CFrame.new(S / 2, 1.6 + H + 2.6, -S / 2), Color3.fromRGB(255, 60, 40), Enum.Material.Neon, false)
	lamp.Shape = Enum.PartType.Ball
	local sign = part(m, "Sign", Vector3.new(6, 1.6, 0.2), face * CFrame.new(0, 1.6 + H + 1, -S / 2 - 1.75), dark, Enum.Material.Metal, false)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	t.TextScaled = true
	t.TextColor3 = yellow
	t.Text = "\u{1F95E} PRESS"
	t.Parent = gui
	gui.Parent = sign
	m:SetAttribute("Compressor", true)
	m.Parent = folder
	table.insert(machines, m)
	-- Its terminal (the same family as the feed terminals): PRESS, one every COOLDOWN s, QUEUE queued.
	pcall(function()
		local LabGuide = lazy("LabGuide")
		local guideFolder = folder:FindFirstChild("Guide") or folder
		local screen = LabGuide.addTerminal(guideFolder, origin, "Compressor", function(): Vector3
			return bed.Position + Vector3.new(0, 1.5, 0)
		end, { "Press", "Compressor", "" }, {
			action = function(term: any)
				local Lab = lazy("Lab")
				Compressor.press(m, term.presser, Lab.ownerAt(origin + Vector3.new(0, 1, 0)))
			end,
			every = Compressor.COOLDOWN,
			queueMax = Compressor.QUEUE,
			out = S / 2 + 5,
		})
		screen.Name = "PressScreen"
		screen:SetAttribute("Tally", "PANCAKE \u{00D7}0")
		local term = screen.Parent
		if term then
			term.Parent = m -- (it belongs to the press)
		end
	end)
end

-- Tests: how many presses ran, and the machines built.
function Compressor.pressesForTest(): number
	return presses
end
function Compressor.machinesForTest(): { Model }
	return machines
end

return Compressor
