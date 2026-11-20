--!strict
-- V6-2: the tools behind the owner's tabbed admin menu (Client/AdminPanel). AdminService checks
-- that the caller is the owner and paces them, then hands the kinds below to AdminTools.run.
-- Every argument is a fixed choice (no free text reaches the world), every action is logged, and
-- nothing writes to a DataStore.
--   Server:  Event id | Gravity g | Clock name | Weather name | Announce id | Kick { target, reason }
--   Players: Goto target | Bring target | Trial { target, weapon }
--   World:   ResetLab target | ReviveAll | Spawn { count, shape } | Crowd delta | ClearDummies
--   Debug:   Debug (the server's numbers back to the owner)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local LogService = game:GetService("LogService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Events = require(Shared:WaitForChild("Events"))
local Toys = require(Shared:WaitForChild("Toys"))
local Systems = script.Parent

local AdminTools = {}

-- The fixed choices the menu offers (the client draws its buttons from these too: Shared copy in
-- the client is AdminPanel's own list; the server only ever accepts these).
AdminTools.GRAVITY = table.freeze({ 196.2, 120, 60, 25 })
AdminTools.CLOCK = table.freeze({ Day = 14.6, Morning = 8, Sunset = 17.4, Night = 0.5 })
AdminTools.WEATHER = table.freeze({ Clear = true, Rain = true, Snow = true, Fog = true })
AdminTools.ANNOUNCE = table.freeze({
	Hello = "The owner says hi! Have fun smashing dummies",
	Event = "An event is coming in a moment: get ready!",
	Party = "Owner party! Everyone come to the plaza",
	Thanks = "Thanks for playing Ragdoll Havoc! Favorite the game to see updates",
	Restart = "This server restarts soon for an update. Rejoin in a minute!",
})
AdminTools.KICK = table.freeze({
	Rude = "Please be kind to other players.",
	Spam = "Please don't spam.",
	Exploit = "Cheating is not allowed.",
	Update = "The server is restarting for an update. Rejoin in a minute!",
})
AdminTools.SPAWN_COUNTS = table.freeze({ 1, 5, 10 })
AdminTools.SHAPES = table.freeze({ Row = true, Ring = true, Tower = true })
AdminTools.CROWD_MAX = 40

local errors: { string } = {} -- the server's last errors (Debug tab)
local beats = { n = 0, t0 = os.clock(), fps = 60 }

local function lazy(name: string): any
	return require(Systems:WaitForChild(name)) :: any
end

local function rootOf(p: Player?): BasePart?
	local c = p and p.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r else nil
end

local function targetOf(arg: unknown): Player?
	local id = if type(arg) == "table" then (arg :: any).target else arg
	return if type(id) == "number" then Players:GetPlayerByUserId(id) else nil
end

-- Positions for `count` dummies in a shape in front of `at` (facing `look`).
function AdminTools.layout(shape: string, count: number, at: Vector3, look: Vector3): { Vector3 }
	local out = {}
	local fwd = Vector3.new(look.X, 0, look.Z)
	fwd = if fwd.Magnitude > 0.01 then fwd.Unit else Vector3.new(0, 0, -1)
	local right = fwd:Cross(Vector3.yAxis)
	local centre = at + fwd * 14
	for i = 1, count do
		if shape == "Ring" then
			local a = (i / count) * math.pi * 2
			table.insert(out, centre + (right * math.cos(a) + fwd * math.sin(a)) * 8)
		elseif shape == "Tower" then
			table.insert(out, centre + Vector3.new(0, (i - 1) * 6, 0))
		else
			table.insert(out, centre + right * ((i - (count + 1) / 2) * 4))
		end
	end
	return out
end

-- Runs one admin tool. Returns (done, what the server log says, what the owner's log shows, a
-- notice for the owner's screen).
function AdminTools.run(by: Player, kind: string, arg: unknown): (boolean, string?, string?, string?)
	local who = string.format("%s (%d)", by.Name, by.UserId)
	if kind == "Event" then
		if type(arg) ~= "string" or not Events.byId[arg] then
			return false
		end
		local EventService = lazy("EventService")
		local place = EventService.trigger(arg, by.DisplayName, "Free", true, nil, by.UserId)
		if not place then
			return false, nil, nil, "That event could not start now"
		end
		return true, who .. " started " .. arg, by.DisplayName .. " started " .. arg
	elseif kind == "Gravity" then
		if not table.find(AdminTools.GRAVITY, arg) then
			return false
		end
		Workspace.Gravity = arg :: number
		Workspace:SetAttribute("AdminGravity", if arg == 196.2 then nil else arg)
		return true, who .. " set gravity " .. tostring(arg), "Gravity " .. tostring(arg)
	elseif kind == "Clock" then
		if arg ~= "Auto" and (type(arg) ~= "string" or AdminTools.CLOCK[arg] == nil) then
			return false
		end
		Workspace:SetAttribute("AdminClock", if arg == "Auto" then nil else AdminTools.CLOCK[arg :: string])
		return true, who .. " set the time " .. tostring(arg), "Time: " .. tostring(arg)
	elseif kind == "Weather" then
		if type(arg) ~= "string" or not AdminTools.WEATHER[arg] then
			return false
		end
		Workspace:SetAttribute("AdminWeather", if arg == "Clear" then nil else arg)
		return true, who .. " set the weather " .. arg, "Weather: " .. arg
	elseif kind == "Announce" then
		local text = if type(arg) == "string" then AdminTools.ANNOUNCE[arg] else nil
		if not text then
			return false
		end
		local ProgressService = lazy("ProgressService")
		for _, p in Players:GetPlayers() do
			ProgressService.notice(p, "\u{1F4E2} " .. text)
		end
		return true, who .. " announced " .. tostring(arg), "Announced: " .. text
	elseif kind == "Kick" then
		local target = targetOf(arg)
		local reason = if type(arg) == "table" and type((arg :: any).reason) == "string" then AdminTools.KICK[(arg :: any).reason] else nil
		if not target or not reason then
			return false
		end
		if target == by then
			return false, nil, nil, "You can't kick yourself"
		end
		local name, id = target.Name, target.UserId
		target:Kick(reason)
		return true, string.format("%s kicked %s (%d): %s", who, name, id, reason), "Kicked " .. name
	elseif kind == "Goto" or kind == "Bring" then
		local target = targetOf(arg)
		local a, b = rootOf(by), rootOf(target)
		if not target or not a or not b then
			return false, nil, nil, "That player has no body right now"
		end
		if kind == "Goto" then
			(by.Character :: Model):PivotTo(b.CFrame * CFrame.new(0, 0, 5))
		else
			(target.Character :: Model):PivotTo(a.CFrame * CFrame.new(0, 0, -5))
		end
		return true, string.format("%s %s %s (%d)", who, if kind == "Goto" then "went to" else "brought", target.Name, target.UserId), (if kind == "Goto" then "Went to " else "Brought ") .. target.DisplayName
	elseif kind == "Trial" then
		local target = targetOf(arg)
		local weapon = if type(arg) == "table" then (arg :: any).weapon else nil
		if not target or type(weapon) ~= "string" or not Toys.byId[weapon] then
			return false
		end
		if not lazy("TrialService").grant(target, weapon) then
			return false, nil, nil, "That weapon has no free try"
		end
		lazy("ProgressService").notice(target, "The owner gave you a free try of the " .. Toys.byId[weapon].label .. "!")
		return true, string.format("%s gave %s (%d) a try of %s", who, target.Name, target.UserId, weapon), "Try " .. weapon .. " for " .. target.DisplayName
	elseif kind == "ResetLab" then
		local target = targetOf(arg)
		if not target then
			return false
		end
		local n = lazy("Lab").rewind(target)
		return true, string.format("%s reset the lab of %s (%d)", who, target.Name, target.UserId), "Reset " .. target.DisplayName .. "'s lab (" .. tostring(n) .. ")"
	elseif kind == "ReviveAll" then
		local VitalsService = lazy("VitalsService")
		local n = 0
		local folder = Workspace:FindFirstChild("Dummies")
		for _, m in if folder then folder:GetChildren() else {} do
			if m:IsA("Model") and VitalsService.reviveNow(m) then
				n += 1
			end
		end
		return true, who .. " revived " .. n, "Revived " .. n
	elseif kind == "Spawn" then
		local count = if type(arg) == "table" then (arg :: any).count else nil
		local shape = if type(arg) == "table" then (arg :: any).shape else nil
		if not table.find(AdminTools.SPAWN_COUNTS, count) or type(shape) ~= "string" or not AdminTools.SHAPES[shape] then
			return false
		end
		local root = rootOf(by)
		if not root then
			return false
		end
		local EventService = lazy("EventService")
		local room = EventService.dummyRoom()
		local n = math.min(count :: number, room)
		if n <= 0 then
			return false, nil, nil, "No room for more bodies in this server right now"
		end
		local DummyFactory = lazy("DummyFactory")
		for _, at in AdminTools.layout(shape, n, root.Position, root.CFrame.LookVector) do
			local model = DummyFactory.spawn(at, root.Position, by)
			model:SetAttribute("NoCredit", true) -- (guests: never counted as takedowns)
		end
		return true, string.format("%s spawned %d dummies (%s)", who, n, shape), string.format("Spawned %d (%s)", n, shape)
	elseif kind == "Crowd" then
		if arg ~= 5 and arg ~= -5 then
			return false
		end
		local place = by:GetAttribute("Place")
		local CrowdService = lazy("CrowdService")
		local n = CrowdService.adjust(if type(place) == "string" then place else "Plaza", arg :: number, AdminTools.CROWD_MAX)
		if n < 0 then
			n = CrowdService.adjust("Plaza", arg :: number, AdminTools.CROWD_MAX)
		end
		return true, string.format("%s set the crowd to %d", who, n), "Crowd here: " .. n
	elseif kind == "ClearDummies" then
		local n = 0
		local folder = Workspace:FindFirstChild("Dummies")
		for _, m in if folder then folder:GetChildren() else {} do
			if m:IsA("Model") and m:GetAttribute("NoCredit") == true then
				m:Destroy()
				n += 1
			end
		end
		return true, who .. " cleared " .. n .. " guest dummies", "Cleared " .. n
	end
	return false
end

-- The Debug tab's numbers.
function AdminTools.debug(): { [string]: any }
	local parts, ragdolls = 0, 0
	for _, d in Workspace:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	local folder = Workspace:FindFirstChild("Dummies")
	ragdolls = if folder then #folder:GetChildren() else 0
	return {
		fps = math.floor(beats.fps + 0.5),
		memory = math.floor(Stats:GetTotalMemoryUsageMb()),
		parts = parts,
		ragdolls = ragdolls,
		players = #Players:GetPlayers(),
		send = math.floor(Stats.DataSendKbps * 10) / 10,
		receive = math.floor(Stats.DataReceiveKbps * 10) / 10,
		errors = table.clone(errors),
		version = Config.Version,
	}
end

function AdminTools.start()
	LogService.MessageOut:Connect(function(message: string, kind: Enum.MessageType)
		if kind == Enum.MessageType.MessageError then
			table.insert(errors, 1, string.sub(message, 1, 160))
			while #errors > 6 do
				table.remove(errors)
			end
		end
	end)
	RunService.Heartbeat:Connect(function()
		beats.n += 1
		local now = os.clock()
		if now - beats.t0 >= 2 then
			beats.fps = beats.n / (now - beats.t0)
			beats.n, beats.t0 = 0, now
		end
	end)
end

-- The kinds this module owns.
AdminTools.KINDS = table.freeze({
	Event = true, Gravity = true, Clock = true, Weather = true, Announce = true, Kick = true,
	Goto = true, Bring = true, Trial = true,
	ResetLab = true, ReviveAll = true, Spawn = true, Crowd = true, ClearDummies = true,
})

return AdminTools
