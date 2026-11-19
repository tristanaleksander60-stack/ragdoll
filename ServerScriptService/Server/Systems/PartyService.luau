--!strict
-- Phase 3 (19 Nov 2026): Prank Party. When 2 to Config.PARTY_MAX players stand in one lab (the
-- owner and the friends they let in), they get one shared experiment card (Experiments.PARTY):
-- everyone's takedowns, cannon shots and traps count, everyone gets the stars (and bolts).
-- Checked every CHECK_EVERY s; a party ends when its card ends, or when fewer than 2 are left.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Experiments = require(Shared:WaitForChild("Experiments"))

local Lab = require(script.Parent.Lab)
local ExperimentService = require(script.Parent.ExperimentService)

local PartyService = {}

PartyService.CHECK_EVERY = 5
PartyService.GAP = 20 -- s between one party card and the next in the same lab

local nextAt: { [Player]: number } = {}
local dealt: { [Player]: number } = {}

-- Who stands in each owner's lab now: { owner = { members } } (owners included).
function PartyService.groups(): { [Player]: { Player } }
	local out: { [Player]: { Player } } = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local owner = Lab.ownerAt(root.Position)
			if owner then
				out[owner] = out[owner] or {}
				table.insert(out[owner], player)
			end
		end
	end
	return out
end

-- One check: deal a party card where a lab has company, end the ones that lost it.
function PartyService.step(now: number, groups: { [Player]: { Player } })
	for owner, members in groups do
		local n = #members
		local running = ExperimentService.partyOf(owner)
		if n >= 2 and n <= Config.PARTY_MAX and not running and now >= (nextAt[owner] or 0) then
			dealt[owner] = (dealt[owner] or 0) + 1
			local def = Experiments.PARTY[((dealt[owner] - 1) % #Experiments.PARTY) + 1]
			ExperimentService.startParty(owner, members, def)
			nextAt[owner] = now + def.seconds + PartyService.GAP
		elseif running and n < 2 then
			ExperimentService.endParty(owner)
		end
	end
	for owner in nextAt do
		if not groups[owner] and ExperimentService.partyOf(owner) then
			ExperimentService.endParty(owner)
		end
	end
end

function PartyService.start()
	if not Config.PRANK_PARTY or not Config.EXPERIMENTS then
		return
	end
	Players.PlayerRemoving:Connect(function(player)
		nextAt[player] = nil
		dealt[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(PartyService.CHECK_EVERY)
			PartyService.step(os.clock(), PartyService.groups())
		end
	end)
end

return PartyService
