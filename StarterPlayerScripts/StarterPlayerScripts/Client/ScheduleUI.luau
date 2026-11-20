--!strict
-- The calendar on this screen (round 3, M9; the server sets the Workspace attributes:
-- ScheduleService).
--   The weekly ADMIN SHOW: SHOP's SERVER EVENTS line counts down to it all week (ScheduleUI.line);
--   a toast 10, 5 and 1 minutes before, and when it starts.
--   The FREE WEEKEND: a toast when it starts (and on joining during it): which weapon is free.
--   The LAUNCH (the owner's free passes): a toast when it starts (and on joining during it).

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Schedule = require(Shared:WaitForChild("Schedule"))
local Toys = require(Shared:WaitForChild("Toys"))
local Notify = require(script.Parent:WaitForChild("Notify")) :: any -- V6-1

local ScheduleUI = {}

local GOLD = Color3.fromRGB(255, 205, 70)
local WARN_AT = { 600, 300, 60 } -- s before the show: a toast

local function clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local d = seconds // 86400
	local h = (seconds % 86400) // 3600
	local m = (seconds % 3600) // 60
	if d > 0 then
		return string.format("%dd %dh", d, h)
	elseif h > 0 then
		return string.format("%dh %02dm", h, m)
	end
	return string.format("%d:%02d", m, seconds % 60)
end

-- The line under SERVER EVENTS: when the next show is (this screen's own clock, its local time).
function ScheduleUI.line(): string
	local nowServer = Workspace:GetServerTimeNow()
	local start = Schedule.nextShow(nowServer)
	if nowServer >= start then
		return "THE ADMIN SHOW is on now: free events for everyone!"
	end
	local localTime = os.date("%a %H:%M", start) -- (this device's time zone)
	return string.format("THE ADMIN SHOW: free events for everyone, %s (in %s)", tostring(localTime), clock(start - nowServer))
end

function ScheduleUI.start()
	local told: { [string]: boolean } = {}
	local function weekend()
		local id = Workspace:GetAttribute("FreeWeapon")
		local toy = if type(id) == "string" then Toys.byId[id] else nil
		if toy and not told["free" .. id] then
			told["free" .. id] = true
			Notify.say("info", string.format("FREE THIS WEEKEND: the %s! Find it in WEAPONS", toy.label), Color3.fromRGB(120, 230, 140))
		end
	end
	Workspace:GetAttributeChangedSignal("FreeWeapon"):Connect(weekend)
	-- The launch: the passes' fun free for everyone for a while (the owner's choice: MoneyService).
	local function launch()
		local untilAt = Workspace:GetAttribute("PassesFreeUntil")
		if type(untilAt) == "number" and untilAt > Workspace:GetServerTimeNow() and not told["launch" .. untilAt] then
			told["launch" .. untilAt] = true
			Notify.say("info", "LAUNCH PARTY: ULTRA and faster eggs FREE for all until " .. tostring(os.date("%a %d %b", untilAt)) .. "!", GOLD)
		end
	end
	Workspace:GetAttributeChangedSignal("PassesFreeUntil"):Connect(launch)
	-- Round 4: the owner is in this server and gave everyone every weapon (AdminService): told when
	-- it starts (and on joining during it), and when it ends.
	local partyTold = false
	local function party()
		local on = Workspace:GetAttribute("OwnerParty") == true
		if on and not partyTold then
			partyTold = true
			Notify.say("info", "THE OWNER IS IN YOUR SERVER! Every weapon is yours while you play with them. Open WEAPONS!", Color3.fromRGB(255, 90, 90))
		elseif not on and partyTold then
			partyTold = false
			Notify.say("info", "The owner's free weapons have ended. Thanks for playing with them!")
		end
	end
	Workspace:GetAttributeChangedSignal("OwnerParty"):Connect(party)
	task.delay(8, function()
		weekend()
		launch()
		party()
	end) -- (after the first seconds' own messages)
	task.spawn(function()
		while true do
			task.wait(1)
			local at = Workspace:GetAttribute("AdminShowAt")
			if type(at) == "number" then
				local left = at - Workspace:GetServerTimeNow()
				for _, s in WARN_AT do
					local key = string.format("%d@%d", s, at)
					if left <= s and left > s - 30 and not told[key] then
						told[key] = true
						Notify.say("info", string.format("THE ADMIN SHOW starts in %d minute%s: free events for everyone!", s // 60, if s >= 120 then "s" else ""), GOLD)
					end
				end
				local key = "on@" .. at
				if left <= 0 and left > -30 and not told[key] then
					told[key] = true
					Notify.say("info", "THE ADMIN SHOW IS ON! Free events for everyone", GOLD)
				end
			end
		end
	end)
end

return ScheduleUI
