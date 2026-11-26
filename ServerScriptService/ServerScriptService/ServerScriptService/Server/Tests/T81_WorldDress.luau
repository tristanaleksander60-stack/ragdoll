--!strict
-- World/Feel v2 (Config.WORLD_V2): a lab's dressing and the Christmas lab's are pictures only (every
-- part anchored, never colliding, never hit by a ray, never touched), stay inside the lab's part and
-- lamp budgets, and build their lamps switched off and tagged for the screen's budget (WorldLights).
-- Built here into a scratch folder far from everything; a lab already built must carry its dressing.
-- The dummies' test suits are never green (green is dead).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Systems = script.Parent.Parent:WaitForChild("Systems")
local WorldDress = require(Systems:WaitForChild("WorldDress"))
local Playground = require(Systems:WaitForChild("Playground")) :: any
local DummyFactory = require(Systems:WaitForChild("DummyFactory")) :: any

local function check(folder: Instance, what: string): (number, number)
	local parts, lights = 0, 0
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
			assert(d.Anchored, what .. ": a loose part " .. d.Name)
			assert(not d.CanCollide and not d.CanQuery and not d.CanTouch, what .. ": " .. d.Name .. " collides, is hit by rays or listens for touches")
			assert(d.Size.X == d.Size.X and d.Position.Y == d.Position.Y, what .. ": a part with no size or place (NaN)")
		elseif d:IsA("Light") then
			lights += 1
			assert(not d.Enabled, what .. ": a lamp built switched on (" .. d:GetFullName() .. ")")
			assert(CollectionService:HasTag(d, WorldDress.LIGHT_TAG), what .. ": a lamp the screen's budget never sees")
		elseif d:IsA("LuaSourceContainer") then
			error(what .. ": a script in the dressing")
		end
	end
	return parts, lights
end

return {
	name = "T81_WorldDress",
	timeout = 10,
	run = function(): string?
		local scratch = Instance.new("Folder")
		scratch.Name = "T81Scratch"
		scratch.Parent = Workspace
		local ground = Vector3.new(5000, 400, 5000)
		local plan = {
			cannonPad = Vector3.new(48, 1, 6),
			landing = Playground.cannonLanding(ground + Vector3.new(48, 1, 6)) - ground,
			velocity = Vector3.new(-0.45, 0.8, -0.4).Unit * 120,
			gravity = Workspace.Gravity,
			stations = Playground.STATIONS,
			maxLights = Config.WORLD_V2_LAB_LIGHTS,
		}
		local ok, err = pcall(function()
			local f = WorldDress.dress(scratch, ground, plan)
			local parts, lights = check(f, "lab")
			assert(parts > 60, "the lab's dressing is nearly empty (" .. parts .. " parts)")
			assert(parts <= Config.WORLD_V2_LAB_PARTS, string.format("the lab's dressing has %d parts (budget %d)", parts, Config.WORLD_V2_LAB_PARTS))
			assert(lights <= Config.WORLD_V2_LAB_LIGHTS, string.format("the lab's dressing has %d lamps (budget %d)", lights, Config.WORLD_V2_LAB_LIGHTS))
			local plaza = WorldDress.dress(scratch, ground + Vector3.new(400, 0, 0), nil)
			local pp, pl = check(plaza, "plaza")
			local xmas = WorldDress.dressChristmas(scratch, ground, Playground.CHRISTMAS_SPOTS)
			local xp, xl = check(xmas, "christmas")
			return string.format("lab %d parts / %d lamps (budget %d / %d); plaza %d / %d; Christmas %d / %d", parts, lights, Config.WORLD_V2_LAB_PARTS, Config.WORLD_V2_LAB_LIGHTS, pp, pl, xp, xl)
		end)
		scratch:Destroy()
		assert(ok, tostring(err))
		local note = err :: any
		-- A lab already built carries its dressing.
		if Config.WORLD_V2 then
			local root = Workspace:FindFirstChild("Playground")
			for _, lab in (if root then root:GetChildren() else {}) do
				if string.match(lab.Name, "^Lab%d+$") then
					assert(lab:FindFirstChild(WorldDress.FOLDER), lab.Name .. " was built without its WORLD_V2 dressing")
				end
			end
		end
		for _, c in DummyFactory.SUITS or {} do
			assert(not (c.G > c.R + 0.12 and c.G > c.B + 0.12), "a test suit is green (green means dead)")
		end
		return note
	end,
}
