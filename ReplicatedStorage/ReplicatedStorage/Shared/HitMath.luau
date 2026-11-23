--!strict
-- Shared force formulas, so a client predicting its own hit and the server computing it agree.

local Toys = require(script.Parent.Toys)

local HitMath = {}

-- Impulse (mass-studs/s) a toy tap gives a dummy of the given mass.
-- (23 Nov 2026, owner: "the longer you hold the mouse, or the button on a phone, the harder you hit".) Blows by hand only:
-- held CHARGE_FROM s nothing more, full after CHARGE_TIME s: that many times the push and the wound.
HitMath.CHARGE_FROM = 0.15
HitMath.CHARGE_TIME = 1.1
HitMath.CHARGE_PUSH = 1.6
HitMath.CHARGE_WOUND = 2
function HitMath.charges(toy: any): boolean
	return toy ~= nil and toy.kind == "hit" and toy.byHand == true and toy.gun ~= true and toy.id ~= "Chainsaw"
end
function HitMath.chargeOf(held: number): number
	return math.clamp((held - HitMath.CHARGE_FROM) / (HitMath.CHARGE_TIME - HitMath.CHARGE_FROM), 0, 1)
end

-- (23 Nov 2026, owner: "a crowbar must not push a ragdoll 2 metres or just knock it out: it hits and hurts it where you
-- hit; that takes long with such a weapon, a bat too".) A blow with a held weapon or the bare hands: the body stays up
-- and the struck part reacts, like a round; the wounds bring it down. Not the ones made for throwing (a kick, an
-- uppercut, a shove, the giant hand).
local THROWS = { Kick = true, Uppercut = true, Shove = true, MegaSlap = true }
function HitMath.strikes(toy: any): boolean
	return toy ~= nil and toy.kind == "hit" and toy.category == "Melee" and toy.byHand == true and not toy.gun and not THROWS[toy.id]
end
HitMath.STRIKE_DAMAGE = 0.6 -- of the damage such a blow did

function HitMath.toyImpulse(toy: Toys.Toy, direction: Vector3, mass: number): Vector3
	local flat = if direction.Magnitude > 1e-3 then direction.Unit else Vector3.zAxis
	if toy.gun then
		-- A round (round 3, M2): a short shove along the shot, never a throw; where it lands decides
		-- what the body does (ActiveRagdoll.gunReaction).
		return flat * HitMath.gunPush(toy) * mass
	end
	if HitMath.strikes(toy) then
		return flat * math.clamp(4 + 4 * (toy.wound or 1), 4, 10) * mass
	end
	local dir = (flat + Vector3.new(0, toy.lift, 0)).Unit
	return dir * toy.speed * mass
end

-- How hard a round shoves the body it hits (studs/s it would give the whole body): a nail 9, a
-- pistol round 12, the heaviest 17.
function HitMath.gunPush(toy: Toys.Toy): number
	return math.clamp(6 + 6 * (toy.wound or 1), 6, 18)
end

-- What a gun's round does to the body it hits (ActiveRagdoll.hit's gun argument): its wound
-- power; nil for anything that is no gun.
function HitMath.gunOf(toy: Toys.Toy): number?
	return if toy.gun or HitMath.strikes(toy) then math.max(toy.wound or 1, 0.1) else nil
end

-- Recent prop velocities, so an impact is judged by how fast the prop was going when it arrived,
-- not after the collision already stopped it. Touched handlers run deferred (often a frame or two
-- after the contact), so a few frames of history are kept and the fastest one counts.
local HISTORY = 8
-- Strong keys on purpose: a weak table drops an Instance's entry whenever Luau collects its
-- userdata wrapper, even while the part lives on (that made impacts randomly read as too slow).
-- Entries are removed by the tracker once the part leaves the world.
local history: { [BasePart]: { Vector3 } } = {}
local trackerStarted = false

-- Starts remembering a prop's velocity every physics step (until it is removed).
function HitMath.track(prop: BasePart)
	history[prop] = { prop.AssemblyLinearVelocity }
	if not trackerStarted then
		trackerStarted = true
		game:GetService("RunService").PreSimulation:Connect(function()
			for part, list in history do
				if part.Parent then
					table.insert(list, 1, part.AssemblyLinearVelocity)
					if #list > HISTORY then
						list[HISTORY + 1] = nil
					end
				else
					history[part] = nil
				end
			end
		end)
	end
end

local function recentFastest(prop: BasePart): Vector3
	local best = prop.AssemblyLinearVelocity
	local list = history[prop]
	if list then
		for _, v in list do
			if v.Magnitude > best.Magnitude then
				best = v
			end
		end
	end
	return best
end

-- One prop hits one dummy once per pass: a ball rolling on into a body it already bowled over would
-- otherwise keep "hitting" it every cooldown and push it across the lab.
local PASS_TIME = 1.5
local passes: { [BasePart]: { [Instance]: number } } = {}

function HitMath.firstHit(prop: BasePart, dummy: Instance, passTime: number?): boolean
	local now = os.clock()
	local seen = passes[prop]
	if not seen then
		seen = {}
		passes[prop] = seen
		for p in passes do
			if not p.Parent then
				passes[p] = nil
			end
		end
	end
	local last = seen[dummy]
	if last and now - last < (passTime or PASS_TIME) then
		return false
	end
	seen[dummy] = now
	return true
end

-- Impulse a moving prop delivers to a dummy part it touches, or nil if too slow.
function HitMath.propImpulse(prop: BasePart, other: BasePart, minSpeed: number, scale: number): Vector3?
	-- The prop's speed as it arrived. The touched part's velocity is not subtracted: by the time
	-- the (deferred) Touched handler runs, the hit has already sped that part up, and subtracting it
	-- made real hits read as gentle nudges. A dummy flying into a resting prop is the dummy's own
	-- landing, handled elsewhere.
	local _ = other
	local relative = recentFastest(prop)
	if relative.Magnitude < minSpeed then
		return nil
	end
	return relative * prop.AssemblyMass * scale
end

-- How props hit dummies: minimum relative speed, impulse scale, and how much of its own speed the
-- prop keeps after the hit (absorb: an anvil goes "thunk" instead of crushing the body into the
-- floor, which the physics answers by firing it into the sky).
-- maxSpeed caps how fast one hit can send the whole dummy (studs/s): a bowling ball bowls it over
-- like a pin, it does not fire it across the map.
-- pass: how long one prop counts as the same pass over a dummy (a bowling ball that keeps rolling
-- into the pin it already bowled over must not bowl it again and again across the floor).
export type PropProfile = { minSpeed: number, scale: number, toyId: string, absorb: number?, maxSpeed: number, pass: number? }
HitMath.PROPS = table.freeze({
	Anvil = { minSpeed = 15, scale = 0.35, toyId = "Anvil", absorb = 0.2, maxSpeed = 60 },
	AnvilTop = { minSpeed = 15, scale = 0.35, toyId = "Anvil", absorb = 0.2, maxSpeed = 60 },
	BowlingBall = { minSpeed = 12, scale = 0.15, toyId = "Bowling", absorb = 0.4, maxSpeed = 48, pass = 5 },
	-- The Cannon tool's ball: fast and heavy, it knocks a dummy flying, then mostly stops.
	Cannonball = { minSpeed = 20, scale = 0.3, toyId = "Cannon", absorb = 0.35, maxSpeed = 75, pass = 3 },
} :: { [string]: PropProfile })

-- Limits a prop impulse to what the profile allows for a dummy of this mass.
function HitMath.capImpulse(impulse: Vector3, profile: PropProfile, dummyMass: number): Vector3
	local limit = profile.maxSpeed * dummyMass
	if impulse.Magnitude > limit then
		return impulse.Unit * limit
	end
	return impulse
end

-- After a prop hit lands, the prop loses most of its speed if its profile says so.
function HitMath.absorb(prop: BasePart, profile: PropProfile)
	local keep = profile.absorb
	if keep then
		prop.AssemblyLinearVelocity *= keep
		prop.AssemblyAngularVelocity *= keep
	end
end

-- The velocity a tracked part had a few frames ago (before whatever just touched it), or nil.
local function pastVelocity(part: BasePart): Vector3?
	local list = history[part]
	return if list and #list > 0 then list[#list] else nil
end

function HitMath.isTracked(part: BasePart): boolean
	return history[part] ~= nil
end

-- Workshop machines hitting dummies: a car running one over, a spinning arm, a swinging ball, a
-- piston. The machine's speed is taken where it touched the body (a spinning arm hits harder at its
-- tip), and the body's own speed from just before the contact is subtracted, so a dummy riding along
-- on a moving machine is not "hit" by it. Fast enough knocks the dummy over and sends it off along
-- the machine's motion with a little lift, capped so it tumbles rather than flies off the map.
HitMath.MACHINE_MIN_SPEED = 9
HitMath.MACHINE_MAX_SPEED = 50
HitMath.MACHINE_LIFT = 0.3

-- The launch velocity (studs/s) a machine part gives the touched dummy part, or nil if too gentle.
function HitMath.machineLaunch(machine: BasePart, other: BasePart, body: BasePart?): Vector3?
	local at = other.Position
	local v = machine:GetVelocityAtPosition(at)
	local root = machine.AssemblyRootPart
	if root then
		local fast = recentFastest(root)
		if fast.Magnitude > v.Magnitude then
			v = fast
		end
	end
	local before = if body then pastVelocity(body) else nil
	local relative = if before then v - before else v
	local speed = relative.Magnitude
	if speed < HitMath.MACHINE_MIN_SPEED then
		return nil
	end
	local dir = (relative.Unit + Vector3.new(0, HitMath.MACHINE_LIFT, 0)).Unit
	return dir * math.min(speed, HitMath.MACHINE_MAX_SPEED)
end

HitMath.TRAMPOLINE_SPEED = 85

-- Pads you put down (tool props), judged where the dummy is simulated (server or owner client):
--   SpringPad   straight up, much higher than a trampoline (the body's sideways speed carries on)
--   BananaPeel  the foot shoots forward along the way the body was going, and up: a flip onto the back
HitMath.SPRING_SPEED = 150
HitMath.SLIP_FORWARD = 30
HitMath.SLIP_UP = 22

-- The velocity (studs/s) a pad gives the touched dummy part, or nil for a part that is not a pad.
function HitMath.padLaunch(pad: BasePart, bodyVelocity: Vector3): Vector3?
	if pad.Name == "SpringPad" then
		return Vector3.new(bodyVelocity.X * 0.3, HitMath.SPRING_SPEED, bodyVelocity.Z * 0.3)
	elseif pad.Name == "BananaPeel" then
		local flat = Vector3.new(bodyVelocity.X, 0, bodyVelocity.Z)
		local forward = if flat.Magnitude > 0.5 then flat.Unit else pad.CFrame.LookVector
		return forward * HitMath.SLIP_FORWARD + Vector3.new(0, HitMath.SLIP_UP, 0)
	end
	return nil
end
HitMath.BUMPER_SPEED = 55
HitMath.TOUCH_COOLDOWN = 0.4
-- A player's own body: the most a knock may send it, and the human cannon (studs/s).
HitMath.PLAYER_MAX_KNOCK = 70
HitMath.PLAYER_LAUNCH_MAX = 260 -- (V8-1.1: the cannon's long arc is about 246 studs/s; was 140)
-- s a player stays limp before getting up again is allowed
HitMath.PLAYER_MIN_DOWN_TIME = 0.6
-- studs above FallenPartsDestroyHeight where a limp body counts as fallen out of the world
HitMath.PLAYER_VOID_MARGIN = 40

return HitMath
