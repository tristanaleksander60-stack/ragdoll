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
	if kind == "LaunchDummy" or kind == "Shot" or kind == "DirectorSave" or kind == "DirectorGet" then
		return AdminTools.director(by, kind, arg)
	end
	local who = string.format("%s (%d)", by.Name, by.UserId)
	if kind == "Event" then
		if type(arg) ~= "string" or not Events.byId[arg] then
			return false
		end
		local EventService = lazy("EventService")
		-- (Review fix: the owner never builds a queue in front of paid events: one waiting at most.)
		if EventService.queued() >= 1 then
			return false, nil, nil, "An event is waiting already: try after it starts"
		end
		local place = EventService.trigger(arg, by.DisplayName, "Free", EventService.current() == nil, nil, by.UserId)
		if not place then
			return false, nil, nil, "That event could not start now"
		end
		return true, who .. " started " .. arg, by.DisplayName .. " started " .. arg
	elseif kind == "Gravity" then
		if not table.find(AdminTools.GRAVITY :: { any }, arg) then
			return false
		end
		Workspace.Gravity = arg :: number
		Workspace:SetAttribute("AdminGravity", if arg == 196.2 then nil else arg)
		return true, who .. " set gravity " .. tostring(arg), "Gravity " .. tostring(arg)
	elseif kind == "Clock" then
		if arg ~= "Auto" and (type(arg) ~= "string" or (AdminTools.CLOCK :: any)[arg] == nil) then
			return false
		end
		Workspace:SetAttribute("AdminClock", if arg == "Auto" then nil else (AdminTools.CLOCK :: any)[arg])
		return true, who .. " set the time " .. tostring(arg), "Time: " .. tostring(arg)
	elseif kind == "Weather" then
		if type(arg) ~= "string" or not (AdminTools.WEATHER :: any)[arg] then
			return false
		end
		Workspace:SetAttribute("AdminWeather", if arg == "Clear" then nil else arg)
		return true, who .. " set the weather " .. arg, "Weather: " .. arg
	elseif kind == "Announce" then
		local text = if type(arg) == "string" then (AdminTools.ANNOUNCE :: any)[arg] else nil
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
		local reason = if type(arg) == "table" and type((arg :: any).reason) == "string" then (AdminTools.KICK :: any)[(arg :: any).reason] else nil
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
		-- (Review fix: never into a private lab the mover may not enter (Lab.keepOut would throw them
		-- straight back out), never someone in a car (the whole car would come along) or in ice.)
		local mover = if kind == "Goto" then by else target
		local moverRoot = if kind == "Goto" then a else b
		local dest = if kind == "Goto" then b else a
		local moverHum = (mover.Character :: Model):FindFirstChildOfClass("Humanoid")
		if moverHum and moverHum.SeatPart then
			return false, nil, nil, mover.DisplayName .. " is in a vehicle: try when they are out"
		end
		if moverRoot.Anchored then
			return false, nil, nil, mover.DisplayName .. " is frozen right now"
		end
		local Lab = lazy("Lab")
		local _, index = Lab.zoneAt(dest.Position)
		if index and not Lab.mayEnter(mover, index) then
			return false, nil, nil, "That is a private lab: use SPECTATE to watch it"
		end
		local spot = if kind == "Goto" then dest.CFrame * CFrame.new(0, 0, 5) else dest.CFrame * CFrame.new(0, 0, -5);
		(mover.Character :: Model):PivotTo(spot)
		-- (The place the mover is in now: lighting, crowd and the rest read it.)
		local other = if kind == "Goto" then target else by
		local place = other:GetAttribute("Place")
		if place ~= nil then
			mover:SetAttribute("Place", place)
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
		if not table.find(AdminTools.SPAWN_COUNTS :: { any }, count) or type(shape) ~= "string" or not AdminTools.SHAPES[shape] then
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
			AdminTools.markGuest(model)
		end
		return true, string.format("%s spawned %d dummies (%s)", who, n, shape), string.format("Spawned %d (%s)", n, shape)
	elseif kind == "Crowd" then
		if arg ~= 5 and arg ~= -5 then
			return false
		end
		local place = by:GetAttribute("Place")
		local CrowdService = lazy("CrowdService")
		-- (Labs have no crowd: said so, never the plaza's number by mistake.)
		local n = CrowdService.adjust(if type(place) == "string" then place else "Plaza", arg :: number, AdminTools.CROWD_MAX)
		if n < 0 then
			return false, nil, nil, "No crowd here: go to the plaza or a map"
		end
		return true, string.format("%s set the crowd to %d", who, n), "Crowd here: " .. n
	elseif kind == "ClearDummies" then
		-- (Only the bodies this menu or the director made: other guests and held bodies are left.)
		local n = 0
		local folder = Workspace:FindFirstChild("Dummies")
		for _, m in if folder then folder:GetChildren() else {} do
			if m:IsA("Model") and m:GetAttribute("AdminGuest") == true and m:GetAttribute("Held") ~= true then
				m:Destroy()
				n += 1
			end
		end
		return true, who .. " cleared " .. n .. " spawned dummies", "Cleared " .. n
	end
	return false
end

------------------------------------------------------------------------------------------------
-- V6-3: the director menu's server half (Client/Director). Same owner check and pacing.
--   LaunchDummy model        one body in Workspace.Dummies flies (up and away from the owner)
--   Shot id                  sets up one of the one-tap TikTok shots in the owner's own lab; the
--                            owner's screen is told where to look ("DirectorFocus")
--   DirectorSave presets     the 5 shot presets, kept for every server (OwnerSetting; never in Studio)
AdminTools.SHOTS = table.freeze({ Cannon = true, CarRow = true, Spider = true, Gorilla = true, Tower = true, MegaBomb = true })
AdminTools.PRESETS_MAX = 5
AdminTools.LAUNCH_SPEED = 95

local presets: any = nil -- the OwnerSetting (made at start)
local focusRemote: ((Player, string, any) -> ())? = nil

local function finite(n: unknown, lo: number, hi: number): boolean
	return type(n) == "number" and n == n and n >= lo and n <= hi
end

-- A preset: { c = 12 numbers (a CFrame), fov 20-110, slow 0.05-1 }.
function AdminTools.cleanPresets(raw: unknown): { any }?
	if type(raw) ~= "table" or #(raw :: any) > AdminTools.PRESETS_MAX then
		return nil
	end
	local out = {}
	for i = 1, AdminTools.PRESETS_MAX do
		local p = (raw :: any)[i]
		if p == nil or p == false then
			out[i] = false
		elseif type(p) == "table" and type(p.c) == "table" and #p.c == 12 and finite(p.fov, 20, 110) and finite(p.slow, 0.05, 1) then
			local c = {}
			for k = 1, 12 do
				if not finite(p.c[k], -1e5, 1e5) then
					return nil
				end
				c[k] = p.c[k]
			end
			out[i] = { c = c, fov = p.fov, slow = p.slow }
		else
			return nil
		end
	end
	return out
end

local function guest(at: Vector3, look: Vector3?, by: Player): Model
	local model = lazy("DummyFactory").spawn(at, look, by)
	AdminTools.markGuest(model)
	return model
end

local function ownLabPart(by: Player, name: string): BasePart?
	local pg = Workspace:FindFirstChild("Playground")
	local Lab = lazy("Lab")
	for _, f in if pg then pg:GetChildren() else {} do
		local part = f:FindFirstChild(name, true)
		if part and part:IsA("BasePart") and Lab.ownerAt(part.Position) == by then
			return part
		end
	end
	return nil
end

function AdminTools.director(by: Player, kind: string, arg: unknown): (boolean, string?, string?, string?)
	local who = string.format("%s (%d)", by.Name, by.UserId)
	if kind == "LaunchDummy" then
		local model = if typeof(arg) == "Instance" then arg :: Instance else nil
		local folder = Workspace:FindFirstChild("Dummies")
		if not model or not model:IsA("Model") or not folder or model.Parent ~= folder then
			return false
		end
		local root = rootOf(by)
		local pivot = (model :: Model):GetPivot().Position
		local away = if root then Vector3.new(pivot.X - root.Position.X, 0, pivot.Z - root.Position.Z) else Vector3.zero
		away = if away.Magnitude > 0.1 then away.Unit else Vector3.new(0, 0, -1)
		lazy("DummyControl").push(model, away * AdminTools.LAUNCH_SPEED * 0.6 + Vector3.new(0, AdminTools.LAUNCH_SPEED, 0), by)
		return true, who .. " launched a dummy", "Launched a dummy"
	elseif kind == "Shot" then
		if type(arg) ~= "string" or not AdminTools.SHOTS[arg] then
			return false
		end
		local root = rootOf(by)
		if not root then
			return false
		end
		local look = root.CFrame.LookVector
		local focus: Vector3 = root.Position
		local shotTo: Vector3? = nil
		if arg == "Cannon" then
			local pad = ownLabPart(by, "CannonPad")
			if not pad then
				return false, nil, nil, "Go to your own lab for this shot"
			end
			guest(pad.Position + Vector3.new(0, 4, 0), nil, by)
			focus = pad.Position
			local okL, landing = pcall(function()
				return lazy("Playground").cannonLanding(pad.Position + Vector3.new(0, 0.5, 0))
			end)
			shotTo = if okL then landing else nil
		elseif arg == "CarRow" then
			local base = root.Position + Vector3.new(look.X, 0, look.Z).Unit * 40
			for _, at in AdminTools.layout("Row", 8, base - Vector3.new(look.X, 0, look.Z).Unit * 14, look) do
				guest(at, root.Position, by)
			end
			focus = base
			shotTo = base + Vector3.new(look.X, 0, look.Z).Unit * 30
		elseif arg == "Tower" then
			local base = root.Position + Vector3.new(look.X, 0, look.Z).Unit * 18 + Vector3.new(0, 34, 0)
			for i = 1, 5 do
				local model = guest(base + Vector3.new((i - 3) * 3, 0, 0), nil, by)
				task.delay(0.6, function()
					if model.Parent then
						lazy("DummyControl").push(model, Vector3.new(look.X, 0, look.Z).Unit * 70 + Vector3.new((i - 3) * 6, 20, 0), by)
					end
				end)
			end
			focus = base
			shotTo = base + Vector3.new(look.X, 0, look.Z).Unit * 30
		elseif arg == "Spider" then
			local web = ownLabPart(by, "SpiderWeb")
			if not web then
				return false, nil, nil, "The spider is not in your lab yet"
			end
			guest(web.Position + Vector3.new(0, 14, 0), nil, by)
			focus = web.Position
		elseif arg == "Gorilla" or arg == "MegaBomb" then
			local id = if arg == "Gorilla" then "GorillaRampage" else "MegaBomb"
			if not Events.byId[id] then
				return false
			end
			local place = lazy("EventService").trigger(id, by.DisplayName, "Free", true, nil, by.UserId)
			if not place then
				return false, nil, nil, "That event could not start now"
			end
			focus = if typeof(place) == "Vector3" then place else lazy("EventService").whereFor(by.UserId)
		end
		local f = focusRemote
		if f then
			f(by, "DirectorFocus", { shot = arg, at = focus, to = shotTo })
		end
		return true, who .. " set up the " .. arg .. " shot", "Shot: " .. arg
	elseif kind == "DirectorSave" then
		local clean = AdminTools.cleanPresets(arg)
		if not clean or not presets then
			return false
		end
		lazy("OwnerSetting").set(presets, clean)
		return true, who .. " saved the director presets", "Presets saved"
	elseif kind == "DirectorGet" then
		local f = focusRemote
		if f then
			f(by, "DirectorPresets", if presets then presets.value else {})
		end
		return true
	end
	return false
end

-- Admin-made bodies: guests (never takedowns), gone after GUEST_LIFE s so they never hold the
-- shared body budget for long (paid Dummy Rain, the horde, the chases).
AdminTools.GUEST_LIFE = 90
function AdminTools.markGuest(model: Model)
	model:SetAttribute("NoCredit", true)
	model:SetAttribute("AdminGuest", true)
	task.delay(AdminTools.GUEST_LIFE, function()
		if model.Parent and model:GetAttribute("Held") ~= true then
			model:Destroy()
		end
	end)
end

-- The owner left: their world changes end with them (gravity, time, weather, spawned bodies).
function AdminTools.ownerLeft()
	Workspace.Gravity = 196.2
	Workspace:SetAttribute("AdminGravity", nil)
	Workspace:SetAttribute("AdminClock", nil)
	Workspace:SetAttribute("AdminWeather", nil)
	local folder = Workspace:FindFirstChild("Dummies")
	for _, m in if folder then folder:GetChildren() else {} do
		if m:GetAttribute("AdminGuest") == true then
			m:Destroy()
		end
	end
end

-- (The world's part count is walked at most every PARTS_EVERY s: never a spike each poll.)
AdminTools.PARTS_EVERY = 15
local partsCache = { n = 0, at = -math.huge }

-- The Debug tab's numbers.
function AdminTools.debug(): { [string]: any }
	local ragdolls = 0
	if os.clock() - partsCache.at > AdminTools.PARTS_EVERY then
		partsCache.at = os.clock()
		local n = 0
		for _, d in Workspace:GetDescendants() do
			if d:IsA("BasePart") then
				n += 1
			end
		end
		partsCache.n = n
	end
	local parts = partsCache.n
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

function AdminTools.start(fire: ((Player, string, any) -> ())?)
	focusRemote = fire
	task.spawn(function()
		-- (Kept for every server live; in Studio only in memory: never a live store write.)
		presets = lazy("OwnerSetting").new("DirectorPresets", {}, function(v: unknown): boolean
			return AdminTools.cleanPresets(v) ~= nil
		end, function() end, not RunService:IsStudio())
	end)
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
	LaunchDummy = true, Shot = true, DirectorSave = true, DirectorGet = true,
	ResetLab = true, ReviveAll = true, Spawn = true, Crowd = true, ClearDummies = true,
})

return AdminTools
