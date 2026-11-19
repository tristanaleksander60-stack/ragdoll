--!strict
-- Which joints are kinematic for a given ragdoll state. Kinematic joints weld parts into one
-- assembly; every machine must agree on this or physics replication of a client-simulated
-- dummy breaks. The server applies these flags when the owning client reports a transition.

local Tone = require(script.Parent.Tone)

local Topology = {}

-- Profile whose kinematic flags a state uses. Ramping states run every joint simulated.
local PROFILE_OF: { [string]: string? } = {
	Standing = "Standing",
	Walking = "Standing",
	Fleeing = "Standing",
	Crawling = "Crawl",
	Flinch = "Flinch",
	Stumble = "Stumble",
	Ragdoll = "Ragdoll",
	Out = "Ragdoll",
	Recovering = nil,
	GettingUp = nil,
}

-- Returns jointName -> kinematic for the state, or nil when the state does not touch joints (Frozen).
function Topology.flags(state: string, broken: { [string]: boolean }, jointNames: { string }): { [string]: boolean }?
	if state == "Frozen" then
		return nil
	end
	local profile = PROFILE_OF[state]
	local flags: { [string]: boolean } = {}
	for _, name in jointNames do
		local kinematic = false
		if profile then
			local t = Tone.get(profile, name)
			kinematic = t ~= nil and t.kinematic
		end
		if broken[name] then
			kinematic = false
		end
		flags[name] = kinematic
	end
	return flags
end

Topology.STATES = table.freeze({
	"Standing", "Walking", "Fleeing", "Crawling", "Flinch", "Stumble", "Ragdoll", "Out", "Recovering", "GettingUp", "Frozen",
})

return Topology
