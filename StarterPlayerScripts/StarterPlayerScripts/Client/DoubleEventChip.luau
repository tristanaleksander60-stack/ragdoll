--!strict
-- V9-NOW 12 (owner, 21 Nov 2026: "a 2x event for 48 hours"): while Config.DOUBLE_EVENT runs, a small gold chip
-- "2X · 47:12:05" (KOs and BOLTS) sits top right on every device, under the top bar's row; one calm reveal
-- (a reward notice) a while after joining. The server decides the doubling (Shared/DoubleEvent, os.time()); the
-- chip reads the same window from the server's clock (GetServerTimeNow), so it ends when the servers stop doubling.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local DoubleEvent = require(Shared:WaitForChild("DoubleEvent"))

local DoubleEventChip = {}

DoubleEventChip.TOP = 60 -- px under the safe area's top (under the top bar's row)
DoubleEventChip.RIGHT = 12
DoubleEventChip.REVEAL_AFTER = 20 -- s after joining (past the first shots)

local label: TextLabel? = nil

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- Tests: the chip's text now ("" when hidden).
function DoubleEventChip.textForTest(): string
	local l = label
	return if l and l.Parent and (l.Parent :: ScreenGui).Enabled then l.Text else ""
end

function DoubleEventChip.start()
	local cfg = Config.DOUBLE_EVENT
	if DoubleEvent.left(cfg, now()) <= 0 and not (type(cfg) == "table" and now() < (cfg :: any).from) then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "DoubleEventChip"
	gui.ResetOnSpawn = false
	-- (22 Nov 2026, owner: "the 2X, the gift and Next together"): on the top bar's line, just left of the
	-- centred Next pill (HudV3; the gift is just right of it).
	gui.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets
	gui.DisplayOrder = 6
	gui.Enabled = false
	local chip = Instance.new("TextLabel")
	chip.Name = "Chip"
	chip.AnchorPoint = Vector2.new(1, 0.5)
	chip.Position = UDim2.new(0.5, -134, 0.5, 12)
	-- (22 Nov 2026, owner: "2X just an icon like the gift, symmetric, a bit lower"): a 44 px round badge.
	chip.Size = UDim2.fromOffset(44, 44)
	-- (22 Nov 2026: the gift's look: a dark glass circle, the 2X in gold, the same 1.2 scale.)
	chip.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
	chip.BackgroundTransparency = 0.1
	chip.TextColor3 = Color3.fromRGB(255, 205, 64)
	local chipScale = Instance.new("UIScale")
	chipScale.Scale = 1.2
	chipScale.Parent = chip
	chip.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)
	chip.TextSize = 20
	chip.Text = ""
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 0)
	pad.PaddingRight = UDim.new(0, 0)
	pad.Parent = chip
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 22)
	round.Parent = chip
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 205, 64)
	stroke.Thickness = 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = chip
	chip.Parent = gui
	label = chip
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local revealed = false
	local joined = time()
	task.spawn(function()
		while gui.Parent do
			local left = DoubleEvent.left(cfg, now())
			gui.Enabled = left > 0
			if left > 0 then
				chip.Text = "2X"
				if not revealed and time() - joined >= DoubleEventChip.REVEAL_AFTER then
					revealed = true
					pcall(function()
						(require(script.Parent:WaitForChild("Notify")) :: any).say("reward", "2X EVENT: every KO counts double and BOLTS are doubled for 48 hours!", Color3.fromRGB(255, 200, 60), "doubleEvent")
					end)
				end
			elseif now() >= (cfg :: any).to then
				gui:Destroy() -- (over: gone for this visit)
				break
			end
			task.wait(1)
		end
	end)
end

return DoubleEventChip
