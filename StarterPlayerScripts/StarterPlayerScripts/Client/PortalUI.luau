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

local black: ScreenGui? = nil
local function going(kind: string)
	local text = if kind == "Solo" then "GOING BACK TO SOLO" elseif kind == "Own" then "GOING TO YOUR OWN SERVER" else "GOING TO MULTIPLAYER"
	if black then
		black:Destroy() -- (one black screen at a time)
	end
	local g = blackScreen(text)
	g.Parent = player:WaitForChild("PlayerGui")
	black = g
	pcall(function()
		TeleportService:SetTeleportGui(blackScreen(text))
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

local function build()
	local multi = C.Window({ name = "Servers", title = "Multiplayer", theme = "rebirth", icon = "friends", size = PortalUI.WINDOW })
	hereLabel = C.Text("caption", "", { wrap = true, autoY = true, layoutOrder = 0, parent = multi.body })
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
	C.Text("body", "A server just for you: your lab, your weapons, nobody else. Come back any time through MULTIPLAYER.", { wrap = true, autoY = true, layoutOrder = 2, parent = solo.body })
	local goSolo = C.Button({ text = "GO SOLO", role = "go", size = UDim2.new(1, 0, 0, Theme.Size.buttonH), layoutOrder = 3, parent = solo.body, onActivated = function()
		remote:FireServer("Solo")
	end })
	solo.defaultSelection = goSolo.hit
	Controller.register(solo)
end

function PortalUI.start()
	remote = Net.event(Net.Names.Portal)
	build()
	remote.OnClientEvent:Connect(function(kind: unknown, data: unknown)
		local d = if type(data) == "table" then data :: any else {}
		if kind == "Open" then
			if d.portal == "PortalSolo" then
				Controller.open("Solo")
			else
				Controller.open("Servers")
				remote:FireServer("List")
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
