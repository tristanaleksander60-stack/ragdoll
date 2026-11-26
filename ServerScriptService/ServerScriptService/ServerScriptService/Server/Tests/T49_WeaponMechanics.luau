--!strict
-- Round 5, phase 2b: each gun's own mechanics on the server (WeaponMechanics, ToyService) and the
-- held models (N7Assets.Weapons: real meshes, normalized).
--   a shotgun's pellets find bodies in a cone; a sniper round goes on through bodies behind; the
--   rail through every one on the line; a flare sticks and glows; C4 waits for the detonator;
--   the grenade is thrown (it flies); the nuke's mushroom cloud rises and goes
--   every round 5 model: Grip at the origin, a Tip ahead (-Z), welded, no scripts, never collides

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local WeaponMechanics = require(Systems:WaitForChild("WeaponMechanics"))
local ToyService = require(Systems:WaitForChild("ToyService"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local EventService = require(Systems:WaitForChild("EventService"))
local Toys = require(ReplicatedStorage.Shared.Toys)

local function line(root: BasePart, n: number, gap: number): { Model }
	local list = {}
	local ahead = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
	for i = 1, n do
		local at = root.Position + ahead * (10 + (i - 1) * gap)
		table.insert(list, DummyFactory.spawn(at, root.Position, nil))
	end
	return list
end

local function models(results: { string })
	local W = ReplicatedStorage:FindFirstChild("N7Assets") and ReplicatedStorage.N7Assets:FindFirstChild("Weapons")
	if not W then
		table.insert(results, "models: skipped (no N7Assets in this place)")
		return
	end
	local count = 0
	for _, m in W:GetChildren() do
		if m:GetAttribute("Round5") == true then
			count += 1
			local grip = m:FindFirstChild("Grip")
			local tip = m:FindFirstChild("Tip")
			assert(m:IsA("Model") and m.PrimaryPart == grip and grip and tip, m.Name .. " has no Grip/Tip")
			assert((grip :: BasePart).Position.Magnitude < 0.01, m.Name .. "'s grip is not at the origin")
			local rel = (grip :: BasePart).CFrame:PointToObjectSpace((tip :: BasePart).Position)
			if m.Name ~= "Grenade" and m.Name ~= "C4" and m.Name ~= "Nuke" then
				assert(rel.Z < -0.3, m.Name .. "'s tip is not ahead of the grip")
			end
			for _, d in m:GetDescendants() do
				assert(not d:IsA("LuaSourceContainer"), m.Name .. " has a script")
				if d:IsA("BasePart") then
					assert(not d.CanCollide and not d.CanQuery and not d.CanTouch and d.Massless and not d.Anchored, m.Name .. "." .. d.Name .. " is not a weightless ghost")
					if d ~= grip then
						local welded = false
						for _, w in d:GetChildren() do
							if w:IsA("Weld") and w.Part0 == grip then
								welded = true
							end
						end
						assert(welded, m.Name .. "." .. d.Name .. " is not welded to the grip")
					end
				end
			end
		end
	end
	assert(count >= 20, "only " .. count .. " real models")
	table.insert(results, count .. " real models: grip at the origin, tip ahead, welded, no scripts, ghosts")
end

local function body(player: Player, root: BasePart): string
	local results = {}
	models(results)
	-- Pellets: a crowd in front, the shotgun's cone finds some of them.
	local crowd = line(root, 3, 1.2)
	task.wait(0.4)
	local target = crowd[2]:FindFirstChild("UpperTorso") :: BasePart
	local hits = 0
	for _ = 1, 4 do
		hits += WeaponMechanics.pellets(player, Toys.byId.DoubleBarrel, target.Position)
	end
	assert(hits >= 2, "double barrel pellets found " .. hits .. " bodies in 4 shots")
	for _, m in crowd do
		m:Destroy()
	end
	-- Pierce: three in a row, the sniper round goes through all.
	local row = line(root, 4, 3)
	task.wait(0.4)
	local first = row[1]:FindFirstChild("UpperTorso") :: BasePart
	local dir = (first.Position - root.Position).Unit
	local through = WeaponMechanics.pierce(player, Toys.byId.Sniper, row[1], first.Position, dir)
	assert(through >= 2 and through <= WeaponMechanics.PIERCE, "a sniper round went through " .. through .. " bodies")
	assert(WeaponMechanics.pierce(player, Toys.byId.AK, row[1], first.Position, dir) == 0, "an AK round went through bodies")
	-- Flare: sticks and glows.
	WeaponMechanics.flare(first, first.Position)
	local flare = first:FindFirstChild("Flare")
	assert(flare and flare:FindFirstChildOfClass("PointLight"), "no glowing flare stuck on")
	for _, m in row do
		m:Destroy()
	end
	table.insert(results, string.format("pellets %d hits in 4 double-barrel shots; sniper through %d; flare stuck", hits, through))
	-- C4 waits for the detonator.
	local d = DummyFactory.spawn(root.Position + root.CFrame.LookVector * 12, root.Position, nil)
	task.wait(0.3)
	local chest = d:FindFirstChild("UpperTorso") :: BasePart
	ToyService.onDummy(player, "C4", chest, chest.Position)
	assert(player:GetAttribute("C4Armed") == 1, "the C4 is not armed")
	assert(ToyService.detonate(player) == 1 and player:GetAttribute("C4Armed") == nil, "the detonator did not set it off")
	assert(ToyService.detonate(player) == 0, "nothing left to set off was set off")
	table.insert(results, "C4 waits for the second press")
	-- The grenade flies; the mushroom cloud goes.
	ToyService.place(player, "Grenade", root.Position + root.CFrame.LookVector * 20, root.CFrame.LookVector)
	ToyService.mushroom(root.Position + Vector3.new(0, 0, 60))
	assert(workspace:FindFirstChild("Mushroom"), "no mushroom cloud")
	table.insert(results, "grenade thrown, mushroom cloud up")
	task.wait(3)
	if d.Parent then
		d:Destroy()
	end
	return table.concat(results, "; ")
end

return {
	name = "weapon-mechanics-models",
	timeout = 40,
	run = function(): string?
		local started = os.clock()
		while os.clock() - started < 20 and not (Players:GetPlayers()[1] and Players:GetPlayers()[1].Character) do
			task.wait(0.2)
		end
		local player = Players:GetPlayers()[1]
		local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not player or not root or not root:IsA("BasePart") then
			return "skipped (no player)"
		end
		EventService.holdForTest(true)
		local ok, result = pcall(body, player, root)
		EventService.holdForTest(false)
		if not ok then
			error(result, 0)
		end
		return result
	end,
}
