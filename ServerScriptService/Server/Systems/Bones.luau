--!strict
-- D12 DAMAGE 12/10, part 1 (owner: "Gør så man faktisk kan knække knoglerne afhængig af hvor mange gange man skyder og hvad
-- man slår/skyder med og hvor hårdt man slår"; docs/DAMAGE_12.md 1; Config.BONES_V2): every bone has its own INTEGRITY
-- (100 fresh). Every wound (VitalsService.wound: guns, melee, bites, blasts) takes integrity off the bone it hits:
--   damage = base (a round 20, a blow 14, a blast 60) x the hit's power (the weapon's wound stat x its charge or draw)
--            x the bone factor (hands, feet, ribs 1.3; lower arms and legs 1.1; upper arms, thighs, pelvis 0.9;
--              skull 0.8)
-- It ADDS UP until a heal or a revive. Stages: 100-70 whole, 70-40 HAIRLINE, 40-1 CRACKED, 0 BROKEN, and one hit that
-- takes 140%+ of what was left: SHATTERED. A limb that reaches BROKEN breaks for real: the attribute BreakReq is set and
-- the simulating screen's ActiveRagdoll breaks that joint (the limp, the dangle, the plaster), so guns break bones now
-- too (before, a round never broke anything). The stages are shared as the attribute BoneStages ("Part:stage;..."),
-- and Bones.hit returns the new stage's word for the hit card ("Left lower leg: CRACKED").

local Bones = {}

Bones.BASE = { round = 20, blow = 14, blast = 60 }
Bones.FACTOR = {
	LeftHand = 1.3, RightHand = 1.3, LeftFoot = 1.3, RightFoot = 1.3, UpperTorso = 1.3,
	LeftLowerArm = 1.1, RightLowerArm = 1.1, LeftLowerLeg = 1.1, RightLowerLeg = 1.1,
	LeftUpperArm = 0.9, RightUpperArm = 0.9, LeftUpperLeg = 0.9, RightUpperLeg = 0.9, LowerTorso = 0.9,
	Head = 0.8,
} :: { [string]: number }
Bones.LIMBS = {
	LeftHand = true, RightHand = true, LeftFoot = true, RightFoot = true,
	LeftLowerArm = true, RightLowerArm = true, LeftLowerLeg = true, RightLowerLeg = true,
	LeftUpperArm = true, RightUpperArm = true, LeftUpperLeg = true, RightUpperLeg = true,
} :: { [string]: boolean }

local STAGE_WORD = { [1] = "HAIRLINE", [2] = "CRACKED", [3] = "BROKEN", [4] = "SHATTERED" }

type BodyBones = { hp: { [string]: number }, stage: { [string]: number }, n: number }
local bodies: { [Model]: BodyBones } = setmetatable({}, { __mode = "k" }) :: any

local function stageOf(hp: number): number
	return if hp <= 0 then 3 elseif hp < 40 then 2 elseif hp < 70 then 1 else 0
end

local function share(model: Model, b: BodyBones)
	local parts = {}
	for name, s in b.stage do
		if s > 0 then
			table.insert(parts, name .. ":" .. tostring(s))
		end
	end
	model:SetAttribute("BoneStages", if #parts > 0 then table.concat(parts, ";") else nil)
end

-- One hit on a bone. kind: "round" | "blow" | "blast". Returns the stage word when the stage changed (for the hit
-- card), else nil.
function Bones.hit(model: Model, part: BasePart, power: number, kind: string): string?
	local factor = Bones.FACTOR[part.Name]
	if not factor then
		return nil
	end
	local b = bodies[model]
	if not b then
		b = { hp = {}, stage = {}, n = 0 }
		bodies[model] = b
	end
	local name = part.Name
	local before = b.hp[name] or 100
	if before <= 0 then
		return nil
	end
	local base = Bones.BASE[kind] or Bones.BASE.blow
	local dmg = base * math.clamp(power, 0, 4) * factor
	local after = math.max(0, before - dmg)
	b.hp[name] = after
	local oldStage = b.stage[name] or 0
	local newStage = stageOf(after)
	if after <= 0 and dmg >= before * 1.4 and before < 100 then
		newStage = 4 -- (one hit that took far more than was left: SHATTERED)
	elseif after <= 0 and dmg >= 140 then
		newStage = 4
	end
	if newStage == oldStage then
		return nil
	end
	b.stage[name] = newStage
	share(model, b)
	if newStage >= 3 and Bones.LIMBS[name] then
		-- the simulating screen breaks the joint for real (ActiveRagdoll watches BreakReq)
		b.n += 1
		model:SetAttribute("BreakReq", name .. "@" .. tostring(b.n))
	end
	return STAGE_WORD[newStage]
end

-- Healed (a bandage, the doctor, a full revive): every bone whole again.
function Bones.reset(model: Model)
	bodies[model] = nil
	model:SetAttribute("BoneStages", nil)
end

function Bones.stageOf(model: Model, partName: string): number
	local b = bodies[model]
	return if b then (b.stage[partName] or 0) else 0
end

return Bones
