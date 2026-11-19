--!strict
-- Round 5, phase 2b: what makes each gun its own, on the server (the client draws the rest:
-- Client/GunFeel). Called by HitService after a round it took (its rate and magazine already paid):
--   shotguns     PELLETS more rounds in a cone from the shooter's head (Shotgun 6, AutoShotgun 5,
--                DoubleBarrel 12: both barrels), each a lighter round on whatever body it meets
--   Sniper       the round goes on through up to PIERCE bodies behind the first; Railgun through
--                every body on the line (RAIL_REACH studs)
--   FlareGun     a burning flare sticks where it hit and glows for FLARE_TIME s
--   GoldenDeagle a round in the head throws gold sparks (Fx "GoldSpark")
-- Every extra round is a hit of this player's through HitService.applyToy (blame, wounds, takedowns
-- and budgets the same as any), never more than the gun's own count, and only on what the server
-- itself finds with its own rays.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Toys = require(Shared:WaitForChild("Toys"))
local Anatomy = require(Shared:WaitForChild("Anatomy"))
local Zones = require(Shared:WaitForChild("Zones"))

local FxService = require(script.Parent.FxService)

local WeaponMechanics = {}

WeaponMechanics.PELLETS = { Shotgun = 6, AutoShotgun = 5, DoubleBarrel = 12 } :: { [string]: number }
WeaponMechanics.SPREAD = { Shotgun = 5, AutoShotgun = 6, DoubleBarrel = 7 } :: { [string]: number } -- degrees
WeaponMechanics.PELLET_SHARE = 0.3 -- a pellet's push and wound against the gun's full round
WeaponMechanics.PELLET_REACH = 90
WeaponMechanics.PIERCE = 3 -- bodies a sniper round goes on through
WeaponMechanics.RAIL_REACH = 260
WeaponMechanics.FLARE_TIME = 8

-- Set by HitService (no require loop): applies one round to a body part as this player's.
WeaponMechanics.apply = nil :: ((toy: any, part: BasePart, position: Vector3, direction: Vector3, requester: Player?) -> string?)?

local pelletToys: { [string]: any } = {}
local function pelletOf(toy: Toys.Toy): any
	local p = pelletToys[toy.id]
	if not p then
		-- A lighter copy of the gun's round (the same id: sounds, blame and tracers stay the gun's).
		p = table.clone(toy :: any)
		p.speed = toy.speed * WeaponMechanics.PELLET_SHARE
		p.wound = toy.wound * WeaponMechanics.PELLET_SHARE
		p.sever = toy.sever * 0.5
		pelletToys[toy.id] = p
	end
	return p
end

local function dummyOf(part: Instance): Model?
	local m = part:FindFirstAncestorOfClass("Model")
	while m do
		if m:GetAttribute("IsDummy") == true then
			return m
		end
		m = m:FindFirstAncestorOfClass("Model")
	end
	return nil
end

local function headOf(player: Player): Vector3?
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	return if head and head:IsA("BasePart") then head.Position else nil
end

local function params(player: Player, extra: { Instance }?): RaycastParams
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	local list: { Instance } = {}
	if player.Character then
		table.insert(list, player.Character)
	end
	local fx = Workspace:FindFirstChild("LocalFx")
	if fx then
		table.insert(list, fx)
	end
	for _, i in extra or {} do
		table.insert(list, i)
	end
	p.FilterDescendantsInstances = list
	return p
end

-- A random direction within `degrees` of `dir`.
local rng = Random.new()
local function cone(dir: Vector3, degrees: number): Vector3
	local a = math.rad(degrees) * math.sqrt(rng:NextNumber())
	local spin = rng:NextNumber() * math.pi * 2
	local frame = CFrame.lookAt(Vector3.zero, dir)
	return (frame * CFrame.Angles(0, 0, spin) * CFrame.Angles(a, 0, 0)).LookVector
end

-- Shotgun pellets from the shooter's head towards the aim. Returns how many found a body.
function WeaponMechanics.pellets(player: Player, toy: Toys.Toy, aim: Vector3): number
	local count = WeaponMechanics.PELLETS[toy.id]
	local apply = WeaponMechanics.apply
	local from = headOf(player)
	if not count or not apply or not from then
		return 0
	end
	local dir = aim - from
	if dir.Magnitude < 0.1 then
		return 0
	end
	dir = dir.Unit
	local hits = 0
	local p = params(player)
	for _ = 1, count - 1 do -- (the first pellet is the round the player aimed)
		local d = cone(dir, WeaponMechanics.SPREAD[toy.id] or 5)
		local r = Workspace:Raycast(from, d * WeaponMechanics.PELLET_REACH, p)
		-- (Never into a lab this player may not reach: review fix, round 5.)
		if r and r.Instance:IsA("BasePart") and dummyOf(r.Instance) and Zones.mayReach(player, r.Position) then
			if apply(pelletOf(toy), r.Instance, r.Position, d, player) then
				hits += 1
			end
		end
	end
	return hits
end

-- A round that goes on through bodies: from the first body hit along the line. Returns bodies hit.
function WeaponMechanics.pierce(player: Player, toy: Toys.Toy, first: Model?, at: Vector3, direction: Vector3): number
	local apply = WeaponMechanics.apply
	local most = if toy.id == "Railgun" then 99 elseif toy.id == "Sniper" then WeaponMechanics.PIERCE else 0
	if most <= 0 or not apply or direction.Magnitude < 0.01 then
		return 0
	end
	local dir = direction.Unit
	local skip: { Instance } = {}
	if first then
		table.insert(skip, first)
	end
	local reach = if toy.id == "Railgun" then WeaponMechanics.RAIL_REACH else 160
	local from = at
	local hits = 0
	for _ = 1, math.min(most, 12) do
		local r = Workspace:Raycast(from, dir * reach, params(player, skip))
		if not r or not r.Instance:IsA("BasePart") then
			break
		end
		local body = dummyOf(r.Instance)
		if not body then
			if toy.id ~= "Railgun" then
				break -- (a wall stops a sniper round; the rail goes through everything)
			end
			table.insert(skip, r.Instance)
		else
			table.insert(skip, body)
			if not Zones.mayReach(player, r.Position) then
				break -- (a private lab stops the round: review fix)
			end
			if apply(toy, r.Instance, r.Position, dir, player) then
				hits += 1
			end
		end
		reach -= (r.Position - from).Magnitude
		from = r.Position
		if reach <= 1 then
			break
		end
	end
	return hits
end

-- A burning flare stuck to the part it hit (it rides along with the body), glowing a while.
function WeaponMechanics.flare(part: BasePart, position: Vector3)
	local f = Instance.new("Part")
	f.Name = "Flare"
	f.Shape = Enum.PartType.Ball
	f.Size = Vector3.new(0.45, 0.45, 0.45)
	f.Material = Enum.Material.Neon
	f.Color = Color3.fromRGB(255, 80, 40)
	f.CanCollide = false
	f.CanQuery = false
	f.CanTouch = false
	f.Massless = true
	f.CFrame = CFrame.new(position)
	f:SetAttribute("Gadget", true) -- (a reset takes it off: DummyControl.reset)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 90, 40)
	light.Range = 16
	light.Brightness = 3
	light.Parent = f
	local fire = Instance.new("Fire")
	fire.Size = 2
	fire.Heat = 6
	fire.Color = Color3.fromRGB(255, 120, 40)
	fire.SecondaryColor = Color3.fromRGB(255, 40, 20)
	fire.Parent = f
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = f
	weld.Parent = f
	f.Parent = part
	task.delay(WeaponMechanics.FLARE_TIME, function()
		if f.Parent then
			f:Destroy()
		end
	end)
end

-- After a round of `toy` landed on a body part (HitService.applyToy, requester known).
function WeaponMechanics.afterHit(player: Player, toy: Toys.Toy, model: Model, woundPart: BasePart, position: Vector3, direction: Vector3)
	if toy.id == "FlareGun" then
		WeaponMechanics.flare(woundPart, position)
	elseif toy.id == "GoldenDeagle" and Anatomy.HEAD_ZONES and (Anatomy.HEAD_ZONES :: any)[woundPart.Name] then
		FxService.hit(position, 0, "GoldSpark", player.UserId)
	end
	if WeaponMechanics.PELLETS[toy.id] then
		WeaponMechanics.pellets(player, toy, position)
	elseif toy.id == "Sniper" or toy.id == "Railgun" then
		-- (The line from the shooter's own head through the checked hit point: never the client's
		-- direction, which could aim the round anywhere. Review fix, round 5.)
		local head = headOf(player)
		if head then
			WeaponMechanics.pierce(player, toy, model, position, position - head)
		end
	end
	local _ = direction
end

-- After a round of `toy` went into the world (no body where it was aimed): pellets still spread,
-- and a rail or sniper round still meets whoever stands on the line.
function WeaponMechanics.afterShot(player: Player, toy: Toys.Toy, point: Vector3)
	if WeaponMechanics.PELLETS[toy.id] then
		WeaponMechanics.pellets(player, toy, point)
	elseif toy.id == "Railgun" then
		local from = headOf(player)
		if from then
			WeaponMechanics.pierce(player, toy, nil, from, point - from)
		end
	end
end

-- (Players is used by tests through the module table.)
WeaponMechanics.Players = Players

return WeaponMechanics
