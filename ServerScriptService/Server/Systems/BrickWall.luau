--!strict
-- OVERVIEW 1d / DESTRUCTION 2b (owner, 26 Nov 2026: "smadre muren en mursten ad gangen ... lagfri ... følger gravity";
-- Config.BRICK_WALL): the crash wall (OwnerMap "CrashBrickWall") becomes a wall of bricks that breaks ONE BRICK AT A
-- TIME and falls with gravity, lag-free:
--   * HYBRID: the wall stands as a few big brick-material PANELS (PANEL_ROWS x PANEL_COLS bricks each). Only the panel
--     that is hit is swapped, in place, for its single bricks. A fresh wall is ~20 parts, not hundreds.
--   * HITS: a bullet cracks a brick (darker), a second knocks it out; a blast or a body/car faster than IMPACT studs/s
--     knocks out the bricks round the point (2-10 by force).
--   * GRAVITY: a brick stays up only if the cell under it is filled, or both side neighbours hold it (a mortar bridge).
--     Unsupported bricks come loose one after another (a trickle, CASCADE s apart), never the whole wall at once.
--   * CHEAP DEBRIS: loose bricks are physics parts; resting for 2 s they are anchored where they lie; at most
--     MAX_LOOSE move at once (the oldest resting goes first); they fade after FADE s.
--   * REBUILD: after REBUILD s with no hit, the wall rebuilds brick by brick from the bottom, then merges into panels.
-- The server decides everything. Hooked into Knockables' listeners (the shots and the blasts), like Breakables.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knockables = require(script.Parent:WaitForChild("Knockables"))

local BrickWall = {}

BrickWall.BW, BrickWall.BH, BrickWall.BD = 4, 2, 3 -- (a brick: along the wall, high, deep)
BrickWall.PANEL_ROWS, BrickWall.PANEL_COLS = 4, 5
BrickWall.IMPACT = 45
BrickWall.CASCADE = 0.07
BrickWall.MAX_LOOSE = 50
BrickWall.FADE = 30
BrickWall.REBUILD = 45

local BRICK = Color3.fromRGB(170, 78, 58)
local CRACKED = Color3.fromRGB(120, 56, 44)

type Cell = { state: string, part: BasePart?, hits: number, panel: number? } -- state: "panel" | "brick" | "gone"
type Wall = { origin: CFrame, rows: number, cols: number, cells: { { Cell } }, panels: { [number]: BasePart }, folder: Folder, lastHit: number, queue: { { number } }, rebuilding: boolean }

local walls: { Wall } = {}
local loose: { { part: BasePart, since: number, restAt: number? } } = {}

-- the cell's world CFrame (row 1 at the bottom, col 1 at the wall's start)
local function cellCF(w: Wall, r: number, c: number): CFrame
	return w.origin * CFrame.new(0, (r - 0.5) * BrickWall.BH, (c - 0.5) * BrickWall.BW)
end

local function newBrick(w: Wall, r: number, c: number): BasePart
	local p = Instance.new("Part")
	p.Name = "Brick"
	p.Anchored = true
	p.Size = Vector3.new(BrickWall.BD, BrickWall.BH - 0.04, BrickWall.BW - 0.06)
	p.CFrame = cellCF(w, r, c)
	local tone = (r * 7 + c * 13) % 5
	p.Color = BRICK:Lerp(Color3.fromRGB(150, 70, 52), tone / 8)
	p.Material = Enum.Material.Brick
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CastShadow = false
	p:SetAttribute("BrickR", r)
	p:SetAttribute("BrickC", c)
	p.Parent = w.folder
	return p
end

local function panelOf(w: Wall, r: number, c: number): number
	local pr = math.floor((r - 1) / BrickWall.PANEL_ROWS)
	local pc = math.floor((c - 1) / BrickWall.PANEL_COLS)
	return pr * 1000 + pc
end

local function makePanel(w: Wall, id: number)
	local pr, pc = math.floor(id / 1000), id % 1000
	local r0, c0 = pr * BrickWall.PANEL_ROWS + 1, pc * BrickWall.PANEL_COLS + 1
	local r1, c1 = math.min(w.rows, r0 + BrickWall.PANEL_ROWS - 1), math.min(w.cols, c0 + BrickWall.PANEL_COLS - 1)
	local a, b = cellCF(w, r0, c0), cellCF(w, r1, c1)
	local p = Instance.new("Part")
	p.Name = "BrickPanel"
	p.Anchored = true
	p.Size = Vector3.new(BrickWall.BD, (r1 - r0 + 1) * BrickWall.BH - 0.04, (c1 - c0 + 1) * BrickWall.BW - 0.06)
	p.CFrame = a:Lerp(b, 0.5)
	p.Color = BRICK
	p.Material = Enum.Material.Brick
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p:SetAttribute("PanelId", id)
	p.Parent = w.folder
	w.panels[id] = p
	for r = r0, r1 do
		for c = c0, c1 do
			w.cells[r][c] = { state = "panel", part = p, hits = 0, panel = id }
		end
	end
end

-- swap a panel for its single bricks, in place
local function split(w: Wall, id: number)
	local p = w.panels[id]
	if not p then
		return
	end
	w.panels[id] = nil
	for r = 1, w.rows do
		for c = 1, w.cols do
			local cell = w.cells[r][c]
			if cell.panel == id and cell.state == "panel" then
				w.cells[r][c] = { state = "brick", part = newBrick(w, r, c), hits = 0 }
			end
		end
	end
	p:Destroy()
end

local function filled(w: Wall, r: number, c: number): boolean
	if r < 1 then
		return true -- (the ground)
	end
	if c < 1 or c > w.cols or r > w.rows then
		return false
	end
	return w.cells[r][c].state ~= "gone"
end

local function trimLoose()
	-- over the cap: the oldest resting ones go first, then the oldest moving
	while #loose > BrickWall.MAX_LOOSE do
		local idx = 1
		for i, l in loose do
			if l.part.Anchored then
				idx = i
				break
			end
		end
		local l = table.remove(loose, idx)
		if l then
			l.part:Destroy()
		end
	end
end

local function knockOut(w: Wall, r: number, c: number, push: Vector3)
	local cell = w.cells[r][c]
	if cell.state == "gone" then
		return
	end
	if cell.state == "panel" and cell.panel then
		split(w, cell.panel)
		cell = w.cells[r][c]
	end
	local p = cell.part
	w.cells[r][c] = { state = "gone", hits = 0 }
	if p then
		p.Name = "LooseBrick"
		p.Anchored = false
		p.CanCollide = true
		p.AssemblyLinearVelocity = push + Vector3.new(math.random(-3, 3), math.random(0, 4), math.random(-3, 3))
		p.AssemblyAngularVelocity = Vector3.new(math.random(-6, 6), math.random(-6, 6), math.random(-6, 6))
		pcall(function()
			p:SetNetworkOwner(nil)
		end)
		table.insert(loose, { part = p, since = os.clock() })
		trimLoose()
	end
	-- whatever this held up may now fall: queue the cells above and beside
	for _, d in { { 1, 0 }, { 1, -1 }, { 1, 1 }, { 0, -1 }, { 0, 1 } } do
		table.insert(w.queue, { r + d[1], c + d[2] })
	end
end

local function supported(w: Wall, r: number, c: number): boolean
	if filled(w, r - 1, c) then
		return true
	end
	-- a mortar bridge: held from both sides, at most 2 bricks over a gap
	local left = filled(w, r, c - 1) and (filled(w, r - 1, c - 1) or filled(w, r, c - 2))
	local right = filled(w, r, c + 1) and (filled(w, r - 1, c + 1) or filled(w, r, c + 2))
	return left and right
end

local function cellAt(w: Wall, point: Vector3, slack: number?): (number?, number?)
	local l = w.origin:PointToObjectSpace(point)
	if math.abs(l.X) > BrickWall.BD + (slack or 0) then
		return nil, nil
	end
	local r = math.floor(l.Y / BrickWall.BH) + 1
	local c = math.floor(l.Z / BrickWall.BW) + 1
	if r < 1 or r > w.rows or c < 1 or c > w.cols then
		return nil, nil
	end
	return r, c
end

local function hitArea(w: Wall, point: Vector3, count: number, push: Vector3)
	local r0, c0 = cellAt(w, point, 6) -- (a body or a ball touching it: its middle is a few studs off the wall)
	if not r0 or not c0 then
		return
	end
	w.lastHit = os.clock()
	-- the nearest filled cells round the point
	local list = {}
	for r = math.max(1, r0 - 3), math.min(w.rows, r0 + 3) do
		for c = math.max(1, c0 - 3), math.min(w.cols, c0 + 3) do
			if w.cells[r][c].state ~= "gone" then
				table.insert(list, { r = r, c = c, d = (r - r0) ^ 2 + ((c - c0) * 2) ^ 2 })
			end
		end
	end
	table.sort(list, function(a, b)
		return a.d < b.d
	end)
	for i = 1, math.min(count, #list) do
		knockOut(w, list[i].r, list[i].c, push)
	end
end

local function shot(point: Vector3, from: Vector3)
	for _, w in walls do
		local r, c = cellAt(w, point)
		if r and c then
			w.lastHit = os.clock()
			local cell = w.cells[r][c]
			if cell.state == "panel" and cell.panel then
				split(w, cell.panel)
				cell = w.cells[r][c]
			end
			if cell.state == "brick" then
				cell.hits += 1
				if cell.hits >= 2 then
					local dir = point - from
					knockOut(w, r, c, (if dir.Magnitude > 0.01 then dir.Unit else Vector3.xAxis) * 28)
				elseif cell.part then
					cell.part.Color = CRACKED -- (cracked: one more and it goes)
				end
			end
			return
		end
	end
end

local function blast(center: Vector3, radius: number)
	for _, w in walls do
		local l = w.origin:PointToObjectSpace(center)
		if math.abs(l.X) < radius + BrickWall.BD then
			local n = math.clamp(math.floor(radius * 0.8), 3, 14)
			local nearest = w.origin * CFrame.new(0, math.clamp(l.Y, 0.1, w.rows * BrickWall.BH - 0.1), math.clamp(l.Z, 0.1, w.cols * BrickWall.BW - 0.1))
			hitArea(w, nearest.Position, n, (nearest.Position - center).Unit * 40)
		end
	end
end

local function build(src: BasePart, folder: Instance)
	-- the wall runs along the source part's longest horizontal side
	local along = if src.Size.Z >= src.Size.X then src.CFrame.LookVector else src.CFrame.RightVector
	local length = math.max(src.Size.X, src.Size.Z)
	local bottom = src.Position - Vector3.new(0, src.Size.Y / 2, 0)
	local start = bottom - along * (length / 2)
	-- origin: local Z along the wall, Y up, X through it
	local origin = CFrame.fromMatrix(start, Vector3.yAxis:Cross(along).Unit, Vector3.yAxis, along)
	local f = Instance.new("Folder")
	f.Name = "BrickWall"
	f.Parent = folder
	local w: Wall = { origin = origin, rows = math.floor(src.Size.Y / BrickWall.BH), cols = math.floor(length / BrickWall.BW), cells = {}, panels = {}, folder = f, lastHit = 0, queue = {}, rebuilding = false }
	for r = 1, w.rows do
		w.cells[r] = {}
	end
	for pr = 0, math.ceil(w.rows / BrickWall.PANEL_ROWS) - 1 do
		for pc = 0, math.ceil(w.cols / BrickWall.PANEL_COLS) - 1 do
			makePanel(w, pr * 1000 + pc)
		end
	end
	-- the old one-part wall and its cap go
	local cap = src.Parent and src.Parent:FindFirstChild("CrashBrickCap")
	if cap then
		cap:Destroy()
	end
	src:Destroy()
	-- bodies and cars crashing in
	local function onTouch(part: BasePart, other: BasePart)
		-- (Touched fires after the bump, when the speed is already about halved: judge the impact by that)
		local v = other.AssemblyLinearVelocity
		local model = other:FindFirstAncestorOfClass("Model")
		if model and game:GetService("Players"):GetPlayerFromCharacter(model) then
			return -- (a player running into it is not a crash)
		end
		if v.Magnitude > BrickWall.IMPACT * 0.45 and not other:IsDescendantOf(f) and not other.Anchored then
			local n = math.clamp(math.floor(v.Magnitude / 8) + 1, 2, 10)
			hitArea(w, other.Position, n, v * 0.4)
		end
	end
	f.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") and (d.Name == "Brick" or d.Name == "BrickPanel") then
			d.Touched:Connect(function(o)
				if d.Anchored then
					onTouch(d, o)
				end
			end)
		end
	end)
	for _, p in f:GetChildren() do
		if p:IsA("BasePart") then
			p.Touched:Connect(function(o)
				onTouch(p, o)
			end)
		end
	end
	table.insert(walls, w)
end

local function rebuild(w: Wall)
	w.rebuilding = true
	for _, l in loose do
		if l.part:IsDescendantOf(w.folder) then
			l.part:Destroy()
		end
	end
	for r = 1, w.rows do
		for c = 1, w.cols do
			local cell = w.cells[r][c]
			if cell.state == "gone" then
				w.cells[r][c] = { state = "brick", part = newBrick(w, r, c), hits = 0 }
				task.wait(0.02) -- (brick by brick, from the bottom)
			elseif cell.state == "brick" and cell.part then
				cell.hits = 0
				cell.part.Color = BRICK
			end
		end
	end
	-- merge back into panels
	for r = 1, w.rows do
		for c = 1, w.cols do
			local cell = w.cells[r][c]
			if cell.state == "brick" and cell.part then
				cell.part:Destroy()
				cell.part = nil
				cell.state = "panel"
				cell.panel = nil
			end
		end
	end
	for r = 1, w.rows do
		for c = 1, w.cols do
			local id = panelOf(w, r, c)
			if not w.panels[id] then
				makePanel(w, id)
			end
		end
	end
	w.lastHit = 0
	w.rebuilding = false
end

-- F48 (Config.CAR_WALL, owner: "Fiks så at muren reagerer hvis man kører ind i den med en bil, og den resetter efter 10-15
-- sekunder"): the driver's screen owns a driven car, so Touched on the server sees little speed. Every check (0.1 s) each
-- vehicle near a wall is measured by its own position change (works whoever owns it); a car inside a wall's slab at more
-- than CAR_SPEED studs/s is an impact: a car-sized hole, by speed x its weight class (6-20 bricks; the tank ploughs
-- through), the bricks pushed along the car's way; an empty car (the server owns it) also loses most of its speed.
BrickWall.CAR_SPEED = 18
BrickWall.CAR_CLASS = { Bike = 0.5, Car = 1, Truck = 1.4, Kart = 0.8, Jeep = 1.2, MuscleCar = 2.5 } :: { [string]: number }
local carSeen: { [any]: { at: Vector3, t: number, hitAt: number } } = setmetatable({}, { __mode = "k" }) :: any
local function carStep()
	local ok, VS = pcall(function()
		return require(script.Parent:WaitForChild("VehicleService")) :: any
	end)
	if not ok or not VS or #walls == 0 then
		return
	end
	local now = os.clock()
	for _, car in VS.carsForTest() do
		local body = car.body
		if not (body and body.Parent) then
			continue
		end
		local pos = body.Position
		local seen = carSeen[car]
		carSeen[car] = { at = pos, t = now, hitAt = if seen then seen.hitAt else 0 }
		if not seen or now - seen.t > 0.5 or now - seen.t <= 0 then
			continue
		end
		local vel = (pos - seen.at) / (now - seen.t)
		local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
		if speed < BrickWall.CAR_SPEED or now - seen.hitAt < 0.6 then
			continue
		end
		for _, w in walls do
			local l = w.origin:PointToObjectSpace(pos)
			local half = math.max(body.Size.X, body.Size.Z) / 2
			if math.abs(l.X) < 2 + half and l.Z > -half and l.Z < w.cols * BrickWall.BW + half and l.Y < w.rows * BrickWall.BH + 2 then
				local kind = tostring(car.kind)
				local class = BrickWall.CAR_CLASS[kind] or 1
				local n = math.clamp(math.floor(speed / 4 * class), 6, 20)
				local hitPoint = w.origin * Vector3.new(0, math.clamp(l.Y, 1, w.rows * BrickWall.BH - 1), math.clamp(l.Z, 0, w.cols * BrickWall.BW))
				hitArea(w, hitPoint, n, Vector3.new(vel.X, 2, vel.Z) * 0.5)
				carSeen[car].hitAt = now
				w.lastHit = now
				if kind ~= "MuscleCar" and car.seat and car.seat.Occupant == nil then
					pcall(function()
						body.AssemblyLinearVelocity = body.AssemblyLinearVelocity * 0.2
					end)
				end
				pcall(function()
					(require(script.Parent:WaitForChild("FxService")) :: any).hit(hitPoint, 60, "Punch")
				end)
				break
			end
		end
	end
end

local function tick()
	local now = os.clock()
	if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).CAR_WALL then
		pcall(carStep)
	end
	for _, w in walls do
		-- the cascade: one unsupported brick per step
		local guard = 0
		while #w.queue > 0 and guard < 40 do
			guard += 1
			local q = table.remove(w.queue, 1) :: { number }
			local r, c = q[1], q[2]
			if r >= 1 and r <= w.rows and c >= 1 and c <= w.cols and w.cells[r][c].state ~= "gone" and not supported(w, r, c) then
				knockOut(w, r, c, Vector3.new(0, -2, 0))
				break -- (one at a time: the next on the next step)
			end
		end
		if not w.rebuilding and w.lastHit > 0 and now - w.lastHit > BrickWall.REBUILD then
			task.spawn(rebuild, w)
		end
	end
	-- debris: rest, anchor, fade
	for i = #loose, 1, -1 do
		local l = loose[i]
		local p = l.part
		if not p.Parent then
			table.remove(loose, i)
		elseif now - l.since > BrickWall.FADE then
			p:Destroy()
			table.remove(loose, i)
		elseif not p.Anchored then
			if p.AssemblyLinearVelocity.Magnitude < 0.6 then
				l.restAt = l.restAt or now
				if now - (l.restAt :: number) > 2 then
					p.Anchored = true -- (resting: no more physics)
				end
			else
				l.restAt = nil
			end
		end
	end
end

function BrickWall.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.BRICK_WALL then
		return
	end
	if Config.CAR_WALL then
		BrickWall.REBUILD = 12 -- (F48: the wall rebuilds 10-15 s after it has fallen)
	end
	table.insert(Knockables.listeners, {
		shot = shot,
		blast = blast,
		reset = function(center: Vector3, radius: number)
			for _, w in walls do
				if (w.origin.Position - center).Magnitude < radius + 60 and not w.rebuilding then
					task.spawn(rebuild, w)
				end
			end
		end,
	})
	task.spawn(function()
		local last = 0
		while true do
			task.wait(BrickWall.CASCADE)
			tick()
			if os.clock() - last > 5 then
				last = os.clock()
				-- new labs: find their crash walls
				local root = Workspace:FindFirstChild("Playground")
				for _, lab in if root then root:GetChildren() else {} do
					local om = lab:FindFirstChild("OwnerMap")
					local src = om and om:FindFirstChild("CrashBrickWall")
					if src and src:IsA("BasePart") then
						pcall(build, src, om)
					end
				end
			end
		end
	end)
end

BrickWall.shotForTest = shot

return BrickWall
