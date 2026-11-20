--!strict
-- V8-2.8 (one sign language): the one name each machine has on every sign, card, toast and path, and
-- the one way a lab is named after its owner. Pure.

local MachineNames = {}

MachineNames.NAMES = table.freeze({
	Cannon = "CANNON",
	Bullseye = "BULLSEYE",
	Lava = "LAVA",
	Wrecking = "WRECKING BALL",
	Tower = "THROW TOWER",
	Trampoline = "TRAMPOLINE",
	Stations = "LAUNCH PADS",
	Button = "BIG RED BUTTON",
	Portals = "PORTALS",
	Vehicles = "CARS",
}) :: { [string]: string }

-- "SAM'S LAB", and "JONAS' LAB" for a name that ends in S (the old signs said "JONAS'S").
function MachineNames.labOf(displayName: string): string
	local name = string.upper(displayName)
	local tail = string.sub(name, -1)
	return name .. (if tail == "S" then "' LAB" else "'S LAB")
end

return MachineNames
