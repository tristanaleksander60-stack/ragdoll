--!strict
-- IconCount (V11 A2, owner 22 Nov 2026: "no pop-ups, only (1), (2) on the icons; only events tell you"). What used
-- to pop up by itself now adds to a red round counter on the icon it belongs to (Rewards = the gift, Weapons =
-- the WEAPONS button). It clears when that window opens. A key can also carry a "!" (an egg waiting on the
-- gift), which stays until the thing is done.
--   IconCount.bump(key)            one more
--   IconCount.bang(key, on)        a "!" on / off
--   IconCount.attach(key, gui)     draw the counter on this button (several buttons per key are fine)
--   IconCount.count(key) / has(key)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IconCount = {}

IconCount.WINDOWS = { Rewards = "Rewards", Weapons = "Tools" } :: { [string]: string }
IconCount.RED = Color3.fromRGB(225, 40, 46)

local counts: { [string]: number } = {}
local bangs: { [string]: boolean } = {}
local targets: { [string]: { GuiObject } } = {}
local started = false

local function draw(key: string)
	local n = counts[key] or 0
	local bang = bangs[key] == true
	for _, gui in targets[key] or {} do
		if gui.Parent then
			local dot = gui:FindFirstChild("IconCount") :: Frame?
			if not dot then
				local f = Instance.new("Frame")
				f.Name = "IconCount"
				f.AnchorPoint = Vector2.new(0.5, 0.5)
				f.Position = UDim2.new(1, -4, 0, 4)
				f.Size = UDim2.fromOffset(22, 22)
				f.BackgroundColor3 = IconCount.RED
				f.ZIndex = 30
				local c = Instance.new("UICorner")
				c.CornerRadius = UDim.new(1, 0)
				c.Parent = f
				local s = Instance.new("UIStroke")
				s.Color = Color3.new(1, 1, 1)
				s.Thickness = 2
				s.Parent = f
				local t = Instance.new("TextLabel")
				t.Name = "N"
				t.BackgroundTransparency = 1
				t.Size = UDim2.fromScale(1, 1)
				t.Font = Enum.Font.BuilderSansBold
				t.TextScaled = true
				t.TextColor3 = Color3.new(1, 1, 1)
				t.ZIndex = 31
				t.Parent = f
				f.Parent = gui
				dot = f
			end
			local d = dot :: Frame
			d.Visible = bang or n > 0
			local label = d:FindFirstChild("N") :: TextLabel?
			if label then
				label.Text = if bang then "!" elseif n > 9 then "9+" else tostring(n)
			end
		end
	end
end

local function start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		local Controller = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIController")) :: any
		while true do
			task.wait(0.4)
			for key, window in IconCount.WINDOWS do
				if (counts[key] or 0) > 0 and Controller.isOpen(window) then
					counts[key] = 0
					draw(key)
				end
			end
		end
	end)
end

function IconCount.bump(key: string)
	start()
	counts[key] = (counts[key] or 0) + 1
	draw(key)
end

function IconCount.bang(key: string, on: boolean)
	if (bangs[key] == true) == on then
		return
	end
	bangs[key] = on
	draw(key)
end

function IconCount.attach(key: string, gui: GuiObject)
	start()
	local list = targets[key]
	if not list then
		list = {}
		targets[key] = list
	end
	if not table.find(list, gui) then
		table.insert(list, gui)
	end
	draw(key)
end

function IconCount.count(key: string): number
	return counts[key] or 0
end

function IconCount.has(key: string): boolean
	return bangs[key] == true
end

return IconCount
