--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
	name = "shared-config-loads",
	run = function(): string?
		local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
		assert(type(Config.Version) == "string", "Config.Version missing")
		assert(table.isfrozen(Config), "Config should be frozen")
		return "v" .. Config.Version
	end,
}
