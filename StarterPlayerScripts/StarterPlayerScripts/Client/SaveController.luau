--!strict
-- "My builds": three save slots, a share code for the current build, and loading a friend's build by
-- its code. Phone first: one centred card, thumb-sized buttons, and every destructive tap (saving
-- over a slot, replacing the build on the table, starting over) asks "Sure?" on the same button
-- instead of opening another dialog. There is no free text anywhere: the only thing a player can
-- type is a code, and the box only accepts code characters.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local ShareCode = require(Shared:WaitForChild("Build"):WaitForChild("ShareCode"))

local Client = script.Parent
local Toast = require(Client:WaitForChild("Toast"))

local player = Players.LocalPlayer

local SaveController = {}

local SLOTS = 3
local CONFIRM_TIME = 3
local DARK = Color3.fromRGB(32, 32, 40)
local IDLE = Color3.fromRGB(52, 52, 64)
local ACCENT = Color3.fromRGB(255, 205, 60)
local GREEN = Color3.fromRGB(120, 230, 140)
local BLUE = Color3.fromRGB(80, 170, 255)
local RED = Color3.fromRGB(255, 90, 70)
local MUTED = Color3.fromRGB(150, 150, 165)

type SlotInfo = { pieces: number, at: number }

local request: RemoteFunction
local buildRequest: RemoteFunction
local gui: ScreenGui
local card: Frame
local slotRows: { { info: TextLabel, save: TextButton, load: TextButton } } = {}
local codeLabel: TextLabel
local codeHint: TextLabel
local codeBox: TextBox
local slots: { SlotInfo | false } = {}
local busy = false
local isOpen = false
local pieceCount: () -> number = function()
	return 0
end

------------------------------------------------------------------------------------------------
-- Helpers

local function corner(object: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = object
end

local function label(text: string, size: number, color: Color3?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
	l.TextSize = size
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	return l
end

local function button(text: string, color: Color3, width: number): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(width, 44)
	b.BackgroundColor3 = color
	b.Text = text
	b.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
	b.TextSize = 15
	b.TextColor3 = Color3.new(0, 0, 0)
	b.AutoButtonColor = true
	corner(b, 12)
	return b
end

local function pop(object: GuiObject)
	local s = Instance.new("UIScale")
	s.Scale = 0.9
	s.Parent = object
	local t = TweenService:Create(s, TweenInfo.new(0.16, Enum.EasingStyle.Back), { Scale = 1 })
	t:Play()
	t.Completed:Once(function()
		s:Destroy()
	end)
end

local function ago(at: number): string
	local s = math.max(0, os.time() - at)
	if s < 60 then
		return "just now"
	elseif s < 3600 then
		return string.format("%d min ago", s // 60)
	elseif s < 86400 then
		return string.format("%d h ago", s // 3600)
	end
	local days = s // 86400
	return if days == 1 then "yesterday" else string.format("%d days ago", days)
end

-- A destructive button asks "Sure?" first: the first tap arms it, a second tap within a few
-- seconds does it. needsConfirm decides at tap time whether this tap needs it.
local function confirmable(b: TextButton, needsConfirm: () -> boolean, action: () -> ())
	local armedAt = 0
	local original = b.Text
	local originalColor = b.BackgroundColor3
	local function disarm()
		armedAt = 0
		b.Text = original
		b.BackgroundColor3 = originalColor
	end
	b.Activated:Connect(function()
		pop(b)
		if os.clock() - armedAt < CONFIRM_TIME or not needsConfirm() then
			disarm()
			action()
			return
		end
		armedAt = os.clock()
		original = b.Text
		originalColor = b.BackgroundColor3
		b.Text = "SURE?"
		b.BackgroundColor3 = ACCENT
		local mine = armedAt
		task.delay(CONFIRM_TIME, function()
			if armedAt == mine then
				disarm()
			end
		end)
	end)
end

local function ask(op: string, arg: any?): (boolean, string?, any)
	if busy then
		return false, nil, nil
	end
	busy = true
	local okCall, success, message, payload = pcall(function()
		return request:InvokeServer(op, arg)
	end)
	busy = false
	if not okCall then
		Toast.show("Could not reach the server", RED)
		return false, nil, nil
	end
	if message then
		Toast.show(message, if success then GREEN else Color3.fromRGB(255, 120, 100))
	end
	return success, message, payload
end

------------------------------------------------------------------------------------------------
-- Refresh

local function refreshSlots()
	for i, row in slotRows do
		local info = slots[i]
		if info then
			row.info.Text = string.format("%d parts  ·  %s", info.pieces, ago(info.at))
			row.info.TextColor3 = Color3.new(1, 1, 1)
			row.load.BackgroundColor3 = BLUE
			row.load.AutoButtonColor = true
			row.load.TextTransparency = 0
		else
			row.info.Text = "Empty"
			row.info.TextColor3 = MUTED
			row.load.BackgroundColor3 = IDLE
			row.load.AutoButtonColor = false
			row.load.TextTransparency = 0.5
		end
	end
end

local function setSlots(list: any)
	if type(list) ~= "table" then
		return
	end
	for i = 1, SLOTS do
		local v = list[i]
		slots[i] = if type(v) == "table" and type(v.pieces) == "number" and type(v.at) == "number" then v else false
	end
	refreshSlots()
end

local function showCode(code: string?)
	if code then
		codeLabel.Text = code
		codeLabel.TextColor3 = ACCENT
		codeHint.Text = "Friends type this code to get a copy"
	else
		codeLabel.Text = "------"
		codeLabel.TextColor3 = MUTED
		codeHint.Text = "Get a code for the build on the table"
	end
end

------------------------------------------------------------------------------------------------
-- UI

local function buildUi()
	gui = Instance.new("ScreenGui")
	gui.Name = "MyBuilds"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.Enabled = false

	-- Tapping outside the card closes it.
	local shade = Instance.new("TextButton")
	shade.Name = "Shade"
	shade.Text = ""
	shade.AutoButtonColor = false
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.45
	shade.Size = UDim2.fromScale(1, 1)
	shade.Parent = gui
	shade.Activated:Connect(function()
		SaveController.close()
	end)

	card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromOffset(380, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = DARK
	card.Active = true
	card.Parent = gui
	corner(card, 18)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.8
	stroke.Thickness = 2
	stroke.Parent = card
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = card
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = card
	-- Small screens: shrink the whole card to fit.
	local scale = Instance.new("UIScale")
	scale.Parent = card
	local function fit()
		local camera = Workspace.CurrentCamera
		local view = if camera then camera.ViewportSize else Vector2.new(1000, 700)
		scale.Scale = math.clamp(math.min((view.Y - 40) / 520, (view.X - 24) / 380), 0.6, 1)
	end
	fit()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end

	local order = 0
	local function add(object: GuiObject)
		order += 1
		object.LayoutOrder = order
		object.Parent = card
	end

	-- Title
	local titleRow = Instance.new("Frame")
	titleRow.BackgroundTransparency = 1
	titleRow.Size = UDim2.new(1, 0, 0, 44)
	add(titleRow)
	local title = label("MY BUILDS", 20, ACCENT)
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Parent = titleRow
	local close = button("X", IDLE, 44)
	close.TextColor3 = Color3.new(1, 1, 1)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.fromScale(1, 0)
	close.Parent = titleRow
	close.Activated:Connect(function()
		SaveController.close()
	end)

	-- Slots
	for i = 1, SLOTS do
		local row = Instance.new("Frame")
		row.BackgroundColor3 = IDLE
		row.Size = UDim2.new(1, 0, 0, 58)
		corner(row, 12)
		add(row)
		local name = label("Slot " .. i, 16)
		name.Position = UDim2.fromOffset(12, 8)
		name.Size = UDim2.new(1, -200, 0, 20)
		name.Parent = row
		local info = label("Empty", 13, MUTED)
		info.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold)
		info.Position = UDim2.fromOffset(12, 30)
		info.Size = UDim2.new(1, -200, 0, 18)
		info.TextTruncate = Enum.TextTruncate.AtEnd
		info.Parent = row
		local save = button("SAVE", GREEN, 84)
		save.AnchorPoint = Vector2.new(1, 0.5)
		save.Position = UDim2.new(1, -96, 0.5, 0)
		save.Parent = row
		local load = button("LOAD", BLUE, 80)
		load.AnchorPoint = Vector2.new(1, 0.5)
		load.Position = UDim2.new(1, -8, 0.5, 0)
		load.Parent = row
		slotRows[i] = { info = info, save = save, load = load }
		confirmable(save, function()
			return slots[i] ~= false and slots[i] ~= nil -- saving over a filled slot
		end, function()
			local ok, _, payload = ask("save", i)
			if ok and type(payload) == "table" then
				setSlots(payload.slots)
			end
		end)
		confirmable(load, function()
			return slots[i] ~= false and pieceCount() > 0 -- replacing what is on the table
		end, function()
			if not slots[i] then
				Toast.show("That slot is empty")
				return
			end
			local ok = ask("load", i)
			if ok then
				SaveController.close()
			end
		end)
	end

	-- Share
	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.85
	divider.BorderSizePixel = 0
	divider.Size = UDim2.new(1, 0, 0, 2)
	add(divider)

	local shareRow = Instance.new("Frame")
	shareRow.BackgroundTransparency = 1
	shareRow.Size = UDim2.new(1, 0, 0, 66)
	add(shareRow)
	codeLabel = label("------", 30, MUTED)
	codeLabel.Font = Enum.Font.Code
	codeLabel.Position = UDim2.fromOffset(2, 0)
	codeLabel.Size = UDim2.new(1, -140, 0, 40)
	codeLabel.Parent = shareRow
	codeHint = label("", 12, MUTED)
	codeHint.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold)
	codeHint.Position = UDim2.fromOffset(2, 42)
	codeHint.Size = UDim2.new(1, -140, 0, 18)
	codeHint.TextWrapped = true
	codeHint.Parent = shareRow
	local share = button("SHARE", ACCENT, 128)
	share.AnchorPoint = Vector2.new(1, 0)
	share.Position = UDim2.new(1, 0, 0, 4)
	share.Parent = shareRow
	share.Activated:Connect(function()
		pop(share)
		if pieceCount() == 0 then
			Toast.show("Build something first")
			return
		end
		local ok, _, payload = ask("share")
		if ok and type(payload) == "table" and type(payload.code) == "string" then
			showCode(payload.code)
			pop(codeLabel)
		end
	end)

	-- Load a code
	local codeRow = Instance.new("Frame")
	codeRow.BackgroundTransparency = 1
	codeRow.Size = UDim2.new(1, 0, 0, 44)
	add(codeRow)
	codeBox = Instance.new("TextBox")
	codeBox.Name = "Code"
	codeBox.Size = UDim2.new(1, -96, 1, 0)
	codeBox.BackgroundColor3 = IDLE
	codeBox.ClearTextOnFocus = false
	codeBox.Font = Enum.Font.Code
	codeBox.TextSize = 22
	codeBox.TextColor3 = Color3.new(1, 1, 1)
	codeBox.PlaceholderText = "Got a code?"
	codeBox.PlaceholderColor3 = MUTED
	codeBox.Text = ""
	corner(codeBox, 12)
	codeBox.Parent = codeRow
	local filtering = false
	codeBox:GetPropertyChangedSignal("Text"):Connect(function()
		if filtering then
			return
		end
		local clean = ShareCode.filter(codeBox.Text)
		if clean ~= codeBox.Text then
			filtering = true
			codeBox.Text = clean
			codeBox.CursorPosition = #clean + 1
			filtering = false
		end
	end)
	local go = button("LOAD", BLUE, 88)
	go.AnchorPoint = Vector2.new(1, 0)
	go.Position = UDim2.fromScale(1, 0)
	go.Parent = codeRow
	confirmable(go, function()
		return pieceCount() > 0 and ShareCode.normalize(codeBox.Text) ~= nil
	end, function()
		local code = ShareCode.normalize(codeBox.Text)
		if not code then
			Toast.show("Codes are " .. ShareCode.LENGTH .. " letters and numbers")
			return
		end
		local ok = ask("code", code)
		if ok then
			codeBox.Text = ""
			SaveController.close()
		end
	end)

	-- Start over
	local fresh = button("START OVER", IDLE, 140)
	fresh.TextColor3 = RED
	fresh.TextSize = 14
	fresh.Size = UDim2.new(1, 0, 0, 40)
	add(fresh)
	confirmable(fresh, function()
		return pieceCount() > 0
	end, function()
		if pieceCount() == 0 then
			Toast.show("The table is already empty")
			return
		end
		local okCall, success, message = pcall(function()
			return buildRequest:InvokeServer("clear", {})
		end)
		if okCall and success then
			Toast.show("Cleared. Undo brings it back", GREEN)
			SaveController.close()
		elseif okCall and message then
			Toast.show(message, RED)
		end
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
	refreshSlots()
	showCode(nil)
end

------------------------------------------------------------------------------------------------
-- API

function SaveController.open()
	if isOpen then
		return
	end
	isOpen = true
	showCode(nil) -- a code belongs to the build it was made for; ask again for this one
	gui.Enabled = true
	pop(card)
	task.spawn(function()
		local ok, _, payload = ask("list")
		if ok and type(payload) == "table" then
			setSlots(payload.slots)
		end
	end)
end

function SaveController.close()
	isOpen = false
	if gui then
		gui.Enabled = false
	end
	if codeBox then
		codeBox:ReleaseFocus()
	end
end

function SaveController.isOpen(): boolean
	return isOpen
end

function SaveController.start(getPieceCount: () -> number)
	pieceCount = getPieceCount
	request = Net.func(Net.Names.BuildStore)
	buildRequest = Net.func(Net.Names.BuildRequest)
	buildUi()
end

return SaveController
