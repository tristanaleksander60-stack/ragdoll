--!strict
-- AUDIT 27 Nov 2: the CHRISTMAS ADVENT CALENDAR window (Config.ADVENT; Shared/Advent, Systems/AdventService).
-- 24 doors in a 6 x 4 grid: an open door shows its gift, the door you may open now glows gold and pulses, the rest
-- are shut (their gift is written small under the number, so the rewards are shown in advance). The gift button at
-- the top opens it while a door waits (player attribute AdventCan); a REWARDS button inside leads on to Rewards.
-- In December a short toast says a door is ready, once a visit.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents")) :: any
local Controller = require(UI:WaitForChild("LihFolkUIController")) :: any
local Theme = require(UI:WaitForChild("LihFolkUITheme")) :: any

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Advent = require(Shared:WaitForChild("Advent"))
local Net = require(Shared:WaitForChild("Net")) :: any

local Toast = require(script.Parent:WaitForChild("Toast")) :: any

local AdventCalendar = {}

AdventCalendar.WINDOW = Vector2.new(560, 470)
AdventCalendar.CELL = Vector2.new(78, 78)

local player = Players.LocalPlayer
local remote: RemoteEvent? = nil
local cells: { TextButton } = {}
local info: TextLabel? = nil
local current = { day = 0, opened = 0, next = 0 }
local pulse: Tween? = nil

local SHUT = Color3.fromRGB(150, 32, 40)
local OPEN = Color3.fromRGB(40, 110, 70)
local GOLD = Color3.fromRGB(255, 196, 50)

local function paint()
	if pulse then
		pulse:Cancel()
		pulse = nil
	end
	for i, b in cells do
		local door = Advent.DOORS[i]
		-- lihfolk-ignore: findfirstchild-chain (checked with `if small` below)
		local small = b:FindFirstChild("Gift") :: TextLabel?
		local stroke = b:FindFirstChildWhichIsA("UIStroke")
		if i <= current.opened then
			b.BackgroundColor3 = OPEN
			b.Text = door.glyph
			b.TextSize = 30
			if small then
				small.Text = "OPEN"
			end
			if stroke then
				stroke.Color = Color3.fromRGB(120, 230, 150)
			end
		elseif i == current.next then
			b.BackgroundColor3 = GOLD
			b.Text = tostring(i)
			b.TextSize = 30
			if small then
				small.Text = "OPEN ME!"
			end
			if stroke then
				stroke.Color = Color3.new(1, 1, 1)
				local t = TweenService:Create(stroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Thickness = 5 })
				t:Play()
				pulse = t
			end
		else
			b.BackgroundColor3 = SHUT
			b.Text = tostring(i)
			b.TextSize = 26
			if small then
				small.Text = door.glyph
			end
			if stroke then
				stroke.Color = Color3.fromRGB(255, 220, 120)
				stroke.Thickness = 2
			end
		end
	end
	local line = info
	if line then
		if current.day == 0 then
			line.Text = "The calendar opens on 1 December. 24 doors, a gift behind each one!"
		elseif current.next > 0 then
			local door = Advent.DOORS[current.next]
			line.Text = "Door " .. current.next .. " is ready: " .. door.text
		elseif current.opened >= #Advent.DOORS then
			line.Text = "Every door is open. Merry Christmas!"
		else
			line.Text = "Door " .. (current.opened + 1) .. " opens tomorrow: " .. Advent.DOORS[current.opened + 1].text
		end
	end
end

local function build()
	local window = C.Window({ name = "Advent", title = "Advent Calendar", theme = "daily", icon = "gift", size = AdventCalendar.WINDOW })
	local line = C.Text("body", "", { autoY = true, wrap = true, layoutOrder = 1, parent = window.body })
	info = line
	local grid = Instance.new("Frame")
	grid.Name = "Doors"
	grid.BackgroundTransparency = 1
	grid.LayoutOrder = 2
	grid.Size = UDim2.new(1, 0, 0, 4 * AdventCalendar.CELL.Y + 3 * 8 + 4)
	grid.Parent = window.body
	C.Grid(grid, AdventCalendar.CELL, 8)
	for i = 1, #Advent.DOORS do
		local b = Instance.new("TextButton")
		b.Name = "Door" .. i
		b.LayoutOrder = i
		b.AutoButtonColor = true
		b.BackgroundColor3 = SHUT
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Font = Enum.Font.FredokaOne
		b.TextSize = 26
		b.Text = tostring(i)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = b
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(255, 220, 120)
		stroke.Parent = b
		local small = Instance.new("TextLabel")
		small.Name = "Gift"
		small.BackgroundTransparency = 1
		small.AnchorPoint = Vector2.new(0.5, 1)
		small.Position = UDim2.new(0.5, 0, 1, -3)
		small.Size = UDim2.new(1, -6, 0, 16)
		small.Font = Enum.Font.GothamBold
		small.TextScaled = true
		small.TextColor3 = Color3.fromRGB(255, 240, 210)
		small.Text = Advent.DOORS[i].glyph
		small.Parent = b
		b.Activated:Connect(function()
			local r = remote
			if not r then
				return
			end
			if i == current.next then
				r:FireServer("Open")
			elseif i > current.opened then
				Toast.show(if current.day == 0 then "The calendar opens on 1 December" else "Door " .. i .. ": " .. Advent.DOORS[i].text .. " (one door a day)")
			end
		end)
		b.Parent = grid
		cells[i] = b
	end
	C.Button({
		text = "REWARDS",
		role = "neutral",
		size = UDim2.new(1, 0, 0, Theme.Size.buttonH),
		layoutOrder = 3,
		parent = window.body,
		onActivated = function()
			Controller.toggle("Advent")
			local HudV3 = require(script.Parent:WaitForChild("HudV3")) :: any
			if HudV3.openRewards then
				HudV3.openRewards()
			end
		end,
	})
	Controller.register(window)
	paint()
end

function AdventCalendar.start()
	if not Config.ADVENT then
		return
	end
	local r = Net.event(Net.Names.Advent)
	remote = r
	build()
	local told = false
	r.OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if kind == "State" and type(data) == "table" then
			local d = data :: any
			current.day = tonumber(d.day) or 0
			current.opened = tonumber(d.opened) or 0
			current.next = tonumber(d.next) or 0
			paint()
			if current.next > 0 and not told then
				told = true
				task.delay(20, function()
					Toast.show("\u{1F384} Advent calendar: door " .. current.next .. " is ready! Tap the gift at the top", GOLD)
				end)
			end
		elseif kind == "Opened" and type(data) == "table" then
			Toast.show("\u{1F381} Door " .. tostring((data :: any).door) .. ": " .. tostring((data :: any).text), GOLD)
		elseif kind == "Refused" and type(data) == "string" and data ~= "" then
			Toast.show(data)
		end
	end)
	-- the gift button opens the calendar while a door waits (else Rewards, as before)
	local HudV3 = require(script.Parent:WaitForChild("HudV3")) :: any
	HudV3.giftHook = function(): boolean
		if player:GetAttribute("AdventCan") == true then
			Controller.open("Advent")
			r:FireServer("State")
			return true
		end
		return false
	end
	r:FireServer("State")
end

return AdventCalendar
