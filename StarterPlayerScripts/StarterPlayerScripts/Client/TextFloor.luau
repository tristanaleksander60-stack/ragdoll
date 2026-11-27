--!strict
-- TextFloor (AUDIT 25 rest, Config.PHONE_TEXT_FLOOR): on a phone, no fixed-size text is shown smaller than 14 px.
-- Every TextLabel, TextButton and TextBox in the PlayerGui that is not TextScaled gets TextSize at least
-- ceil(14 / the product of its UIScales) when it appears. TextScaled text with a UITextSizeConstraint gets
-- MinTextSize at least 14. Phones only (touch, the short screen side 500 px or less); PC and iPad are untouched.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local TextFloor = {}
TextFloor.MIN = 14

local function isPhone(): boolean
	local camera = workspace.CurrentCamera
	local v = if camera then camera.ViewportSize else Vector2.new(1000, 1000)
	return UserInputService.TouchEnabled and math.min(v.X, v.Y) <= 500
end

local function scaleOf(o: Instance): number
	local s = 1
	local p: Instance? = o
	while p and not p:IsA("PlayerGui") do
		local u = p:FindFirstChildOfClass("UIScale")
		if u then
			s *= u.Scale
		end
		p = p.Parent
	end
	return math.max(s, 0.25)
end

local function fix(o: Instance)
	if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
		local t = o :: any
		if t.TextScaled then
			local c = o:FindFirstChildOfClass("UITextSizeConstraint")
			if c and c.MinTextSize < TextFloor.MIN and c.MaxTextSize >= TextFloor.MIN then
				c.MinTextSize = TextFloor.MIN
			end
		else
			local need = math.ceil(TextFloor.MIN / scaleOf(o))
			if t.TextSize < need and t.TextSize > 0 then
				t.TextSize = need
			end
		end
	end
end

function TextFloor.start()
	if not Config.PHONE_TEXT_FLOOR then
		return
	end
	task.spawn(function()
		task.wait(1)
		if not isPhone() then
			return
		end
		local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
		pg.DescendantAdded:Connect(function(o)
			task.defer(fix, o)
		end)
		for _, o in pg:GetDescendants() do
			fix(o)
		end
	end)
end

return TextFloor
