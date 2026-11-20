--!strict
-- V9-0a (owner, 21 Nov 2026: "when you try to hit a ragdoll you open the talk menu all the time"):
-- the Talk prompt is never clickable from the server; TalkRules hides it during a fight (2 s after a
-- click, R2 or shot; 3 s on touch, and on touch only while standing still) and while Grab holds a
-- body; the panel never opens within 0.5 s of an attack; a calm keyboard player still sees it. 30
-- quick hits in a row never leave a window for Talk.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TalkRules = require(Shared:WaitForChild("TalkRules")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

return {
	name = "T158_HitNotTalk",
	timeout = 30,
	run = function(): string?
		local function state(now: number, last: number, touch: boolean, speed: number?, grabbing: boolean?): any
			return { now = now, lastAttack = last, touch = touch, speed = speed or 0, grabbing = grabbing == true, viewOk = true }
		end
		-- Calm: shown (keyboard and touch standing still).
		assert(TalkRules.show(state(100, -math.huge, false)), "a calm keyboard player does not see Talk")
		assert(TalkRules.show(state(100, -math.huge, true)), "a calm touch player standing still does not see Talk")
		-- 30 quick hits, one every 0.15 s: Talk never shows and never opens in between.
		local t = 100
		for _ = 1, 30 do
			local last = t
			t += 0.15
			assert(not TalkRules.show(state(t, last, false)), "Talk showed between two clicks")
			assert(not TalkRules.show(state(t, last, true)), "Talk showed between two taps")
			assert(not TalkRules.mayOpen(t, last), "the panel could open between two hits")
		end
		-- After the quiet time it comes back.
		assert(TalkRules.show(state(t + TalkRules.QUIET_AFTER + 0.01, t, false)), "Talk did not come back after the quiet time")
		assert(not TalkRules.show(state(t + TalkRules.QUIET_AFTER + 0.01, t, true)), "touch came back before its longer quiet time")
		assert(TalkRules.show(state(t + TalkRules.QUIET_AFTER_TOUCH + 0.01, t, true)), "touch did not come back")
		-- Touch while walking, grabbing, the lab view: hidden.
		assert(not TalkRules.show(state(200, -math.huge, true, 8)), "touch shows Talk while walking")
		assert(not TalkRules.show(state(200, -math.huge, false, 0, true)), "Talk shows while Grab holds a body")
		local s = state(200, -math.huge, false)
		s.viewOk = false
		assert(not TalkRules.show(s), "Talk shows in the lab view")
		-- What counts as an attack; the prompt's style per device.
		assert(TalkRules.isAttack(Enum.UserInputType.MouseButton1, Enum.KeyCode.Unknown), "a click is no attack")
		assert(TalkRules.isAttack(Enum.UserInputType.Touch, Enum.KeyCode.Unknown), "a tap is no attack")
		assert(TalkRules.isAttack(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonR2), "R2 is no attack")
		assert(not TalkRules.isAttack(Enum.UserInputType.Keyboard, Enum.KeyCode.E), "E counted as an attack")
		local clickMouse, holdMouse = TalkRules.promptStyle(false)
		local clickTouch, holdTouch = TalkRules.promptStyle(true)
		assert(clickMouse == false and holdMouse == 0, "the prompt is clickable with a mouse")
		assert(clickTouch == true and holdTouch >= 0.3, "a quick tap could open Talk on touch")
		-- Every live Talk prompt from the server: not clickable, E / L3.
		local prompts = 0
		TestLib.waitFor(function()
			local d = Workspace:FindFirstChild("Dummies")
			return d ~= nil and d:FindFirstChild("TalkPrompt", true) ~= nil
		end, 15)
		local folder = Workspace:FindFirstChild("Dummies")
		for _, p in if folder then folder:GetDescendants() else {} do
			if p:IsA("ProximityPrompt") and p.Name == "TalkPrompt" then
				prompts += 1
				assert(p.ClickablePrompt == false, "a Talk prompt is clickable: " .. p:GetFullName())
				assert(p.KeyboardKeyCode == Enum.KeyCode.E, "Talk is not on E")
			end
		end
		return string.format("30 quick hits never show or open Talk; back after %g s (touch %g s, standing still); grab and lab view hide it; %d server prompts not clickable", TalkRules.QUIET_AFTER, TalkRules.QUIET_AFTER_TOUCH, prompts)
	end,
}
