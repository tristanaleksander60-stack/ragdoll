--!strict
-- 21 Nov 2026 (the owner: "a pass called God: it gives access to creating life, spawning ragdolls";
-- Config.GOD_PASS, Server/Systems/DummySpawn): the GOD MODE window and its launcher (a square on a
-- computer or tablet: HudV3; a launcher by SHOP on a phone).
--   * With GOD MODE (or its free trial running): four ragdolls to create, MINI, HEAVY, BOUNCY and
--     FLOPPY; a tap closes the window and one comes down in a beam of light a little in front of you.
--   * Without it: what it gives, a TRY FREE (the first creation starts the 60 s trial) and GET GOD
--     MODE (the Roblox purchase prompt, through MoneyService "Buy").
-- The server decides everything (DummySpawn); a refused "god" opens this window.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Net = require(Shared:WaitForChild("Net")) :: any
local Shop = require(Shared:WaitForChild("Shop")) :: any
local GodRules = require(Shared:WaitForChild("GodRules")) :: any
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents")) :: any
local Controller = require(UI:WaitForChild("LihFolkUIController")) :: any

local GodMode = {}

GodMode.TYPES = {
	{ id = "MINI", word = "TINY", color = Color3.fromRGB(120, 210, 255) },
	{ id = "HEAVY", word = "HEAVY", color = Color3.fromRGB(150, 150, 160) },
	{ id = "BOUNCY", word = "BOUNCY", color = Color3.fromRGB(255, 140, 220) },
	{ id = "FLOPPY", word = "FLOPPY", color = Color3.fromRGB(255, 220, 120) },
}
GodMode.AHEAD = 12 -- studs in front of you (the way you look) where life comes down

local player = Players.LocalPlayer
local window: any = nil
local offer: GuiObject? = nil
local cards: GuiObject? = nil
local trialLine: TextLabel? = nil

-- Whether creating life needs GOD MODE here (the same rule as DummySpawn.godGated: a pass on sale, or
-- Studio). While the pass is not on sale live, everyone creates for free and the window has no offer.
function GodMode.gated(): boolean
	local pass = Shop.byKey.God
	return pass ~= nil and GodRules.gated(Config.GOD_PASS == true, pass.id, RunService:IsStudio())
end

-- V9-0f: whether this player sees the GOD launcher (HUD square, phone MENU entry): an owner of the pass
-- or during the free trial (or everyone while creating is free). Others find GOD MODE in the SHOP.
function GodMode.launcherShown(): boolean
	return GodRules.launcherShown(GodMode.gated(), player:GetAttribute("God") == true, player:GetAttribute("GodTrialUntil"), Workspace:GetServerTimeNow())
end

-- V9-0f: the SHOP card's TRY 60 s: the server starts the trial (once a visit), the window opens.
function GodMode.tryIt()
	Net.event(Net.Names.Spawn):FireServer("Try")
	Controller.open("God")
end

local function creating(): boolean
	if not GodMode.gated() or player:GetAttribute("God") == true then
		return true
	end
	local untilAt = player:GetAttribute("GodTrialUntil")
	return type(untilAt) == "number" and Workspace:GetServerTimeNow() < untilAt
end

-- A spot on the ground a little in front of you.
local function spotAhead(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return nil
	end
	-- (Where you look, so you see it come down: the camera's way, flat; the avatar's if there is no camera.)
	local camera = Workspace.CurrentCamera
	local facing = if camera then camera.CFrame.LookVector else root.CFrame.LookVector
	local look = Vector3.new(facing.X, 0, facing.Z)
	local ahead = root.Position + (if look.Magnitude > 0.01 then look.Unit else Vector3.zAxis) * GodMode.AHEAD
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character :: Instance }
	local hit = Workspace:Raycast(ahead + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), params)
	return if hit then hit.Position else ahead
end

function GodMode.create(kind: string)
	local at = spotAhead()
	if at then
		Net.event(Net.Names.Spawn):FireServer("Spawn", kind, at)
	end
end

local function refresh()
	local can = creating()
	if offer then
		offer.Visible = not can
	end
	if cards then
		cards.Visible = true -- (always shown: the first tap starts the free trial)
	end
	local line = trialLine
	if line then
		local untilAt = player:GetAttribute("GodTrialUntil")
		local left = if type(untilAt) == "number" then math.ceil(untilAt - Workspace:GetServerTimeNow()) else 0
		line.Visible = GodMode.gated() and player:GetAttribute("God") ~= true
		line.Text = if player:GetAttribute("God") == true then ""
			elseif left > 0 then string.format("FREE TRY: %d s", left)
			elseif type(untilAt) == "number" then "Your free try is over"
			else "Tap one to try it FREE for 60 s"
	end
end

local function build()
	window = C.Window({ name = "God", title = "GOD MODE", theme = "shop", icon = "god", size = Vector2.new(560, 440) })
	local body = window.body
	trialLine = C.Text("body", "", { wrap = true, size = UDim2.new(1, 0, 0, 30), layoutOrder = 1, parent = body })
	-- The four kinds of life.
	local grid = Instance.new("Frame")
	grid.Name = "Kinds"
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.fromScale(1, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.LayoutOrder = 2
	C.Grid(grid, Vector2.new(230, 70), 12)
	grid.Parent = body
	cards = grid
	for i, t in GodMode.TYPES do
		-- (Each kind in its own colour, the colour its chest plate wears: DummySpawn.TYPES.)
		local swatch = {
			top = t.color:Lerp(Color3.new(1, 1, 1), 0.12),
			bottom = t.color,
			shade = t.color:Lerp(Color3.new(0, 0, 0), 0.45),
			text = Color3.fromRGB(22, 18, 40),
		}
		local b = C.Button({
			text = t.word,
			icon = "god",
			swatch = swatch,
			size = UDim2.fromOffset(230, 70),
			layoutOrder = i,
			parent = grid,
			onActivated = function()
				Controller.closeAll()
				GodMode.create(t.id)
			end,
		})
		b.root.Name = t.id
	end
	-- The offer (without GOD MODE).
	local o = Instance.new("Frame")
	o.Name = "Offer"
	o.BackgroundTransparency = 1
	o.Size = UDim2.fromScale(1, 0)
	o.AutomaticSize = Enum.AutomaticSize.Y
	o.LayoutOrder = 3
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = o
	-- (One short line, not a list: the coloured kinds above already show what it is.)
	C.Text("body", "\u{2728} Always on   \u{2728} Twice as many   \u{2728} Beam of light", { wrap = true, size = UDim2.new(1, 0, 0, 26), layoutOrder = 1, parent = o })
	local get = C.Button({
		text = "GET GOD MODE",
		icon = "god",
		role = "premium",
		size = UDim2.fromOffset(300, 60),
		layoutOrder = 10,
		parent = o,
		onActivated = function()
			Net.event(Net.Names.Money):FireServer("Buy", "God")
		end,
	})
	get.root.Name = "Get"
	o.Parent = body
	offer = o
	Controller.register(window)
	Controller.addHudButton({ window = "God", label = "God", icon = "god", theme = "shop", layoutOrder = 2 })
end

function GodMode.start()
	if not (Config.GOD_PASS and Config.DUMMY_TYPES) then
		return
	end
	build()
	refresh()
	for _, name in { "God", "GodTrialUntil" } do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	-- (The trial's clock, while the window is open.)
	task.spawn(function()
		while true do
			task.wait(1)
			if Controller.isOpen("God") then
				refresh()
			end
		end
	end)
	-- A creation the server refused for want of GOD MODE: the window says what it is.
	Net.event(Net.Names.Spawn).OnClientEvent:Connect(function(kind: unknown, why: unknown)
		if kind == "Refused" and why == "god" then
			Controller.open("God")
		end
	end)
end

return GodMode
