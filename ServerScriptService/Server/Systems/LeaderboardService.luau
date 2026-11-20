--!strict
-- The plaza's four leaderboards (round 3, M6): MOST TAKEDOWNS, MOST TIME PLAYED, and the same two
-- for VIPs only. Each shows the top five with their avatar, gold, silver and bronze for the first
-- three, and says whether it is every server's (the real DataStores) or this server's.
--
-- Global: every BOARD_EVERY s each player here writes what changed (an OrderedDataStore per board;
-- a VIP board only takes VIPs; UpdateAsync keeps the larger) and the four tops are read back. What a player here has now is
-- merged on top, so your own number moves while you play and not just every 90 s. In a Studio
-- test run (no DataStores) the boards are this server's players.
--
-- The numbers come from ProgressService (takedowns are counted on the server; time played is the
-- server's clock while you are here), so nothing a client says reaches a board.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local UserService = game:GetService("UserService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local ProgressService = require(script.Parent.ProgressService)

local log = Log.new("Boards")

local LeaderboardService = {}

export type Row = { userId: number, name: string, value: number }
type Board = {
	id: string,
	title: string,
	store: string,
	vip: boolean,
	time: boolean, -- the value is seconds played (else takedowns)
}

LeaderboardService.BOARDS = {
	{ id = "Takedowns", title = "MOST TAKEDOWNS", store = "TakedownBoard_v1", vip = false, time = false },
	{ id = "Time", title = "MOST TIME PLAYED", store = "TimeBoard_v1", vip = false, time = true },
	{ id = "VipTakedowns", title = "VIP  TAKEDOWNS", store = "VipTakedownBoard_v1", vip = true, time = false },
	{ id = "VipTime", title = "VIP  TIME PLAYED", store = "VipTimeBoard_v1", vip = true, time = true },
} :: { Board }

local BOARD_EVERY = 60 -- s between global writes and reads (4 boards: well inside the budget)
local REDRAW_EVERY = 5 -- s at most between redraws of what changed here
local TOP = 5 -- (five big rows read from across the plaza on a phone; ten were 1.1 studs tall)
LeaderboardService.TOP = TOP
-- Where they stand: an arc on the plaza's far side (where the one board stood), facing its middle,
-- 3 studs behind the ring of lamps (47) and clear of the ones at 60 and 120 degrees (WorldMaps: the
-- plaza's middle and its dressing). 11 wide with 1.2 between them.
local PLAZA_MIDDLE = Vector3.new(0, 0, 85)
local RADIUS = 50
-- One even arc between the lamps at 60 and 120 (the fountain moved to the east side: WorldMaps).
local ANGLES = { 69, 83, 97, 111 } -- (left to right as you face them from the plaza)
local BOARD_SIZE = Vector3.new(11, 15, 0.6)
local PIXELS_PER_STUD = 28
local MEDALS = {
	Color3.fromRGB(255, 200, 61), -- gold
	Color3.fromRGB(206, 214, 224), -- silver
	Color3.fromRGB(214, 138, 78), -- bronze
}
local INK = Color3.fromRGB(22, 15, 43)
local PANEL = Color3.fromRGB(34, 28, 62)
local VIP_GOLD = Color3.fromRGB(255, 178, 36)

-- v4 D2 (owner: "the UI must not look AI-made"): with Config.UI_CLEAN the boards are calm wall
-- panels: a matte slate face, a warm off-white header with dark lettering, plain alternating rows,
-- the top three marked by a thin metal stripe (gold, silver, bronze; no glow), one body font, a
-- painted steel frame and a real lamp (no neon frame, no crown). Off = the round 5 look.
local CLEAN = (require(game:GetService("ReplicatedStorage").Shared.Config) :: any).UI_CLEAN == true
local STYLE = if CLEAN
	then {
		panel = Color3.fromRGB(33, 36, 41),
		head = Color3.fromRGB(238, 233, 222),
		headVip = Color3.fromRGB(226, 196, 120),
		headInk = Color3.fromRGB(28, 30, 34),
		row = Color3.fromRGB(43, 47, 54),
		rowAlt = Color3.fromRGB(38, 41, 47),
		face = Color3.fromRGB(56, 60, 68),
		text = Color3.fromRGB(236, 236, 232),
		muted = Color3.fromRGB(150, 156, 166),
		medals = { Color3.fromRGB(212, 175, 92), Color3.fromRGB(176, 182, 190), Color3.fromRGB(176, 120, 82) },
		font = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
		title = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold),
		frame = Color3.fromRGB(70, 73, 80),
		radius = 4,
	}
	else nil
LeaderboardService.STYLE = STYLE

local stores: { [string]: OrderedDataStore } = {}
local globalRows: { [string]: { Row } } = {}
local written: { [Player]: { [string]: number } } = {}
local names: { [number]: string } = {}
type View = { rows: { Frame }, sub: TextLabel, empty: TextLabel }
local views: { [string]: { View } } = {} -- (each board: the plaza's, and one in every lab)
local lastText: { [string]: string } = {}
local drawQueued = false

-- "2h 05m", "12m", "45s": time played as a board shows it.
function LeaderboardService.formatTime(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	if s >= 3600 then
		return string.format("%dh %02dm", s // 3600, (s % 3600) // 60)
	elseif s >= 60 then
		return string.format("%dm", s // 60)
	end
	return string.format("%ds", s)
end

local function isVip(player: Player): boolean
	return player:GetAttribute("VIP") == true
end

-- The ten a board shows: the global top with everyone here merged on top (their number now), best
-- first; ties keep the earlier name. Pure on its inputs (tests call it).
function LeaderboardService.merge(global: { Row }, here: { Row }): { Row }
	local byId: { [number]: Row } = {}
	local list: { Row } = {}
	for _, row in global do
		if not byId[row.userId] then
			local copy = table.clone(row)
			byId[row.userId] = copy
			table.insert(list, copy)
		end
	end
	for _, row in here do
		local seen = byId[row.userId]
		if seen then
			seen.value = math.max(seen.value, row.value)
			seen.name = row.name
		elseif row.value > 0 then
			local copy = table.clone(row)
			byId[row.userId] = copy
			table.insert(list, copy)
		end
	end
	table.sort(list, function(a, b)
		if a.value ~= b.value then
			return a.value > b.value
		end
		return a.name < b.name
	end)
	while #list > TOP do
		table.remove(list)
	end
	return list
end

local function hereRows(board: Board): { Row }
	local rows: { Row } = {}
	ProgressService.eachLoaded(function(player: Player, takedowns: number, seconds: number)
		if board.vip and not isVip(player) then
			return
		end
		table.insert(rows, { userId = player.UserId, name = player.DisplayName, value = if board.time then math.floor(seconds) else takedowns })
	end)
	return rows
end

function LeaderboardService.rowsOf(id: string): { Row }
	for _, board in LeaderboardService.BOARDS do
		if board.id == id then
			return LeaderboardService.merge(globalRows[id] or {}, hereRows(board))
		end
	end
	return {}
end

------------------------------------------------------------------------------------------------
-- Drawing

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function label(name: string, parent: Instance, props: { [string]: any }): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	if STYLE then
		t.FontFace = STYLE.font
	else
		t.Font = Enum.Font.FredokaOne
	end
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextScaled = true
	for key, value in props do
		(t :: any)[key] = value
	end
	t.Parent = parent
	return t
end

local function buildBoard(board: Board, cf: CFrame, folder: Instance, boardSize: Vector3?)
	local BOARD_SIZE = boardSize or BOARD_SIZE
	local model = Instance.new("Model")
	model.Name = "Board_" .. board.id
	local panel = Instance.new("Part")
	panel.Name = "Panel"
	panel.Anchored = true
	panel.Size = BOARD_SIZE
	panel.CFrame = cf
	panel.Color = if STYLE then STYLE.panel else PANEL
	panel.Material = Enum.Material.SmoothPlastic
	panel.Parent = model
	-- Two posts down to the floor (it stands, it does not float).
	local bottom = cf.Position.Y - BOARD_SIZE.Y / 2
	local hit = Workspace:Raycast(cf.Position, Vector3.new(0, -40, 0))
	local floorY = if hit then hit.Position.Y else bottom - 2
	local postH = math.max(0.5, bottom - floorY)
	for _, side in { -1, 1 } do
		local post = Instance.new("Part")
		post.Name = "Post"
		post.Anchored = true
		post.Size = Vector3.new(0.6, postH, 0.6)
		post.CFrame = cf * CFrame.new(side * (BOARD_SIZE.X / 2 - 1), -(BOARD_SIZE.Y / 2 + postH / 2), 0.4)
		post.Color = INK
		post.Material = Enum.Material.SmoothPlastic
		post.Parent = model
	end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Board"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.Parent = panel
	local w, h = BOARD_SIZE.X * PIXELS_PER_STUD, BOARD_SIZE.Y * PIXELS_PER_STUD
	local head = Instance.new("Frame")
	head.Name = "Head"
	head.Size = UDim2.fromOffset(w, 72)
	head.BackgroundColor3 = if STYLE then (if board.vip then STYLE.headVip else STYLE.head) elseif board.vip then VIP_GOLD else Color3.fromRGB(110, 86, 255)
	head.Parent = gui
	local title = label("Title", head, { Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 4), Text = board.title })
	if STYLE then
		title.FontFace = STYLE.title
		title.TextColor3 = STYLE.headInk
	end
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = if STYLE then 0 else 3
	stroke.Color = INK
	stroke.Parent = title
	local sub = label("Sub", head, { Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 48), Text = "", TextColor3 = INK })
	local rows: { Frame } = {}
	local top, gap = 80, 3
	local rowH = math.floor((h - top - 8) / TOP) - gap
	for i = 1, TOP do
		local row = Instance.new("Frame")
		row.Name = "Row" .. i
		row.Size = UDim2.fromOffset(w - 16, rowH)
		row.Position = UDim2.fromOffset(8, top + (i - 1) * (rowH + gap))
		row.BackgroundColor3 = if STYLE then (if i % 2 == 1 then STYLE.row else STYLE.rowAlt) else Color3.fromRGB(52, 44, 92)
		row.Visible = false
		corner(row, if STYLE then STYLE.radius else 10)
		if STYLE and STYLE.medals[i] then
			-- (The top three: a thin metal stripe down the left edge.)
			local stripe = Instance.new("Frame")
			stripe.Name = "Stripe"
			stripe.BorderSizePixel = 0
			stripe.Size = UDim2.new(0, 6, 1, 0)
			stripe.BackgroundColor3 = STYLE.medals[i]
			stripe.Parent = row
		end
		row.Parent = gui
		-- The face with a medal ring (gold, silver, bronze; plain after) and its place on a badge;
		-- the name gets most of the row (it is what people look for); the number on the right.
		local a = rowH - 10
		local face = Instance.new("ImageLabel")
		face.Name = "Avatar"
		face.Size = UDim2.fromOffset(a, a)
		face.AnchorPoint = Vector2.new(0, 0.5)
		face.Position = UDim2.new(0, 8, 0.5, 0)
		face.BackgroundColor3 = if STYLE then STYLE.face else Color3.fromRGB(76, 66, 128)
		corner(face, a // 2)
		local ring = Instance.new("UIStroke")
		ring.Thickness = if STYLE then 0 else 4
		ring.Color = MEDALS[i] or Color3.fromRGB(120, 110, 170)
		ring.Parent = face
		face.Parent = row
		local badge = Instance.new("Frame")
		badge.Name = "Medal"
		badge.Size = UDim2.fromOffset(22, 22)
		badge.AnchorPoint = Vector2.new(0.5, 0.5)
		badge.Position = UDim2.new(0, 8 + a - 4, 0, 8)
		badge.BackgroundColor3 = MEDALS[i] or Color3.fromRGB(120, 110, 170)
		badge.ZIndex = 3
		corner(badge, 11)
		badge.Parent = row
		badge.Visible = STYLE == nil -- (clean: the order and the stripes say the place)
		label("Rank", badge, { Size = UDim2.fromScale(1, 1), Text = tostring(i), ZIndex = 4, TextColor3 = if MEDALS[i] then INK else Color3.new(1, 1, 1) })
		local textH = math.floor(rowH * 0.72) -- (read from the plaza's middle on a phone too)
		local nameX = 8 + a + 10
		local scoreW = 70
		local name = label("PlayerName", row, { Size = UDim2.new(1, -(nameX + scoreW + 10), 0, textH), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, nameX, 0.5, 0), TextXAlignment = Enum.TextXAlignment.Left })
		local score = label("Score", row, { Size = UDim2.fromOffset(scoreW, textH), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = if STYLE then STYLE.text else (MEDALS[i] or Color3.new(1, 1, 1)) })
		for _, t in { name, score } do
			local cap = Instance.new("UITextSizeConstraint")
			cap.MaxTextSize = 44
			cap.Parent = t
		end
		rows[i] = row
	end
	local empty = label("Empty", gui, {
		Size = UDim2.fromOffset(w - 60, 80),
		Position = UDim2.fromOffset(30, h / 2 - 40),
		Text = if board.vip then "No VIPs here yet!" elseif board.time then "Nobody yet: just play!" else "Knock something down to get on the board!",
		TextColor3 = if STYLE then STYLE.muted else Color3.fromRGB(240, 236, 255),
		TextWrapped = true,
	})
	local list = views[board.id] or {}
	views[board.id] = list
	table.insert(list, { rows = rows, sub = sub, empty = empty })
	lastText[board.id] = nil -- (a new copy: drawn at the next redraw whatever changed)
	model.PrimaryPart = panel
	model.Parent = folder
	return model
end

local function draw()
	local global = next(stores) ~= nil
	for _, board in LeaderboardService.BOARDS do
		local list = views[board.id]
		if not list then
			continue
		end
		local rows = LeaderboardService.rowsOf(board.id)
		local text = {}
		for i, row in rows do
			table.insert(text, string.format("%d:%d:%s:%d", i, row.userId, row.name, row.value))
		end
		local key = table.concat(text, "|") .. (if global then "G" else "L")
		if lastText[board.id] == key then
			continue -- (nothing changed: no instance is touched)
		end
		lastText[board.id] = key
		for _, view in list do
			view.sub.Text = if global then "ALL SERVERS" else "THIS SERVER"
			view.empty.Visible = #rows == 0
			for i, frame in view.rows do
				local row = rows[i]
				frame.Visible = row ~= nil
				if row then
					(frame :: any).PlayerName.Text = row.name;
					(frame :: any).Score.Text = if board.time then LeaderboardService.formatTime(row.value) else tostring(row.value);
					(frame :: any).Avatar.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", row.userId)
				end
			end
		end
	end
end

-- A redraw half a second after a join or a leave (a burst of them draws once); numbers changing
-- while players play show at the next REDRAW_EVERY s tick. Either way only boards whose rows
-- changed are touched.
function LeaderboardService.redraw()
	if drawQueued then
		return
	end
	drawQueued = true
	task.delay(0.5, function()
		drawQueued = false
		draw()
	end)
end

------------------------------------------------------------------------------------------------
-- Global

local function nameOf(userId: number): string
	local cached = names[userId]
	if cached then
		return cached
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		names[userId] = player.DisplayName
		return player.DisplayName
	end
	-- (The display name, as a player here is shown: the same person reads the same either way.)
	local ok, infos = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync({ userId })
	end)
	local info = ok and type(infos) == "table" and (infos :: any)[1]
	if info and type(info.DisplayName) == "string" then
		names[userId] = info.DisplayName
		return info.DisplayName
	end
	return "Player"
end

-- Writes one player's numbers that changed since this server last wrote them, keeping the larger
-- of what is stored and theirs (two servers, or a stale one, never lower a board). Within budget:
-- at most one write per board per player per BOARD_EVERY, and once when they leave.
local function writeFor(player: Player)
	local mine = written[player] or {}
	written[player] = mine
	for _, board in LeaderboardService.BOARDS do
		local store = stores[board.id]
		if not store then
			continue
		end
		for _, row in hereRows(board) do
			if row.userId == player.UserId and row.value > 0 and mine[board.id] ~= row.value then
				local value = row.value
				local before = mine[board.id]
				mine[board.id] = value -- (marked first: a second call meanwhile never writes it again)
				local ok = pcall(function()
					store:UpdateAsync(tostring(row.userId), function(old: any)
						if type(old) == "number" and old >= value then
							return nil -- (already as high: nothing written)
						end
						return value
					end)
				end)
				if not ok and mine[board.id] == value then
					mine[board.id] = before -- (tried again at the next sync)
				end
			end
		end
	end
end

local function sync()
	for _, player in Players:GetPlayers() do
		writeFor(player)
	end
	-- Reads: the four tops.
	for _, board in LeaderboardService.BOARDS do
		local store = stores[board.id]
		if not store then
			continue
		end
		local ok, pages = pcall(function()
			return store:GetSortedAsync(false, TOP)
		end)
		if ok and pages then
			local rows: { Row } = {}
			for _, entry in (pages :: DataStorePages):GetCurrentPage() do
				local userId = tonumber(entry.key)
				if userId and type(entry.value) == "number" then
					table.insert(rows, { userId = userId, name = nameOf(userId), value = entry.value })
				end
			end
			globalRows[board.id] = rows
		end
	end
	draw()
end

------------------------------------------------------------------------------------------------

function LeaderboardService.textForTest(id: string): string
	draw()
	local view = views[id] and views[id][1]
	if not view then
		return ""
	end
	local lines = { view.sub.Text }
	for _, frame in view.rows do
		if frame.Visible then
			table.insert(lines, (frame :: any).PlayerName.Text .. " " .. (frame :: any).Score.Text .. " " .. (frame :: any).Avatar.Image)
		end
	end
	return table.concat(lines, "\n")
end

-- Every lab's own boards (10 Nov 2026, the owner: fine leaderboards by the lab you spawn in): MOST
-- TAKEDOWNS and MOST TIME PLAYED at the lab's far end, either side of the crash wall, facing the
-- spawn so they are the first thing seen; bigger than the plaza's, in a glowing frame with a gold
-- crown, lit from below. Inside the lab's folder (Workspace.Labs.LabN): a lab you may not enter
-- hides them with the rest of it (PlotPrivacy).
local LAB_BOARD = if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).LAYOUT_V3 then Vector3.new(20, 26, 0.6) else Vector3.new(14, 18, 0.6) -- (V9-0h: a board wall like the leader's)
local LAB_BOARD_IDS = { "Takedowns", "Time" }
local FRAME_GLOW = Color3.fromRGB(140, 110, 255)

local function trim(model: Model, cf: CFrame, size: Vector3, glow: Color3)
	local function bar(name: string, s: Vector3, at: CFrame, color: Color3, material: Enum.Material)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Size = s
		p.CFrame = at
		p.Color = color
		p.Material = material
		p.Parent = model
		return p
	end
	local w, h = size.X, size.Y
	-- The frame round the panel (clean: painted steel, no glow; then no crown).
	if STYLE then
		glow = STYLE.frame
	end
	local frameMaterial = if STYLE then Enum.Material.Metal else Enum.Material.Neon
	bar("Frame", Vector3.new(w + 1, 0.5, 0.8), cf * CFrame.new(0, h / 2 + 0.25, 0), glow, frameMaterial)
	bar("Frame", Vector3.new(w + 1, 0.5, 0.8), cf * CFrame.new(0, -h / 2 - 0.25, 0), glow, frameMaterial)
	bar("Frame", Vector3.new(0.5, h + 1, 0.8), cf * CFrame.new(w / 2 + 0.25, 0, 0), glow, frameMaterial)
	bar("Frame", Vector3.new(0.5, h + 1, 0.8), cf * CFrame.new(-w / 2 - 0.25, 0, 0), glow, frameMaterial)
	-- A gold crown on top: a band and three points (the round 5 look only).
	if not STYLE then
	local gold = Color3.fromRGB(255, 196, 46)
	bar("Crown", Vector3.new(5, 1, 0.8), cf * CFrame.new(0, h / 2 + 1.2, 0), gold, Enum.Material.Metal)
	for i = -1, 1 do
		local point = bar("CrownPoint", Vector3.new(1.1, 1.6, 0.8), cf * CFrame.new(i * 2, h / 2 + 2.3 + (if i == 0 then 0.4 else 0), 0) * CFrame.Angles(0, 0, math.rad(45)), gold, Enum.Material.Metal)
		point.Size = Vector3.new(1.2, 1.2, 0.8)
	end
	end
	-- Light from below, onto the face.
	local lampPart = bar("BoardLamp", Vector3.new(w, 0.4, 0.6), cf * CFrame.new(0, -h / 2 - 0.9, -1.4), Color3.fromRGB(30, 30, 40), Enum.Material.Metal)
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Top
	light.Angle = 70
	light.Range = 22
	light.Brightness = 2.2
	light.Color = Color3.fromRGB(255, 240, 220)
	light.Parent = lampPart
end

function LeaderboardService.buildLabBoards()
	local labs = Workspace:FindFirstChild("Labs")
	if not labs then
		return
	end
	for _, folder in labs:GetChildren() do
		local origin = folder:GetAttribute("Origin")
		if typeof(origin) ~= "Vector3" then
			continue
		end
		for i, id in LAB_BOARD_IDS do
			local board: Board? = nil
			for _, b in LeaderboardService.BOARDS do
				if b.id == id then
					board = b
				end
			end
			if not board then
				continue
			end
			local side = if i == 1 then -1 else 1
			local ground = origin.Y - 0.5
			local center = Vector3.new(origin.X + side * 34, ground + 4 + LAB_BOARD.Y / 2, origin.Z - 86)
			-- (Turned a little inwards, towards the spawn.)
			local cf = CFrame.lookAt(center, Vector3.new(origin.X, center.Y, origin.Z + 10))
			local model = buildBoard(board, cf, folder, LAB_BOARD)
			trim(model, cf, LAB_BOARD, if board.vip then VIP_GOLD else FRAME_GLOW)
		end
	end
	LeaderboardService.redraw()
end

function LeaderboardService.start(labOrigin: Vector3)
	if ProgressService.usesDataStores() then
		for _, board in LeaderboardService.BOARDS do
			local ok, store = pcall(function()
				return DataStoreService:GetOrderedDataStore(board.store)
			end)
			if ok and store then
				stores[board.id] = store
			end
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = "Boards"
	folder.Parent = Workspace
	local middle = labOrigin + PLAZA_MIDDLE
	for i, board in LeaderboardService.BOARDS do
		local a = math.rad(ANGLES[i])
		local at = middle + Vector3.new(math.cos(a), 0, math.sin(a)) * RADIUS
		local hit = Workspace:Raycast(at + Vector3.new(0, 40, 0), Vector3.new(0, -100, 0))
		local floorY = if hit then hit.Position.Y else middle.Y
		local center = Vector3.new(at.X, floorY + 3 + BOARD_SIZE.Y / 2, at.Z)
		buildBoard(board, CFrame.lookAt(center, Vector3.new(middle.X, center.Y, middle.Z)), folder)
	end
	ProgressService.boardsChanged = LeaderboardService.redraw
	-- Leaving: what changed since the last sync goes up now (not lost for up to BOARD_EVERY s); a
	-- closing server does the same for everyone still here.
	Players.PlayerRemoving:Connect(function(player)
		if next(stores) then
			pcall(writeFor, player)
		end
		-- (Kept a while: a server closing just now finds it written and does not write it again.)
		task.delay(60, function()
			if not player.Parent then
				written[player] = nil
			end
		end)
	end)
	game:BindToClose(function()
		if not next(stores) then
			return
		end
		-- Everyone's writes at once (not one after another), waited for within the close's time.
		local left = 0
		for _, player in Players:GetPlayers() do
			left += 1
			task.spawn(function()
				pcall(writeFor, player)
				left -= 1
			end)
		end
		local started = os.clock()
		while left > 0 and os.clock() - started < 20 do
			task.wait(0.1)
		end
	end)
	draw()
	task.spawn(function()
		while true do
			task.wait(REDRAW_EVERY)
			draw()
		end
	end)
	task.spawn(function()
		-- A new (or restarted) server reads every server's tops straight away, and once more soon
		-- after (a first read can be refused while the server starts): the boards are never empty
		-- for the first minute (10 Nov 2026, the owner: "Nobody yet" after a restart).
		-- (Round 5, "most time played" empty on a new server: read again every few seconds until
		-- every board has its rows, at most FIRST_TRIES times, then the usual pace.)
		task.wait(2)
		for _ = 1, 12 do
			if not next(stores) then
				break
			end
			local ok, err = pcall(sync)
			if not ok then
				log.warn("board first read failed: " .. tostring(err))
			end
			local all = ok
			for _, board in LeaderboardService.BOARDS do
				if globalRows[board.id] == nil then
					all = false
				end
			end
			if all then
				break
			end
			task.wait(5)
		end
		while true do
			task.wait(BOARD_EVERY)
			local ok, err = pcall(sync) -- (one bad answer from Roblox never ends the loop)
			if not ok then
				log.warn("board sync failed: " .. tostring(err))
			end
		end
	end)
	log.info("boards ready" .. (if next(stores) then " (global)" else " (this server)"))
end

return LeaderboardService
