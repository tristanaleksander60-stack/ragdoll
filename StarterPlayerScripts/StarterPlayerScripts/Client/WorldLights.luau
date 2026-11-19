--!strict
-- World/Feel v2: the world's lamps (WorldDress tags them WorldLight and builds them switched off)
-- are lit on this screen only, and only the nearest few the device can afford (Config.FX_CAPS
-- lights: a phone 4, a computer 14). Looked at again every LOOK s; another lab's lamps, which
-- PlotPrivacy takes off this screen, never count.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local WorldLights = {}

WorldLights.TAG = "WorldLight"
WorldLights.LOOK = 1 -- s
WorldLights.REACH = 220 -- studs: further than this a lamp stays off whatever the budget

local started = false

-- The lamps to light: the nearest `budget` of those within REACH of `from`. Pure apart from reading
-- the lamps' positions (T80 checks the budget holds).
function WorldLights.pick(lamps: { { light: Light, position: Vector3 } }, from: Vector3, budget: number): { [Light]: boolean }
	local near = {}
	for _, l in lamps do
		local d = (l.position - from).Magnitude
		if d <= WorldLights.REACH then
			table.insert(near, { light = l.light, d = d })
		end
	end
	table.sort(near, function(a, b)
		return a.d < b.d
	end)
	local on: { [Light]: boolean } = {}
	for i = 1, math.min(budget, #near) do
		on[near[i].light] = true
	end
	return on
end

local function positionOf(light: Light): Vector3?
	local p = light.Parent
	if p and p:IsA("BasePart") then
		return p.Position
	elseif p and p:IsA("Attachment") then
		return p.WorldPosition
	end
	return nil
end

function WorldLights.start(budget: number)
	if started then
		return
	end
	started = true
	task.spawn(function()
		while true do
			local camera = Workspace.CurrentCamera
			if camera then
				local lamps = {}
				local all = CollectionService:GetTagged(WorldLights.TAG)
				for _, inst in all do
					if inst:IsA("Light") then
						local at = if inst:IsDescendantOf(Workspace) then positionOf(inst) else nil
						if at then
							table.insert(lamps, { light = inst, position = at })
						end
					end
				end
				local on = WorldLights.pick(lamps, camera.CFrame.Position, budget)
				for _, inst in all do
					if inst:IsA("Light") then
						local want = on[inst] == true
						if inst.Enabled ~= want then
							inst.Enabled = want
						end
					end
				end
			end
			task.wait(WorldLights.LOOK)
		end
	end)
end

return WorldLights
