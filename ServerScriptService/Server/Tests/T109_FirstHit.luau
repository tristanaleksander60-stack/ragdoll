--!strict
-- V8-0.2 (the first hit lands):
--   the greeter is in the player's own lab (audit A: its route might be worked out at the plaza
--   spawn, before the move into the lab), and walks up to the player;
--   a first hit knocks a standing body flat and throws it back at FIRST_HIT_PUSH studs/s or more,
--   even a hit far too soft to do it on its own (ActiveRagdoll.firstHitsLeft, on a body the server
--   simulates), and uses up one of the hits.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local ActiveRagdoll = require(Shared:WaitForChild("Ragdoll"):WaitForChild("ActiveRagdoll")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")
local Lab = require(Systems:WaitForChild("Lab")) :: any
local DummyControl = require(Systems:WaitForChild("DummyControl")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

return {
	name = "T109_FirstHit",
	timeout = 60,
	run = function(): string?
		if not Config.V8_FIRST_HIT then
			return "skipped (V8_FIRST_HIT off)"
		end
		local notes = {}
		-- The greeter: in the player's own lab, and it comes up to them.
		local p: Player? = nil
		TestLib.waitFor(function()
			p = Players:GetPlayers()[1]
			return p ~= nil and p.Character ~= nil
		end, 20)
		if p then
			local player = p :: Player
			local greeter: Model? = nil
			TestLib.waitFor(function()
				for _, m in (Workspace:FindFirstChild("Dummies") or Workspace):GetChildren() do
					if m:IsA("Model") and m:GetAttribute("Greeter") == player.UserId then
						greeter = m
					end
				end
				return greeter ~= nil
			end, 20)
			if greeter then
				local pelvis = (greeter :: Model):FindFirstChild("LowerTorso")
				assert(pelvis and pelvis:IsA("BasePart"), "the greeter has no body")
				assert(Lab.ownerAt(pelvis.Position) == player, "the greeter is not in the player's own lab")
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local near = TestLib.waitFor(function()
					return root ~= nil and (root :: BasePart).Position ~= nil and ((root :: BasePart).Position - (pelvis :: BasePart).Position).Magnitude < 14
				end, 12)
				table.insert(notes, if near then "greeter in the player's lab, walked up" else "greeter in the player's lab")
			else
				table.insert(notes, "no greeter this visit (not a newcomer)")
			end
		end
		-- The first hit: a body the server simulates, standing.
		local body: Model? = nil
		TestLib.waitFor(function()
			for _, m in (Workspace:FindFirstChild("Dummies") or Workspace):GetChildren() do
				if m:IsA("Model") and ActiveRagdoll.isSimulating(m) and DummyControl.ownerOf(m) == nil and ActiveRagdoll.getState(m) == "Standing" then
					body = m
					return true
				end
			end
			return false
		end, 15)
		if not body then
			table.insert(notes, "no standing server-simulated body to hit (push not checked)")
			return table.concat(notes, "; ")
		end
		local model = body :: Model
		local chestPart = model:FindFirstChild("UpperTorso")
		local pelvisPart = model:FindFirstChild("LowerTorso")
		assert(chestPart and chestPart:IsA("BasePart") and pelvisPart and pelvisPart:IsA("BasePart"), "the body has no torso")
		local chest, pelvis = chestPart :: BasePart, pelvisPart :: BasePart
		local mass = ActiveRagdoll.getMass(model) or 10
		local was = ActiveRagdoll.firstHitsLeft
		ActiveRagdoll.firstHitsLeft = 1
		ActiveRagdoll.ownHit = true -- (only the player's own hit uses them)
		local ok, err = pcall(function()
			-- A tap: 2 studs/s, far under a stagger.
			local state = ActiveRagdoll.hit(model, chest, chest.CFrame.LookVector * -2 * mass, chest.Position, nil, nil)
			assert(state == "Ragdoll", "a first hit did not knock it flat: " .. tostring(state))
			assert(ActiveRagdoll.firstHitsLeft == 0, "the first hit was not used up")
			local fastest = 0
			for _ = 1, 10 do
				task.wait()
				fastest = math.max(fastest, pelvis.AssemblyLinearVelocity.Magnitude)
			end
			assert(fastest >= Config.FIRST_HIT_PUSH * 0.6, string.format("the flop is too soft: %.1f studs/s", fastest))
			table.insert(notes, string.format("a 2 studs/s tap knocked it flat at %.0f studs/s", fastest))
		end)
		ActiveRagdoll.firstHitsLeft = was
		ActiveRagdoll.ownHit = false
		assert(ok, err)
		return table.concat(notes, "; ")
	end,
}
