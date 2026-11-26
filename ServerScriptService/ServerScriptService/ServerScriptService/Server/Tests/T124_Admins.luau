--!strict
-- 21 Nov 2026 (the owner: give others the admin menu):
--   a player who is neither owner nor admin gets nothing from the admin remote;
--   an admin gets the tools, but not the owner's settings (free passes) and cannot make admins;
--   the owner makes and removes admins (never themself), and the IsAdmin attribute follows;
--   a play-as-newcomer visit is never an admin.
-- Memory only (Studio): never the live Admins_v1 store.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local Admins = require(Systems:WaitForChild("Admins")) :: any
local AdminService = require(Systems:WaitForChild("AdminService")) :: any
local Owner = require(Systems:WaitForChild("Owner")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

return {
	name = "T124_Admins",
	timeout = 30,
	run = function(): string?
		TestLib.waitFor(function()
			return Players:GetPlayers()[1] ~= nil
		end, 15)
		local p = Players:GetPlayers()[1]
		if not p then
			return "skipped (no player)"
		end
		local wasOwner = Owner.studioOwnerForTest
		local ok, err = pcall(function()
			Admins.resetForTest()
			-- Neither owner nor admin.
			Owner.studioOwnerForTest = false
			AdminService.resetPaceForTest(p)
			assert(not Admins.isAdmin(p), "a plain player is admin")
			assert(not AdminService.request(p, "Hello", nil), "a plain player got an answer from the admin remote")
			-- Made admin (as the owner would).
			Admins.setForTest(p.UserId, true)
			assert(Admins.isAdmin(p) and p:GetAttribute("IsAdmin") == true, "the admin is not marked")
			AdminService.resetPaceForTest(p)
			assert(AdminService.request(p, "Hello", nil), "an admin was refused the menu")
			AdminService.resetPaceForTest(p)
			assert(not AdminService.request(p, "FreePasses", 0), "an admin changed the owner's free passes")
			local made = Admins.set(p, 123, "Friend", true)
			assert(not made and not Admins.listed(123), "an admin made another admin")
			-- A play-as-newcomer visit is never an admin.
			ServerStorage:SetAttribute("StudioFresh", true)
			local fresh = Admins.isAdmin(p)
			ServerStorage:SetAttribute("StudioFresh", false)
			assert(not fresh, "a play-as-newcomer visit is admin")
			Admins.setForTest(p.UserId, false)
			assert(p:GetAttribute("IsAdmin") == nil, "IsAdmin stayed after admin was taken")
			-- The owner makes and removes admins (never themself).
			Owner.studioOwnerForTest = true
			local okMake = Admins.set(p, 123, "Friend", true)
			assert(okMake and Admins.listed(123), "the owner could not make an admin")
			local okTake = Admins.set(p, 123, "Friend", false)
			assert(okTake and not Admins.listed(123), "the owner could not remove an admin")
			assert(not (Admins.set(p, p.UserId, "Me", true)), "the owner was put on the list")
			assert(Admins.isAdmin(p), "the owner is not admin")
		end)
		Owner.studioOwnerForTest = wasOwner
		ServerStorage:SetAttribute("StudioFresh", false)
		Admins.resetForTest()
		AdminService.resetPaceForTest(p)
		assert(ok, err)
		return "plain player refused; admin gets the menu, not the owner's settings, cannot make admins; owner makes/removes admins; newcomer visit never admin"
	end,
}
