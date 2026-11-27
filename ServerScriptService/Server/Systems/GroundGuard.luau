--!strict
-- v4 A2 (owner: "things fall half through the ground"): a quiet guard. Every CHECK_EVERY s it looks
-- at each dummy and crowd body that is at rest; if solid ground (terrain or a colliding part) sits
-- above its pelvis within LOOK_UP studs, the body is buried in it, and is lifted to stand on top.
-- Only a short look up (not from the sky), so a body under a stair or a table is left alone.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local GroundGuard = {}

GroundGuard.CHECK_EVERY = 2 -- s
GroundGuard.LOOK_UP = 3 -- studs above the pelvis the ray starts
GroundGuard.BURIED_BY = 0.6 -- studs: ground this far over the pelvis counts as buried
GroundGuard.REST_SPEED = 4 -- studs/s: only bodies at rest (a flying body passes through floors by itself)
GroundGuard.lifted = 0 -- (tests and the log)
-- NOW 2 (owner, 26 Nov 2026: "ragdolls fall through or half into the ground"): a body with no ground
-- under it at all fell through: it goes back on top of the first surface above it (from FALL_LOOK_UP),
-- moving or not. A head or chest sunk into the ground (not only the pelvis) counts as buried too.
GroundGuard.FALL_LOOK_UP = 120 -- studs above a fallen body to look for the surface it came through
GroundGuard.FALL_LOOK_DOWN = 400 -- studs under a body: nothing solid there = it fell through
GroundGuard.SINK_PARTS = { "LowerTorso", "UpperTorso", "Head" }
GroundGuard.rescued = 0
GroundGuard.HAND_BACK = 0.5 -- s the server keeps a body it moved before its player simulates it again

-- Ground is terrain or an anchored, colliding part (never another body, a player, a car or water:
-- a pile of ragdolls or a body afloat at the Island is left as it is).
local function isGround(inst: Instance): boolean
	if inst:IsA("Terrain") then
		return true
	end
	return inst:IsA("BasePart") and inst.CanCollide and inst.Anchored
end

local function solidHit(from: Vector3, dir: Vector3, params: RaycastParams): RaycastResult?
	-- (Past see-through, non-colliding or moving pieces: snow, signs, glass, bodies, cars.)
	local ignore = params.FilterDescendantsInstances
	for _ = 1, 6 do
		local hit = Workspace:Raycast(from, dir, params)
		if not hit then
			return nil
		end
		local inst = hit.Instance
		if isGround(inst) then
			return hit
		end
		table.insert(ignore, inst)
		params.FilterDescendantsInstances = ignore
	end
	return nil
end

-- Moves a body up by `dy`. A body is simulated on its lab player's machine, which would put it
-- straight back: the server takes it for a moment, moves it, and hands it back.
local function lift(model: Model, dy: number)
	local owner: Player? = nil
	local parts: { BasePart } = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and not part.Anchored then
			table.insert(parts, part)
			if not owner then
				local ok, who = pcall(part.GetNetworkOwner, part)
				if ok and who then
					owner = who
				end
			end
		end
	end
	for _, part in parts do
		pcall(part.SetNetworkOwner, part, nil)
	end
	model:PivotTo(model:GetPivot() + Vector3.new(0, dy, 0))
	if owner then
		local back = owner
		task.delay(GroundGuard.HAND_BACK, function()
			if back.Parent == nil or model.Parent == nil then
				return
			end
			for _, part in parts do
				if part.Parent and not part.Anchored then
					pcall(part.SetNetworkOwner, part, back)
				end
			end
		end)
	end
end

-- Lifts `model` if buried; true when it moved it.
function GroundGuard.check(model: Model): boolean
	local pelvis = model:FindFirstChild("LowerTorso")
	if not pelvis or not pelvis:IsA("BasePart") or pelvis.Anchored then
		return false
	end
	-- (A creature or machine that holds a body, the mole underground included, owns where it is.)
	if model:GetAttribute("InMachine") ~= nil or model:GetAttribute("MachineHidden") ~= nil then
		return false
	end
	-- (27 Nov late, owner: carried into the tower, a body was "sent to the top of the machine": a carried body is the
	-- player's, never lifted; Config.GROUND_INSIDE_ONLY below.)
	if model:GetAttribute("Held") == true then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	-- (Every body and every player: only real ground counts.)
	local skip: { Instance } = { model }
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(skip, dummies)
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	params.FilterDescendantsInstances = skip
	-- (NOW 2: fell through? nothing solid under it: back on top of the surface above, at any speed.)
	if (require(game:GetService("ReplicatedStorage").Shared.Config) :: any).GROUND_RESCUE then
		local under = solidHit(pelvis.Position, Vector3.new(0, -GroundGuard.FALL_LOOK_DOWN, 0), params)
		if not under then
			params.FilterDescendantsInstances = skip
			local top = solidHit(pelvis.Position + Vector3.new(0, GroundGuard.FALL_LOOK_UP, 0), Vector3.new(0, -GroundGuard.FALL_LOOK_UP, 0), params)
			if top then
				for _, part in model:GetDescendants() do
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					end
				end
				lift(model, top.Position.Y - pelvis.Position.Y + 3)
				GroundGuard.rescued += 1
				return true
			end
		end
		params.FilterDescendantsInstances = skip
	end
	if pelvis.AssemblyLinearVelocity.Magnitude > GroundGuard.REST_SPEED then
		return false
	end
	-- (NOW 2: the head or chest sunk in counts too, not only the pelvis.)
	local partsToCheck = if (require(game:GetService("ReplicatedStorage").Shared.Config) :: any).GROUND_RESCUE then GroundGuard.SINK_PARTS else { "LowerTorso" }
	for _, name in partsToCheck do
		local part = model:FindFirstChild(name)
		if not (part and part:IsA("BasePart")) then
			continue
		end
		params.FilterDescendantsInstances = skip
		local from = part.Position + Vector3.new(0, GroundGuard.LOOK_UP, 0)
		local hit = solidHit(from, Vector3.new(0, -GroundGuard.LOOK_UP - 1, 0), params)
		-- (GROUND_INSIDE_ONLY: a floor, stair or beam ABOVE a body inside a building (the tower's next storey) is a ceiling,
		-- not ground it is buried in: it counts only when the part's middle is really inside that solid.)
		local inside = true
		if hit and (require(game:GetService("ReplicatedStorage").Shared.Config) :: any).GROUND_INSIDE_ONLY then
			local op = OverlapParams.new()
			op.FilterType = Enum.RaycastFilterType.Exclude
			op.FilterDescendantsInstances = skip
			inside = false
			for _, h in Workspace:GetPartBoundsInRadius(part.Position, 0.35, op) do
				if isGround(h) then
					inside = true
					break
				end
			end
			if not inside and (hit :: RaycastResult).Instance:IsA("Terrain") then
				inside = true -- (terrain over a body is ground it sank into)
			end
		end
		if hit and inside and hit.Position.Y > part.Position.Y + GroundGuard.BURIED_BY then
			local up = hit.Position.Y - part.Position.Y + 3
			lift(model, up)
			GroundGuard.lifted += 1
			return true
		end
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
