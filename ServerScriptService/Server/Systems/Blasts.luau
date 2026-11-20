--!strict
-- Every explosion in the lab: TNT, firecracker, shockwave, sticky bomb, big boom (ToyService sets
-- them off), build crates (BuildService) and the black hole's last gasp. One rule for players: a
-- blast only ever knocks over the player who set it off, never anyone else (server events, which
-- everyone sees coming, knock players themselves in EventService).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DummyControl = require(script.Parent.DummyControl)
local FxService = require(script.Parent.FxService)
local Knockables = require(script.Parent.Knockables)
local PlayerRagdoll = require(script.Parent.PlayerRagdoll)
local Props = require(script.Parent.Props)
local VitalsService = require(script.Parent.VitalsService)
local Anatomy = require(game:GetService("ReplicatedStorage").Shared.Anatomy)
local Zones = require(game:GetService("ReplicatedStorage").Shared.Zones)

-- Up close, a real explosion can take a limb off (Config.SEVERING): within this share of its radius,
-- with this chance per body (the limb nearest the blast).
local SEVER_WITHIN = 0.35
local SEVER_CHANCE = { TNT = 0.45, StickyBomb = 0.45, BigBoom = 0.7 }

local Blasts = {}

-- Players hitting players (round 3, M1): only in the shared plaza, where both stand, and nobody
-- gets hurt (a knock, never a wound). Never yourself through this path. The positions default to
-- where their avatars are (tests pass them).
local function rootOf(who: Instance): Vector3?
	local character = if who:IsA("Player") then who.Character else nil
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end
function Blasts.pvpReaches(source: Instance, other: Instance, sourceAt: Vector3?, otherAt: Vector3?): boolean
	if other == source then
		return false
	end
	local a, b = sourceAt or rootOf(source), otherAt or rootOf(other)
	return a ~= nil and b ~= nil and Zones.isPlaza(a) and Zones.isPlaza(b)
end

-- How big a blast is: its reach, how fast it sends a dummy (at the edge, at the centre), the same
-- for its player, how much of the push goes up, whether it sets off TNT nearby, how hard it shoves
-- props, its effect, and whether it has the engine's explosion flash (small ones only spark).
-- Physics tuning, so it lives here and not in the catalog (Shared/Toys).
export type Blast = {
	radius: number,
	dummyMin: number,
	dummyMax: number,
	playerMin: number,
	playerMax: number,
	lift: number,
	chain: boolean,
	propPush: number,
	fxSpeed: number,
	toyId: string,
	explosion: boolean,
}

Blasts.KINDS = {
	TNT = { radius = 20, dummyMin = 35, dummyMax = 120, playerMin = 30, playerMax = 80, lift = 0.75, chain = true, propPush = 1, fxSpeed = 140, toyId = "TNT", explosion = true },
	Firecracker = { radius = 9, dummyMin = 14, dummyMax = 36, playerMin = 10, playerMax = 24, lift = 0.95, chain = false, propPush = 0.4, fxSpeed = 45, toyId = "Firecracker", explosion = false },
	Shockwave = { radius = 26, dummyMin = 30, dummyMax = 70, playerMin = 25, playerMax = 50, lift = 0.25, chain = false, propPush = 0.8, fxSpeed = 80, toyId = "Shockwave", explosion = false },
	StickyBomb = { radius = 13, dummyMin = 30, dummyMax = 95, playerMin = 25, playerMax = 60, lift = 0.8, chain = true, propPush = 0.8, fxSpeed = 120, toyId = "StickyBomb", explosion = true },
	BigBoom = { radius = 36, dummyMin = 45, dummyMax = 140, playerMin = 40, playerMax = 90, lift = 0.8, chain = true, propPush = 1.4, fxSpeed = 220, toyId = "BigBoom", explosion = true },
} :: { [string]: Blast }

-- Told about every chaining blast (build crates go off with it): (center, radius, who set it off).
Blasts.listeners = {} :: { (center: Vector3, radius: number, source: Player?) -> () }

-- Where a client-simulated bomb may go off: where it is, but never far from where the server last
-- knew it (its owner's client moves it, so the server keeps it near the spot it checked).
function Blasts.clampTo(position: Vector3, anchor: Vector3, drift: number): Vector3
	local offset = position - anchor
	if offset.Magnitude <= drift then
		return position
	end
	return anchor + offset.Unit * drift
end

function Blasts.dummiesNear(center: Vector3, radius: number): { Model }
	local found = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	for _, model in if dummies then dummies:GetChildren() else {} do
		local pelvis = model:FindFirstChild("LowerTorso") :: BasePart?
		if model:IsA("Model") and pelvis and (pelvis.Position - center).Magnitude <= radius then
			table.insert(found, model)
		end
	end
	return found
end

local function away(offset: Vector3, lift: number): Vector3
	local flat = Vector3.new(offset.X, 0, offset.Z)
	return ((if flat.Magnitude > 0.01 then flat.Unit else Vector3.zero) * (1 - lift * 0.4) + Vector3.new(0, lift, 0)).Unit
end

local function flash(center: Vector3)
	local e = Instance.new("Explosion")
	e.Position = center
	e.BlastPressure = 0
	e.BlastRadius = 0
	e.DestroyJointRadiusPercent = 0
	e.ExplosionType = Enum.ExplosionType.NoCraters
	e.Parent = Workspace
end

-- Whether a blast set off by `source` may move or set off this prop: only that player's own props
-- (and the lab's, owned by nobody). Someone else's TNT never goes off early, and their props are
-- never pushed into them.
local function belongsTo(prop: Instance, source: Player?): boolean
	local owner = (prop:GetAttribute("Owner") :: number?) or 0
	return owner == 0 or (source ~= nil and owner == source.UserId)
end
Blasts.belongsTo = belongsTo -- the fan and the black hole follow the same rule

-- A blast at a point: knocks dummies and props away, the one who set it off if they stood too
-- close (unless `spareSource`: a bomb carried far from where it was stuck), and sets off their own
-- TNT nearby when it chains. `exclude`: the crate or bomb that went off.
function Blasts.blast(center: Vector3, kind: Blast, exclude: Instance?, source: Player?, spareSource: boolean?)
	if kind.explosion then
		flash(center)
	end
	FxService.hit(center, kind.fxSpeed, kind.toyId, if source then source.UserId else nil)
	local radius = kind.radius
	for _, model in Blasts.dummiesNear(center, radius) do
		local pelvis = model:FindFirstChild("LowerTorso") :: BasePart?
		-- (A blast by the edge never reaches into a lab its player may not enter: round 3, M1.)
		if pelvis and (not source or Zones.mayReach(source, pelvis.Position)) then
			local offset = pelvis.Position - center
			local falloff = 1 - math.clamp(offset.Magnitude / radius, 0, 1)
			local mass = (model:GetAttribute("Mass") :: number?) or 10
			local speed = kind.dummyMin + (kind.dummyMax - kind.dummyMin) * falloff
			DummyControl.hit(model, pelvis, away(offset, kind.lift) * speed * mass, pelvis.Position, nil, source)
			-- The blast's wound (shrapnel and burns, worse up close) and, right by a real
			-- explosion, maybe a limb.
			if model:GetAttribute("Frozen") ~= true then
				local chance = if kind.explosion and offset.Magnitude <= radius * SEVER_WITHIN then SEVER_CHANCE[kind.toyId] or 0 else 0
				VitalsService.wound(model, pelvis, pelvis.Position, source, 0.4 + 1.2 * falloff, { zone = Anatomy.zones.Blast })
				if chance > 0 and math.random() < chance then
					local nearest, best = nil :: string?, math.huge
					for name, limb in Anatomy.LIMBS do
						local first = model:FindFirstChild(limb.parts[1])
						if first and first:IsA("BasePart") and (first.Position - center).Magnitude < best then
							nearest, best = name, (first.Position - center).Magnitude
						end
					end
					if nearest then
						VitalsService.sever(model, nearest)
					end
				end
			end
		end
	end
	local character = source and source.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if source and not spareSource and root and root:IsA("BasePart") and Players:GetPlayerByUserId(source.UserId) then
		local offset = root.Position - center
		if offset.Magnitude < radius then
			local falloff = 1 - math.clamp(offset.Magnitude / radius, 0, 1)
			PlayerRagdoll.knock(source, away(offset, kind.lift) * (kind.playerMin + (kind.playerMax - kind.playerMin) * falloff))
		end
	end
	-- Other players in reach fly too, in the plaza only (Blasts.pvpReaches; no wounds on players).
	if source then
		for _, other in Players:GetPlayers() do
			if Blasts.pvpReaches(source, other) then
				local oc = other.Character
				local oroot = oc and oc:FindFirstChild("HumanoidRootPart")
				if oroot and oroot:IsA("BasePart") then
					local offset = oroot.Position - center
					if offset.Magnitude < radius then
						local falloff = 1 - math.clamp(offset.Magnitude / radius, 0, 1)
						-- (One knock per player each PLAZA_GAP, hits and blasts together.)
						PlayerRagdoll.plazaKnock(other, away(offset, kind.lift) * (kind.playerMin + (kind.playerMax - kind.playerMin) * falloff))
					end
				end
			end
		end
	end
	-- (UI audit 21 Nov 2026: the lab's barrels, crates and cones fly too.)
	Knockables.blast(center, radius)
	-- Props in reach fly too, and other TNT goes off a beat later: chain reactions.
	for _, near in Props.near(center, radius, exclude) do
		local prop = near.prop
		if not belongsTo(prop, source) then
			continue
		end
		local falloff = 1 - near.offset.Magnitude / radius
		if kind.chain and (prop.Name == "TNT" or prop.Name == "BigBoom") and prop:GetAttribute("Chain") ~= true then
			task.delay(0.08 + 0.1 * (1 - falloff), function()
				if prop.Parent then
					prop:SetAttribute("Chain", true)
				end
			end)
		end
		Props.push(prop, away(near.offset, 0.7) * (25 + 55 * falloff) * kind.propPush)
	end
	if kind.chain then
		for _, listener in Blasts.listeners do
			task.spawn(listener, center, radius, source)
		end
	end
end

-- A TNT blast (crates in builds go off with this too); source: the owner of the crate.
function Blasts.explode(center: Vector3, exclude: Instance?, source: Player?)
	Blasts.blast(center, Blasts.KINDS.TNT, exclude, source)
end

return Blasts
