--!strict
-- The owner's own controls (round 3): every request is checked on the server (Owner.isOwner),
-- paced, and its arguments are fixed choices only (no free text).
--   Theme "auto" | "on" | "off"          the Christmas theme (M7, ChristmasService), every server
--   FreePasses 0 | 3 | 7 | 14       the launch: the passes free for everyone for that many days
--                                          (MoneyService; 0 ends it), kept for every server
--   Troll { target = userId, action }     the troll menu (M8): something silly happens to one
--                                          player in this server
--   AllWeapons true | false               every weapon for everyone in this server while the
--                                          owner is here (Workspace "OwnerParty"; never saved)
-- The owner's screen is told who is here and the last troll actions (the log) when it asks
-- ("Hello"), after every request and as people come and go ("State"); the theme it reads from the
-- Workspace attributes every screen gets. "Notice": something went wrong (the theme not kept).
--
-- The troll menu's rules (the owner's plan): everything is temporary and harmless. Nothing touches
-- anyone's data, money, eggs, weapons or takedowns (the bodies it brings are guests marked
-- NoCredit, its present only pops); a size or a freeze always ends by itself; one action on the
-- same player at a time per kind (COOLDOWN s), and everything is logged with who did what to whom.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Log = require(Shared:WaitForChild("Log"))
local Owner = require(script.Parent.Owner)
local Admins = require(script.Parent.Admins) -- (21 Nov: the owner and the admins the owner made)
local ChristmasService = require(script.Parent.ChristmasService)
local MoneyService = require(script.Parent.MoneyService)
local PlayerRagdoll = require(script.Parent.PlayerRagdoll)
local StreamerService = require(script.Parent.StreamerService)
local FxService = require(script.Parent.FxService)
local Lab = require(script.Parent.Lab)
local AdminTools = require(script.Parent.AdminTools) -- V6-2: the tabbed menu's tools

local log = Log.new("Admin")

local AdminService = {}

local GAP = 0.5 -- s between two requests from the owner (a held button never floods)
AdminService.COOLDOWN = 4 -- s before the same action again on the same player
AdminService.FREEZE_TIME = 5
AdminService.SIZE_TIME = 15 -- s small or giant lasts
AdminService.SPIN_TIME = 3
AdminService.CHASE_TIME = 15
AdminService.CHASERS = 4
AdminService.LOG_KEEP = 5 -- lines of the log the owner sees

-- The menu, in its order: id, the button's words, what the log says.
AdminService.ACTIONS = table.freeze({
	{ id = "Ragdoll", name = "RAGDOLL", did = "ragdolled" },
	{ id = "Fling", name = "FLING", did = "flung" },
	{ id = "Freeze", name = "FREEZE 5S", did = "froze" },
	{ id = "Small", name = "TINY", did = "shrank" },
	{ id = "Giant", name = "GIANT", did = "made a giant of" },
	{ id = "Spin", name = "SPIN", did = "spun" },
	{ id = "Launch", name = "SKY LAUNCH", did = "launched" },
	{ id = "Rain", name = "DUMMY RAIN", did = "rained dummies on" },
	{ id = "Chase", name = "NPC CHASE", did = "set chasers on" },
	{ id = "Present", name = "PRESENT", did = "dropped a present on" },
})
local BY_ID: { [string]: any } = {}
for _, a in AdminService.ACTIONS do
	BY_ID[a.id] = a
end

local remote: RemoteEvent
local last: { [Player]: number } = {}
local cooled: { [Player]: { [string]: number } } = {} -- target -> action -> os.clock() it ran
local busy: { [Player]: { [string]: boolean } } = {} -- target -> "Size" / "Freeze" / "Spin" while on
local ices: { [Player]: BasePart } = {} -- a frozen target's ice (gone with a new body)
local lines: { string } = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
		return root
	end
	return nil
end

local function busyOf(target: Player): { [string]: boolean }
	local b = busy[target] or {}
	busy[target] = b
	return b
end

------------------------------------------------------------------------------------------------
-- The actions. Each returns whether it happened (false: the player can't be trolled that way now).

local RUN: { [string]: (Player, BasePart) -> boolean } = {}

RUN.Ragdoll = function(target, _root)
	PlayerRagdoll.knock(target, Vector3.new(0, 6, 0))
	return true
end

RUN.Fling = function(target, root)
	local a = math.random() * math.pi * 2
	PlayerRagdoll.launch(target, Vector3.new(math.cos(a) * 70, 55, math.sin(a) * 70))
	FxService.hit(root.Position, 30, "SpringPad")
	return true
end

RUN.Launch = function(target, root)
	PlayerRagdoll.launch(target, Vector3.new(0, 130, 0))
	FxService.hit(root.Position, 30, "SpringPad")
	return true
end

-- Frozen in a block of ice where they stand, FREEZE_TIME s (the root anchored; it lets go by
-- itself, and on a respawn the new body is free anyway).
RUN.Freeze = function(target, root)
	local b = busyOf(target)
	if b.Freeze then
		return false
	end
	b.Freeze = true
	local character = root.Parent :: Model
	local cf, size = character:GetBoundingBox()
	local ice = Instance.new("Part")
	ice.Name = "TrollIce"
	ice.Anchored = true
	ice.CanCollide = false
	ice.CanQuery = false
	ice.CanTouch = false
	ice.Material = Enum.Material.Ice
	ice.Color = Color3.fromRGB(170, 220, 255)
	ice.Transparency = 0.45
	ice.Size = size + Vector3.new(1, 0.6, 1)
	ice.CFrame = cf
	ice.Parent = Workspace
	ices[target] = ice
	root.Anchored = true
	FxService.hit(root.Position, 20, "Freeze")
	task.delay(AdminService.FREEZE_TIME, function()
		if root.Parent then
			root.Anchored = false
		end
		ice:Destroy()
		if ices[target] == ice then
			ices[target] = nil
		end
		b.Freeze = nil
	end)
	return true
end

-- Tiny or giant for SIZE_TIME s, then their own size again (one at a time).
local function resize(target: Player, root: BasePart, k: number): boolean
	local b = busyOf(target)
	local character = root.Parent :: Model
	if b.Size or math.abs(character:GetScale() - 1) > 0.01 then
		return false
	end
	local ok = pcall(function()
		character:ScaleTo(k)
	end)
	if not ok then
		error("ScaleTo failed") -- (said as "didn't work this time", not "another size")
	end
	b.Size = true
	task.delay(AdminService.SIZE_TIME, function()
		if character.Parent and target.Character == character then
			pcall(function()
				character:ScaleTo(1)
			end)
		end
		b.Size = nil
	end)
	return true
end
RUN.Small = function(target, root)
	return resize(target, root, 0.5)
end
RUN.Giant = function(target, root)
	return resize(target, root, 2)
end

RUN.Spin = function(target, root)
	local b = busyOf(target)
	if b.Spin then
		return false
	end
	b.Spin = true
	local attachment = Instance.new("Attachment")
	attachment.Name = "TrollSpin"
	attachment.Parent = root
	local spin = Instance.new("AngularVelocity")
	spin.Name = "TrollSpin"
	spin.Attachment0 = attachment
	spin.RelativeTo = Enum.ActuatorRelativeTo.World
	spin.AngularVelocity = Vector3.new(0, 25, 0)
	spin.MaxTorque = 1e6
	spin.Parent = root
	task.delay(AdminService.SPIN_TIME, function()
		spin:Destroy()
		attachment:Destroy()
		b.Spin = nil
	end)
	return true
end

RUN.Rain = function(target, _root)
	return StreamerService.runAt(target, "Rain")
end

-- Guest bodies (NoCredit) that run after them for CHASE_TIME s (they only walk into them), then poof.
RUN.Chase = function(target, root)
	local b = busyOf(target)
	if b.Chase then
		return false
	end
	local chasers: { Model } = {}
	for i = 1, AdminService.CHASERS do
		local a = (i / AdminService.CHASERS) * math.pi * 2
		local at = root.Position + Vector3.new(math.cos(a) * 16, 0, math.sin(a) * 16)
		local model = StreamerService.guestBody(at, root.Position, 2)
		if not model then
			break
		end
		model.Name = "TrollChaser"
		model:SetAttribute("Role", "Charging")
		model:SetAttribute("Pace", 1.3)
		model:SetAttribute("PersonName", "Chaser")
		table.insert(chasers, model)
	end
	if #chasers == 0 then
		return false
	end
	b.Chase = true
	task.spawn(function()
		local ends = os.clock() + AdminService.CHASE_TIME
		while os.clock() < ends and target.Parent do
			local r = rootOf(target)
			if r then
				for _, m in chasers do
					if m.Parent then
						m:SetAttribute("Home", r.Position - Vector3.new(0, 2.5, 0))
						m:SetAttribute("HomeLook", r.Position)
					end
				end
			end
			task.wait(0.5)
		end
		-- (Round 4, M10: a dead one stays for its DEAD_HOLD; VitalsService takes it.)
		for _, m in chasers do
			if m.Parent and m:GetAttribute("Vital") ~= "Dead" then
				local pelvis = m:FindFirstChild("LowerTorso")
				if pelvis and pelvis:IsA("BasePart") then
					Lab.poof(pelvis.Position)
				end
				m:Destroy()
			end
		end
		b.Chase = nil
	end)
	return true
end

-- A present lands on their head and pops (confetti and a boing). It holds nothing: no egg.
RUN.Present = function(_target, root)
	return ChristmasService.prank(root.Position)
end

------------------------------------------------------------------------------------------------

local function state(): { [string]: any }
	local here = {}
	for _, p in Players:GetPlayers() do
		-- (21 Nov: who is admin, for the owner's MAKE ADMIN / REMOVE ADMIN.)
		table.insert(here, { id = p.UserId, name = p.DisplayName, user = p.Name, admin = Admins.isAdmin(p) or nil, owner = Owner.isOwner(p) or nil })
	end
	table.sort(here, function(a, b)
		return a.name < b.name
	end)
	return { players = here, log = table.clone(lines), admins = Admins.entries() }
end

local function tell(player: Player)
	remote:FireClient(player, "State", state())
end

-- The server's log names everyone by user name and id (who did it, for sure); the owner's window
-- by the names the game shows (as on the player buttons).
local function note(logged: string, shown: string)
	log.info(logged)
	table.insert(lines, 1, shown)
	while #lines > AdminService.LOG_KEEP do
		table.remove(lines)
	end
end

-- Actions that move the body: nothing to see while it is frozen in ice (refused, and said why).
local MOVES = { Ragdoll = true, Fling = true, Launch = true, Spin = true }
-- What a refused action says on the owner's screen.
local WHY = {
	Freeze = "%s is frozen already",
	Small = "%s is another size already",
	Giant = "%s is another size already",
	Spin = "%s is spinning already",
	Chase = "%s is being chased already, or the server has no room for more bodies",
	Rain = "No room for more bodies in this server right now",
}

-- One troll action on one player here. Returns whether it happened, and why not.
local function troll(by: Player, arg: unknown): (boolean, string?)
	if type(arg) ~= "table" then
		return false, nil
	end
	local a = arg :: any
	local action = BY_ID[a.action]
	local target = if type(a.target) == "number" then Players:GetPlayerByUserId(a.target) else nil
	if not action then
		return false, nil
	elseif not target then
		return false, "That player has left"
	end
	local root = rootOf(target)
	if not root then
		return false, target.DisplayName .. " has no body right now (respawning). Try again in a moment"
	end
	if MOVES[action.id] and busyOf(target).Freeze then
		return false, target.DisplayName .. " is frozen: wait for the ice to go"
	end
	local c = cooled[target] or {}
	cooled[target] = c
	local now = os.clock()
	local wait = AdminService.COOLDOWN - (now - (c[action.id] or -math.huge))
	if wait > 0 then
		return false, string.format("%s again on %s in %d s", action.name, target.DisplayName, math.ceil(wait))
	end
	local ok, done = pcall(RUN[action.id], target, root)
	if not ok or done ~= true then
		local why = WHY[action.id]
		return false, if why then string.format(why, target.DisplayName) else action.name .. " didn't work this time"
	end
	c[action.id] = now
	note(string.format("%s (%d) %s %s (%d)", by.Name, by.UserId, action.did, target.Name, target.UserId), string.format("%s %s %s", by.DisplayName, action.did, target.DisplayName))
	return true, nil
end

------------------------------------------------------------------------------------------------
-- Round 4: the owner's party. While the owner is in this server and has it on, everyone here has
-- every weapon (Workspace "OwnerParty": ProgressService.isUnlocked and the catalog read it). Nothing
-- is saved or bought: it ends the moment the owner leaves or turns it off. And everyone can see who
-- the owner is: OWNER over their head.

local function ownerHere(): boolean
	for _, p in Players:GetPlayers() do
		if Owner.isOwner(p) then
			return true
		end
	end
	return false
end

function AdminService.setAllWeapons(on: boolean)
	Workspace:SetAttribute("OwnerParty", if on and ownerHere() then true else nil)
end

local function ownerTag(player: Player, character: Model)
	if not Owner.isOwner(player) or require(game:GetService("ReplicatedStorage").Shared.Config).LOOK_V3 then
		return
	end
	local head = character:WaitForChild("Head", 10)
	if not (head and head:IsA("BasePart")) or head:FindFirstChild("OwnerTag") then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "OwnerTag"
	gui.Size = UDim2.fromOffset(96, 30)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0) -- (above a VIP tag at 2.6)
	gui.MaxDistance = 120
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(220, 40, 50)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	label.TextScaled = true
	label.Text = "OWNER"
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = label
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.fromRGB(255, 215, 80)
	stroke.Thickness = 2
	stroke.Parent = label
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.1, 0)
	pad.PaddingRight = UDim.new(0.1, 0)
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.Parent = label
	label.Parent = gui
	gui.Parent = head
end

local function watchOwnerTag(player: Player)
	player.CharacterAdded:Connect(function(character)
		ownerTag(player, character)
	end)
	if player.Character then
		task.spawn(ownerTag, player, player.Character)
	end
end

-- SPECTATE (10 Nov 2026, the owner): the owner's camera follows a player in this server (client
-- Spectate). Here only the streaming: the world around the one watched is sent to the owner
-- (ReplicationFocus, kept on their avatar as it respawns), nothing changes for anyone else.
local watching: { [Player]: number } = {}
local watchLoop = false

local function focusOn(owner: Player)
	local id = watching[owner]
	local target = if id then Players:GetPlayerByUserId(id) else nil
	local root = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if id and not target then
		watching[owner] = nil -- (they left)
	end
	owner.ReplicationFocus = if root and root:IsA("BasePart") then root else nil
end

local function spectate(owner: Player, arg: unknown): boolean
	local id = if type(arg) == "number" then arg else nil
	local target = if id then Players:GetPlayerByUserId(id) else nil
	if not target or target == owner then
		watching[owner] = nil
		owner.ReplicationFocus = nil
		return id == nil -- (a stop is done; someone not here is not)
	end
	watching[owner] = target.UserId
	focusOn(owner)
	if not watchLoop then
		watchLoop = true
		task.spawn(function()
			while next(watching) ~= nil do
				task.wait(1)
				for p in watching do
					if p.Parent then
						focusOn(p)
					else
						watching[p] = nil
					end
				end
			end
			watchLoop = false
		end)
	end
	log.info(string.format("%s (%d) spectates %s (%d)", owner.Name, owner.UserId, target.Name, target.UserId))
	return true
end

-- Tests: whom the owner is watching (a userId) or nil.
function AdminService.watchingOf(player: Player): number?
	return watching[player]
end

-- One request, as if the client sent it (tests call it too). Returns whether it was done.
-- (21 Nov 2026, the owner: admins (Admins) use the menu too. These stay the owner's: settings kept
-- for every server, the director, and who is admin.)
AdminService.OWNER_ONLY = table.freeze({
	SoloList = true, SpectateSolo = true, FreePasses = true, Theme = true, AllWeapons = true, AdminSet = true,
	LaunchDummy = true, Shot = true, DirectorSave = true, DirectorGet = true,
}) :: { [string]: boolean }
-- (What an admin may never do to the owner or another admin.)
local AIMED = table.freeze({ Kick = true, Bring = true, Goto = true, Troll = true, Trial = true }) :: { [string]: boolean }

function AdminService.request(player: Player, kind: unknown, arg: unknown): boolean
	if not Admins.isAdmin(player) then
		return false -- (never told: a non-admin learns nothing of what is here)
	end
	local owner = Owner.isOwner(player)
	if type(kind) == "string" and not owner then
		if AdminService.OWNER_ONLY[kind] then
			remote:FireClient(player, "Notice", "Only the owner can do that")
			return false
		end
		if AIMED[kind] then
			local id = if type(arg) == "table" then (arg :: any).target else arg
			local aimed = if type(id) == "number" then Players:GetPlayerByUserId(id) else nil
			if aimed and aimed ~= player and Admins.isAdmin(aimed) then
				remote:FireClient(player, "Notice", "Not on the owner or another admin")
				return false
			end
		end
	end
	if kind == "AdminSet" then
		-- (The owner gives or takes admin: { target = userId, on = boolean }.)
		local a = if type(arg) == "table" then arg :: any else {}
		local id = if type(a.target) == "number" then a.target else nil
		local who = if id then Players:GetPlayerByUserId(id) else nil
		local ok, line = Admins.set(player, id or 0, if who then who.DisplayName else tostring(id), a.on == true)
		remote:FireClient(player, "Notice", line)
		if ok then
			note(string.format("%s (%d) %s admin for %s", player.Name, player.UserId, if a.on == true then "gave" else "took", tostring(id)), line)
		end
		for _, p in Players:GetPlayers() do
			if Admins.isAdmin(p) then
				tell(p)
			end
		end
		return ok
	end
	if kind == "DirectorGet" then
		AdminTools.run(player, kind, arg) -- (not paced: the director asks once when it opens)
		return true
	end
	if kind == "Debug" then
		remote:FireClient(player, "Debug", AdminTools.debug()) -- (not paced: the tab polls it)
		return true
	end
	if kind == "SoloList" or kind == "SpectateSolo" then
		-- (23 Nov 2026, the owner: watch people in singleplayer, each in a server of their own.)
		local at = os.clock()
		if at - (last[player] or -math.huge) < GAP then
			return false
		end
		last[player] = at
		local Portal = require(script.Parent:WaitForChild("PortalService")) :: any
		if kind == "SoloList" then
			remote:FireClient(player, "SoloList", Portal.soloList())
			return true
		end
		if type(arg) ~= "number" then
			return false
		end
		local why = Portal.spectateSolo(player, arg)
		if why then
			remote:FireClient(player, "Notice", why)
		else
			log.info(string.format("%s (%d) goes to watch %d in singleplayer", player.Name, player.UserId, arg))
		end
		return why == nil
	end
	if kind == "Spectate" then
		return spectate(player, arg) -- (not paced: STOP must always work at once)
	end
	local now = os.clock()
	if now - (last[player] or -math.huge) < GAP then
		if kind == "Troll" then
			remote:FireClient(player, "Notice", "One at a time: tap again in a moment")
		end
		return false
	end
	last[player] = now
	local done = false
	if kind == "Hello" then
		done = true
	elseif kind == "Theme" then
		done = ChristmasService.setMode(arg)
		if done then
			note(string.format("%s (%d) set the Christmas theme to %s", player.Name, player.UserId, tostring(arg)), player.DisplayName .. " set the Christmas theme to " .. string.upper(tostring(arg)))
		end
	elseif kind == "FreePasses" then
		done = MoneyService.setLaunchFree(arg)
		if done then
			note(string.format("%s (%d) set free passes for everyone: %s days", player.Name, player.UserId, tostring(arg)), player.DisplayName .. (if arg == 0 then " ended the free passes" else " made the passes free for " .. tostring(arg) .. " days"))
		end
	elseif kind == "AllWeapons" then
		if type(arg) == "boolean" then
			AdminService.setAllWeapons(arg)
			done = true
			note(string.format("%s (%d) set all weapons for everyone here: %s", player.Name, player.UserId, tostring(arg)), player.DisplayName .. (if arg then " gave everyone here every weapon" else " ended the free weapons"))
		end
	elseif type(kind) == "string" and AdminTools.KINDS[kind] then
		local logged, shown, why
		done, logged, shown, why = AdminTools.run(player, kind, arg)
		if done and logged then
			note(logged, shown or logged)
		end
		if why then
			remote:FireClient(player, "Notice", why)
		end
	elseif kind == "Debug" then
		remote:FireClient(player, "Debug", AdminTools.debug())
		done = true
	elseif kind == "Troll" then
		local why
		done, why = troll(player, arg)
		if why then
			remote:FireClient(player, "Notice", why)
		end
	end
	tell(player)
	return done
end

function AdminService.resetPaceForTest(player: Player)
	last[player] = nil -- (the owner's own pace only: the cooldowns on a target stay)
end

function AdminService.resetCooldownsForTest(target: Player)
	cooled[target] = nil
end

function AdminService.logForTest(): { string }
	return table.clone(lines)
end

function AdminService.start()
	Admins.start() -- (21 Nov: the admins the owner made, kept for every server)
	remote = Net.event(Net.Names.Admin)
	AdminTools.start(function(p: Player, kind: string, data: any)
		remote:FireClient(p, kind, data)
	end)
	remote.OnServerEvent:Connect(function(player: Player, kind: unknown, arg: unknown)
		AdminService.request(player, kind, arg)
	end)
	MoneyService.onLaunchSaveFailed(function()
		for _, p in Players:GetPlayers() do
			if Owner.isOwner(p) then
				remote:FireClient(p, "Notice", "The free passes are set here, but could not be kept for every server. Tap again")
			end
		end
	end)
	ChristmasService.onSaveFailed = function(m: string)
		for _, p in Players:GetPlayers() do
			if Owner.isOwner(p) then
				remote:FireClient(p, "Notice", "The theme is " .. string.upper(m) .. " here, but it could not be kept for every server. Tap " .. string.upper(m) .. " again")
			end
		end
	end
	-- The owner's list of who is here stays right as people come and go.
	local function refresh()
		for _, p in Players:GetPlayers() do
			if Admins.isAdmin(p) then
				tell(p)
			end
		end
	end
	Players.PlayerAdded:Connect(refresh)
	-- A new body is a fresh start: no size, ice, spin or chase carried over from the old one.
	local function watch(p: Player)
		-- (V6-3: a hint for the owner's screen only, F8 director mode; every action is still checked here.)
		if Owner.isOwner(p) then
			p:SetAttribute("IsOwner", true)
		end
		p.CharacterAdded:Connect(function()
			busy[p] = nil
			local ice = ices[p]
			if ice then
				ice:Destroy()
				ices[p] = nil
			end
		end)
	end
	for _, p in Players:GetPlayers() do
		watch(p)
		watchOwnerTag(p)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerAdded:Connect(watchOwnerTag)
	Players.PlayerRemoving:Connect(function(player)
		-- (The owner gone: the free weapons go with them, a beat after they have left the list.)
		if Owner.isOwner(player) then
			task.defer(function()
				if not ownerHere() then
					AdminService.setAllWeapons(false)
				end
			end)
		end
		-- (21 Nov: the last admin gone, the owner included: gravity, time, weather and spawned bodies
		-- go too, V6-2 review.)
		if Admins.isAdmin(player) then
			task.defer(function()
				for _, p in Players:GetPlayers() do
					if p ~= player and Admins.isAdmin(p) then
						return
					end
				end
				AdminTools.ownerLeft()
			end)
		end
		last[player] = nil
		cooled[player] = nil
		busy[player] = nil
		if ices[player] then
			ices[player]:Destroy()
			ices[player] = nil
		end
		task.defer(refresh)
	end)
end

return AdminService
