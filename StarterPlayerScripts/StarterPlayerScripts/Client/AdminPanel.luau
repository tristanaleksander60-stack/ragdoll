--!strict
-- V6-2: the owner's admin menu as one clean window with tabs (Config.ADMIN_V2). Built only for the
-- owner (EventShop's "Hello" answer); every button sends a fixed choice over the Admin remote, and
-- AdminService checks on the server that it is the owner (AdminTools runs and logs it).
--   SERVER   events, all weapons, gravity, time of day, weather, announcements, the old menu
--   PLAYERS  pick a player: go to, bring, spectate, a free weapon try, kick with a fixed reason
--   WORLD    reset a lab, revive all, spawn dummies (row / ring / tower), crowd +/-, clear guests
--   DEBUG    this screen's and the server's frame rate, memory, parts, ragdolls, traffic, errors

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local LogService = game:GetService("LogService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Events = require(Shared:WaitForChild("Events")) :: any
local Toys = require(Shared:WaitForChild("Toys")) :: any
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents")) :: any
local Controller = require(UI:WaitForChild("LihFolkUIController")) :: any
local Theme = require(UI:WaitForChild("LihFolkUITheme")) :: any

local Client = script.Parent
local Toast = require(Client:WaitForChild("Toast")) :: any

local AdminPanel = {}

AdminPanel.NAME = "AdminV2"
AdminPanel.TABS = { "SERVER", "PLAYERS", "WORLD", "DEBUG" }
-- (The same fixed choices AdminTools accepts.)
AdminPanel.GRAVITY = { { "NORMAL", 196.2 }, { "LOW", 120 }, { "MOON", 60 }, { "SPACE", 25 } }
AdminPanel.CLOCK = { "Auto", "Morning", "Day", "Sunset", "Night" }
AdminPanel.WEATHER = { "Clear", "Rain", "Snow", "Fog" }
AdminPanel.ANNOUNCE = { { "HELLO", "Hello" }, { "EVENT SOON", "Event" }, { "PARTY", "Party" }, { "THANKS", "Thanks" }, { "RESTART", "Restart" } }
AdminPanel.KICK = { { "RUDE", "Rude" }, { "SPAM", "Spam" }, { "CHEATING", "Exploit" }, { "UPDATE", "Update" } }
AdminPanel.TRIALS = { "Minigun", "RPG", "Railgun", "GoldenDeagle", "Nuke", "GravityGun" }

local built = false
local remote: RemoteEvent? = nil
local target: number? = nil -- the picked player (PLAYERS / WORLD)
local playerList: { any } = {}
local adminList: { any } = {} -- (21 Nov: the admins the owner made, from the server's State)
local onPlayers: { () -> () } = {}
local serverDebug: { [string]: any } = {}
local clientErrors: { string } = {}

local function send(kind: string, arg: any?)
	if remote then
		remote:FireServer(kind, arg)
	end
end

local function page(parent: Instance, name: string, order: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromScale(1, 0)
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.LayoutOrder = order
	f.Parent = parent
	local l = Instance.new("UIListLayout")
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, Theme.Space.sm)
	l.Parent = f
	return f
end

local orderOf: { [Instance]: number } = {}
local function nextOrder(p: Instance): number
	orderOf[p] = (orderOf[p] or 0) + 1
	return orderOf[p]
end

local function header(p: Instance, text: string)
	C.SectionHeader(text, "settings", nextOrder(p), p)
end

local function caption(p: Instance, text: string): TextLabel
	local t = C.Text("caption", text, { color = Theme.Palette.textMid, wrap = true, size = UDim2.new(1, 0, 0, 0), layoutOrder = nextOrder(p), parent = p })
	t.AutomaticSize = Enum.AutomaticSize.Y
	return t
end

-- A grid of buttons, `perRow` a row.
local function grid(p: Instance, perRow: number): Frame
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromScale(1, 0)
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.LayoutOrder = nextOrder(p)
	f.Parent = p
	local layout = C.Grid(f, Vector2.new(100, Theme.Size.buttonH), Theme.Space.sm)
	layout.CellSize = UDim2.new(1 / perRow, -Theme.Space.sm, 0, Theme.Size.buttonH)
	return f
end

local function button(g: Instance, text: string, role: string, fn: () -> ()): any
	return C.Button({ text = text, role = role, size = UDim2.fromOffset(100, Theme.Size.buttonH), layoutOrder = nextOrder(g), parent = g, onActivated = fn })
end

local function needTarget(): number?
	if not target then
		Toast.show("Pick a player first (PLAYERS)")
	end
	return target
end

local function buildServer(p: Frame)
	header(p, "START AN EVENT (FREE, EVERYONE HERE)")
	local g = grid(p, 3)
	for _, e in Events.list do
		button(g, string.upper(e.name), "danger", function()
			send("Event", e.id)
		end)
	end
	header(p, "ALL WEAPONS FOR EVERYONE HERE")
	local w = grid(p, 2)
	button(w, "ON", "go", function()
		send("AllWeapons", true)
	end)
	button(w, "OFF", "neutral", function()
		send("AllWeapons", false)
	end)
	header(p, "GRAVITY")
	local gr = grid(p, 4)
	for _, it in AdminPanel.GRAVITY do
		button(gr, it[1], "neutral", function()
			send("Gravity", it[2])
		end)
	end
	header(p, "TIME OF DAY")
	local cl = grid(p, 5)
	for _, it in AdminPanel.CLOCK do
		button(cl, string.upper(it), "neutral", function()
			send("Clock", it)
		end)
	end
	header(p, "WEATHER")
	local we = grid(p, 4)
	for _, it in AdminPanel.WEATHER do
		button(we, string.upper(it), "neutral", function()
			send("Weather", it)
		end)
	end
	header(p, "ANNOUNCE TO EVERYONE HERE")
	local an = grid(p, 3)
	for _, it in AdminPanel.ANNOUNCE do
		button(an, it[1], "neutral", function()
			send("Announce", it[2])
		end)
	end
	header(p, "MORE")
	local more = grid(p, 1)
	button(more, "THEME, FREE PASSES AND TROLLS (OLD MENU)", "neutral", function()
		Controller.open("Admin")
	end)
end

local function buildPlayers(p: Frame)
	header(p, "PICK A PLAYER")
	local list = grid(p, 2)
	local buttons: { [number]: any } = {}
	local pickedLabel = caption(p, "Nobody picked")
	local function draw()
		local seen: { [number]: boolean } = {}
		for _, entry in playerList do
			local id = tonumber(entry.id)
			if id then
				seen[id] = true
				if not buttons[id] then
					local userId = id
					buttons[id] = button(list, tostring(entry.name), "neutral", function()
						target = userId
						for bid, b in buttons do
							b.setRole(if bid == target then "go" else "neutral")
						end
						local who = Players:GetPlayerByUserId(userId)
						pickedLabel.Text = "Picked: " .. (if who then who.DisplayName .. " (@" .. who.Name .. ")" else tostring(userId))
					end)
				end
			end
		end
		for id, b in buttons do
			if not seen[id] then
				b.root:Destroy()
				buttons[id] = nil
				if target == id then
					target = nil
					pickedLabel.Text = "Nobody picked"
				end
			end
		end
	end
	table.insert(onPlayers, draw)
	header(p, "MOVE")
	local mv = grid(p, 3)
	button(mv, "GO TO", "go", function()
		local t = needTarget()
		if t then
			send("Goto", t)
		end
	end)
	button(mv, "BRING", "go", function()
		local t = needTarget()
		if t then
			send("Bring", t)
		end
	end)
	button(mv, "SPECTATE", "go", function()
		local t = needTarget()
		local who = if t then Players:GetPlayerByUserId(t) else nil
		if who then
			Controller.closeAll()
			require(Client:WaitForChild("Spectate")).watch(who)
		end
	end)
	header(p, "FREE WEAPON TRY (2 MIN)")
	local tr = grid(p, 3)
	for _, id in AdminPanel.TRIALS do
		local toy = Toys.byId[id]
		if toy then
			button(tr, string.upper(toy.short or toy.label), "neutral", function()
				local t = needTarget()
				if t then
					send("Trial", { target = t, weapon = id })
				end
			end)
		end
	end
	-- (21 Nov 2026, the owner: give others the admin menu. Owner only; kept for every server. Admins
	-- get every tool here but never against the owner or another admin, and none of the owner's
	-- settings kept for every server.)
	if Players.LocalPlayer:GetAttribute("IsOwner") == true then
		header(p, "ADMINS (ONLY YOU CAN CHANGE THIS)")
		local ad = grid(p, 2)
		button(ad, "MAKE ADMIN", "go", function()
			local t = needTarget()
			if t then
				send("AdminSet", { target = t, on = true })
			end
		end)
		button(ad, "REMOVE ADMIN", "danger", function()
			local t = needTarget()
			if t then
				send("AdminSet", { target = t, on = false })
			end
		end)
		local adminsLine = caption(p, "Admins: none yet")
		table.insert(onPlayers, function()
			local names = {}
			for _, e in adminList do
				table.insert(names, tostring(e.name))
			end
			adminsLine.Text = "Admins: " .. (if #names > 0 then table.concat(names, ", ") else "none yet")
		end)
	end
	header(p, "KICK (THE REASON IS SHOWN TO THEM)")
	local kk = grid(p, 4)
	for _, it in AdminPanel.KICK do
		button(kk, it[1], "danger", function()
			local t = needTarget()
			if t then
				send("Kick", { target = t, reason = it[2] })
			end
		end)
	end
end

local function buildWorld(p: Frame)
	header(p, "LABS")
	local lb = grid(p, 2)
	button(lb, "RESET PICKED PLAYER'S LAB", "danger", function()
		local t = needTarget()
		if t then
			send("ResetLab", t)
		end
	end)
	button(lb, "RESET MY LAB", "danger", function()
		send("ResetLab", Players.LocalPlayer.UserId)
	end)
	header(p, "DUMMIES")
	local dm = grid(p, 2)
	button(dm, "REVIVE ALL", "go", function()
		send("ReviveAll")
	end)
	button(dm, "CLEAR SPAWNED", "neutral", function()
		send("ClearDummies")
	end)
	caption(p, "Spawn in front of you (guests: they never count as takedowns):")
	for _, shape in { "Row", "Ring", "Tower" } do
		local sg = grid(p, 3)
		for _, n in { 1, 5, 10 } do
			button(sg, string.format("%s x%d", string.upper(shape), n), "neutral", function()
				send("Spawn", { count = n, shape = shape })
			end)
		end
	end
	header(p, "CROWD WHERE YOU ARE")
	local cr = grid(p, 2)
	button(cr, "+5 PEOPLE", "neutral", function()
		send("Crowd", 5)
	end)
	button(cr, "-5 PEOPLE", "neutral", function()
		send("Crowd", -5)
	end)
end

local function buildDebug(p: Frame, isShown: () -> boolean)
	header(p, "THIS SCREEN")
	local mine = caption(p, "...")
	header(p, "THE SERVER")
	local server = caption(p, "...")
	header(p, "LAST ERRORS")
	local errs = caption(p, "none")
	local frames, t0, fps = 0, os.clock(), 60
	local parts, partsAt = 0, -math.huge
	RunService.RenderStepped:Connect(function()
		frames += 1
		local now = os.clock()
		if now - t0 >= 1 then
			fps = frames / (now - t0)
			frames, t0 = 0, now
		end
	end)
	task.spawn(function()
		while true do
			task.wait(2)
			if isShown() then
				send("Debug")
				-- (The part walk every 10 s only: no spike on the owner's screen each poll.)
				if os.clock() - partsAt > 10 then
					partsAt = os.clock()
					local n = 0
					for _, d in Workspace:GetDescendants() do
						if d:IsA("BasePart") then
							n += 1
						end
					end
					parts = n
				end
				local ping = math.floor(Players.LocalPlayer:GetNetworkPing() * 1000)
				mine.Text = string.format("%d fps   %d MB   %d parts streamed   ping %d ms", math.floor(fps + 0.5), math.floor(Stats:GetTotalMemoryUsageMb()), parts, ping)
				local s = serverDebug
				server.Text = if s.fps
					then string.format("%d fps   %d MB   %d parts   %d ragdolls   %d players   send %.1f / receive %.1f KB/s   v%s", s.fps, s.memory, s.parts, s.ragdolls, s.players, s.send, s.receive, tostring(s.version))
					else "waiting..."
				local lines = {}
				for _, e in (s.errors or {}) :: { string } do
					table.insert(lines, "server: " .. e)
				end
				for _, e in clientErrors do
					table.insert(lines, "client: " .. e)
				end
				errs.Text = if #lines > 0 then table.concat(lines, "\n") else "none"
			end
		end
	end)
end

function AdminPanel.build()
	if built then
		return
	end
	built = true
	remote = Net.event(Net.Names.Admin)
	LogService.MessageOut:Connect(function(message: string, kind: Enum.MessageType)
		if kind == Enum.MessageType.MessageError then
			table.insert(clientErrors, 1, string.sub(message, 1, 160))
			while #clientErrors > 4 do
				table.remove(clientErrors)
			end
		end
	end)
	local window = C.Window({ name = AdminPanel.NAME, title = "Admin", theme = "settings", icon = "crown", size = Vector2.new(620, 660) })
	-- The tab bar, then one page per tab (only the picked one shows).
	local bar = C.Row({ height = Theme.Size.buttonH, gap = Theme.Space.sm, layoutOrder = 0, parent = window.body })
	local pages: { [string]: Frame } = {}
	local tabs: { [string]: any } = {}
	local current = "SERVER"
	local function show(name: string)
		current = name
		for n, pg in pages do
			pg.Visible = n == name
		end
		for n, b in tabs do
			b.setRole(if n == name then "go" else "neutral")
		end
	end
	for i, name in AdminPanel.TABS do
		tabs[name] = C.Button({
			text = name,
			role = "neutral",
			size = UDim2.new(1 / #AdminPanel.TABS, -Theme.Space.sm, 0, Theme.Size.buttonH),
			layoutOrder = i,
			parent = bar,
			onActivated = function()
				show(name)
			end,
		})
		pages[name] = page(window.body, name, i)
	end
	buildServer(pages.SERVER)
	buildPlayers(pages.PLAYERS)
	buildWorld(pages.WORLD)
	buildDebug(pages.DEBUG, function()
		return current == "DEBUG" and Controller.isOpen(AdminPanel.NAME)
	end)
	show("SERVER")
	-- (Studio only: the player attribute "DevAdminTab" picks a tab, for the captures.)
	if RunService:IsStudio() then
		local lp = Players.LocalPlayer
		lp:GetAttributeChangedSignal("DevAdminTab"):Connect(function()
			local t = lp:GetAttribute("DevAdminTab")
			if type(t) == "string" and pages[t] then
				show(t)
			end
		end)
	end
	local r = remote :: RemoteEvent
	r.OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if kind == "State" and type(data) == "table" then
			playerList = (data :: any).players or {}
			adminList = (data :: any).admins or {}
			for _, fn in onPlayers do
				fn()
			end
		elseif kind == "Debug" and type(data) == "table" then
			serverDebug = data :: any
		end
	end)
	Controller.register(window)
	send("Hello")
end

return AdminPanel
