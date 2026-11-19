--!strict
-- Friends on screen (phase G): the FRIENDS window (P key, HUD launcher, or MENU on a phone):
-- INVITE (Roblox's own invite sheet), the "friends can prank me" switch (players hit each other
-- only in the plaza, round 3: a line says so), whether the friend boost is on, a row for each
-- Roblox friend in this server with LET IN (your private lab, round 3), NUKE and PRANK (the time
-- left when a button rests), and friends playing in other servers with JOIN. When you are hit:
-- a toast with who and what; a nuke on its way also flashes a red banner with the countdown.
-- The server decides everything; this only asks and draws.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Keybinds = require(Shared:WaitForChild("Keybinds"))

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))

local Client = script.Parent
local Toast = require(Client:WaitForChild("Toast"))
local HudSlots = require(Client:WaitForChild("HudSlots"))

local player = Players.LocalPlayer
local P = Theme.Palette
local SP = Theme.Space
local ONLINE_EVERY = 30 -- s between friends-online lookups

local FriendsUI = {}

FriendsUI.BUTTON_W = 112 -- px: each friend row's buttons (LayoutCheck measures the lab button's words)
FriendsUI.BANNER = Vector2.new(300, 48) -- the nuke warning at its widest (narrower in a phone's toast box)

type Friend = { userId: number, name: string, pranks: boolean, invited: boolean? }
type State = { here: { Friend }, nukeIn: number, prankIn: number, pranks: boolean, boost: boolean }

local remote: RemoteEvent
local state: State = { here = {}, nukeIn = 0, prankIn = 0, pranks = true, boost = false }
local stateAt = os.clock()
local hereList: Frame? = nil
local elsewhereList: Frame? = nil
local boostLabel: TextLabel? = nil
local prankRow: any = nil
local rows: { [number]: { nuke: any, prank: any, lab: any, root: Frame } } = {}
local onlineAt = -math.huge
local banner: TextLabel? = nil

local function timeText(seconds: number): string
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function refreshButtons()
	local elapsed = math.floor(os.clock() - stateAt)
	local nukeLeft = math.max(0, state.nukeIn - elapsed)
	local prankLeft = math.max(0, state.prankIn - elapsed)
	for _, f in state.here do
		local row = rows[f.userId]
		if row then
			row.nuke.setEnabled(nukeLeft == 0 and f.pranks)
			row.nuke.setText(if not f.pranks then "OFF" elseif nukeLeft > 0 then timeText(nukeLeft) else "NUKE")
			row.prank.setEnabled(prankLeft == 0 and f.pranks)
			row.prank.setText(if not f.pranks then "OFF" elseif prankLeft > 0 then timeText(prankLeft) else "PRANK")
			row.lab.setText(if f.invited then "INVITED" else "LAB INVITE")
			row.lab.setRole(if f.invited then "done" else "go")
		end
	end
end

local function rebuildHere()
	local list = hereList
	if not list then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	rows = {}
	if #state.here == 0 then
		C.Text("caption", "No Roblox friends in this server yet. Invite some!", { color = P.textLow, wrap = true, size = UDim2.new(1, 0, 0, 36), parent = list })
	end
	for index, f in state.here do
		local row = Instance.new("Frame")
		row.Name = "Friend" .. f.userId
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 56)
		row.LayoutOrder = index
		local name = C.Text("body", f.name, { size = UDim2.new(1, -354, 1, 0), parent = row })
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextTruncate = Enum.TextTruncate.AtEnd
		local id = f.userId
		-- Your lab is private (round 3): LET IN lets this friend walk (or travel) into it; again to
		-- take it back.
		local labButton = C.Button({
			text = "LAB INVITE",
			role = "go",
			size = UDim2.fromOffset(FriendsUI.BUTTON_W, 52),
			anchor = Vector2.new(1, 0.5),
			position = UDim2.new(1, -240, 0.5, 0),
			parent = row,
			onActivated = function()
				remote:FireServer("LabInvite", id)
			end,
		})
		local nukeButton = C.Button({
			text = "NUKE",
			role = "danger",
			size = UDim2.fromOffset(FriendsUI.BUTTON_W, 52),
			anchor = Vector2.new(1, 0.5),
			position = UDim2.new(1, -120, 0.5, 0),
			parent = row,
			onActivated = function()
				remote:FireServer("Nuke", id)
			end,
		})
		local prankButton = C.Button({
			text = "PRANK",
			role = "info",
			size = UDim2.fromOffset(FriendsUI.BUTTON_W, 52),
			anchor = Vector2.new(1, 0.5),
			position = UDim2.new(1, 0, 0.5, 0),
			parent = row,
			onActivated = function()
				remote:FireServer("Prank", id)
			end,
		})
		row.Parent = list
		rows[id] = { nuke = nukeButton, prank = prankButton, lab = labButton, root = row }
	end
	refreshButtons()
end

local function redraw()
	if boostLabel then
		boostLabel.Text = if state.boost then "FRIEND BOOST ON: every 2nd takedown counts double" else "Play with a Roblox friend here for a takedown boost"
		boostLabel.TextColor3 = if state.boost then P.positive else P.textLow
	end
	if prankRow then
		prankRow.toggle.set(state.pranks, true)
	end
	rebuildHere()
end

-- Friends playing Ragdoll Lab in other servers (Roblox's own list), each with JOIN.
local function refreshElsewhere()
	local list = elsewhereList
	if not list or os.clock() - onlineAt < ONLINE_EVERY then
		return
	end
	onlineAt = os.clock()
	task.spawn(function()
		local ok, online = pcall(function()
			return player:GetFriendsOnline(50)
		end)
		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local count = 0
		if ok and type(online) == "table" then
			for _, f in online do
				local info = f :: any
				if info.PlaceId == game.PlaceId and info.GameId ~= game.JobId and type(info.VisitorId) == "number" then
					count += 1
					local row = Instance.new("Frame")
					row.BackgroundTransparency = 1
					row.Size = UDim2.new(1, 0, 0, 56)
					row.LayoutOrder = count
					-- (The name players see everywhere else: the display name, cut off with "..." if long.)
					local shown = tostring(info.DisplayName or info.UserName or "Friend")
					local name = C.Text("body", shown, { size = UDim2.new(1, -128, 1, 0), parent = row })
					name.TextXAlignment = Enum.TextXAlignment.Left
					local userId = info.VisitorId
					C.Button({
						text = "JOIN",
						role = "go",
						size = UDim2.fromOffset(FriendsUI.BUTTON_W, 52),
						anchor = Vector2.new(1, 0.5),
						position = UDim2.new(1, 0, 0.5, 0),
						parent = row,
						onActivated = function()
							remote:FireServer("Join", userId)
							Toast.show("Joining " .. shown .. "...")
						end,
					})
					row.Parent = list
				end
			end
		end
		if count == 0 then
			C.Text("caption", "No friends in other Ragdoll Havoc servers right now.", { color = P.textLow, wrap = true, size = UDim2.new(1, 0, 0, 36), parent = list })
		end
	end)
end

local function makeList(parent: Instance, order: number): Frame
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromScale(1, 0)
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.LayoutOrder = order
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, SP.sm)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = f
	f.Parent = parent
	return f
end

local function build()
	local window = C.Window({ name = "Friends", title = "Friends", theme = "rebirth", icon = "friends" })
	local invite = C.Button({
		text = "INVITE FRIENDS",
		role = "go",
		size = UDim2.new(1, 0, 0, Theme.Size.buttonH),
		layoutOrder = 1,
		parent = window.body,
		onActivated = function()
			local ok, can = pcall(function()
				return SocialService:CanSendGameInviteAsync(player)
			end)
			if ok and can then
				pcall(function()
					SocialService:PromptGameInvite(player)
				end)
			else
				Toast.show("Invites are not available here")
			end
		end,
	})
	boostLabel = C.Text("caption", "", { wrap = true, size = UDim2.new(1, 0, 0, 22), layoutOrder = 2, parent = window.body })
	C.SectionHeader("FRIENDS HERE", "rebirth", 3, window.body)
	hereList = makeList(window.body, 4)
	C.SectionHeader("IN OTHER SERVERS", "rebirth", 5, window.body)
	elsewhereList = makeList(window.body, 6)
	C.SectionHeader("SETTINGS", "rebirth", 7, window.body)
	-- (Hitting other players: only in the plaza, round 3. Nobody gets hurt there.)
	C.Text("caption", "Hit other players in the PLAZA only. Everyone there can, and nobody gets hurt.", {
		color = P.textMid,
		wrap = true,
		size = UDim2.new(1, 0, 0, 40),
		layoutOrder = 8,
		parent = window.body,
	})
	prankRow = C.SettingRow({
		label = "Friends can prank me",
		description = "Nukes and pranks from your Roblox friends",
		value = true,
		layoutOrder = 9,
		parent = window.body,
		onChanged = function(on)
			remote:FireServer("Pranks", on)
		end,
	})
	window.defaultSelection = invite.hit
	Controller.register(window)
	Controller.addHudButton({ window = "Friends", label = "Friends", icon = "friends", theme = "rebirth", layoutOrder = 6 })
	local openToken = 0
	Controller.onChanged(function(name, isOpen)
		if name == "Friends" and isOpen then
			refreshElsewhere()
			remote:FireServer("Hello")
			-- While it stays open, the other-servers list is asked again every ONLINE_EVERY s.
			openToken += 1
			local token = openToken
			task.spawn(function()
				while token == openToken and Controller.isOpen("Friends") do
					task.wait(ONLINE_EVERY + 0.1)
					if token == openToken and Controller.isOpen("Friends") then
						refreshElsewhere()
					end
				end
			end)
		elseif name == "Friends" then
			openToken += 1
		end
	end)

	-- The nuke warning: a red banner with the countdown.
	local gui = Instance.new("ScreenGui")
	gui.Name = "NukeWarning"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 35
	local b = Instance.new("TextLabel")
	b.AnchorPoint = Vector2.new(0.5, 0)
	b.Position = UDim2.new(0.5, 0, 0, 10)
	b.Size = UDim2.fromOffset(FriendsUI.BANNER.X, FriendsUI.BANNER.Y)
	b.BackgroundColor3 = Color3.fromRGB(220, 40, 50)
	b.FontFace = Theme.Fonts.display
	b.TextScaled = true -- a long name shrinks to fit, never spills
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 24
	limit.MinTextSize = 12
	limit.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = b
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = b
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = P.ink
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	b.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	banner = b
end

local function incoming(by: string, seconds: number)
	local b = banner
	if not b then
		return
	end
	if Toast.isHeld("card") then
		return -- (the first minute's view card has the middle of the screen: the nuke just lands)
	end
	local name = if #by > 14 then string.sub(by, 1, 13) .. "." else by
	if Toast.isRedirected() then
		-- A phone during a horde: no room under the bar, so the warning shows in the bar's points
		-- line like every other message.
		Toast.show(string.format("NUKE FROM %s in %d!", string.upper(name), math.ceil(seconds)))
		return
	end
	-- In the toasts' own place (toasts wait the few seconds): clear of everything else on any
	-- screen, under the horde's bar while one runs (LayoutCheck checks the "Nuke" box).
	local gui = b:FindFirstAncestorOfClass("ScreenGui")
	local screen = if gui then gui.AbsoluteSize else workspace.CurrentCamera.ViewportSize
	local centre, width = HudSlots.toastBox(screen, HudSlots.context(false, false))
	local w = math.min(FriendsUI.BANNER.X, width)
	b.Position = UDim2.fromOffset(centre, Toast.topY())
	Toast.hold("Nuke", true)
	b.Visible = true
	b.Size = UDim2.fromOffset(0, FriendsUI.BANNER.Y)
	TweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(w, FriendsUI.BANNER.Y) }):Play()
	for left = math.ceil(seconds), 1, -1 do
		b.Text = string.format("NUKE FROM %s  %d", string.upper(name), left)
		-- A shake each second, eased back.
		b.Rotation = if left % 2 == 0 then -3 else 3
		TweenService:Create(b, TweenInfo.new(0.5, Enum.EasingStyle.Elastic), { Rotation = 0 }):Play()
		task.wait(1)
	end
	b.Visible = false
	Toast.hold("Nuke", false)
end

function FriendsUI.start()
	remote = Net.event(Net.Names.Friends)
	build()
	remote.OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if type(data) ~= "table" then
			return
		end
		local d = data :: any
		if kind == "State" then
			state = {
				here = if type(d.here) == "table" then d.here else {},
				nukeIn = tonumber(d.nukeIn) or 0,
				prankIn = tonumber(d.prankIn) or 0,
				pranks = d.pranks ~= false,
				boost = d.boost == true,
			}
			stateAt = os.clock()
			redraw()
		elseif kind == "Hit" then
			Toast.show(if d.kind == "Nuke" then string.format("%s nuked you!", tostring(d.by)) else string.format("%s pranked you: %s!", tostring(d.by), tostring(d.kind)), Color3.fromRGB(255, 154, 205))
		elseif kind == "Incoming" then
			task.spawn(incoming, tostring(d.by), tonumber(d.seconds) or 3)
		elseif kind == "Sent" then
			Toast.show(if d.kind == "Nuke" then string.format("Nuke away! %s is going up.", tostring(d.to)) else string.format("Pranked %s: %s!", tostring(d.to), tostring(d.kind)))
		elseif kind == "Refused" and type(d.text) == "string" then
			Toast.show(d.text)
		elseif kind == "LabInvited" then
			Toast.show(string.format("%s let you into their lab! Find it in Places.", tostring(d.name)), Color3.fromRGB(120, 230, 140))
		end
	end)
	-- The resting buttons count down (texts only, once a second).
	task.spawn(function()
		while true do
			task.wait(1)
			if Controller.isOpen("Friends") then
				refreshButtons()
			end
		end
	end)
	-- The co-op horde (HordeService): told to everyone.
	Net.event(Net.Names.Horde).OnClientEvent:Connect(function(kind: unknown, data: unknown)
		local d = if type(data) == "table" then data :: any else {}
		if kind == "HordeWarning" then
			Toast.show(string.format("HORDE of %d at the Plaza in %d s! Open Places to go", tonumber(d.count) or 0, tonumber(d.seconds) or 10), Color3.fromRGB(255, 110, 110))
		elseif kind == "HordeCancelled" then
			Toast.show("No horde this time: the plaza is too full", Color3.fromRGB(255, 210, 74))
		elseif kind == "HordeEnd" then
			Toast.show(if d.cleared
				then string.format("Horde cleared! +%d takedowns for each helper", tonumber(d.bonus) or 0)
				else string.format("The horde is over: %d of %d down", tonumber(d.downed) or 0, tonumber(d.total) or 0), Color3.fromRGB(255, 210, 74))
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if Keybinds.live(processed) and input.UserInputType == Enum.UserInputType.Keyboard and Keybinds.is("Friends", input.KeyCode) then
			Controller.toggle("Friends")
		end
	end)
	remote:FireServer("Hello")
end

return FriendsUI
