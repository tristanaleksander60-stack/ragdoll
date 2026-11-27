--!strict
-- F88 RAGDOLL BOWLING, part 1 (owner: "vores bedste aspekt ... vores HOOK"; docs/BOWLING_12.md; Config.BOWLING): on the
-- plan's RagdollBowling spot by the spawn (Shared/OwnerMapPlan, lab-space), built from parts:
--   a glossy maple lane with dark wood edges, 7 aiming arrows and a red foul line, chrome gutters, a lighter approach;
--   10 GIANT pins (about 5 high: a white body and head with 2 red neck stripes) with real physics, a dark padded pit
--   and kickback walls; a low roof on slim posts with 2 warm lights; a retro scoreboard (bulbs round the edge) above
--   the pins; the big RED LEVER on the approach.
-- The game: pull the lever (a ProximityPrompt "Bowl!"): the nearest free ragdoll is put on the approach, curled, and
-- rolled down the lane (a real push; the server's physics). 4.5 s later the pins are counted: STRIKE / SPARE / SPLIT /
-- GUTTER / n pins on the board, a frame is 2 rolls (a strike ends it), then the pin-setter puts the 10 pins back.
-- The board shows your frame, YOUR BEST and TODAY'S BEST (the top 3 players' names this server, no free text).
-- 1 setup in 8 has a GOLDEN pin.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Bowling = {}

Bowling.ROLL_SPEED = 58 -- studs/s down the lane
Bowling.COUNT_AFTER = 4.5
Bowling.COOLDOWN = 7 -- s between two rolls on one lane

local MAPLE = Color3.fromRGB(214, 168, 112)
local DARK_WOOD = Color3.fromRGB(92, 58, 36)
local CHROME = Color3.fromRGB(196, 202, 212)
local PIN_WHITE = Color3.fromRGB(246, 244, 238)
local PIN_RED = Color3.fromRGB(205, 30, 40)
local GOLD = Color3.fromRGB(255, 196, 40)

type Lane = {
	pins: { Model },
	homes: { CFrame },
	board: TextLabel,
	word: TextLabel,
	at: Vector3, -- the approach (where the ball starts)
	dir: Vector3, -- down the lane
	deckAt: Vector3,
	busy: boolean,
	lastRoll: number,
	roll: number, -- 1 or 2 in the frame
	first: number, -- pins down in the frame's first roll
	golden: Model?,
}

local today: { [number]: { name: string, best: number } } = {}

local function part(into: Instance, name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?, anchored: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = anchored ~= false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = into
	return p
end

local function deco(p: BasePart)
	p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
end

-- One giant pin (about 5 high): a cylinder body, a ball belly and a ball head, 2 red neck stripes, welded; unanchored.
local function makePin(into: Instance, at: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "BowlingPin"
	local up = CFrame.Angles(0, 0, math.rad(90)) -- (a cylinder's axis is X)
	local props = PhysicalProperties.new(0.35, 0.35, 0.35, 1, 1) -- (light, a little bouncy: they fly and spin)
	local base = part(m, "Base", Vector3.new(2.4, 1.3, 1.3), at * CFrame.new(0, 1.2, 0) * up, PIN_WHITE, Enum.Material.SmoothPlastic, false)
	local belly = part(m, "Belly", Vector3.new(1.9, 1.9, 1.9), at * CFrame.new(0, 2.1, 0), PIN_WHITE, Enum.Material.SmoothPlastic, false)
	belly.Shape = Enum.PartType.Ball
	local neck = part(m, "Neck", Vector3.new(1.4, 0.8, 0.8), at * CFrame.new(0, 3.6, 0) * up, PIN_WHITE, Enum.Material.SmoothPlastic, false)
	local head = part(m, "Head", Vector3.new(1.15, 1.15, 1.15), at * CFrame.new(0, 4.5, 0), PIN_WHITE, Enum.Material.SmoothPlastic, false)
	head.Shape = Enum.PartType.Ball
	for i, y in { 3.35, 3.75 } do
		local s = part(m, "Stripe" .. i, Vector3.new(0.18, 0.86, 0.86), at * CFrame.new(0, y, 0) * up, PIN_RED, Enum.Material.SmoothPlastic, false)
		s.Shape = Enum.PartType.Cylinder
		deco(s)
	end
	base.Shape = Enum.PartType.Cylinder
	neck.Shape = Enum.PartType.Cylinder
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") then
			p.CustomPhysicalProperties = props
			p.Reflectance = 0.06
			if p ~= base then
				local w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = base, p
				w.Parent = p
			end
		end
	end
	m.PrimaryPart = base
	m.Parent = into
	return m
end

local function standing(pin: Model, home: CFrame): boolean
	local base = pin.PrimaryPart
	if not base then
		return false
	end
	local upY = base.CFrame.RightVector.Y -- (the base cylinder's axis is its X: up when standing)
	return math.abs(upY) > 0.8 and (base.Position - (home * CFrame.new(0, 1.2, 0)).Position).Magnitude < 2.2
end

local function resetPins(lane: Lane)
	lane.golden = nil
	local goldIdx = if math.random(1, 8) == 1 then math.random(1, #lane.pins) else 0
	for i, pin in lane.pins do
		for _, p in pin:GetChildren() do
			if p:IsA("BasePart") then
				p.AssemblyLinearVelocity = Vector3.zero
				p.AssemblyAngularVelocity = Vector3.zero
				if not string.match(p.Name, "^Stripe") then
					p.Color = if i == goldIdx then GOLD else PIN_WHITE
				end
			end
		end
		pin:PivotTo(lane.homes[i] * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)))
		if i == goldIdx then
			lane.golden = pin
		end
	end
end

local function showBoard(lane: Lane, by: Player?, word: string?)
	local me = by and today[by.UserId]
	local rows = {}
	for _, t in today do
		table.insert(rows, t)
	end
	table.sort(rows, function(a, b)
		return a.best > b.best
	end)
	local top = {}
	for i = 1, math.min(3, #rows) do
		table.insert(top, string.format("%d. %s  %d", i, rows[i].name, rows[i].best))
	end
	lane.board.Text = string.format("FRAME  roll %d\nYOUR BEST  %s\n\nTODAY'S BEST\n%s", lane.roll, if me then tostring(me.best) else "-", if #top > 0 then table.concat(top, "\n") else "be the first!")
	if word then
		lane.word.Text = word
		lane.word.TextTransparency = 0
		task.delay(2.2, function()
			if lane.word.Text == word then
				lane.word.TextTransparency = 1
			end
		end)
	end
end

local function freeRagdoll(near: Vector3): Model?
	local dummies = Workspace:FindFirstChild("Dummies")
	local best, bestD = nil :: Model?, 90
	for _, m in if dummies then dummies:GetChildren() else {} do
		local pe = m:FindFirstChild("LowerTorso")
		if m:IsA("Model") and pe and pe:IsA("BasePart") and m:GetAttribute("Vital") ~= "Dead" and m:GetAttribute("Held") ~= true
			and m:GetAttribute("InMachine") == nil and m:GetAttribute("Watch") == nil and m:GetAttribute("Bowling") == nil
			and m:GetAttribute("CommandedBy") == nil and m:GetAttribute("TryFor") == nil then
			local d = (pe.Position - near).Magnitude
			if d < bestD then
				best, bestD = m, d
			end
		end
	end
	return best
end

local function bowl(lane: Lane, by: Player)
	local now = os.clock()
	if lane.busy or now - lane.lastRoll < Bowling.COOLDOWN then
		return
	end
	local ball = freeRagdoll(lane.at)
	if not ball then
		lane.word.Text = "No ragdoll near!"
		lane.word.TextTransparency = 0
		task.delay(1.5, function()
			lane.word.TextTransparency = 1
		end)
		return
	end
	lane.busy = true
	lane.lastRoll = now
	ball:SetAttribute("Bowling", true)
	-- The ball: put on the approach, curled (a ragdoll on its side), then a real push down the lane.
	ball:PivotTo(CFrame.lookAt(lane.at + Vector3.new(0, 3, 0), lane.at + Vector3.new(0, 3, 0) + lane.dir) * CFrame.Angles(math.rad(-80), 0, 0))
	task.wait(0.15)
	local pelvis = ball:FindFirstChild("LowerTorso")
	if pelvis and pelvis:IsA("BasePart") then
		local mass = 0
		for _, p in ball:GetDescendants() do
			if p:IsA("BasePart") and not p.Massless then
				mass += p.Mass
			end
		end
		pcall(function()
			(require(script.Parent:WaitForChild("DummyControl")) :: any).hit(ball, pelvis, lane.dir * Bowling.ROLL_SPEED * math.max(mass, 1), pelvis.Position, Bowling.ROLL_SPEED + 10, by)
		end)
		for _, p in ball:GetDescendants() do
			if p:IsA("BasePart") then
				p.AssemblyAngularVelocity = lane.dir:Cross(Vector3.yAxis) * -9 -- (it rolls)
			end
		end
	end
	-- (T1 FTUE_10: a new player's FIRST roll is always a STRIKE: as the ball reaches the pins, every pin still up is
	-- knocked flying)
	local sure = by:GetAttribute("Tried_Bowling") ~= true and lane.roll == 1
		and (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).FTUE_10 == true
	by:SetAttribute("Tried_Bowling", true)
	if sure then
		task.delay(1.5, function()
			for i, pin in lane.pins do
				if standing(pin, lane.homes[i]) then
					local side = lane.dir:Cross(Vector3.yAxis) * (math.random() - 0.5) * 30
					for _, p in pin:GetChildren() do
						if p:IsA("BasePart") then
							p.AssemblyLinearVelocity = lane.dir * 26 + side + Vector3.new(0, 14, 0)
							p.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-8, 8), math.random(-8, 8))
						end
					end
				end
			end
		end)
	end
	task.wait(Bowling.COUNT_AFTER)
	ball:SetAttribute("Bowling", nil)
	local down = 0
	local goldDown = false
	for i, pin in lane.pins do
		if not standing(pin, lane.homes[i]) then
			down += 1
			if pin == lane.golden then
				goldDown = true
			end
		end
	end
	local word: string
	local frameDone = false
	local score = 0
	if lane.roll == 1 then
		if down >= 10 then
			word, frameDone, score = "STRIKE!", true, 30
		elseif down == 0 then
			word = "GUTTER..."
		else
			-- (a split: the front pin down, pins left standing on both sides)
			local left, right = false, false
			for i, pin in lane.pins do
				if standing(pin, lane.homes[i]) then
					local side = (lane.homes[i].Position - lane.deckAt):Dot(lane.dir:Cross(Vector3.yAxis))
					if side < -1 then
						left = true
					elseif side > 1 then
						right = true
					end
				end
			end
			word = if left and right and not standing(lane.pins[1], lane.homes[1]) then "SPLIT!" else string.format("%d PINS", down)
		end
		lane.first = down
		lane.roll = 2
	else
		local more = down - lane.first
		if down >= 10 then
			word, score = "SPARE!", 20
		elseif more <= 0 then
			word, score = "GUTTER...", down
		else
			word, score = string.format("+%d PINS", more), down
		end
		frameDone = true
	end
	if goldDown then
		word ..= "  GOLDEN PIN!"
	end
	pcall(function()
		(require(script.Parent:WaitForChild("FxService")) :: any).hit(lane.deckAt + Vector3.new(0, 3, 0), if down >= 10 then 90 else 30, "Bowling")
	end)
	if frameDone then
		local mine = today[by.UserId]
		if not mine then
			mine = { name = by.DisplayName, best = 0 }
			today[by.UserId] = mine
		end
		if score > mine.best then
			mine.best = score
			if score > 0 then
				word ..= "  NEW BEST!"
			end
		end
		lane.roll = 1
	end
	showBoard(lane, by, word)
	if frameDone then
		task.wait(1.2) -- (the pin-setter)
		resetPins(lane)
	end
	lane.busy = false
end

-- Builds the lane in a lab (the Playground calls this after the lab stands; origin = the lab floor's middle).
function Bowling.build(into: Instance, origin: Vector3)
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.BOWLING then
		return
	end
	local okPlan, Plan = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OwnerMapPlan")) :: any
	end)
	local it = okPlan and Plan and Plan.ITEMS and Plan.ITEMS.RagdollBowling
	if not it then
		return
	end
	local L, W = it.size.X, it.size.Y
	local mid = origin + Vector3.new(it.at.X, 0, it.at.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	-- lihfolk-ignore: findfirstchild-chain (only put in the filter list; a missing folder just filters nothing)
	params.FilterDescendantsInstances = { Workspace:FindFirstChild("Dummies") :: Instance }
	local hit = Workspace:Raycast(mid + Vector3.new(0, 60, 0), Vector3.new(0, -140, 0), params)
	local y = if hit then hit.Position.Y else origin.Y + 0.5
	local f = Instance.new("Model")
	f.Name = "RagdollBowling"
	f.Parent = into
	-- The lane runs along X: the pins at the west end (-X), the approach at the east end (+X), so it faces east.
	local dir = Vector3.new(-1, 0, 0)
	local laneW = math.min(8, W - 4)
	local top = y + 0.6
	local function at(x: number, z: number, h: number): CFrame
		return CFrame.new(mid.X + x, top + h, mid.Z + z)
	end
	part(f, "Bed", Vector3.new(L, 0.6, W), at(0, 0, -0.3), DARK_WOOD, Enum.Material.Wood)
	local lane = part(f, "Lane", Vector3.new(L - 10, 0.2, laneW), at(-1, 0, 0.1), MAPLE, Enum.Material.SmoothPlastic)
	lane.Reflectance = 0.12
	for _, s in { -1, 1 } do
		part(f, "Edge", Vector3.new(L - 10, 0.3, 0.35), at(-1, s * (laneW / 2 + 0.17), 0.15), DARK_WOOD, Enum.Material.Wood)
		local g = part(f, "Gutter", Vector3.new(L - 10, 0.8, 1.3), at(-1, s * (laneW / 2 + 1), -0.15), CHROME, Enum.Material.Metal)
		g.Shape = Enum.PartType.Cylinder
		g.CFrame = at(-1, s * (laneW / 2 + 1), -0.35)
		g.Size = Vector3.new(L - 10, 1.3, 1.3)
	end
	for k = -3, 3 do -- the 7 aiming arrows
		local a = part(f, "Arrow", Vector3.new(1.2, 0.05, 0.35), at(L / 2 - 14 - math.abs(k) * 0.9, k * laneW / 8, 0.22), DARK_WOOD)
		a.CFrame = a.CFrame * CFrame.Angles(0, math.rad(45), 0)
		deco(a)
	end
	deco(part(f, "FoulLine", Vector3.new(0.25, 0.05, laneW), at(L / 2 - 6, 0, 0.22), PIN_RED, Enum.Material.Neon))
	part(f, "Approach", Vector3.new(6, 0.25, W - 2), at(L / 2 - 3, 0, 0.12), Color3.fromRGB(232, 196, 146), Enum.Material.Wood)
	-- The pit and kickbacks at the west end.
	part(f, "Pit", Vector3.new(3, 0.4, W), at(-L / 2 + 1.5, 0, -0.8), Color3.fromRGB(30, 30, 36), Enum.Material.Fabric)
	part(f, "Cushion", Vector3.new(1, 6, W), at(-L / 2 + 0.5, 0, 3), Color3.fromRGB(26, 26, 34), Enum.Material.Fabric)
	for _, s in { -1, 1 } do
		local kb = part(f, "Kickback", Vector3.new(12, 6, 0.6), at(-L / 2 + 7, s * (W / 2 - 0.3), 3), Color3.fromRGB(40, 44, 70), Enum.Material.SmoothPlastic)
		deco(part(f, "Stripe", Vector3.new(12, 0.6, 0.1), at(-L / 2 + 7, s * (W / 2 - 0.62), 4.4), Color3.fromRGB(255, 120, 40), Enum.Material.Neon))
		local _ = kb
	end
	-- The roof on slim posts, with 2 warm lights.
	for _, x in { -L / 2 + 2, L / 2 - 2 } do
		for _, s in { -1, 1 } do
			part(f, "Post", Vector3.new(0.6, 12, 0.6), at(x, s * (W / 2 - 0.3), 6), CHROME, Enum.Material.Metal)
		end
	end
	local roof = part(f, "Roof", Vector3.new(L + 1, 0.6, W + 1), at(0, 0, 12.3), Color3.fromRGB(150, 40, 50), Enum.Material.SmoothPlastic)
	for _, x in { -L / 4, L / 4 } do
		local a = Instance.new("Attachment")
		a.Position = Vector3.new(x, -1, 0)
		a.Parent = roof
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 214, 160)
		light.Range = 22
		light.Brightness = 1.6
		light.Shadows = false
		light.Parent = a
	end
	-- The scoreboard above the pins, facing the approach.
	local boardPart = part(f, "Scoreboard", Vector3.new(0.6, 6, 10), at(-L / 2 + 9, 0, 9), Color3.fromRGB(20, 20, 28), Enum.Material.SmoothPlastic)
	deco(boardPart)
	for k = 0, 15 do -- the bulbs round the edge
		local t = k / 16
		local zz = -5 + 10 * t
		for _, yy in { 3.1, -3.1 } do
			local b = part(f, "Bulb", Vector3.new(0.3, 0.3, 0.3), at(-L / 2 + 9.35, zz, 9 + yy), Color3.fromRGB(255, 220, 120), Enum.Material.Neon)
			b.Shape = Enum.PartType.Ball
			deco(b)
			b:SetAttribute("Idx", k)
			game:GetService("CollectionService"):AddTag(b, "Chase")
		end
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right -- (+X: toward the approach)
	gui.CanvasSize = Vector2.new(500, 300)
	gui.MaxDistance = 140
	gui.LightInfluence = 0
	gui.Parent = boardPart
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.2)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 196, 60)
	title.Text = "RAGDOLL BOWLING"
	title.Parent = gui
	local board = Instance.new("TextLabel")
	board.Size = UDim2.fromScale(0.94, 0.62)
	board.Position = UDim2.fromScale(0.03, 0.22)
	board.BackgroundTransparency = 1
	board.Font = Enum.Font.GothamBold
	board.TextScaled = true
	board.TextColor3 = Color3.fromRGB(235, 240, 255)
	board.TextXAlignment = Enum.TextXAlignment.Left
	board.Parent = gui
	local word = Instance.new("TextLabel")
	word.Size = UDim2.fromScale(1, 0.16)
	word.Position = UDim2.fromScale(0, 0.84)
	word.BackgroundTransparency = 1
	word.Font = Enum.Font.FredokaOne
	word.TextScaled = true
	word.TextColor3 = Color3.fromRGB(255, 90, 120)
	word.TextTransparency = 1
	word.Text = ""
	word.Parent = gui
	-- The 10 pins in their triangle at the west end (the head pin nearest the approach).
	local pinsFolder = Instance.new("Folder")
	pinsFolder.Name = "Pins"
	pinsFolder.Parent = f
	local deckX = -L / 2 + 9
	local homes: { CFrame } = {}
	local gap = 2.3
	for row = 0, 3 do
		for k = 0, row do
			local x = deckX - row * gap * 0.87
			local z = (k - row / 2) * gap
			table.insert(homes, at(x, z, 0.2))
		end
	end
	local pins: { Model } = {}
	for _, h in homes do
		table.insert(pins, makePin(pinsFolder, h))
	end
	-- The red lever on the approach.
	local leverBase = part(f, "LeverBase", Vector3.new(1.2, 1.2, 1.2), at(L / 2 - 2, W / 2 - 2, 0.6), Color3.fromRGB(40, 40, 46), Enum.Material.Metal)
	local stick = part(f, "Lever", Vector3.new(0.3, 3, 0.3), at(L / 2 - 2, W / 2 - 2, 2.4) * CFrame.Angles(0, 0, math.rad(-20)), PIN_RED, Enum.Material.SmoothPlastic)
	local knob = part(f, "Knob", Vector3.new(0.9, 0.9, 0.9), stick.CFrame * CFrame.new(0, 1.6, 0), PIN_RED, Enum.Material.SmoothPlastic)
	knob.Shape = Enum.PartType.Ball
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Bowl!"
	prompt.ObjectText = "Ragdoll Bowling"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = leverBase
	local laneState: Lane = {
		pins = pins,
		homes = homes,
		board = board,
		word = word,
		at = at(L / 2 - 4, 0, 0).Position,
		dir = dir,
		deckAt = at(deckX, 0, 0).Position,
		busy = false,
		lastRoll = -math.huge,
		roll = 1,
		first = 0,
		golden = nil,
	}
	resetPins(laneState)
	showBoard(laneState, nil, nil)
	prompt.Triggered:Connect(function(player: Player)
		if not player:IsA("Player") then
			return
		end
		task.spawn(bowl, laneState, player)
	end)
	local _ = Players
end

return Bowling
