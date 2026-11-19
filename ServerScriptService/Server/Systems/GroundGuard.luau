--!strict
-- v4 A2 (owner: "things fall half through the ground"): a quiet guard. Every CHECK_EVERY s it looks
-- at each dummy and crowd body that is at rest; if solid ground (terrain or a colliding part) sits
-- above its pelvis within LOOK_UP studs, the body is buried in it, and is lifted to stand on top.
-- Only a short look up (not from the sky), so a body under a stair or a table is left alone.

local Workspace = game:GetService("Workspace")

local GroundGuard = {}

GroundGuard.CHECK_EVERY = 2 -- s
GroundGuard.LOOK_UP = 3 -- studs above the pelvis the ray starts
GroundGuard.BURIED_BY = 0.6 -- studs: ground this far over the pelvis counts as buried
GroundGuard.REST_SPEED = 4 -- studs/s: only bodies at rest (a flying body passes through floors by itself)
GroundGuard.lifted = 0 -- (tests and the log)

local function solidHit(from: Vector3, dir: Vector3, params: RaycastParams): RaycastResult?
	-- (Past see-through, non-colliding pieces: snow, signs, glass.)
	local ignore = params.FilterDescendantsInstances
	for _ = 1, 4 do
		local hit = Workspace:Raycast(from, dir, params)
		if not hit then
			return nil
		end
		local inst = hit.Instance
		if inst:IsA("Terrain") or (inst:IsA("BasePart") and inst.CanCollide) then
			return hit
		end
		table.insert(ignore, inst)
		params.FilterDescendantsInstances = ignore
	end
	return nil
end

-- Lifts `model` if buried; true when it moved it.
function GroundGuard.check(model: Model): boolean
	local pelvis = model:FindFirstChild("LowerTorso")
	if not pelvis or not pelvis:IsA("BasePart") or pelvis.Anchored then
		return false
	end
	if pelvis.AssemblyLinearVelocity.Magnitude > GroundGuard.REST_SPEED then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model }
	local from = pelvis.Position + Vector3.new(0, GroundGuard.LOOK_UP, 0)
	local hit = solidHit(from, Vector3.new(0, -GroundGuard.LOOK_UP - 1, 0), params)
	if hit and hit.Position.Y > pelvis.Position.Y + GroundGuard.BURIED_BY then
		local up = hit.Position.Y - pelvis.Position.Y + 3
		model:PivotTo(model:GetPivot() + Vector3.new(0, up, 0))
		GroundGuard.lifted += 1
		return true
	end
	return false
end

function GroundGuard.start()
	task.spawn(function()
		while true do
			task.wait(GroundGuard.CHECK_EVERY)
			local folder = Workspace:FindFirstChild("Dummies")
			for _, model in if folder then folder:GetChildren() else {} do
				if model:IsA("Model") then
					pcall(GroundGuard.check, model)
				end
			end
		end
	end)
end

return GroundGuard
