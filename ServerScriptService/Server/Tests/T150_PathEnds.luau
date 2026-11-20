--!strict
-- V9-0 F2/F3 (owner, 21 Nov 2026: "grey things through the path, the path also stops, boxy bushes"):
--   * every end of the lab's path network (a point used by one segment only) leads to its thing
--     (PathPlan.END_TARGETS): a named lab part within reach, or the garden's own walks;
--   * nothing that is not paving shows on the paving in the lab or on the plaza (a 3x3x3 sample of
--     every other part, from the paving's top to 0.9 studs over it; knockable props that roll are
--     left out), and every kerb stops where another walkway or the plaza begins;
--   * with FOLIAGE_V9 the verges hold real bushes and flowers, no balls or blocks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local PathPlan = require(Shared:WaitForChild("PathPlan")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

local PAVING = { PathSlab = true, PathJoint = true, Plaza = true, PlazaHeart = true, PlazaRose = true, GardenPath = true }
-- Things that may stand on a path for a moment (they are knocked about, or walk).
local MOVING = { Knockable = true }

local function isRound(p: BasePart): boolean
	return p:IsA("Part") and p.Shape == Enum.PartType.Cylinder
end

-- Parts that are not paving and show on top of some paving in `root`.
local function onPaving(root: Instance): { string }
	local pave: { BasePart } = {}
	local others: { BasePart } = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.95 then
			local n = d.Name
			if PAVING[n] then
				table.insert(pave, d)
			elseif string.sub(n, 1, 4) ~= "Path" and string.sub(n, 1, 5) ~= "Plaza" then
				local model = d:FindFirstAncestorWhichIsA("Model")
				if not (d:GetAttribute("Knockable") or (model and model:GetAttribute("Knockable")) or MOVING[n]) then
					table.insert(others, d)
				end
			end
		end
	end
	local hits: { string } = {}
	for _, o in others do
		-- (A tall thing (a lamp, a trunk) is one mesh whose box can hang over a path: only its foot,
		-- the middle of its box, counts. A low thing counts over its whole footprint.)
		local reach = if o.Size.Y > 3 then 0 else 1
		for _, pv in pave do
			if (o.Position - pv.Position).Magnitude < 60 then
				local top = pv.Position.Y + 0.17
				local hit = false
				for i = -reach, reach do
					for j = -1, 1 do
						for k = -reach, reach do
							local w = o.CFrame * Vector3.new(i * o.Size.X * 0.45, if reach == 0 then -(o.Size.Y / 2 - 0.2) else j * o.Size.Y * 0.45, k * o.Size.Z * 0.45)
							if w.Y > top - 0.02 and w.Y < top + 0.9 then
								local l = pv.CFrame:PointToObjectSpace(Vector3.new(w.X, pv.Position.Y, w.Z))
								if isRound(pv) then
									hit = hit or Vector2.new(l.Y, l.Z).Magnitude < pv.Size.Y / 2 - 0.3
								else
									hit = hit or (math.abs(l.X) < pv.Size.X / 2 - 0.3 and math.abs(l.Z) < pv.Size.Z / 2 - 0.3)
								end
							end
						end
					end
				end
				if hit then
					table.insert(hits, o:GetFullName())
					break
				end
			end
		end
	end
	return hits
end

return {
	name = "T150_PathEnds",
	timeout = 60,
	run = function(): string?
		if not (Config.PATHS and Config.LAYOUT_V2) then
			return "skipped (PATHS / LAYOUT_V2 off)"
		end
		assert(TestLib.waitFor(function()
			local pg = Workspace:FindFirstChild("Playground")
			local lab = pg and pg:FindFirstChild("Lab1")
			return lab ~= nil and lab:FindFirstChild("Paths") ~= nil and lab:FindFirstChild("CreatureYard") ~= nil
		end, 40), "no Lab1 with paths and creatures")
		local lab = (Workspace :: any).Playground.Lab1 :: Instance
		local Zones = require(Shared:WaitForChild("Zones")) :: any
		local o2 = Vector2.new(Zones.plotCenterX(1), 0) -- (Lab1's origin; plots sit on z 0)
		-- 1. Every end leads somewhere.
		local uses: { [string]: number } = {}
		for _, seg in PathPlan.LAB_SEGMENTS do
			uses[seg[1]] = (uses[seg[1]] or 0) + 1
			uses[seg[2]] = (uses[seg[2]] or 0) + 1
		end
		local ends = 0
		for name, n in uses do
			if n == 1 then
				ends += 1
				local target = PathPlan.END_TARGETS[name]
				assert(target, "the path end " .. name .. " leads nowhere (no END_TARGETS entry)")
				local at = o2 + PathPlan.LAB_POINTS[name]
				local best = math.huge
				for _, d in lab:GetDescendants() do
					if target.kind == "part" and d.Name == target.name and (d:IsA("Model") or d:IsA("BasePart")) then
						local p = (d :: any):GetPivot().Position
						best = math.min(best, Vector2.new(p.X - at.X, p.Z - at.Y).Magnitude)
					elseif d:IsA("BasePart") then
						local hitName = if target.kind == "part" then false else (d.Name == "PathJoint" or d.Name == "PathSlab") and d.Parent and d.Parent.Name == "Garden"
						if hitName then
							local l = d.CFrame:PointToObjectSpace(Vector3.new(at.X, d.Position.Y, at.Y))
							local dist = if target.kind == "part" then Vector2.new(d.Position.X - at.X, d.Position.Z - at.Y).Magnitude elseif isRound(d) then math.max(0, Vector2.new(l.Y, l.Z).Magnitude - d.Size.Y / 2) else math.max(0, math.abs(l.X) - d.Size.X / 2, math.abs(l.Z) - d.Size.Z / 2)
							best = math.min(best, dist)
						end
					end
				end
				assert(best <= target.reach, string.format("the path end %s is %.1f studs from its %s (reach %g)", name, best, if target.kind == "part" then target.name else "garden walk", target.reach))
			end
		end
		-- 2. Nothing shows on the paving (lab and plaza).
		local hits = onPaving(lab)
		local plaza = (Workspace :: any).Playground:FindFirstChild("Plaza")
		if plaza then
			for _, h in onPaving(plaza) do
				table.insert(hits, h)
			end
		end
		assert(#hits == 0, #hits .. " part(s) on the paving: " .. table.concat(hits, ", ", 1, math.min(#hits, 6)))
		-- 2b. (V9-0 review) No kerb lies on paving, in either folder: every kerb's middle line, sampled
		-- every half stud, stays off every paving piece (its own walk's included: it sits beside it).
		local pave: { BasePart } = {}
		for _, d in lab:GetDescendants() do
			if d:IsA("BasePart") and PAVING[d.Name] then
				table.insert(pave, d)
			end
		end
		local kerbs, badKerbs = 0, {}
		for _, k in lab:GetDescendants() do
			if k:IsA("BasePart") and k.Name == "PathKerb" then
				kerbs += 1
				local steps = math.max(1, math.ceil(k.Size.Z / 0.5))
				for i = 0, steps do
					local w = k.CFrame * Vector3.new(0, 0, (i / steps - 0.5) * k.Size.Z)
					local over = false
					for _, pv in pave do
						if (Vector2.new(pv.Position.X, pv.Position.Z) - Vector2.new(w.X, w.Z)).Magnitude < 40 then
							local l = pv.CFrame:PointToObjectSpace(Vector3.new(w.X, pv.Position.Y, w.Z))
							if isRound(pv) then
								over = Vector2.new(l.Y, l.Z).Magnitude < pv.Size.Y / 2 - 0.3
							else
								over = math.abs(l.X) < pv.Size.X / 2 - 0.3 and math.abs(l.Z) < pv.Size.Z / 2 - 0.3
							end
							if over then
								break
							end
						end
					end
					if over then
						table.insert(badKerbs, string.format("(%.0f, %.0f)", w.X - o2.X, w.Z - o2.Y))
						break
					end
				end
			end
		end
		assert(kerbs > 50, "only " .. kerbs .. " kerbs in the lab")
		assert(#badKerbs == 0, #badKerbs .. " kerb(s) across paving at " .. table.concat(badKerbs, ", ", 1, math.min(#badKerbs, 6)))
		-- 3. Real foliage on the verges.
		local real, fake = 0, 0
		for _, d in lab:GetDescendants() do
			if d.Name == "PathVergeBushRound" or d.Name == "PathVergeBushLeafy" or string.sub(d.Name, 1, 16) == "PathVergeFlowers" then
				real += 1
			elseif d.Name == "PathBush" or d.Name == "PathTuft" or d.Name == "PathFlower" then
				fake += 1
			end
		end
		if Config.FOLIAGE_V9 then
			assert(real >= 20 and fake == 0, string.format("verges: %d real plants, %d balls/blocks", real, fake))
		end
		return string.format("%d path ends each at its thing; nothing on the paving (lab + plaza); no kerb across paving; %d real plants on the verges, no balls or blocks", ends, real)
	end,
}
