--!strict
-- OVERVIEW 0.1 part B, step 1 (owner: "de skal bare spawne hvor man er, så det ikke lagger"; docs/RAGDOLL_DIRECTOR.md;
-- Config.RAGDOLL_DIRECTOR): the far ragdolls cost nothing. Every 0.5 s the server marks each lab ragdoll that is more
-- than PARK studs from every player and not in use as Parked (attribute); within WAKE studs it is woken again
-- (hysteresis, so it never flickers). The simulating screen (Shared/Ragdoll/ActiveRagdoll) skips a parked body's whole
-- brain and pose update: a standing one keeps standing on its held joints, a lying one lies, at no cost.
-- In use = held, in a machine, hidden by a machine, a demo or NEVER ZERO runner, moving fast, or hit in the last 10 s.
-- At most MAX_CHANGES park/wake changes a tick (no spikes).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RagdollDirector = {}

RagdollDirector.PARK = 140
RagdollDirector.WAKE = 120
RagdollDirector.MAX_CHANGES = 8

local function inUse(m: Model, pe: BasePart): boolean
	local watch = m:GetAttribute("Watch")
	local hitAt = m:GetAttribute("ServerHitAt")
	return m:GetAttribute("Held") == true or m:GetAttribute("InMachine") ~= nil or m:GetAttribute("MachineHidden") ~= nil
		or watch == "Demo" or watch == "NeverZero" or m:GetAttribute("TryFor") ~= nil
		or pe.AssemblyLinearVelocity.Magnitude > 6
		or (type(hitAt) == "number" and workspace:GetServerTimeNow() - hitAt < 10)
end

local function step()
	local dummies = Workspace:FindFirstChild("Dummies")
	if not dummies then
		return
	end
	local eyes = {}
	for _, p in Players:GetPlayers() do
		local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if r and r:IsA("BasePart") then
			table.insert(eyes, r.Position)
		end
	end
	local changes = 0
	for _, m in dummies:GetChildren() do
		local pe = m:FindFirstChild("LowerTorso")
		if m:IsA("Model") and pe and pe:IsA("BasePart") then
			local near = math.huge
			for _, e in eyes do
				near = math.min(near, (e - pe.Position).Magnitude)
			end
			local parked = m:GetAttribute("Parked") == true
			if parked and (near < RagdollDirector.WAKE or inUse(m, pe)) then
				m:SetAttribute("Parked", nil)
				changes += 1
			elseif not parked and near > RagdollDirector.PARK and not inUse(m, pe) then
				m:SetAttribute("Parked", true)
				changes += 1
			end
			if changes >= RagdollDirector.MAX_CHANGES then
				return
			end
		end
	end
end

function RagdollDirector.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.RAGDOLL_DIRECTOR then
		return
	end
	task.spawn(function()
		while true do
			task.wait(0.5)
			pcall(step)
		end
	end)
end

return RagdollDirector
