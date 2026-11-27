--!strict
-- HighlightCap (LAG-FREE 2 item 5, Config.LAGFREE_HIGHLIGHT; PERF_MOBILE §6). Every visible Highlight costs a full
-- extra screen pass (heavy on a phone, worst on an iPad's big screen); they are made in about 17 places. Rather than
-- change each one, this watches every Highlight in the place and keeps at most CAP of them drawn at once: phone 3,
-- tablet 5, PC 10. Priority: what you hold or grab, then the X-ray bones, then the dog, then glows and hints; one off
-- screen is not drawn. It only turns back on what it turned off itself (the attribute CapOff), so a system that
-- switches its own Highlight off keeps it off.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local HighlightCap = {}

local all: { [Highlight]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function capNow(): number
	local dev = tostring(Players.LocalPlayer:GetAttribute("Device"))
	if dev == "phone" then
		return 3
	elseif dev == "tablet" then
		return 5
	elseif dev == "pc" or dev == "console" then
		return 10
	end
	return if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then 3 else 10
end

local function rank(h: Highlight): number
	local path = h:GetFullName()
	if string.find(path, "Grab", 1, true) or string.find(path, "Held", 1, true) then
		return 1
	elseif string.find(path, "Xray", 1, true) then
		return 2
	elseif string.find(path, "Dog", 1, true) or string.find(path, "GuardDog", 1, true) then
		return 3
	end
	return 4
end

local function where(h: Highlight): Vector3?
	local a = h.Adornee or h.Parent
	if a and a:IsA("BasePart") then
		return a.Position
	elseif a and a:IsA("Model") then
		return a:GetPivot().Position
	end
	return nil
end

local function step()
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end
	local list: { { h: Highlight, r: number } } = {}
	for h in all do
		if h.Parent == nil then
			all[h] = nil
		elseif h.Enabled or h:GetAttribute("CapOff") == true then
			local at = where(h)
			local onScreen = false
			if at then
				local _, vis = cam:WorldToViewportPoint(at)
				onScreen = vis
			end
			if onScreen then
				table.insert(list, { h = h, r = rank(h) })
			elseif h.Enabled then
				h.Enabled = false
				h:SetAttribute("CapOff", true)
			end
		end
	end
	table.sort(list, function(a, b)
		return a.r < b.r
	end)
	local cap = capNow()
	for i, e in list do
		local h = e.h
		if i <= cap then
			if not h.Enabled and h:GetAttribute("CapOff") == true then
				h.Enabled = true
				h:SetAttribute("CapOff", nil)
			end
		elseif h.Enabled then
			h.Enabled = false
			h:SetAttribute("CapOff", true)
		end
	end
end

function HighlightCap.start()
	if not Config.LAGFREE_HIGHLIGHT then
		return
	end
	local function seen(d: Instance)
		if d:IsA("Highlight") then
			all[d] = true
		end
	end
	for _, root in { Workspace, Players.LocalPlayer:WaitForChild("PlayerGui") } :: { Instance } do
		for _, d in root:GetDescendants() do
			seen(d)
		end
		root.DescendantAdded:Connect(seen)
	end
	task.spawn(function()
		while true do
			task.wait(0.25)
			pcall(step)
		end
	end)
end

return HighlightCap
