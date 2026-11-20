--!strict
-- v4 A1: Red Light, Green Light can be won. An honest runner through the red line costs no life;
-- a cheater (moved on RED) costs one; every runner that is out is replaced in its lane, so the round
-- lasts its minute; the round does not end while replacements are on their way.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Places = require(ReplicatedStorage.Shared.Places)
local Systems = script.Parent.Parent:WaitForChild("Systems")
local MinigameService = require(Systems:WaitForChild("MinigameService")) :: any

return {
	name = "T94_RedLight",
	timeout = 30,
	run = function(): string?
		if not (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).ARENA_ENABLED then
			return "skipped (V9-0s: the Game Arena is hidden, Config.ARENA_ENABLED off)"
		end
		local player = Players:GetPlayers()[1]
		assert(player, "no player in the play test")
		local wasPlace = player:GetAttribute("Place")
		player:SetAttribute("Place", "Arena")
		MinigameService.stopForTest()
		local ok, why = MinigameService.start(player, "RLGL")
		assert(ok, "the round did not start: " .. tostring(why))
		local result: string? = nil
		local success, err = pcall(function()
			local s = MinigameService.current()
			assert(s and #s.runners == MinigameService.RLGL.runners, "not every runner came")
			local origin = Workspace:GetAttribute("LabOrigin")
			local centre = Places.floorCenter(if typeof(origin) == "Vector3" then origin else Vector3.zero, "Arena") :: Vector3
			local livesBefore = s.lives
			local function across(r: any)
				r.model:PivotTo(CFrame.new(centre + Vector3.new(r.laneX, 3, -44)))
			end
			-- An honest one through: safe, no life lost.
			local honest = s.runners[1]
			honest.cheated = false
			across(honest)
			MinigameService.stepForTest()
			assert(honest.done and s.lives == livesBefore, string.format("an honest runner cost a life (%d -> %d)", livesBefore, s.lives))
			-- A cheater through: one life.
			local cheater = s.runners[2]
			cheater.cheated = true
			across(cheater)
			MinigameService.stepForTest()
			assert(cheater.done and s.lives == livesBefore - 1, string.format("a cheater through cost %d lives", livesBefore - s.lives))
			-- Both replaced in their lanes after a beat; the round goes on.
			task.wait(MinigameService.RLGL.respawnAfter + 0.6)
			MinigameService.stepForTest()
			local fresh = 0
			for _, r in s.runners do
				if not r.done then
					fresh += 1
				end
			end
			assert(fresh == MinigameService.RLGL.runners, string.format("%d runners in play after the replacements (want %d)", fresh, MinigameService.RLGL.runners))
			assert(MinigameService.current() == s, "the round ended")
			result = string.format("honest runner safe; cheater -1 life (%d left); both replaced, %d runners in play", s.lives, fresh)
		end)
		MinigameService.stopForTest()
		player:SetAttribute("Place", wasPlace)
		if not success then
			error(err, 0)
		end
		return result
	end,
}
