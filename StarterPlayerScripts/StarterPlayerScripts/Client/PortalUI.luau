--!strict
-- Round 5, phase 4: what the lab's portals open (PortalService on the server).
--   MULTIPLAYER: the server list. EVERYONE: PLAY NOW (the fullest server with room) and the rows:
--   the server's fun name, its region, players x/10 and JOIN. FRIENDS ONLY: MAKE MY OWN (a private
--   server; friends join you through Roblox).
--   SINGLEPLAYER: GO SOLO (a server of your own).
-- Leaving shows a black screen ("GOING TO MULTIPLAYER" / "GOING BACK TO SOLO"), kept through the
-- teleport (TeleportService:SetTeleportGui).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))

local Toast = require(script.Parent:WaitForChild("Toast"))

local PortalUI = {}

PortalUI.WINDOW = Vector2.new(560, 520)
local SP = Theme.Space
local player = Players.LocalPlayer
local remote: RemoteEvent
local rowsFrame: Frame? = nil
local hereLabel: TextLabel? = nil
local friendsFrame: Frame? = nil

local function blackScreen(text: string): ScreenGui
	local g = Instance.new("ScreenGui")
	g.Name = "PortalBlack"
	g.IgnoreGuiInset = true
	g.DisplayOrder = 100
	g.ResetOnSpawn = false
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.Parent = g
	local l = Instance.new("TextLabel")
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, 0.5)
	l.Size = UDim2.new(0.8, 0, 0, 60)
	l.BackgroundTransparency = 1
	l.FontFace = Theme.Fonts.display
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Text = text
	l.Parent = f
	return g
end

-- (23 Nov 2026, owner: "GOING BACK TO SOLO comes up when you join"): the way on to your own server at a join is one
-- loading screen: the same look as ReplicatedFirst's FirstCover, here and through the teleport.
local function joinScreen(): ScreenGui
	local g = blackScreen("Hyper Ragdoll Physics")
	g.Name = "FirstCover"
	g.DisplayOrder = 200
	local f = g:FindFirstChildOfClass("Frame") :: Frame
	f.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
	local l = f:FindFirstChildOfClass("TextLabel") :: TextLabel
	l.Position = UDim2.fromScale(0.5, 0.45)
	l.TextColor3 = Color3.fromRGB(240, 240, 240)
	local sub = l:Clone()
	sub.AnchorPoint = Vector2.new(0.5, 0)
	sub.Position = UDim2.fromScale(0.5, 0.53)
	sub.Size = UDim2.new(0.6, 0, 0, 26)
	sub.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	sub.TextColor3 = Color3.fromRGB(190, 190, 200)
	sub.Text = "Loading..."
	sub.Parent = f
	return g
end

local black: ScreenGui? = nil
local function going(kind: string)
	local text = if kind == "Solo" then "GOING BACK TO SOLO" elseif kind == "Back" then "BACK TO SINGLEPLAYER" elseif kind == "Own" then "GOING TO YOUR OWN SERVER" else "GOING TO MULTIPLAYER"
	if black then
		black:Destroy() -- (one black screen at a time)
	end
	local join = kind == "Join"
	local g = if join then joinScreen() else blackScreen(text)
	g.Parent = player:WaitForChild("PlayerGui")
	black = g
	pcall(function()
		TeleportService:SetTeleportGui(if join then joinScreen() else blackScreen(text))
	end)
	Controller.closeAll()
	task.delay(12, function()
		g:Destroy() -- (a teleport that never happened: the screen goes again)
		if black == g then
			black = nil
		end
	end)
end

local function drawRows(rows: { any })
	local frame = rowsFrame
	if not frame then
		return
	end
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	if #rows == 0 then
		C.Text("body", "No other servers right now. PLAY NOW finds you one!", { wrap = true, autoY = true, layoutOrder = 1, parent = frame })
		return
	end
	for i, r in rows do
		local line = C.Row({ height = 48, gap = SP.sm, layoutOrder = i, parent = frame })
		C.Text("body", tostring(r.name), { size = UDim2.new(1, -230, 1, 0), layoutOrder = 1, parent = line })
		C.Text("caption", tostring(r.region), { size = UDim2.fromOffset(40, 48), layoutOrder = 2, parent = line })
		C.Text("body", string.format("%d/%d", tonumber(r.players) or 0, tonumber(r.max) or 10), { size = UDim2.fromOffset(56, 48), layoutOrder = 3, parent = line })
		local id = r.id
		C.Button({ text = "JOIN", role = "go", size = UDim2.fromOffset(100, 44), layoutOrder = 4, parent = line, onActivated = function()
			remote:FireServer("Join", id)
		end })
	end
end

-- Friends online in this game (Roblox's own list), each with JOIN (their server, through PortalService "Friend").
local function drawFriends()
	local frame = friendsFrame
	if not frame then
		return
	end
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local ok, list = pcall(function()
		return player:GetFriendsOnline(50)
	end)
	local shown = 0
	if ok and type(list) == "table" then
		for _, f in list :: any do
			if f.PlaceId == (if Config.MULTI_PLACE ~= 0 then Config.MULTI_PLACE else game.PlaceId) and type(f.GameId) == "string" and f.GameId ~= game.JobId then
				shown += 1
				local line = C.Row({ height = 48, gap = SP.sm, layoutOrder = shown, parent = frame })
				C.Text("body", tostring(f.DisplayName or f.UserName), { size = UDim2.new(1, -120, 1, 0), layoutOrder = 1, parent = line })
				local id = f.GameId
				C.Button({ text = "JOIN", role = "go", size = UDim2.fromOffset(100, 44), layoutOrder = 2, parent = line, onActivated = function()
					remote:FireServer("Friend", id)
				end })
			end
		end
	end
	if shown == 0 then
		C.Text("body", "No friends playing right now. Invite them from the Roblox menu!", { wrap = true, autoY = true, layoutOrder = 1, parent = frame })
	end
end

-- The multiplayer hub, opened by the start menu and the MULTIPLAYER portal.
function PortalUI.openHub()
	Controller.open("Servers")
	remote:FireServer("List")
	task.spawn(drawFriends)
end

local function build()
	local multi = C.Window({ name = "Servers", title = "Multiplayer", theme = "rebirth", icon = "friends", size = PortalUI.WINDOW })
	hereLabel = C.Text("caption", "", { wrap = true, autoY = true, layoutOrder = -10, parent = multi.body })
	-- (23 Nov 2026, owner: "multiplayer: see the servers, join your friends, make your own server"): the hub.
	-- FRIENDS: friends online in this game, JOIN.
	-- (23 Nov 2026, owner: "PLAY WITH EVERYONE HERE makes no sense": the list is the multiplayer servers only.)
	C.SectionHeader("FRIENDS", "rebirth", -7, multi.body)
	local friendsHolder = Instance.new("Frame")
	friendsHolder.Name = "Friends"
	friendsHolder.BackgroundTransparency = 1
	friendsHolder.Size = UDim2.fromScale(1, 0)
	friendsHolder.AutomaticSize = Enum.AutomaticSize.Y
	friendsHolder.LayoutOrder = -6
	local fl = Instance.new("UIListLayout")
	fl.Padding = UDim.new(0, SP.xs)
	fl.SortOrder = Enum.SortOrder.LayoutOrder
	fl.Parent = friendsHolder
	friendsHolder.Parent = multi.body
	friendsFrame = friendsHolder
	C.SectionHeader("EVERYONE", "rebirth", 1, multi.body)
	local play = C.Button({ text = "PLAY NOW", role = "go", size = UDim2.new(1, 0, 0, Theme.Size.buttonH), layoutOrder = 2, parent = multi.body, onActivated = function()
		remote:FireServer("PlayNow")
	end })
	local holder = Instance.new("Frame")
	holder.Name = "Rows"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.LayoutOrder = 3
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, SP.xs)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = holder
	holder.Parent = multi.body
	rowsFrame = holder
	C.SectionHeader("FRIENDS ONLY", "rebirth", 4, multi.body)
	C.Text("caption", "A server just for you. Your friends can join you from your Roblox profile.", { wrap = true, autoY = true, layoutOrder = 5, parent = multi.body })
	C.Button({ text = "MAKE MY OWN", role = "info", size = UDim2.new(1, 0, 0, Theme.Size.buttonH), layoutOrder = 6, parent = multi.body, onActivated = function()
		remote:FireServer("Own")
	end })
	multi.defaultSelection = play.hit
	Controller.register(multi)

	local solo = C.Window({ name = "Solo", title = "Singleplayer", theme = "daily", icon = "map", size = Vector2.new(440, 300) })
	C.Text("title", "Play on your own?", { scaled = true, size = UDim2.new(1, 0, 0, 32), layoutOrder = 1, parent = solo.body })
	C.Text("body", "Your own lab, your weapons, nobody else in it. Come back any time through MULTIPLAYER.", { wrap = true, autoY = true, layoutOrder = 2, parent = solo.body })
	local goSolo = C.Button({ text = "SINGLEPLAYER", role = "go", size = UDim2.new(1, 0, 0, Theme.Size.buttonH), layoutOrder = 3, parent = solo.body, onActivated = function()
		remote:FireServer("Solo")
	end })
	solo.defaultSelection = goSolo.hit
	Controller.register(solo)

	-- (V11 C10, owner: "multiplayer = everyone in one lab"): MULTIPLAYER's window: one button to the shared lab.
	local shared = C.Window({ name = "Shared", title = "Multiplayer", theme = "rebirth", icon = "friends", size = Vector2.new(440, 300) })
	C.Text("title", "Play together?", { scaled = true, size = UDim2.new(1, 0, 0, 32), layoutOrder = 1, parent = shared.body })
	C.Text("body", "A server where everyone shares ONE lab: the same ragdolls, the same machines. Come back any time through SINGLEPLAYER.", { wrap = true, autoY = true, layoutOrder = 2, parent = shared.body })
	local goShared = C.Button({ text = "PLAY TOGETHER", role = "go", size = UDim2.new(1, 0, 0, Theme.Size.buttonH), layoutOrder = 3, parent = shared.body, onActivated = function()
		remote:FireServer("Shared")
	end })
	shared.defaultSelection = goShared.hit
	Controller.register(shared)
end

function PortalUI.start()
	remote = Net.event(Net.Names.Portal)
	build()
	-- (Owner, 26 Nov 2026: "tænk mere ind i telefon": on a phone the HudV3 squares are not shown, so MULTIPLAYER is a
	-- launcher in the left stack under Shop and Menu there (HudMenu.PHONE_KEEP); it opens the hub with its list.)
	if Config.MP_ICON then
		Controller.addHudButton({ window = "Servers", label = "Multiplayer", icon = "friends", theme = "rebirth", layoutOrder = 8, onActivated = PortalUI.openHub })
	end
	remote.OnClientEvent:Connect(function(kind: unknown, data: unknown)
		local d = if type(data) == "table" then data :: any else {}
		if kind == "Open" then
			if d.portal == "PortalPlaces" then
				Controller.open("Maps") -- (V9-0e: the gold PLACES portal opens the places)
			elseif d.portal == "PortalSolo" then
				-- (23 Nov 2026, owner: "singleplayer: nobody else in your server"): to a server of your own.
				remote:FireServer("Solo")
			else
				-- (23 Nov 2026, owner: "choose servers in the portal as before"): the server list, with the lab here on top.
				PortalUI.openHub()
			end
		elseif kind == "List" then
			local here = d.here
			if hereLabel and type(here) == "table" then
				hereLabel.Text = string.format("You are in %s (%d/%d)%s", tostring(here.name), tonumber(here.players) or 0, tonumber(here.max) or 10, if d.solo then ". PLAY NOW takes you back to a shared server." else "")
			end
			drawRows(if type(d.rows) == "table" then d.rows else {})
		elseif kind == "Going" and type(d.kind) == "string" then
			going(d.kind)
		elseif kind == "Refused" and type(d.text) == "string" then
			-- (A failed teleport: the black screen goes at once, so the message is seen: review fix.)
			local b = black
			if b then
				b:Destroy()
				black = nil
			end
			Toast.show(d.text)
		end
	end)
end

return PortalUI
