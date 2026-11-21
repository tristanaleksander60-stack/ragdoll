--!strict
-- V9-NOW 24 (owner, 21 Nov 2026: "no hold E anywhere; press the computer itself"). On this screen, for every
-- ProximityPrompt in the world:
--   * never a hold (HoldDuration 0);
--   * a mouse or a finger: no floating "E" panel and no E key; the thing itself is pressed (a click or a tap on
--     the part the prompt sits on, within its reach), which fires that very prompt (InputHoldBegin/End), so every
--     handler on the server or here stays as it was;
--   * a pad: the prompt shows as a single press of its pad button (nothing to click with a stick);
--   * KEEP: where there is nothing to click (getting into a car, Talk) the E stays, one press.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local PromptGate = {}

PromptGate.KEEP = table.freeze({ Drive = true, TalkPrompt = true }) :: { [string]: boolean }
PromptGate.EXTRA_REACH = 4 -- studs a click may come from past the prompt's own reach

type Entry = { prompt: ProximityPrompt, key: Enum.KeyCode, style: Enum.ProximityPromptStyle, exclusivity: Enum.ProximityPromptExclusivity, click: ClickDetector? }
local entries: { [ProximityPrompt]: Entry } = {}
local padMode = false

local function isPad(): boolean
	return string.find(UserInputService:GetLastInputType().Name, "Gamepad", 1, true) ~= nil
end

local function apply(e: Entry)
	local p = e.prompt
	p.HoldDuration = 0
	if padMode then
		p.Style = e.style
		p.KeyboardKeyCode = e.key
		p.Exclusivity = e.exclusivity
	else
		p.Style = Enum.ProximityPromptStyle.Custom -- (nothing drawn: no "E" panel)
		p.KeyboardKeyCode = Enum.KeyCode.Unknown
		-- (Every one in reach stays live, so a click on any of them presses it: one shared key would leave only the
		-- nearest one shown and pressable.)
		p.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	end
end

-- The part a click or a tap presses: the prompt's own part (or an attachment's).
local function partOf(p: ProximityPrompt): BasePart?
	local parent = p.Parent
	if parent and parent:IsA("Attachment") then
		parent = parent.Parent
	end
	return if parent and parent:IsA("BasePart") then parent else nil
end

local function press(p: ProximityPrompt)
	if not p.Enabled or not p.Parent then
		return
	end
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local part = partOf(p)
	if not (root and root:IsA("BasePart") and part) then
		return
	end
	if (root.Position - part.Position).Magnitude > p.MaxActivationDistance + PromptGate.EXTRA_REACH then
		return
	end
	pcall(function()
		p:InputHoldBegin()
		p:InputHoldEnd()
	end)
end

local function add(p: ProximityPrompt)
	if entries[p] then
		return
	end
	p.HoldDuration = 0
	if PromptGate.KEEP[p.Name] then
		return -- (E, one press: nothing to click there)
	end
	local part = partOf(p)
	if not part then
		return -- (nothing to click: it stays shown as a single press)
	end
	local existing = part:FindFirstChildOfClass("ClickDetector")
	if existing and existing.Name == "PromptGateClick" then
		return -- (a second prompt on the same thing, a booth's Buy beside its Try: the click is the first one's;
		-- this one stays shown as a single press, never a hold)
	end
	local e: Entry = { prompt = p, key = p.KeyboardKeyCode, style = p.Style, exclusivity = p.Exclusivity, click = nil }
	entries[p] = e
	if existing then
		-- (The thing is clickable already, a terminal's button: its own click does the job; nothing doubled.)
	elseif part then
		-- (A local detector: this screen's clicks and taps on the thing.)
		local c = Instance.new("ClickDetector")
		c.Name = "PromptGateClick"
		c.MaxActivationDistance = p.MaxActivationDistance + PromptGate.EXTRA_REACH
		c.Parent = part
		e.click = c
		c.MouseClick:Connect(function()
			press(p)
		end)
	end
	apply(e)
	p.Destroying:Once(function()
		entries[p] = nil
	end)
end

-- Tests: how many prompts this screen gates, and whether pads see them now.
function PromptGate.counts(): (number, boolean)
	local n = 0
	for _ in entries do
		n += 1
	end
	return n, padMode
end

function PromptGate.start()
	padMode = isPad()
	for _, d in Workspace:GetDescendants() do
		if d:IsA("ProximityPrompt") then
			add(d)
		end
	end
	Workspace.DescendantAdded:Connect(function(d)
		if d:IsA("ProximityPrompt") then
			task.defer(add, d) -- (after its maker set its name, keys and style)
		end
	end)
	UserInputService.LastInputTypeChanged:Connect(function()
		local now = isPad()
		if now ~= padMode then
			padMode = now
			for _, e in entries do
				apply(e)
			end
		end
	end)
end

return PromptGate
