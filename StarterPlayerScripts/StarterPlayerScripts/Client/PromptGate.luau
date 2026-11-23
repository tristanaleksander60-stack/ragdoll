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
-- (A thing whose own screen takes the click (the Map Board picks the tile under it): its prompt gets no click of its own,
-- E (USE) and a pad still press it.)
PromptGate.NO_CLICK = table.freeze({ MapBoardPrompt = true }) :: { [string]: boolean }

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

-- (Owner, 21 Nov 2026: "close up you cannot press anything, and not with both mouse buttons". Roblox's ClickDetector
-- missed close up (your own avatar stood between the camera and the screen) and took either button. PromptGate's
-- own click: the LEFT button or a tap, the ray from the pointer (the screen's middle in first person or shift lock)
-- tested against the registered things themselves, so nothing in front of them, your avatar included, blocks it.)
type Clickable = { fn: (Vector3) -> (), reach: number }
local clickables: { [BasePart]: Clickable } = {}

-- A thing this screen's left click or tap presses: fn gets the point clicked; only within reach of your body.
function PromptGate.register(part: BasePart, fn: (Vector3) -> (), reach: number)
	clickables[part] = { fn = fn, reach = reach }
	part.Destroying:Once(function()
		clickables[part] = nil
	end)
end

-- Where a ray meets a part's box (studs along the ray), or nil.
local function hitBox(part: BasePart, origin: Vector3, dir: Vector3): number?
	local o = part.CFrame:PointToObjectSpace(origin)
	local d = part.CFrame:VectorToObjectSpace(dir)
	local half = part.Size / 2
	local tMin, tMax = -math.huge, math.huge
	for _, axis in { "X", "Y", "Z" } do
		local oa, da, h = (o :: any)[axis], (d :: any)[axis], (half :: any)[axis]
		if math.abs(da) < 1e-6 then
			if oa < -h or oa > h then
				return nil
			end
		else
			local t1, t2 = (-h - oa) / da, (h - oa) / da
			tMin = math.max(tMin, math.min(t1, t2))
			tMax = math.min(tMax, math.max(t1, t2))
		end
	end
	if tMax < math.max(tMin, 0) then
		return nil
	end
	return math.max(tMin, 0)
end

local function clickAt(input: InputObject)
	local camera = Workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (camera and root and root:IsA("BasePart")) then
		return
	end
	local ray = if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter and input.UserInputType ~= Enum.UserInputType.Touch
		then camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
		else camera:ScreenPointToRay(input.Position.X, input.Position.Y) -- (where the pointer is, or the finger went down)
	local best: Clickable? = nil
	local bestT = math.huge
	for part, c in clickables do
		if part.Parent and (root.Position - part.Position).Magnitude <= c.reach then
			local at = hitBox(part, ray.Origin, ray.Direction)
			if at and at < bestT then
				best, bestT = c, at
			end
		end
	end
	if best then
		best.fn(ray.Origin + ray.Direction * bestT)
	end
end
-- (23 Nov 2026, bug: on a phone every finger that went down counted as a press, the thumb on the walking stick and a turn
-- of the camera too, so by the arms' stand walking away took the arms off again. A finger presses a thing only with a
-- short tap that stays where it is and is not on the stick.)
local TAP_TIME, TAP_MOVE = 0.4, 16
local downs: { [InputObject]: { at: Vector2, t: number } } = {}
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		clickAt(input)
	elseif input.UserInputType == Enum.UserInputType.Touch then
		local okS, onStick = pcall(function()
			return (require(script.Parent:WaitForChild("MoveStick")) :: any).has(input)
		end)
		if not (okS and onStick) then
			downs[input] = { at = Vector2.new(input.Position.X, input.Position.Y), t = os.clock() }
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	local down = downs[input]
	downs[input] = nil
	if down and os.clock() - down.t <= TAP_TIME and (Vector2.new(input.Position.X, input.Position.Y) - down.at).Magnitude <= TAP_MOVE then
		clickAt(input)
	end
end)

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
	if clickables[part] and not existing then
		return -- (a second prompt on the same thing, a booth's Buy beside its Try: the click is the first one's;
		-- this one stays shown as a single press, never a hold)
	end
	local e: Entry = { prompt = p, key = p.KeyboardKeyCode, style = p.Style, exclusivity = p.Exclusivity, click = nil }
	entries[p] = e
	if existing or PromptGate.NO_CLICK[p.Name] then
		-- (The thing is clickable already, a terminal's button: its own click does the job; nothing doubled.)
	else
		-- (This screen's left clicks and taps on the thing: PromptGate's own click, below.)
		PromptGate.register(part, function()
			press(p)
		end, p.MaxActivationDistance + PromptGate.EXTRA_REACH)
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
	-- (Owner, 21 Nov 2026: "keybinds on everything, so you never leave first person": USE (E) presses the nearest
	-- thing in reach, a terminal, a board, a button or a booth, with no aiming; never in the lab view or building.)
	local Keybinds = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Keybinds")) :: any
	UserInputService.InputBegan:Connect(function(input, processed)
		if not Keybinds.live(processed) or input.UserInputType ~= Enum.UserInputType.Keyboard or not Keybinds.is("Use", input.KeyCode) then
			return
		end
		local Client = script.Parent
		local okView, lab = pcall(function()
			return (require(Client:WaitForChild("ViewMode")) :: any).isLab()
		end)
		local okBuild, building = pcall(function()
			return (require(Client:WaitForChild("BuildController")) :: any).isActive()
		end)
		if (okView and lab) or (okBuild and building) then
			return
		end
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return
		end
		local best: ProximityPrompt? = nil
		local bestDist = math.huge
		for p in entries do
			local part = partOf(p)
			if p.Enabled and part then
				local d = (root.Position - part.Position).Magnitude
				if d <= p.MaxActivationDistance + PromptGate.EXTRA_REACH and d < bestDist then
					best, bestDist = p, d
				end
			end
		end
		if best then
			press(best)
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
