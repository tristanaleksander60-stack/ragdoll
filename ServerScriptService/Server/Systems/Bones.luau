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

-- D12 part 2 (DAMAGE_12.md 2): every weapon class does its own bone damage (the base at force 1; melee from a tap to a
-- full charge). Shots to break a fresh lower leg: light pistol ~5, heavy pistol ~3, auto ~10, rifle ~3, sniper 1.
Bones.CLASS = {
	Blaster = { 18 }, -- light pistol
	Deagle = { 32 }, Revolver = { 32 }, GoldenDeagle = { 32 }, -- heavy pistol
	SMG = { 9 }, TommyGun = { 9 }, LMG = { 9 }, Minigun = { 9 }, NailGun = { 9 }, AK = { 12 }, -- auto
	DMR = { 38 }, -- rifle
	Shotgun = { 26 }, -- (one wound per blast: the pellets together)
	Sniper = { 95 },
	Bow = { 10, 42 }, Crossbow = { 42 }, -- (the bow by its draw)
	Poke = { 2, 6 }, Slap = { 4, 12 }, Shove = { 4, 12 }, Punch = { 4, 14 }, Kick = { 6, 18 }, Uppercut = { 6, 18 }, Glove = { 5, 16 }, MegaSlap = { 10, 30 }, -- fists
	Bat = { 22, 60 }, Golf = { 22, 60 }, Pan = { 18, 50 }, Crowbar = { 24, 64 }, -- bats and clubs
	Hammer = { 30, 95 }, -- heavy (can shatter)
	Axe = { 26, 70 }, Cleaver = { 26, 70 }, Katana = { 26, 70 }, Chainsaw = { 26, 70 }, PlasmaBlade = { 30, 80 }, -- blades act blunt
} :: { [string]: { number } }
Bones.BLAST_BASE = 120 -- at the centre, down to 0 at the edge, on the bone it hits

-- The force of one hit: guns by range (point blank 1.3, normal 1.0, far 0.6); melee and bows by the charge.
function Bones.damageFor(toyId: string?, charge: number?, range: number?, kind: string, power: number): number
	local c = toyId and Bones.CLASS[toyId]
	if kind == "blast" then
		-- (Blasts pass power 0.4 + 1.2 x falloff)
		return Bones.BLAST_BASE * math.clamp((power - 0.4) / 1.2, 0, 1)
	elseif not c then
		return (Bones.BASE[kind] or Bones.BASE.blow) * math.clamp(power, 0, 4)
	elseif #c >= 2 then
		local k = math.clamp(charge or 0, 0, 1)
		return c[1] + (c[2] - c[1]) * k
	end
	local force = 1
	if range then
		force = if range < 8 then 1.3 elseif range > 90 then 0.6 else 1.0 - math.clamp((range - 40) / 50, 0, 1) * 0.4
	end
	return c[1] * force
end

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
function Bones.hit(model: Model, part: BasePart, power: number, kind: string, toyId: string?, charge: number?, range: number?): string?
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
	local dmg = Bones.damageFor(toyId, charge, range, kind, power) * factor
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
	-- (D12: broken ribs: it hunches and holds its chest a while, unless it is busy with a mood of its own)
	if newStage >= 3 and name == "UpperTorso" and model:GetAttribute("Mood") == nil then
		model:SetAttribute("Mood", "WrapMid")
		task.delay(6, function()
			if model:GetAttribute("Mood") == "WrapMid" then
				model:SetAttribute("Mood", nil)
			end
		end)
	end
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
