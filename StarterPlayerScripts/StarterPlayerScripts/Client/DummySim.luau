--!strict
-- Simulates the dummies the server gave to this player. Runs the same ActiveRagdoll the server
-- uses, reports every state change back (so the server can mirror joint topology), and carries out
-- commands for hits that happened elsewhere (props, blasts, other players).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local ActiveRagdoll = require(Shared:WaitForChild("Ragdoll"):WaitForChild("ActiveRagdoll"))

local player = Players.LocalPlayer

local DummySim = {}

-- Effects of our own simulation: (kind, model, position, speed). Set by the effects controller.
DummySim.onEvent = nil :: ((kind: string, model: Model, position: Vector3, speed: number) -> ())?

local watched: { [Model]: RBXScriptConnection } = {}

local function isMine(model: Model): boolean
	return model:GetAttribute("Owner") == player.UserId
end

local function complete(model: Model): boolean
	local joints = 0
	for _, d in model:GetDescendants() do
		if d:IsA("AnimationConstraint") then
			joints += 1
		end
	end
	return joints >= 15 and model:FindFirstChild("LowerTorso") ~= nil and model:GetAttribute("Mass") ~= nil
end

local function refresh(model: Model)
	if isMine(model) and model.Parent then
		if not ActiveRagdoll.isSimulating(model) then
			-- Streaming can deliver a model before all of it; wait until it is whole.
			local started = os.clock()
			while not complete(model) and os.clock() - started < 5 do
				task.wait(0.1)
			end
			if isMine(model) and model.Parent and not ActiveRagdoll.isSimulating(model) then
				local ok, err = ActiveRagdoll.setup(model)
				if not ok then
					warn("[DummySim] cannot simulate", model:GetFullName(), err)
				end
			end
		end
	elseif ActiveRagdoll.isSimulating(model) then
		ActiveRagdoll.teardown(model)
	end
end

local function watch(model: Instance)
	if not model:IsA("Model") or watched[model] then
		return
	end
	local m = model :: Model
	watched[m] = m:GetAttributeChangedSignal("Owner"):Connect(function()
		task.spawn(refresh, m)
	end)
	m:GetAttributeChangedSignal("Frozen"):Connect(function()
		if ActiveRagdoll.isSimulating(m) then
			ActiveRagdoll.setExternalFrozen(m, m:GetAttribute("Frozen") == true)
		end
	end)
	m.Destroying:Once(function()
		local c = watched[m]
		if c then
			c:Disconnect()
		end
		watched[m] = nil
		ActiveRagdoll.teardown(m)
	end)
	task.spawn(refresh, m)
end

local function onCommand(kind: string, model: Model, a: any, b: any, c: any, d: any, e: any)
	if typeof(model) ~= "Instance" or not ActiveRagdoll.isSimulating(model) then
		return
	end
	if kind == "Hit" then
		local part = model:FindFirstChild(a)
		if part and part:IsA("BasePart") and typeof(b) == "Vector3" and typeof(c) == "Vector3" then
			ActiveRagdoll.hit(model, part, b, c, if type(d) == "number" then d else nil, if type(e) == "number" then math.clamp(e, 0, 3) else nil)
		end
	elseif kind == "Push" and typeof(a) == "Vector3" then
		ActiveRagdoll.push(model, a)
	elseif kind == "Heal" then
		ActiveRagdoll.heal(model)
	elseif kind == "Reset" and typeof(a) == "CFrame" then
		model:PivotTo(a)
		ActiveRagdoll.reset(model)
	elseif kind == "Move" and typeof(a) == "CFrame" then
		model:PivotTo(a) -- (somewhere else, as it is: hurt, stuck things and all)
	end
end

function DummySim.start()
	local topology = Net.event(Net.Names.Topology)
	-- A hit can change a dummy's state several times in one frame (ragdoll, then out cold, then a
	-- limb breaks); only the last one is sent, once per frame, so a blast on many dummies never
	-- runs into the server's rate limit.
	type Report = { state: string, broken: { string }, held: boolean }
	local outgoing: { [Model]: Report } = {}
	local flushing = false
	local function flush()
		flushing = false
		for model, report in outgoing do
			if model.Parent and isMine(model) then
				topology:FireServer(model, report.state, report.broken, report.held)
			end
		end
		table.clear(outgoing)
	end
	ActiveRagdoll.onTransition = function(model: Model, state: string, broken: { string }, held: boolean)
		if isMine(model) then
			outgoing[model] = { state = state, broken = broken, held = held }
			if not flushing then
				flushing = true
				task.defer(flush)
			end
		end
	end
	ActiveRagdoll.onEvent = function(kind: string, model: Model, position: Vector3, speed: number)
		local listener = DummySim.onEvent
		if listener then
			listener(kind, model, position, speed)
		end
	end
	Net.event(Net.Names.DummyCmd).OnClientEvent:Connect(onCommand)

	local folder = Workspace:WaitForChild("Dummies")
	folder.ChildAdded:Connect(watch)
	for _, child in folder:GetChildren() do
		watch(child)
	end
end

-- The dummy model a part belongs to, if this client simulates it.
function DummySim.simulatedDummyOf(part: Instance): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:GetAttribute("IsDummy") == true then
			return if ActiveRagdoll.isSimulating(model) then model else nil
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

return DummySim
