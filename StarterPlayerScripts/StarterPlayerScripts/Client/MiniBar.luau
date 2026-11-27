--!strict
-- F71 (owner: "Gør så hotbaren er mindre på telefon, indtil du trykker på den og så bliver den forstørret og så kan du
-- vælge våben"; Config.PHONE_MINI_BAR): on a PHONE (touch, the short screen side 500 px or less, not a gamepad) the
-- hotbar (PokeController's ToyBar.Bar, anchored bottom centre) rests at 0.6 size. One tap anywhere on it (an invisible
-- button a bit bigger than the small bar, never firing or equipping) opens it to today's size in 0.15 s with a small
-- spring; the slots then work as today. It shrinks again 0.35 s after a tap on it (a weapon picked), after 4 s with no
-- tap, on a touch anywhere else (that touch still works: nothing is sunk) or when a window opens. A new slot (a new
-- weapon) opens it for 1.5 s. iPad, PC and gamepad keep today's bar. Only the UIScale is tweened.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local MiniBar = {}

MiniBar.SMALL = 0.75 -- (AUDIT 24: the slots stay at least 44 px at rest)
MiniBar.IDLE = 4

local function isPhone(): boolean
	local camera = workspace.CurrentCamera
	local v = if camera then camera.ViewportSize else Vector2.new(1000, 1000)
	local pad = string.sub(UserInputService:GetLastInputType().Name, 1, 7) == "Gamepad"
	return UserInputService.TouchEnabled and math.min(v.X, v.Y) <= 500 and not pad
end

function MiniBar.start()
	if not Config.PHONE_MINI_BAR then
		return
	end
	task.spawn(function()
		local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
		local gui = pg:WaitForChild("ToyBar", 60)
		local bar = gui and gui:WaitForChild("Bar", 30)
		if not (gui and bar and bar:IsA("GuiObject")) then
			return
		end
		local Controller = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIController")) :: any
		local scale = Instance.new("UIScale")
		scale.Name = "MiniScale"
		scale.Parent = bar
		local hit = Instance.new("TextButton")
		hit.Name = "MiniHit"
		hit.Text = ""
		hit.BackgroundTransparency = 1
		hit.AnchorPoint = Vector2.new(0.5, 1)
		hit.ZIndex = 50
		hit.Parent = gui
		local open = false
		local lastTap = 0
		local tween: Tween? = nil
		local function to(s: number, spring: boolean)
			if tween then
				tween:Cancel()
			end
			tween = TweenService:Create(scale, TweenInfo.new(0.15, if spring then Enum.EasingStyle.Back else Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = s })
			;(tween :: Tween):Play()
		end
		local function place()
			-- the tap target: the small bar, 8 px wider each side and at least 48 px high
			local size = bar.AbsoluteSize -- (already scaled)
			hit.Size = UDim2.fromOffset(size.X + 16, math.max(48, size.Y + 8))
			hit.Position = bar.Position
		end
		-- (AUDIT 24 rest: icons only at rest. The slot names, not the short key numbers, hide while the bar is small)
		local hidden = setmetatable({}, { __mode = "k" }) :: any
		local function names(show: boolean)
			if show then
				for l in hidden do
					l.Visible = true
				end
				table.clear(hidden)
				return
			end
			for _, d in bar:GetDescendants() do
				if d:IsA("TextLabel") and d.Visible and #d.Text > 2 and d:FindFirstAncestor("Slots") then
					hidden[d] = true
					d.Visible = false
				end
			end
		end
		local function close()
			open = false
			if isPhone() then
				to(MiniBar.SMALL, false)
				hit.Visible = true
				names(false)
			end
		end
		local function openIt()
			open = true
			lastTap = os.clock()
			hit.Visible = false
			names(true)
			to(1, true)
		end
		hit.Activated:Connect(openIt)
		bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
		bar:GetPropertyChangedSignal("Position"):Connect(place)
		-- a touch: on the open bar it is a pick (shrink a moment later); anywhere else it closes the bar (and still works)
		UserInputService.InputBegan:Connect(function(input)
			if not open or input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local inside = false
			for _, o in pg:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y) do
				if o == bar or o:IsDescendantOf(bar) then
					inside = true
					break
				end
			end
			if inside then
				lastTap = os.clock()
				task.delay(1.5, function() -- (AUDIT 24: it stays open 1.5 s after a pick)
					if open and os.clock() - lastTap >= 0.3 then
						close()
					end
				end)
			else
				close()
			end
		end)
		-- a new slot: open for 1.5 s
		local slots = 0
		local function countSlots(): number
			local n = 0
			for _, d in bar:GetDescendants() do
				if d:IsA("GuiObject") and d.Parent and d.Parent.Name == "Slots" then
					n += 1
				end
			end
			return n
		end
		slots = countSlots()
		task.spawn(function()
			while bar.Parent do
				task.wait(0.25)
				local phone = isPhone()
				if not phone then
					-- (iPad, PC, a pad: today's bar)
					if scale.Scale ~= 1 then
						scale.Scale = 1
					end
					hit.Visible = false
					open = false
					names(true)
					continue
				end
				if not open and not hit.Visible then
					close()
				elseif not open then
					names(false) -- (a slot added while small)
				end
				if open then
					local window = Controller.getCurrent and Controller.getCurrent() ~= nil
					if window or os.clock() - lastTap > MiniBar.IDLE then
						close()
					end
				end
				local n = countSlots()
				if n > slots and not open then
					openIt()
					lastTap = os.clock() - MiniBar.IDLE + 1.5
				end
				slots = n
				place()
			end
		end)
		place()
		if isPhone() then
			scale.Scale = MiniBar.SMALL
			hit.Visible = true
			names(false)
		else
			hit.Visible = false
		end
	end)
end

return MiniBar
