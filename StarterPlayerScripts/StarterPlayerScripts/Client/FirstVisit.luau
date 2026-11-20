--!strict
-- Audit area 1 (docs/RESEARCH_FIRST_SESSION.md: the top ragdoll games show a new player a bare
-- screen, one objective at a time, and bring the rest of the HUD in at about 90 s). For a newcomer
-- (server attribute Newcomer: under Config.NEWCOMER_SECONDS played in all), on every platform:
--   * one objective line at the top, walking the lab's best moments in the order players find them:
--     knock a dummy over, fire yourself from the cannon, ride the wrecking ball, open WEAPONS;
--   * the machine the line is about wears a soft yellow outline (no arrows across the map);
--   * until Config.QUIET_START the left and right launcher columns, the key chips, LAB VIEW, the
--     replay button and the long help line wait; then they slide in one a second (key chips last).
-- Returning players see none of it. Config.FIRST_VISIT switches it off.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme")) :: any

local Client = script.Parent
local HudSlots = require(Client:WaitForChild("HudSlots"))

local FirstVisit = {}

FirstVisit.GIVE_UP = 300 -- s: the line goes away after this whatever is left
FirstVisit.STEPS = table.freeze({
	{ id = "Takedown", text = "Knock a dummy over!" },
	{ id = "Cannon", text = "Fire yourself from the CANNON", target = "CannonPad", glow = "CannonModel" },
	{ id = "Wrecking", text = "Get hit by the WRECKING BALL", target = "SwingBall" },
	{ id = "Weapons", text = "Open WEAPONS for more" },
})

local player = Players.LocalPlayer

local function myLab(root: BasePart): Instance?
	local pg = Workspace:FindFirstChild("Playground")
	local best, bestD = nil, math.huge
	for _, f in if pg then pg:GetChildren() else {} do
		if f.Name ~= "Plaza" then
			local pad = f:FindFirstChild("CannonPad")
			if pad and pad:IsA("BasePart") then
				local d = (pad.Position - root.Position).Magnitude
				if d < bestD then
					best, bestD = f, d
				end
			end
		end
	end
	return best
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
	pill.Position = UDim2.new(0.5, 0, 0, 14)
	pill.Size = UDim2.fromOffset(0, 40)
	pill.AutomaticSize = Enum.AutomaticSize.X
	pill.BackgroundColor3 = Theme.Palette.dusk or Color3.fromRGB(23, 25, 30)
	pill.BackgroundTransparency = 0.12
	pill.TextColor3 = Color3.fromRGB(245, 244, 240)
	pill.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	pill.TextSize = 20
	pill.Text = ""
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 18)
	pad.PaddingRight = UDim.new(0, 18)
	pad.Parent = pill
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
	game:GetService("TweenService"):Create(h, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { OutlineTransparency = 0.7, FillTransparency = 0.95 }):Play()
	return h
end

function FirstVisit.start()
	if not (Config :: any).FIRST_VISIT then
		return
	end
	-- Wait for the server's answer about this player.
	local t0 = os.clock()
	while player:GetAttribute("Newcomer") == nil and os.clock() - t0 < 30 do
		task.wait(0.25)
	end
	if player:GetAttribute("Newcomer") ~= true then
		return
	end
	local revealAt = math.max(time(), 0) + math.max(0, Config.QUIET_START - time())
	HudSlots.newcomerUntil = revealAt
	local ok, HudV3 = pcall(function()
		return require(Client:WaitForChild("HudV3", 5)) :: any
	end)
	local hud = if ok then HudV3 else nil
	if hud and hud.hold then
		hud.hold("Left", true)
		hud.hold("Right", true)
		hud.hold("Chips", true)
	end
	-- The lab's signs (today's machine, NEW tags) wait too: the first screen is the dummies.
	local hiddenSigns: { BillboardGui } = {}
	local hiddenLight: { BasePart } = {}
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
	-- The reveal: one piece a second, the key chips last.
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
		if hud and hud.hold then
			hud.hold("Left", false)
			task.wait(1)
			hud.hold("Right", false)
			task.wait(9)
			hud.hold("Chips", false)
		end
	end)

	local _, line = buildLine()
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	local lab = if root then myLab(root) else nil
	local startTakedowns = (player:GetAttribute("Takedowns") :: number?) or 0
	local started = time()
	for _, step in FirstVisit.STEPS do
		-- (The lab streams in: look again for a while before giving a machine up.)
		local target: Instance? = nil
		if step.target then
			local waitUntil = os.clock() + 15
			repeat
				local r0 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if not lab and r0 and r0:IsA("BasePart") then
					lab = myLab(r0)
				end
				target = if lab then lab:FindFirstChild(step.target, true) else nil
				if not target then
					task.wait(0.5)
				end
			until target or os.clock() > waitUntil
		end
		if step.target and not target then
			continue -- (no such machine here)
		end
		line.Text = step.text
		local glowAt: Instance? = if target and target:IsA("BasePart") then target else nil
		if step.glow and lab then
			glowAt = lab:FindFirstChild(step.glow, true) or glowAt
		end
		local hl = glow(glowAt)
		local done = false
		while not done do
			if time() - started > FirstVisit.GIVE_UP then
				break
			end
			local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if step.id == "Takedown" then
				done = ((player:GetAttribute("Takedowns") :: number?) or 0) > startTakedowns
			elseif step.id == "Cannon" and target and r and r:IsA("BasePart") and target:IsA("BasePart") then
				-- (Fired: high above the pad, near it.)
				local flat = Vector2.new(r.Position.X - target.Position.X, r.Position.Z - target.Position.Z).Magnitude
				done = r.Position.Y > target.Position.Y + 18 and flat < 120
			elseif step.id == "Wrecking" and target and r and r:IsA("BasePart") and target:IsA("BasePart") then
				done = (r.Position - target.Position).Magnitude < 8
			elseif step.id == "Weapons" then
				-- (Only once the HUD is in; the catalog open is the end of the tour.)
				local ok2, ToolCatalog = pcall(function()
					return require(Client:WaitForChild("ToolCatalog")) :: any
				end)
				done = ok2 and ToolCatalog.isOpen()
			end
			RunService.Heartbeat:Wait()
			if done then
				break
			end
			task.wait(0.2)
		end
		if hl then
			hl:Destroy()
		end
		if time() - started > FirstVisit.GIVE_UP then
			break
		end
		-- A short "done" beat before the next line.
		if done then
			line.Text = "\u{2713} Nice!"
			task.wait(1.4)
		end
		-- (The Weapons step waits for the HUD to come in.)
		if step.id == "Wrecking" and time() < revealAt then
			line.Text = ""
			line.Visible = false
			task.wait(math.max(0, revealAt + 2 - time()))
			line.Visible = true
		end
	end
	line.Parent:Destroy()
end

return FirstVisit
