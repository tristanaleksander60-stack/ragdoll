--!strict
-- RAGDOLL_10 THE v6 FIT PASS, item 1 (Config.BODY_FIT): the shape of the approved v6 body, written from
-- art/models/mannequin/build_mannequin_v6.py (its signed-distance parts are the mesh). Every attach point (holes,
-- bandages, held props, rides, X-ray bones, physics parts) reads its size from here instead of guessing, so nothing
-- floats off, sinks in or pokes through.
-- Units are studs in the v6 mesh's rest space: X right, Y up, Z back (the face looks to -Z), right side (+X) given,
-- the left side is its mirror. The neck top is at Y = 1.84 and the soles at Y = -2.25 (the mesh is 4.39 tall, the
-- game's round head sits on top).
local BodyShape = {}

export type Profile = { r0: number, r1: number, depth0: number?, depth1: number? } -- radius at the joint end, at the far end

-- The joints (right side).
BodyShape.JOINT = {
	Neck = Vector3.new(0, 1.84, 0),
	Shoulder = Vector3.new(1.33, 1.34, 0),
	Elbow = Vector3.new(1.53, 0.7, -0.03),
	Wrist = Vector3.new(1.64, 0.12, -0.08),
	Hip = Vector3.new(0.55, -0.3, 0),
	Knee = Vector3.new(0.55, -1.05, 0),
	Ankle = Vector3.new(0.55, -1.76, 0.01),
	Sole = Vector3.new(0.55, -2.25, -0.2),
}

-- Each R15 part's round cross-section along its length (v6 limbs are round: as deep as they are wide).
BodyShape.LIMB = {
	UpperArm = { r0 = 0.375, r1 = 0.35 },
	LowerArm = { r0 = 0.35, r1 = 0.3 },
	UpperLeg = { r0 = 0.47, r1 = 0.43 },
	LowerLeg = { r0 = 0.41, r1 = 0.33 },
	Neck = { r0 = 0.3, r1 = 0.28 },
} :: { [string]: Profile }

-- The torso: half width and half depth at three heights (it is 1.6 deep at the chest and belly).
BodyShape.TORSO = {
	{ y = 1.03, halfWidth = 0.97, halfDepth = 0.8 }, -- the chest
	{ y = 0.42, halfWidth = 0.94, halfDepth = 0.82 }, -- the belly (bulges 0.05 forward)
	{ y = -0.2, halfWidth = 0.88, halfDepth = 0.74 }, -- the hips
}

-- The hand: a thick palm (facing the body), 4 separate fingers curled half open, a short thumb in front.
BodyShape.HAND = {
	palm = Vector3.new(1.66, -0.15, -0.06), -- the palm's centre
	palmHalf = Vector3.new(0.17, 0.26, 0.36), -- its half thickness (X), half height (Y), half width (Z)
	grip = Vector3.new(1.55, -0.42, -0.08), -- where a held handle sits: inside the curl of the fingers
	thumbTip = Vector3.new(1.56, -0.37, -0.55),
	fingerRadius = 0.072,
}

-- The boot: a round toe and heel with a dark sole.
BodyShape.BOOT = { centre = Vector3.new(0.55, -2.0, -0.2), half = Vector3.new(0.36, 0.25, 0.66) }

-- The yellow-black marks (outward normal), as on the renders.
BodyShape.MARK = {
	Chest = { at = Vector3.new(0, 1.1, -0.8), normal = Vector3.new(0, 0, -1), radius = 0.3 },
	UpperArm = { at = Vector3.new(1.8, 0.96, 0), normal = Vector3.new(1, 0, 0), radius = 0.17 },
	Thigh = { at = Vector3.new(1.0, -0.7, 0), normal = Vector3.new(1, 0, 0), radius = 0.17 },
}

-- The chest plate (CPR hands go here): centre and half size on the front of the chest.
BodyShape.CHEST_PLATE = { centre = Vector3.new(0, 1.1, -0.8), halfWidth = 0.74, halfHeight = 0.5 }

-- The game's head on top of the neck.
BodyShape.HEAD = { centre = Vector3.new(0, 2.6, 0), radius = 0.84 }

-- The whole body's shares of the mass (RAGDOLL_FEEL): the heavier, chunkier v6 body falls and rolls with weight.
BodyShape.MASS_SHARE = {
	UpperTorso = 0.24, LowerTorso = 0.16, Head = 0.08,
	UpperArm = 0.025, LowerArm = 0.017, Hand = 0.008,
	UpperLeg = 0.09, LowerLeg = 0.05, Foot = 0.02,
}

local function limbKey(partName: string): string?
	for _, k in { "UpperArm", "LowerArm", "UpperLeg", "LowerLeg" } do
		if string.find(partName, k, 1, true) then
			return k
		end
	end
	return nil
end

-- The radius of an R15 limb part at fraction t along it (0 at its upper joint, 1 at its lower), or nil for a part
-- that is not a round limb (the torso, the head, the hands and feet).
function BodyShape.radius(partName: string, t: number?): number?
	local k = limbKey(partName)
	local p = k and BodyShape.LIMB[k]
	if not p then
		return nil
	end
	local f = math.clamp(t or 0.5, 0, 1)
	return p.r0 + (p.r1 - p.r0) * f
end

-- How far out from a limb part's axis something wrapped round it (a bandage, a sling) sits: the v6 radius + 0.05.
function BodyShape.wrapRadius(partName: string, t: number?): number?
	local r = BodyShape.radius(partName, t)
	return if r then r + 0.05 else nil
end

-- The torso's half width and half depth at a height (linear between the three measured rings).
function BodyShape.torsoAt(y: number): (number, number)
	local rings = BodyShape.TORSO
	if y >= rings[1].y then
		return rings[1].halfWidth, rings[1].halfDepth
	end
	for i = 1, #rings - 1 do
		local a, b = rings[i], rings[i + 1]
		if y >= b.y then
			local f = (a.y - y) / (a.y - b.y)
			return a.halfWidth + (b.halfWidth - a.halfWidth) * f, a.halfDepth + (b.halfDepth - a.halfDepth) * f
		end
	end
	local last = rings[#rings]
	return last.halfWidth, last.halfDepth
end

-- Whether the v6 shape is in use (both switches on and the imported body there).
function BodyShape.active(): boolean
	local Config = require(script.Parent:WaitForChild("Config")) :: any
	if not (Config.BODY_FIT and Config.SMOOTH_BODY_V6) then
		return false
	end
	return game:GetService("ReplicatedStorage"):FindFirstChild("SmoothBodyV6") ~= nil
end

return BodyShape
