--!strict
-- Round 5, phase 2: magazines and reloads (like every shooter). Each gun holds MAG rounds; empty, it
-- reloads by itself for RELOAD s (R reloads early). The server counts every round it takes
-- (HitService: Ammo.take) and refuses a shot while that gun reloads, so nobody gets endless rounds;
-- the client counts the same way to draw "12 / 17" and the reload ring (Client/AmmoClient).
-- Pure: the state lives in whoever keeps a Book (one per player on the server, one on the client).

local Ammo = {}

export type Spec = { mag: number, reload: number }

Ammo.SPECS = table.freeze({
	Blaster = { mag = 17, reload = 1.3 },
	Revolver = { mag = 6, reload = 2.0 },
	Deagle = { mag = 7, reload = 1.6 },
	GoldenDeagle = { mag = 7, reload = 1.6 },
	SMG = { mag = 30, reload = 1.6 },
	TommyGun = { mag = 50, reload = 2.4 },
	AK = { mag = 30, reload = 2.1 },
	M4 = { mag = 30, reload = 1.9 },
	LMG = { mag = 100, reload = 3.4 },
	Minigun = { mag = 200, reload = 3.8 },
	Shotgun = { mag = 6, reload = 2.4 },
	DoubleBarrel = { mag = 2, reload = 1.8 },
	AutoShotgun = { mag = 10, reload = 2.4 },
	Sniper = { mag = 5, reload = 2.6 },
	DMR = { mag = 10, reload = 2.2 },
	FlareGun = { mag = 1, reload = 1.5 },
	LaserRifle = { mag = 40, reload = 2.0 },
	Railgun = { mag = 3, reload = 2.4 },
	NailGun = { mag = 40, reload = 1.8 },
	Crossbow = { mag = 1, reload = 1.2 },
} :: { [string]: Spec })

-- The server allows a reload a little short of the client's, so a shot the client fires the moment
-- its reload ends is never refused for the trip across the network.
Ammo.SERVER_SLACK = 0.25

export type Mag = { left: number, reloadUntil: number }
export type Book = { [string]: Mag }

function Ammo.spec(toyId: string): Spec?
	return Ammo.SPECS[toyId]
end

local function magOf(book: Book, toyId: string, spec: Spec): Mag
	local m = book[toyId]
	if not m then
		m = { left = spec.mag, reloadUntil = 0 }
		book[toyId] = m
	end
	return m
end

-- Rounds left (a finished reload fills it). nil: the weapon has no magazine.
function Ammo.left(book: Book, toyId: string, now: number): number?
	local spec = Ammo.SPECS[toyId]
	if not spec then
		return nil
	end
	local m = magOf(book, toyId, spec)
	if m.reloadUntil > 0 and now >= m.reloadUntil then
		m.left = spec.mag
		m.reloadUntil = 0
	end
	return m.left
end

-- How far a running reload is (0..1), or nil when none runs.
function Ammo.reloading(book: Book, toyId: string, now: number): number?
	local spec = Ammo.SPECS[toyId]
	local m = book[toyId]
	if not spec or not m or m.reloadUntil <= now then
		return nil
	end
	return math.clamp(1 - (m.reloadUntil - now) / spec.reload, 0, 1)
end

-- Starts a reload (not while one runs, not with a full magazine). slack: s taken off (the server's).
function Ammo.reload(book: Book, toyId: string, now: number, slack: number?): boolean
	local spec = Ammo.SPECS[toyId]
	if not spec then
		return false
	end
	local left = Ammo.left(book, toyId, now) :: number
	local m = magOf(book, toyId, spec)
	if m.reloadUntil > now or left >= spec.mag then
		return false
	end
	m.reloadUntil = now + math.max(0.1, spec.reload - (slack or 0))
	return true
end

-- Takes one round. False while reloading or empty. The last round starts the reload by itself.
function Ammo.take(book: Book, toyId: string, now: number, slack: number?): boolean
	local spec = Ammo.SPECS[toyId]
	if not spec then
		return true -- (no magazine: nothing to count)
	end
	local left = Ammo.left(book, toyId, now) :: number
	local m = magOf(book, toyId, spec)
	if m.reloadUntil > now or left <= 0 then
		return false
	end
	m.left = left - 1
	if m.left <= 0 then
		m.reloadUntil = now + math.max(0.1, spec.reload - (slack or 0))
	end
	return true
end

return Ammo
