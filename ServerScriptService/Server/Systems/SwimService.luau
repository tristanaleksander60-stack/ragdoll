--!strict
-- F78 part 1 (owner: "ragdollen skal svømme eller drukne"; Config.REAL_WATER): ragdolls in the real terrain water. Every
-- water body has an invisible box tagged WaterVolume (LabOwnerMap realWater). 5 times a second each ragdoll near one is
-- tested (pelvis inside the box):
--   * going in: a splash cry ("Help!", "I can't swim!", "Cold!") and the attribute InWater (the terrain water itself
--     makes the limp body float and bob);
--   * a living, awake one that is not held climbs out after SWIM_FOR s: it is set standing on the bank just outside the
--     nearest side of the box, facing away from the water, and says "Brr!" (attribute Wet for 20 s: drips on screens);
--   * a knocked-out or dead one just floats (kid-friendly: no drowning effects beyond that).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SwimService = {}

SwimService.SWIM_FOR = 8
SwimService.LINES_IN = { "Help!", "I can't swim!", "Cold!", "Splash!" }
SwimService.LINES_OUT = { "Brr!", "So cold!", "I'm soaked!" }

local since: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

local function say(m: Model, line: string)
	m:SetAttribute("MoodSay", line)
	task.delay(2.5, function()
		if m.Parent and m:GetAttribute("MoodSay") == line then
			m:SetAttribute("MoodSay", nil)
		end
	end)
end

local function boxOf(at: Vector3): BasePart?
	for _, v in CollectionService:GetTagged("WaterVolume") do
		if v:IsA("BasePart") then
			local l = v.CFrame:PointToObjectSpace(at)
			local h = v.Size / 2 + Vector3.new(0.5, 2, 0.5)
			if math.abs(l.X) < h.X and math.abs(l.Y) < h.Y and math.abs(l.Z) < h.Z then
				return v
			end
		end
	end
	return nil
end

local function climbOut(m: Model, box: BasePart, at: Vector3)
	local l = box.CFrame:PointToObjectSpace(at)
	local h = box.Size / 2
	-- the nearest side, 4 studs past it
	local dx, dz = h.X - math.abs(l.X), h.Z - math.abs(l.Z)
	local out = if dx < dz then Vector3.new(math.sign(l.X) * (h.X + 5), 0, l.Z) else Vector3.new(l.X, 0, math.sign(l.Z) * (h.Z + 5))
	local world = box.CFrame:PointToWorldSpace(out)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.FilterDescendantsInstances = { (m.Parent or m) :: Instance } -- (every ragdoll: only real ground)
	local hit = Workspace:Raycast(world + Vector3.new(0, 30, 0), Vector3.new(0, -60, 0), params)
	if not hit then
		return
	end
	local stand = hit.Position + Vector3.new(0, 3.2, 0)
	local away = Vector3.new(stand.X - box.Position.X, 0, stand.Z - box.Position.Z)
	local DC = require(script.Parent:WaitForChild("DummyControl")) :: any
	pcall(DC.move, m, CFrame.lookAt(stand, stand + (if away.Magnitude > 0.1 then away.Unit else Vector3.zAxis)))
	m:SetAttribute("Home", stand)
	m:SetAttribute("Wet", true)
	say(m, SwimService.LINES_OUT[math.random(1, #SwimService.LINES_OUT)])
	task.delay(20, function()
		if m.Parent then
			m:SetAttribute("Wet", nil)
		end
	end)
end

local function step(dummies: Instance)
	if #CollectionService:GetTagged("WaterVolume") == 0 then
		return
	end
	local now = os.clock()
	for _, m in dummies:GetChildren() do
		local pe = m:FindFirstChild("LowerTorso")
		if not (m:IsA("Model") and pe and pe:IsA("BasePart")) then
			continue
		end
		local box = boxOf(pe.Position)
		if not box then
			if since[m] then
				since[m] = nil
				m:SetAttribute("InWater", nil)
			end
			continue
		end
		if not since[m] then
			since[m] = now
			m:SetAttribute("InWater", true)
			local vital = m:GetAttribute("Vital")
			if vital ~= "Dead" and vital ~= "Unconscious" then
				say(m, SwimService.LINES_IN[math.random(1, #SwimService.LINES_IN)])
			end
		end
		local vital = m:GetAttribute("Vital")
		local awake = vital ~= "Dead" and vital ~= "Unconscious"
		if awake and m:GetAttribute("Held") ~= true and m:GetAttribute("InMachine") == nil and now - (since[m] :: number) > SwimService.SWIM_FOR then
			since[m] = nil
			m:SetAttribute("InWater", nil)
			climbOut(m, box, pe.Position)
		end
	end
end

function SwimService.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.REAL_WATER then
		return
	end
	task.spawn(function()
		local dummies = Workspace:WaitForChild("Dummies", 120)
		if not dummies then
			return
		end
		while true do
			task.wait(0.2)
			pcall(step, dummies)
		end
	end)
end

return SwimService
