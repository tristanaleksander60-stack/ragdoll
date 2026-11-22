--!strict
-- Tuning shared by the ragdoll code on every machine (simulator, server, every screen).

local Config = {}

-- Studs of empty space under the pelvis that count as flying.
Config.AIR_CLEARANCE = 3
-- Freeze ray: how long a dummy stays an ice statue, and the ice colour.
Config.FROZEN_TIME = 8
Config.ICE_COLOR = Color3.fromRGB(170, 225, 255)
-- The joints a hard hit can break (noodle limbs); no other joint is ever reported broken.
Config.BREAKABLE_JOINTS = table.freeze({
	LeftShoulder = true, RightShoulder = true, LeftElbow = true, RightElbow = true,
	LeftHip = true, RightHip = true, LeftKnee = true, RightKnee = true,
})
-- The simulator never lets a body part go faster than this (studs/s).
Config.MAX_LINEAR_SPEED = 180
-- Force limits (lift, balance, drive, grabs, rocket thrust) are sized from normal gravity, never
-- the live value: a body set up during Zero-G must be just as strong once gravity comes back.
Config.NORMAL_GRAVITY = 196.2

-- Getting about (lab dummies): walking home, limping, crawling, fleeing, out cold.
Config.GetAbout = table.freeze({
	-- Speeds in studs/s.
	WALK_SPEED = 7,
	LIMP_SPEED = 3.2,
	CRAWL_SPEED = 2.2,
	FLEE_SPEED = 7.5, -- (V10, owner: "much slower when they run"; was 15)
	LIMP_FLEE_SPEED = 3.5, -- (V10; was 5.5)
	CRAWL_FLEE_SPEED = 3,
	SPEED_EASE = 4, -- 1/s
	HOME_LEAVE = 5, -- studs from home before it walks back
	HOME_ARRIVE = 1.6,
	ARRIVE_TURN_MAX = 5, -- s turning on the spot at home before it stands anyway (a snagged limb)
	LOOK_AROUND_TIME = 0.9, -- s standing before it sets off (gets its bearings)
	FLEE_RADIUS = 15, -- a person this close to a dummy hurt in the last FLEE_MEMORY s scares it
	FLEE_MEMORY = 8,
	FLEE_TIME = 3.2,
	FLEE_REST = 2.5, -- s after fleeing before it can be scared off again
	CRAWL_HEIGHT = 1.05, -- pelvis above the ground while crawling
	WALK_HOVER = 0.12, -- the walking body is carried this much higher, so the feet skim the floor
	-- instead of carrying the weight (with it, the soles grip and it moves in jerks)
	LEDGE_DROP = 3, -- studs: ground further down than this ahead of its feet means it walked off an edge
	STUCK_DETOUR = 1.5, -- s without progress home before it tries going round
	DETOUR_ANGLE = math.rad(70),
	DETOUR_TIME = 1.2, -- s it keeps to a detour once chosen
	CRAWL_PITCH = math.rad(18), -- chest raised off the floor
	TRIP_DEG = 55, -- tipped further than this while getting about: falls over
	-- Out cold: a head hit this hard, or any hit this hard (change in body speed, studs/s).
	KO_HEAD_SPEED = 32,
	KO_SPEED = 85,
	KO_MIN = 3.5, -- s out cold, at least...
	KO_MAX = 6, -- ...and at most
})

return table.freeze(Config)
