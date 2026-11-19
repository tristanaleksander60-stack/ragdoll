--!strict
-- Round 4, M10: sprinting. The Sprint module runs on the client (hold Shift / RUN / L3); a server
-- test cannot read a script's source or drive a client's input, so this checks what the server
-- owns: Shift is free for sprinting (Roblox's mouse lock is off), the client module ships, and the
-- walk speed it scales is a real one. The hold-to-run feel is checked by hand (see the test list).

local StarterPlayer = game:GetService("StarterPlayer")

return {
	name = "T42_Sprint",
	timeout = 2,
	run = function(): string?
		assert(StarterPlayer.EnableMouseLockOption == false, "mouse lock is still on: Shift would toggle it instead of sprinting")
		local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
		local client = scripts and scripts:FindFirstChild("Client")
		local sprint = client and client:FindFirstChild("Sprint")
		assert(sprint and sprint:IsA("ModuleScript"), "the client Sprint module is missing")
		assert(StarterPlayer.CharacterWalkSpeed > 0, "no walk speed to sprint from")
		return string.format("mouse lock off (Shift sprints), Sprint module ships, walk %.0f studs/s to sprint (x1.65 in Sprint)", StarterPlayer.CharacterWalkSpeed)
	end,
}
