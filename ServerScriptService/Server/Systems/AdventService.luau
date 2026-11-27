--!strict
-- AUDIT 27 Nov 2: the CHRISTMAS ADVENT CALENDAR on the server (Config.ADVENT; Shared/Advent says the doors and rules).
-- Remote "Advent" (Net): client -> server "State" (send me the calendar) or "Open" (open today's door; no other
-- argument is read). The server decides everything: the UTC day, which door, that it was not opened today, the reward.
-- At most one call a second a player. The door is marked in eco.codes BEFORE the reward goes in, so a double tap
-- can never give it twice; the profile saves as usual. The player attribute AdventCan (true when a door waits) lights
-- the gift button (Client/AdventCalendar).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Advent = require(Shared:WaitForChild("Advent"))
local Net = require(Shared:WaitForChild("Net"))

local AdventService = {}

local last: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any
local nowForTest: number? = nil

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function now(): number
	return nowForTest or os.time()
end

function AdventService.setTimeForTest(t: number?)
	nowForTest = t
end

local function state(player: Player): { [string]: any }?
	local e = lazy("ProgressService").ecoOf(player)
	if not e then
		return nil
	end
	local day = Advent.dayOf(now())
	return { day = day or 0, opened = Advent.opened(e.codes), next = Advent.next(e.codes, day) or 0 }
end

local function refresh(player: Player)
	local s = state(player)
	player:SetAttribute("AdventCan", if s and s.next > 0 then true else nil)
	if s then
		Net.event(Net.Names.Advent):FireClient(player, "State", s)
	end
end

-- Opens today's door. Returns the door number, or nil and why.
function AdventService.open(player: Player): (number?, string?)
	local PS = lazy("ProgressService")
	local e = PS.ecoOf(player)
	if not e then
		return nil, "Your progress is still loading"
	end
	local day = Advent.dayOf(now())
	local n = Advent.next(e.codes, day)
	if not n or not day then
		return nil, "No door today. Come back tomorrow!"
	end
	local door = Advent.DOORS[n]
	e.codes[Advent.TAG .. n] = true
	e.codes[Advent.TAG .. "T" .. day] = true
	PS.ecoChanged(player)
	if door.bolts then
		pcall(function()
			lazy("EconomyService").give(player, door.bolts, nil, true)
		end)
	end
	if door.cosmetic and player:GetAttribute("Offer_" .. door.cosmetic) ~= true then
		local untilT = Workspace:GetServerTimeNow() + (door.hours or 72) * 3600
		e.perks[door.cosmetic] = math.max(e.perks[door.cosmetic] or 0, untilT)
		PS.ecoChanged(player)
		pcall(function()
			lazy("EconomyService").applyPerks(player)
		end)
	end
	if door.egg then
		pcall(PS.giveEgg, player, "ADVENT: a free weapon egg!")
	end
	pcall(function()
		lazy("EconomyService").send(player)
	end)
	return n, nil
end

function AdventService.start()
	local Config = require(Shared:WaitForChild("Config")) :: any
	if not Config.ADVENT then
		return
	end
	local remote = Net.event(Net.Names.Advent)
	remote.OnServerEvent:Connect(function(player: Player, kind: unknown)
		if typeof(kind) ~= "string" then
			return
		end
		local t = os.clock()
		if t - (last[player] or -math.huge) < 1 then
			return
		end
		last[player] = t
		if kind == "State" then
			refresh(player)
		elseif kind == "Open" then
			local n, why = AdventService.open(player)
			if n then
				remote:FireClient(player, "Opened", { door = n, text = Advent.DOORS[n].text })
			else
				remote:FireClient(player, "Refused", why or "")
			end
			refresh(player)
		end
	end)
	-- (the gift button's light: on join once the profile is in, and every 10 minutes for the day change)
	local function watch(player: Player)
		task.spawn(function()
			for _ = 1, 60 do
				if not player.Parent or lazy("ProgressService").ecoOf(player) then
					break
				end
				task.wait(2)
			end
			while player.Parent do
				refresh(player)
				task.wait(600)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
end

return AdventService
