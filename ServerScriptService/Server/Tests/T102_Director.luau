--!strict
-- V6-3: the director mode's server half (AdminTools.director through AdminService).
--   a non-owner gets nothing (no shot, no launch, no presets saved);
--   presets: only 5 clean { c = 12 numbers, fov, slow } (NaN, huge, junk refused);
--   a launch takes only a body in Workspace.Dummies; the tower shot spawns guests (NoCredit).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local AdminService = require(Systems:WaitForChild("AdminService"))
local AdminTools = require(Systems:WaitForChild("AdminTools"))
local Owner = require(Systems:WaitForChild("Owner"))

local function guests(): number
	local n = 0
	local f = Workspace:FindFirstChild("Dummies")
	for _, m in if f then f:GetChildren() else {} do
		if m:GetAttribute("AdminGuest") == true then
			n += 1
		end
	end
	return n
end

return {
	name = "T102_Director",
	timeout = 30,
	run = function(): string?
		local p = Players:GetPlayers()[1]
		if not p then
			return "skipped (no player)"
		end
		local function req(kind: string, arg: any?): boolean
			AdminService.resetPaceForTest(p)
			return AdminService.request(p, kind, arg)
		end
		local good = { { c = { 0, 10, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, fov = 70, slow = 0.5 } }
		local ok, err = pcall(function()
			Owner.studioOwnerForTest = false
			local before = guests()
			assert(not req("Shot", "Tower"), "a non-owner set up a shot")
			assert(not req("DirectorSave", { slot = 1, preset = good[1] }), "a non-owner saved presets")
			assert(guests() == before, "a non-owner's shot spawned bodies")
			Owner.studioOwnerForTest = true
			-- Presets.
			assert(AdminTools.cleanPresets(good) ~= nil, "a good preset was refused")
			assert(AdminTools.cleanPresets({ { c = { 0 / 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, fov = 70, slow = 1 } }) == nil, "NaN taken")
			assert(AdminTools.cleanPresets({ { c = { 1e9, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, fov = 70, slow = 1 } }) == nil, "a huge position taken")
			assert(AdminTools.cleanPresets({ { c = { 0, 0, 0 }, fov = 70, slow = 1 } }) == nil, "a short CFrame taken")
			assert(AdminTools.cleanPresets({ good[1], good[1], good[1], good[1], good[1], good[1] }) == nil, "6 presets taken")
			assert(AdminTools.cleanPresets("junk") == nil, "junk taken")
			assert(not req("DirectorSave", { slot = 9, preset = good[1] }), "slot 9 taken")
			assert(not req("DirectorSave", { slot = 1, preset = { c = { 0 } } }), "a bad preset taken")
			task.wait(0.3)
			assert(req("DirectorSave", { slot = 2, preset = good[1] }), "the owner could not save a preset")
			-- Launch: only a body in Workspace.Dummies.
			assert(not req("LaunchDummy", Workspace:FindFirstChildWhichIsA("BasePart", true)), "a launch took a part")
			assert(not req("LaunchDummy", p.Character), "a launch took a player")
			assert(not req("Shot", "Nope"), "an unknown shot was taken")
			-- The tower shot.
			local b = guests()
			assert(req("Shot", "Tower"), "the tower shot was refused")
			assert(guests() >= b + 1, "the tower shot spawned no guests")
			local f = Workspace:FindFirstChild("Dummies")
			local one = nil
			for _, m in if f then f:GetChildren() else {} do
				if m:GetAttribute("AdminGuest") == true then
					one = m
				end
			end
			assert(one and req("LaunchDummy", one), "a guest dummy could not be launched")
		end)
		Owner.studioOwnerForTest = true
		AdminService.resetPaceForTest(p)
		AdminService.request(p, "ClearDummies")
		if not ok then
			error(err, 0)
		end
		return "non-owner refused, presets checked, launch takes bodies only, tower shot spawns guests"
	end,
}
