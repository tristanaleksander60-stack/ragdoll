--!strict
-- World/Feel v2 (Config.FEEL_V2): the numbers of hit feel in one place, pure (no instances, no
-- services), so T80 checks them off-line. One strength value per moment drives the shake, the
-- hit-stop and the flop sound (vault: Hit-Stop and Screen Shake Tuning by Numbers). The per-device
-- budgets come from Config.FX_CAPS through DeviceTier's tiers.
--
--   strength   0 .. 1.3 from a hit's speed (studs/s): light hits are 0 by construction
--   trauma     added to the camera's trauma; the shake drawn is trauma squared (small hits only
--              count in a flurry), with noise (never per-frame random jitter), its frequency capped
--              at 0.4 x the frame rate so a 30 fps phone does not alias it into judder
--   stop       a hit-stop only from "heavy" up (66 ms+, the phone threshold), budgeted by HitFeel
--   flop       a ragdoll landing's sound layer by speed: a soft flop, a thud, a slam
--   GUN_FX     per gun: camera recoil (degrees), muzzle-flash size and colour, and what it throws
--              out (brass, a red shell, or nothing: a revolver and a break-action keep theirs)

local Config = require(script.Parent:WaitForChild("Config"))
local DeviceTier = require(script.Parent:WaitForChild("DeviceTier"))

local FeelTuning = {}

export type Caps = { lights: number, flashes: number, particles: number, trails: number, casings: number, ragdolls: number }
export type GunFx = { kick: number, flash: number, color: Color3?, casing: ("brass" | "shell")? }
export type Flop = { bank: string, volume: number, pitch: number, layer: string? }

-- The device's tier from what it has (the client's own guess; the server reads SessionStats' plat).
-- A touch screen without a keyboard is a phone (a tablet if its short side is over 600 px), a
-- gamepad without a keyboard a console, anything else a computer.
function FeelTuning.platOf(touch: boolean, keyboard: boolean, gamepad: boolean, shortSide: number?): string
	if touch and not keyboard then
		return if (shortSide or 0) > 600 then "tablet" else "phone"
	elseif gamepad and not keyboard then
		return "console"
	end
	return "pc"
end

function FeelTuning.caps(tier: DeviceTier.Tier): Caps
	local all = Config.FX_CAPS :: any
	return all[tier] or all.mid
end

-- 0 .. 1.3 from a speed: 30 studs/s is about "medium", 90 "finisher", 120+ the very biggest.
FeelTuning.LIGHT = 0.35 -- strength under this: no shake, no stop
function FeelTuning.strength(speed: number): number
	return math.clamp(speed / 90, 0, 1.3)
end

local TRAUMA = { { 0.35, 0 }, { 0.45, 0.12 }, { 0.8, 0.25 }, { 1.0, 0.35 }, { 1.3, 0.6 } }
function FeelTuning.trauma(strength: number): number
	if strength < TRAUMA[1][1] then
		return 0
	end
	for i = 2, #TRAUMA do
		local a, b = TRAUMA[i - 1], TRAUMA[i]
		if strength <= b[1] then
			local t = (strength - a[1]) / (b[1] - a[1])
			return a[2] + (b[2] - a[2]) * t
		end
	end
	return TRAUMA[#TRAUMA][2]
end

-- How far away a moment still shakes this camera (studs), and how much (1 at the camera, 0 here).
FeelTuning.SHAKE_RANGE = 70
function FeelTuning.near(distance: number): number
	return math.clamp(1 - distance / FeelTuning.SHAKE_RANGE, 0, 1)
end

-- The shake drawn from a trauma: degrees of pitch/yaw and of roll (roll small: it sickens).
FeelTuning.SHAKE_DEG = 2.4
FeelTuning.SHAKE_ROLL_DEG = 1.2
FeelTuning.SHAKE_HZ = 16
FeelTuning.TRAUMA_DECAY = 1.5 -- per s
function FeelTuning.shakeOf(trauma: number): number
	local t = math.clamp(trauma, 0, 1)
	return t * t
end
function FeelTuning.shakeHz(fps: number): number
	return math.min(FeelTuning.SHAKE_HZ, 0.4 * math.max(fps, 1))
end

-- A hit-stop for a big moment (not a melee blow: PokeController's HitFeel does those): heavy and up.
function FeelTuning.stop(strength: number): number
	if strength < 0.8 then
		return 0
	end
	return 0.03 + 0.045 * math.min(strength, 1.3)
end

-- A body landing: under FLOP_MIN nothing extra; then a flop, a thud, a slam.
FeelTuning.FLOP_MIN = 12
function FeelTuning.flop(speed: number): Flop?
	if speed < FeelTuning.FLOP_MIN then
		return nil
	elseif speed < 35 then
		return { bank = "land", volume = 0.18 + speed / 200, pitch = 1.45 }
	elseif speed < 80 then
		return { bank = "land", volume = 0.35 + speed / 300, pitch = 1.05, layer = "hit" }
	end
	return { bank = "land", volume = 0.75, pitch = 0.75, layer = "slam" }
end

-- Speed trails: a body faster than this (studs/s) streaks; one launched or thrown streaks at once.
FeelTuning.TRAIL_SPEED = 70
FeelTuning.TRAIL_KEEP = 0.5 -- s a trail stays after the body slows (then fades out)
FeelTuning.TRAIL_MAX_TIME = 4 -- s a trail lives at most
FeelTuning.TRAIL_COLORS = table.freeze({
	Launch = Color3.fromRGB(255, 170, 60), -- the cannon, the stations, the hazards
	Throw = Color3.fromRGB(120, 220, 255), -- thrown by hand (a grab)
	Hit = Color3.fromRGB(255, 255, 255), -- knocked flying by a blow
	Fast = Color3.fromRGB(235, 235, 245), -- fast for any other reason
})

-- Impact particles (Mild: never blood): stars on a clang or a head, sparks on metal and guns, a dust
-- ring on the floor. How many of a burst, under the tier's cap.
function FeelTuning.burst(strength: number, cap: number): number
	if strength < 0.2 then
		return 0
	end
	return math.min(cap, math.floor(4 + 14 * strength))
end

-- V9-P4: what a body lands on answers in its own way (by the material's name, pure):
--   "soft"  grass, sand, earth, snow, cloth: a dull thud, earth-coloured dust;
--   "metal" metal, plate, foil: the thud plus a clang;
--   "water" water: no dust (the splash is the water's own);
--   "hard"  everything else (concrete, tiles, plastic, wood): the thud plus a sharp slap.
local SOFT = table.freeze({ Grass = true, LeafyGrass = true, Ground = true, Sand = true, Mud = true, Snow = true, Fabric = true, Salt = true, Pebble = true })
local METAL = table.freeze({ Metal = true, DiamondPlate = true, CorrodedMetal = true, Foil = true })
function FeelTuning.surface(material: string): "soft" | "metal" | "water" | "hard"
	if SOFT[material] then
		return "soft"
	elseif METAL[material] then
		return "metal"
	elseif material == "Water" then
		return "water"
	end
	return "hard"
end

-- The combo slow-mo beat (a camera and colour beat, never the physics): at COMBO_SLOWMO and every
-- COMBO_SLOWMO after.
FeelTuning.SLOWMO_TIME = 0.9
function FeelTuning.slowmoAt(count: number): boolean
	local n = Config.COMBO_SLOWMO
	return n > 0 and count >= n and count % n == 0
end

-- Per gun (every Toys gun: T80). kick: degrees of camera recoil on your own shot (third person; the
-- first-person viewmodel kicks itself), flash: muzzle-flash size in studs (0 = none).
local WARM = Color3.fromRGB(255, 214, 130)
FeelTuning.GUN_FX = table.freeze({
	Blaster = { kick = 0.6, flash = 1.1, casing = "brass" },
	Deagle = { kick = 1.6, flash = 1.6, casing = "brass" },
	GoldenDeagle = { kick = 1.6, flash = 1.7, color = Color3.fromRGB(255, 220, 110), casing = "brass" },
	Revolver = { kick = 1.4, flash = 1.5 }, -- (a revolver keeps its cases in the cylinder)
	SMG = { kick = 0.3, flash = 0.9, casing = "brass" },
	TommyGun = { kick = 0.35, flash = 1.0, casing = "brass" },
	AK = { kick = 0.55, flash = 1.3, casing = "brass" },
	M4 = { kick = 0.45, flash = 1.2, casing = "brass" },
	LMG = { kick = 0.4, flash = 1.3, casing = "brass" },
	Minigun = { kick = 0.15, flash = 1.4, casing = "brass" },
	Sniper = { kick = 2.6, flash = 2.0, casing = "brass" },
	DMR = { kick = 1.2, flash = 1.5, casing = "brass" },
	Shotgun = { kick = 2.4, flash = 2.0, casing = "shell" },
	AutoShotgun = { kick = 1.6, flash = 1.8, casing = "shell" },
	DoubleBarrel = { kick = 3.2, flash = 2.4 }, -- (a break-action: the shells come out on reload)
	FlareGun = { kick = 1.2, flash = 1.4, color = Color3.fromRGB(255, 130, 50) },
	LaserRifle = { kick = 0.15, flash = 0.9, color = Color3.fromRGB(255, 60, 70) },
	Railgun = { kick = 3.5, flash = 2.6, color = Color3.fromRGB(110, 215, 255) },
	Crossbow = { kick = 0.8, flash = 0 },
	Bow = { kick = 0.35, flash = 0 }, -- (V9-NOW 23)
	NailGun = { kick = 0.15, flash = 0 },
} :: { [string]: GunFx })
FeelTuning.FLASH_COLOR = WARM
FeelTuning.KICK_RETURN = 9 -- degrees per s the recoil settles back
FeelTuning.KICK_MAX = 6 -- degrees of recoil held at most (a long burst)

return table.freeze(FeelTuning)
