--!strict
-- CreatureGrip (Config.CREATURE_GRIP). An animal really takes a ragdoll IN ITS MOUTH. Before, the bear and the T-rex
-- "held" a body by teleporting it to a guessed point every 0.1 s (DummyControl.move), so it jittered behind the animal,
-- took no harm and was let go as if nothing happened. Now:
--   * the mouth is found on the animal's own model: a part or Bone named like Jaw / LowerJaw / Mouth / Snout / Head (in
--     that order); else the front-top of its box;
--   * an invisible anchored GRIP part sits in the mouth and follows the animal every frame (whatever moves the animal:
--     PivotTo shakes, a walk);
--   * the bitten limb is joined to the grip with a BallSocket, the body is simulated by the SERVER while held (one
--     simulator, the animal's own), so it dangles and swings for real when the head shakes;
--   * every bite and shake gives real wounds through VitalsService (purple blood, mild: no severing), so a long maul can
--     knock it out or kill it;
--   * release(): the joint goes, the body goes back to its lab player's screen and is thrown.

local RunService = game:GetService("RunService")

local CreatureGrip = {}

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local MOUTH_NAMES = { "jaw", "lowerjaw", "jaw_lower", "mouth", "snout", "muzzle", "head" }

-- The mouth's world CFrame now (a Bone's live frame, a part's frame, or the box's front top).
function CreatureGrip.mouthOf(creature: Model): () -> CFrame
	local best: Instance? = nil
	local bestRank = math.huge
	for _, d in creature:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Bone") then
			local n = string.lower(d.Name)
			for rank, want in MOUTH_NAMES do
				if n == want or (rank <= 5 and string.find(n, want, 1, true)) then
					if rank < bestRank then
						best, bestRank = d, rank
					end
					break
				end
			end
		end
	end
	if best and best:IsA("Bone") then
		local bone = best
		return function()
			return bone.TransformedWorldCFrame
		end
	elseif best and best:IsA("BasePart") then
		local p = best
		local cf0 = creature:GetBoundingBox()
		-- a head part: its front, a bit down (where the teeth are)
		local off = p.CFrame:ToObjectSpace(CFrame.new(p.Position + cf0.LookVector * (p.Size.Z * 0.45) - Vector3.new(0, p.Size.Y * 0.2, 0)))
		return function()
			return p.CFrame * off
		end
	end
	local cf, size = creature:GetBoundingBox()
	local off = creature:GetPivot():ToObjectSpace(cf * CFrame.new(0, size.Y * 0.25, -size.Z * 0.48))
	return function()
		return creature:GetPivot() * off
	end
end

export type Grip = { model: Model, grip: BasePart, joint: BallSocketConstraint, conn: RBXScriptConnection, limb: BasePart, owner: Player? }

-- Takes `body` in the creature's mouth by `limbName` (default UpperTorso). Returns the grip, or nil.
function CreatureGrip.grab(creature: Model, body: Model, limbName: string?, by: Player?): Grip?
	local limb = body:FindFirstChild(limbName or "UpperTorso")
	if not (limb and limb:IsA("BasePart")) then
		return nil
	end
	local mouth = CreatureGrip.mouthOf(creature)
	local DummyControl = lazy("DummyControl")
	local owner = DummyControl.ownerOf(body)
	pcall(DummyControl.wake, body)
	pcall(DummyControl.setOwner, body, nil) -- (the server holds it: the same machine that moves the animal)
	local grip = Instance.new("Part")
	grip.Name = "MouthGrip"
	grip.Size = Vector3.new(0.4, 0.4, 0.4)
	grip.Transparency = 1
	grip.Anchored, grip.CanCollide, grip.CanQuery, grip.CanTouch = true, false, false, false
	grip.CFrame = mouth()
	grip.Parent = creature
	local a0 = Instance.new("Attachment")
	a0.Parent = grip
	local a1 = Instance.new("Attachment")
	a1.Parent = limb
	body:PivotTo(body:GetPivot() + (grip.Position - limb.Position)) -- (the whole body to the mouth at once: no limb torn from the rest)
	local joint = Instance.new("BallSocketConstraint")
	joint.Name = "MouthJoint"
	joint.Attachment0 = a0
	joint.Attachment1 = a1
	joint.Parent = grip
	body:SetAttribute("InMachine", "Jaws")
	body:SetAttribute("Held", true)
	local conn = RunService.Heartbeat:Connect(function()
		if grip.Parent then
			grip.CFrame = mouth()
		end
	end)
	-- the bite itself
	CreatureGrip.bite(body, limb, by, 2)
	return { model = body, grip = grip, joint = joint, conn = conn, limb = limb, owner = owner }
end

-- Tooth wounds on `limb` (n of them), real harm, mild look.
function CreatureGrip.bite(body: Model, limb: BasePart, by: Player?, n: number)
	for _ = 1, n do
		local at = limb.Position + Vector3.new((math.random() - 0.5) * limb.Size.X, (math.random() - 0.5) * limb.Size.Y, (math.random() - 0.5) * limb.Size.Z) * 0.8
		pcall(lazy("VitalsService").wound, body, limb, at, by, 0.55, { blunt = false, sever = 0 })
	end
end

-- Lets go: the joint goes, the body goes back to its player's screen and is thrown with `velocity`.
function CreatureGrip.release(g: Grip, velocity: Vector3?, by: Player?)
	g.conn:Disconnect()
	if g.joint.Parent then
		g.joint:Destroy()
	end
	if g.grip.Parent then
		g.grip:Destroy()
	end
	for _, a in g.limb:GetChildren() do
		if a:IsA("Attachment") and a.Name == "Attachment" then
			a:Destroy()
		end
	end
	g.model:SetAttribute("InMachine", nil)
	g.model:SetAttribute("Held", nil)
	local DummyControl = lazy("DummyControl")
	pcall(DummyControl.setOwner, g.model, g.owner)
	if velocity then
		task.defer(function()
			pcall(DummyControl.push, g.model, velocity, by)
		end)
	end
end

return CreatureGrip
