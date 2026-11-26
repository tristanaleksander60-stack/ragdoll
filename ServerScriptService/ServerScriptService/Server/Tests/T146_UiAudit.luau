--!strict
-- UI audit (21 Nov 2026, before the ads): only what is needed, in the right place, and the lab's
-- things are real.
--   * the lab's barrels, crates and cones are knockables: a knock sets one loose and moving, and it
--     goes back to its spot, anchored, by itself;
--   * WEAPONS is one button (the bar's slab): HudV3's left squares are Shop and Lab;
--   * today's-machine signs are in studs (they shrink with distance), not pixel cards;
--   * a newcomer's launch gift and the weekend news wait out the first minutes;
--   * at most one idle dummy line on screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local Knockables = require(Systems:WaitForChild("Knockables")) :: any
local LabZones = require(Systems:WaitForChild("LabZones")) :: any
local LaunchGift = require(Systems:WaitForChild("LaunchGift")) :: any
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
local DummyLines = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DummyLines")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

return {
	name = "T146_UiAudit",
	timeout = 40,
	run = function(): string?
		-- The left squares (a pure module of the client's).
		local Client = StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("Client")
		local Layout = require(Client:WaitForChild("HudV3Layout")) :: any
		assert(not table.find(Layout.LEFT, "Weapons"), "WEAPONS is a square again beside the bar's own slab")
		assert(table.find(Layout.LEFT, "Shop") and table.find(Layout.LEFT, "Lab"), "Shop or Lab missing from the left squares")
		local rects = Layout.touchRects(Vector2.new(1180, 820), nil, nil)
		assert(#rects == #Layout.LEFT + 2, "the touch layout does not draw LEFT plus Maps and More")

		-- Waiting news and fewer floating words.
		assert(LaunchGift.NEWCOMER_AT > Config.QUIET_START, "the launch gift talks during a newcomer's quiet start")
		assert(DummyLines.IDLE_MAX <= 1, "more than one idle dummy line on screen")

		-- Today's machine: a sign in studs.
		assert(type(LabZones.PX_PER_STUD) == "number" and LabZones.PX_PER_STUD > 0, "no px-to-studs rule for the zone signs")
		local pg = Workspace:FindFirstChild("Playground")
		local signs, inStuds = 0, 0
		if pg then
			for _, d in pg:GetDescendants() do
				if d:IsA("BillboardGui") and d.Name == "ZoneSign" then
					signs += 1
					if d.Size.X.Offset == 0 and d.Size.X.Scale > 0 then
						inStuds += 1
					end
				end
			end
		end
		assert(signs == inStuds, string.format("%d of %d zone signs are pixel cards", signs - inStuds, signs))

		-- The knockables: wait for a lab with them (the labs build as players claim them).
		TestLib.waitFor(function()
			return next(Knockables.all()) ~= nil
		end, 20)
		local body: BasePart? = nil
		for b, model in Knockables.all() do
			if b.Parent and model.Parent and not Knockables.isLoose(b) then
				body = b
				break
			end
		end
		if not body then
			return string.format("skipped knockables (no lab dressed); %d zone signs in studs, left squares %s", signs, table.concat(Layout.LEFT, "+"))
		end
		local b = body :: BasePart
		local home = b.CFrame
		assert(b.Anchored and b.CanCollide, "a knockable at rest is not a solid anchored thing")
		Knockables.knockForTest(b, Vector3.new(0, 10, 30))
		assert(Knockables.isLoose(b) and not b.Anchored, "a knock did not set it loose")
		task.wait(0.4)
		local moved = (b.Position - home.Position).Magnitude
		assert(moved > 0.5, string.format("a knocked %s moved only %.2f studs", tostring(b.Parent and b.Parent.Name), moved))
		Knockables.sendHomeForTest(b)
		assert(b.Anchored and not Knockables.isLoose(b), "it did not settle back anchored")
		assert((b.Position - home.Position).Magnitude < 0.05, "it did not go back to its spot")
		return string.format("%s knocked %.1f studs and back home; %d zone signs in studs; left squares %s", tostring(b.Parent and b.Parent.Name), moved, signs, table.concat(Layout.LEFT, "+"))
	end,
}
