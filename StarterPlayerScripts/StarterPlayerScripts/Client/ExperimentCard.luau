--!strict
-- Phase 1 (19 Nov 2026): the Experiment card (ExperimentService, Shared\Experiments). One line,
-- "🧪 Blast off the CANNON  0/1  1:24", in HudSlots "Experiment" (a phone: the big WEAPONS button's
-- box; elsewhere top middle). It waits out the first minute's bar, steps aside for a replay, a slot
-- pick, the catalog, a chase and the arena. Tap it: the EXPERIMENTS window (SKIP, stars, and a
-- friend's SHARE CODE from a replay: "Beat 140 with the Rattler!"). Gamepad: in MENU's list too.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local ShareCode = require(Shared:WaitForChild("ShareCode"))
local Toys = require(Shared:WaitForChild("Toys"))
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))
local Theme = require(UI:WaitForChild("LihFolkUITheme"))

local Client = script.Parent
local HudSlots = require(Client:WaitForChild("HudSlots"))
local PokeController = require(Client:WaitForChild("PokeController"))
local ReplayController = require(Client:WaitForChild("ReplayController"))
local ToolCatalog = require(Client:WaitForChild("ToolCatalog"))
local ViewMode = require(Client:WaitForChild("ViewMode"))
local Toast = require(Client:WaitForChild("Toast"))

local ExperimentCard = {}
ExperimentCard.showEconomy = function(_d: any) end -- (set below; phase 2)

local player = Players.LocalPlayer
local card: TextButton? = nil
local current: any = nil -- the server's Card data
local endsAt = 0
local challenge: { toy: string, score: number }? = nil
local windowText: TextLabel? = nil
local ecoText: TextLabel? = nil
local buyButton: any = nil

-- A friend's code: the toy and the score to beat (nil: not a code).
function ExperimentCard.challengeOf(code: string): (string?, number?)
	local index, score = ShareCode.decode(code)
	local toy = index and Toys.list[index]
	if not toy or not score then
		return nil, nil
	end
	return toy.id, score
end

-- The replay told its score: a friend's code beaten?
function ExperimentCard.scored(score: number)
	local c = challenge
	if c and score > c.score then
		challenge = nil
		Toast.show(string.format("\u{1F3C6} You beat your friend's %d!", c.score), Color3.fromRGB(120, 230, 140))
	end
end

local function lineOf(data: any, left: number): string
	return string.format("\u{1F9EA} %s  %d/%d  %d:%02d", data.text, data.count, data.target, left // 60, left % 60)
end

local function shown(): boolean
	local gui = player:FindFirstChild("PlayerGui")
	local chase = gui and gui:FindFirstChild("ChaseHud")
	local arena = gui and gui:FindFirstChild("MinigameHud")
	return current ~= nil
		and not PokeController.firstMinute()
		and not PokeController.isPicking()
		and not ReplayController.isPlaying()
		and not ToolCatalog.isOpen()
		and not (chase and chase:IsA("ScreenGui") and chase.Enabled)
		and not (arena and arena:IsA("ScreenGui") and arena.Enabled)
end

local function pop(b: GuiObject)
	local s = Instance.new("UIScale")
	s.Scale = 1.15
	s.Parent = b
	local t = TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 })
	t:Play()
	t.Completed:Once(function()
		s:Destroy()
	end)
end

local function buildWindow()
	local window = C.Window({ name = "Experiments", title = "Experiments", theme = "daily", icon = "gift", size = Vector2.new(440, if Config.ECONOMY then 640 else 360) })
	windowText = C.Text("body", "", { wrap = true, size = UDim2.new(1, 0, 0, 60), layoutOrder = 1, parent = window.body })
	C.Button({
		text = "SKIP",
		role = "neutral",
		size = UDim2.fromOffset(160, 46),
		layoutOrder = 2,
		parent = window.body,
		onActivated = function()
			Net.event(Net.Names.Experiment):FireServer("Skip")
			Controller.close("Experiments")
		end,
	})
	C.Text("body", "A friend's SHARE CODE (from a replay):", { wrap = true, size = UDim2.new(1, 0, 0, 26), layoutOrder = 3, parent = window.body })
	local box = Instance.new("TextBox")
	box.Name = "Code"
	box.PlaceholderText = "ABC234"
	box.Text = ""
	box.ClearTextOnFocus = false
	box.Size = UDim2.new(1, 0, 0, 46)
	box.LayoutOrder = 4
	box.FontFace = Theme.Fonts.display
	box.TextSize = 24
	box.BackgroundColor3 = Theme.Palette.dusk
	box.TextColor3 = Color3.new(1, 1, 1)
	box.Parent = window.body
	box:GetPropertyChangedSignal("Text"):Connect(function()
		-- (Codes only: six letters from the code alphabet, nothing else can be typed.)
		local clean = string.sub(string.upper(string.gsub(box.Text, "[^%w]", "")), 1, 6)
		if clean ~= box.Text then
			box.Text = clean
		end
	end)
	C.Button({
		text = "TRY IT",
		role = "go",
		size = UDim2.fromOffset(160, 46),
		layoutOrder = 5,
		parent = window.body,
		onActivated = function()
			local toyId, score = ExperimentCard.challengeOf(box.Text)
			if toyId and score then
				challenge = { toy = toyId, score = score }
				Controller.close("Experiments")
				Toast.show(string.format("Beat %d with the %s!", score, Toys.byId[toyId].label), Color3.fromRGB(255, 210, 74))
				if table.find(PokeController.getLoadout(), toyId) then
					PokeController.select(toyId)
				end
			else
				Toast.show("That code does not work. Check the letters")
			end
		end,
	})
	-- Phase 2: BOLTS, today's Daily Experiments, the BONE JOURNAL and like-milestone codes
	-- (EconomyService State). Lines of text and two buttons: nothing here can be typed but a code.
	if Config.ECONOMY then
		local remote = Net.event(Net.Names.Economy)
		ecoText = C.Text("body", "", { wrap = true, size = UDim2.new(1, 0, 0, 230), layoutOrder = 6, parent = window.body })
		buyButton = C.Button({
			text = "BUY NEXT WEAPON",
			role = "go",
			size = UDim2.fromOffset(240, 46),
			layoutOrder = 7,
			parent = window.body,
			onActivated = function()
				remote:FireServer("BuyNext")
			end,
		})
		local codeBox = Instance.new("TextBox")
		codeBox.Name = "LikeCode"
		codeBox.PlaceholderText = "Code"
		codeBox.Text = ""
		codeBox.ClearTextOnFocus = false
		codeBox.Size = UDim2.new(1, 0, 0, 46)
		codeBox.LayoutOrder = 8
		codeBox.FontFace = Theme.Fonts.display
		codeBox.TextSize = 22
		codeBox.BackgroundColor3 = Theme.Palette.dusk
		codeBox.TextColor3 = Color3.new(1, 1, 1)
		codeBox.Parent = window.body
		codeBox:GetPropertyChangedSignal("Text"):Connect(function()
			local clean = string.sub(string.upper(string.gsub(codeBox.Text, "[^%w]", "")), 1, 24)
			if clean ~= codeBox.Text then
				codeBox.Text = clean
			end
		end)
		C.Button({
			text = "REDEEM CODE",
			role = "neutral",
			size = UDim2.fromOffset(200, 46),
			layoutOrder = 9,
			parent = window.body,
			onActivated = function()
				if codeBox.Text ~= "" then
					remote:FireServer("Redeem", codeBox.Text)
					codeBox.Text = ""
				end
			end,
		})
		remote.OnClientEvent:Connect(function(kind: unknown, data: unknown)
			if kind == "State" and type(data) == "table" then
				ExperimentCard.showEconomy(data)
			end
		end)
		remote:FireServer("Hello")
	end
	Controller.register(window)
end

-- The economy part of the window from the server's State.
ExperimentCard.showEconomy = function(d: any)
	local lines = { string.format("\u{1F529} %d BOLTS", tonumber(d.bolts) or 0) }
	if type(d.nextName) == "string" then
		table.insert(lines, string.format("Next weapon: %s for %d BOLTS", d.nextName, tonumber(d.price) or 0))
	end
	table.insert(lines, "\nTODAY'S EXPERIMENTS (the same on every server):")
	for _, x in (if type(d.daily) == "table" then d.daily else {}) do
		table.insert(lines, (if x.done then "\u{2705} " else "\u{2B1C} ") .. tostring(x.text))
	end
	local got, total, found = 0, 0, {}
	for _, page in (if type(d.journal) == "table" then d.journal else {}) do
		total += 1
		if page.got then
			got += 1
			table.insert(found, tostring(page.text))
		end
	end
	table.insert(lines, string.format("\n\u{1F4D6} BONE JOURNAL %d/%d%s", got, total, if #found > 0 then ": " .. table.concat(found, ", ") else ""))
	for _, c in (if type(d.codes) == "table" then d.codes else {}) do
		if type(c.code) == "string" and c.code ~= "" then
			table.insert(lines, string.format("CODE %s (%d likes!)", c.code, c.likes))
		else
			table.insert(lines, string.format("At %d likes: a new code here!", tonumber(c.likes) or 0))
			break
		end
	end
	local t = ecoText
	if t then
		t.Text = table.concat(lines, "\n")
	end
	local b = buyButton
	if b then
		b.setText(if type(d.nextName) == "string" then string.format("BUY %s (%d)", string.upper(d.nextName), tonumber(d.price) or 0) else "ALL WEAPONS YOURS")
	end
end

local function build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ExperimentCard"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 8
	local b = Instance.new("TextButton")
	b.Name = "Card"
	b.AutoButtonColor = true
	b.BackgroundColor3 = Color3.fromRGB(30, 60, 70)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.FontFace = Theme.Fonts.display
	b.TextScaled = true
	b.TextWrapped = true
	b.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = b
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = Color3.fromRGB(120, 230, 210)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent = b
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 18
	limit.MinTextSize = 10
	limit.Parent = b
	b.Activated:Connect(function()
		Controller.toggle("Experiments")
	end)
	b.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	card = b
	HudSlots.watch(function()
		HudSlots.apply(b, "Experiment", HudSlots.context(ViewMode.isTouch(), ViewMode.isLab()))
	end)
end

function ExperimentCard.start()
	if not Config.EXPERIMENTS then
		return
	end
	build()
	buildWindow()
	Net.event(Net.Names.Experiment).OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if type(data) ~= "table" then
			return
		end
		local d = data :: any
		if kind == "Card" and type(d.text) == "string" then
			local fresh = current == nil or current.id ~= d.id
			current = d
			endsAt = os.clock() + (tonumber(d.left) or 0)
			local b = card
			if b and fresh then
				pop(b)
			end
		elseif kind == "Done" then
			current = nil
			Toast.show(string.format("\u{2B50} Experiment done! +%d star%s", d.stars or 1, if d.stars == 1 then "" else "s"), Color3.fromRGB(255, 210, 74))
		elseif kind == "Late" then
			current = nil
		end
	end)
	RunService.Heartbeat:Connect(function()
		local b = card
		if not b then
			return
		end
		local show = shown()
		if b.Visible ~= show then
			b.Visible = show
		end
		local d = current
		if show and d then
			local text = lineOf(d, math.max(0, math.floor(endsAt - os.clock())))
			if b.Text ~= text then
				b.Text = text
			end
		end
		local w = windowText
		if w then
			local stars = (player:GetAttribute("Stars") :: number?) or 0
			w.Text = (if d then "Now: " .. d.text .. "\n" else "A new experiment is coming...\n") .. string.format("\u{2B50} %d stars this visit", stars)
		end
	end)
end

return ExperimentCard
