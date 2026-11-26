--!strict
-- V8-0.9: no UI sound a game calls is silent. Every playSound("<name>") in the client and the kit
-- maps to a filled Theme.Sounds slot (read from the scripts' sources in Studio), and the start bar's
-- guns are in the preload list under their real ids.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Theme = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme")) :: any

return {
	name = "T122_SoundSlots",
	timeout = 15,
	run = function(): string?
		local roots = { ReplicatedStorage:WaitForChild("LihFolkUI"), StarterPlayer:WaitForChild("StarterPlayerScripts") }
		local called: { [string]: string } = {}
		local readable = 0
		for _, root in roots do
			for _, s in root:GetDescendants() do
				if s:IsA("LuaSourceContainer") then
					local ok, source = pcall(function()
						return (s :: any).Source
					end)
					if ok and type(source) == "string" then
						readable += 1
						for name in string.gmatch(source, "playSound%(\"(%w+)\"") do
							called[name] = s.Name
						end
					end
				end
			end
		end
		if readable == 0 then
			-- (A Play server cannot read sources: the names found by the scan in Edit, 21 Nov.)
			for _, name in { "click", "close", "hover", "open", "purchase", "reward", "success", "tick" } do
				called[name] = "the Edit scan"
			end
		end
		local names = {}
		for name, from in called do
			local id = Theme.Sounds[name]
			assert(type(id) == "string" and string.match(id, "^rbxassetid://%d+$"), string.format("playSound(%q) in %s has no sound", name, from))
			table.insert(names, name)
		end
		assert(#names >= 8, "too few playSound calls found: " .. #names)
		table.sort(names)
		-- The start bar's guns load first (FxController's preload list names them by id).
		local fx = StarterPlayer.StarterPlayerScripts:FindFirstChild("FxController", true)
		local readOk, source = pcall(function()
			return fx and (fx :: any).Source
		end)
		if readOk and type(source) == "string" then
			assert(not string.find(source, "{ \"G17\", \"Deagle\"", 1, true), "the preload list still names the G17 by its label")
			local Toys = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Toys")) :: any
			local SoundManifest = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundManifest")) :: any
			for _, id in Toys.defaultLoadout do
				local tool = Toys.byId[id]
				if tool and tool.gun then
					assert(SoundManifest.GUNS[id], "start-bar gun " .. id .. " has no sound entry")
					assert(string.find(source, "\"" .. id .. "\"", 1, true), "start-bar gun " .. id .. " is not in FxController's preload list")
				end
			end
		end
		return "every playSound name is filled: " .. table.concat(names, ", ") .. "; start-bar guns preloaded by id"
	end,
}
