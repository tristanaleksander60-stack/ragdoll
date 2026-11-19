--!strict
-- World/Feel v2: a small signal on this screen only (no remote, nothing crosses the network) that
-- tells any widget about the feel moments FeelV2 sees, so the UI can join in without FeelV2 knowing
-- about it. Every handler runs in its own thread; one that errors never stops the rest.
--
--   "Combo"   { count: number, at: Vector3? }   a takedown combo went up (ProgressService's Combo)
--   "SlowMo"  { count: number }                 the slow-mo beat of a big combo started
--   "BigHit"  { position: Vector3, strength: number }  a hit of strength >= 0.8 near this camera
--   "Launch"  { position: Vector3, kind: string }      a body was launched or thrown ("Launch",
--                                                       "Throw", "Hit")
--   "Land"    { position: Vector3, speed: number }     a body came down hard (flop sound played)
--   "Shot"    { toyId: string, own: boolean }          a gun fired (muzzle flash drawn)
--
-- Usage: local off = FeelBus.on("Combo", function(data) ... end); off() to stop listening.

local FeelBus = {}

FeelBus.EVENTS = table.freeze({ "Combo", "SlowMo", "BigHit", "Launch", "Land", "Shot" })

local handlers: { [string]: { (any) -> () } } = {}

function FeelBus.on(name: string, fn: (any) -> ()): () -> ()
	local list = handlers[name]
	if not list then
		list = {}
		handlers[name] = list
	end
	table.insert(list, fn)
	return function()
		local now = handlers[name]
		local i = now and table.find(now, fn)
		if now and i then
			table.remove(now, i)
		end
	end
end

function FeelBus.fire(name: string, data: any)
	local list = handlers[name]
	if not list then
		return
	end
	for _, fn in table.clone(list) do
		task.spawn(fn, data)
	end
end

return FeelBus
