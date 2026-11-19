--!strict
-- v4 B4 (owner): talk to the NPCs. Walk up to one and press E ("Talk"): a small panel opens (Client
-- NpcTalk) with Follow me, Stay here, Attack… and Bye. Attack: pick another NPC nearby and one of
-- YOUR unlocked weapons; the NPC holds it and uses it on the target with the real hit rules
-- (HitService, the same as yours; they do not count as your takedowns).
-- Limits (all checked here, never trusted from the client):
--   at most MAX_FOLLOWERS commanded NPCs per player; only bodies within TALK_REACH of you; only
--   NPCs (Workspace.Dummies), never players; a target within TARGET_REACH of the NPC; a weapon you
--   own and that hits; one request per REQUEST_GAP; commands end when you leave the place or the
--   game, or the NPC dies or goes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Toys = require(Shared:WaitForChild("Toys"))
local Config = require(Shared:WaitForChild("Config"))

local CrowdService = require(script.Parent.CrowdService)
local HitService = require(script.Parent.HitService)
local ProgressService = require(script.Parent.ProgressService)

local NpcCommand = {}

NpcCommand.MAX_FOLLOWERS = 3
NpcCommand.TALK_REACH = 14 -- studs from you to the NPC you command
NpcCommand.TARGET_REACH = 60 -- studs from the NPC to its target
NpcCommand.REQUEST_GAP = 0.3 -- s
NpcCommand.FOLLOW_BACK = 5 -- studs behind you a follower walks
NpcCommand.STRIKE_REACH = 6 -- studs: close enough to hit
NpcCommand.STRIKE_GAP_MIN = 0.7 -- s between an NPC's hits (a fast gun is slowed to this)
NpcCommand.TICK = 0.25

type Order = { owner: Player, mode: string, target: Model?, toy: Toys.Toy?, nextHit: number, place: unknown, held: Model? }
local orders: { [Model]: Order } = {}
local lastRequest: { [Player]: number } = {}
local remote: RemoteEvent

local function bodyOf(inst: unknown): Model?
	if typeof(inst) ~= "Instance" then
		return nil
	end
	local folder = Workspace:FindFirstChild("Dummies")
	local m = inst :: Instance
	if not folder or not m:IsA("Model") or m.Parent ~= folder then
		return nil
	end
	-- (Not the arena's runners, a chase's chasers or a greeter: their own games drive them.)
	if m:GetAttribute("Minigame") or m:GetAttribute("Chaser") or m:GetAttribute("Greeter") then
		return nil
	end
	if m:GetAttribute("Vital") == "Dead" or not m:FindFirstChild("LowerTorso") then
		return nil
	end
	return m :: Model
end

local function pelvisOf(m: Model): BasePart?
	local p = m:FindFirstChild("LowerTorso")
	return if p and p:IsA("BasePart") then p else nil
end

local function rootOf(player: Player): BasePart?
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r else nil
end

local function goTo(m: Model, spot: Vector3, facing: Vector3)
	if not CrowdService.goTo(m, spot, facing) then
		-- (A lab dummy: its Home is where it walks.)
		m:SetAttribute("Home", spot)
		m:SetAttribute("HomeLook", facing)
	end
end

local function dropHeld(o: Order)
	if o.held then
		o.held:Destroy()
		o.held = nil
	end
end

local function release(m: Model)
	local o = orders[m]
	if o then
		dropHeld(o)
	end
	orders[m] = nil
	if m.Parent then
		m:SetAttribute("CommandedBy", nil)
		m:SetAttribute("Command", nil)
	end
end

local function countOf(player: Player): number
	local n = 0
	for _, o in orders do
		if o.owner == player then
			n += 1
		end
	end
	return n
end

-- The weapon's model in the NPC's right hand (pictures only).
local function hold(m: Model, toyId: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("N7Assets")
	local weapons = assets and assets:FindFirstChild("Weapons")
	local src = weapons and weapons:FindFirstChild(toyId)
	local hand = m:FindFirstChild("RightHand")
	if not (src and src:IsA("Model") and hand and hand:IsA("BasePart")) then
		return nil
	end
	local copy = src:Clone()
	copy.Name = "HeldByNpc"
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		elseif d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	copy:PivotTo(hand.CFrame * CFrame.new(0, -0.35, -0.25))
	local primary = copy.PrimaryPart or copy:FindFirstChildWhichIsA("BasePart", true)
	if primary then
		for _, d in copy:GetDescendants() do
			if d:IsA("BasePart") and d ~= primary then
				local w = Instance.new("WeldConstraint")
				w.Part0 = primary
				w.Part1 = d
				w.Parent = d
			end
		end
		local grip = Instance.new("WeldConstraint")
		grip.Part0 = hand
		grip.Part1 = primary
		grip.Parent = primary
	end
	copy.Parent = m
	return copy
end

-- Weapons a player may hand an NPC: owned (or trial/pass) tools that hit.
function NpcCommand.weaponsOf(player: Player): { string }
	local out = {}
	for _, toy in Toys.list do
		if toy.kind == "hit" and ProgressService.isUnlocked(player, toy) then
			table.insert(out, toy.id)
		end
	end
	return out
end

-- Why a command is refused (nil: it may go). Exposed for the tests.
function NpcCommand.refusal(player: Player, action: unknown, npcInst: unknown, targetInst: unknown, toyId: unknown): string?
	if action ~= "Follow" and action ~= "Stay" and action ~= "Attack" and action ~= "Bye" then
		return "Unknown command"
	end
	local m = bodyOf(npcInst)
	local root = rootOf(player)
	if not m or not root then
		return "They can't hear you"
	end
	local pelvis = pelvisOf(m) :: BasePart
	local o = orders[m]
	if o and o.owner ~= player then
		return "Someone else is talking to them"
	end
	if not o and (pelvis.Position - root.Position).Magnitude > NpcCommand.TALK_REACH then
		return "Walk up to them first"
	end
	if not o and action ~= "Bye" and countOf(player) >= NpcCommand.MAX_FOLLOWERS then
		return string.format("You already lead %d people", NpcCommand.MAX_FOLLOWERS)
	end
	if action == "Attack" then
		local target = bodyOf(targetInst)
		if not target or target == m then
			return "Pick someone to attack"
		end
		local tp = pelvisOf(target) :: BasePart
		if (tp.Position - pelvis.Position).Magnitude > NpcCommand.TARGET_REACH then
			return "That one is too far away"
		end
		if type(toyId) ~= "string" then
			return "Pick a weapon"
		end
		local toy = Toys.byId[toyId]
		if not toy or toy.kind ~= "hit" or not ProgressService.isUnlocked(player, toy) then
			return "You don't own that weapon"
		end
	end
	return nil
end

function NpcCommand.command(player: Player, action: string, npcInst: unknown, targetInst: unknown, toyId: unknown): (boolean, string?)
	local why = NpcCommand.refusal(player, action, npcInst, targetInst, toyId)
	if why then
		return false, why
	end
	local m = bodyOf(npcInst) :: Model
	if action == "Bye" then
		release(m)
		return true, nil
	end
	local o = orders[m]
	if not o then
		o = { owner = player, mode = action, nextHit = 0, place = player:GetAttribute("Place") }
		orders[m] = o
	end
	local order = o :: Order
	order.mode = action
	dropHeld(order)
	order.target = nil
	order.toy = nil
	m:SetAttribute("CommandedBy", player.UserId)
	m:SetAttribute("Command", action)
	if action == "Stay" then
		local p = pelvisOf(m) :: BasePart
		goTo(m, p.Position, p.Position + p.CFrame.LookVector)
	elseif action == "Attack" then
		order.target = bodyOf(targetInst)
		order.toy = Toys.byId[toyId :: string]
		order.held = hold(m, toyId :: string)
	end
	return true, nil
end

local function step(now: number)
	for m, o in orders do
		local pelvis = m.Parent and pelvisOf(m)
		local root = rootOf(o.owner)
		if not pelvis or m:GetAttribute("Vital") == "Dead" or not o.owner.Parent or not root or o.owner:GetAttribute("Place") ~= o.place then
			release(m)
			continue
		end
		if o.mode == "Follow" then
			local behind = root.Position - root.CFrame.LookVector * NpcCommand.FOLLOW_BACK
			if (pelvis.Position - behind).Magnitude > 2.5 then
				goTo(m, behind, root.Position)
			end
		elseif o.mode == "Attack" then
			local target = o.target and bodyOf(o.target)
			local tp = target and pelvisOf(target)
			if not target or not tp then
				-- (Down for good or gone: the job is done; it stays where it is.)
				o.mode = "Stay"
				m:SetAttribute("Command", "Stay")
				dropHeld(o)
				goTo(m, pelvis.Position, pelvis.Position + pelvis.CFrame.LookVector)
				continue
			end
			local gap = tp.Position - pelvis.Position
			local flat = Vector3.new(gap.X, 0, gap.Z)
			if flat.Magnitude > NpcCommand.STRIKE_REACH - 1 then
				goTo(m, tp.Position - (if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis) * (NpcCommand.STRIKE_REACH - 2), tp.Position)
			end
			local toy = o.toy
			if toy and flat.Magnitude <= NpcCommand.STRIKE_REACH and now >= o.nextHit then
				o.nextHit = now + math.max(toy.cooldown, NpcCommand.STRIKE_GAP_MIN)
				local dir = if gap.Magnitude > 0.01 then gap.Unit else Vector3.zAxis
				local chest = target:FindFirstChild("UpperTorso")
				local part = if chest and chest:IsA("BasePart") then chest else tp
				-- (No requester: the server applies the push itself, as nobody predicted it, and an
				-- NPC's hits never count as your takedowns, so they cannot be farmed.)
				pcall(HitService.applyToy, toy, part, part.Position, dir, nil)
			end
		end
	end
end

function NpcCommand.start()
	if not Config.NPC_COMMANDS then
		return
	end
	remote = Net.event(Net.Names.NpcCommand)
	remote.OnServerEvent:Connect(function(player: Player, action: unknown, npcInst: unknown, targetInst: unknown, toyId: unknown)
		local now = os.clock()
		if now - (lastRequest[player] or -math.huge) < NpcCommand.REQUEST_GAP then
			return
		end
		lastRequest[player] = now
		if type(action) ~= "string" then
			return
		end
		local ok, why = NpcCommand.command(player, action, npcInst, targetInst, toyId)
		remote:FireClient(player, if ok then "Done" else "Refused", { action = action, text = why })
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
		for m, o in orders do
			if o.owner == player then
				release(m)
			end
		end
	end)
	-- The Talk prompt on every NPC (new ones as they come).
	local function addPrompt(m: Instance)
		if not m:IsA("Model") or m:FindFirstChild("TalkPrompt", true) or m:GetAttribute("Minigame") or m:GetAttribute("Chaser") then
			return
		end
		local head = m:FindFirstChild("Head")
		if not head or not head:IsA("BasePart") then
			return
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TalkPrompt"
		prompt.ActionText = "Talk"
		prompt.ObjectText = tostring(m:GetAttribute("PersonName") or "Dummy")
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = 9
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Style = Enum.ProximityPromptStyle.Default
		prompt.Parent = head
		prompt.Triggered:Connect(function(player: Player)
			local body = bodyOf(m)
			local root = rootOf(player)
			local pelvis = body and pelvisOf(body)
			if not body or not root or not pelvis then
				return
			end
			-- Who could be attacked: the nearest other bodies (not players).
			local near: { { model: Model, name: string, d: number } } = {}
			local folder = Workspace:FindFirstChild("Dummies")
			for _, other in if folder then folder:GetChildren() else {} do
				local ob = bodyOf(other)
				local op = ob and pelvisOf(ob)
				if ob and op and ob ~= body then
					local d = (op.Position - pelvis.Position).Magnitude
					if d <= NpcCommand.TARGET_REACH then
						table.insert(near, { model = ob, name = tostring(ob:GetAttribute("PersonName") or "Dummy"), d = d })
					end
				end
			end
			table.sort(near, function(a, b)
				return a.d < b.d
			end)
			local targets = {}
			for i = 1, math.min(5, #near) do
				table.insert(targets, { model = near[i].model, name = near[i].name })
			end
			remote:FireClient(player, "Open", { npc = body, name = prompt.ObjectText, targets = targets, weapons = NpcCommand.weaponsOf(player), mode = body:GetAttribute("Command") })
		end)
	end
	task.spawn(function()
	local folder = Workspace:WaitForChild("Dummies", 30)
	if folder then
		for _, m in folder:GetChildren() do
			addPrompt(m)
		end
		folder.ChildAdded:Connect(function(m)
			task.defer(addPrompt, m)
		end)
	end
	end)
	task.spawn(function()
		while true do
			task.wait(NpcCommand.TICK)
			step(os.clock())
		end
	end)
end

return NpcCommand
