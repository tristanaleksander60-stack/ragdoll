--!strict
-- V8-2.5 (dummy types and a SPAWN key): a typed dummy drops in your own lab (its plate and size),
-- never outside it or out of reach, at most the device cap of them (the oldest goes), and Reset /
-- clear removes them. Also: one way to name a lab ("JONAS' LAB").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local MachineNames = require(Shared:WaitForChild("MachineNames")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")
local DummySpawn = require(Systems:WaitForChild("DummySpawn")) :: any
local Lab = require(Systems:WaitForChild("Lab")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

return {
	name = "T128_SpawnDummy",
	timeout = 40,
	run = function(): string?
		assert(MachineNames.labOf("Jonas") == "JONAS' LAB" and MachineNames.labOf("Sam") == "SAM'S LAB", "the lab name is wrong")
		if not Config.DUMMY_TYPES then
			return "lab names right; skipped (DUMMY_TYPES off)"
		end
		TestLib.waitFor(function()
			local p = Players:GetPlayers()[1]
			return p ~= nil and p.Character ~= nil and Lab.plotIndex(p) ~= nil
		end, 20)
		local p = Players:GetPlayers()[1]
		if not p or not p.Character then
			return "lab names right; skipped (no player with a lab)"
		end
		local character = p.Character :: Model
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart or not rootPart:IsA("BasePart") then
			return "lab names right; skipped (no avatar root)"
		end
		local root = rootPart :: BasePart
		character:PivotTo(CFrame.new(Lab.focusFor(p) + Vector3.new(0, 4, 0)))
		task.wait(0.5)
		local here = root.Position + Vector3.new(6, -2, 0)
		local made: { Model } = {}
		-- (GOD MODE, T148: a fresh trial lets the first drop through; the pass off keeps the plain cap.)
		local hadGod = p:GetAttribute("God")
		p:SetAttribute("God", false)
		DummySpawn.resetTrialForTest(p)
		local ok, err = pcall(function()
			local m, why = DummySpawn.spawnFor(p, "MINI", here)
			assert(m, "a MINI was refused: " .. tostring(why))
			table.insert(made, m :: Model)
			assert((m :: Model):GetAttribute("DummyType") == "MINI", "no type on the dummy")
			local chest = (m :: Model):FindFirstChild("UpperTorso")
			assert(chest and chest:FindFirstChild("TypePlate"), "no chest plate")
			local _, far = DummySpawn.spawnFor(p, "HEAVY", here + Vector3.new(500, 0, 0))
			assert(far ~= nil, "a dummy dropped outside the lab or out of reach")
			local _, junk = DummySpawn.spawnFor(p, "GIANT", here)
			assert(junk ~= nil, "an unknown type dropped")
			-- The cap: the oldest goes.
			for _ = 1, 8 do
				task.wait(DummySpawn.GAP + 0.05)
				DummySpawn.spawnFor(p, "BOUNCY", here)
			end
			-- (With live ids the creator owns GOD MODE in Studio, and Roblox may say so mid-test: twice the cap.)
			local cap = if p:GetAttribute("God") == true then 12 else 6
			assert(#DummySpawn.of(p) <= cap, "more spawned dummies than the cap: " .. #DummySpawn.of(p))
			DummySpawn.clear(p)
			assert(#DummySpawn.of(p) == 0, "clear left dummies")
		end)
		DummySpawn.clear(p)
		DummySpawn.resetTrialForTest(p)
		p:SetAttribute("God", hadGod)
		assert(ok, err)
		return "MINI dropped with its plate; outside the lab, out of reach and junk refused; the cap holds; clear removes them; JONAS' LAB"
	end,
}
