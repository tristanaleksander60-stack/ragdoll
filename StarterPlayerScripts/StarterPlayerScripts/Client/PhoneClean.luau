--!strict
-- F6 (owner, 26 Nov 2026: "telefon UI kun viser det nødvendige"; Config.PHONE_CLEAN): on a touch screen only what is
-- needed shows. Kept: the joystick, jump, SHOOT, the hotbar, Shop / Multiplayer / Menu on the left, the goal line,
-- the gift clock, X-RAY and the context buttons while they apply (TRY, SLAM, dog, RELOAD only when low: TouchShoot).
-- Hidden here: the key chips and slot numbers on the hotbar (no keys on a phone), the body-card arrow and the
-- first-person camera button (both in Menu > Settings on a phone). Looked at once a second, so new pieces follow.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local PhoneClean = {}

PhoneClean.HIDE_GUIS = { "BodyCardArrow", "FirstPersonTouch" }
PhoneClean.HIDE_NAMES = { KeyChip = true, Number = true }
PhoneClean.HIDE_EVERYWHERE = { KeyChip = true, Key = true } -- (F70: no key letter on any HUD button on a touch screen)

function PhoneClean.start()
	if not Config.PHONE_CLEAN then
		return
	end
	local ViewMode = require(script.Parent:WaitForChild("ViewMode")) :: any
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	task.spawn(function()
		while true do
			if ViewMode.isTouch() then
				for _, name in PhoneClean.HIDE_GUIS do
					local g = pg:FindFirstChild(name)
					if g and g:IsA("ScreenGui") and g.Enabled then
						g.Enabled = false
					end
				end
				local bar = pg:FindFirstChild("ToyBar")
				if bar then
					for _, d in bar:GetDescendants() do
						if PhoneClean.HIDE_NAMES[d.Name] and d:IsA("GuiObject") and d.Visible then
							d.Visible = false
						end
					end
				end
			end
			task.wait(1)
		end
	end)
	-- (F70, Config.PHONE_NO_KEYS: on any touch screen no key letter anywhere on the HUD; every 3 s, cheap)
	if Config.PHONE_NO_KEYS then
		local UserInputService = game:GetService("UserInputService")
		task.spawn(function()
			while true do
				if UserInputService.TouchEnabled then
					for _, d in pg:GetDescendants() do
						if PhoneClean.HIDE_EVERYWHERE[d.Name] and d:IsA("TextLabel") and d.Visible then
							d.Visible = false
						end
					end
				end
				task.wait(3)
			end
		end)
	end
end

return PhoneClean
