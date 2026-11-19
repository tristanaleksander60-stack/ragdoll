--!strict
-- The clock to the next free gift for time played (PlaytimeGifts on the server, 10 Nov 2026): a gold
-- tag on the WEAPONS tile ("🎁 1:42", READY! while it waits for room among the eggs), and once a
-- visit, as soon as the first minute is over, one line saying what it is. The gift itself comes from
-- the server as an egg (ProgressUI then offers to open it). Draws only what the server set:
-- GiftAt (server time the next gift is due) and GiftLeft on the player.

local Players = game:GetService("Players")

local Client = script.Parent
local PokeController = require(Client:WaitForChild("PokeController"))
local OnboardingController = require(Client:WaitForChild("OnboardingController"))
local Toast = require(Client:WaitForChild("Toast"))

local GiftClock = {}

GiftClock.INTRO_AFTER = 7 -- s after the first minute's unlock (after its own toast)
GiftClock.TAG_WIDTH = 72 -- px (the tile is 64)

local player = Players.LocalPlayer

-- The tag's text for this many seconds left (nil: no tag).
function GiftClock.text(left: number?): string?
	if left == nil then
		return nil
	end
	if left <= 0 then
		return "GIFT!"
	end
	local s = math.ceil(left)
	return string.format("GIFT %d:%02d", s // 60, s % 60)
end

local function secondsLeft(): number?
	local at = player:GetAttribute("GiftAt")
	if typeof(at) ~= "number" then
		return nil
	end
	return (at :: number) - workspace:GetServerTimeNow()
end

function GiftClock.start()
	task.spawn(function()
		local shown: string? = "-"
		while true do
			local hud = PokeController.weaponsHud
			local text = GiftClock.text(secondsLeft())
			if hud and text ~= shown then
				shown = text
				hud.setTag(text)
				-- (A little wider than the kit's clock pill: "GIFT 12:34" fits; the column has room.)
				local tag = hud.root:FindFirstChild("Tag")
				if tag and tag:IsA("TextLabel") then
					tag.Size = UDim2.fromOffset(GiftClock.TAG_WIDTH, 15)
				end
			end
			task.wait(0.5)
		end
	end)
	OnboardingController.whenFree(function()
		task.wait(GiftClock.INTRO_AFTER)
		local left = secondsLeft()
		if left and left > 5 then
			local minutes = math.max(1, math.ceil(left / 60))
			Toast.show(string.format("\u{1F381} Play %d more min for a FREE weapon egg! The clock is on WEAPONS.", minutes), Color3.fromRGB(255, 210, 74))
		end
	end)
end

return GiftClock
