--!strict
-- 3.4 GIANT FAN (docs/MACHINES_10.md "GIANT FAN"; Config.FAN_10). The Giant Fan pass's fan (MapShopService builds it in
-- the owner's lab) gets:
--   * a speed dial: a prompt on the fan steps OFF > 1 > 2 > 3 > OFF (one tap, phone too), shown on a small board;
--   * the blade spins up on every screen (GateMotion "Spin", its speed by the dial), a wind roar rising in pitch, and dust
--     and leaves blowing out in a cone in front of it;
--   * ragdolls in the cone: speed 1 pushes them along, 2 lifts and slides them, 3 blows them backwards tumbling;
--   * at speed 3 the distance a body was blown pops where it lands ("BLOWN 74 studs!") with a NEW BEST (FanBest);
--   * at speed 3 a player in the cone is pushed back too, but can lean into it (a slow walk forward).
-- The cone points along the fan's front (+Z of the plan spot, as before).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local FanMachine = {}

FanMachine.TICK = 0.25
FanMachine.BLADE = { 0, 6, 13, 24 } -- blade turn speed by dial (rad/s)
FanMachine.REACH = { 0, 30, 42, 56 } -- cone length by dial (studs)
FanMachine.PLAYER_PUSH = 9 -- studs/s taken off a player walking into it at speed 3

type Fan = { model: Model, owner: Player, front: Vector3, mouth: Vector3, sound: Sound?, dust: ParticleEmitter?, board: TextLabel?, prompt: ProximityPrompt? }

local fans: { [Model]: Fan } = {}
local blownAt: { [Model]: { from: Vector3, t: number, by: Player } } = setmetatable({}, { __mode = "k" }) :: any
local rest: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function speedOf(f: Fan): number
	return (f.model:GetAttribute("FanSpeed") :: number?) or 0
end

local function show(f: Fan)
	local k = speedOf(f)
	local blade = f.model:FindFirstChild("Blade", true)
	if blade then
		blade:SetAttribute("Speed", FanMachine.BLADE[k + 1])
	end
	if f.sound then
		if k == 0 then
			f.sound:Stop()
		else
			f.sound.PlaybackSpeed = 0.6 + 0.3 * k
			f.sound.Volume = 0.25 + 0.15 * k
			if not f.sound.IsPlaying then
				f.sound:Play()
			end
		end
	end
	if f.dust then
		f.dust.Rate = ({ 0, 10, 24, 45 })[k + 1]
		f.dust.Speed = NumberRange.new(10 + 10 * k, 18 + 14 * k)
	end
	if f.board then
		f.board.Text = if k == 0 then "FAN: OFF" else "FAN: " .. string.rep("|", k) .. "  " .. tostring(k)
	end
	if f.prompt then
		f.prompt.ActionText = if k == 3 then "Turn off" else "Speed " .. tostring(k + 1)
	end
end

function FanMachine.setup(m: Model, owner: Player)
	if fans[m] then
		return
	end
	local cf, size = m:GetBoundingBox()
	local front = Vector3.new(0, 0, 1)
	local mouth = cf.Position + front * (size.Z / 2 + 1)
	local f: Fan = { model = m, owner = owner, front = front, mouth = mouth, sound = nil, dust = nil, board = nil, prompt = nil }
	-- the blade spins on each screen round its own thin axis
	local blade = m:FindFirstChild("Blade", true)
	if blade and blade:IsA("BasePart") then
		local s = blade.Size
		local axis = if s.Z <= s.X and s.Z <= s.Y then blade.CFrame.LookVector elseif s.X <= s.Y then blade.CFrame.RightVector else blade.CFrame.UpVector
		blade:SetAttribute("Axis", axis)
		blade:SetAttribute("Speed", 0)
		CollectionService:AddTag(blade, "Spin")
	end
	-- the roar, the dust cone and the dial board sit on an invisible anchor at the fan's mouth
	local anchor = Instance.new("Part")
	anchor.Name = "FanMouth"
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch, anchor.Transparency = true, false, false, false, 1
	anchor.Size = Vector3.new(size.X * 0.8, size.Y * 0.8, 0.2)
	anchor.CFrame = CFrame.lookAt(mouth, mouth + front)
	anchor.Parent = m
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://9125742262" -- (PSE "Plasma Trails Constant Airy Whooshing Windy 2": the wind roar)
	sound.Looped = true
	sound.RollOffMaxDistance = 100
	sound.Parent = anchor
	f.sound = sound
	local dust = Instance.new("ParticleEmitter")
	dust.EmissionDirection = Enum.NormalId.Front
	dust.SpreadAngle = Vector2.new(18, 18)
	dust.Lifetime = NumberRange.new(1, 1.8)
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.9) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	dust.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 175, 90)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190, 160, 110)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(205, 195, 175)),
	})
	dust.Rotation = NumberRange.new(0, 360)
	dust.RotSpeed = NumberRange.new(-300, 300)
	dust.Rate = 0
	dust.Parent = anchor
	f.dust = dust
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(150, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, size.Y / 2 + 2, 0)
	gui.MaxDistance = 80
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(30, 50, 34)
	label.BackgroundTransparency = 0.2
	label.TextColor3 = Color3.fromRGB(190, 255, 170)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = label
	f.board = label
	local pp = Instance.new("ProximityPrompt")
	pp.ObjectText = "Giant Fan"
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 14
	pp.RequiresLineOfSight = false
	pp.Parent = anchor
	f.prompt = pp
	local last = 0
	pp.Triggered:Connect(function(_player)
		if os.clock() - last < 0.4 then
			return
		end
		last = os.clock()
		m:SetAttribute("FanSpeed", (speedOf(f) + 1) % 4)
		show(f)
	end)
	if m:GetAttribute("FanSpeed") == nil then
		m:SetAttribute("FanSpeed", 2) -- (it was always blowing: it starts on 2)
	end
	fans[m] = f
	show(f)
	m.Destroying:Once(function()
		fans[m] = nil
	end)
end

function FanMachine.active(m: Model?): boolean
	return m ~= nil and fans[m] ~= nil
end

local function blow(f: Fan)
	local k = speedOf(f)
	if k == 0 then
		return
	end
	local reach = FanMachine.REACH[k + 1]
	local centre = f.mouth + f.front * (reach / 2) + Vector3.new(0, 3, 0)
	local box = CFrame.lookAt(centre, centre + f.front)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local dummies = Workspace:FindFirstChild("Dummies")
	params.FilterDescendantsInstances = if dummies then { dummies } else {}
	local DC = lazy("DummyControl")
	local seen: { [Model]: boolean } = {}
	for _, part in Workspace:GetPartBoundsInBox(box, Vector3.new(16 + k * 4, 12, reach), params) do
		local m = part:FindFirstAncestorOfClass("Model")
		while m and m.Parent ~= dummies do
			m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model") or nil
		end
		if m and not seen[m] and m:GetAttribute("InMachine") == nil and m:GetAttribute("Held") ~= true then
			seen[m] = true
			if k == 1 then
				DC.nudge(m, f.front * 16 + Vector3.new(0, 4, 0))
			elseif k == 2 then
				DC.nudge(m, f.front * 30 + Vector3.new(0, 14, 0))
			elseif os.clock() - (rest[m] or 0) > 1.6 then
				rest[m] = os.clock()
				local pe = m:FindFirstChild("LowerTorso")
				if pe and pe:IsA("BasePart") and not blownAt[m] then
					blownAt[m] = { from = pe.Position, t = os.clock(), by = f.owner }
				end
				DC.push(m, f.front * 95 + Vector3.new(0, 55, 0), f.owner)
			end
		end
	end
	if k == 3 then
		for _, pl in Players:GetPlayers() do
			local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
			if r and r:IsA("BasePart") then
				local rel = box:PointToObjectSpace(r.Position)
				if math.abs(rel.X) < 10 + k * 2 and math.abs(rel.Y) < 8 and math.abs(rel.Z) < reach / 2 then
					-- (leaning in: a slow walk forward, never thrown)
					local v = r.AssemblyLinearVelocity
					r.AssemblyLinearVelocity = v + f.front * FanMachine.PLAYER_PUSH
				end
			end
		end
	end
end

local function scoreLandings()
	for m, b in blownAt do
		if os.clock() - b.t > 2.6 then
			blownAt[m] = nil
			local pe = m.Parent and m:FindFirstChild("LowerTorso")
			if pe and pe:IsA("BasePart") then
				local d = math.floor(Vector3.new(pe.Position.X - b.from.X, 0, pe.Position.Z - b.from.Z).Magnitude + 0.5)
				if d >= 8 then
					local text = "BLOWN " .. tostring(d) .. " studs!"
					local best = (b.by:GetAttribute("FanBest") :: number?) or 0
					if b.by.Parent and d > best then
						b.by:SetAttribute("FanBest", d)
						text ..= " NEW BEST!"
					end
					pcall(function()
						lazy("Playground").pop(pe.Position + Vector3.new(0, 4, 0), text, Color3.fromRGB(170, 240, 255))
					end)
				end
			end
		end
	end
end

function FanMachine.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.FAN_10 then
		return
	end
	task.spawn(function()
		while true do
			task.wait(FanMachine.TICK)
			for m, f in fans do
				if not m.Parent or not f.owner.Parent then
					fans[m] = nil
				else
					pcall(blow, f)
				end
			end
			pcall(scoreLandings)
		end
	end)
end

return FanMachine
