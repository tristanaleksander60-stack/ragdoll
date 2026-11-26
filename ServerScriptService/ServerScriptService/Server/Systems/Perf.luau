--!strict
-- 22 Nov 2026 (owner: "make the game run completely lag free"): 10,631 of 12,343 parts cast a shadow,
-- most of them small dressing (path stones, tufts, lamps, crates, fences). A shadow from a part this
-- small is barely seen but costs every screen each frame. Parts whose biggest side is under
-- SMALL studs stop casting shadows, now and whenever something is built later (labs, maps).
-- Bodies (dummies, players, the crowd) and anything moving keep theirs.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Perf = {}

Perf.SMALL = 6 -- studs: the biggest side under this casts no shadow

local function skip(p: BasePart): boolean
	if not p.Anchored then
		return true -- (bodies, cars, knockables: their shadows read the motion)
	end
	local model = p:FindFirstAncestorOfClass("Model")
	if model and (model:FindFirstChildOfClass("Humanoid") or Players:GetPlayerFromCharacter(model)) then
		return true
	end
	return false
end

local function trim(d: Instance)
	if d:IsA("BasePart") and d.CastShadow and not skip(d) then
		local s = d.Size
		if math.max(s.X, s.Y, s.Z) < Perf.SMALL then
			d.CastShadow = false
		end
	end
end

function Perf.start()
	local n = 0
	for _, d in Workspace:GetDescendants() do
		trim(d)
		n += 1
		if n % 4000 == 0 then
			task.wait() -- (spread over a few frames at boot)
		end
	end
	Workspace.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			task.defer(trim, d) -- (after its builder set its size and anchoring)
		end
	end)
end

return Perf
