--!strict
-- Round 5, phase 1: the sandbox buttons on the right edge (like the big ragdoll games: SLOW MO,
-- REVIVE ALL, RESET), for your own lab only. The client asks (remote Sandbox: "SlowMo" | "Revive" |
-- "Reset"); the server checks the player has a lab and stands in it, paces each action (GAP s), and:
--   SlowMo  a big slow-motion bubble over the lab's middle (ToyService's Slowmo, as the spell)
--   Revive  every dead dummy of the lab comes round, every hurt one is healed (VitalsService)
--   Reset   every knocked-about dummy back on its slot (Lab.rewind); the props go with CleanUp
-- Answers with a short notice (remote Progress "Notice", the toast the client already shows).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Lab = require(script.Parent.Lab)
local ToyService = require(script.Parent.ToyService)
local VitalsService = require(script.Parent.VitalsService)

local SandboxService = {}

SandboxService.GAP = { SlowMo = 8, Revive = 3, Reset = 2 } :: { [string]: number }
local last: { [Player]: { [string]: number } } = {}

local function inOwnLab(player: Player): boolean
	local index = Lab.plotIndex(player)
	if not index then
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false
	end
	local zone, at = Lab.zoneAt(root.Position)
	return zone == "Lab" and at == index
end

local function notice(player: Player, text: string)
	Net.event(Net.Names.Progress):FireClient(player, "Notice", text)
end

-- Runs one action for a player. Returns what happened (tests read it), or nil when refused.
function SandboxService.run(player: Player, action: unknown): string?
	if type(action) ~= "string" or SandboxService.GAP[action] == nil then
		return nil
	end
	if not inOwnLab(player) then
		notice(player, "Sandbox buttons work in your own lab")
		return nil
	end
	local now = os.clock()
	local mine = last[player] or {}
	last[player] = mine
	if now - (mine[action] or -math.huge) < SandboxService.GAP[action] then
		return nil
	end
	mine[action] = now
	if action == "SlowMo" then
		local centre = Lab.focusFor(player)
		local ok = ToyService.place(player, "Slowmo", centre, Vector3.new(0, 0, -1))
		return if ok then "slowmo" else nil
	elseif action == "Revive" then
		local n = 0
		for _, model in Lab.dummiesOf(player) do
			if VitalsService.reviveNow(model) then
				n += 1
			end
		end
		notice(player, if n > 0 then "Everyone is back on their feet!" else "Nobody needs a doctor")
		return "revived " .. n
	elseif action == "Reset" then
		pcall(function()
			(require(script.Parent:WaitForChild("DummySpawn")) :: any).clear(player) -- (V8-2.5: the spawned ones go)
		end)
		local n = Lab.rewind(player)
		return "reset " .. n
	end
	return nil
end

function SandboxService.start()
	Net.event(Net.Names.Sandbox).OnServerEvent:Connect(function(player: Player, action: unknown)
		SandboxService.run(player, action)
	end)
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)
end

-- Tests: forget the pacing.
function SandboxService.resetForTest(player: Player)
	last[player] = nil
end

return SandboxService
