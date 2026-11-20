--!strict
-- Audit area 1 (docs/RESEARCH_FIRST_SESSION.md: the top ragdoll games show a new player a bare
-- screen, one objective at a time, and bring the rest of the HUD in at about 90 s). For a newcomer
-- (server attribute Newcomer: under Config.NEWCOMER_SECONDS played in all), on every platform:
--   * one objective line at the top, walking the lab's best moments in the order players find them:
--     knock a dummy over, fire yourself from the cannon, ride the wrecking ball, open WEAPONS;
--   * the machine the line is about wears a soft pulsing yellow outline (no arrows across the map);
--   * until the reveal (Config.QUIET_START, at least FirstVisit.MIN_QUIET after the flow starts) the
--     launcher columns (PC) or SHOP/MENU (phone), the key chips, LAB VIEW, the replay button, the
--     long help line, the lab's signs, dummy chatter and the news toasts wait; then they come in one
--     piece at a time (key chips last);
--   * news and tips wait for the reveal (Client/Notify, V6-1), rewards come one at a time; toasts
--     sit below the line (Toast.setGoalTop), never on it.
-- The HUD is held from the first frame and let go at once when the server says "not a newcomer",
-- so a returning player never sees it vanish, and a newcomer never sees it flash.
-- Step completion comes from the server (player attributes): Takedowns, CannonShots (Playground's
-- cannon) and ThrownBy_SwingBall (the wrecking ball's throwOnTouch). Config.FIRST_VISIT switches
-- it all off.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme")) :: any
local Controller = require(UI:WaitForChild("LihFolkUIController")) :: any

local Client = script.Parent
local HudSlots = require(Client:WaitForChild("HudSlots"))
local Toast = require(Client:WaitForChild("Toast")) :: any

local FirstVisit = {}

FirstVisit.GIVE_UP = 300 -- s: the line goes away after this whatever is left
FirstVisit.MIN_QUIET = 45 -- s: a flow that starts late (slow load) still gets this much quiet
FirstVisit.REVEAL_GAP = 5 -- s between the pieces of the reveal (left, right, then the key chips at 2x)
FirstVisit.ANSWER_WAIT = 20 -- s: no server answer by then = treated as a returning player
FirstVisit.PHONE_HELD = { "Shop", "Menu" } -- the phone's launchers held with the rest
FirstVisit.STEPS = table.freeze({
	{ id = "Takedown", text = "Knock a dummy over!", pad = "Knock a dummy over! (R2)" },
	{ id = "Cannon", text = "Fire yourself from the CANNON", target = "CannonPad", glow2 = "CannonModel", attr = "CannonShots" },
	{ id = "Wrecking", text = "Get hit by the WRECKING BALL", target = "SwingBall", attr = "ThrownBy_SwingBall" },
	{ id = "Weapons", text = "Open WEAPONS for more", pad = "Open WEAPONS for more (Y)" },
})

local player = Players.LocalPlayer

-- The player's own lab: the Playground folder whose plot the player owns (Lab sets the plot
-- folder's Owner and the player's LabOrigin; the Playground lab sits on that origin).
local function myLab(): Instance?
	local pg = Workspace:FindFirstChild("Playground")
	if not pg then
		return nil
	end
	local origin = player:GetAttribute("LabOrigin")
	local best, bestD = nil, math.huge
	for _, f in pg:GetChildren() do
		if f.Name ~= "Plaza" and f.Name ~= "Labs" then
			if f:GetAttribute("Owner") == player.UserId then
				return f
			end
			local pad = f:FindFirstChild("CannonPad")
			if typeof(origin) == "Vector3" and pad and pad:IsA("BasePart") then
				local d = Vector2.new(pad.Position.X - origin.X, pad.Position.Z - origin.Z).Magnitude
				if d < bestD then
					best, bestD = f, d
				end
			end
		end
	end
	return if bestD < 400 then best else nil
end

local function onPad(): boolean
	return UserInputService.GamepadEnabled and not UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function phone(): boolean
	local cam = Workspace.CurrentCamera
	local v = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	return UserInputService.TouchEnabled and math.min(v.X, v.Y) < 600
end

local function buildLine(): (ScreenGui, TextLabel)
	local gui = Instance.new("ScreenGui")
	gui.Name = "FirstVisitGoal"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 8
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	local pill = Instance.new("TextLabel")
	pill.Name = "Goal"
	pill.AnchorPoint = Vector2.new(0.5, 0)
	-- (A phone keeps its top-left counter: the line goes under it.)
	pill.Position = UDim2.new(0.5, 0, 0, if phone() then 48 else 14)
	pill.Size = UDim2.fromOffset(200, 40)
	pill.BackgroundColor3 = Theme.Palette.dusk or Color3.fromRGB(23, 25, 30)
	pill.BackgroundTransparency = 0.12
	pill.TextColor3 = Color3.fromRGB(245, 244, 240)
	pill.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	pill.TextSize = 20
	pill.Text = ""
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = pill
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(240, 196, 70)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = pill
	pill.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	return gui, pill
end

-- Sets the line's text and fits the pill to it: never wider than the screen less 16 px a side,
-- the text shrinking down to 14 px before that (narrow phones).
local function setText(pill: TextLabel, text: string)
	pill.Text = text
	local gui = pill.Parent :: ScreenGui
	local maxW = math.max(160, gui.AbsoluteSize.X - 32)
	local size = 20
	local w = 0
	while true do
		local params = Instance.new("GetTextBoundsParams")
		params.Text = text
		params.Font = pill.FontFace
		params.Size = size
		params.Width = 10000
		local ok, b = pcall(TextService.GetTextBoundsAsync, TextService, params)
		w = (if ok then b.X else #text * size * 0.55) + 36
		if w <= maxW or size <= 14 then
			break
		end
		size -= 1
	end
	pill.TextSize = size
	pill.TextWrapped = w > maxW
	pill.Size = UDim2.fromOffset(math.min(w, maxW), if w > maxW then 58 else 40)
end

local function glow(target: Instance?): Highlight?
	if not target then
		return nil
	end
	local h = Instance.new("Highlight")
	h.Name = "FirstVisitGlow"
	h.FillTransparency = 0.85
	h.FillColor = Color3.fromRGB(255, 205, 70)
	h.OutlineColor = Color3.fromRGB(255, 205, 70)
	h.OutlineTransparency = 0.1
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Adornee = target
	h.Parent = target
	-- (A slow pulse: it catches the eye without shouting.)
	TweenService:Create(h, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { OutlineTransparency = 0.7, FillTransparency = 0.95 }):Play()
	return h
end

-- The HUD hold: PC (HudV3 columns and chips) and phone (the kit's SHOP/MENU launchers).
local hud: any = nil
local function holdHud(on: boolean, which: string?)
	if hud and hud.hold then
		if which == nil or which == "Left" then
			hud.hold("Left", on)
		end
		if which == nil or which == "Right" then
			hud.hold("Right", on)
		end
		if which == nil or which == "Chips" then
			hud.hold("Chips", on)
		end
	end
	if which == nil or which == "Left" then
		for _, label in FirstVisit.PHONE_HELD do
			pcall(Controller.setHudShown, label, not on)
		end
	end
end

function FirstVisit.start()
	if not (Config :: any).FIRST_VISIT then
		return
	end
	local ok, HudV3 = pcall(function()
		return require(Client:WaitForChild("HudV3", 5)) :: any
	end)
	hud = if ok then HudV3 else nil
	-- Held from the first frame: a newcomer never sees the HUD flash, a returning player gets it
	-- back the moment the server answers (usually well under a second).
	HudSlots.setNewcomerUntil(math.huge)
	holdHud(true)
	local t0 = os.clock()
	while player:GetAttribute("Newcomer") == nil and os.clock() - t0 < FirstVisit.ANSWER_WAIT do
		task.wait(0.1)
	end
	if player:GetAttribute("Newcomer") ~= true then
		HudSlots.setNewcomerUntil(0)
		holdHud(false)
		return
	end
	local revealAt = math.max(Config.QUIET_START, time() + FirstVisit.MIN_QUIET)
	HudSlots.setNewcomerUntil(revealAt)
	-- (For modules that cannot require HudSlots: DummyLife, ProgressUI.)
	player:SetAttribute("NewcomerUntil", revealAt)


	-- The lab's signs (today's machine, NEW tags) wait too: the first screen is the dummies.
	local hiddenSigns: { BillboardGui } = {}
	local hiddenLight: { BasePart } = {}
	-- The reveal is scheduled first, so nothing below can leave the HUD held for good. It comes in
	-- piece by piece (research: one new thing at a time): the signs and the left cards, the right
	-- column REVEAL_GAP later, the key chips last.
	task.delay(math.max(0, revealAt - time()), function()
		for _, s in hiddenSigns do
			if s.Parent then
				s.Enabled = true
			end
		end
		for _, p in hiddenLight do
			if p.Parent then
				p.LocalTransparencyModifier = 0
			end
		end
		holdHud(false, "Left")
		HudSlots.newcomerChanged:Fire() -- (LAB VIEW and the rest place themselves again)
		pcall(function()
			-- (The help line grows back to its full text with the HUD.)
			local Poke = require(Client:WaitForChild("PokeController")) :: any
			if Poke.refreshHelp then
				Poke.refreshHelp()
			end
		end)
		task.wait(FirstVisit.REVEAL_GAP)
		holdHud(false, "Right")
		task.wait(FirstVisit.REVEAL_GAP * 2)
		holdHud(false, "Chips")
	end)
	local pgFolder = Workspace:FindFirstChild("Playground")
	for _, d in if pgFolder then pgFolder:GetDescendants() else {} do
		if d:IsA("BillboardGui") and d.Name == "ZoneSign" and d.Enabled then
			d.Enabled = false
			table.insert(hiddenSigns, d)
		elseif d:IsA("BasePart") and d.Name == "TodayLight" then
			d.LocalTransparencyModifier = 1
			table.insert(hiddenLight, d)
		end
	end

	local gui, line = buildLine()
	Toast.setGoalTop(function(): number
		if not line.Parent or not line.Visible then
			return 0
		end
		return line.Position.Y.Offset + line.AbsoluteSize.Y + 8
	end)
	local wanted = "" -- the step text as written (the pill shows it, fitted)
	local function refit()
		line.Position = UDim2.new(0.5, 0, 0, if phone() then 48 else 14)
		if wanted ~= "" then
			setText(line, wanted)
		end
	end
	local cam = Workspace.CurrentCamera
	local viewConn = if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(refit) else nil
	local function say(text: string)
		wanted = text
		line.Visible = true
		setText(line, text)
	end

	local started = time()
	local ok2, err = pcall(function()
		for _, step in FirstVisit.STEPS do
			-- (The Weapons step waits for the HUD: WEAPONS is the thing it points at.)
			if step.id == "Weapons" and time() < revealAt + 1 then
				line.Visible = false
				task.wait(math.max(0, revealAt + 1 - time()))
			end
			-- (The lab streams in: look again for a while before giving a machine up; the line hides
			-- while it looks.)
			local target: Instance? = nil
			if step.target then
				local waitUntil = os.clock() + 15
				repeat
					local lab = myLab()
					target = if lab then lab:FindFirstChild(step.target, true) else nil
					if not target then
						line.Visible = false
						task.wait(0.5)
					end
				until target or os.clock() > waitUntil
				if not target then
					continue -- (no such machine here)
				end
			end
			local padNow = onPad()
			say(if padNow and step.pad then step.pad else step.text)
			local hl = glow(target)
			local lab = myLab()
			local hl2 = if step.glow2 and lab then glow(lab:FindFirstChild(step.glow2, true)) else nil
			local startCount = if step.attr then ((player:GetAttribute(step.attr) :: number?) or 0) else 0
			local startTakedowns = (player:GetAttribute("Takedowns") :: number?) or 0
			local done = false
			while not done and time() - started <= FirstVisit.GIVE_UP do
				if step.id == "Takedown" then
					done = ((player:GetAttribute("Takedowns") :: number?) or 0) > startTakedowns
				elseif step.attr then
					done = ((player:GetAttribute(step.attr) :: number?) or 0) > startCount
				elseif step.id == "Weapons" then
					local okCat, ToolCatalog = pcall(function()
						return require(Client:WaitForChild("ToolCatalog")) :: any
					end)
					done = okCat and ToolCatalog.isOpen()
				end
				if not done then
					-- (A pad plugged in or out mid-step: the button name follows.)
					if onPad() ~= padNow and step.pad then
						padNow = onPad()
						say(if padNow then step.pad else step.text)
					end
					task.wait(0.2)
				end
			end
			for _, h in { hl, hl2 } do
				if h then
					h:Destroy()
				end
			end
			if not done then
				break
			end
			-- A short "done" beat before the next line.
			say("\u{2713} Nice!")
			task.wait(1.4)
		end
	end)
	if not ok2 then
		warn("[FirstVisit] " .. tostring(err))
	end
	if viewConn then
		viewConn:Disconnect()
	end
	Toast.setGoalTop(nil)
	gui:Destroy()
end

return FirstVisit
