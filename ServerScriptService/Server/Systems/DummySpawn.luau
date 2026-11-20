--!strict
-- V8-2.5 (dummy types and a SPAWN key, Config.DUMMY_TYPES): a player drops an extra dummy of a type
-- where they aim, in their own lab: MINI (small, flies far), HEAVY (big, hard to move), BOUNCY
-- (bounces off everything) and FLOPPY (light as a pillow). Each wears its type on a chest plate.
-- The server checks every request: a known type, a point in your own lab within REACH of you, one
-- per GAP s, and at most CAP[device] of yours at once (the oldest goes). Reset (SandboxService) and
-- leaving remove them. Remote Net "Spawn": client -> server ("Spawn", type, at).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Net = require(Shared:WaitForChild("Net")) :: any

local DummySpawn = {}

DummySpawn.REACH = 80 -- studs from you to the spot
DummySpawn.GAP = 1.5 -- s between two spawns
DummySpawn.CAP = table.freeze({ phone = 3, tablet = 5, pc = 6, console = 6 }) :: { [string]: number }

type Spec = { scale: number, density: number, elasticity: number, color: Color3, plate: string }
DummySpawn.TYPES = table.freeze({
	MINI = { scale = 0.6, density = 0.7, elasticity = 0.3, color = Color3.fromRGB(120, 210, 255), plate = "MINI" },
	HEAVY = { scale = 1.3, density = 3, elasticity = 0.1, color = Color3.fromRGB(150, 150, 160), plate = "HEAVY" },
	BOUNCY = { scale = 1, density = 0.9, elasticity = 1, color = Color3.fromRGB(255, 140, 220), plate = "BOUNCY" },
	FLOPPY = { scale = 1, density = 0.25, elasticity = 0.2, color = Color3.fromRGB(255, 220, 120), plate = "FLOPPY" },
}) :: { [string]: Spec }

local mine: { [Player]: { Model } } = {}
local last: { [Player]: number } = {}

local function capFor(player: Player): number
	local SessionStats = require(script.Parent:WaitForChild("SessionStats")) :: any
	local record = SessionStats.recordFor(player)
	return DummySpawn.CAP[record and record.plat or "pc"] or 6
end

local function dress(model: Model, spec: Spec)
	if spec.scale ~= 1 then
		pcall(function()
			model:ScaleTo(spec.scale)
		end)
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CustomPhysicalProperties = PhysicalProperties.new(spec.density, 0.4, spec.elasticity, 1, if spec.elasticity >= 0.9 then 100 else 1)
		end
	end
	model:SetAttribute("DummyType", spec.plate)
	-- The chest plate: the type in big letters on the chest (a SurfaceGui, so the crowd-style
	-- strip of marks leaves it).
	local chest = model:FindFirstChild("UpperTorso")
	if chest and chest:IsA("BasePart") then
		local gui = Instance.new("SurfaceGui")
		gui.Name = "TypePlate"
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(200, 120)
		gui.LightInfluence = 0
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(0.9, 0, 0.5, 0)
		t.Position = UDim2.fromScale(0.05, 0.25)
		t.BackgroundColor3 = spec.color
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = Color3.fromRGB(20, 20, 30)
		t.Text = spec.plate
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 12)
		c.Parent = t
		t.Parent = gui
		gui.Parent = chest
	end
end

-- A player's spawned dummies now (tests).
function DummySpawn.of(player: Player): { Model }
	return mine[player] or {}
end

-- Drops one dummy of `kind` at `at` for `player`. Returns it, or nil and why not.
function DummySpawn.spawnFor(player: Player, kind: unknown, at: unknown): (Model?, string?)
	if not Config.DUMMY_TYPES then
		return nil, "off"
	end
	local spec = if type(kind) == "string" then DummySpawn.TYPES[kind] else nil
	if not spec or typeof(at) ~= "Vector3" then
		return nil, "bad request"
	end
	local point = at :: Vector3
	if point.X ~= point.X or point.Y ~= point.Y or point.Z ~= point.Z then
		return nil, "bad request"
	end
	local Lab = require(script.Parent:WaitForChild("Lab")) :: any
	if Lab.ownerAt(point) ~= player then
		return nil, "only in your own lab"
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or (root.Position - point).Magnitude > DummySpawn.REACH then
		return nil, "too far"
	end
	local now = os.clock()
	if now - (last[player] or -math.huge) < DummySpawn.GAP then
		return nil, "slow down"
	end
	last[player] = now
	local list = mine[player] or {}
	mine[player] = list
	while #list >= capFor(player) do
		local oldest = table.remove(list, 1)
		if oldest then
			oldest:Destroy()
		end
	end
	local DummyFactory = require(script.Parent:WaitForChild("DummyFactory")) :: any
	local model = DummyFactory.spawn(point + Vector3.new(0, 4, 0), root.Position, player)
	model.Name = "SpawnedDummy"
	dress(model, spec)
	table.insert(list, model)
	return model, nil
end

-- Removes a player's spawned dummies (Reset, leaving).
function DummySpawn.clear(player: Player)
	for _, m in mine[player] or {} do
		if m.Parent then
			m:Destroy()
		end
	end
	mine[player] = nil
end

function DummySpawn.start()
	local remote = Net.event(Net.Names.Spawn)
	if not Config.DUMMY_TYPES then
		return
	end
	-- lihfolk-ignore: remote-unvalidated-args (what is only compared with "Spawn"; kind and at are checked in spawnFor)
	;(remote :: RemoteEvent).OnServerEvent:Connect(function(player: Player, what: unknown, kind: unknown, at: unknown)
		if what ~= "Spawn" then
			return
		end
		local model, why = DummySpawn.spawnFor(player, kind, at)
		if not model and why and why ~= "slow down" then
			remote:FireClient(player, "Refused", why)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		DummySpawn.clear(player)
		last[player] = nil
	end)
end

return DummySpawn
